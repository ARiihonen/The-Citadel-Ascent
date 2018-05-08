module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

require "cinematic.CinematicUtil"

local thisModule = _M

-- NOTE: Basically don't need to do much in here anymore, but decided to keep the LUA file anyhow.

function startCredits()
	common.CommonUtils.playMusicAudioEvent("Stop_ALL_music")	
	common.CommonUtils.playGUIAudioEvent("stop_all_ambients")
	
	common.CommonUtils.makeGameCompleted();
	
	state:setFUIHintFirstTimeInLevel(true);
	
	-- Make sure that trophies gets updated
	if(state:isOffline() or state:isServer()) then
		common.CommonUtils.getTrophyDetectionManager():sendEndOfMissionEvent()
	end

	if state:isOffline() then
		cinematic.CinematicUtil.handleOfflineGameEnd();
	else
		cinematic.CinematicUtil.handleOnlineGameEndThroughCredits();
	end
end