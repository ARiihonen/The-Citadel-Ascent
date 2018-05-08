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
cinematicName = "cinematic.LoadingAnna04TutorialLilyAndShadwen";

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

-- LOADING SCREEN 3
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
	if traumatizingMissionNumber == 2 then
		narratorLineTrauma2_1();
	elseif traumatizingMissionNumber == 3 then
		narratorLineTimetravel1();
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
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i2_01_lily",
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma2_2()")
end

function narratorLineTrauma2_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i2_02_shadwen", 
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma2_3()")
end

function narratorLineTrauma2_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i2_03_lily",
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma2_4()")
end

function narratorLineTrauma2_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i2_04_shadwen",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma2_5()")
end

function narratorLineTrauma2_5()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i2_05_lily", 
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma2_6()")
end

function narratorLineTrauma2_6()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i3_01_shadwen",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma2_7()")
end

function narratorLineTrauma2_7()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i3_02_lily",
	nil, 1000, 700, cinematicName .. ".theEnd()")
end

-- NO TRAUMA

function narratorLineNoTrauma1()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_01_01_lily",
	nil, 1000, 700, cinematicName .. ".narratorLineNoTrauma2()")
end

function narratorLineNoTrauma2()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_01_02_shadwen", 
	nil, 1000, 1000, cinematicName .. ".narratorLineNoTrauma3()")
end

function narratorLineNoTrauma3()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_01_03_lily", 
	nil, 2000, 700, cinematicName .. ".narratorLineNoTrauma4()")
end

function narratorLineNoTrauma4()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_01_04_shadwen", 
	nil, 2000, 1000, cinematicName .. ".narratorLineNoTrauma5()")
end

function narratorLineNoTrauma5()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_01_05_lily", 
	nil, 3000, 450, cinematicName .. ".narratorLineNoTrauma6()")
end

function narratorLineNoTrauma6()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_02_02_shadwen", 
	nil, 1000, 700, cinematicName .. ".theEnd()")
end

-- TIMETRAVEL

function narratorLineTimetravel1()
	cinematic.CinematicUtil.playSpeech("Play_vocal_sfx_lily_sigh_relief", 
	nil, 1000, 700, cinematicName .. ".narratorLineTimetravel2()")
end

function narratorLineTimetravel2()
	cinematic.CinematicUtil.playSpeech("Play_vocal_sfx_shadwen_displeased", 
	nil, 1000, 700, cinematicName .. ".theEnd()")
end

function theEnd()
	cinematic.CinematicUtil.loadingCinematicDone()
end