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
cinematicName = "cinematic.LoadingVille02PoorDistrictPoorHousing";

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
	
	-- LOADING SCREEN 8
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
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a3_01_lily",
	nil, 6000, 700, cinematicName .. ".narratorLineTrauma2_2()")
end

function narratorLineTrauma2_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a3_02_shadwen", 
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma2_3()")
end

function narratorLineTrauma2_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a3_03_shadwen",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma2_4()")
end

function narratorLineTrauma2_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a3_04_lily",
	nil, 4000, 700, cinematicName .. ".theEnd()")
end


-- TRAUMA MISSION 3 - TRAUMA FROM LEVEL 3
	
function narratorLineTrauma3_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a3_01_lily",
	nil, 6000, 700, cinematicName .. ".narratorLineTrauma3_2()")
end

function narratorLineTrauma3_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a3_02_shadwen", 
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma3_3()")
end

function narratorLineTrauma3_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a3_03_shadwen",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma3_4()")
end

function narratorLineTrauma3_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a3_04_lily",
	nil, 4000, 700, cinematicName .. ".theEnd()")
end


-- TRAUMA MISSION 4 - TRAUMA FROM LEVEL 4
	
function narratorLineTrauma4_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a2_01_lily",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma4_2()")
end

function narratorLineTrauma4_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a2_02_shadwen", 
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma4_3()")
end

function narratorLineTrauma4_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a2_03_lily",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma4_4()")
end

function narratorLineTrauma4_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a2_04_shadwen",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma4_5()")
end

function narratorLineTrauma4_5()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a2_05_lily",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma4_6()")
end

function narratorLineTrauma4_6()
	cinematic.CinematicUtil.playSpeech("Play_protecting_01_01_shadwen",
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma4_7()")
end

function narratorLineTrauma4_7()
	cinematic.CinematicUtil.playSpeech("Play_protecting_01_02_lily",
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma4_8()")
end

function narratorLineTrauma4_8()
	cinematic.CinematicUtil.playSpeech("Play_protecting_01_03_shadwen",
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma4_9()")
end

function narratorLineTrauma4_9()
	cinematic.CinematicUtil.playSpeech("Play_protecting_01_04_lily",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma4_10()")
end

function narratorLineTrauma4_10()
	cinematic.CinematicUtil.playSpeech("Play_protecting_01_05_lily",
	nil, 6000, 700, cinematicName .. ".narratorLineTrauma4_11()")
end

function narratorLineTrauma4_11()
	cinematic.CinematicUtil.playSpeech("Play_protecting_01_06_lily",
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma4_12()")
end

function narratorLineTrauma4_12()
	cinematic.CinematicUtil.playSpeech("Play_protecting_01_07_shadwen",
	nil, 1000, 700, cinematicName .. ".theEnd()")
end


-- TRAUMA MISSION 5 - TRAUMA FROM LEVEL 5
	
function narratorLineTrauma5_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a1_01_lily",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma5_2()")
end

function narratorLineTrauma5_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a1_02_shadwen", 
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma5_3()")
end

function narratorLineTrauma5_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a1_03_lily",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma5_4()")
end

function narratorLineTrauma5_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a1_04_shadwen",
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma5_5()")
end

function narratorLineTrauma5_5()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a1_05_lily",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma5_6()")
end

function narratorLineTrauma5_6()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a1_06_shadwen",
	nil, 6000, 700, cinematicName .. ".narratorLineTrauma5_7()")
end

function narratorLineTrauma5_7()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a1_07_lily",
	nil, 3000, 700, cinematicName .. ".theEnd()")
end

-- TRAUMA MISSION 6 - TRAUMA FROM LEVEL 6
	
function narratorLineTrauma6_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i2_01_lily",
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma6_2()")
end

function narratorLineTrauma6_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i2_02_shadwen", 
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma6_3()")
end

