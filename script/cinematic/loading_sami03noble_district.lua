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
cinematicName = "cinematic.LoadingSami03NobleDistrict";

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
	
	-- LOADING SCREEN 13
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
		narratorLineTrauma10_1();
	elseif traumatizingMissionNumber == 11 then
		narratorLineTrauma11_1();
	elseif traumatizingMissionNumber == 12 then
		narratorLineTrauma12_1();
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
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_c2_01_lily",
	nil, 7000, 700, cinematicName .. ".narratorLineTrauma2_2()")
end

function narratorLineTrauma2_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_c2_02_shadwen", 
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma2_3()")
end

function narratorLineTrauma2_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_c2_03_lily", 
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma2_4()")
end

function narratorLineTrauma2_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_c2_04_shadwen", 
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma2_5()")
end

function narratorLineTrauma2_5()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_c2_05_lily", 
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma2_6()")
end

function narratorLineTrauma2_6()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_c2_06_shadwen",
	nil, 1000, 700, cinematicName .. ".theEnd()")
end

-- TRAUMA MISSION 3 - TRAUMA FROM LEVEL 3
	
function narratorLineTrauma3_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_c2_01_lily",
	nil, 7000, 700, cinematicName .. ".narratorLineTrauma3_2()")
end

function narratorLineTrauma3_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_c2_02_shadwen", 
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma3_3()")
end

function narratorLineTrauma3_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_c2_03_lily", 
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma3_4()")
end

function narratorLineTrauma3_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_c2_04_shadwen", 
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma3_5()")
end

function narratorLineTrauma3_5()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_c2_05_lily", 
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma3_6()")
end

function narratorLineTrauma3_6()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_c2_06_shadwen",
	nil, 1000, 700, cinematicName .. ".theEnd()")
end


-- TRAUMA MISSION 4 - TRAUMA FROM LEVEL 4
	
function narratorLineTrauma4_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_c1_01_lily",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma4_2()")
end

function narratorLineTrauma4_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_c1_02_shadwen", 
	nil, 8000, 700, cinematicName .. ".narratorLineTrauma4_3()")
end

function narratorLineTrauma4_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_c1_03_shadwen", 
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma4_4()")
end

function narratorLineTrauma4_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_c1_04_lily", 
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma4_5()")
end

function narratorLineTrauma4_5()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_c1_05_shadwen",
	nil, 1000, 700, cinematicName .. ".theEnd()")
end


-- TRAUMA MISSION 5 - TRAUMA FROM LEVEL 5

function narratorLineTrauma5_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b3_01_lily",
	nil, 8000, 700, cinematicName .. ".narratorLineTrauma5_2()")
end

function narratorLineTrauma5_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b3_02_shadwen", 
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma5_3()")
end

function narratorLineTrauma5_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b3_03_lily", 
	nil, 5000, 700, cinematicName .. ".narratorLineTrauma5_4()")
end

function narratorLineTrauma5_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b3_04_lily", 
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma5_5()")
end

function narratorLineTrauma5_5()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b3_05_shadwen",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma5_6()")
end 
	
function narratorLineTrauma5_6()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma5_7()")
end
function narratorLineTrauma5_7()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_01",
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma5_8()")
end
function narratorLineTrauma5_8()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_02",
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma5_9()")
end
function narratorLineTrauma5_9()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_03",
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma5_10()")
end
function narratorLineTrauma5_10()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_04",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma5_11()")
end
function narratorLineTrauma5_11()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_05",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma5_12()")
end
function narratorLineTrauma5_12()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_06",
	nil, 5000, 900, cinematicName .. ".narratorLineTrauma5_13()")
end
function narratorLineTrauma5_13()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_07",
	nil, 1000, 700, cinematicName .. ".theEnd()")
end	

-- TRAUMA MISSION 6 - TRAUMA FROM LEVEL 6
	
