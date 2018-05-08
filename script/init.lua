package.path = "./data/script/?.lua;"

require "debug.ReloadScripts"
require "debug.AutoReloadable"
require "debug.Assert"
require "debug.ViewProfiling"

function delayedInitLoggingCheck()
  -- hack: delayed whine about this...
	if (loggerUsedBeforeInit) then
		loggerUsedBeforeInit = false
		logger:error("Logger was used in lua before initialization was completed. This is not acceptable and may cause the application to freeze.");
		if (type(loggerMessageBeforeInit) == "string") then		
			logger:info("At least one of the init logged messages was: "..loggerMessageBeforeInit);
		end
	end
end

function sceneExecute(string)
	delayedInitLoggingCheck()
	if not gameScene then
		logger:error("No gameScene found")
	end
	gameScene:runStringInLua(string)
end


function bind(func, obj)
	return function(...)
		func(obj, ...)
	end
end


function exit()
	state:requestQuit()
end


function quit()
	state:requestQuit()
end


function clear()
	developerConsole:clear()
end


function reloadScripts()
	delayedInitLoggingCheck()
	debug.ReloadScripts.reloadScripts()
end


function reloadScriptsImpl()
	local result = debug.ReloadScripts.reloadScriptsImpl()
end

function postConsoleMessage(message)
	if developerConsole and message then
		developerConsole:postConsoleMessage(tostring(message))
	end
end

function reloadSceneScriptsImplRunningInScene()
	postConsoleMessage("Scene script reload:")
	debug.ReloadScripts.reloadSceneScriptsImpl()
end


function reloadSceneScriptsImpl()
	sceneExecute("reloadSceneScriptsImplRunningInScene()")
end


function reloadSceneScripts()
	debug.ReloadScripts.reloadSceneScripts()
end


function reloadAllScripts()
	reloadScripts()
	reloadSceneScripts()
end

function reloadLocales()
	-- toggle the languages back&forth to get a reload done :)
	local subLocale = localeModule:getSubtitleLanguage()
	local audLocale = localeModule:getAudioLanguage()
	local guiLocale = localeModule:getGuiLanguage()

	if (guiLocale == "en") then
		localeModule:setGuiLanguage("de")
	else
		localeModule:setGuiLanguage("en")
	end
	localeModule:setGuiLanguage(guiLocale)
	
	if (subLocale == "en") then
		localeModule:setSubtitleLanguage("de")
	else
		localeModule:setSubtitleLanguage("en")
	end
	localeModule:setSubtitleLanguage(subLocale)
	
	if (audLocale == "en") then
		localeModule:setAudioLanguage("de")
		audioModule:setAudioLanguage("german/")
	else
		localeModule:setAudioLanguage("en")
		audioModule:setAudioLanguage("english_us_/")
	end
	localeModule:setAudioLanguage(audLocale)
	
	reloadSceneScripts()
end

-- alias for faster autocomplete.
_G.d_reloadscripts = reloadAllScripts

-- (note, copy&pasted this from somewhere, just to get a simple lua split function without having to fiddle with the regexps)
-- Compatibility: Lua-5.0
function split_compat(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim, 1, true) == nil then
        return { str }
    end

		-- frigging regexp...
		delim = string.gsub(delim, "[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
		
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

require "misc.Filterbase"

require "misc.Locale"
_G.loadLocale = misc.Locale.loadLocale


require "debug.ConsoleUtil"

require "debug.DebugStatsOverlayUtil"

require "debug.Visualize"

require "debug.Trace"

require "debug.DebugShortcuts"

require "cheat"

require "misc.util"

require "misc.database"
