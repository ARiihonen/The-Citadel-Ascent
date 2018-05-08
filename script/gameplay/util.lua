module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

local thisModule = _M
declareCustomReload(thisModule, [[vars]], [[init]], [[uninit]], { })


function init()
	vars = { }
end


function uninit()
	vars = nil
end

function uninitScene()
	vars = { }
end

function isTooltipAllowed(demoOnly)
	if not common.CommonUtils.isInGameGUIAllowed() then
		return false;
	end

	if demoOnly and demoOnly ~= 0 then		
		if gameBaseApplicationModule:getDemo() then
			return true;
		else
			return false;
		end
	end
	
	return true;
end

-- note: this returns all copies for all clients!
function getAllCharacters()
	return common.CommonUtils.getAllPlayerCharacters()
end


-- This returns only active copies, which may or may not reside on local client
function getActiveCharacters()
	return common.CommonUtils.getSelectedPlayerCharacters()
end


-- this is used by the TrineCinematicCharacterHiderComponent, to warp all the other players to the given one.
-- (note, this has a small threshold to the warp)
-- note, this should work for warping to other entities as well, not limited to a character only
function warpOtherCharacterToCharacter(destinationCharacterUH)
	assert_uh(destinationCharacterUH)
	
	local warpThreshold = 1.0
	local sce = common.CommonUtils.getScene();
	
	local sceneInstanceManager = sce:getSceneInstanceManager()
	if sceneInstanceManager then
		local destinationPos
		local instance = sceneInstanceManager:getInstanceByUH(destinationCharacterUH)
		if instance then
			local transform = instance:findComponent(engine.component.TransformComponent);
			if transform then
				destinationPos = transform:getPosition()
			else
				logger:error("warpOtherCharacterToCharacter: TransformComponent not found.")
				return
			end
		else
			logger:error("warpOtherCharacterToCharacter: Instance not found.")
			return
		end
	
		local characterManager = common.CommonUtils.getSelectedPlayerCharacters()
		for key, playerInstance in pairs(playerCharacters) do
			if playerInstance then
				if (playerInstance:getUnifiedHandle() ~= destinationCharacterUH) then
					local playerTransformComponent = playerInstance:findComponent(engine.component.TransformComponent);
					if playerTransformComponent then
						local posDiff = playerTransformComponent:getPosition() - destinationPos
						if (posDiff:getSquareLength() > warpThreshold*warpThreshold) then
							-- HACK: since the current cinematics prefer showing the rightmost character in the map, when others are hidden,
							-- thus, hacking this so that the warping character won't be the rightmost, but stays a bit to the left
							-- (that should hopefully usually make the originally visible character remain visible)
							local destinationPosOnLeft = VC3(destinationPos.x - 0.1, destinationPos.y, destinationPos.z)
							-- TODO: should clear the velocity of the warped character to ensure that it actually stays on the left... rather than going past the previous player
							playerTransformComponent:setPosition(destinationPosOnLeft)
						end
					end
				end
			end
		end
	end
end


function warpPlayerToDestination(spawnInstanceName)
	local sce = common.CommonUtils.getScene();
	
	local sceneInstanceManager = sce:getSceneInstanceManager()
	if sceneInstanceManager then
		local destinationPos
		local instance = sceneInstanceManager:findInstanceByName(spawnInstanceName)
		if instance then
			local transform = instance:findComponent(engine.component.TransformComponent);
			if transform then
				destinationPos = transform:getPosition()
			else
				logger:error("warpPlayerToDestination: TransformComponent not found.")
				return
			end
		else
			logger:error("warpPlayerToDestination: Instance not found.")
			return
		end
	
		local characterManager = common.CommonUtils.getSelectedPlayerCharacters()
		for key, playerInstance in pairs(playerCharacters) do
			if playerInstance then
				local playerTransformComponent = playerInstance:findComponent(engine.component.TransformComponent);
				if playerTransformComponent then
					playerTransformComponent:setPosition(destinationPos)
				end
			end
		end
	end
end

