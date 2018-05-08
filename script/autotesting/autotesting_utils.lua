module("autoTesting", package.seeall)
require "cheat"
require "misc.LocaleSettings"

function causeAssert(message, delay)
	autoTestingManager:addTestFrame(delay, "Causing assert after " .. delay .. " seconds" , function() autoTestingManager:causeAssert(message) end)
end

function causeError(message, delay)
	autoTestingManager:addTestFrame(delay, "Causing assert after " .. delay .. " seconds" , function() autoTestingManager:causeError(message) end)
end

function idle(delay)
	delay = delay or 0
	autoTestingManager:addTestFrame(delay, "Idling for " .. delay .. " seconds" , function() autoTestingManager:idleForSeconds(delay) end)
end

function nextCheckPoint(delay)
	delay = delay or 0
	autoTestingManager:addTestFrame(delay, "Warping to next checkpoint... USE_CUSTOM_LOGGING" , function() autoTestingManager:cycleCheckpoints(1) end)
end

function previousCheckPoint(delay)
	delay = delay or 0
	autoTestingManager:addTestFrame(delay, "Warping to previous checkpoint... USE_CUSTOM_LOGGING" , function() autoTestingManager:cycleCheckpoints(-1) end) 
end

function pressButton(buttonName, delay)
	delay = delay or 0
	autoTestingManager:addTestFrame(delay, "Pressing button " .. buttonName, function() autoTestingManager:pressButton(buttonName) end)
end

function releaseButton(buttonName, delay)
	delay = delay or 0
	autoTestingManager:addTestFrame(delay, "Releasing button " .. buttonName, function() autoTestingManager:releaseButton(buttonName) end)
end

function warpToPosition(position, delay)
	delay = delay or 0
	autoTestingManager:addTestFrame(delay, "Warping to position... USE_CUSTOM_LOGGING", function() autoTestingManager:movePlayerToPosition(position) end)
end

function loopingMovement(firstButtonName, secondButtonName, loopCounter, delay)
	delay = delay or 0
	for i=1,loopCounter,1 do
		pressButton(firstButtonName, delay)
		releaseButton(firstButtonName)
		pressButton(secondButtonName, delay)
		releaseButton(secondButtonName)
	end
end

function loopThroughCheckPoints(checkPoints, delay)
	delay = delay or 0
	for i=1,checkPoints,1 do
		nextCheckPoint(delay)
	end
end

function loopThroughCheckPointsBackwards(checkPoints, delay)
	delay = delay or 0
	for i=1,checkPoints,1 do
		previousCheckPoint(delay)
	end
end

function setImmortal(immortality, delay)
	delay = delay or 0
	if immortality == true then autoTestingManager:addTestFrame(delay, "Making player immortal... ", function() cheat.makePlayerActorsImmortal() end)
	else autoTestingManager:addTestFrame(delay, "Making player mortal... ", function() cheat.makePlayerActorsMortal() end)
	end
end

function makeAiBlindAndDeaf(AiBlindAndDeaf, delay)
	delay = delay or 0
	if AiBlindAndDeaf == true then autoTestingManager:addTestFrame(delay, "Making AI blind and deaf... ", function() cheat.makeAiBlindAndDeaf() end)
	end
end

function testRunToMissionExit(RunToExit, delay)
	delay = delay or 0
	if RunToExit == true then autoTestingManager:addTestFrame(delay, "Causing the guards to run to mission exit...", function() cheat.testRunToMissionExit() end)
	end
end

function moveTime(canMoveTime, delay)
	delay = delay or 0
	if canMoveTime == true then autoTestingManager:addTestFrame(delay, "Making the time move...", function() cheat.moveTime() end)
	end
end

function getUnstuck(delay)
	delay = delay or 0
	pressButton("left", delay)
	releaseButton("left")
	pressButton("up", delay)
	releaseButton("up")
	pressButton("right", delay)
	releaseButton("right")
	pressButton("down", delay)
	releaseButton("down")
end

function crashOnPurpose(delay)
	delay = delay or 0
	autoTestingManager:addTestFrame(delay, "Crashing test for debugging reasons... ", function() autoTestingManager:crashOnPurpose()  end)
end

function openMainMenuItem (menuName, pressDelay, releaseDelay, idleTime)
	pressDelay = pressDelay or 0
	releaseDelay = releaseDelay or 0
	idleTime = idleTime or 0
	if menuName == "Credits" then 
		for i=1,2,1 do 
			pressButton("gamepad_leftstick_up", pressDelay)
			releaseButton("gamepad_leftstick_up", releaseDelay)
		end
		pressButton("gamepad_a", pressDelay)
		releaseButton("gamepad_a", releaseDelay)
		idle(idleTime)
	elseif menuName == "Settings" then
		for i=1,3,1 do 
			pressButton("gamepad_leftstick_up", pressDelay)
			releaseButton("gamepad_leftstick_up", releaseDelay)
		end
		pressButton("gamepad_a", pressDelay)
		releaseButton("gamepad_a", releaseDelay)
		idle(idleTime)
	elseif menuName == "Achievements" then
		for i=1,4,1 do 
			pressButton("gamepad_leftstick_up", pressDelay)
			releaseButton("gamepad_leftstick_up", releaseDelay)
		end
		pressButton("gamepad_a", pressDelay)
		releaseButton("gamepad_a", releaseDelay)
		idle(idleTime)
	elseif menuName == "Multiplayer" then
		for i=1,5,1 do 
			pressButton("gamepad_leftstick_up", pressDelay)
			releaseButton("gamepad_leftstick_up", releaseDelay)
		end
		pressButton("gamepad_a", pressDelay)
		releaseButton("gamepad_a", releaseDelay)
		idle(idleTime)
	elseif menuName == "Singleplayer" then
		for i=1,6,1 do 
			pressButton("gamepad_leftstick_up", pressDelay)
			releaseButton("gamepad_leftstick_up", releaseDelay)
		end
		pressButton("gamepad_a", pressDelay)
		releaseButton("gamepad_a", releaseDelay)
		idle(idleTime)
	end
