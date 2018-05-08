module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

require "cinematic.CinematicUtil"

local thisModule = _M
declareReload(thisModule, [[waitTimer]])
declareManualReload(thisModule, [[waitStep]])
declareManualReload(thisModule, [[speechesDone]])
declareManualReload(thisModule, [[videoDone]])

waitTimer = nil
waitStep = 500 
-- don't touch this. it needs to be in some appropriate range (not too low, not too high)
-- too high a value causes notable skipping delay
-- too low a value causes rounding errors to accumulate, causing incorrect timing

function start()
	-- Skips the tutorial intro if using a mod 
	if(common.CommonUtils.getFirstMissionIDName() ~= "01_tutorial") then
		if(state:isOffline() or state:isServer()) then
			mission.MissionChangeUtil.changeToMissionUsingLoadingWindow(common.CommonUtils.getFirstMissionIDName())
		end
		return
	end
	
	-- Disable game input
	if gameStatusModule then gameStatusModule:setGameInputDisableStatus("IntroCinematicInput", 10, true) end
	
	-- NOTE: Find the manager and try to start the intro
	local manager = getIntroManager()
	local mainmenuManager = getMainMenuManager()
	
	if not manager or not mainmenuManager then
		allDone()
		return
	end
	
	cinematic.CinematicUtil.skippingGUICinematic = false
	cinematic.CinematicUtil.setIntroCinematicIsPlaying(true)
	cinematic.CinematicUtil.setIntroCinematicCanBeSkipped(true)
	
	-- TODO: Should get rid of the separate intro handler and just combine it to mainmenu manager.
	manager:startIntro()
	mainmenuManager:handleIntroWarp()
end

function getIntroManager()
	if not gameScene then
		return nil
	end
	
	local managerInst = gameScene:getSceneInstanceManager():findInstanceByName("intro_cinematic")
	if not managerInst then
		return nil
	end
	
	local manager = managerInst:findComponent(gameplay.IntroCinematicComponent)
	if not manager then
		return nil
	end
	
	return manager
end

function getMainMenuManager()
	local managerInst = common.CommonUtils.getMainMenuManager();
	if not managerInst then return nil end
	
	local manager = managerInst:findComponent(trinebase.gameplay.mission.TrineMainMenuHelperComponent)
	if not manager then return nil end
	
	return manager
end

function allDone()
	cinematic.CinematicUtil.cinematicDone()
	
	if gameStatusModule then gameStatusModule:removeGameInputDisableStatus("IntroCinematicInput") end
	
	-- (ensuring that the cinematic skipping flag is sure to get cleared, even though missing change should do that anyway)
	cinematic.CinematicUtil.skippingGUICinematic = false	
	cinematic.CinematicUtil.setIntroCinematicIsPlaying(false)
	cinematic.CinematicUtil.setIntroCinematicCanBeSkipped(false)

	-- hack, make sure the window really disappears instantly, so the loading window can be seen
	cinematic.CinematicUtil.removeBackground("blackBackground", 0, 0)
	
	-- NOTE: New logic, don't load map anymore directly if playable level selection is active. Goes to map instead.
	if common.CommonUtils.getLevelSelectionPlayable() then
		local mainmenuManager = getMainMenuManager()
		if mainmenuManager then
			mainmenuManager:handleIntroWarp()
		end
	else
		if (state:isOffline() or state:isServer()) then
			mission.MissionChangeUtil.changeToMission(common.CommonUtils.getFirstMissionIDName())
		end
	end
end
