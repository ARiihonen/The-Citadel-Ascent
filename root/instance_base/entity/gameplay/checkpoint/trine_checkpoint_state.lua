local moduleName = "gameplay.TrineCheckpointState"
module(moduleName, package.seeall)
gameplay.stateCollectionUtils.createReloadSupport(moduleName)

local states = {}
states.Init = ""
states.NonActivated = ""
states.Activated = ""

gameplay.stateCollectionUtils.createStateCollection(moduleName, states)

stateCollection:setDefaultState("Init");

local thisModule = _M

shouldActivateMinTimeToWait = 3000

declareManualReload(thisModule, [[characterNames]])
declareManualReload(thisModule, [[lastActivationTime]])
declareManualReload(thisModule, [[shouldActivateMinTimeToWait]])

-------------------------------------------------------------------------------------------------

function isActivateCheckpoint(self)
	return self:getFinalOwner():findComponent(trinebase.gameplay.TrineCheckpointComponent):getActivated();
end


function activateCheckpoint(self)
	local comp = self:getFinalOwner():findComponent(trinebase.gameplay.TrineCheckpointComponent);
	if not comp:getActivated() then
		comp:setActivated(true);
	end
end


function unActivateCheckpoint(self)
	local comp = self:getFinalOwner():findComponent(trinebase.gameplay.TrineCheckpointComponent);
	if comp:getActivated() then
		comp:setActivated(false);
	end
end


function isCheckpointEnabled(self)
	return self:getFinalOwner():findComponent(trinebase.gameplay.TrineCheckpointComponent):getEnabled();
end


local function getExtraInfoForCharacters(characterInstances)
	local infoTable = { }
	for name, instance in pairs(characterInstances) do
		local uh = instance:getUnifiedHandle()
		local master = instance:findComponent(trinebase.gameplay.TrineHealthComponent)
		local hc = instance:findComponent(trinebase.gameplay.TrineHealthComponent)
		local tc = instance:getTransformComponent()
		if hc and tc then
			infoTable[name] = { instance = instance, healthComponent = hc, transformComponent = tc, uh = uh }
		else
			if not hc then logger:error("trine_checkpoint_state.lua - getExtraInfoForCharacters: healthComponent missing") end
			if not tc then logger:error("trine_checkpoint_state.lua - getExtraInfoForCharacters: transformComponent missing") end
		end
	end
	return infoTable
end


local function shouldWarpCharacterToCheckPoint(allCharacters, characterWithInfo, position)
	-- warp only if all other local players are dead or at least one of them is near the checkpoint
	-- (avoid throwing players around in net coop)
	local hasLocalPlayerNearCheckPoint = false
	local allLocalPlayersDead = true
	for name, character in pairs(allCharacters) do
		-- Don't compare to self
		if character.uh ~= characterWithInfo.uh then
			-- Check if characters are on same client
			if character.master == characterWithInfo.master then
				if character.healthComponent:getHealth() > 0 then
					allLocalPlayersDead = false
				end
				local d = character.transformComponent:getPosition() - position
				if d:getLength() < 5.0 then
					hasLocalPlayerNearCheckPoint = true
				end
			end
		end
	end
	return allLocalPlayersDead or hasLocalPlayerNearCheckPoint
end


local function giveCharacterHealth(characterWithInfo, factor, position)
	local wasDead = false
	local gotHealth = false
	local hc = characterWithInfo.healthComponent
	local newHealth = hc:getMaxHealth() * factor
	local curHealth = hc:getHealth()
	if curHealth <= 0 then 
		wasDead = true
		hc:increaseTempImmortalCounter();
	end
	if curHealth < newHealth then
		gotHealth = true
		eventQueue:sendEventToMaster(hc:getUnifiedHandle(), hc.EventSetHealthAbsolute, { health = newHealth, forClient = false })
	end
	if wasDead then
		local tc = characterWithInfo.transformComponent
		local params = {}
		params.position = VC3(position.x, position.y, position.z)
		eventQueue:sendEventToMaster(tc:getUnifiedHandle(), tc.EventWarpToPosition, params)
		-- make sure a frame is executed so player can be warped to safety (this will break at < 5 FPS)
		hc:decreaseTempImmortalCounterWithDelay(200);
	end
	local rv = {}
	rv.wasDead = wasDead
	rv.gotHealth = gotHealth
	return rv
end


