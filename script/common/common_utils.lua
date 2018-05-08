local moduleName = "common.CommonUtils"
module(moduleName, package.seeall)
debug.ReloadScripts.allowReload(moduleName)

require "cinematic.CinematicUtil"

local thisModule = _M

declareManualReload(thisModule, [[cameraUH]])
declareManualReload(thisModule, [[allowLogosOnStart]])
declareManualReload(thisModule, [[gameMaxLevelExp]])
declareManualReload(thisModule, [[gameMaxMonsterExp]])
cameraUH = UH_NONE
allowLogosOnStart = true

declareManualReload(thisModule, [[globalSpawnerSpawnNextAllowedTime]])
globalSpawnerSpawnNextAllowedTime = 0;

-------------------------------------------------------------------------------------------------

-- Level stat info
declareManualReload(thisModule, [[levelStatInfo]])
levelStatInfo =
{
	["01_tutorial"]						= { campaign = "original", maxLevelExp = 0, maxEnemyExp = 0 }
	,["02_add_mission_name_here"]		= { campaign = "original", maxLevelExp = 0, maxEnemyExp = 0 }
}

gameMaxLevelExp = 1000
gameMaxMonsterExp = 0

function getGameMaxLevelExp()
	return gameMaxLevelExp;
end

function getGameMaxMonsterExp()
	return gameMaxMonsterExp;
end

function getMissionUpperCaseIDName(paramMissionID)
	assert_string(paramMissionID);
	
	local missionID = paramMissionID;
	
	-- HACK: If missionID is "", act as mainmenu (as it probably usually is mainmenu which we are loading)
	if missionID == "" or string.len(missionID) <= 1 then
		logger:warning("CommontUtils:getMissionUpperCaseIDName - paramMissionID is empty or invalid string: \"" .. missionID .. "\". Using mainmenu default missionID");
		missionID = "mainmenu";
	end
	
	local upperMissionId = "";
	
	-- FIXME: proper "lower_case" -> "LowerCase" mission name conversion!
	if (missionID == "mainmenu") then upperMissionId = "MainMenu" end
	if (missionID == "anna_02_tutorial_lily") then upperMissionId = "Anna02TutorialLily" end
	if (missionID == "anna_03_tutorial_shadwen") then upperMissionId = "Anna03TutorialShadwen" end
	if (missionID == "anna_04_tutorial_lily_and_shadwen") then upperMissionId = "Anna04TutorialLilyAndShadwen" end
	if (missionID == "kim_01_castle_wall_cliff_guard_house") then upperMissionId = "Kim01CastleWallCliffGuardHouse" end
	if (missionID == "anna_01_castle_wall_city_walls") then upperMissionId = "Anna01CastleWallCityWalls" end
	if (missionID == "sami_02_prisons_prisons") then upperMissionId = "Sami02PrisonsPrisons" end
	if (missionID == "esa_01_prisons_guard_house") then upperMissionId = "Esa01PrisonsGuardHouse" end
	if (missionID == "ville_02_poor_district_poor_housing") then upperMissionId = "Ville02PoorDistrictPoorHousing" end
	if (missionID == "sami_01_poor_district_poor_courtyard") then upperMissionId = "Sami01PoorDistrictPoorCourtyard" end
	if (missionID == "mikko_02_poor_district_poor_square") then upperMissionId = "Mikko02PoorDistrictPoorSquare" end
	if (missionID == "kim_03_merchants_square_and_docks_port") then upperMissionId = "Kim03MerchantsSquareAndDocksPort" end
	if (missionID == "kim_02_merchants_square_and_docks_market_place") then upperMissionId = "Kim02MerchantsSquareAndDocksMarketPlace" end
	if (missionID == "sami_03_noble_district") then upperMissionId = "Sami03NobleDistrict" end
	if (missionID == "esa_03_castle_courtyard_main_gate") then upperMissionId = "Esa03CastleCourtyardMainGate" end
	if (missionID == "ville_03_inside_the_castle") then upperMissionId = "Ville03InsideTheCastle" end
	if (missionID == "ville_03_inside_the_castle_reversed") then upperMissionId = "Ville03InsideTheCastleReversed" end
	if (missionID == "esa_03_castle_courtyard_main_gate_reversed") then upperMissionId = "Esa03CastleCourtyardMainGateReversed" end
	if (missionID == "sami_03_noble_district_reversed") then upperMissionId = "Sami03NobleDistrictReversed" end
	if (missionID == "kim_02_merchants_square_and_docks_market_place_reversed") then upperMissionId = "Kim02MerchantsSquareAndDocksMarketPlaceReversed" end
	if (missionID == "kim_03_merchants_square_and_docks_port_reversed") then upperMissionId = "Kim03MerchantsSquareAndDocksPortReversed" end
	if (missionID == "mikko_02_poor_district_poor_square_reversed") then upperMissionId = "Mikko02PoorDistrictPoorSquareReversed" end
	if (missionID == "sami_01_poor_district_poor_courtyard_reversed") then upperMissionId = "Sami01PoorDistrictPoorCourtyardReversed" end
	if (missionID == "ville_02_poor_district_poor_housing_reversed") then upperMissionId = "Ville02PoorDistrictPoorHousingReversed" end
	if (missionID == "esa_01_prisons_guard_house_reversed") then upperMissionId = "Esa01PrisonsGuardHouseReversed" end
	if (missionID == "sami_02_prisons_prisons_reversed") then upperMissionId = "Sami02PrisonsPrisonsReversed" end
	if (missionID == "anna_01_castle_wall_city_walls_reversed") then upperMissionId = "Anna01CastleWallCityWallsReversed" end
	if (missionID == "kim_01_castle_wall_cliff_guard_house_reversed") then upperMissionId = "Kim01CastleWallCliffGuardHouseReversed" end
	if (missionID == "anna_04_tutorial_lily_and_shadwen_reversed") then upperMissionId = "Anna04TutorialLilyAndShadwenReversed" end
	if (missionID == "anna_03_tutorial_shadwen_reversed") then upperMissionId = "Anna03TutorialShadwenReversed" end

	if string.len(upperMissionId) == 0 then
		logger:error("CommontUtils:getMissionUpperCaseIDName - Couldn't find upper case name for mission: " .. missionID);
	end
	
	return upperMissionId;