function switchPlayerToCharacter(characterName)
	local sce = common.CommonUtils.getScene();
	local sceneInstanceManager = sce:getSceneInstanceManager();
	
	local characterManager = common.CommonUtils.getCharacterSelectionManager()
	local missionManager = common.CommonUtils.getMissionManager()
	if characterManager and missionManager then
		if characterName == "warrior" then
			if characterManager:getCharacterForPlayer(0) ~= trinebase.gameplay.TrineCharacterNone then
				characterManager:forceCharacterChange(0, trinebase.gameplay.TrineCharacterWarrior)
			end
			if missionManager:getGhostMultiplayerEnabled() then
				if characterManager:getCharacterForPlayer(1) ~= trinebase.gameplay.TrineCharacterNone then
					characterManager:forceCharacterChange(1, trinebase.gameplay.TrineCharacterWarriorGhostOne)
				end
				if characterManager:getCharacterForPlayer(2) ~= trinebase.gameplay.TrineCharacterNone then
					characterManager:forceCharacterChange(2, trinebase.gameplay.TrineCharacterWarriorGhostTwo)
				end
			end
		elseif characterName == "thief" then
			if characterManager:getCharacterForPlayer(0) ~= trinebase.gameplay.TrineCharacterNone then
				characterManager:forceCharacterChange(0, trinebase.gameplay.TrineCharacterThief)
			end
			if missionManager:getGhostMultiplayerEnabled() then
				if characterManager:getCharacterForPlayer(1) ~= trinebase.gameplay.TrineCharacterNone then
					characterManager:forceCharacterChange(1, trinebase.gameplay.TrineCharacterThiefGhostOne)
				end
				if characterManager:getCharacterForPlayer(2) ~= trinebase.gameplay.TrineCharacterNone then
					characterManager:forceCharacterChange(2, trinebase.gameplay.TrineCharacterThiefGhostTwo)
				end
			end
		elseif characterName == "wizard" then
			if characterManager:getCharacterForPlayer(0) ~= trinebase.gameplay.TrineCharacterNone then
				characterManager:forceCharacterChange(0, trinebase.gameplay.TrineCharacterWizard)
			end
			if missionManager:getGhostMultiplayerEnabled() then
				if characterManager:getCharacterForPlayer(1) ~= trinebase.gameplay.TrineCharacterNone then
					characterManager:forceCharacterChange(1, trinebase.gameplay.TrineCharacterWizardGhostOne)
				end
				if characterManager:getCharacterForPlayer(2) ~= trinebase.gameplay.TrineCharacterNone then
					characterManager:forceCharacterChange(2, trinebase.gameplay.TrineCharacterWizardGhostTwo)
				end
			end
		else
			logger:error("switchPlayerToCharacter: parameter must be \"warrior\", \"thief\" or \"wizard\"")
			return
		end
	end
end

function warpCamera(duration, ignoreErrors)
	local s = gameScene;
	if(not s)
	then
		s = scene;
	end
	local cam = s:getSceneInstanceManager():findInstanceByName("NormalGameCamera");
	if cam then
		local ccc = cam:findComponent(gameplay.CameraCalculateComponent)
		if ccc then
 			ccc:setWarpTime(Time(duration))
		elseif ignoreErrors ~= nil and not ignoreErrors then
			logger:error("Could not find CameraCalculateComponent from NormalGameCamera")
		end
	else
		if ignoreErrors ~= nil and not ignoreErrors then
			logger:error("Could not find camera");
		end
	end

-- HACK: !!!	
	cam = s:getSceneInstanceManager():findInstanceByName("CoopGameCamera");
	if cam then
		local ccc = cam:findComponent(gameplay.CameraCalculateComponent)
		if ccc then
 			ccc:setWarpTime(Time(duration))
		elseif ignoreErrors ~= nil and not ignoreErrors then
			logger:error("Could not find CameraCalculateComponent from CoopGameCamera")
		end
	else
		if ignoreErrors ~= nil and not ignoreErrors then
			logger:error("Could not find camera");
		end
	end
	
