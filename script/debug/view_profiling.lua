module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

require "debug.AnimatedLightProfiling"
require "debug.GuiProfiling"

----------------------------------------------------------------------------------------------------------

local thisModule = _M

declareManualReload(thisModule, [[previousViewMsecPerFrame]])
declareManualReload(thisModule, [[currentViewProfilingCycles]])
declareManualReload(thisModule, [[currentViewProfilingDuration]])

-- milliseconds per cycle
currentViewProfilingDuration = 2000

previousViewMsecPerFrame = 0

-- run these profiling cycles (steps)
currentViewProfilingCycles = {
	initial = { 
		stepInitFunction = [[setCurrentViewProfilingInitial]],
		deltaStatsVariable = "initialViewMsecX10", totalStatsVariable = "initialViewTotalFrameMsecX10", nextCycle = "minimal" 
	}
	, minimal = { 
		stepInitFunction = [[setCurrentViewProfilingMinimal]],
		deltaStatsVariable = "minimalViewMsecX10", totalStatsVariable = "minimalViewTotalFrameMsecX10", nextCycle = "geometry" 
	}
	, geometry = { 
		stepInitFunction = [[setCurrentViewProfilingGeometry]],
		deltaStatsVariable = "geometryViewMsecX10", totalStatsVariable = "geometryViewTotalFrameMsecX10", nextCycle = "pointlights" 
	}
	, pointlights = { 
		stepInitFunction = [[setCurrentViewProfilingPointlights]],
		deltaStatsVariable = "pointlightsViewMsecX10", totalStatsVariable = "pointlightsViewTotalFrameMsecX10", nextCycle = "spotlights" 
	}
	, spotlights = { 
		stepInitFunction = [[setCurrentViewProfilingSpotlights]],
		deltaStatsVariable = "spotlightsViewMsecX10", totalStatsVariable = "spotlightsViewTotalFrameMsecX10", nextCycle = nil
	}
}

function setCurrentViewProfilingInitial()
	renderingModule:setShowDebugText(false)
end
function setCurrentViewProfilingMinimal()
	renderingModule:setGeometryEnabled(false)
	renderingModule:setSpotlightsEnabled(false)
	renderingModule:setPointlightsEnabled(false)
end
function setCurrentViewProfilingGeometry()
	renderingModule:setGeometryEnabled(true)
end
function setCurrentViewProfilingPointlights()
	renderingModule:setPointlightsEnabled(true)
end
function setCurrentViewProfilingSpotlights()
	renderingModule:setSpotlightsEnabled(true)
end

----------------------------------------------------------------------------------------------------------

function profileCurrentView()
	debug.DebugStatsOverlayUtil.clearOverlay()
	debug.DebugStatsOverlayUtil.addCurrentViewProfilingInProgress()
	previousViewMsecPerFrame = 0
	local cycleTableName = "debug.ViewProfiling.currentViewProfilingCycles"
	state:runLuaString("debug.ViewProfiling.profileCurrentViewCycleImpl("..cycleTableName..", \""..cycleTableName.."\", \"initial\")")
end

function profileCurrentViewCloseConsole()
	profileCurrentView()
	if developerConsole then
		developerConsole:setIsConsoleOpen(false)
	end
end

function profileTogglePointlights()
	renderingModule:setPointlightsEnabled(not renderingModule:getPointlightsEnabled())
end

function profileToggleSpotlights()
	renderingModule:setSpotlightsEnabled(not renderingModule:getSpotlightsEnabled())
end

-- alias for faster autocomplete.
_G.d_profileview = profileCurrentViewCloseConsole

_G.d_togglepointlights = profileTogglePointlights
_G.d_togglespotlights = profileToggleSpotlights

----------------------------------------------------------------------------------------------------------