end

function backingInMenus (steps, pressDelay, releaseDelay, idleTime)
	steps = steps or 0
	pressDelay = pressDelay or 0
	releaseDelay = releaseDelay or 0
	idleTime = idleTime or 0
	for i=1,steps,1 do
			pressButton("gamepad_b", pressDelay)
			releaseButton("gamepad_b", releaseDelay)
	end
	idle(idleTime)
end

function defaultingMainMenu (pressDelay, releaseDelay, idleTime)
	pressDelay = pressDelay or 0
	releaseDelay = releaseDelay or 0
	idleTime = idleTime or 0
	backingInMenus(5, pressDelay, releaseDelay, 0)
	for i=1,2,1 do
		pressButton("gamepad_start", pressDelay)
		releaseButton("gamepad_start", releaseDelay)
		idle(1)
	end
	idle(idleTime)
end

function settingsMenuAll (pressDelay, releaseDelay, idleTime)
	pressDelay = pressDelay or 0
	releaseDelay = releaseDelay or 0
	idleTime = idleTime or 0
	--[[
	Loops through the menus starting from the bottom, 
	skips the configure controls menu due to opening 
	it requires a mouse and opens language menu instead at its place,
	that's why the loop counter is set at 7
	--]]
	for i=1,7,1 do 
		if i ~= 4 then 
			for j=1,i,1 do
				pressButton("gamepad_leftstick_up", pressDelay)
				releaseButton("gamepad_leftstick_up", releaseDelay)
			end
		elseif i == 4 then i = i+1
		end
		pressButton("gamepad_a", pressDelay)
		releaseButton("gamepad_a", releaseDelay)
		idle(idleTime)
		pressButton("gamepad_b", pressDelay)
		releaseButton("gamepad_b", releaseDelay)
	end
end

function loopLanguages(delay)
	logger:error("AutotestingUtils::loopLanguages - This doesn't work anymore, please re-factor me!");
	--[[
	autoTestingManager:addTestFrame(delay, "Changing language to German... ", function()
	localeModule:setGuiLanguage("de")
	localeModule:setSubtitleLanguage("de")
	localeModule:setAudioLanguage("de")
	end)
	autoTestingManager:addTestFrame(delay, "Changing language to French... ", function()
	localeModule:setGuiLanguage("fr")
	localeModule:setSubtitleLanguage("fr") 
	localeModule:setAudioLanguage("fr") 
	end)
	autoTestingManager:addTestFrame(delay, "Changing language to Spanish... ", function()
	localeModule:setGuiLanguage("es")
	localeModule:setSubtitleLanguage("es")
	localeModule:setAudioLanguage("es")
	end)
	autoTestingManager:addTestFrame(delay, "Changing language to Italian... ", function()
	localeModule:setGuiLanguage("it")
	localeModule:setSubtitleLanguage("it") end)
	autoTestingManager:addTestFrame(delay, "Changing language to Portuguese... ", function()
	localeModule:setGuiLanguage("br")
	localeModule:setSubtitleLanguage("br") 
	localeModule:setAudioLanguage("br")
	end)
	autoTestingManager:addTestFrame(delay, "Changing language to Russian... ", function()
	localeModule:setGuiLanguage("ru")
	localeModule:setSubtitleLanguage("ru")
	localeModule:setAudioLanguage("ru")
	end)
	autoTestingManager:addTestFrame(delay, "Changing language to Swedish... ", function()
	localeModule:setGuiLanguage("sv")
	localeModule:setSubtitleLanguage("sv") end)
	autoTestingManager:addTestFrame(delay, "Changing language to Norwegian... ", function()
	localeModule:setGuiLanguage("nn")
	localeModule:setSubtitleLanguage("nn") end)
	autoTestingManager:addTestFrame(delay, "Changing language to Danish... ", function()
	localeModule:setGuiLanguage("da")
	localeModule:setSubtitleLanguage("da") end)
	autoTestingManager:addTestFrame(delay, "Changing language to Japanese... ", function()
	localeModule:setGuiLanguage("ja")
	localeModule:setSubtitleLanguage("ja") 
	localeModule:setAudioLanguage("ja")
	end)
	autoTestingManager:addTestFrame(delay, "Changing language to Chinese... ", function()
	localeModule:setGuiLanguage("zh")
	localeModule:setSubtitleLanguage("zh") end)
	autoTestingManager:addTestFrame(delay, "Changing language to English... ", function()
	localeModule:setGuiLanguage("en")
	localeModule:setSubtitleLanguage("en") 
	localeModule:setAudioLanguage("en")
	end)
	]]--
end