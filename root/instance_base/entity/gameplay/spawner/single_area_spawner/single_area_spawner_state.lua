local moduleName = "gameplay.SingleAreaSpawnerState"
module(moduleName, package.seeall)
gameplay.stateCollectionUtils.createReloadSupport(moduleName)

local states = {}
states.Idle = gameplay.SingleSpawnerState.Idle
states.Spawn = gameplay.SingleSpawnerState.Spawn
states.Finished = gameplay.SingleSpawnerState.Finished

gameplay.stateCollectionUtils.createStateCollection(moduleName, states)
gameplay.stateCollectionUtils.setCommonStateIfNotSet(moduleName, "Common", gameplay.SingleSpawnerState.Common)

stateCollection:setDefaultState("Idle");

-------------------------------------------------------------------------------------------------

function getSpawnerComponent(self)
	return self:getFinalOwner():findComponent(gameplay.AbstractSpawnerComponent);
end

function getSpawnType(self, spawnerComponent) 
	if spawnerComponent then
		return spawnerComponent:getTypeForSpawn();
	else
		logger:error("single_area_spawner_state.lua  No spawner component found from owner")
		return UH_NONE;
	end
end

-------------------------------------------------------------------------------------------------

function Spawn:EventSpawn()
	-- This is called from SingleAreaSpawnerComponent::doSpawn()
	-- This occurs e.g. when last object leaves from the area or gets destroyed
	
	local spawnerComponent = getSpawnerComponent(self)
	if spawnerComponent then
		if (common.CommonUtils.getScene():getTime():getMilliseconds() - spawnerComponent:getLastSpawnTime():getMilliseconds()) < spawnerComponent:getSpawnIntervalMsec() then
			self:delayedStateCall("doSpawn", spawnerComponent:getSpawnIntervalMsec() - (common.CommonUtils.getScene():getTime():getMilliseconds() - spawnerComponent:getLastSpawnTime():getMilliseconds()))
			return
		end
	end
	
	self:doStateCall("doSpawn");
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
	

	local spawnType = getSpawnType(self, spawnerComponent)
	if not(spawnType == UH_NONE) then
	
		function initSpawned(obj, params)
			obj:getTransformComponent():setPosition(params.pos);
			obj:getTransformComponent():setRotation(params.rot);
			
			-- These differs from single_spawner_state.lua:doSpawn()
			params.spawner:setLastSpawnedUH(obj:getUnifiedHandle());
			params.spawner:connectBreakSignal(obj:getUnifiedHandle());
			params.spawner:addToSpawnedList(obj:getUnifiedHandle());
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
		
		-- Just to be sure, check for master
		if self:getNetSyncer():hasLocalMaster() then
			sceneInstanceManager:createNewInstance(spawnType, initSpawned, {pos=spawnPos, spawner=spawnerComponent, rot=QUAT(rotx * 0.0174532925, roty * 0.0174532925, rotz * 0.0174532925)});
		end
		
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
		
		spawnerComponent:setLastSpawnTime(common.CommonUtils.getScene():getTime())
		
		-- Reduce spawnsLeft
		local spawnsLeft = spawnerComponent:getSpawnsLeft();
		spawnsLeft = spawnsLeft - 1;
		if spawnsLeft < 0 then
			-- This seems to happen sometimes (not sure if with single spawner or with multispawner 
			-- or with both). If it is by design, should probably think about it and remove the 
			-- error. TrineExperienceSpawnerComponent presumes spawns left never goes under zero, 
			-- but doesn't really mind the extra spawns.
			spawnsLeft = 0
			logger:error("SingleAreaSpawnerState - doSpawn: spawned an extra object")
		end
		spawnerComponent:setSpawnsLeft(spawnsLeft);

		-- Continue spawning or stop?
		if spawnsLeft > 0 then
			-- Start waiting for spawn
		else
			-- No spawns anymore, spawner is finished!
			self:changeState("Finished");
		end
	else
		logger:error("SingleAreaSpawnerState:Spawn:doSpawn - Spawn type UH is UH_NONE.");
	end
end

-------------------------------------------------------------------------------------------------
