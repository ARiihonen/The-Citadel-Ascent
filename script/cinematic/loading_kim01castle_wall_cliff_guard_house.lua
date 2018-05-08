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
cinematicName = "cinematic.LoadingKim01CastleWallCliffGuardHouse";

-----------------------------------------------------
-- Content
-----------------------------------------------------

function getLoadingTextLocales()

	return 
	{
		
	}

end


-- LOADING SCREEN 4
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
	
	
	-- LOADING SCREEN 4
	
	-- Start the speeches
	if traumatizingMissionNumber == 2 then
		narratorLineTrauma2_1();
	elseif traumatizingMissionNumber == 3 then
		narratorLineTrauma3_1();
	elseif traumatizingMissionNumber == 4 then
		narratorLineTimetravel1();
	elseif traumatizingMissionNumber == 5 then
		narratorLineTimetravel1();
	elseif traumatizingMissionNumber == 6 then
		narratorLineTimetravel1();
	elseif traumatizingMissionNumber == 7 then
		narratorLineTimetravel1();
	elseif traumatizingMissionNumber == 8 then
		narratorLineTimetravel1();
	elseif traumatizingMissionNumber == 9 then
		narratorLineTimetravel1();
	elseif traumatizingMissionNumber == 10 then
		narratorLineTimetravel1();		
	elseif traumatizingMissionNumber == 11 then
		narratorLineTimetravel1();
	elseif traumatizingMissionNumber == 12 then
		narratorLineTimetravel1();
	elseif traumatizingMissionNumber == 13 then
		narratorLineTimetravel1();
	elseif traumatizingMissionNumber == 14 then
		narratorLineTimetravel1();
	elseif traumatizingMissionNumber == 15 then
		narratorLineTimetravel1();		
	else
		narratorLineNoTrauma1();
	end
end

	
-- TRAUMA MISSION 2 - TRAUMA FROM LEVEL 2
	
function narratorLineTrauma2_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i4_01_lily",
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma2_2()")
end

function narratorLineTrauma2_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i4_02_shadwen", 
	nil, 6000, 700, cinematicName .. ".narratorLineTrauma2_3()")
end

function narratorLineTrauma2_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i4_03_lily",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma2_4()")
end

function narratorLineTrauma2_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i4_04_shadwen",
	nil, 2000, 700, cinematicName .. ".theEnd()")
end


-- TRAUMA MISSION 3 - TRAUMA FROM LEVEL 3
	
function narratorLineTrauma3_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i1_01_lily",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma3_2()")
end

function narratorLineTrauma3_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i1_02_shadwen", 
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma3_3()")
end

function narratorLineTrauma3_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i1_03_lily",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma3_4()")
end

function narratorLineTrauma3_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i1_04_shadwen",
	nil, 2000, 700, cinematicName .. ".theEnd()")
end


-- NO TRAUMA

function narratorLineNoTrauma1()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_02_01_lily",
	nil, 2000, 700, cinematicName .. ".narratorLineNoTrauma2()")
end

function narratorLineNoTrauma2()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_02_02_shadwen", 
	nil, 1000, 700, cinematicName .. ".narratorLineNoTrauma3()")
end

function narratorLineNoTrauma3()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_02_03_lily", 
	nil, 2000, 1000, cinematicName .. ".narratorLineNoTrauma4()")
end

function narratorLineNoTrauma4()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_02_04_shadwen", 
	nil, 1000, 700, cinematicName .. ".narratorLineNoTrauma5()")
end

function narratorLineNoTrauma5()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_02_05_lily", 
	nil, 4000, 700, cinematicName .. ".narratorLineNoTrauma6()")
end

function narratorLineNoTrauma6()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_02_06_shadwen", 
	nil, 1000, 700, cinematicName .. ".narratorLineNoTrauma7()")
end
	
function narratorLineNoTrauma7()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_02_07_lily", 
	nil, 2000, 700, cinematicName .. ".theEnd()")
end

-- TIMETRAVEL

function narratorLineTimetravel1()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_14_01_lily", 
	nil, 2000, 700, cinematicName .. ".narratorLineTimetravel2()")
end

function narratorLineTimetravel2()
	cinematic.CinematicUtil.playSpeech("Play_vocal_sfx_shadwen_thoughtful", 
	nil, 1000, 700, cinematicName .. ".theEnd()")
end	

function theEnd()
	cinematic.CinematicUtil.loadingCinematicDone()
end