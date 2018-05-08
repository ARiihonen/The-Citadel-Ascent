local moduleName = "gameplay.SingleSpawnerState"
module(moduleName, package.seeall)
gameplay.stateCollectionUtils.createReloadSupport(moduleName)

local states = {}
states.Idle = ""
states.Spawn = ""
states.Finished = ""

gameplay.stateCollectionUtils.createStateCollection(moduleName, states)
gameplay.stateCollectionUtils.setCommonStateIfNotSet(moduleName, "Common", nil)

stateCollection:setDefaultState("Idle");

-------------------------------------------------------------------------------------------------

function getSpawnerComponent(self)
	return self:getFinalOwner():findComponent(gameplay.SingleSpawnerComponent);
end

function getSpawnType(self, spawnerComponent) 
	if spawnerComponent then
		return spawnerComponent:getTypeForSpawn();
	else
		logger:error("single_spawner_state.lua  No spawner component found from owner")
		return UH_NONE;
	end
end
-------------------------------------------------------------------------------------------------

function Common:sendEnableGravityEvent()
	local spawnerComponent = getSpawnerComponent(self)
	if spawnerComponent then
		local instance = common.CommonUtils.getSceneInstanceByUH(spawnerComponent:getReturnGravityForUH())
		if instance then
			local floatingInfo = instance:findComponent(trinebase.gameplay.skills.FloatingInfoComponent)
			if floatingInfo then
				eventQueue:sendEventWithDelay(spawnerComponent:getEnableGravityDelayMsec(), floatingInfo:getUnifiedHandle(), floatingInfo.EventEnableGravityEvent, {});
			end
		end
	end
end

-------------------------------------------------------------------------------------------------

function Idle:onEnter()
	-- This spawner is now ready for spawning!
	local sc = getSpawnerComponent(self);
	if not sc:getIsReadyForSpawning() then
		sc:setIsReadyForSpawning(true);
	end
	
	if sc:getShouldStartSpawning() then
		-- Start the spawning right away! Don't wait the EventTriggerEnter event, start has been queued by something
		self:doStateCall("EventTriggerEnter");
	end
end

function Idle:onExit()
	-- This spawner isn't ready for another spawn (when the spawner is ready again, it comes back to this idle state)
	local sc = getSpawnerComponent(self);
	if sc:getIsReadyForSpawning() then
		sc:setIsReadyForSpawning(false);
	end
end

function Idle:EventTriggerEnter()
	-- This is called from AbstractSpawnerComponent::trigger()
	
	self:changeState("Spawn");
end

-------------------------------------------------------------------------------------------------

function Spawn:onEnter()	
	self:doStateCall("startSpawning");
end

function Spawn:onExit()
	local spawnerComponent = getSpawnerComponent(self)
	if spawnerComponent:getSpawnAnimContextSetTrueUntilUntrigger() then
		local animationComponent = self:getFinalOwner():getAnimationComponent()
		if animationComponent and spawnerComponent then
			local spawningContext = spawnerComponent:getSpawnAnimationContext()
			if animationComponent:hasContext(spawningContext) then
				animationComponent:setContext(spawningContext, false)
			end
		end	
	end
end

function Spawn:EventTriggerEnter()
	-- nop
end

function Spawn:startSpawning()
	
	if not self:getFinalOwner():isActive() then
		-- Check again later
		self:delayedStateCall("startSpawning", 100);
		return;
	end
	
	local spawnerComponent = getSpawnerComponent(self);	
	local triggerDelayMsec = spawnerComponent:getTriggerDelayMsec();
	
	-- Dont' spawn if not enabled
	if not spawnerComponent:getEnabled() then
		-- Check again later
		self:delayedStateCall("startSpawning", 100);
		return;
	end
	
	if triggerDelayMsec > 20 then
		spawnerComponent:createDelayedSpawnerSpawnEvent(triggerDelayMsec);
	else	
		if spawnerComponent:getDontSpawnIfSpawnAreaIsOccupied() then
			spawnerComponent:doSpawn()
		else
			self:doStateCall("doSpawn")
		end
	end	
end

function Spawn:EventDelayedSpawnerSpawn()
	-- This is called from AbstractSpawnerComponent::delayedSpawerSpawnEvent()
	
	local spawnerComponent = getSpawnerComponent(self);
	if spawnerComponent:getDontSpawnIfSpawnAreaIsOccupied() then
		spawnerComponent:doSpawn()
	else
		self:doStateCall("doSpawn")
	end	
end

