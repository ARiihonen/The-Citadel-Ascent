module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

--[[
	This file is just used as a quick way to add certain stats to DebugStatsOverlay.
	The actual code is in fb::gamebase::gui::FUIDebugStatsOverlayComponent.
]]

function addVariableToOverlay(scope, variableName)
	if not debugStatsOverlay then
		-- if debugStatsOverlay is NIL first try to toggle it
		if not debugComponent then
			logger:error("debug.DebugStatsOverlayUtil.addVariableToOverlay - debugComponent is NIL, cannot add variables to debug stats overlay")
			return
		end
		
		if not debugComponent.toggleDebugStatsOverlay then
			logger:error("debug.DebugStatsOverlayUtil.addVariableToOverlay - debugComponent.toggleDebugStatsOverlay function does not exist, cannot add variables to debug stats overlay")
			return
		end
		
		debugComponent:toggleDebugStatsOverlay()
		
		if not debugStatsOverlay then
			logger:error("debug.DebugStatsOverlayUtil.addVariableToOverlay - debugStatsOverlay is NIL, cannot add variables to debug stats overlay")
			return
		end
	end
	
	if not scope then
		logger:error("debug.DebugStatsOverlayUtil.addVariableToOverlay - scope argument was NIL")
		return
	end
	if not variableName then
		variableName = ""
	end
	
	debugStatsOverlay:addVariableToOverlay(scope, variableName)
end

function clearOverlay()
	if not debugStatsOverlay then
		-- if debugStatsOverlay is NIL first try to toggle it
		if not debugComponent then
			logger:error("debug.DebugStatsOverlayUtil.addVariableToOverlay - debugComponent is NIL, cannot add variables to debug stats overlay")
			return
		end
		
		if not debugComponent.toggleDebugStatsOverlay then
			logger:error("debug.DebugStatsOverlayUtil.addVariableToOverlay - debugComponent.toggleDebugStatsOverlay function does not exist, cannot add variables to debug stats overlay")
			return
		end
		
		debugComponent:toggleDebugStatsOverlay()
		
		if not debugStatsOverlay then
			logger:error("debug.DebugStatsOverlayUtil.addVariableToOverlay - debugStatsOverlay is NIL, cannot add variables to debug stats overlay")
			return
		end
	end
	
	debugStatsOverlay:clearOverlay()
end

function addFrameratesToOverlay()
	addVariableToOverlay("fb::rendering::RenderingModule", "FPS")
	--if platformModule:isPlatformTypeConsole() then
		--addVariableToOverlay("fb::rendering::RenderingModule", "GPUtms")
	--end

	addVariableToOverlay("fb::rendering::RenderingScene", "gpuTotalEstimateTMs")
	addVariableToOverlay("fb::rendering::RenderingScene", "gpuShadowsTMs")
	addVariableToOverlay("fb::rendering::RenderingScene", "gpuGeometryTMs")
	addVariableToOverlay("fb::rendering::RenderingScene", "gpuBacklightTMs")
	addVariableToOverlay("fb::rendering::RenderingScene", "gpuAOTMs")
	addVariableToOverlay("fb::rendering::RenderingScene", "gpuPointlightTMs")
	addVariableToOverlay("fb::rendering::RenderingScene", "gpuCascadeTMs")
	addVariableToOverlay("fb::rendering::RenderingScene", "gpuSpotlightTMs")
	addVariableToOverlay("fb::rendering::RenderingScene", "gpuFogSpotlightTMs")
	addVariableToOverlay("fb::rendering::RenderingScene", "gpuAlphaTMs")
	addVariableToOverlay("fb::rendering::RenderingScene", "gpuParticlesTMs")
	addVariableToOverlay("fb::rendering::RenderingScene", "gpuGlowAndConesTMs")
	addVariableToOverlay("fb::rendering::RenderingScene", "gpuGlow2DTMs")
	addVariableToOverlay("fb::rendering::RenderingScene", "gpuDistortionAndParticlesTMs")
	addVariableToOverlay("fb::rendering::RenderingScene", "gpuPostprocessTMs")
	addVariableToOverlay("fb::rendering::RenderingScene", "gpuFxaaTMs")
	
	addVariableToOverlay("fb::rendering::RenderingModule", "drawCalls")
	addVariableToOverlay("fb::rendering::RenderingModule", "drawCallsSimple")
	addVariableToOverlay("fb::rendering::RenderingModule", "polygons")