local function changeCheckpointModel(self, active)
	local modelComponent = self:getFinalOwner():findComponent(rendering.ModelComponent)
	if modelComponent then
		local checkpointComponent = self:getFinalOwner():findComponent(trinebase.gameplay.TrineCheckpointComponent)
		if checkpointComponent then
			-- need to start checkpointComponent first
			if(not checkpointComponent:isStarted()) then
				checkpointComponent:start();
			end
						
			local activatedModelComponent = checkpointComponent:findComponent(rendering.ModelComponent)
			if activatedModelComponent then
				if active then
					if checkpointComponent:getActivatedModelUH() == UH_NONE then
						-- Skip model change
						return
					end
					activatedModelComponent:setVisibilityEnabled(true)
					activatedModelComponent:setSwayFrequency(VC3(0.5,0.0,3.5))
					modelComponent:setVisibilityEnabled(false)
					modelComponent:setSwayFrequency(VC3(0.5,0.0,1.5))
				else
					if checkpointComponent:getActivatedModelUH() ~= UH_NONE then
						activatedModelComponent:setVisibilityEnabled(false)
						activatedModelComponent:setSwayFrequency(VC3(0.5,0.0,3.5))
					end
					modelComponent:setVisibilityEnabled(true)
					modelComponent:setSwayFrequency(VC3(0.5,0.0,1.5))
				end
			else
				logger:error("trine_checkpoint_state.lua -  activated model component not found")
			end
		else
			logger:error("trine_checkpoint_state.lua -  TrineCheckpointComponent is not found")
		end
	else
		logger:error("trine_checkpoint_state.lua -  ModelComponent is not found")
	end
end


local function doesNeedToAddHealth(instance, factor)
	if instance then
		if factor < 0 or factor > 1.0 then
			logger:error("TrineCheckpointState - doesNeedToAddHealth() - Invalid factor")
			return false
		end
		local comp = instance:findComponent(trinebase.gameplay.TrineHealthComponent)
		if comp then
			if comp:getHealth() < comp:getMaxHealth() * factor - 0.1 then
				return true
			end
		end
	end
	return false
end


local function shouldActivateCheckpoint(self)
	local cpc = self:getFinalOwner():findComponent(trinebase.gameplay.TrineCheckpointComponent)
	if cpc and cpc:getAreaRefCount() > 0 then
		-- check if this checkpoint is not last activated checkpoint
		local spawnManager = common.CommonUtils.getGameSpawnManager();
		if spawnManager then
			local handle = spawnManager:getLastActivatedCheckpointUH()
			if handle:getContextSceneUH() == UH_NONE and cpc:getMissionStartCheckpoint() == false then
				return true
			end
			if handle:getContextSceneUH() == scene:getUnifiedHandle() then
				if handle:getUH() == UH_NONE or handle:getUH() ~= self:getFinalOwner():getUnifiedHandle() then
					return true
				end
			end
		end

		-- check if need to give health
		if cpc:getRestoreHealthAndResurrect() then
			local healthFactor = cpc:getHealthRestoreFactor()
			local characters = gameplay.util.getActiveCharacters()
			for name, instance in pairs(characters) do
				if doesNeedToAddHealth(instance, healthFactor) then return true end
			end
		end
	end
	return false
end


local function healAndResurrect(checkPoint)
	local cpc = checkPoint:findComponent(trinebase.gameplay.TrineCheckpointComponent)
	if cpc and cpc:getRestoreHealthAndResurrect() then
		local deadCharacters = 0
		local checkpointPosition = checkPoint:getTransformComponent():getPosition()
		-- Dealing with active characters should be enough
		local allCharacters = gameplay.util.getActiveCharacters()
		allCharacters = getExtraInfoForCharacters(allCharacters)
		local newPositions = {}
		local spawnManager = common.CommonUtils.getGameSpawnManager();
		for name, character in pairs(allCharacters) do
			if character.transformComponent then
				local playerPos = character.transformComponent:getPosition()
				newPositions[name] = cpc:findClosestRespawnPoint(playerPos)
			else
				newPositions[name] = checkpointPosition
			end
		end
		
		-- Give health
		local healthFactor = cpc:getHealthRestoreFactor()
		local wasDead = false
		local gotHealth = false
		for name, character in pairs(allCharacters) do
			local hpInfo = giveCharacterHealth(character, healthFactor, newPositions[name])
			if hpInfo.wasDead then
				wasDead = true
				deadCharacters = deadCharacters + 1
			end
			if hpInfo.gotHealth then
				gotHealth = true
			end
		end
		if deadCharacters > 0 then
			local audioComponent = checkPoint:findComponent(audio.AudioComponent)
			if audioComponent then
				audioComponent:postEventLua("Play_checkpoint_ball_resurrection")
			end
		end

		cpc:giveFocusTestInfo(wasDead, gotHealth)
	end
end


-------------------------------------------------------------------------------------------------

function Init:onEnter()
	-- nop
end


function Init:onExit()
	-- nop
end


function Init:EventStarted()
	self:changeState("NonActivated");
end


-------------------------------------------------------------------------------------------------

function NonActivated:onEnter()
	unActivateCheckpoint(self)
	changeCheckpointModel(self, isActivateCheckpoint(self))
	self:doStateCall("playerInAreaCheck")
end


function NonActivated:onExit()
	-- nop
end


function NonActivated:onAreaEnter()
	if(not self:getNetSyncer():hasLocalMaster()) then
		return
	end
	
	if isCheckpointEnabled(self) then
		if shouldActivateCheckpoint(self) then
			self:changeState("Activated")
		end
	end
end