function narratorLineTrauma6_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b3_01_lily",
	nil, 8000, 700, cinematicName .. ".narratorLineTrauma6_2()")
end

function narratorLineTrauma6_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b3_02_shadwen", 
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma6_3()")
end

function narratorLineTrauma6_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b3_03_lily", 
	nil, 5000, 700, cinematicName .. ".narratorLineTrauma6_4()")
end

function narratorLineTrauma6_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b3_04_lily", 
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma6_5()")
end

function narratorLineTrauma6_5()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b3_05_shadwen",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma6_6()")
end
	
function narratorLineTrauma6_6()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma6_7()")
end
function narratorLineTrauma6_7()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_01",
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma6_8()")
end
function narratorLineTrauma6_8()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_02",
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma6_9()")
end
function narratorLineTrauma6_9()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_03",
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma6_10()")
end

function narratorLineTrauma6_10()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_04",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma6_11()")
end

function narratorLineTrauma6_11()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_05",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma6_12()")
end
function narratorLineTrauma6_12()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_06",
	nil, 5000, 900, cinematicName .. ".narratorLineTrauma6_13()")
end
function narratorLineTrauma6_13()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_07",
	nil, 1000, 700, cinematicName .. ".theEnd()")
end	

-- TRAUMA MISSION 7 - TRAUMA FROM LEVEL 7

function narratorLineTrauma7_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b3_01_lily",
	nil, 8000, 700, cinematicName .. ".narratorLineTrauma7_2()")
end

function narratorLineTrauma7_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b3_02_shadwen", 
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma7_3()")
end

function narratorLineTrauma7_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b3_03_lily", 
	nil, 5000, 700, cinematicName .. ".narratorLineTrauma7_4()")
end

function narratorLineTrauma7_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b3_04_lily", 
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma7_5()")
end

function narratorLineTrauma7_5()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b3_05_shadwen",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma7_6()")
end	
	
function narratorLineTrauma7_6()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma7_7()")
end
function narratorLineTrauma7_7()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_01",
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma7_8()")
end
function narratorLineTrauma7_8()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_02",
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma7_9()")
end
function narratorLineTrauma7_9()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_03",
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma7_10()")
end
function narratorLineTrauma7_10()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_04",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma7_11()")
end
function narratorLineTrauma7_11()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_05",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma7_12()")
end
function narratorLineTrauma7_12()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_06",
	nil, 5000, 900, cinematicName .. ".narratorLineTrauma7_13()")
end
function narratorLineTrauma7_13()
	cinematic.CinematicUtil.playSpeech("Play_protecting_02_07",
	nil, 1000, 700, cinematicName .. ".theEnd()")
end	

	
-- TRAUMA MISSION 8 - TRAUMA FROM LEVEL 8

function narratorLineTrauma8_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b2_01_shadwen",
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma8_2()")
end

function narratorLineTrauma8_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b2_02_lily", 
	nil, 15000, 700, cinematicName .. ".narratorLineTrauma8_3()")
end

function narratorLineTrauma8_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b2_03_shadwen", 
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma8_4()")
end

function narratorLineTrauma8_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b2_04_lily", 
	nil, 6000, 700, cinematicName .. ".narratorLineTrauma8_5()")
end

function narratorLineTrauma8_5()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b2_05_shadwen",
	nil, 10000, 700, cinematicName .. ".theEnd()")
end
	

-- TRAUMA MISSION 9 - TRAUMA FROM LEVEL 9

function narratorLineTrauma9_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b3_01_lily",
	nil, 8000, 700, cinematicName .. ".narratorLineTrauma9_2()")
end

function narratorLineTrauma9_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b3_02_shadwen", 
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma9_3()")
end

function narratorLineTrauma9_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b3_03_lily", 
	nil, 5000, 700, cinematicName .. ".narratorLineTrauma9_4()")
end

function narratorLineTrauma9_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b3_04_lily", 
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma9_5()")
end

