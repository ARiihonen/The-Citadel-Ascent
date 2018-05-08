module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

require "cinematic.MissionLoadingCinematic"
require "cinematic.BossFightEndCinematic"

local thisModule = _M

declareReload(thisModule, [[skippingGUICinematic]])
declareReload(thisModule, [[lastGUISpeechPlayed]])
declareReload(thisModule, [[someVideoIsPlaying]])
declareReload(thisModule, [[effectAttenuationHandles]])
declareReload(thisModule, [[playingVideoCallbackFunction]])
declareReload(thisModule, [[introCinematicIsPlaying]])
declareReload(thisModule, [[introCinematicCanBeSkipped]])
declareReload(thisModule, [[menuTimerTransitionIsPlaying]])

skippingGUICinematic = false
lastGUISpeechPlayed = nil
loadingCinematicPlaying = false
someVideoIsPlaying = false
effectAttenuationHandles = { }
playingVideoCallbackFunction = nil

-- Special variables for handling skipping of intro cinematic
introCinematicIsPlaying = false;
introCinematicCanBeSkipped = false;

-- Special variable for mainmenu <-> playable level selection menu transitions.
menuTimerTransitionIsPlaying = false

cinematicSpeechArrayTimer = 0;
cinematicHackTimerStep = 100;

function setIntroCinematicIsPlaying(isPlaying)
	assert_boolean(isPlaying)
	introCinematicIsPlaying = isPlaying
end

function setIntroCinematicCanBeSkipped(canBeSkipped)
	assert_boolean(canBeSkipped)
	introCinematicCanBeSkipped = canBeSkipped
end
	
function getIntroCinematicIsPlaying()
	return introCinematicIsPlaying
end

function getIntroCinematicCanBeSkipped()
	return introCinematicCanBeSkipped
end



function setMenuTimerTransitionIsPlaying(isPlaying)
	assert_boolean(isPlaying)
	menuTimerTransitionIsPlaying = isPlaying
end

function getMenuTimerTransitionIsPlaying()
	return menuTimerTransitionIsPlaying
end
	


-- can be used as a parameter for playSpeech, if no callback is required
function dummyCallback()
	-- nop
end


function playLoadingScreenMusic(play_event_name)
	assert_string_or_nil(play_event_name)
	
	local musicEventName = play_event_name;
	if musicEventName == nil then
		-- Use default
		musicEventName = "Play_loading_screen_music";
	end
	
	--if audioModule then
		-- this breaks music fadeouts so i commented it out
		--audioModule:stopAllSounds()
		
		-- The following line prevents sound effects in playable main menu
		--common.CommonUtils.playGUIAudioEvent("stop_all_except_music")
	--end
	
	local audioMan = common.CommonUtils.getAudioManager()
	if audioMan then
		audioMan:playMusic(musicEventName)
	end
end

function setBackground(name, imageFile, startUpTime, fadeInTime)
	if (fadeInTime == 0 and startUpTime == 0) then 
		-- TODO: just stay black
	else
		fuiEffectManager:waitAndDipToBlackAndWaitAndBack(0,0,startUpTime,fadeInTime)
	end
	
	startUpTime = startUpTime + fadeInTime
	return startUpTime
end

function removeBackground(name, startUpTime, fadeOutTime)
	if (fadeOutTime <= 0) then fadeOutTime = 1 end
	fuiEffectManager:waitAndDipToBlackAndWaitAndBack(startUpTime,fadeOutTime,0,0)
	-- TODO: Should stay black after this 
	return startUpTime
end


function delayedCall(duration, completedCallback)
	assert_number(duration)
	assert_string(completedCallback)
	
	if (skippingGUICinematic)	then
		state:runLuaStringWithDelay(completedCallback, 1)
	else
		state:runLuaStringWithDelay(completedCallback, duration)
	end
end


