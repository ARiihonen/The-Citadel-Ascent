local moduleName = "gameplay.MultiSpawnerState"
module(moduleName, package.seeall)
gameplay.stateCollectionUtils.createReloadSupport(moduleName)

local states = {}
states.Idle = ""
states.StartSpawn = ""
states.WaitingForDelayedSpawn = ""
states.Spawn = ""
states.WaitingSpawnToBeFinished = ""
states.SpawnBlocked = ""
states.Finished = ""

gameplay.stateCollectionUtils.createStateCollection(moduleName, states)
gameplay.stateCollectionUtils.setCommonStateIfNotSet(moduleName, "Common", nil)

stateCollection:setDefaultState("Idle");

-------------------------------------------------------------------------------------------------

function getSpawnerComponent(self)
	return self:getFinalOwner():findComponent(gameplay.MultiSpawnerComponent);
end

function setShouldStopSpawning(self, value)
	getSpawnerComponent(self):setShouldStopSpawning(value);
end

function getShouldStopSpawning(self)
	return getSpawnerComponent(self):getShouldStopSpawning();
end

function getTrackObjectsComponentActiveInstanceAmountFromTargetPointUH(targetPointUH)
	if targetPointUH ~= UH_NONE then
		local targetPointInstance = sceneInstanceManager:getInstanceByUH(targetPointUH);
		if targetPointInstance ~= nil then
			local trackObjectsComponent = targetPointInstance:findComponent(gameplay.TrackObjectsComponent);
			if trackObjectsComponent ~= nil then
				return trackObjectsComponent:getActiveInstanceAmount();
			end
		end
	end
	return 0;
end

function canSpawnIntoTargetPointUH(targetPointUH, ignoreSpawnPointBlockedStatus)
	local targetPointInstance = sceneInstanceManager:getInstanceByUH(targetPointUH);
	if targetPointInstance == nil then
		logger:error("MultiSpawnerState:canSpawnIntoTargetPointUH - No such target point instance found with given UH.");
		return false;
	end
	
	local spawnPointStateComponent = targetPointInstance:findComponent(gameplay.ScriptedStateComponent);
	if spawnPointStateComponent == nil then
		logger:error("MultiSpawnerState:canSpawnIntoTargetPointUH - TargetPointInstance doesn't have ScriptedStateComponent.");
		return false;
	end
	
	-- Not very pretty or efficient at all.
	local spawnPointComponent = targetPointInstance:findComponent(gameplay.SpawnerPointComponent);
	if spawnPointComponent ~= nil then
		local ownerSpawnerInstance = sceneInstanceManager:getInstanceByUH(spawnPointComponent:getOwnerSpawnerUH());
		if ownerSpawnerInstance ~= nil then
			local ownerSpawnerComponent = ownerSpawnerInstance:findComponent(gameplay.MultiSpawnerComponent);
			if ownerSpawnerComponent ~= nil then
				if ownerSpawnerComponent:getEnableSpawnPointOccupiedCheck() and not spawnPointComponent:isSpawnAreaClear() then
					return false;
				elseif ownerSpawnerComponent:getLookAlikeSpawn() then
					if ownerSpawnerComponent:getTargetPointUHArray():getSize() ~= ownerSpawnerComponent:getSpawnAmount() then
						logger:error("LookAlikeSpawn only works correctly if spawner has as many points in TargetPointUHArray as SpawnAmount.")
					elseif spawnPointComponent:getLastSpawnedUH() ~= UH_NONE then
						-- Just disable anything that has already spawned something so the spawn points can "become alive" only once.
						return false;
					end
				end
			end
		end
	end
	
	if spawnPointStateComponent:getCurrentState() ~= "Idle" then				
		-- Allow spawning only if spawn point's state is Idle
		-- Not an error, just wait that spawn point is ready again for spawning
		return false;
	end
	
	local spawnPointAvailable = true;
		
	if ignoreSpawnPointBlockedStatus then
		-- Ignore blocked status
	else
		local instancesBlockingThePoint = getTrackObjectsComponentActiveInstanceAmountFromTargetPointUH(targetPointUH);
		if instancesBlockingThePoint > 0 then
			spawnPointAvailable = false;
		end
	end

	return spawnPointAvailable;
end