function Spawn:continueSpawning()
	local spawnerComponent = getSpawnerComponent(self);
	
	if not self:getFinalOwner():isActive() then
		-- Check again later
		self:delayedStateCall("continueSpawning", 100);
		return;
	end
	
	-- Dont' spawn if not enabled
	if not spawnerComponent:getEnabled() then
		-- Check again later
		self:delayedStateCall("continueSpawning", 100);
		return;
	end
	
	local spawnIntervalMsec = spawnerComponent:getSpawnIntervalMsec();
	
	-- Add some random
	if spawnerComponent:getSpawnIntervalRandomAmountMsec() > 0 then
		local rg = gameplay.ai.AiUtils.getRandomGenerator(self);
		spawnIntervalMsec = spawnIntervalMsec + gameplay.ai.AiUtils.getRandomFloat(rg) * spawnerComponent:getSpawnIntervalRandomAmountMsec();
	end
	
	if spawnIntervalMsec > 20 then
		spawnerComponent:createDelayedSpawnerSpawnEvent(spawnIntervalMsec);
	else	
		if spawnerComponent:getDontSpawnIfSpawnAreaIsOccupied() then
			spawnerComponent:doSpawn()
		else
			self:doStateCall("doSpawn")
		end	
	end	
end

function Spawn:spawnAreaBlocked()
	local spawnerComponent = getSpawnerComponent(self);
	spawnerComponent:doSpawn()
end

function spawnObject(self)
	local spawnerComponent = getSpawnerComponent(self);
	local spawnType = spawnerComponent:getSpawnType();
	
	if spawnType == UH_NONE then
		logger:error("SingleSpawnerState:spawnObject - Spawn type UH is UH_NONE.");
		return false
	end
	
	local isSpawnedTypeNetSyncModeNotSupported = false
	local spawnedTypeObj = typeManager:getTypeByUH(spawnType)
	if(spawnedTypeObj) then
		isSpawnedTypeNetSyncModeNotSupported = spawnedTypeObj:getInstanceProperty("NetSyncMode") == engine.base.NetSyncModeNotSupported
	else
		logger:error("SingleSpawnerState:spawnObject - spawnedTypeObj is nil.")
	end

	if self:getNetSyncer():hasLocalMaster() then
		if isSpawnedTypeNetSyncModeNotSupported then
			self:sendGlobalCallToAll("Spawn", "spawnImpl", 0);
		else
			Spawn.spawnImpl(self)
		end
	end
	return true
end

function Spawn:spawnImpl()
	local spawnerComponent = getSpawnerComponent(self);
	local spawnType = getSpawnType(self, spawnerComponent);
	
	if spawnType == UH_NONE then
		return
	end
	
	function initSpawned(obj, params)
		obj:getTransformComponent():setPosition(params.pos)
		obj:getTransformComponent():setRotation(params.rot)
		params.spawner:addToSpawnedList(obj:getUnifiedHandle())
	end

	local spawnPos = self:getFinalOwner():getTransformComponent():getPosition();
	spawnPos = spawnPos + spawnerComponent:getOffset();
	local randomOffset = spawnerComponent:getOffsetRandomAmount();

	if randomOffset.x > 0 then spawnPos.x = spawnPos.x + gameplay.ai.AiUtils.getRandomFloat(self) * randomOffset.x - randomOffset.x * 0.5 end
	if randomOffset.y > 0 then spawnPos.y = spawnPos.y + gameplay.ai.AiUtils.getRandomFloat(self) * randomOffset.y - randomOffset.y * 0.5 end
	if randomOffset.z > 0 then spawnPos.z = spawnPos.z + gameplay.ai.AiUtils.getRandomFloat(self) * randomOffset.z - randomOffset.z * 0.5 end

	local rotationOffset = spawnerComponent:getRotationOffset();
	local rotationOffsetRandomAmount = spawnerComponent:getRotationOffsetRandomAmount();
	local rotx = rotationOffset.x + gameplay.ai.AiUtils.getRandomFloat(self) * rotationOffsetRandomAmount.x - rotationOffsetRandomAmount.x * 0.5;
	local roty = rotationOffset.y + gameplay.ai.AiUtils.getRandomFloat(self) * rotationOffsetRandomAmount.y - rotationOffsetRandomAmount.y * 0.5;
	local rotz = rotationOffset.z + gameplay.ai.AiUtils.getRandomFloat(self) * rotationOffsetRandomAmount.z - rotationOffsetRandomAmount.z * 0.5;

	sceneInstanceManager:createNewInstance(spawnType, initSpawned, {pos=spawnPos, spawner=spawnerComponent, rot=QUAT(rotx * 0.0174532925, roty * 0.0174532925, rotz * 0.0174532925)});
	
	local animationComponent = self:getFinalOwner():getAnimationComponent()
	if animationComponent then
		local spawningContext = spawnerComponent:getSpawnAnimationContext()
		if animationComponent:hasContext(spawningContext) then
			if spawnerComponent:getSpawnAnimContextSetTrueUntilUntrigger() then
				animationComponent:setContext(spawningContext, true)
			else
				animationComponent:enableContextOnce(spawningContext)
			end
		end
	end

	local audioComponent = self:getFinalOwner():findComponent(audio.AudioComponent)
	if audioComponent then
		local audioEvent = spawnerComponent:getOnSpawnAudioEvent();
		if string.len(audioEvent) > 0 then
			audioComponent:postEventLua(audioEvent);
		end
	end	
	
	-- Reduce spawnsLeft
	local spawnsLeft = spawnerComponent:getSpawnsLeft();
	spawnsLeft = spawnsLeft - 1;
	if spawnsLeft < 0 then
		-- This seems to happen sometimes (not sure if with single spawner or with multispawner or 
		-- with both). If it is by design, should probably think about it and remove the error. 
		-- TrineExperienceSpawnerComponent presumes spawns left never goes under zero, but doesn't 
		-- really mind the extra spawns.
		spawnsLeft = 0
		logger:error("SingleSpawnerState - spawnObject: spawned an extra object")
	end
	spawnerComponent:setSpawnsLeft(spawnsLeft);
