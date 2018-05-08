module(..., package.seeall)
debug.ReloadScripts.allowReload(...)



function getMatches(line)
	local t = _G
	local path = ""

	local lastToken = line:match("([%w_.:]+)$") or ""

	local lastIdentifier = ""

	for identifier, separator in lastToken:gmatch("([%w_]+)([.:]?)") do
		if t == nil then
			break
		end
		if separator == '.' then
			t = t[identifier]
		elseif separator == ':' then
			t = t[identifier]
		else
			lastIdentifier = identifier
		end
	end
	
	local matches, types = findMatchingElementsInTable(lastIdentifier, t)
	local commonStart = findCommonInitialCharacters(matches)
	
	return matches, types, commonStart, lastIdentifier
end

function findMatchingElementsInTable(line, t)
	local matches = {}
	local types = {}
	if type(t) == "userdata" and getmetatable(t) then
		if type(getmetatable(t).__index) == "table" then
			t = getmetatable(t).__index
		else
			t = getmetatable(t).classTable
		end
	end
	if type(t) ~= "table" then
		return matches
	end
	while true do
		for name in pairs(t) do
	--		if type(t[name]) ~= "userdata" or getmetatable(t[name]).__luabind_class then
				if name ~= "UH_NONE" and name ~= "GUID_NONE" then
					if tostring(name):sub(1, line:len()):lower() == line:lower() then
						table.insert(matches, name)
						if type(t[name]) == "userdata" and getmetatable(t[name]) then
							types[name] = getScriptClassName(t[name])
						else
							if (type(t[name]) == "string") then
								local str = t[name]
								if (#str > 20) then
									str = str:sub(1, 20) .. "..."
								end
								types[name] = type(t[name]) .. ", \"" .. str .. "\""
							elseif (type(t[name]) == "number" or type(t[name]) == "boolean") then
								types[name] = type(t[name]) .. ", " .. tostring(t[name])
							else
								types[name] = type(t[name])
							end

						end
					end
				end
	--		end
		end
		
		-- get base class
		if(getmetatable(t) and getmetatable(t).__index) then
			t = getmetatable(t).__index
		else
			break
		end
	end
	table.sort(matches)
	return matches, types
end

function findCommonInitialCharacters(t)
	if #t == 0 then
		return ""
	end

	if #t == 1 then
		return t[1]
	end

	local common = tostring(t[1])
	for id, name in pairs(t) do
		for i = 1, common:len() do
			if common:byte(i) ~= name:byte(i) then
				common = common:sub(1, i - 1)
				break
			end
		end
	end

	return common
end
