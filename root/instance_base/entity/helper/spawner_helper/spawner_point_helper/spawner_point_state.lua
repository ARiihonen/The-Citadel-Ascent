local moduleName = "gameplay.SpawnerPointState"
module(moduleName, package.seeall)
gameplay.stateCollectionUtils.createReloadSupport(moduleName)


local states = {}
states.Idle = ""
states.SpawnFromPoint = ""
states.SpawnFromPointFinished = ""

gameplay.stateCollectionUtils.createStateCollection(moduleName, states)

stateCollection:setDefaultState("Idle");

-------------------------------------------------------------------------------------------------

function getSpawnerPointComponent(self)
	return self:getFinalOwner():findComponent(gameplay.SpawnerPointComponent);
end

function getSpawnerPointPosition(self)
	return getSpawnerPointComponent(self):getFinalOwner():getTransformComponent():getPosition();
end

	
function getOwnerSpawnerInstance(self)
	local spawnerPointComponent = getSpawnerPointComponent(self);
	if spawnerPointComponent ~= nil then
		local ownerSpawnerUH = spawnerPointComponent:getOwnerSpawnerUH();
		if not(ownerSpawnerUH == UH_NONE) then
			return sceneInstanceManager:getInstanceByUH(ownerSpawnerUH);
		else
			logger:error("SpawnerPointState:getOwnerSpawnerInstance - No owner instance.");
			return nil;
		end
	else
		logger:error("SpawnerPointState:getOwnerSpawnerInstance - SpawnerPointComponent is missing.");
		return nil;
	end
end

function getOwnerSpawnerInstancePosition(self)
	return getOwnerSpawnerInstance(self):getTransformComponent():getPosition();
end

function getOwnerSpawnerInstanceRotation(self)
	return getOwnerSpawnerInstance(self):getTransformComponent():getRotation();
end

function getOwnerSpawnerStateComponent(self)
	return getOwnerSpawnerInstance(self):findComponent(gameplay.ScriptedStateComponent);
end

function getOwnerSpawnerMultiSpawnerComponent(self)
	return getOwnerSpawnerInstance(self):findComponent(gameplay.MultiSpawnerComponent);
end

function getSpawnTypeUH(self)
	
	local owner = getOwnerSpawnerInstance(self);
	if owner then
		local spawnerComponent = owner:findComponent(gameplay.MultiSpawnerComponent)
		if spawnerComponent then
			return spawnerComponent:getTypeForSpawn();
		else
			logger:error("spawner_point_state.lua No spawner component found from owner")
		end
	else
		return UH_NONE;
	end
end

function spawnFailed(self)
	local owner = getOwnerSpawnerInstance(self);
	if owner then
		owner:findComponent(gameplay.ScriptedStateComponent):doStateCall("spawnFailed");
	end
end

function spawnFinished(self)
	local owner = getOwnerSpawnerInstance(self);
	if owner then
		owner:findComponent(gameplay.ScriptedStateComponent):doStateCall("spawnFinished");
	else
		logger:error("SpawnerPointState:spawnFinished - Owner missing, cannot reduce spawn amount from the owner.");
	end
end

function spawnInstance(self, spawnType, spawnPos, spawnRot, spawningFinishedStateName)
	if spawnType == UH_NONE then
		logger:error("SpawnerPointState:spawnInstance - spawnType is UH_NONE.");
		return false;
	end	

	function initSpawned(obj, params)
		local objTransformComponent = obj:getTransformComponent();
		objTransformComponent:setPosition(params.pos);
		--objTransformComponent:setRotation(params.rot);
		local trine3DPhysicsComp = obj:findComponent(trinebase.gameplay.Trine3DCharacterPhysicsComponent)
		if trine3DPhysicsComp then
			-- HACKY: T3 specific, transform component gets overriden in the first tick so have to use this
			trine3DPhysicsComp:setCapsuleHeading(params.rot);
		end
		local tc = obj:findComponent(engine.component.TransformComponent)
		if tc then
			-- Special AIs that don't navigate with navigation still need this too...
			tc:setRotation(params.rot);
		end
		
		if params.spawnerStateComponent == nil then
			logger:error("SpawnerPointState:spawnInstance:initSpawned - params.spawnerStateComponent is nil.");
			return;
		end
		
		local ownerSpawnerInstance = getOwnerSpawnerInstance(params.spawnerStateComponent);
		if ownerSpawnerInstance == nil then
			logger:error("SpawnerPointState:spawnInstance:initSpawned - ownerSpawnerInstance is nil.");
			return;
		end

		local spawnerComp = ownerSpawnerInstance:findComponent(gameplay.AbstractSpawnerComponent)
		if spawnerComp then
			spawnerComp:addToSpawnedList(obj:getUnifiedHandle())
			local aiCharComp = obj:findComponent(gameplay.ai.AICharacterComponent)
			if aiCharComp ~= nil then
				aiCharComp:setAiSpawnerUH(spawnerComp:getUnifiedHandle())
				aiCharComp:setSpawnerPointUH(params.spawnerPointComponent:getUnifiedHandle())
			else
				logger:error("SpawnerPointState:spawnInstance:initSpawned - AICharacterComponent was not found.")
			end
			local modelComp = obj:findComponent(rendering.ModelComponent)
			if modelComp ~= nil then -- Hide the model before the AI gets the correct spawn context
				modelComp:setVisibleInGame(false);
			else
				logger:error("SpawnerPointState:spawnInstance:initSpawned - ModelComponent was not found.")
			end
		end
		
		-- Finally finished
		if params.spawnerPointComponent ~= nil then
			-- Save last spawned object UH
			params.spawnerPointComponent:setLastSpawnedUH(obj:getUnifiedHandle());
		end
		
		-- Change to finished state
		params.spawnerStateComponent:changeState(params.spawnerStateFinishedStateName);

		-- After this init script, start() is runned
		-- Instance creation is synced after start() is run
	end
	
	-- Just to be sure, check for master
	if self:getNetSyncer():hasLocalMaster() then
		sceneInstanceManager:createNewInstance(spawnType, initSpawned, {spawnerStateComponent = self, spawnerPointComponent = getSpawnerPointComponent(self), spawnerStateFinishedStateName = spawningFinishedStateName,  pos = spawnPos, rot = spawnRot});
	end
	
	return true;
