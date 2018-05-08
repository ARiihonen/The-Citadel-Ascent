module(..., package.seeall)

require "misc.LocaleSettings"

function loadLocale(locale, file, prefix)
	local input = assert(loadfile(file))
	if input then
		local temp = { }
		temp._G = _G
		setfenv(input, temp)
		pcall(input)
		for key, value in pairs(temp) do
			locale:setValue(prefix .. key, tostring(value))
		end
	end
end


function constructLocaleKey(locale)
	local metatable = { }
	metatable.key = ""
	metatable.__index = function(t, k)
		local temp = { }
		local meta = { }
		meta.__index = getmetatable(t).__index
		meta.__tostring = getmetatable(t).__tostring
		meta.key = getmetatable(t).key
		if meta.key == "" then
			meta.key = k
		else
			meta.key = meta.key .. "." .. k
		end
		setmetatable(temp, meta)
		return temp
	end
	metatable.__tostring = function(t)
		return locale:getValue(getmetatable(t).key)
	end
	local temp = { }
	setmetatable(temp, metatable)
	return temp
end


function usingLocaleKeys()

logger:error("This is some unused function?")

	gui = constructLocaleKey(guiLocale)
	subtitles = constructLocaleKey(subtitlesLocale)
end