end

-------------------------------------------------------------------------------------------------

function uninitScene()
	cameraUH = UH_NONE
end

-------------------------------------------------------------------------------------------------
--
-- Mission name cfg
--

function getFirstMissionIDName()
	return missionModule:getMissionIDByIndexInCampaign(0,"original");
end

function getSecondMissionIDName()
	-- Trine 3
	return "02_journey_to_astral_academy";
end

function getTutorialMissionIDName01()
	return "01_tutorial"
end

function getTutorialMissionIDName02()
	return "02_tutorial"
end

function getTutorialMissionIDName03()
	return "03_tutorial"
end

function isTutorialMission(missionId)
	if missionId == nil then		
		logger:error("CommontUtils:isTutorialMission - missionId param is nil.");
		return false;
	end
	
	return string.find(missionId, getTutorialMissionIDName01()) or string.find(missionId, getTutorialMissionIDName02()) or string.find(missionId, getTutorialMissionIDName03());
end

function getMaxLevelExp(missionID)
	assert_string(missionID);
	
	local info = levelStatInfo[missionID];
	
	if info == nil then
		return 0;
	end
	
	return info.maxLevelExp;
end

function getMaxEnemyExp(missionID)
	assert_string(missionID);
	
	local info = levelStatInfo[missionID];
	
	if info == nil then
		return 0;
	end
	
	return info.maxEnemyExp;
end

function getTotalMaxLevelExp(campaignOpt)
	local totalLevelExp = 0;
	
	for k, v in pairs(levelStatInfo) do
		if campaignOpt == nil or campaignOpt == v.campaign then
			totalLevelExp = totalLevelExp + v.maxLevelExp;
		end
	end
	
	return totalLevelExp;
end

function getTotalMaxEnemyExp(campaignOpt)
	local totalEnemyExp = 0;
	
	for k, v in pairs(levelStatInfo) do
		if campaignOpt == nil or campaignOpt == v.campaign then
			totalEnemyExp = totalEnemyExp + v.maxEnemyExp;
		end
	end
	
	return totalEnemyExp;
end

function changeMissionIDToDemoMissionID(missionID)
	assert_string(missionID);	
	
	-- Frozenbyte super DRM: Fail-safe to ensure none of these specific final version maps are allowed in various demo builds.
	-- NOTE; This should never happen, but just in case someone manages to hack past some demo trigger and/or add the full game levels to demo builds
	-- See also: bool State::loadMission(const char *filename)
	if gameBaseApplicationModule:getDemo() then
		if missionID == "mainmenu" then
			-- All ok
			return missionID;
		end
		
		if gameBaseApplicationModule:getDemoExpo() then
			--
			-- Expo demo
			--
			if missionID == "01_tutorial" then
				-- All ok
				return missionID;
			else
				return "mainmenu";
			end
		elseif gameBaseApplicationModule:getDemoStage() then
			--
			-- Stage demo
			--
			if missionID == "01_tutorial" then
				-- All ok
				return missionID;
			else
				return "mainmenu";
			end
		else
			--
			-- Normal demo
			--
			if missionID == "01_tutorial" then
				-- All ok
				return missionID;
			else
				return "mainmenu";
			end
		end
	end
	
	return missionID;
end

-- Called by pause_menu.lua
function isReturnToCheckpointButtonDisabledForMissionID(missionID)
	assert_string(missionID);
	
	if(missionID == "add_mission_name_here") then return true end
	
	return false;
