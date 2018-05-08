--
-- Properties
--
gamebase.state.scene.GameBaseGameScene.addProperty(engine.base.TypeBool, "CameraCreated", false, "", "Is game camera created.");

--------------------------------------------------------------------------------------------------------------------------------------
--
-- CHEAT SKILL GIVING (These functions should be removed from the final release, atm we don't have inventory)
--

function allowCheatSkills()
	-- HACK: Give all skills
	-- NOTE: Remove also hacks from: source\fb\gamebase\state\State.cpp (void State::startInstanceRoot())
	local hack_giveAllSkills = false;
	--if platformModule:isPlatformWiiU() then
	--	-- HACK: Always enabled on WiiU
	--	hack_giveAllSkills = true;
	--end

	-- Don't allow on final release
	--if FB_BUILD ~= "FB_FINAL_RELEASE" then
	--	hack_giveAllSkills = false;
	--end

	return hack_giveAllSkills;
end

function addCheatSkillsWizard(inventoryComponent, missionID)
	if allowCheatSkills() then
		inventoryComponent:setItemWithEvent("Floating", 1)
		inventoryComponent:setItemWithEvent("Conjuring", 1)
		inventoryComponent:setItemWithEvent("Plank", 1)
		inventoryComponent:setItemWithEvent("GlassObjects", 1)
		inventoryComponent:setItemWithEvent("ConjuredObjectsAmount", 4)
		inventoryComponent:setItemWithEvent("KeepKinetic", 1)
		inventoryComponent:setItemWithEvent("MonsterLevitation", 1)
		inventoryComponent:setItemWithEvent("Magnetization", 1)
		inventoryComponent:setItemWithEvent("TrapAI", 1)
	end
end

function addCheatSkillsThief(inventoryComponent, missionID)
	if allowCheatSkills() then
		inventoryComponent:setItemWithEvent("FireBow", 2)
		inventoryComponent:setItemWithEvent("Rope", 1)
		inventoryComponent:setItemWithEvent("MultipleArrows", 3)
		inventoryComponent:setItemWithEvent("TimeSlow", 2)
		inventoryComponent:setItemWithEvent("Vanish", 2)
		inventoryComponent:setItemWithEvent("IceBow", 2)
		inventoryComponent:setItemWithEvent("StealthDisguise", 1)
	end
end

function addCheatSkillsWarrior(inventoryComponent, missionID)
	if allowCheatSkills() then
		inventoryComponent:setItemWithEvent("Sword", 1)
		inventoryComponent:setItemWithEvent("Hammer", 3)
		inventoryComponent:setItemWithEvent("HammerThrow", 1)
		inventoryComponent:setItemWithEvent("HammerExplosion", 1)
		inventoryComponent:setItemWithEvent("Shield", 1)
		inventoryComponent:setItemWithEvent("Charge", 2)
		inventoryComponent:setItemWithEvent("FrostShield", 1)
		inventoryComponent:setItemWithEvent("FireSword", 1)
		inventoryComponent:setItemWithEvent("Gliding", 1)
		inventoryComponent:setItemWithEvent("MagneticShield", 1)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------


	
function gamebase.state.scene.GameBaseGameScene:started()
	local createCharacters = true;	
	if common.CommonUtils.getMainMenuPlayable() then
		-- nop
	else	
		-- No characters in main menu
		if string.find(state:getCurrentMapFile(), common.CommonUtils.getMainMenuMissionID()) then
			createCharacters = false;
		end
	end
	
	if not createCharacters then
		return;
	end
	
	if(not self:getCharactersCreated())
	then
		self:createCharactersForClient(0);
		self:createCharactersForClient(1);
		self:createCharactersForClient(2);
	end
	if(not self:getCameraCreated())
	then
		self:createCamera();
	end
end

function gamebase.state.scene.GameBaseGameScene:createCamera()

	function dummyInit(obj, params) 
		-- nop
	end

	-- camera shake
	local shakeDynConType = typeManager:findTypeByName("ShakeEntityOffsetDynamicConnectorComponent")
	local shakeSys = sceneInstanceManager:findInstanceByName("cameraShake")
	if (shakeSys) then
		shakeSys:findComponentByExactType(shakeDynConType:getUnifiedHandle()):setConnect(false)
		shakeSys:findComponentByExactType(shakeDynConType:getUnifiedHandle()):setConnect(true)	
	else
		function initShake(obj, params)
			obj:setName("cameraShake")
			obj:findComponentByExactType(shakeDynConType:getUnifiedHandle()):setConnect(false)
			obj:findComponentByExactType(shakeDynConType:getUnifiedHandle()):setConnect(true)
		end
		local shakeType = typeManager:findTypeByName("ShakeEntity");
		sceneInstanceManager:createNewInstance(shakeType:getUnifiedHandle(), initShake, nil)
	end

	-- player character averaged position tracker component. (used by the camera system)
	function initAvgTracker(obj, params)
		obj:setName("averagedPlayerTracker") 
		local spawnMan = common.CommonUtils.getGameSpawnManager();
		if (spawnMan) then
			local missionStartPos = spawnMan:getMissionStartSpawnPosition(true)
			if not state:inEmptyMap() and not missionModule:isTestMissionId(common.CommonUtils.getCurrentMissionID()) then
				if (missionStartPos.x == 0 and missionStartPos.y == 0 and missionStartPos.z == 0) then
					logger:error("Spawn manager returned zero mission start position. Curren mission ID was: \"" .. common.CommonUtils.getCurrentMissionID() .. "\". Editor map was: \"" .. state:getCurrentMapFile() .. "\".")
				end
			end
			obj:findComponent(engine.component.TransformComponent):setPosition(missionStartPos)
		else
			logger:error("Spawn manager instance was not found.");
		end
		scene:setAveragedCharacterTrackerGUID(obj:getGuid());
	end
	local avgTrackerType = typeManager:findTypeByName("TrineAveragedPlayerTrackerEntity");
	
	sceneInstanceManager:createNewInstance(avgTrackerType:getUnifiedHandle(), initAvgTracker, nil)
	
	self:setCameraCreated(true);  
end

function gamebase.state.scene.GameBaseGameScene:createCharactersForClient(clientIndex)

	if state:isEditorState() then
		return;
	end
	
	local missionManager = common.CommonUtils.getMissionManager();
	
	local createCharacters = true;	
	if common.CommonUtils.getMainMenuPlayable() then
		-- nop
	else	
		-- No characters in main menu
		local missionID = missionManager:getCurrentMissionID();
		if missionID == common.CommonUtils.getMainMenuMissionID() then
			createCharacters = false;
		end
	end
	
	if not createCharacters then
		return;
	end

	function initCharacter(obj, params)
		obj:findComponent(engine.component.AbstractNetSyncComponent):setMasterPropagateFromOthers(false);
		obj:findComponent(engine.component.AbstractNetSyncComponent):setMasterResetOnSleep(false);
		obj:findComponent(engine.component.AbstractNetSyncComponent):setMasterDefaultToLocal(false);
		obj:findComponent(engine.component.AbstractNetSyncComponent):forceMasterToClient(clientIndex);
		if params.name == "wizard" then
			obj:findComponent(input.InputComponent):setBindSetNumber(0);
		else
			obj:findComponent(input.InputComponent):setBindSetNumber(input.InputComponent.getNoBindSetNumber());
		end
		obj:findComponent(trinebase.gameplay.player.TrineCharacterSelectionComponent):setClientIndex(clientIndex)
		obj:findComponent(trinebase.gameplay.player.TrineCharacterSelectionComponent):setCharacterID(params.character)
		obj:setName(params.name.. clientIndex);

		-- Make sure health is set to full
		local healthComponent = obj:findComponent(gameplay.damage.HealthComponent)
		healthComponent:setHealth( healthComponent:getMaxHealth())

		obj:findComponent(engine.component.AbstractModelComponent):setAlternativeTexture(params.texture)
	end

	local bookLevel = tostring(missionManager:getCurrentMissionID()):find("book") ~= nil

	local wizardType = typeManager:findTypeByName(bookLevel and "BookWizardCharacterEntityInLimbo" or "WizardCharacterEntityInLimbo");
	sceneInstanceManager:createNewInstance(wizardType:getUnifiedHandle(), initCharacter, { missionID = missionID, name = "wizard", texture = 0, character = trinebase.gameplay.TrineCharacterWizard });
	
	local thiefType = typeManager:findTypeByName(bookLevel and "BookThiefCharacterEntityInLimbo" or "ThiefCharacterEntityInLimbo");
	sceneInstanceManager:createNewInstance(thiefType:getUnifiedHandle(), initCharacter, { missionID = missionID, name = "thief", texture = 0, character = trinebase.gameplay.TrineCharacterThief });

	local warriorType = typeManager:findTypeByName(bookLevel and "BookWarriorCharacterEntityInLimbo" or "WarriorCharacterEntityInLimbo");
	sceneInstanceManager:createNewInstance(warriorType:getUnifiedHandle(), initCharacter, { missionID = missionID, name = "warrior", texture = 0, character = trinebase.gameplay.TrineCharacterWarrior });

	if gameModule == nil then
		logger:error("GameScene.lua:createCharactersForClient - No gameModule found.");
	end
	
	if common.CommonUtils.getUnlimitedMultiplayerEnabled()
		or missionManager:getGhostMultiplayerEnabled()
		-- always add ghost characters in main menu (fixes problems when unlimited mode is switched on the fly)
		or common.CommonUtils.isMainMenuMission(missionManager:getCurrentMissionID())
	then
		local params = { missionID = missionID, name = nil, texture = nil, character = nil }

		params.name = "wizardGhostOne"
		params.texture = 1
		params.character = trinebase.gameplay.TrineCharacterWizardGhostOne
		sceneInstanceManager:createNewInstance(wizardType:getUnifiedHandle(), initCharacter, params)
		
		params.name = "wizardGhostTwo"
		params.texture = 2
		params.character = trinebase.gameplay.TrineCharacterWizardGhostTwo
		sceneInstanceManager:createNewInstance(wizardType:getUnifiedHandle(), initCharacter, params)

		params.name = "thiefGhostOne"
		params.texture = 1
		params.character = trinebase.gameplay.TrineCharacterThiefGhostOne
		sceneInstanceManager:createNewInstance(thiefType:getUnifiedHandle(), initCharacter, params)
		
		params.name = "thiefGhostTwo"
		params.texture = 2
		params.character = trinebase.gameplay.TrineCharacterThiefGhostTwo
		sceneInstanceManager:createNewInstance(thiefType:getUnifiedHandle(), initCharacter, params)
		
		params.name = "warriorGhostOne"
		params.texture = 1
		params.character = trinebase.gameplay.TrineCharacterWarriorGhostOne
		sceneInstanceManager:createNewInstance(warriorType:getUnifiedHandle(), initCharacter, params)
		
		params.name = "warriorGhostTwo"
		params.texture = 2
		params.character = trinebase.gameplay.TrineCharacterWarriorGhostTwo
		sceneInstanceManager:createNewInstance(warriorType:getUnifiedHandle(), initCharacter, params)
	end
	
	self:setCharactersCreated(true);
end


-- a hacky lua function for scene context, making it a bit easier to access state manager stuff
-- this is internally used by the get/setStateManagerPropertyValue functions.
_G.getStateManagerComponent = function(managerName, managerComponentType)

	-- NOTE: If we are building maps, suppress some errors
	local reportErrors = true;
	if app:isBuildingMaps() then
		reportErrors = false;
	end
	
	-- parameter check
	if type(managerName) ~= "string" then
		logger:error("Expected a state manager name as the first parameter.");
		return nil
	end
	if type(managerComponentType) ~= "string" then
		logger:error("Expected a component type name as the second parameter.");
		return nil
	end
	
	-- get the state instance manager, find the manager by given name
	local stateInstMan = instanceManager:getTopmostInstanceRoot():getInstanceManager()
	if not(stateInstMan) then
		logger:error("Failed to get state instance manager.");
		return nil
	end
	local managerInstance = stateInstMan:findInstanceByName(managerName)
	if not(managerInstance) then
		if reportErrors then
			logger:error("Failed to find manager with given name \"".. managerName .."\".");
		end
		return nil
	end
	
	-- find the requested component type of given type name
	local typ = typeManager:findTypeByName(managerComponentType)
	if (not(typ)) then
		logger:error("Failed to find a type with given name \"".. managerComponentType .."\".");
		return nil
	end
	
	local typeUH = typ:getUnifiedHandle()
	
	-- then find the actual component from the instance
	local comp = managerInstance:findComponentByExactType(typeUH)
	if not(comp) then
		logger:error("The manager \"" .. managerName .. "\" did not have the requested component \"".. managerComponentType .."\".");
		return nil
	end
	
	return comp
end

-- a hacky lua function for scene context, making it a bit easier to set/get the state manager property values
-- recommended usage: setStateManagerPropertyValue([[stateManagerInstName]], [[ComponentTypeName]], [[PropertyName]], value)
-- notice that [[string]] notation is preferred over "string", as you are possibly using this from a CustomLuaExpression component or such.
-- and they tend to have nasty bugs regarding "doublequotes". so, use the doublebrackets to get past that (or single quotes would work too)
_G.setStateManagerPropertyValue = function(managerName, managerComponentType, propertyName, value)

	-- NOTE: If we are building maps, suppress some errors
	local reportErrors = true;
	if app:isBuildingMaps() then
		reportErrors = false;
	end
	
	local comp = getStateManagerComponent(managerName, managerComponentType);
	if (not(comp)) then
		if reportErrors then
			logger:error("Failed to find the state manager \"" .. managerName .. "\" or its component \"".. managerComponentType .."\". (1)");
		end
		return
	end

	-- parameter check
	if type(propertyName) ~= "string" then
		logger:error("Expected a property name as the third parameter. (1)");
		return
	end
	if not(type(value)) then
		logger:error("Expected a value as the fourth parameter. (1)");
		return
	end

	-- and finally, find the property and do something with that
	local propIndex = comp:findPropertyIndexByName(propertyName)
	if propIndex == -1 then
		logger:error("The component \"" .. managerComponentType .. "\" did not have a property by given name \"".. propertyName .."\". (1)");
		return
	end
	
	comp:setPropertyValue(propIndex, value)
end

-- a hacky lua function for scene context, making it a bit easier to set/get the state manager property values
-- recommended usage: setStateManagerPropertyValue([[stateManagerInstName]], [[ComponentTypeName]], [[PropertyName]], value)
-- notice that [[string]] notation is preferred over "string", as you are possibly using this from a CustomLuaExpression component or such.
-- and they tend to have nasty bugs regarding "doublequotes". so, use the doublebrackets to get past that (or single quotes would work too)
_G.getStateManagerPropertyValue = function(managerName, managerComponentType, propertyName)

	-- NOTE: If we are building maps, suppress some errors
	local reportErrors = true;
	if app:isBuildingMaps() then
		reportErrors = false;
	end
	
	local comp = getStateManagerComponent(managerName, managerComponentType);
	if (not(comp)) then
		if reportErrors then
			logger:error("Failed to find the state manager \"" .. managerName .. "\" or its component \"".. managerComponentType .."\". (2)");
		end
		return nil
	end

	-- parameter check
	if type(propertyName) ~= "string" then
		logger:error("Expected a property name as the third parameter. (2)");
		return nil
	end

	-- and finally, find the property and do something with that
	local propIndex = comp:findPropertyIndexByName(propertyName)
	if propIndex == -1 then
		logger:error("The component \"" .. managerComponentType .. "\" did not have a property by given name \"".. propertyName .."\". (2)");
		return nil
	end
	
	local propValue = comp:getPropertyValue(propIndex)
	return propValue
end

-- same as setStateManagerPropertyValue, but gets run only while in game (not in editor)
_G.setGameStateManagerPropertyValue = function(managerName, managerComponentType, propertyName, value)
	if (not(state:isEditorState())) then
		setStateManagerPropertyValue(managerName, managerComponentType, propertyName, value)
	end
end

-- same as getStateManagerPropertyValue, but gets run only while in game (not in editor)
-- notice, this returns nil in editor!
_G.getGameStateManagerPropertyValue = function(managerName, managerComponentType, propertyName)
	if (not(state:isEditorState())) then
		return getStateManagerPropertyValue(managerName, managerComponentType, propertyName)
	else
		return nil
	end
end