function startSpawningForTargetPointUH(self, targetPointUH, spawner)
	if not(targetPointUH == UH_NONE) then
		local targetPointInstance = sceneInstanceManager:getInstanceByUH(targetPointUH);
		if targetPointInstance then
		
			local spawnPointStateComponent = targetPointInstance:findComponent(gameplay.ScriptedStateComponent);
			if spawnPointStateComponent == nil then
				logger:error("MultiSpawnerState:startSpawningForTargetPointUH - TargetPointInstance doesn't have ScriptedStateComponent.");
				return false;
			end
			
			local spawnerPointComponent = targetPointInstance:findComponent(gameplay.SpawnerPointComponent);
			if spawnerPointComponent ~= nil then
				spawnerPointComponent:setOffset(spawner:getOffset());
				spawnerPointComponent:setOffsetRandomAmount(spawner:getOffsetRandomAmount());
				spawnerPointComponent:setRotationOffset(spawner:getRotationOffset());
				spawnerPointComponent:setRotationOffsetRandomAmount(spawner:getRotationOffsetRandomAmount());
			end				
			-- Save UH
			-- NOTE: This is a stupid hack, multispawner might spawn instances simultaneously...
			spawner:setLastSpawnPointUH(targetPointUH);	

			spawnPointStateComponent:doStateCall("startSpawn");
						
			return true;
		else
			logger:error("MultiSpawnerState:startSpawningForTargetPointUH - Invalid targetPoint instance.");
			return false;			
		end
	else
		logger:error("MultiSpawnerState:startSpawningForTargetPointUH - Invalid targetPointUH.");
		return false;
	end
	
	logger:error("MultiSpawnerState:startSpawningForTargetPointUH - Error occured.");
	return false;
end

function handleExitImpl(self)
	local spawnerComponent = getSpawnerComponent(self);
	
	if spawnerComponent:getFinishSpawningOnUnTrigger() then
		-- Spawner is finished!
		
		-- Reset queued exit
		if getShouldStopSpawning(self) then
			setShouldStopSpawning(self, false);
		end
		self:changeState("Finished");
		return true; -- Return true, which indicates that this spawner isn't ready for new spawns!
	end

	if spawnerComponent:getReUseEnabled() then
		--spawnerComponent:setSpawnsLeft(spawnerComponent:getSpawnAmount())
		-- Back to start waiting for new trigger
		
		-- Reset queued exit
		if getShouldStopSpawning(self) then
			setShouldStopSpawning(self, false);
		end
		
		if self:getCurrentState() == "Idle" then
			return false; -- Need to return false as the spawner is ready for new spawns!
		else
			self:changeState("Idle");
			return true; -- Return true, which indicates that this spawner isn't ready for new spawns!
		end		
	end
	
	return false;
end

function handleExit(self, queueExit)
	if queueExit then
		setShouldStopSpawning(self, true);
		return false;
	else
		return handleExitImpl(self);
	end
end

function stopSpawningAndFinish(self)
	-- Has someone requested stopping the spawning?
	if getShouldStopSpawning(self) then		
		if handleExitImpl(self) then
			-- Stop!
			return true;
		end		
	end	
	return false;
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
	if stopSpawningAndFinish(self) then
		return;
	end
	
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

	-- Only master handles spawning
	if not self:getNetSyncer():hasLocalMaster() then
		return;
	end
	
	self:changeState("StartSpawn");
end

-------------------------------------------------------------------------------------------------