end

-- Called by game_over_menu.lua
function hasRestartLevelButton(missionID)
	assert_string(missionID);
	
	if(missionID == "add_mission_name_here") then return true end
	
	return false;
end

function isMissionUnlockedAlways(missionID)
	assert_string(missionID);
	if gameBaseApplicationModule:getDemo() then
		if isTutorialMission(missionID) or missionID == "02_journey_to_astral_academy" then
			return true;
		end
	end
	
	return false;
end

function shouldIgnoreChangeToNextMission(missionID)
	assert_string(missionID);
	if gameBaseApplicationModule:getDemoExpo() then
		-- the last mission, don't get out from it (we handle this differently)
		if missionID == "02_journey_to_astral_academy" then
			return true;
		end
	elseif gameBaseApplicationModule:getDemoStage() then
		-- the last mission, don't get out from it (we handle this differently)
		if missionID == "02_add_mission_name_here" then
			return true;
		end
	end
	
	return false;
end

-------------------------------------------------------------------------------------------------
--
-- Logos on start
--

function setAllowLogosOnStart(enabled)
	assert_boolean(enabled)
	allowLogosOnStart = enabled;
end

function getAllowLogosOnStart()
	return allowLogosOnStart;
end

-------------------------------------------------------------------------------------------------
--
-- Scene load stuff
--

function startSceneLoadedDelayed(delay)
	state:runLuaStringWithDelay("common.CommonUtils.doSceneLoadedDelayed()", delay);
end

function doSceneLoadedDelayed()
	if common.CommonUtils.isCurrentMissionMainMenuMission() then
		-- Delay scene load until logos etc. has gone away
		if cinematic.CinematicUtil.isActive() or state:isCinematicRunning() then
			state:runLuaStringWithDelay("common.CommonUtils.doSceneLoadedDelayed()", 200)
			return;
		end
	end
	
	common.CommonUtils.doSceneLoaded();
end

function doSceneLoaded()
	if state:isEditorState() then
		return;
	end

	-- Do some magic...	
	
	-- See if this was started with "start at position" in the editor
	local startAtPositionUsed = false
	local root = instanceManager:getTopmostInstanceRoot()
	-- HACK: assumes trine here!
	local spawnMan = common.CommonUtils.getGameSpawnManager();
	if spawnMan then 
		startAtPositionUsed = spawnMan:getInitialSpawnPosEnabled()
	end
	
	if (startAtPositionUsed) then
		-- TODO: Fade immediately to black and then smoothly back
	else
		--search for sceneLoadTriggers
		local sceneLoadTriggerFound = false
		local sceneLoadTriggerEntityType = typeManager:findTypeByName("SceneLoadTriggerEntity")
		if sceneLoadTriggerEntityType then
			local root = instanceManager:getTopmostInstanceRoot()
			local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilter(root, "0,All", 99999, false)
			local obj = resultIterator:next()
			while (obj) do
				if obj:getType() == sceneLoadTriggerEntityType:getUnifiedHandle() then
					local sceneLoadTrigger = obj:findComponent(gameplay.trigger.SceneLoadTriggerComponent)
					if sceneLoadTrigger then
						if not sceneLoadTrigger:getTriggered() then
							sceneLoadTrigger:sceneLoaded()
						end
						sceneLoadTriggerFound = true
					end
				end
				obj = resultIterator:next()
			end
		end

		if sceneLoadTriggerFound == false then
			-- TODO: Fade immediately to black and then smoothly back
		end
	end
end

-------------------------------------------------------------------------------------------------
--
-- Main menu stuff
--

function getCreditsMenuBGImage()
	return "data/gui/menu/credits/credits_bg.png";
end

function getPoemUnlocksMenuBGImage()
	return nil;
end

function getConceptArtMenuBGImage()
	return nil;
end

function makeGameCompleted()
	if gameModule == nil then
		logger:error("CommontUtils:makeGameCompleted - gameModule is nil, cannot determine anything. Returning crap.");
	end
	
	if not gameModule:getGameCompleted() then
		gameModule:setGameCompleted(true);
	end
end

function isGameCompleted()
	if gameModule == nil then
		logger:error("CommontUtils:isGameCompleted - gameModule is nil, cannot determine anything. Returning crap.");
	end
	
	return gameModule:getGameCompleted();
end

function setLastMissionCanBeContinued(enabled)
	if missionModule == nil then
		logger:error("CommontUtils:setLastMissionCanBeContinued - missionModule is nil, cannot determine anything. Returning crap.");
	end
	
	if missionModule:getLastMissionCanBeContinued() ~= enabled then
		missionModule:setLastMissionCanBeContinued(enabled);
	end
end

function getLastMissionCanBeContinued()
	if missionModule == nil then
		logger:error("CommontUtils:getLastMissionCanBeContinued - missionModule is nil, cannot determine anything. Returning crap.");
	end
	
	return missionModule:getLastMissionCanBeContinued();