function profileCurrentViewDone()
	debug.DebugStatsOverlayUtil.clearOverlay()
	debug.DebugStatsOverlayUtil.addFrameratesToOverlay()
	debug.DebugStatsOverlayUtil.addCurrentViewProfilingStats()

	logger:info("Profiling current view done.")

	-- TODO: should restore the original value!
	renderingModule:setShowDebugText(false)	
end

----------------------------------------------------------------------------------------------------------

function profileCurrentViewCycleImpl(profileCyclesTable, profileCyclesTableNameString, cycleName)
	assert_table(profileCyclesTable)
	assert_string(profileCyclesTableNameString)
	assert_string(cycleName)

	--logger:info("Profiling current view cycle start: "..cycleName)

	local profileCycleEntry = profileCyclesTable[cycleName]
	assert_table(profileCycleEntry)
	
	thisModule[profileCycleEntry.stepInitFunction]()
	app:startCurrentViewProfiling()	
		
	-- one second profiling interval
	-- TODO: the first run param should be passed here as a param.
	state:runLuaStringWithDelay("debug.ViewProfiling.profileCurrentViewCycleImplDone("..profileCyclesTableNameString..", \""..profileCyclesTableNameString.."\", \""..cycleName.."\")", currentViewProfilingDuration)
end

----------------------------------------------------------------------------------------------------------

function profileCurrentViewCycleImplDone(profileCyclesTable, profileCyclesTableNameString, cycleName)
	assert_table(profileCyclesTable)
	assert_string(profileCyclesTableNameString)
	assert_string(cycleName)

	--logger:info("Profiling current view cycle done: "..cycleName)
	
	local profileCycleEntry = profileCyclesTable[cycleName]
	assert_table(profileCycleEntry)

	app:stopCurrentViewProfiling()
	
	-- (the time should be approx. the currentViewProfilingDuration milliseconds given as parameter)
	local timeMsec = app:getCurrentViewProfilingTime()
	if (timeMsec < 1) then timeMsec = 1 end
	local frames = app:getCurrentViewProfilingFrames()
	if (frames < 1) then frames = 1 end
	local msecPerFrame = timeMsec / frames
	local fps = frames / timeMsec
	local msecDelta = msecPerFrame - previousViewMsecPerFrame
	
	if (debugStatsModule) then
		debugStatsModule:setDebugStatsValue("fb::trine2::Trine2Application", profileCycleEntry.totalStatsVariable, msecPerFrame * 10)
		debugStatsModule:setDebugStatsValue("fb::trine2::Trine2Application", profileCycleEntry.deltaStatsVariable, msecDelta * 10)
		--debugStatsModule:setDebugStatsValue("fb::trine2::Trine2Application", profileCycleEntry.fpsStatsVariable, fps)
	else
		logger:info(profileCycleEntry.totalStatsVariable .. tostring(msecPerFrame))
		logger:info(profileCycleEntry.deltaStatsVariable .. tostring(msecPerFrame - previousViewMsecPerFrame))
	end
	
	previousViewMsecPerFrame = msecPerFrame
	
	if (profileCycleEntry.nextCycle) then
		if (cycleName == profileCycleEntry.nextCycle) then
			logger:error("Oops, infinite profiling cycle loop.")
		else
			profileCurrentViewCycleImpl(profileCyclesTable, profileCyclesTableNameString, profileCycleEntry.nextCycle)
		end
	else
		profileCurrentViewDone()
	end
end

----------------------------------------------------------------------------------------------------------

function hideModels(filenamePart)
	gameScene:getSceneInstanceManager():findInstanceByName("optimizedEntity"):hideModelsByFilename(filenamePart)
end

function showModels(filenamePart)
	gameScene:getSceneInstanceManager():findInstanceByName("optimizedEntity"):showModelsByFilename(filenamePart)
end

function setModelVisibilityByFilename(filenamePart, visible)
	gameScene:getSceneInstanceManager():findInstanceByName("optimizedEntity"):setModelVisibilityByFilename(filenamePart, visible)
end


