module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

function isMissionChangeAllowed(demoOnly)
	if demoOnly then	
		if gameBaseApplicationModule:getDemo() then
			return true;
		else		
			return false;
		end
	end
	
	return true;
end

function startChangeToNextMission(disableInput, demoOnly)
	if not isMissionChangeAllowed(demoOnly) then
		return;
	end
end

function updateMissionChangeFades(mainFadeOut, hudTransparency, demoOnly)
	if not isMissionChangeAllowed(demoOnly) then
		return;
	end
end

-- NOTE: This is supposed to be used via cheating
function changeToNextMissionDirectly()
	if common.CommonUtils.shouldIgnoreChangeToNextMission(missionManager:getCurrentMissionID()) then
		return;
	end
	
	if(state:isOffline() or state:isServer()) then
		local scene = common.CommonUtils.getScene()
		if scene then scene:sendEndOfMissionEvent() end
		common.CommonUtils.getTrophyDetectionManager():sendEndOfMissionEvent();
		
		local misMan = common.CommonUtils.getMissionManager();
		if (not(misMan)) then
			logger:error("No mission manager instance was found.")
		end
		
		if (misMan:hasNextMissionID()) then
			changeToMission(misMan:getNextMissionID(), nil, nextMissionAutoStartWhenReady, nextMissionLoadingWindowSecondary);
		else
			gameState:setNextSaveAsFakeSaveToBeginningOfMission(true)
			logger:error("MissionChangeUtil:changeToNextMission - Current mission has no next mission, changing back to main menu.");
			-- Failsafe to main menu
			--changeToMainMenuMissionUsingParams(true, false, nil);
		end
	end
end

function changeToNextMission(nextMissionAutoStartWhenReady, nextMissionLoadingWindowSecondary, demoOnly)

	if gameState and gameState.changeToNextMission then	
		-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		-- Shadwen has no multiplayer or most of other complexities handled here so lets just skip all of that
		-- gameState.changeToNextMission saves the latest used missionid and savepoint to GameUpgradeManager
		-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		gameState:changeToNextMission()
		return
	else
		logger:error("MissionChangeUtil.changeToNextMission - gameState.changeToNextMission not found")
	end

	assert_boolean_or_nil(nextMissionAutoStartWhenReady);
	assert_boolean_or_nil(nextMissionLoadingWindowSecondary);
	assert_boolean_or_nil(demoOnly);
		
	if not isMissionChangeAllowed(demoOnly) then
		return;
	end
	
	if common.CommonUtils.shouldIgnoreChangeToNextMission(missionManager:getCurrentMissionID()) then
		return;
	end
	
	if gameBaseApplicationModule:getDemo() then
		local misMan = common.CommonUtils.getMissionManager()
		if (not(misMan)) then
			logger:error("No mission manager instance was found.")
		end
		if (not misMan:hasNextMissionID()) then
		
			local showDemoSplashScreen = false;
			if gameBaseApplicationModule:getDemo() then
				if gameBaseApplicationModule:getHasDemoSplashScreen() then
					if gameBaseApplicationModule:getDemoExpo() then
						-- Expo demo
						showDemoSplashScreen = true;
					elseif gameBaseApplicationModule:getDemoStage() then
						-- Stage demo
						showDemoSplashScreen = false;			
					else
						-- Normal demo
						showDemoSplashScreen = true;
					end
				end
			end
		end
	end
	
	-- note, assuming that this gets run in state lua 
	if(state:isOffline() or state:isServer()) then
	
	--[[
		if(scene) then
			scene:sendEndOfMissionEvent();
		elseif(gameScene) then
			gameScene:sendEndOfMissionEvent();
		end
	]]--
		local scene = common.CommonUtils.getScene()
		if scene then scene:sendEndOfMissionEvent() end
		common.CommonUtils.getTrophyDetectionManager():sendEndOfMissionEvent();
	-- new implementation
	
		local misMan = common.CommonUtils.getMissionManager();
		if (not(misMan)) then
			logger:error("No mission manager instance was found.")
		end
		

		if gameBaseApplicationModule:getDemo() then
			if gameBaseApplicationModule:getDemoExpo() then
				--
				-- Expo demo
				--				
				if (misMan:hasNextMissionID()) then
					nextMissionAutoStartWhenReady = false
					changeToMission(misMan:getNextMissionID(), nil, nextMissionAutoStartWhenReady, nextMissionLoadingWindowSecondary);
				else
					gameState:setNextSaveAsFakeSaveToBeginningOfMission(true)
					changeToMainMenuWithParams(true, false, nil);
				end
			elseif gameBaseApplicationModule:getDemoStage() then
				--
				-- Stage demo
				--				
				if (misMan:hasNextMissionID()) then
					nextMissionAutoStartWhenReady = true
					changeToMission(misMan:getNextMissionID(), nil, nextMissionAutoStartWhenReady, nextMissionLoadingWindowSecondary);
				else
					gameState:setNextSaveAsFakeSaveToBeginningOfMission(true)
					changeToMainMenuWithParams(true, false, nil);
				end
			else
				--
				-- Normal demo
				--				
				if (misMan:hasNextMissionID()) then
					changeToMission(misMan:getNextMissionID(), nil, nextMissionAutoStartWhenReady, nextMissionLoadingWindowSecondary);
				else
					gameState:setNextSaveAsFakeSaveToBeginningOfMission(true)

					--if gameBaseApplicationModule:getHasDemoSplashScreen() or gameBaseApplicationModule:getForceDemoSplashScreen() then
					if gameBaseApplicationModule:getHasDemoSplashScreen() then
						-- nop
					else
						changeToMainMenuWithParams(true, false, nil);
					end
				end
			end
		else
			-- Full game
			
			if common.CommonUtils.getLevelSelectionPlayable() then
				-- NOTE: Unlock next level. Originally the mission unlock would've happened when the next stage was loaded.
				if (state:isOffline() or state:isServer()) then
					-- NOTE: New design; don't unlock missions directly anymore.
					--state:unlockMissionForAll(nextMissionID)
					state:setMissionCompletedForAll(common.CommonUtils.getCurrentMissionID())
					returnToMap()
				end
			else
				if (misMan:hasNextMissionID()) then
					changeToMission(misMan:getNextMissionID(), nil, nextMissionAutoStartWhenReady, nextMissionLoadingWindowSecondary);
				else
					gameState:setNextSaveAsFakeSaveToBeginningOfMission(true)
					logger:error("MissionChangeUtil:changeToNextMission - Current mission has no next mission, changing back to main menu.");
					-- Failsafe to main menu
					changeToMainMenuWithParams(true, false, nil);
				end
			end
		end
	end
