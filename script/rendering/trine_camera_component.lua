--
-- Ported to C++. No more used in lua.
-- Old code commented and kept here just in case.
--

--[[
trinebase.rendering.TrineAttachedCameraComponent.addProperty(engine.base.TypeBool, "CameraMissingErrorPrinted", false, "", "Is missing camera entity error message shown.");

function trinebase.rendering.TrineAttachedCameraComponent:start()
	trinebase.rendering.TrineCameraComponent.showingCharacterDeathCharacterChangeTooltip = false
end

function trinebase.rendering.TrineAttachedCameraComponent:stop()
	self:setCameraMissingErrorPrinted(false);
	trinebase.rendering.TrineCameraComponent.cameraUH = nil;
	trinebase.rendering.TrineCameraComponent.characterManagerUH = nil;
	trinebase.rendering.TrineCameraComponent.updatesUntilNextCameraFind = 0;
	trinebase.rendering.TrineCameraComponent.previousPosition = nil
	trinebase.rendering.TrineCameraComponent.previousTime = nil
	trinebase.rendering.TrineCameraComponent.damperComponentTypeUH = nil
	trinebase.rendering.TrineCameraComponent.previousCharacters = {nil,nil,nil}
	trinebase.rendering.TrineCameraComponent.scharacterDeathTime = nil
	trinebase.rendering.TrineCameraComponent.scharacterDeathTimeSet = false	
	trinebase.rendering.TrineCameraComponent.showingCharacterDeathCharacterChangeTooltip = false
end

function getScene()
	if (scene) then
		return scene
	end
	if (gameScene) then
		return gameScene
	end
	logger:error("Couldn't resolve the scene to use for camera calculation.");
	return nil
end


function getSceneInstanceManager()
	local sceneInstMan = sceneInstanceManager
	
	-- what, still no luck? I dunno where the f... I'm supposed to get the manager anyway...
	if (not(sceneInstMan)) then
		if (scene) then
			sceneInstMan = scene:getSceneInstanceManager()
		end
	end
	-- what, still no luck? I dunno where the f... I'm supposed to get the manager anyway...
	if (not(sceneInstMan)) then
		if (gameScene) then
			sceneInstMan = gameScene:getSceneInstanceManager()
		end
	end
	if (not(sceneInstMan)) then
		-- already running in scene context maybe?
		sceneInstMan = instanceManager
	end
	-- oh heck.
	if (not(sceneInstMan)) then
		logger:error("Couldn't resolve the scene instance manager to use for camera calculation.");
	end
	
  return sceneInstMan	
end

function trinebase.rendering.TrineAttachedCameraComponent:calculatePosition()
	if trinebase.rendering.TrineCameraComponent.characterManagerUH == nil or trinebase.rendering.TrineCameraComponent.characterManagerUH == UH_NONE then
		local characterManager = common.CommonUtils.getCharacterSelectionManager()
		if characterManager then
			trinebase.rendering.TrineCameraComponent.characterManagerUH = characterManager:getUnifiedHandle()
		else
			trinebase.rendering.TrineCameraComponent.characterManagerUH = UH_NONE
		end
	end

	local trans = self:getFinalOwner():findComponent(engine.component.TransformComponent);
	local camComp = self:getFinalOwner():findComponent(rendering.CameraComponent);
	local pos = trans:getPosition();
	
	local sce = getScene()
	local sceneInstMan = getSceneInstanceManager();

	local characters = { }
	local characterManager = sceneInstMan:getInstanceByUH(trinebase.rendering.TrineCameraComponent.characterManagerUH)
	if characterManager then
		-- note: the use of hardcoded player indices here is a bit questionable, should rather iterate through all character instances..
		-- Yeah, probably prettier, but at least checking one to three characters instead of nine is faster
		characters = { 
			characterManager:getCharacterInstanceForPlayer(0), 
			characterManager:getCharacterInstanceForPlayer(1), 
			characterManager:getCharacterInstanceForPlayer(2)
		}
	else
		trinebase.rendering.TrineCameraComponent.characterManagerUH = UH_NONE
	end
	
	local instance = nil;
	for key, character in pairs(characters) do
		if character and character:findComponent(engine.component.AbstractNetSyncComponent):hasLocalMaster() then
			local transformComp = character:findComponent(engine.component.TransformComponent)
			local physComp = character:getPhysicsComponent()
			local ragdollPhysComp = character:findComponent(physics.RagdollPhysicsComponent)
			local modelComp = character:findComponent(engine.component.AbstractModelComponent)
			if transformComp and physComp and modelComp and not(ragdollPhysComp) then
				instance = character
				break
			else
				instance = nil
			end
		end
	end
	
	if instance then
		local modelComp = instance:findComponent(engine.component.AbstractModelComponent)
		local lerpedPos = modelComp:getInterpolatedPosition()
		pos = lerpedPos + VC3(0,12.0,2.0)
	end

	if (pos.x == 0 and pos.y == 0 and pos.z == 0) then
		logger:error("About to move camera to zero position.");
	end
	trans:setPosition(pos)
	camComp:setCameraFOV(110.0)
	camComp:setCameraRange(1000.0)
	camComp:setTargetDistance(0.001)
	camComp:setLocalPositionOffset(VC3(0,0,0))
	camComp:setLocalTargetOffset(VC3(0,0,0))
	camComp:setGlobalPositionOffset(VC3(0,0,0))
	camComp:setGlobalTargetOffset(VC3(0,0,0.0))
end



function trinebase.rendering.TrineAttachedCameraComponent:calculatePositionToCameraSystem()

	local sce = getScene()
	local sceneInstMan = getSceneInstanceManager();
	
	-- HACK: Failsafe if CameraSystem does not exist
	if trinebase.rendering.TrineCameraComponent.cameraUH == nil or trinebase.rendering.TrineCameraComponent.cameraUH == UH_NONE then
		-- HACK: prevent the find every single frame (which takes up quite a bit of cpu)
		if (trinebase.rendering.TrineCameraComponent.updatesUntilNextCameraFind > 0) then 
			trinebase.rendering.TrineCameraComponent.updatesUntilNextCameraFind = trinebase.rendering.TrineCameraComponent.updatesUntilNextCameraFind - 1
		else
			-- (note, not sure how often this is really called, but going with this kind of assumption)
			-- 100 frames, with the usual 30Hz or so, should result in a 3 sec delay until the next check is allowed. (?)
			trinebase.rendering.TrineCameraComponent.updatesUntilNextCameraFind = 100
						
			local cam = sceneInstMan:findInstanceByName("NormalGameCamera");
			if cam ~= nil then
				trinebase.rendering.TrineCameraComponent.cameraUH = cam:getUnifiedHandle();
			else
				if not self:getCameraMissingErrorPrinted() then
					local misionIDStr = "NOT FOUND";
					local missionManager = common.CommonUtils.getMissionManager();
					if missionManager ~= nil then					
						local missionID = missionManager:getCurrentMissionID();					
						if missionID ~= nil and string.len(missionID) > 0 then
							misionIDStr = missionID;
						end
					else
						logger:error("TrineCameraComponent - MissionManager is missing.");
					end
					
					-- Don't print error if we are in main menu mission
					if not common.CommonUtils.isMainMenuMission(misionIDStr) then					
						logger:warning("TrineCameraComponent: Mission: " .. misionIDStr .. " - NormalGameCamera is missing! You should add CameraSystemEntity in to the scene and name it to NormalGameCamera.");
					end

					self:setCameraMissingErrorPrinted(true);
				end
			end
			
		end
	else
		local cam = sceneInstMan:getInstanceByUH(trinebase.rendering.TrineCameraComponent.cameraUH);
		if not cam then
			trinebase.rendering.TrineCameraComponent.cameraUH = UH_NONE;
			-- try to find a new one immediately.
			trinebase.rendering.TrineCameraComponent.updatesUntilNextCameraFind = 0
		else
			if cam:getName() ~= "NormalGameCamera" then
				trinebase.rendering.TrineCameraComponent.cameraUH = UH_NONE;
				-- try to find a new one immediately.
				trinebase.rendering.TrineCameraComponent.updatesUntilNextCameraFind = 0
			end
		end
	end
	
	if trinebase.rendering.TrineCameraComponent.characterManagerUH == nil or trinebase.rendering.TrineCameraComponent.characterManagerUH == UH_NONE then
		local characterManager = common.CommonUtils.getCharacterSelectionManager()
		if characterManager then
			trinebase.rendering.TrineCameraComponent.characterManagerUH = characterManager:getUnifiedHandle()
		else
			trinebase.rendering.TrineCameraComponent.characterManagerUH = UH_NONE
		end
	end
	
	if trinebase.rendering.TrineCameraComponent.cameraUH == nil or trinebase.rendering.TrineCameraComponent.cameraUH == UH_NONE then
		trinebase.rendering.TrineAttachedCameraComponent.calculatePosition(self);
		return;
	end
	
	local cam = sceneInstMan:getInstanceByUH(trinebase.rendering.TrineCameraComponent.cameraUH);
	if not cam then
		return;
	end
	
	local calcComp = cam:findComponent(gameplay.CameraCalculateComponent);
	if not(calcComp) then
		logger:error("No CameraCalculateComponent found.");
	end
	--if not calcComp:getCameraEnabled() then
	--	trinebase.rendering.TrineAttachedCameraComponent.calculatePosition(self);
	--	return;
	--end
	local timerComp = cam:findComponent(gameplay.TimerComponent)
	if not(timerComp) then
		logger:error("No TimerComponent found.");
	end

	-- solve time delta from camera system timer
	local currentTime = timerComp:getTime()
	if (not(trinebase.rendering.TrineCameraComponent.previousTime)) then
		trinebase.rendering.TrineCameraComponent.previousTime = currentTime	
	end
	
	local timeDelta = (currentTime - trinebase.rendering.TrineCameraComponent.previousTime)
	local timeDeltaSecs = timeDelta:getSeconds()
	
	-- Note, this camera logic is run by the rendering, rather than by the game logic!
	-- thus, the time deltas here are not bound by the game min/max time step limits
	-- need to probably consider that... and bail out here if time delta is zero, 
	-- since otherwise velocity calculation will incorrectly get a zero value.
	
	if (timeDeltaSecs < 0.0001) then
		return
	end	
    
	local pos = calcComp:getPlayerPosition();

	-- calculate average (weighted) position of players
	local posVectorSum = VC3(0,0,0)
	local posWeightSum = 0
	local vel = VC3(0,0,0)

	local characters = { }
	local characterManager = sceneInstMan:getInstanceByUH(trinebase.rendering.TrineCameraComponent.characterManagerUH)
	if characterManager then
		-- note: the use of hardcoded player indices here is a bit questionable, should rather iterate through all character instances..
		-- Yeah, probably prettier, but at least checking one to three characters instead of nine is faster
		characters = { 
			characterManager:getCharacterInstanceForPlayer(0), 
			characterManager:getCharacterInstanceForPlayer(1), 
			characterManager:getCharacterInstanceForPlayer(2)
		}
	else
		trinebase.rendering.TrineCameraComponent.characterManagerUH = UH_NONE
	end

	local hasPlayerBoundingBox = false
	local playerBoundingBoxMin = VC3(0,0,0)
	local playerBoundingBoxMax = VC3(0,0,0)
	
	local instance = nil
	for key, character in pairs(characters) do
		-- cache UH in case player dies
		-- Why do we care about dead players?
		if character then
			trinebase.rendering.TrineCameraComponent.previousCharacters[key] = character:getUnifiedHandle()
		elseif trinebase.rendering.TrineCameraComponent.previousCharacters[key] then
			characters[key] = sceneInstMan:getInstanceByUH(trinebase.rendering.TrineCameraComponent.previousCharacters[key])
		end
		if character and character:findComponent(engine.component.TransformComponent) and character:getNetSyncer():hasLocalMaster() then
			local playerWeight = 1.0
			local physComp = character:getPhysicsComponent();
			local ragdollPhysComp = character:findComponent(physics.RagdollPhysicsComponent);
			local modelComp = character:findComponent(engine.component.AbstractModelComponent);
			local transfCompForLerpCheck = character:findComponent(engine.component.TransformComponent);
			if(physComp and modelComp and not(ragdollPhysComp)) then
				if key == 1 then playerWeight = 1.75 else playerWeight = 1.0 end
				if(not physComp:isInherited(physics.RagdollPhysicsComponent.getStaticObjectClass())) then
					vel = vel + physComp:getLinearVelocity() * playerWeight;
				end
				local lerpedPos = modelComp:getInterpolatedPosition()
				
				-- if we're dealing with an obvious warp, ignore the model (rendering based) position as that may not have been updated
				local nonLerpedPos = transfCompForLerpCheck:getPosition()
				local lerpDiff = lerpedPos - nonLerpedPos
				if (lerpDiff:getSquareLength() > 5.0*5.0) then
					lerpedPos = nonLerpedPos
				end
				posVectorSum = posVectorSum + (lerpedPos * playerWeight)
				posWeightSum = posWeightSum + playerWeight
				
				if (hasPlayerBoundingBox) then
					if (lerpedPos.x < playerBoundingBoxMin.x) then playerBoundingBoxMin.x = lerpedPos.x end
					if (lerpedPos.x > playerBoundingBoxMax.x) then playerBoundingBoxMax.x = lerpedPos.x end
					if (lerpedPos.z < playerBoundingBoxMin.z) then playerBoundingBoxMin.z = lerpedPos.z end
					if (lerpedPos.z > playerBoundingBoxMax.z) then playerBoundingBoxMax.z = lerpedPos.z end
				else
					playerBoundingBoxMin = VC3(lerpedPos.x, lerpedPos.y, lerpedPos.z)
					playerBoundingBoxMax = VC3(lerpedPos.x, lerpedPos.y, lerpedPos.z)
					hasPlayerBoundingBox = true
				end
			end
		end
	end
	
	-- HACK: ... player distance hack hint for camera system combine...
	if (hasPlayerBoundingBox) then
		-- note, this is not really max player distance, it is actually the bounding box UpL - DownR corner distance 
		-- (note, for 2 players, the same thing, for 3, not quite the same...)
		local playerDistVec = (playerBoundingBoxMax - playerBoundingBoxMin)
		local playerMaxDist = playerDistVec:getLength()
		local camCombineInstance = sceneInstMan:findInstanceByName("CameraSystemCombine")
		if camCombineInstance then
			local combineComp = camCombineInstance:findComponent(platformer.gameplay.PlatformerCameraCombineComponent)
			if combineComp then
				-- HACK: ...				
				playerMaxDist = (playerMaxDist - 3.0) * 0.1
				combineComp:setMaxPlayerDistance(playerMaxDist)
			end
		end
	end
	
	if posWeightSum > 0 then
		pos = posVectorSum * (1 / posWeightSum)
		vel = vel * (1 / posWeightSum)
		characterDeathTimeSet = false
		if trinebase.rendering.TrineCameraComponent.showingCharacterDeathCharacterChangeTooltip then
			local upgradeManager = common.CommonUtils.getTrineUpgradeManager()
			if upgradeManager then
				upgradeManager:hideHintMessage(false)
				gameplay.TrineTooltipState.trineTooltipStateShowingTooltip = false	
				trinebase.rendering.TrineCameraComponent.showingCharacterDeathCharacterChangeTooltip = false	
			else
				logger:error("trine_camera_component.lua - TrineUpgradeManagerInst not found.")
			end							
		end
	else
		if characterDeathTimeSet == false then
			characterDeathTime = common.CommonUtils.getScene():getTime():getMilliseconds()
			characterDeathTimeSet = true
		end		
		if characterDeathTime ~= nil and common.CommonUtils.getScene():getTime():getMilliseconds() - characterDeathTime > 3000 then
			local spawnManager = common.CommonUtils.getGameSpawnManager()
			if spawnManager then
				local reSpawnPos = spawnManager:getLastReSpawnPosition(pos)
				pos = pos * 0.9 + reSpawnPos * 0.1
				pos.y = 0.0
				vel = VC3(0,0,0)
				local dir = pos - reSpawnPos
				if trinebase.rendering.TrineCameraComponent.showingCharacterDeathCharacterChangeTooltip == false and dir:getSquareLength() < 2 then
					local upgradeManager = common.CommonUtils.getTrineUpgradeManager()
					if upgradeManager then
						--TODO: set correct controller
						upgradeManager:showHintMessage("hud.tutorial_tooltips.character_change", gameplay.tooltips.ButtonLB, gameplay.tooltips.ButtonRB, HintMessageController.PS3, false, false)
						trinebase.rendering.TrineCameraComponent.showingCharacterDeathCharacterChangeTooltip = true
					else
						logger:error("trine_camera_component.lua - TrineUpgradeManagerInst not found.")
					end
				end
			else
				logger:error("trine_camera_component.lua - TrineGameSpawnManagerInst not found.")
			end
		end
	end

	-- velocity calculation follows:

	if not trinebase.rendering.TrineCameraComponent.previousPosition then
		-- if previously uninitialized, no velocity
		trinebase.rendering.TrineCameraComponent.previousPosition = pos
	end
	
	local velocityFactor = 0.7
	if not trinebase.rendering.TrineCameraComponent.damperComponentTypeUH then
		local t = typeManager:findTypeByName("CameraSystemEntityGlobalPositionOffsetVectorDamperComponent")
		if t then
			trinebase.rendering.TrineCameraComponent.damperComponentTypeUH = t:getUnifiedHandle();
		else
			logger:error("Failed to find type CameraSystemEntityGlobalPositionOffsetVectorDamperComponent");
			trinebase.rendering.TrineCameraComponent.damperComponentTypeUH = UH_NONE;
		end
	end
	
	local damper = calcComp:getFinalOwner():findComponentByExactType(trinebase.rendering.TrineCameraComponent.damperComponentTypeUH);
	local springC = 1
	if(damper) then
		springC = damper:getSpringConstant() / 4;
	end
	local velocityOffset = vel / springC * velocityFactor;
	
	local posWithVelOffset = pos + velocityOffset
	
	calcComp:setPlayerPosition(posWithVelOffset);

-- HACK: ...
	local cam2 = sceneInstMan:findInstanceByName("CoopGameCamera");
	if (cam2) then
		local calcComp2 = cam2:findComponent(gameplay.CameraCalculateComponent);	
		if (calcComp2) then
			calcComp2:setPlayerPosition(posWithVelOffset)
		end
	end
	local cam3 = sceneInstMan:findInstanceByName("FarCoopGameCamera");
	if (cam3) then
		local calcComp3 = cam3:findComponent(gameplay.CameraCalculateComponent);	
		if (calcComp3) then
			calcComp3:setPlayerPosition(posWithVelOffset)
		end
	end


	-- set the averaged character tracker entity position too, that will be used to trigger camera areas
	local trackerUH = sce:getAveragedCharacterTracker()
	if (trackerUH ~= UH_NONE) then
		local trackerInstance = sceneInstMan:getInstanceByUH(trackerUH)
		if (trackerInstance) then
			local trackerTrans = trackerInstance:findComponent(engine.component.TransformComponent);
			--assert_component(trackerTrans)
			-- do not allow warp to exact zero. just rather remain where-ever the entity currently is instead.
			if (pos.x == 0 and pos.y == 0 and pos.z == 0) then
				-- this apparently happens at startup...
				--logger:error("About to move average position tracker to zero position.");
			else
				trackerTrans:setPosition(pos)
			end
		else
			logger:error("Averaged character tracker entity UH was not valid.")
		end
	else
		logger:error("Averaged character tracker entity is missing (UH_NONE).")
	end
	
	
	trinebase.rendering.TrineCameraComponent.previousPosition = pos
	trinebase.rendering.TrineCameraComponent.previousTime = currentTime
end

local moduleName = "trinebase.rendering.TrineCameraComponent"
module(moduleName, package.seeall)

cameraUH = nil;
updatesUntilNextCameraFind = 0;

-- TODO: this really cannot handle script reload, etc.
-- so this should rather be a property of the CameraCalculateComponent or such.
previousPosition = nil
previousTime = nil
damperComponentTypeUH = nil
previousCharacters = {nil,nil,nil}

characterDeathTime = nil
characterDeathTimeSet = false	
showingCharacterDeathCharacterChangeTooltip = false ]]--