end

function Spawn:doSpawn()
	if not self:getFinalOwner():isActive() then
		-- Check again later
		self:delayedStateCall("doSpawn", 100);
		return;
	end
	
	local spawnerComponent = getSpawnerComponent(self);
	
	-- Dont' spawn if not enabled
	if not spawnerComponent:getEnabled() then
		-- Check again later
		self:delayedStateCall("doSpawn", 100);
		return;
	end
	
	if spawnerComponent:getSpawnedInstancesAmount() >= spawnerComponent:getMaxExistSpawnedObjects() then
		-- Check again later
		self:delayedStateCall("doSpawn", 100)
		return
	end
	
	if spawnerComponent:getSpawnsLeft() <= 0 then
		-- No spawns anymore, spawner is finished!
		self:changeState("Finished")
		return
	end
	
	if spawnObject(self) then
		-- Continue spawning or stop?
		if spawnerComponent:getSpawnsLeft() > 0 then
			self:doStateCall("continueSpawning");
		else
			-- No spawns anymore, spawner is finished!
			self:changeState("Finished");
		end	
	end
end

function Spawn:EventTriggerExit()
	-- This is called from AbstractSpawnerComponent::untrigger()
	
	local spawnerComponent = getSpawnerComponent(self);

	if spawnerComponent:getReUseEnabled() then
		if spawnerComponent:getResetSpawnsLeftOnReUse() then
			spawnerComponent:setSpawnsLeft(spawnerComponent:getSpawnAmount())
		end
		-- Back to start waiting for new trigger
		self:changeState("Idle");
		return;
	end
	
	if spawnerComponent:getFinishSpawningOnUnTrigger() then
		-- Spawner is finished!
		self:changeState("Finished");
		return;
	end
	
	-- This is not a valid error message (spawner is left to this state because it's spawning)
	--logger:error("SingleSpawnerState:Spawn:EventTriggerExit - Spawner doesn't know what to to, probably jammed.");
end

-------------------------------------------------------------------------------------------------

function Finished:onEnter()
	local spawnerComponent = getSpawnerComponent(self);

	-- back to idle if this spawner is reUsable
	if spawnerComponent:getReUseEnabled() then
		if spawnerComponent:getResetSpawnsLeftOnReUse() then
			spawnerComponent:setSpawnsLeft(spawnerComponent:getSpawnAmount())
		end
		self:changeState("Idle");
		return;
	end
	
	if not spawnerComponent:getFinishSpawningOnUnTrigger() then
		if spawnerComponent:getWarnAboutSpawnsLeftOnFinished() then
			-- FinishSpawningOnUnTrigger is true, spawner may still have spawns left when spawner is finished, but if false, there shouldn't be any spawns left, never!
			local spawnsLeft = spawnerComponent:getSpawnsLeft();
			if spawnsLeft > 0 then
				logger:error("SingleSpawner:Finished:onEnter - Spawner has " .. tostring(spawnsLeft) .. " left and it's finished. This shouldn't happen. These spawns left aren't spawned now, never.");
			end
		end
	end
end

function Finished:onExit()
	-- nop
end

function Finished:EventTriggerEnter()
	-- nop
end

-------------------------------------------------------------------------------------------------