end


function addTimeToOverlay()
	addVariableToOverlay("fb::trine2", "applicationTimeMinutes")
	addVariableToOverlay("fb::trine2", "applicationTimeSeconds")
	--addVariableToOverlay("fb::trine2", "applicationTimeMilliSeconds")
end


function addBandwidthToOverlay()
	addVariableToOverlay("fb::sys::net::Socket", "combinedBPS")
	addVariableToOverlay("fb::sys::net::Socket", "combinedPPS")
	addVariableToOverlay("fb::sys::net::Socket", "reliableBPS")
	addVariableToOverlay("fb::sys::net::Socket", "reliablePPS")
	addVariableToOverlay("fb::sys::net::Socket", "unreliableBPS")
	addVariableToOverlay("fb::sys::net::Socket", "unreliablePPS")
end

function addPingsToOverlay()
	addVariableToOverlay("fb::sync::NetSyncer", "pingToServer")
	addVariableToOverlay("fb::sync::NetSyncer", "pingToClient1")
	addVariableToOverlay("fb::sync::NetSyncer", "pingToClient2")
	addVariableToOverlay("fb::sync::NetSyncer", "pingToClient3")
end


function addTimersToOverlay()
	addVariableToOverlay("fb::gameplay::TimerComponent", "peakTimersRunningInGame")
	addVariableToOverlay("fb::gameplay::TimerComponent", "totalTimersRunningInGame")
	addVariableToOverlay("fb::gameplay::TimerComponent", "totalTimersEnabledInGame")
end

function addParticlesToOverlay()
	addVariableToOverlay("fb::particles::ParticleModule", "particleEffects")
	addVariableToOverlay("fb::particles::ParticleModule", "particlesSimulated")
	addVariableToOverlay("fb::particles::ParticleModule", "particlesRendered")
end

function addEffectsToOverlay()
	addVariableToOverlay("fb::gameplay::effect::EffectComponent", "totalEffectCreations")
	addVariableToOverlay("fb::gameplay::effect::EffectComponent", "totalEffectDestructions")
	addVariableToOverlay("fb::gameplay::effect::EffectComponent", "totalEffectActivations")
	addVariableToOverlay("fb::gameplay::effect::EffectScene", "effectSceneEffectRequests")
	addVariableToOverlay("fb::gameplay::effect::EffectScene", "effectSceneEffectCreations")
	addVariableToOverlay("fb::gameplay::effect::EffectScene", "effectPoolHitRate")
	addVariableToOverlay("fb::gameplay::effect::EffectComponent", "effectsActive")
	addVariableToOverlay("fb::gameplay::effect::EffectScene", "effectsInPool")
	addVariableToOverlay("fb::gameplay::effect::EffectScene", "effectsPurgedFromPool")
end

function addCurrentViewProfilingInProgress()
	--addVariableToOverlay("_", "View_Profiling_In_Progress_Dont_Touch_Anything")
	addVariableToOverlay("fb::rendering::RenderingModule", "FPS")
end

function addCurrentViewProfilingStats()
	--addVariableToOverlay("fb::trine2::Trine2Application", "initialViewMsecX10")
	addVariableToOverlay("fb::trine2::Trine2Application", "initialViewTotalFrameMsecX10")
	--addVariableToOverlay("fb::trine2::Trine2Application", "minimalViewMsecX10")
	addVariableToOverlay("fb::trine2::Trine2Application", "minimalViewTotalFrameMsecX10")
	addVariableToOverlay("fb::trine2::Trine2Application", "geometryViewMsecX10")
	--addVariableToOverlay("fb::trine2::Trine2Application", "geometryViewTotalFrameMsecX10")
	addVariableToOverlay("fb::trine2::Trine2Application", "pointlightsViewMsecX10")
	--addVariableToOverlay("fb::trine2::Trine2Application", "pointlightsViewTotalFrameMsecX10")
	addVariableToOverlay("fb::trine2::Trine2Application", "spotlightsViewMsecX10")
	--addVariableToOverlay("fb::trine2::Trine2Application", "spotlightsViewTotalFrameMsecX10")
end