-- DEPRECATED LEGACY - use the one with real function callbacks
function playSpeech(speechEvent, subtitleLocaleKey, failsafeDuration, extraDelay, completedCallback, subtitleFontOpt)
	assert_string(speechEvent)
	assert_string_or_nil(subtitleLocaleKey)
	assert_number(failsafeDuration)
	assert_string_or_nil(subtitleFontOpt)
	
	loadingCinematicPlaying = true
	
	if (skippingGUICinematic) then
		state:runLuaStringWithDelay(completedCallback, 1)
		return
	end
	
	-- HACK: support for old the ones as well, as the extradelay was requested to be added after failsafe duration, rather than as the very last param. :P
	if (type(extraDelay) == "string") then
		completedCallback = extraDelay
		extraDelay = 0
	end
	
	-- note, you must give a lua string to run, not a function. nil is acceptable for no callback
	assert_string(completedCallback)
	
	if(not subtitleLocaleKey)then
		subtitleLocaleKey = "locales." .. string.sub(speechEvent, 6) -- strip "Play_" from start of the speech event
	end
	
	if (subtitleLocaleKey) then
		local subFontName = ""
		if (subtitleFontOpt) then
			subFontName = subtitleFontOpt
		end
		if gameLoadingScreenComponent then
			gameLoadingScreenComponent:setSubtitle(subtitleLocaleKey)
		elseif fuiSubtitleComponent then
			fuiSubtitleComponent:setSubtitle("", subtitleLocaleKey, "", subFontName, "")
		else
			logger:error("CinematicUtil.playSpeech - Couldn't find fuiSubtitleComponent or gameLoadingScreenComponent")
		end
	end

	local success = false
	if (extraDelay == 0) then
		success = audio.AudioManager.playGUISoundWithLuaCallback(speechEvent, completedCallback)
	else
		local extraDelayedFuncStr = "state:runLuaStringWithDelay([["..completedCallback.."]], "..tostring(extraDelay)..")"
		success = audio.AudioManager.playGUISoundWithLuaCallback(speechEvent, extraDelayedFuncStr)
	end
	if (success) then
		lastGUISpeechPlayed = speechEvent
	else
		logger:warning("Cinematic audio play of \""..speechEvent.."\" failed.");
		-- send an event to run the completedCallback in failsafeDuration milliseconds.
		state:runLuaStringWithDelay(completedCallback, failsafeDuration + extraDelay)
	end
	
end

-- intended for ui (loading, no scene available) speeches only, ingame cinematics should do this stuff using AudioTimerComponent and such..
-- failsafeDuration is the duration used whenever the audio file is missing (or sounds are completely disabled from the game)
function playSpeechCallFunction(speechEvent, subtitleLocaleKey, failsafeDuration, extraDelay, completedCallback, subtitleFontOpt)
	assert_string(speechEvent)
	assert_string_or_nil(subtitleLocaleKey)
	assert_number(failsafeDuration)
	assert_string_or_nil(subtitleFontOpt)
	
	if (skippingGUICinematic) then
		state:runLuaFuncWithDelay(1, completedCallback)
		return
	end
	
	if not completedCallback  then
		logger:error("No valid callback function given");
	end
	
	if (subtitleLocaleKey) then
		local subFontName = ""
		if (subtitleFontOpt) then
			subFontName = subtitleFontOpt
		end
		if fuiSubtitleComponent then
			fuiSubtitleComponent:setSubtitle("", subtitleLocaleKey, "", subFontName, "")
		else
			logger:error("cinematic_util.lua - Couldn't find fuiSubtitleComponent")
		end
	end

	local success = false
	if (extraDelay == 0) then
		success = audio.AudioManager.playGUISoundWithLuaFunctionFunctionCallback(speechEvent, completedCallback)
	else
		local extraDelayedFunc = function() state:runLuaFuncWithDelay(extraDelay, completedCallback) end;
		success = audio.AudioManager.playGUISoundWithLuaFunctionCallback(speechEvent, extraDelayedFunc)
	end
	if (success) then
		lastGUISpeechPlayed = speechEvent
	else
		-- A warning? Of course, failing cinematics are so everyday that why even bother with errors.
		logger:warning("Cinematic audio play of \""..speechEvent.."\" failed.");
		-- send an event to run the completedCallback in failsafeDuration milliseconds.
		state:runLuaFuncWithDelay(failsafeDuration + extraDelay, completedCallback)
	end
	
end