-- HACK: !!!	
	cam = s:getSceneInstanceManager():findInstanceByName("FarCoopGameCamera");
	if cam then
		local ccc = cam:findComponent(gameplay.CameraCalculateComponent)
		if ccc then
 			ccc:setWarpTime(Time(duration))
		elseif ignoreErrors ~= nil and not ignoreErrors then
			logger:error("Could not find CameraCalculateComponent from FarCoopGameCamera")
		end
	else
		if ignoreErrors ~= nil and not ignoreErrors then
			logger:error("Could not find camera");
		end
	end
	
	-- need to cause immediate update	
	local rendCamInst = s:getSceneInstanceManager():findInstanceByName("camera");
	if (rendCamInst) then
		local trineCamComp = rendCamInst:findComponent(trinebase.gameplay.TrineAttachedCameraComponent)
		if(trineCamComp) then
			trineCamComp:update()
		end
	end
end

function tutorialChangeToWarriorPart() 
	-- disable wizard stuff
	--common.CommonUtils.setFogEnabledByName("wizard_outside_fog", false)
	--common.CommonUtils.setSkyModelEnabledByName("wizard_thief_skymodel", false)
	--common.CommonUtils.setAmbientLightEnabledByName("Lights_off_ambient", false)
	-- enable warrior stuff
	--common.CommonUtils.setFogEnabledByName("warrior_outside_fog", true)
	--common.CommonUtils.setSkyModelEnabledByName("warrior_skymodel", true)
	--common.CommonUtils.setAmbientLightEnabledByName("warrior_outside_ambient", true)
	-- change character
	gameplay.util.warpPlayerToDestination("warrior_spawn")
	gameplay.util.switchPlayerToCharacter("warrior")
	-- NOTE: warpCamera must now occur after the player entities really move! (to ensure a framerate independent immediate camera update)
	gameplay.util.warpCamera(1)	
end

function tutorialChangeToThiefPart()
	-- disable warrior stuff
	--common.CommonUtils.setFogEnabledByName("warrior_outside_fog", false) 
	--common.CommonUtils.setSkyModelEnabledByName("warrior_skymodel", false)
	--common.CommonUtils.setAmbientLightEnabledByName("warrior_outside_ambient", false)
	-- enable thief stuff
	--common.CommonUtils.setFogEnabledByName("thief_fog", true)
	--common.CommonUtils.setSkyModelEnabledByName("wizard_thief_skymodel", true)
	--common.CommonUtils.setAmbientLightEnabledByName("thief_ambient", true)
	-- change character
	gameplay.util.warpPlayerToDestination("thief_spawn")
	gameplay.util.switchPlayerToCharacter("thief")
	-- NOTE: warpCamera must now occur after the player entities really move! (to ensure a framerate independent immediate camera update)
	gameplay.util.warpCamera(1)
end

function getCurrectTooltipComponent()
	local sce = common.CommonUtils.getScene()
	if sce then
		local sceneInstanceManager = sce:getSceneInstanceManager()
		if sceneInstanceManager then
			local upgradeManager = common.CommonUtils.getTrineUpgradeManager()
			if upgradeManager then	
				local handle = upgradeManager:getCurrentTooltipUH()
				if handle:getContextSceneUH() == sce:getUnifiedHandle() then
					if not(handle:getUH() == UH_NONE) then
						local instance = sceneInstanceManager:getInstanceByUH(handle:getUH())
						if instance then
							return instance:findComponent(trinebase.gameplay.TrineTooltipsComponent)
						end
					end
				end
			else
				logger:error("gameplay.util.getCurrectTooltipComponent: upgradeManager not found")
			end
		else
			logger:error("gameplay.util.getCurrectTooltipComponent: sceneInstanceManager is nil")
		end
	else
		logger:error("gameplay.util.getCurrectTooltipComponent: scene not found")
	end
	return nil
end

function hideCurrentTooltip(demoOnly)
	if demoOnly ~= nil then
		if not isTooltipAllowed(demoOnly) then
			return;
		end
	end
	
	local tooltipComponent = getCurrectTooltipComponent()
	if tooltipComponent then
		local stateComponent = tooltipComponent:getFinalOwner():findComponent(gameplay.ScriptedStateComponent)
		if stateComponent then
			stateComponent:changeState("Idle")
		end
	end
end