function narratorLineTrauma9_5()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b3_05_shadwen",
	nil, 2000, 700, cinematicName .. ".theEnd()")
end	


-- TRAUMA MISSION 10 - TRAUMA FROM LEVEL 10
	
function narratorLineTrauma10_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b1_01_lily",
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma10_2()")
end

function narratorLineTrauma10_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b1_02_shadwen", 
	nil, 12000, 700, cinematicName .. ".narratorLineTrauma10_3()")
end

function narratorLineTrauma10_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_b1_03_shadwen",
	nil, 14000, 700, cinematicName .. ".theEnd()")
end


-- TRAUMA MISSION 11 - TRAUMA FROM LEVEL 11
	
function narratorLineTrauma11_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a1_01_lily",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma11_2()")
end

function narratorLineTrauma11_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a1_02_shadwen", 
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma11_3()")
end

function narratorLineTrauma11_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a1_03_lily",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma11_4()")
end

function narratorLineTrauma11_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a1_04_shadwen",
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma11_5()")
end

function narratorLineTrauma11_5()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a1_05_lily",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma11_6()")
end

function narratorLineTrauma11_6()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a1_06_shadwen",
	nil, 6000, 700, cinematicName .. ".narratorLineTrauma11_7()")
end

function narratorLineTrauma11_7()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a1_07_lily",
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma11_8()")	
end	
	
function narratorLineTrauma11_8()
	cinematic.CinematicUtil.playSpeech("Play_protecting_01_01_shadwen",
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma11_9()")
end

function narratorLineTrauma11_9()
	cinematic.CinematicUtil.playSpeech("Play_protecting_01_02_lily",
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma11_10()")
end

function narratorLineTrauma11_10()
	cinematic.CinematicUtil.playSpeech("Play_protecting_01_03_shadwen",
	nil, 3000, 700, cinematicName .. ".narratorLineTrauma11_11()")
end

function narratorLineTrauma11_11()
	cinematic.CinematicUtil.playSpeech("Play_protecting_01_04_lily",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma11_12()")
end

function narratorLineTrauma11_12()
	cinematic.CinematicUtil.playSpeech("Play_protecting_01_05_lily",
	nil, 6000, 700, cinematicName .. ".narratorLineTrauma11_13()")
end

function narratorLineTrauma11_13()
	cinematic.CinematicUtil.playSpeech("Play_protecting_01_06_lily",
	nil, 4000, 700, cinematicName .. ".narratorLineTrauma11_14()")
end

function narratorLineTrauma11_14()
	cinematic.CinematicUtil.playSpeech("Play_protecting_01_07_shadwen",
	nil, 1000, 700, cinematicName .. ".theEnd()")
end	

-- TRAUMA MISSION 12 - TRAUMA FROM LEVEL 12
	
function narratorLineTrauma12_1()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a2_01_lily",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma12_2()")
end

function narratorLineTrauma12_2()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a2_02_shadwen", 
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma12_3()")
end

function narratorLineTrauma12_3()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a2_03_lily",
	nil, 2000, 700, cinematicName .. ".narratorLineTrauma12_4()")
end

function narratorLineTrauma12_4()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a2_04_shadwen",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma12_5()")
end

function narratorLineTrauma12_5()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a2_05_lily",
	nil, 1000, 700, cinematicName .. ".narratorLineTrauma12_6()")
end

function narratorLineTrauma12_6()
	cinematic.CinematicUtil.playSpeech("Play_shadwenstory_a2_06_shadwen",
	nil, 1000, 700, cinematicName .. ".theEnd()")
end


-- NO TRAUMA

function narratorLineNoTrauma1()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_12_01_lily",
	nil, 3000, 700, cinematicName .. ".narratorLineNoTrauma2()")
end

function narratorLineNoTrauma2()
	cinematic.CinematicUtil.playSpeech("Play_lilystory_12_02_shadwen", 
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