end

function isLatestSaveAllowed()
	local latestSaveMissionId = common.CommonUtils.getLatestSaveMissionId()
	if(not isMissionLoadable(latestSaveMissionId)) then
		return false
	end
	if(not missionManager:isMissionUnlocked(latestSaveMissionId)) then
		return false
	end
	return common.CommonUtils.getLastMissionCanBeContinued();
end

function getMainMenuPlayable()
	if missionModule == nil then
		logger:error("CommontUtils:getMainMenuPlayable - missionModule is nil, cannot determine anything. Returning crap.");
	end
		
	return missionModule:getMainMenuPlayable();
end

function getLevelSelectionPlayable()
	-- NOTE: No playable level selection for mods.
	if (state:isModEnabled()) then
		return false
	end
	
	if missionModule == nil then
		logger:error("CommontUtils:getLevelSelectionPlayable - missionModule is nil, cannot determine anything. Returning crap.");
		return false
	end
	
	-- HACK: Only enable this on PC for now.
	if platformModule == nil or not platformModule:isPlatformTypePC() then
		return false
	end
		
	return missionModule:getLevelSelectionPlayable();
end

function isMainMenuMission(missionID)
	assert_string(missionID)
	
	if missionModule == nil then
		logger:error("CommontUtils:isMainMenuMission - missionModule is nil, cannot determine anything. Returning crap.");
		return false
	end
	
	return missionModule:isMainMenuMission(missionID);
end

function isCurrentMissionMainMenuMission(suppressErrors)
	assert_boolean_or_nil(suppressErrors) -- if instance managers are not found we are clearly not in the main menu, so just ignore the errors and pass false
	if(suppressErrors == nil) then
		suppressErrors = false
	end
	
	-- NOTE: If we are building maps, suppress errors
	if app:isBuildingMaps() then
		suppressErrors = true;
	end

	local missionManager = getMissionManager(suppressErrors);
	if missionManager == nil then
		if not suppressErrors then
			logger:error("CommontUtils:isCurrentMissionMainMenuMission - Mission manager is nil, cannot determine anything.");
		end
		return false;
	end
	
	local currentMissionID = missionManager:getCurrentMissionID();
	if string.len(currentMissionID) <= 0 then
		return false;
	end
	
	return isMainMenuMission(currentMissionID);
end

function getMainMenuMissionID()
	if missionModule == nil then
		logger:error("CommontUtils:getMainMenuMissionID - missionModule is nil, cannot determine anything. Returning crap.");
	end

	return missionModule:getMainMenuMissionID();
end

function getCurrentMainMenuMissionFilename()
	if missionModule == nil then
		logger:error("CommontUtils:getCurrentMainMenuMissionFilename - missionModule is nil, cannot determine anything. Returning crap.");
	end
	
	local mainMenuMissionID = getMainMenuMissionID();
	return "data/mission/" .. mainMenuMissionID .. "/" .. mainMenuMissionID .. ".fbe";
end

function getCurrentMainMenuMissionFilenameBuild()
	if missionModule == nil then
		logger:error("CommontUtils:getCurrentMainMenuMissionFilenameBuild - missionModule is nil, cannot determine anything. Returning crap.");
	end

	local mainMenuMissionID = getMainMenuMissionID();
	return "builds/common/data/mission/" .. mainMenuMissionID .. "/" .. mainMenuMissionID .. ".fbe";
end

function getMainMenuWindowStateName()
	return [[mainMenu]];
end

function getMainMenuPreWindowStateName()
	return [[mainMenuPre]];
end

function getCurrentMissionID()
	local missionManager = common.CommonUtils.getMissionManager();
	if missionManager == nil then
		logger:warning("CommontUtils:getCurrentMissionID - Mission manager is nil, returning empty string.");
		return "";
	end
	
	return missionManager:getCurrentMissionID();
end

function getCurrentMissionNumber()
	local missionManager = common.CommonUtils.getMissionManager();
	if missionManager == nil then
		logger:warning("CommontUtils:getCurrentMissionID - Mission manager is nil, returning 1.");
		return 1;
	end
	
	return missionManager:getMissionNumber();
end

function doesMissionExistWithMissionID(missionID)
	assert_string(missionID)
	
	if missionModule == nil then
		logger:error("CommontUtils:doesMissionExistWithMissionID - missionModule is nil, cannot determine anything. Returning crap.");
		return false;
	end
	
	return missionModule:doesMissionExistWithMissionID(missionID);
end

function getLatestSaveMissionId()
	local missionFileName = missionManager:getLatestSaveMissionFilename()
	-- assuming ".../mission/missionid/..."
	local splitted = split_compat(missionFileName, "/")
	local missionId = "missing"
	-- hacky parsing of mission id from the mission file...
	for i=1,#splitted do
		if (splitted[i] == "mission") then
			missionId = splitted[i+1]
			break
		end
	end
	return missionId