function StartSpawn:onEnter()
	if stopSpawningAndFinish(self) then
		return;
	end

	-- NOTE: Add some random
	-- if combineTriggerComponent triggers multiple spawners, they all might get triggered at the same time (if there isn't any trigger delay),
	-- And if there is an ai collector area which should ensure that there isn't too many ais, it may fail
	-- By adding some random to the spawning start, change that too many ais will exist, is reduced
	local addRandomDelayBeforeSpawn = getInstanceType(self):getAddRandomDelayBeforeSpawn();
	if addRandomDelayBeforeSpawn then
		self:delayedStateCall("startSpawnImpl", math.random(1, 200));
	else
		self:doStateCall("startSpawnImpl");
	end
end

function StartSpawn:onExit()
	-- nop
end

function StartSpawn:startSpawnImpl()
	if not self:getFinalOwner():isActive() then
		-- Check again later
		self:delayedStateCall("startSpawnImpl", 100);
		return;
	end
	
	local spawnerComponent = getSpawnerComponent(self);
	
	-- Don't spawn if not enabled
	if not spawnerComponent:getEnabled() then
		-- Check again later
		self:delayedStateCall("startSpawnImpl", 100);
		return;
	end
	
	local triggerDelayMsec = spawnerComponent:getTriggerDelayMsec();

	if triggerDelayMsec > 20 then		
		spawnerComponent:createDelayedSpawnerSpawnEvent(triggerDelayMsec);
		self:changeState("WaitingForDelayedSpawn");
	else
		-- Instant spawn
		self:changeState("Spawn");
	end	
end

function StartSpawn:EventTriggerExit()
	-- This is called from AbstractSpawnerComponent::untrigger()
	handleExit(self, false);
end

-------------------------------------------------------------------------------------------------

function WaitingForDelayedSpawn:onEnter()
	if stopSpawningAndFinish(self) then
		return;
	end
end

function WaitingForDelayedSpawn:onExit()
	-- nop
end

function WaitingForDelayedSpawn:EventDelayedSpawnerSpawn()
	-- This is called from AbstractSpawnerComponent::delayedSpawerSpawnEvent()
	self:changeState("Spawn");
end

function WaitingForDelayedSpawn:EventTriggerExit()
	-- This is called from AbstractSpawnerComponent::untrigger()
	handleExit(self, true);
end

function WaitingForDelayedSpawn:EventTriggerEnter()
	-- desperate hack... just please spawn me some cauldron monsters...

	if not self:getNetSyncer():hasLocalMaster() then
		return;
	end
	
	self:changeState("StartSpawn");
end

-------------------------------------------------------------------------------------------------

function Spawn:onEnter()
	-- Instant spawn
	self:doStateCall("doSpawn");
end

function Spawn:onExit()
	-- nop
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
		self:changeState("Finished")
		return
	end
	
	local targetPointUHList = spawnerComponent:getTargetPointUHArray();
	
	local ignoreSpawnPointBlockedStatus = getInstanceType(self):getIgnoreSpawnPointBlockedStatus();
	
	if spawnerComponent:getSpawnSimultaneously() then
		-- Search for valid spawn points
		local spawnAmountAllowed = 0;
		for i = 0, targetPointUHList:getSize() - 1 do
			if not(targetPointUHList:get(i) == UH_NONE) then
				local targetPointUH = targetPointUHList:get(i);
				if canSpawnIntoTargetPointUH(targetPointUH, ignoreSpawnPointBlockedStatus) then
					spawnAmountAllowed = spawnAmountAllowed + 1;
				end
			end
		end
		
		local assumedSpawnAmount = targetPointUHList:getSize();
		if assumedSpawnAmount ~= spawnAmountAllowed then
			-- If even one of the spawn points fails, all will fail
			self:changeState("SpawnBlocked");
			return;
		else		
			spawnerComponent:setSimultaneouslySpawnsLeft(assumedSpawnAmount);
			-- Final check
			local spawnsOccured = false;
			for i = 0, targetPointUHList:getSize() - 1 do
				if not(targetPointUHList:get(i) == UH_NONE) then
					spawnsOccured = true;
					break;
				end
			end
			
			if spawnsOccured then				
				-- NOTE: Relies on that state is changed instant and startSpawningForTargetPointUH may call some state calls inside the new state
				self:changeState("WaitingSpawnToBeFinished");
				-- Spawn!
				for i = 0, targetPointUHList:getSize() - 1 do
					if not(targetPointUHList:get(i) == UH_NONE) then
						local targetPointUH = targetPointUHList:get(i);
						startSpawningForTargetPointUH(self, targetPointUH, spawnerComponent);
					end
				end			
				return;
			else
				logger:error("MultiSpawnerState:Spawn:doSpawn - No simultaneously spawns occured, targetPointUHList size is zero? Spawner stops working now.");	
				self:changeState("Finished");
				return;
			end
		end
	else
		local targetPointUH = spawnerComponent:getRandomTargetPointUH();
		if not spawnerComponent:getUseHighestPriorityPointByDefault() and 
				canSpawnIntoTargetPointUH(targetPointUH, ignoreSpawnPointBlockedStatus) then
			-- NOTE: Relies on that state is changed instant and startSpawningForTargetPointUH may call some state calls inside the new state
			self:changeState("WaitingSpawnToBeFinished");
			
			startSpawningForTargetPointUH(self, targetPointUH, spawnerComponent);
			return;
		else
			-- Cannot spawn to random spawn point, try to find some other point
			local lastTargetPointUH = UH_NONE;
			local highestPriorityTargetPointUH = UH_NONE;
			local highestPriorityTargetPointValue = 0;
			for i = 0, targetPointUHList:getSize() - 1 do
				if not(targetPointUHList:get(i) == UH_NONE) then
					local targetPointUH = targetPointUHList:get(i);
					if canSpawnIntoTargetPointUH(targetPointUH, ignoreSpawnPointBlockedStatus) then
						lastTargetPointUH = targetPointUH;
					
						local targetPointInstance = sceneInstanceManager:getInstanceByUH(targetPointUH);
						if targetPointInstance ~= nil then
							local spawnerPointComponent = targetPointInstance:findComponent(gameplay.SpawnerPointComponent);
							if spawnerPointComponent ~= nil then
								local priority = spawnerPointComponent:getPriority();
								if priority > highestPriorityTargetPointValue then
									highestPriorityTargetPointUH = targetPointUH;
									highestPriorityTargetPointValue = priority;
								end
							end
						end			
					end
				end
			end
			
			if highestPriorityTargetPointUH ~= UH_NONE then
				-- Found one, spawn!
		
				-- NOTE: Relies on that state is changed instant and startSpawningForTargetPointUH may call some state calls inside the new state
				self:changeState("WaitingSpawnToBeFinished");
			
				startSpawningForTargetPointUH(self, highestPriorityTargetPointUH, spawnerComponent);
				return;
			else
				-- Just use last one valid (shouldn't come here never)
				if lastTargetPointUH ~= UH_NONE then
					-- Found one, spawn!
							
					-- NOTE: Relies on that state is changed instant and startSpawningForTargetPointUH may call some state calls inside the new state
					self:changeState("WaitingSpawnToBeFinished");
					
					startSpawningForTargetPointUH(self, lastTargetPointUH, spawnerComponent);
					return;
				end
			end

			-- No spawns points found where to spawn, switch state
			self:changeState("SpawnBlocked");
			return;
		end
	end
	
	logger:error("MultiSpawnerState:Spawn:doSpawn - Error occured, spawner stops working now.");	
	self:changeState("Finished");
end

function Spawn:EventTriggerExit()
	-- This is called from AbstractSpawnerComponent::untrigger()
	handleExit(self, true);
end

-------------------------------------------------------------------------------------------------

function WaitingSpawnToBeFinished:onEnter()
	-- nop
end

function WaitingSpawnToBeFinished:onExit()
	-- nop
end

function WaitingSpawnToBeFinished:spawnFailed()
	-- spawnFailed() is called from SpawnerPoint
	
	local spawnerComponent = getSpawnerComponent(self);
	if spawnerComponent ~= nil then
		spawnerComponent:setLastSpawnPointUH(UH_NONE);
	else
		logger:error("MultiSpawnerState:WaitingSpawnToBeFinished:spawnFailed - SpawnerComponent is missing.");
	end
	
	logger:warning("MultiSpawnerState:WaitingSpawnToBeFinished:spawnFailed - Spawning failed, spawner stops working now.");
	
	self:changeState("Finished");
end

function WaitingSpawnToBeFinished:spawnFinished()
	-- spawnFinished() is called from SpawnerPoint

	local tryToContinueSpawning = false;
	local spawnerComponent = getSpawnerComponent(self);
			
	if spawnerComponent:getSpawnSimultaneously() then
		-- Reduce simultaneosly spawns
		spawnerComponent:setSimultaneouslySpawnsLeft(spawnerComponent:getSimultaneouslySpawnsLeft() - 1);		
		if spawnerComponent:getSimultaneouslySpawnsLeft() > 0 then
			-- Do nothing, simultaneously spawns still left
			return;
		else
			-- All simultaneosly spawns are spawned, reduce spawn amount and continue spawning if possible
			tryToContinueSpawning = true;
		end
	else
		tryToContinueSpawning = true;
	end
	
	if tryToContinueSpawning then
		-- Reduce spawnsLeft
		local spawnsLeft = spawnerComponent:getSpawnsLeft() - 1;
		if spawnsLeft < 0 then
			-- This seems to happen sometimes (not sure if with single spawner or with multispawner 
			-- or with both). If it is by design, should probably think about it and remove the 
			-- error. TrineExperienceSpawnerComponent presumes spawns left never goes under zero, 
			-- but doesn't really mind the extra spawns.
			spawnsLeft = 0
			logger:error("MultiSpawnerState - spawnFinished: spawned an extra object")
		end
		spawnerComponent:setSpawnsLeft(spawnsLeft);
		
		-- Continue spawning or stop?
		if spawnsLeft > 0 then
			-- NOTE: Continue spawning needs to be a bit delayed, otherwise spawners with multiple spawnpoints will spawn object to each spawn point
			-- Spawner might get disabled after one spawn
			self:delayedStateCall("continueSpawning", 100);
			return;
		end
	end	
	
	-- Get out
	self:changeState("Finished");
end

function WaitingSpawnToBeFinished:continueSpawning()
	if stopSpawningAndFinish(self) then
		return;
	end

	if not self:getFinalOwner():isActive() then
		-- Check again later
		self:delayedStateCall("continueSpawning", 100);
		return;
	end
	
	local spawnerComponent = getSpawnerComponent(self);
	
	-- Don't spawn if not enabled
	if not spawnerComponent:getEnabled() then
		-- Check again later
		self:delayedStateCall("continueSpawning", 100);
		return;
	end

	local spawnIntervalMsec = spawnerComponent:getSpawnIntervalMsec();
	
	-- Add some random
	if spawnerComponent:getSpawnIntervalRandomAmountMsec() > 0 then
		spawnIntervalMsec = spawnIntervalMsec + gameplay.ai.AiUtils.getRandomFloat(self) * spawnerComponent:getSpawnIntervalRandomAmountMsec();
	end

	if spawnIntervalMsec > 20 then
		-- Create delayed spawn event
		spawnerComponent:createDelayedSpawnerSpawnEvent(spawnIntervalMsec);
		self:changeState("WaitingForDelayedSpawn");
		return;
	else
		-- Instant spawn
		self:changeState("Spawn");
		return;
	end	
end

function WaitingSpawnToBeFinished:EventTriggerExit()
	-- This is called from AbstractSpawnerComponent::untrigger()
	handleExit(self, true);
end

-------------------------------------------------------------------------------------------------

function SpawnBlocked:onEnter()
	if stopSpawningAndFinish(self) then
		return;
	end
	
	local spawnerComponent = getSpawnerComponent(self);
	
	local blockedDelay = 0;
	local spawnInterVal = spawnerComponent:getSpawnIntervalMsec();
	if spawnInterVal > 0 then
		blockedDelay = spawnInterVal;
	else
		-- SHOULD Spawn immediately, but add always some delay because of blocked
		blockedDelay = 200;
	end

	if blockedDelay > 0 then
		self:delayedStateCall("startSpawnAfterBlocked", blockedDelay);
	else
		self:doStateCall("startSpawnAfterBlocked");	
	end
end

function SpawnBlocked:onExit()
	-- nop
end

function SpawnBlocked:startSpawnAfterBlocked()
	if stopSpawningAndFinish(self) then
		return;
	end

	self:changeState("StartSpawn");
end

function SpawnBlocked:EventTriggerExit()
	-- This is called from AbstractSpawnerComponent::untrigger()
	
	-- Do not queue the stop spawning, we don't know how long it's going to take that this spawner can spawn again and spawn points aren't blocked anymore
	handleExit(self, false);
end

-------------------------------------------------------------------------------------------------

function Finished:onEnter()
	local spawnerComponent = getSpawnerComponent(self);
	if spawnerComponent ~= nil then
		-- Trigger possible other instances
		spawnerComponent:triggerOtherInstances();
	end
	
	-- Check spawn amount status delayed
	self:delayedStateCall("checkSpawnedAmountStatus", 500);
end

function Finished:onExit()
	-- nop
end

function Finished:checkSpawnedAmountStatus()
	local spawnerComponent = getSpawnerComponent(self);
	if not spawnerComponent:getFinishSpawningOnUnTrigger() then
		if spawnerComponent:getWarnAboutSpawnsLeftOnFinished() then
			-- FinishSpawningOnUnTrigger is true, spawner may still have spawns left when spawner is finished, but if false, there shouldn't be any spawns left, never!
			local spawnsLeft = spawnerComponent:getSpawnsLeft();
			if spawnsLeft > 0 then
				if self:getNetSyncer():hasLocalMaster() then
					-- Only host should print the message
					logger:error("MultiSpawnerState:Finished:onEnter - Spawner has " .. tostring(spawnsLeft) .. " left and it's finished. This shouldn't happen. These spawns left aren't spawned now, never.");
				end
			end
		end
	end
end

-------------------------------------------------------------------------------------------------