function NonActivated:playerInAreaCheck()
	if shouldActivateCheckpoint(self) then
		local curTime = common.CommonUtils.getScene():getTime():getMilliseconds();
		if not lastActivationTime then
			lastActivationTime = curTime
		elseif curTime - lastActivationTime > shouldActivateMinTimeToWait then
			self:changeState("Activated")
			return
		end
	end
	local cpc = self:getFinalOwner():findComponent(trinebase.gameplay.TrineCheckpointComponent)
	if cpc:getAreaRefCount() > 0 then
		self:delayedStateCall("playerInAreaCheck", 500)
	end
end


-------------------------------------------------------------------------------------------------

function Activated:onEnter()
	-- Activate checkpoint for the first time
	lastActivationTime = common.CommonUtils.getScene():getTime():getMilliseconds()
	activateCheckpoint(self)
	
	-- activation effect
	local doEffectComponent = self:getFinalOwner():findComponent(gameplay.effect.DoEffectComponent)
	if doEffectComponent then
		if doEffectComponent:getEffectType() ~= UH_NONE then
			doEffectComponent:spawnWithEffectEntityUH(doEffectComponent:getEffectType())
		end
	end

	local attachEffectComponent = self:getFinalOwner():findComponent(gameplay.effect.AttachEffectComponent)
	if attachEffectComponent then
		local cpc = self:getFinalOwner():findComponent(trinebase.gameplay.TrineCheckpointComponent)
		if cpc and cpc:getAttachedEffectWhenActivated() ~= UH_NONE then
			attachEffectComponent:setEffectType(cpc:getAttachedEffectWhenActivated())
			attachEffectComponent:setEnabled(true)
		end
	end
	
	local audioComponent = self:getFinalOwner():findComponent(audio.AudioComponent)
	if audioComponent then
		audioComponent:postEventLua("Play_checkpoint_ball_check")
	end
	
	changeCheckpointModel(self, isActivateCheckpoint(self))
	
	if(not self:getNetSyncer():hasLocalMaster()) then
		return
	end
	
	healAndResurrect(self:getFinalOwner())
	
	self:delayedStateCall("playerInAreaCheck", 500)
end


function Activated:onAreaEnter()
	-- Reactivate checkpoint

	local cpc = self:getFinalOwner():findComponent(trinebase.gameplay.TrineCheckpointComponent)
	if cpc then
		local minReactivationInterval = cpc:getMinReactivationInterval()
		if minReactivationInterval > 0 then
			shouldActivateMinTimeToWait = minReactivationInterval * 1000 -- sec to ms
		end
	end
	
	if not lastActivationTime then
		lastActivationTime = common.CommonUtils.getScene():getTime():getMilliseconds()
	end
	
	local curTime = common.CommonUtils.getScene():getTime():getMilliseconds()
	if curTime - lastActivationTime > shouldActivateMinTimeToWait then
		lastActivationTime = curTime
		activateCheckpoint(self)

		if cpc then
			-- spawn reactivation effect
			local effect = cpc:getReactivationEffect()
			if effect ~= UH_NONE then
				local doEffectComponent = self:getFinalOwner():findComponent(gameplay.effect.DoEffectComponent)
				if doEffectComponent then
					doEffectComponent:spawnWithEffectEntityUH(effect)
				end
			end
			
			-- reactivation sound 
			local audioEvent = cpc:getReactivationAudioEvent()
			if audioEvent ~= "" then
				local audioComponent = self:getFinalOwner():findComponent(audio.AudioComponent)
				if audioComponent then
					audioComponent:postEventLua(audioEvent)
				end
			end
			
			-- set reactivation animation context
			local animContext = cpc:getReactivationAnimContext()
			if animContext ~= "" then
				local animationComponent = self:getFinalOwner():findComponent(animation.AnimationComponent)
				if animationComponent then
					animationComponent:setContext(animContext, true)
				end
			end
		end

		healAndResurrect(self:getFinalOwner())
	end

	self:delayedStateCall("playerInAreaCheck", 500)
end


function Activated:onExit()
	-- nop
end


function Activated:playerInAreaCheck()
	if shouldActivateCheckpoint(self) then
		local curTime = common.CommonUtils.getScene():getTime():getMilliseconds();
		if not lastActivationTime then
			lastActivationTime = curTime
		elseif curTime - lastActivationTime > shouldActivateMinTimeToWait then
			self:doStateCall("enable")
			return
		end
	end
	local cpc = self:getFinalOwner():findComponent(trinebase.gameplay.TrineCheckpointComponent)
	if cpc:getAreaRefCount() > 0 then
		self:delayedStateCall("playerInAreaCheck", 500)
	end
end


function Activated:onAreaExit()
	if(not self:getNetSyncer():hasLocalMaster()) then
		return
	end
	
	-- All players exited the area
	
	-- Go back to start
	local delay = getInstanceType(self):getCheckpointDisableTime();
	if delay > 0 then
		self:delayedStateCall("enable", delay);
	else
		self:doStateCall("enable");	
	end
end


function Activated:enable()
	unActivateCheckpoint(self)
end

-------------------------------------------------------------------------------------------------