end

function isMissionLoadable(missionId)
	return true
end

-------------------------------------------------------------------------------------------------
	
function isConsoleAllowed()
	local gameConsoleAllowed = true;
	
	if FB_BUILD == "FB_FINAL_RELEASE" then
		if platformModule:isPlatformTypePC() then
			gameConsoleAllowed = gameBaseApplicationModule:getGameConsoleEnabledOnFinalReleasePC();
		elseif platformModule:isPlatformTypeConsole() then
			gameConsoleAllowed = gameBaseApplicationModule:getGameConsoleEnabledOnFinalReleaseConsole();
		elseif platformModule:isPlatformTypeMobile() then
			gameConsoleAllowed = gameBaseApplicationModule:getGameConsoleEnabledOnFinalReleaseMobile();
		else
			gameConsoleAllowed = false;
			logger:error("isConsoleAllowed - Invalid platform, please handle me.");
		end
	end
	
	return gameConsoleAllowed;
end

-------------------------------------------------------------------------------------------------

function isInGameGUIAllowed()
	-- DemoExpo: allow in game GUI always
	if gameBaseApplicationModule:getDemoExpo() then
		return true;
	elseif gameBaseApplicationModule:getDemoStage() then
		-- Normal behaviour
		return false;
	end

	local inMainMenu = isCurrentMissionMainMenuMission();
	
	if inMainMenu then
		return false;
	end
	
	return true;
end

-------------------------------------------------------------------------------------------------
--
-- Some commonly used helper scripts
--

function getScene()
	if gameScene ~= nil then
		return gameScene;
	end
	
	if scene ~= nil then
		return scene;
	end

	-- Unnecessary error (Caller should handle this)
	--logger:error("common_utils:getScene - Cannot find Scene.");
	
	return nil;
end

function getSceneInstanceManager()
	
	local sce = getScene();
	if sce ~= nil then
		local instanceManager = sce:getSceneInstanceManager();
		if instanceManager then
			return instanceManager;
		end
	end
	
	if sceneInstanceManager ~= nil then
		return sceneInstanceManager;
	end

	-- Unnecessary error (Caller should handle this)
	--logger:error("common_utils:getSceneInstanceManager - Cannot find SceneInstanceManager.");
	return nil;
end

function getStateInstanceManager()
	return instanceManager
end

function getUpgradeManager()
	local sceneInstanceManager = getSceneInstanceManager()
	if sceneInstanceManager then
		return common.CommonUtils.getTrineUpgradeManager()
	end
end


function getTypeManager()
	
	if typeManager ~= nil then
		return typeManager;
	end

	-- Unnecessary error (Caller should handle this)
	--logger:error("common_utils:getTypeManager - Cannot find TypeManager.");
	return nil;
end

function getSceneInstanceByUH(uh)
	local instMa = getSceneInstanceManager();
	if instMa == nil then
		return nil;
	end	
	return instMa:getInstanceByUH(uh);
end

function getFinalOwnerInstance(obj)
	if obj:isInherited(engine.base.ComponentBase.getStaticObjectClass()) and obj.getFinalOwner then
		return obj:getFinalOwner();
	else
		return obj;
	end
end

function getEventQueue()
	
	if eventQueue ~= nil then
		return eventQueue;
	end

	logger:error("common_utils:getEventQueue - Cannot find eventQueue.");
	return nil;
end

function getInstanceByName(name)
	if name == nil then
		logger:error("common_utils:getInstanceByName - Param name is nil.");
		return nil;
	end
	
	local sce = getScene();
	if not sce then
		logger:error("common_utils:getInstanceByName - Scene is nil");
		return nil;
	end
	local instance = sce:getSceneInstanceManager():findInstanceByName(tostring(name));
	if instance ~= nil then
		return instance;
	else
		logger:error("common_utils:getInstanceByName - No such instance found with name: " .. tostring(name));
	end
	
	return nil;
end

function doesInstanceExistByName(name)
	if name == nil then
		logger:error("common_utils:doesInstanceExistByName - Param name is nil.");
		return false;
	end
	
	local sce = getScene();
	if not sce then
		logger:error("common_utils:doesInstanceExistByName - Scene is nil");
		return false;
	end
	local instance = sce:getSceneInstanceManager():findInstanceByName(tostring(name));
	if instance ~= nil then
		return true;
	end
	
	return false;
end

-------------------------------------------------------------------------------------------------
--
-- Type helpers
--

function isClassIDInheritedFromType(classId, type)
	if classId == nil then
		logger:error("common_utils:isClassIDInheritedFromType - Class id is nil.");
		return false;
	end
	
	if type == nil then
		logger:error("common_utils:isClassIDInheritedFromType - Type is nil.");
		return false;
	end
	
	local classIDType = getTypeManager():getStaticDefaultType(classId);
	if classIDType == nil then
		logger:error("common_utils:isClassIDInheritedFromType - No such default type found with given class id.");
		return false;	
	end	
	return type:doesInheritType(classIDType);
