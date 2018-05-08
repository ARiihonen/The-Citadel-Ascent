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
cinematicName = "cinematic.LoadingMainMenu";

-----------------------------------------------------
-- Content
-----------------------------------------------------

function getLoadingTextLocales()

	return 
	{
		"locales.nextParagraph", 
		"locales.nextParagraph",
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
	
	-- Start the speeches
	--narratorLine1();
	theEnd();
end
	
function narratorLine1()
	cinematic.CinematicUtil.playSpeech("Play_01_tutorial_101_narrator_heroes_were",
	nil, 2000, 700, cinematicName .. ".narratorLine2()")
end

function narratorLine2()
	cinematic.CinematicUtil.playSpeech("Play_01_tutorial_002_narrator_why_of_course", 
	nil, 8000, 700, cinematicName .. ".narratorLine3()")
end

function narratorLine3()
	cinematic.CinematicUtil.playSpeech("Play_01_tutorial_003_narrator_once_upon",
	nil, 10000, 700, cinematicName .. ".narratorLine4()")
end

function narratorLine4()
	cinematic.CinematicUtil.playSpeech("Play_01_tutorial_004_narrator_not_until",
	nil, 10000, 700, cinematicName .. ".theEnd()")
end

function theEnd()
	cinematic.CinematicUtil.loadingCinematicDone()
end