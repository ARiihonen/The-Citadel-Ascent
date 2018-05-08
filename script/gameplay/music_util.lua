module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

require "mission.MissionMusicList"

function startMusic(startMusicMissionId)
	local playEventId = getMusicNameForMissionId(startMusicMissionId)
	if playEventId == nil or playEventId == "" then
		logger:info("menu_music_util:startMusic(" .. tostring(startMusicMissionId) .. ") translated to nil or empty event id, not playing anything.")
	elseif playEventId == mission.MissionMusicList.no_music_event then
		logger:info("menu_music_util:startMusic(" .. tostring(startMusicMissionId) .. ") translated to no_music_event id. Stopping current music")
		stopMusic()
	else
		common.CommonUtils.playMusicAudioEvent(playEventId)
	end
end

function stopMusic()
	common.CommonUtils.playMusicAudioEvent("")
end

function getMusicNameForMissionId(missionId)
	local music = mission.MissionMusicList.music
	if (missionId ~= nil) then
		-- NOTE: Add "mission_" prefix to missionIDs since LUA doesn't really like variable names which starts with numbers
		local missionMusicStr = "mission_" .. missionId;
		local playEventId = music[missionMusicStr];
		return playEventId;
	else
		-- NOTE: Do not spam the error on missing music, this will be spammed to all test levels as well
		-- TODO: Should determine is the mission actual mission or test mission
		--logger:error("gui::menu::MissionMusicList::startMusic - playEventId is nil with given mission param: \"mission_" .. startMusicMissionId .. "\". Check file: data\\script\\gui\\menu\\mission_music_list.lua");
		return nil;
	end
end

function startCurrentMissionMusic()
	local sce = common.CommonUtils.getScene();
	if sce ~= nil then
		local sceneInstanceManager = sce:getSceneInstanceManager();
		if sceneInstanceManager ~= nil then
			local missionManager = common.CommonUtils.getMissionManager();
			local missionId = "";
			if missionManager ~= nil then
				missionId = missionManager:getCurrentMissionID();
					-- Audiomodule checks if this music is different than before
				startMusic(missionId);	
			end
			
			-- stop ambient sounds to be sure
			audioModule:resetLastPlayedAmbientInfo();
		end
	end
end
