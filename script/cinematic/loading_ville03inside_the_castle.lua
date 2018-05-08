module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

require "cinematic.CinematicUtil"

------------------------------------------------
-- Globals
------------------------------------------------

local thisModule = _M
local tm = thisModule

-- this is required to exist by the util
declareReload(thisModule, [[cinematicName]])
cinematicName = "cinematic.LoadingVille03InsideTheCastle";

-----------------------------------------------------
-- Content
-----------------------------------------------------

function getLoadingTextLocales()

	return 
	{
	
	}

end

function startMusic()
	return cinematic.CinematicUtil.playLoadingScreenMusic(nil)
end

function start(traumatizingMissionNumber)

	-- If running expo or stage demo, skip the speeches
	if gameBaseApplicationModule:getDemo() then
		if gameBaseApplicationModule:getDemoExpo() then
			theEnd();
			return;			
		elseif gameBaseApplicationModule:getDemoStage() then
			theEnd();
			return;
		end
	end
	
	-- LOADING SCREEN 3
	
	-- Start the speeches
	if traumatizingMissionNumber == 14 then
		narratorLineTrauma14_1();
	elseif traumatizingMissionNumber == 15 then
		narratorLineTrauma14_1();	
	else
		narratorLineTrauma1();
	end	
end
	

-- TRAUMA MISSION 14 - TRAUMA FROM LEVEL 14
	
function narratorLineTrauma14_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_00_01_lily",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma14_2()")
end

function narratorLineTrauma14_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_00_02_shadwen", 
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma14_3()")
end

function narratorLineTrauma14_3()
	cinematic.CinematicUtil.playSpeech("Play_guard_overheard_guards_15_01_guard2",
	nil, 5000, 700, cinematicName .. ".narratorLineTrauma14_4()")
end

function narratorLineTrauma14_4()
	cinematic.CinematicUtil.playSpeech("Play_guard_overheard_guards_15_02_guard3",
	nil, 9000, 700, cinematicName .. ".narratorLineTrauma14_5()")
end

function narratorLineTrauma14_5()
	cinematic.CinematicUtil.playSpeech("Play_guard_overheard_guards_15_03_guard2", 
	nil, 12000, 700, cinematicName .. ".narratorLineTrauma14_6()")
end

function narratorLineTrauma14_6()
	cinematic.CinematicUtil.playSpeech("Play_guard_overheard_guards_15_04_guard3",
	nil, 8000, 700, cinematicName .. ".narratorLineTrauma14_7()")
end

function narratorLineTrauma14_7()
	cinematic.CinematicUtil.playSpeech("Play_guard_overheard_guards_15_05_shadwen",
	nil, 2000, 700, cinematicName .. ".theEnd()")
end

-- ALL ELSE

function narratorLineTrauma1()
	cinematic.CinematicUtil.playSpeech("Play_guard_overheard_guards_15_01_guard2",
	nil, 5000, 700, cinematicName .. ".narratorLineTrauma2()")
end

function narratorLineTrauma2()
	cinematic.CinematicUtil.playSpeech("Play_guard_overheard_guards_15_02_guard3",
	nil, 9000, 700, cinematicName .. ".narratorLineTrauma3()")
end

function narratorLineTrauma3()
	cinematic.CinematicUtil.playSpeech("Play_guard_overheard_guards_15_03_guard2", 
	nil, 12000, 700, cinematicName .. ".narratorLineTrauma4()")
end

function narratorLineTrauma4()
	cinematic.CinematicUtil.playSpeech("Play_guard_overheard_guards_15_04_guard3",
	nil, 8000, 700, cinematicName .. ".narratorLineTrauma5()")
end

function narratorLineTrauma5()
	cinematic.CinematicUtil.playSpeech("Play_guard_overheard_guards_15_05_shadwen",
	nil, 2000, 700, cinematicName .. ".theEnd()")
end

function theEnd()
	cinematic.CinematicUtil.loadingCinematicDone()
end