end

function isTypeUHInheritedFromType(typeUH, inheritedFromType)
	if not typeUH then
		return false
	end
	if not inheritedFromType then
		return false
	end
	if typeUH == inheritedFromType:getUnifiedHandle() then
		return true
	end
	for i = 0, inheritedFromType:getNumChildren() - 1 do
		local child = inheritedFromType:getChild(i)
		if child then
			if typeUH == child:getUnifiedHandle() then
				return true
			end
			if child:getNumChildren() > 0 then
				if isTypeUHInheritedFromType(typeUH, child:getUnifiedHandle()) then
					return true
				end
			end
		end
	end
end

----------------------------------------------------------------------------------------------------------------------------
--
-- Fog/Skymodel/Ambient helper scripts
--

function setFogEnabledByName(name, enabled)
	if name == nil then
		logger:error("common_utils:setFogEnabledByName - name param is nil.");
		return;
	end
	
	if enabled == nil then
		logger:error("common_utils:setFogEnabledByName - enabled param is nil.");
		return;
	end
	
	local instance = getScene():getSceneInstanceManager():findInstanceByName(name);
	if instance == nil then
		logger:error("common_utils:setFogEnabledByName - No such instance found with given name: \"" .. name .. "\".");
		return;
	end
	
	local component = instance:findComponentByClass(rendering.FogComponent.getStaticObjectClass());
	if component == nil then
		logger:error("common_utils:setFogEnabledByName - No FogComponent found with given instance name: \"" .. name .. "\".");
		return;
	end
	
	component:setEnabled(enabled);
end

function setSkyModelEnabledByName(name, enabled)
	if name == nil then
		logger:error("common_utils:setSkyModelEnabledByName - name param is nil.");
		return;
	end
	
	if enabled == nil then
		logger:error("common_utils:setSkyModelEnabledByName - enabled param is nil.");
		return;
	end
	
	local instance = getScene():getSceneInstanceManager():findInstanceByName(name);
	if instance == nil then
		logger:error("common_utils:setSkyModelEnabledByName - No such instance found with given name: \"" .. name .. "\".");
		return;
	end
	
	local component = instance:findComponentByClass(rendering.SkyModelComponent.getStaticObjectClass());
	if component == nil then
		logger:error("common_utils:setSkyModelEnabledByName - No SkyModelComponent found with given instance name: \"" .. name .. "\".");
		return;
	end
	
	component:setEnabled(enabled);	
end

function setAmbientLightEnabledByName(name, enabled)
	if name == nil then
		logger:error("common_utils:setAmbientLightEnabledByName - name param is nil.");
		return;
	end
	
	if enabled == nil then
		logger:error("common_utils:setAmbientLightEnabledByName - enabled param is nil.");
		return;
	end
	
	local instance = getScene():getSceneInstanceManager():findInstanceByName(name);
	if instance == nil then
		logger:error("common_utils:setAmbientLightEnabledByName - No such instance found with given name: \"" .. name .. "\".");
		return;
	end
	
	local component = instance:findComponentByClass(lighting.AmbientLightComponent.getStaticObjectClass());
	if component == nil then
		logger:error("common_utils:setAmbientLightEnabledByName - No AmbientLightComponent found with given instance name: \"" .. name .. "\".");
		return;
	end
	
	component:setEnabled(enabled);	
end

-------------------------------------------------------------------------------------------------

function findCamera()
	if cameraUH == nil or cameraUH == UH_NONE then
		local cam = getSceneInstanceManager():findInstanceByName("camera")
		if cam ~= nil then
			cameraUH = cam:getUnifiedHandle()
			return cam
		end
	else
		local cam = getSceneInstanceManager():getInstanceByUH(cameraUH);
		if not cam or cam:getName() ~= "camera" then
			cameraUH = UH_NONE
			-- re-try to find it if it just has changed UH (re-created or something)...
			cam = getSceneInstanceManager():findInstanceByName("camera")
			if cam ~= nil then
				cameraUH = cam:getUnifiedHandle()
				return cam
			end
		else
			return cam
		end
	end
	return nil
end

function resetCamera()
    cameraUH = nil
end

function isOutOfSight(obj, maxDistanceFromFrustum, offset)
	local maxDistanceFromFrustum = maxDistanceFromFrustum or 0.0 
	local camera = findCamera()
	if camera then
		local cc = camera:findComponent(rendering.CameraComponent)
		local tc = getFinalOwnerInstance(obj):getTransformComponent()
		if cc and tc then
			local pos = tc:getPosition()
			if(offset) then pos = pos + offset end
			return not cc:isInFieldOfView(pos, maxDistanceFromFrustum)
		else
			if not cc then logger:debug("common_utils - isOutOfSight() - CameraComponent not found") end
			if not tc then logger:debug("common_utils - isOutOfSight() - TransformComponent not found") end
		end
	else
		logger:debug("common_utils - isOutOfSight() - Camera not found")
	end
	return false