function setTooltipConditionTrueWithNoShowTest(conditionNbr, ifTooltipIsType, ifTooltipIsInStage)
	local tooltipComponent = getCurrectTooltipComponent()
	if tooltipComponent then
		if tooltipComponent:getEnabled() and tooltipComponent:getTooltipType() == ifTooltipIsType then
			if tooltipComponent:getStage() == ifTooltipIsInStage or ifTooltipIsInStage == -1 then
				if conditionNbr == 1 then
					tooltipComponent:setCondition1Done(true)
				else
					tooltipComponent:setCondition2Done(true)
				end
			end
		end
	end	
end

function setTooltipConditionTrue(conditionNbr, ifTooltipIsType, ifTooltipIsInStage)
	if not gameplay.TrineTooltipState.trineTooltipStateShowingTooltip then
		return
	end
	setTooltipConditionTrueWithNoShowTest(conditionNbr, ifTooltipIsType, ifTooltipIsInStage)
end


function setTooltipStage(stage, ifTooltipIsType, ifTooltipIsInStage, noTimeDelays)
	if not gameplay.TrineTooltipState.trineTooltipStateShowingTooltip then
		return
	end
	if gameplay.TrineTooltipState.trineTooltipLastStateChangeTimerUpdated == true and not(gameplay.TrineTooltipState.trineTooltipStateChangeTimerNewStage == stage) then
		gameplay.TrineTooltipState.trineTooltipLastStateChangeTimerUpdated = false
	end
	local tooltipComponent = getCurrectTooltipComponent()
	if tooltipComponent then
		if tooltipComponent:getEnabled() and tooltipComponent:getTooltipType() == ifTooltipIsType then
			if not(tooltipComponent:getStage() == stage) then
				if tooltipComponent:getStage() == ifTooltipIsInStage or ifTooltipIsInStage == -1 then
					if gameplay.TrineTooltipState.trineTooltipLastStateChangeTimerUpdated == false then
						gameplay.TrineTooltipState.trineTooltipStateChangeTimer = scene:getTime():getMilliseconds()
						gameplay.TrineTooltipState.trineTooltipLastStateChangeTimerUpdated = true
						gameplay.TrineTooltipState.trineTooltipStateChangeTimerNewStage = stage
					end
					local currentTime = scene:getTime():getMilliseconds()
					if noTimeDelays or currentTime - gameplay.TrineTooltipState.trineTooltipStateChangeTimer > 300 or (stage == 0 and currentTime - gameplay.TrineTooltipState.trineTooltipStateChangeTimer > 50) then
						gameplay.TrineTooltipState.trineTooltipLastStateChangeTimerUpdated = false
						tooltipComponent:setStage(stage)
					end
				end
			end
		end
	end
end

function getTooltipStage(tooltipType)
	if not gameplay.TrineTooltipState.trineTooltipStateShowingTooltip then
		return -1
	end
	local tooltipComponent = getCurrectTooltipComponent()
	if tooltipComponent then
		if tooltipComponent:getEnabled() and tooltipComponent:getTooltipType() == tooltipType then
		    return tooltipComponent:getStage()
		end
    end
    return -1
end

function forceTooltipVisibilityIfTooltipType(visible, ifTooltipIsType)
	if not gameplay.TrineTooltipState.trineTooltipStateInTooltipArea then
		return
	end
	local tooltipComponent = getCurrectTooltipComponent()
	if tooltipComponent then
		if tooltipComponent:getEnabled() and tooltipComponent:getTooltipType() == ifTooltipIsType then
			local ts = tooltipComponent:getFinalOwner():findComponent(gameplay.ScriptedStateComponent)
			if ts then
				if visible then
					ts:doStateCall("forceStartShowingTooltip")
				else
					ts:doStateCall("forceHideTooltip")
				end
			end
		end
	end
end