end

function returnToMap()
	local missionManager = common.CommonUtils.getMissionManager()
	if missionManager then
		missionManager:setLastMissionQuitFromStage(value)
	end
	
	cinematic.CinematicUtil.setMenuTimerTransitionIsPlaying(false);
	state:setSkipNextQuitToMainMenu(true);
	state:setSkipNextControllerClear(true);
	state:setPlayableLevelSelectionActiveForAll(true)
	changeToMainMenu();
end
function sendEndOfMissionEventToTrophyDetectionManager()
	local scene = common.CommonUtils.getScene()
	if scene then scene:sendEndOfMissionEvent() end
	common.CommonUtils.getTrophyDetectionManager():sendEndOfMissionEvent();

end
 
function changeToMission(missionId, missionFile, nextMissionAutoStartWhenReady, nextMissionLoadingWindowSecondary, customMenuOpenParams)
	assert_string(missionId);
	assert_string_or_nil(missionFile);
	assert_boolean_or_nil(nextMissionAutoStartWhenReady);
	assert_boolean_or_nil(nextMissionLoadingWindowSecondary);
	assert_table_or_nil(customMenuOpenParams);
	

	lastNextMissionAutoStartWhenReady = nextMissionAutoStartWhenReady;
	lastNextMissionLoadingWindowSecondary = nextMissionLoadingWindowSecondary;
	if(lastNextMissionAutoStartWhenReady == nil) then lastNextMissionAutoStartWhenReady = false end
	if(lastNextMissionLoadingWindowSecondary == nil) then lastNextMissionLoadingWindowSecondary = false end
	
	if missionFile == nil then
		missionFile = ""
	end
	
	state:loadMissionWithParams(missionId, missionFile, customMenuOpenParams);
end

function changeToMainMenu()
	changeToMission(common.CommonUtils.getMainMenuMissionID(), common.CommonUtils.getCurrentMainMenuMissionFilename(), nil, nil, nil);
end

function changeToMainMenuWithParams(nextMissionAutoStartWhenReady, nextMissionLoadingWindowSecondary, customMenuOpenParams)
	changeToMission(common.CommonUtils.getMainMenuMissionID(), common.CommonUtils.getCurrentMainMenuMissionFilename(), nextMissionAutoStartWhenReady, nextMissionLoadingWindowSecondary, customMenuOpenParams);
end