end

function isOutOfSightFromCameraComponent(cameraComponent, obj, maxDistanceFromFrustum, offset)
	local maxDistanceFromFrustum = maxDistanceFromFrustum or 0.0 
	if cameraComponent then
		local tc = getFinalOwnerInstance(obj):getTransformComponent()
		if tc then
			local pos = tc:getPosition()
			if(offset) then pos = pos + offset end
			return not cameraComponent:isInFieldOfView(pos, maxDistanceFromFrustum)
		else
			if not tc then logger:debug("common_utils - isOutOfSightFromCameraComponent() - TransformComponent not found") end
		end
	else
		logger:debug("common_utils - isOutOfSightFromCameraComponent() - cameraComponent not found")
	end
	return false
end



function setCameraRange(value)
	local camera = findCamera()
	if camera ~= nil then
		local cc = camera:findComponent(rendering.CameraComponent)
		if cc then
			cc:setCameraRange(value)
		end
	end
end

-------------------------------------------------------------------------------------------------

function playMusicAudioEvent(audioEvent)
	if FB_AUDIO_ENGINE == "FB_NULL_AUDIO" then
		return;
	end
	
	local audioManager = common.CommonUtils.getAudioManager();
	if audioManager then
		audioManager:playMusic(audioEvent)
	else
		logger:error("playMusicAudioEvent("..audioEvent..") failed - audioManager was not found.")
	end
end

function playGUIAudioEvent(audioEvent)
	if FB_AUDIO_ENGINE == "FB_NULL_AUDIO" then
		return;
	end
	
	local audioManager = common.CommonUtils.getAudioManager();
	if audioManager then
		audioManager:playGUISound(audioEvent)
	else
		logger:error("playGUIAudioEvent("..audioEvent..") failed - audioManager was not found.")
	end
end

function playGUISoundWithLuaCallback(audioEvent, completedCallback)
	audio.AudioManager.playGUISoundWithLuaCallback(audioEvent, completedCallback)
end

function playOutOfManaSound(self)
	local audioComponent = self:getFinalOwner():findComponent(audio.AudioComponent)
	if audioComponent then
		audioComponent:postEventLua("Play_out_of_mana_sound")
	end
end

-------------------------------------------------------------------------------------------------

function getManagerInstance(managerName, suppressErrors)
	-- Managers exist only in game state
	if state:isEditorState() then
		return nil;
	end

	-- Funny things may happen when trying to find instances at loading screens or between scenes
	assert_boolean_or_nil(suppressErrors) 
	if suppressErrors == nil then 
		suppressErrors = false
	end
	
	-- NOTE: If we are building maps, suppress errors
	if app:isBuildingMaps() then
		suppressErrors = true;
	end
	
	local manager = nil;
	
	local sceneInstanceManager = getSceneInstanceManager();
	if sceneInstanceManager ~= nil then
		manager = sceneInstanceManager:findInstanceByName(managerName);	
		if manager ~= nil then
			return manager;
		end
	end
	
	if instanceManager ~= nil then
		manager = instanceManager:findInstanceByName(managerName);	
		if manager ~= nil then
			return manager;	
		end
	end

	if not suppressErrors then
		logger:error("getManagerInstance - Couldn't find manager with name: " .. tostring(managerName));
		--assert(manager)
	end
	return nil;
end

function getRagdollManager()
	return getManagerInstance("RagdollManagerInst");
end

function getGameSpawnManager()
	return getManagerInstance("GameSpawnManagerInst");
end

function getMissionManager(suppressErrors)
	return getManagerInstance("MissionManagerInst", suppressErrors);
end

function getAudioManager(suppressErrors)
	return getManagerInstance("AudioManagerInst", suppressErrors);
end

function getPlayerManager()
	return getManagerInstance("PlayerManagerInst");
end

function getPlayerActorManager()
	return getManagerInstance("PlayerActorManagerInst");
end

function getCharacterSelectionManager()
	return nil --getManagerInstance("CharacterSelectionManagerInst");
end

function getDifficultyManager()
	return getManagerInstance("DifficultyManagerInst");
end

--NOTE: Perhaps should relocate this.
function getMainMenuManager()
	return getManagerInstance("MainMenuManager");
end

-------------------------------------------------------------------------------------------------

function isMissionIDTestMission(missionID)
	if missionModule == nil then
		logger:error("CommontUtils:isMissionIDTestMission - Mission module is nil");
		return false;
	end
	
	return missionModule:isTestMissionId(missionID);
end

-------------------------------------------------------------------------------------------------
--
-- Trine specific (should be in some Trine utils instead of there)
--