function doShakeEffect(shakeOrigin, shakeLength, shakeOffsetRandom, shakeOffsetSway, swayFrequency, useOldShakeOffsetAmountModifier, smoothingAtEndLength, playAudio)
	assert_vc3(shakeOrigin)
	assert_number(shakeLength)
	assert_vc3(shakeOffsetRandom)
	assert_vc3(shakeOffsetSway)
	assert_vc3(swayFrequency)
	assert_number(useOldShakeOffsetAmountModifier)
	assert_number(smoothingAtEndLength)
	-- HACK: allowing nil for backward compatibility
	assert_boolean_or_nil(playAudio)

	local sceneInstanceManager = nil
	if scene then
		sceneInstanceManager = scene:getSceneInstanceManager()
	elseif gameScene then
		sceneInstanceManager = gameScene:getSceneInstanceManager()
	end
	if not(sceneInstanceManager) then
		logger:error("gameplay.util.lua - sceneInstanceManager is nil")
		return false
	end
	local shakeInstance = nil
	if vars.shakeEffectUH == nil or vars.shakeEffectUH == UH_NONE then
		shakeInstance = sceneInstanceManager:findInstanceByName("cameraShake")
		if shakeInstance ~= nil then
			vars.shakeEffectUH = shakeInstance:getUnifiedHandle()
		else
			logger:error("gameplay.util.lua - cameraShake instance not found")
		end
	else
		shakeInstance = sceneInstanceManager:getInstanceByUH(vars.shakeEffectUH)
		if shakeInstance == nil then
			shakeInstance = sceneInstanceManager:findInstanceByName("cameraShake")
			if shakeInstance then vars.shakeEffectUH = shakeInstance:getUnifiedHandle() end
		end
	end
	if vars.shakeEffectUH == nil or vars.shakeEffectUH == UH_NONE then
		logger:error("gameplay.util.lua - shakeEffectUH is nil")
		return false
	end
	shakeInstance = shakeInstance or sceneInstanceManager:getInstanceByUH(vars.shakeEffectUH)
	if shakeInstance then
		local shakeComponent = shakeInstance:findComponent(gameplay.ShakeComponent)
		if shakeComponent then
			-- HACK: backward compatibility support with old executables
			if (playAudio == nil) then
				playAudio = true
			end
			if (shakeComponent.getPlayAudio == nil) then
				shakeComponent:doShake({shakeOrigin, shakeLength, shakeOffsetRandom, shakeOffsetSway, swayFrequency, useOldShakeOffsetAmountModifier, smoothingAtEndLength})
			else
				shakeComponent:doShake({shakeOrigin, shakeLength, shakeOffsetRandom, shakeOffsetSway, swayFrequency, useOldShakeOffsetAmountModifier, smoothingAtEndLength, playAudio})
			end
		else
			logger:error("gameplay.util.lua - shakeComponent not found.")
			return false
		end
	else
		logger:error("gameplay.util.lua - camera shake instance not found.")
		return false
	end
	return true
end

function doBasicShakeEffect(shakeOrigin, shakeLength, shakeStrength)
	if not(shakeOrigin) or not(shakeOrigin.x) then	
		logger:error("doBasicShakeEffect shake effect expects position as the first parameter.")
	end
	assert_number(shakeLength)
	assert_number(shakeStrength)

	doShakeEffect(shakeOrigin, shakeLength, VC3(1.0,0.5,1.0)*shakeStrength, VC3(0.1,0.1,0.1)*shakeStrength, VC3(0.011,0.013,0.015), 0.7, 1.0, true)
end

function setCharacterCinematicEnabledImpl(characterInstance, enabled)
	-- Sets all character state machines to Cinematic/default state (if state is supported in the stateMachine)
	
	if characterInstance == nil then
		logger:error("gameplay.util.lua:setCharacterCinematicEnabledImpl - characterInstance param is nil, character instance expected.")
		return;
	end
	
	if enabled == nil then
		logger:error("gameplay.util.lua:setCharacterCinematicEnabledImpl - enabled param is nil, bool expected.")
		return;
	end
	
	local characterComponent = characterInstance:findComponent(gameplay.CharacterComponent);	
	if characterComponent == nil then
		logger:error("gameplay.util.lua:setCharacterCinematicEnabledImpl - Given instance doesn't have CharacterComponent.")
		return;
	end
	
	characterComponent:setCinematicEnabled(enabled);
end

function setCharacterCinematicEnabled(characterInstance)
	-- Sets all character state machines to Cinematic state (if state is supported in the stateMachine)
	setCharacterCinematicEnabledImpl(characterInstance, true);
