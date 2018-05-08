module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

require "cinematic.CinematicUtil"

function start()
	if not common.CommonUtils.getAllowLogosOnStart() then
		return;
	end
	
	if state:isOffline() then
		-- Allow
	else
		-- Never allow logos (as they cannot be skipped in online game (cinematic skipping is disabled in online game)
		return;
	end
	
	cinematic.CinematicUtil.playLoadingScreenMusic("Play_startup_music");
	
	-- Attenuate music for 5 seconds tops. That is just an arbitary value, nothing important.
	local attenuationHandle = audioModule:addAttenuationFactor(audioModule.getAttenuationTypeEffect(), 1.0, 5.0)
	cinematic.CinematicUtil.effectAttenuationHandles[attenuationHandle] = attenuationHandle
	
	-- Starup logos moved to FUIStartupLogosComponent.
end