--Helper functions for playSpeechCallFunction(...)
-- used by loading_<missionID>.lua files
function playSpeechesFromArray(array, index, allDoneCallbackFunc, hackTimerArray)
	assert_number(index)
	-- make sure that previous subtitles have ended or end them now 
	if( index == 1) then
		-- Start mystery timer to hack some Wii U stuff...
		cinematicSpeechArrayTimer = 0;
		cinematic.CinematicUtil.delayedCall(cinematicHackTimerStep, "cinematic.CinematicUtil.updateHackTimer()")

		if(audio.AudioManager.isGUISoundPlayingWithCallbackFunction()) then 
			audio.AudioManager.clearGUISoundCallbackFunctionsList()
		end 
	end 

	if (type(array) == "table") then
		local size = table.getn(array)
		if( index <= size ) then
			if (type(hackTimerArray) == "table" and cinematicSpeechArrayTimer < hackTimerArray[index]) then
				-- do a delayed call here to this func
				local delayLoopFunc = function() cinematic.CinematicUtil.playSpeechesFromArray(array, index, allDoneCallbackFunc, hackTimerArray) end
				state:runLuaFuncWithDelay(50, delayLoopFunc)
				return
			end
			local nextIndex = index +1
			local callBackFunction = function() cinematic.CinematicUtil.playSpeechesFromArray(array, nextIndex, allDoneCallbackFunc, hackTimerArray) end
			playSpeechByLocale(array[index], callBackFunction)
		elseif allDoneCallbackFunc then
			allDoneCallbackFunc()
		else
			loadingCinematicDone()
		end
	else 
		logger:error("playSpeechesByMissionID did not receive a table as a parameter")
	end
end

function updateHackTimer()
	-- We need to also check that if we are already playing the final audio we don't want to call this anymore
	if cinematic.CinematicUtil.skippingGUICinematic then
		return
	end

	if inputModule:isSystemInterrupted() then
		cinematic.CinematicUtil.delayedCall(cinematicHackTimerStep, "cinematic.CinematicUtil.updateHackTimer()")
		return
	end

	local updateIntervalError = state:getLuaStringRunTimeDeltaError()
	cinematicSpeechArrayTimer = cinematicSpeechArrayTimer + cinematicHackTimerStep + updateIntervalError
	cinematic.CinematicUtil.delayedCall(cinematicHackTimerStep, "cinematic.CinematicUtil.updateHackTimer()")
end

function playSpeechByLocale(localeName, completedCallback)
	assert_string(localeName)
	local maxPlayTimeIfNoSoundFile = 6000; --milliseconds
	local silenceTimeAfterSpeech = 700; --milliseconds
	playSpeechCallFunction(generateAudioFileName(localeName), generateSubtitleLocale(localeName), maxPlayTimeIfNoSoundFile, silenceTimeAfterSpeech, completedCallback)
end


function generateAudioFileName(localeName)
	assert_string(localeName)
	local audioPrefix = "Play_";
	return audioPrefix..localeName;

end

function generateSubtitleLocale(localeName)
	assert_string(localeName)
	local subtitlePrefix = "locales.";
	return subtitlePrefix..localeName
end

function loadingCinematicDone()
	skippingGUICinematic = false
	lastGUISpeechPlayed = nil
	loadingCinematicPlaying = false
	
	if fuiSubtitleComponent then 
		fuiSubtitleComponent:clearAllSubtitles()
	end
	
	if gameLoadingScreenComponent then 
		gameLoadingScreenComponent:clearAllSubtitles()
		gameLoadingScreenComponent:loadingCinematicDone();
	end
end

function cinematic.CinematicUtil.cinematicEnded()
	someVideoIsPlaying = false
	loadingCinematicPlaying = false
	-- called by cinematic timer code, whenever a cinematic ends
	-- note, this might not always happen after a cinematic skip, should the skip be interrupted by say, network failure, and thus
	-- causing a fallback to menus or such.
	
	-- quickly fade-in (from 1.0 to 0.0) rather that just setting back to 0
	-- (handled by the updater function now)
	fuiEffectManager:waitAndDipToBlackAndWaitAndBack(0, 0.2, 0.5, 0.5)
end

-- returns true if cinematic is intercepting pause menu open bind...
function shouldSkipCinematicRatherThanOpenPauseMenu()
	-- don't allow switching to pause menu while a cinematic is running. (allow switching out of it though)
	-- offline game only, online uses pause menu normally (even during cinematics)
	if state:isOffline() then
		if state:isCinematicRunning() or someVideoIsPlaying then
			-- TODO: Check is game is paused and return false if it is
			return true
		end
	else
		-- hacked exception to online pause menu, if a video is playing, then the pause menu is not allowed.
		if (someVideoIsPlaying) then
			-- TODO: Check is game is paused and return false if it is
			return true
		end
	end
	
	return false
end