end

function setCharacterCinematicDisabled(characterInstance)
	-- Sets all character state machines to default state (if state is supported in the stateMachine)
	setCharacterCinematicEnabledImpl(characterInstance, false);
end

function setCharacterCinematicEnabledForAllPlayersImpl(enabled)

	if enabled == nil then
		logger:error("gameplay.util.lua:setCharacterCinematicEnabledForAllPlayersImpl - enabled param is nil, bool expected.")
		return;
	end
	
	local sce = common.CommonUtils.getScene();	
	if not sce then
		logger:error("gameplay.util.lua:setCharacterCinematicEnabledForAllPlayersImpl - Scene is nil");
		return;
	end

	local sceneInstanceManager = sce:getSceneInstanceManager()
	if sceneInstanceManager then
		local characterManager = common.CommonUtils.getSelectedPlayerCharacters()
		for key, playerInstance in pairs(playerCharacters) do
			if playerInstance ~= nil then
				setCharacterCinematicEnabledImpl(playerInstance, enabled);
			end
		end
	end
end

function setCharacterCinematicEnabledForAllPlayers()
	setCharacterCinematicEnabledForAllPlayersImpl(true);
end

function setCharacterCinematicDisabledForAllPlayers()
	setCharacterCinematicEnabledForAllPlayersImpl(false);
end

function startStateCinematicScript(str)
	state:runLuaString(str)	
end

function setPVPMode(value)

	--
	-- NOTE: this is just a fast hack, needs to be called everytime character is switched because character physics are reseted at every switch
	-- Also, friendly fire boolean is carried over a character switch
	--
	if (value ~= true and value ~= false) then
		logger:error("gameplay.util.lua:setPVPMode - parameter not boolean");
		return;
	end
	
	local sce = common.CommonUtils.getScene();	
	if not sce then
		logger:error("gameplay.util.lua:setPVPMode - Scene is nil");
		return;
	end
	
	local sceneInstanceManager = sce:getSceneInstanceManager()
	if sceneInstanceManager then
		local characterManager = common.CommonUtils.getSelectedPlayerCharacters()
		for key, playerInstance in pairs(playerCharacters) do
			if playerInstance ~= nil then
				local playerHittableComp = playerInstance:findComponent(gameplay.hit.HittableComponent)
				if playerHittableComp ~= nil then
					playerHittableComp:setDoFriendlyFire(value)
				end	
				local playerPhysComp = playerInstance:findComponent(trinebase.physics.TrineCharacterPhysicsComponent);
				if playerPhysComp ~= nil then
					-- if (value) then
						-- playerPhysComp:setCollisionGroup(engine.component.AbstractPhysicsComponent.CollisionGroupCharacterPvp)
					-- else
						-- playerPhysComp:setCollisionGroup(engine.component.AbstractPhysicsComponent.CollisionGroupPlayerCharacter)
					-- end
				end
			end
		end
	end
	-- if (value) then
		-- logger:error("PVP Mode = ON")
	-- else
		-- logger:error("PVP Mode = OFF")
	-- end
end

function getLocalInventoryComponent(characterIndex)
	if characterIndex == nil then
		logger:error("util:getLocalInventoryComponent - characterIndex is nil.");
		return nil;
	end
		
	local characterSelectionManager = common.CommonUtils.getCharacterSelectionManager();
	if characterSelectionManager == nil then
		logger:error("util:getLocalInventoryComponent - characterSelectionManager is nil.");
		return nil;
	end
	
	local characterInstance = characterSelectionManager:getLocalCharacterInstanceByIndex(characterIndex);
	if characterInstance == nil then
		-- NOTE: This is actually allowed, since in single player there is only one character
		--logger:error("util:getLocalInventoryComponent - characterInstance is nil with given characterIndex: " .. tostring(characterIndex));
		return nil;	
	end
	
	return characterInstance:findComponent(gameplay.item.InventoryComponent);
end

-- Player could've gone past a skill chest. Lets give him/her the skill in the beginning of next mission.
function giveMissingSkills()
	-- Not in use for this project
end