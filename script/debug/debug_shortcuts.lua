
--[[
This file creates just some global debug shortcuts
]]

do
	function errChk()
		if not debugComponent then logger:error("debugComponent is NIL") end
	end
	
	if debug then
		debug.toggleControllerInfoOverlay = function() errChk() debugComponent:toggleControllerInfoOverlay() end
		debug.toggleFuiInputEventOverlay = function() errChk() debugComponent:toggleFuiInputEventOverlay() end
		debug.toggleDebugStatsOverlay = function() errChk() debugComponent:toggleDebugStatsOverlay() end
	end
end