-- hack, stop only the latest cinematic speech, but don't assume entire cinematic.speech skipping
-- (can give an optional substring filtering parameter 
function skipSingleCinematicGUISpeechOnly(containingStringOpt)
	if (lastGUISpeechPlayed) then
		if (containingStringOpt == nil or string.find(lastGUISpeechPlayed, containingStringOpt, 1, true)) then
			if (string.sub(lastGUISpeechPlayed, 1, 5) == "Play_") then
				local stopEvent = "Stop_" .. string.sub(lastGUISpeechPlayed, 6)
				local audioMan = common.CommonUtils.getAudioManager()
				if (audioMan) then
					audioMan:playGUISound(stopEvent)
				else
					logger:error("No audio manager available.")
				end
			end
			lastGUISpeechPlayed = nil
		end
	end
end

-- this should get called when skipping loading screen or other cinematic. (videos)
function skipCinematicGUISpeech()
	
	-- stop all speeches asap... (assuming only the last one is playing)
	if (lastGUISpeechPlayed) then
		if (string.sub(lastGUISpeechPlayed, 1, 5) == "Play_") then
			local stopEvent = "Stop_" .. string.sub(lastGUISpeechPlayed, 6)
			local audioMan = common.CommonUtils.getAudioManager()
			if (audioMan) then
				audioMan:playGUISound(stopEvent)
			else
				logger:error("No audio manager available.")
			end
		end
		lastGUISpeechPlayed = nil
	end
	
	if loadingCinematicPlaying then
		-- HACK: umm.. since currently not all speeches immediately stop and call the next speech... need to hack hack hack...
		-- setting a mystery variable that tells the audio playing and everything that no more speech audio is to play...	
		skippingGUICinematic = true
	end	
	
	if introCinematicIsPlaying then
		setIntroCinematicIsPlaying(false)
		setIntroCinematicCanBeSkipped(false)
	end
end

function isActive()
	return false --gui.hud.TopEffect.anyEffectsActive()
end

function handleOnlineGameEndThroughCredits()
	-- TODO: Show credits
end

function isPlaying()
	return (someVideoIsPlaying or isActive()) and not skippingGUICinematic
end

function handleOnlineGameEndFromCredits()
	local loadMainMenuForReal = true;

	--if state:isServer() then
	--	local textTable = { "menu.mainmenu.creditsmenu.popupEndCredits1", "menu.mainmenu.creditsmenu.popupEndCredits2", "menu.mainmenu.creditsmenu.popupEndCredits3" };
	--	if state:isInPrivateLobby() then
	--		if loadMainMenuForReal then
	--			gui.MessageBoxUtils.displayMultiline(textTable, "AcceptCancel", function() accept("private_end") end)
	--		else
	--			gui.menu.mainmenu.MainMenu.makeMainMenuAsParameter("with_mp_menu_join");
	--			gui.menu.Menus.switchToWindowState(nil, common.CommonUtils.getMainMenuWindowStateName());
	--			gui.menu.Menus.switchToWindowState(nil, [[multiplayerMenu]]);
	--			gui.menu.mainmenu.multiplayermenu.HostGameMenu.makeHostGameMenuAsParameter("private_end");
	--			gui.menu.Menus.switchToWindowState(nil, [[hostGameMenu]]);
	--		end
	--	else
	--		if loadMainMenuForReal then
	--			gui.MessageBoxUtils.displayMultiline(textTable, "AcceptCancel", function() accept("public_end") end)
	--		else
	--			gui.menu.mainmenu.MainMenu.makeMainMenuAsParameter("with_mp_menu_join");
	--			gui.menu.Menus.switchToWindowState(nil, common.CommonUtils.getMainMenuWindowStateName());
	--			gui.menu.Menus.switchToWindowState(nil, [[multiplayerMenu]]);
	--			gui.menu.mainmenu.multiplayermenu.HostGameMenu.makeHostGameMenuAsParameter("public_end");
	--			gui.menu.Menus.switchToWindowState(nil, [[hostGameMenu]]);
	--		end
	--	end
	--else
	--	if loadMainMenuForReal then
	--		local textTable = { "menu.mainmenu.creditsmenu.popupQuitOrWait1", "menu.mainmenu.creditsmenu.popupQuitOrWait2", "menu.mainmenu.creditsmenu.popupQuitOrWait3" };
	--		gui.MessageBoxUtils.displayMultiline(textTable, "AcceptCancel", function() accept("clientquit") end)
	--	else
	--		gui.menu.mainmenu.MainMenu.makeMainMenuAsParameter("with_mp_menu_join");
	--		gui.menu.Menus.switchToWindowState(nil, common.CommonUtils.getMainMenuWindowStateName());
	--		gui.menu.Menus.switchToWindowState(nil, [[multiplayerMenu]]);
	--		gui.menu.mainmenu.multiplayermenu.HostGameMenu.makeHostGameMenuAsParameter("join_end");
	--		gui.menu.Menus.switchToWindowState(nil, [[hostGameMenu]]);
	--	end
	--end
end

function handleOnlineGameEnd()
	local loadMainMenuForReal = true;

	--if state:isServer() then
	--	if state:isInPrivateLobby() then
	--		if loadMainMenuForReal then
	--			local customMenuOpenParams = { }
	--			local customMenuOpenMenuNames = { }
	--			local customMenuOpenMenuPreFuncStrings = { }
	--			table.insert(customMenuOpenMenuNames, common.CommonUtils.getMainMenuWindowStateName())
	--			table.insert(customMenuOpenMenuPreFuncStrings, "gui.menu.mainmenu.MainMenu.makeMainMenuAsParameter(\"with_mp_menu_join\")")
	--			table.insert(customMenuOpenMenuNames, [[multiplayerMenu]])
	--			table.insert(customMenuOpenMenuPreFuncStrings, "")
	--			table.insert(customMenuOpenMenuNames, [[hostGameMenu]])
	--			table.insert(customMenuOpenMenuPreFuncStrings, "gui.menu.mainmenu.multiplayermenu.HostGameMenu.makeHostGameMenuAsParameter(\"private_end\")");
	--			table.insert(customMenuOpenParams, customMenuOpenMenuNames)
	--			table.insert(customMenuOpenParams, customMenuOpenMenuPreFuncStrings)
	--			state:setSkipNextQuitToMainMenu(true);
	--			gui.menu.LoadingWindow.changeToMainMenuUsingLoadingWindowWithParams(nil, nil, customMenuOpenParams);
	--		else
	--			gui.menu.mainmenu.MainMenu.makeMainMenuAsParameter("with_mp_menu_join");
	--			gui.menu.Menus.switchToWindowState(nil, common.CommonUtils.getMainMenuWindowStateName());
	--			gui.menu.Menus.switchToWindowState(nil, [[multiplayerMenu]]);
	--			gui.menu.mainmenu.multiplayermenu.HostGameMenu.makeHostGameMenuAsParameter("private_end");
	--			gui.menu.Menus.switchToWindowState(nil, [[hostGameMenu]]);
	--		end
	--	else
	--		if loadMainMenuForReal then
	--			local customMenuOpenParams = { }
	--			local customMenuOpenMenuNames = { }
	--			local customMenuOpenMenuPreFuncStrings = { }
	--			table.insert(customMenuOpenMenuNames, common.CommonUtils.getMainMenuWindowStateName())
	--			table.insert(customMenuOpenMenuPreFuncStrings, "gui.menu.mainmenu.MainMenu.makeMainMenuAsParameter(\"with_mp_menu_join\")")
	--			table.insert(customMenuOpenMenuNames, [[multiplayerMenu]])
	--			table.insert(customMenuOpenMenuPreFuncStrings, "")
	--			table.insert(customMenuOpenMenuNames, [[hostGameMenu]])
	--			table.insert(customMenuOpenMenuPreFuncStrings, "gui.menu.mainmenu.multiplayermenu.HostGameMenu.makeHostGameMenuAsParameter(\"public_end\")");
	--			table.insert(customMenuOpenParams, customMenuOpenMenuNames)
	--			table.insert(customMenuOpenParams, customMenuOpenMenuPreFuncStrings)
	--			state:setSkipNextQuitToMainMenu(true);
	--			gui.menu.LoadingWindow.changeToMainMenuUsingLoadingWindowWithParams(nil, nil, customMenuOpenParams);
	--		else
	--			gui.menu.mainmenu.MainMenu.makeMainMenuAsParameter("with_mp_menu_join");
	--			gui.menu.Menus.switchToWindowState(nil, common.CommonUtils.getMainMenuWindowStateName());
	--			gui.menu.Menus.switchToWindowState(nil, [[multiplayerMenu]]);
	--			gui.menu.mainmenu.multiplayermenu.HostGameMenu.makeHostGameMenuAsParameter("public_end");
	--			gui.menu.Menus.switchToWindowState(nil, [[hostGameMenu]]);
	--		end
	--	end
	--else
	--	if loadMainMenuForReal then
	--		-- Just wait for the host
	--		--local customMenuOpenParams = { }
	--		--local customMenuOpenMenuNames = { }
	--		--local customMenuOpenMenuPreFuncStrings = { }
	--		--table.insert(customMenuOpenMenuNames, common.CommonUtils.getMainMenuWindowStateName())
	--		--table.insert(customMenuOpenMenuPreFuncStrings, "gui.menu.mainmenu.MainMenu.makeMainMenuAsParameter(\"with_mp_menu_join\")")
	--		--table.insert(customMenuOpenMenuNames, [[multiplayerMenu]])
	--		--table.insert(customMenuOpenMenuPreFuncStrings, "")
	--		--table.insert(customMenuOpenMenuNames, [[hostGameMenu]])
	--		--table.insert(customMenuOpenMenuPreFuncStrings, "gui.menu.mainmenu.multiplayermenu.HostGameMenu.makeHostGameMenuAsParameter(\"join_end\")");
	--		--table.insert(customMenuOpenParams, customMenuOpenMenuNames)
	--		--table.insert(customMenuOpenParams, customMenuOpenMenuPreFuncStrings)	
	--		--gui.menu.LoadingWindow.changeToMainMenuUsingLoadingWindowWithParams(nil, nil, customMenuOpenParams);
	--	else
	--		gui.menu.mainmenu.MainMenu.makeMainMenuAsParameter("with_mp_menu_join");
	--		gui.menu.Menus.switchToWindowState(nil, common.CommonUtils.getMainMenuWindowStateName());
	--		gui.menu.Menus.switchToWindowState(nil, [[multiplayerMenu]]);
	--		gui.menu.mainmenu.multiplayermenu.HostGameMenu.makeHostGameMenuAsParameter("join_end");
	--		gui.menu.Menus.switchToWindowState(nil, [[hostGameMenu]]);
	--	end
	--end
		
	-- Load main menu mission and open host game menu (clients gets disconnected, should load he main menu properly but might need hacking to get this work)
	--local customMenuOpenParams = { }
	--local customMenuOpenMenuNames = { }
	--local customMenuOpenMenuPreFuncStrings = { }
	--
	---- Open main menu
	--table.insert(customMenuOpenMenuNames, common.CommonUtils.getMainMenuWindowStateName())
	--table.insert(customMenuOpenMenuPreFuncStrings, "")
	--
	---- And then the multiplayer menu
	--table.insert(customMenuOpenMenuNames, [[multiplayerMenu]])
	--table.insert(customMenuOpenMenuPreFuncStrings, "")
	--
	--if state:isServer() then
	--	if state:isInPrivateLobby() then
	--		table.insert(customMenuOpenMenuNames, [[hostGameMenu]])
	--		table.insert(customMenuOpenMenuPreFuncStrings, "gui.menu.mainmenu.multiplayermenu.HostGameMenu.makeHostGameMenuAsParameter(\"private\")");
	--	else
	--		table.insert(customMenuOpenMenuNames, [[hostGameMenu]])
	--		table.insert(customMenuOpenMenuPreFuncStrings, "gui.menu.mainmenu.multiplayermenu.HostGameMenu.makeHostGameMenuAsParameter(\"public\")");
	--	end
	--else
	--	table.insert(customMenuOpenMenuNames, [[hostGameMenu]])
	--	table.insert(customMenuOpenMenuPreFuncStrings, "gui.menu.mainmenu.multiplayermenu.HostGameMenu.makeHostGameMenuAsParameter(\"join\")");
	--end
	--
	--table.insert(customMenuOpenParams, customMenuOpenMenuNames)
	--table.insert(customMenuOpenParams, customMenuOpenMenuPreFuncStrings)	
	--gui.menu.LoadingWindow.changeToMainMenuUsingLoadingWindowWithParams(nil, nil, customMenuOpenParams);

	
	-- Open pause menus's game host game menu (can't really do much here?)
	--gui.menu.Menus.switchToWindowState(nil, [[pauseMenu]]);
	--gui.menu.mainmenu.multiplayermenu.HostGameMenu.makeHostGameMenuAsParameter("pause");
	--gui.menu.Menus.switchToWindowState(nil, [[hostGameMenu]]);
end

function cinematicDone()
	--gui.menu.TapInfoPopup.closeWindow()
end