function getTrine2CameraManager()
	return getSceneInstanceManager():findInstanceByName("TrineCameraManagerInst");
end

function getTrineUpgradeManager()
	return getSceneInstanceManager():findInstanceByName("TrineUpgradeManagerInst");
end

function getTrineRagdollManager()
	return getSceneInstanceManager():findInstanceByName("TrineRagdollManagerInst");
end

function getTrophyDetectionManager()
	return getSceneInstanceManager():findInstanceByName("TrophyDetectionManagerInst");
end

function getUnlimitedMultiplayerEnabled()
	return gameModule:getUnlimitedMultiplayerEnabled();
end

function getIsUnlimitedMultiplayerDefaultCharacterMode()
	return gameModule:getUnlimitedMultiplayerIsDefaultCharacterMode()
end

-------------------------------------------------------------------------------------------------

function isCheatMenuEnabled()
	if(FB_BUILD ~= "FB_FINAL_RELEASE") then
		return true;
	end
	return false;
end

-------------------------------------------------------------------------------------------------

function resetGlobalSpawnerSpawnIgnoreTime()
	globalSpawnerSpawnNextAllowedTime = 0;
end	

function storeGlobalSpawnerSpawnIgnoreTime()
	if globalSpawnerSpawnNextAllowedTime == nil then
		logger:error("CommontUtils:storeGlobalSpawnerSpawnIgnoreTime - globalSpawnerSpawnNextAllowedTime is nil.");
		return;
	end
	
	local curTime = getScene():getTime():getMilliseconds();
	
	local delayMilliSeconds = 150;
	
	-- Store into global
	globalSpawnerSpawnNextAllowedTime = curTime + delayMilliSeconds;
end	

function isGlobalSpawnerSpawnIgnoreTimeActive()
	if globalSpawnerSpawnNextAllowedTime == nil then
		logger:error("CommontUtils:isGlobalSpawnerSpawnIgnoreTimeActive - globalSpawnerSpawnNextAllowedTime is nil.");
		return false;
	end
	
	local curTime = getScene():getTime():getMilliseconds();
		
	if globalSpawnerSpawnNextAllowedTime > curTime then		
		-- Sanity check that values dont get too high
		local diff = globalSpawnerSpawnNextAllowedTime - curTime;
		if diff >= 500 then
			-- Value too high, reset
			globalSpawnerSpawnNextAllowedTime = 0;
			return false;
		end
	
		return true;
	end
	
	return false;
end


function getAllPlayerCharacters()
	local pam = getPlayerActorManager()
	local allCharacters = {}
	if pam then
		for i = 0, pam:getNumCharacters()-1 do
			local instance = pam:getFromAllCharactersByIndex(i);
			if instance then
				table.insert(allCharacters, instance)
			end
		end
	else
		logger:error("common.CommonUtils.getAllPlayerCharacters - PlayerActorManager is missing")
	end
	return allCharacters
end

function getAllLocalPlayerCharacters()
	local pam = getPlayerActorManager()
	local allCharacters = {}
	if pam then
		for i = 0, pam:getNumCharacters()-1 do
			local instance = pam:getLocalCharacterInstanceByIndex(i);
			if instance then
				local playerComponent = instance:findComponentByClassName("PlayerComponent")
				if playerComponent and playerComponent:getHasPlayer() and playerComponent:isLocalPlayer() then 
					table.insert(allCharacters, instance)
				elseif not playerComponent then
					logger:error("Player character (" .. instance:getName() .. ") with index " .. tostring(i) .. " had no PlayerComponent")
				end
			end
		end
	else
		logger:error("common.CommonUtils.getAllLocalPlayerCharacters - PlayerActorManager is missing")
	end
	return allCharacters
end

function getSelectedPlayerCharacters()
	local pm = getPlayerManager()
	local allCharacters = {}
	if pm then 
		for i = 0, pm:getNumPlayers()-1 do
			local instance = pm:getCharacterInstanceForPlayer(i);
			if instance then
				table.insert(allCharacters, instance)
			end
		end
	else
		logger:error("common.CommonUtils.getSelectedPlayerCharacters - PlayerManager is missing")
	end
	return allCharacters
end

function getSelectedLocalPlayerCharacters()
	local pm = getPlayerManager()
	local allCharacters = {}
	if pm then
		for i = 0, pm:getNumCharacters()-1 do
			local instance = pm:getCharacterInstanceForPlayer(i);
			if instance then
				local playerComponent = instance:findComponentByClassName("PlayerComponent")
				if playerComponent and playerComponent:isLocalPlayer() then 
					table.insert(allCharacters, instance)
				elseif not playerComponent then
					logger:error("Player " .. tostring(i) .. " character had no PlayerComponent")
				end
			end
		end
	else
		logger:error("common.CommonUtils.getSelectedLocalPlayerCharacters - PlayerManager is missing")
	end
	return allCharacters
end