function narratorLineTrauma6_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i2_03_lily",
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma6_4()")
end

function narratorLineTrauma6_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i2_04_shadwen",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma6_5()")
end

function narratorLineTrauma6_5()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i2_05_lily",
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma6_6()")
end

function narratorLineTrauma6_6()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i3_01_shadwen",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma6_7()")
end

function narratorLineTrauma6_7()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i3_02_lily",
	nil, 1000, 700, cinematicName .. ".theEnd()")
end

-- TRAUMA MISSION 7 - TRAUMA FROM LEVEL 7
	
function narratorLineTrauma7_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i1_01_lily",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma7_2()")
end

function narratorLineTrauma7_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i1_02_shadwen", 
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma7_3()")
end

function narratorLineTrauma7_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i1_03_lily",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma7_4()")
end

function narratorLineTrauma7_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_i1_04_shadwen",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma7_5()")
end

function narratorLineTrauma7_5()
	cinematic.CinematicUtil.playSpeech("Play_protecting_01_01_shadwen",
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma7_6()")
end

function narratorLineTrauma7_6()
	cinematic.CinematicUtil.playSpeech("Play_protecting_01_02_lily",
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma7_7()")
end

function narratorLineTrauma7_7()
	cinematic.CinematicUtil.playSpeech("Play_protecting_01_03_shadwen",
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma7_8()")
end

function narratorLineTrauma7_8()
	cinematic.CinematicUtil.playSpeech("Play_protecting_01_04_lily",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma7_9()")
end

function narratorLineTrauma7_9()
	cinematic.CinematicUtil.playSpeech("Play_protecting_01_05_lily",
	nil, 6000, 700, cinematicName .. ".narratorLineTrauma7_10()")
end

function narratorLineTrauma7_10()
	cinematic.CinematicUtil.playSpeech("Play_protecting_01_06_lily",
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma7_11()")
end

function narratorLineTrauma7_11()
	cinematic.CinematicUtil.playSpeech("Play_protecting_01_07_shadwen",
	nil, 1000, 700, cinematicName .. ".theEnd()")
end

-- NO TRAUMA

function narratorLineNoTrauma1()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_06_01_lily",
	nil, 1000, 700, cinematicName .. ".narratorLineNoTrauma2()")
end

function narratorLineNoTrauma2()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_06_02_lily", 
	nil, 8000, 700, cinematicName .. ".narratorLineNoTrauma3()")
end

function narratorLineNoTrauma3()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_06_03_lily", 
	nil, 2000, 700, cinematicName .. ".narratorLineNoTrauma4()")
end

function narratorLineNoTrauma4()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_06_04_shadwen", 
	nil, 4000, 700, cinematicName .. ".narratorLineNoTrauma5()")
end

function narratorLineNoTrauma5()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_06_05_lily", 
	nil, 13000, 700, cinematicName .. ".narratorLineNoTrauma6()")
end

function narratorLineNoTrauma6()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_06_06_shadwen", 
	nil, 2000, 700, cinematicName .. ".narratorLineNoTrauma7()")
end

function narratorLineNoTrauma7()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_06_07_lily", 
	nil, 2000, 700, cinematicName .. ".theEnd()")
end	

-- TIMETRAVEL

function narratorLineTimetravel1()
	cinematic.CinematicUtil.playSpeech("Play_food_shadwen_eat", 
	nil, 1000, 700, cinematicName .. ".narratorLineTimetravel2()")
end

function narratorLineTimetravel2()
	cinematic.CinematicUtil.playSpeech("Play_food_lily_delighted", 
	nil, 1000, 700, cinematicName .. ".narratorLineTimetravel3()")
end

function narratorLineTimetravel3()
	cinematic.CinematicUtil.playSpeech("Play_food_shadwen_hush", 
	nil, 1000, 700, cinematicName .. ".theEnd()")
end
	
function theEnd()
	cinematic.CinematicUtil.loadingCinematicDone()
end