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
cinematicName = "cinematic.LoadingMikko02PoorDistrictPoorSquare";

-----------------------------------------------------
-- Content
-----------------------------------------------------

function getLoadingTextLocales()

	return 
	{
	
	}

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
	
	-- LOADING SCREEN 10
	-- Start the speeches
	if traumatizingMissionNumber == 2 then
		narratorLineTrauma2_1();
	elseif traumatizingMissionNumber == 3 then
		narratorLineTrauma3_1();
	elseif traumatizingMissionNumber == 4 then
		narratorLineTrauma4_1();
	elseif traumatizingMissionNumber == 5 then
		narratorLineTrauma5_1();
	elseif traumatizingMissionNumber == 6 then
		narratorLineTrauma6_1();
	elseif traumatizingMissionNumber == 7 then
		narratorLineTrauma7_1();
	elseif traumatizingMissionNumber == 8 then
		narratorLineTrauma8_1();
	elseif traumatizingMissionNumber == 9 then
		narratorLineTrauma9_1();
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
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b2_01_shadwen",
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma2_2()")
end

function narratorLineTrauma2_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b2_02_lily", 
	nil, 15000, 700, cinematicName .. ".narratorLineTrauma2_3()")
end

function narratorLineTrauma2_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b2_03_shadwen", 
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma2_4()")
end

function narratorLineTrauma2_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b2_04_lily", 
	nil, 6000, 700, cinematicName .. ".narratorLineTrauma2_5()")
end

function narratorLineTrauma2_5()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b2_05_shadwen",
	nil, 10000, 700, cinematicName .. ".theEnd()")
end


-- TRAUMA MISSION 3 - TRAUMA FROM LEVEL 3
	
function narratorLineTrauma3_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b2_01_shadwen",
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma3_2()")
end

function narratorLineTrauma3_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b2_02_lily", 
	nil, 15000, 700, cinematicName .. ".narratorLineTrauma3_3()")
end

function narratorLineTrauma3_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b2_03_shadwen", 
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma3_4()")
end

function narratorLineTrauma3_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b2_04_lily", 
	nil, 6000, 700, cinematicName .. ".narratorLineTrauma3_5()")
end

function narratorLineTrauma3_5()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b2_05_shadwen",
	nil, 10000, 700, cinematicName .. ".theEnd()")
end


-- TRAUMA MISSION 4 - TRAUMA FROM LEVEL 4
	
function narratorLineTrauma4_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b1_01_lily",
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma4_2()")
end

function narratorLineTrauma4_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b1_02_shadwen", 
	nil, 12000, 700, cinematicName .. ".narratorLineTrauma4_3()")
end

function narratorLineTrauma4_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b1_03_shadwen",
	nil, 14000, 700, cinematicName .. ".theEnd()")
end


-- TRAUMA MISSION 5 - TRAUMA FROM LEVEL 5

function narratorLineTrauma5_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a3_01_lily",
	nil, 6000, 700, cinematicName .. ".narratorLineTrauma5_2()")
end

function narratorLineTrauma5_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a3_02_shadwen", 
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma5_3()")
end

function narratorLineTrauma5_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a3_03_shadwen",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma5_4()")
end

function narratorLineTrauma5_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a3_04_lily",
	nil, 4000, 700, cinematicName .. ".theEnd()")
end	

-- TRAUMA MISSION 6 - TRAUMA FROM LEVEL 6
	
function narratorLineTrauma6_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a2_01_lily",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma6_2()")
end

function narratorLineTrauma6_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a2_02_shadwen", 
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma6_3()")
end

function narratorLineTrauma6_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a2_03_lily",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma6_4()")
end

function narratorLineTrauma6_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a2_04_shadwen",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma6_5()")
end

function narratorLineTrauma6_5()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a2_05_lily",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma6_6()")
end

function narratorLineTrauma6_6()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a2_06_shadwen",
	nil, 1000, 700, cinematicName .. ".theEnd()")
end


-- TRAUMA MISSION 7 - TRAUMA FROM LEVEL 7
	
function narratorLineTrauma7_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a1_01_lily",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma7_2()")
end

function narratorLineTrauma7_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a1_02_shadwen", 
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma7_3()")
end

function narratorLineTrauma7_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a1_03_lily",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma7_4()")
end

function narratorLineTrauma7_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a1_04_shadwen",
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma7_5()")
end

function narratorLineTrauma7_5()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a1_05_lily",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma7_6()")
end

function narratorLineTrauma7_6()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a1_06_shadwen",
	nil, 6000, 700, cinematicName .. ".narratorLineTrauma7_7()")
end

function narratorLineTrauma7_7()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a1_07_lily",
	nil, 3000, 700, cinematicName .. ".theEnd()")
end

-- TRAUMA MISSION 8 - TRAUMA FROM LEVEL 8
	
function narratorLineTrauma8_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i2_01_lily",
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma8_2()")
end

function narratorLineTrauma8_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i2_02_shadwen", 
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma8_3()")
end

function narratorLineTrauma8_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i2_03_lily",
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma8_4()")
end

function narratorLineTrauma8_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i2_04_shadwen",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma8_5()")
end

function narratorLineTrauma8_5()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i2_05_lily",
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma8_6()")
end

function narratorLineTrauma8_6()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i3_01_shadwen",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma8_7()")
end

function narratorLineTrauma8_7()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i3_02_lily",
	nil, 1000, 700, cinematicName .. ".theEnd()")
end

-- TRAUMA MISSION 9 - TRAUMA FROM LEVEL 9
	
function narratorLineTrauma9_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i1_01_lily",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma9_2()")
end

function narratorLineTrauma9_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i1_02_shadwen", 
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma9_3()")
end

function narratorLineTrauma9_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i1_03_lily",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma9_4()")
end

function narratorLineTrauma9_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i1_04_shadwen",
	nil, 2000, 700, cinematicName .. ".theEnd()")
end


-- NO TRAUMA

function narratorLineNoTrauma1()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_08_01_lily",
	nil, 3000, 700, cinematicName .. ".narratorLineNoTrauma2()")
end

function narratorLineNoTrauma2()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_08_02_shadwen", 
	nil, 1000, 700, cinematicName .. ".narratorLineNoTrauma3()")
end

function narratorLineNoTrauma3()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_08_03_lily", 
	nil, 9000, 700, cinematicName .. ".narratorLineNoTrauma4()")
end

function narratorLineNoTrauma4()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_08_04_lily", 
	nil, 6000, 700, cinematicName .. ".theEnd()")
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