end

function doSpawnWithStateTransition(self, spawnPos, spawnRot, failedStateName, spawningFinishedStateName)
	local spawnerPointComponent = getSpawnerPointComponent(self);
	if not spawnerPointComponent == nil then
		logger:error("SpawnerPointState:doSpawn - SpawnerPointComponent is missing.");
		self:changeState(failedStateName);
		return;
	end
	
	local spawnType = getSpawnTypeUH(self);
	if spawnType == UH_NONE then
		logger:error("SpawnerPointState:doSpawn - spawnType is UH_NONE.");
		spawnFailed(self);
		return;
	end
	
	-- Reset last spawned always
	spawnerPointComponent:setLastSpawnedUH(UH_NONE);
	
	local success = spawnInstance(self, spawnType, spawnPos, spawnRot, spawningFinishedStateName);	
	if success then		
		-- When instance is actually created, state is change to spawningFinishedStateName
		-- Waiting...
	else
		self:changeState(failedStateName);
		spawnFailed(self);
	end
end

-------------------------------------------------------------------------------------------------

function Idle:onEnter()
	-- HACK: Apparently game scene raytraces doesn't work in component::start() ?? Need to delay them a bit...
	-- Move spawn point to near the ground delayed
	--if self:getNetSyncer():hasLocalMaster() then
		if getSpawnerPointComponent(self):getMoveOwnerToGround() then
			self:delayedStateCall("initToGroundPos", math.random(50, 200)); -- Add some random that "Exceeded maximum limit for delayed state calls per frame" will shut up :)
		end
	--end
end

function Idle:onExit()
	-- nop
end

function Idle:initToGroundPos()
	getSpawnerPointComponent(self):initToGroundPos();
end

function Idle:startSpawn()
	-- This is called from multi_spawner_state.lua:startSpawningForTargetPointUH()	
	
	-- Only master handles spawning
	if not self:getNetSyncer():hasLocalMaster() then
		return;
	end
	
	self:changeState("SpawnFromPoint");
end

-------------------------------------------------------------------------------------------------

function SpawnFromPoint:onEnter()
	self:doStateCall("spawn");
end

function SpawnFromPoint:onExit()
	-- nop
end

function SpawnFromPoint:spawn()
	local spawnerPointComponent = getSpawnerPointComponent(self)
	local spawnPos = getSpawnerPointPosition(self)
	spawnPos = spawnPos + spawnerPointComponent:getOffset()
	local spawnRot = QUAT()
	local tc = spawnerPointComponent:getFinalOwner():findComponent(engine.component.TransformComponent)
	if tc ~= nil then
		spawnRot = tc:getRotation()
	end
	doSpawnWithStateTransition(self, spawnPos, spawnRot, "Idle", "SpawnFromPointFinished")
end

-------------------------------------------------------------------------------------------------

function SpawnFromPointFinished:onEnter()
	local lastSpawnedUH = getSpawnerPointComponent(self):getLastSpawnedUH();
	
	-- only localmaster calls the sceneInstanceManager and gives a function
	-- that sets the LastSpawnedUH
	local hasLocalMaster = self:getNetSyncer():hasLocalMaster()
	if lastSpawnedUH == UH_NONE and hasLocalMaster then
		logger:error("SpawnerPointState:SpawnFromPointFinished:onEnter - SpawnFromPoint should be successfull but last spawned UH is UH_NONE.");
	end
	-- Back to start
	self:changeState("Idle");
end

function SpawnFromPointFinished:onExit()
	spawnFinished(self);
end

-------------------------------------------------------------------------------------------------
