module("debug.ConsoleUtil", package.seeall)
debug.ReloadScripts.allowReload("debug.ConsoleUtil")

require "misc.AutoComplete"

--[[
	FUIDeveloperConsole uses this for some Lua-related functionality
]]

local thisModule = _M
declareManualReload(thisModule, [[maxMessageRows]])
declareManualReload(thisModule, [[messageLevel]])

maxMessageRows = 100 -- Maximum row count of a single message
messageLevel = 3 -- Show messages with level lower than this in console (prevents debug spam reaching developer console)

function startListeningToLogger()
	logger:addLoggerListener(addRowWithLevel)
end
function stopListeningToLogger()
	logger:removeLoggerListener(addRowWithLevel)
end

function addRowWithLevel(msg, level)
  if (level <= messageLevel) then
	addRow(msg)
  end
end

function safeExecute(line)
	if common.CommonUtils.isConsoleAllowed() then
		-- nop
	else
		return
	end
	
	local loadedFunction, errorMessage = loadstring(line)
	if not loadedFunction then
		logger:error("Error: " .. errorMessage)
		return
	end

	--local ok, output = xpcall(loadedFunction, editor.Trace.errorhandler)
	local ok, output = pcall(loadedFunction)
	if ok == false then
		logger:error("Error: " .. tostring(output))

		if FB_BUILD == "FB_FINAL_RELEASE" and developerConsole and developerConsole:getIsConsoleOpen() then
			developerConsole:postConsoleMessage("Error: " .. tostring(output));
		end

		return
	else
		--editor.Trace.clearLastTraceback()
		logger:info(tostring(output))

		if FB_BUILD == "FB_FINAL_RELEASE" and developerConsole and developerConsole:getIsConsoleOpen() then
			developerConsole:postConsoleMessage(tostring(output));
		end
	end
end


function autoComplete(line, fullLine)
	assert_string(line)
	assert_string(fullLine)
	
	if not developerConsole then
		logger:error("DeveloperConsole is not present while calling autoCompete")
		return
	end
	
	local matches, types, commonStart, identifier = misc.AutoComplete.getMatches(line)
	if commonStart:len() > identifier:len() then
		local startOfLine = line:sub(1, line:len() - identifier:len())
		local endOfLine = string.sub(fullLine, startOfLine:len() + identifier:len() + 1)
		
		local result = startOfLine .. commonStart .. endOfLine;
		local cursorPosition = startOfLine:len() + commonStart:len()
		
		developerConsole:receiveAutoCompleteResult(result, cursorPosition)
	else
		for i, name in pairs(matches) do
			addRow(name .. " (" .. types[name] .. ")")
		end
	end
end

function addRow(msg)
	local count = 0
	for row in msg:gmatch("[^\n]*") do
		if row ~= "" then
			count = count + 1
		end
	end
	for row in msg:gmatch("[^\n]*") do
		if count > maxMessageRows then
			count = count - 1
		else
			if row ~= "" then
				addRowImpl(row)
			end
		end
	end
end


function addRowImpl(msg)
    if (not(msg)) then 
        return 
    end
    
    -- Prevent really long lines jamming the rendering completely.
    local msgcut = ""
    if (msg:len() >= 256) then
        msgcut = msg:sub(1,256) .. "..."
    else
        msgcut = msg
    end
	
	if developerConsole then
		developerConsole:postConsoleMessage(msgcut)
	end
end


function getConsoleHistoryTable()
	local result = {}
	if not io then return nil end
	
	local ret = io.open("log/console.log", "r")
	if ret == nil then return nil end
	
	io.input(ret)
	for line in io.lines() do
		table.insert(result, line)
	end
	io.input():close()
	
	return result
end

function saveConsoleHistoryString(consoleHistoryString)
	assert_string(consoleHistoryString)
	
	local result = {}
	if not io then return end
	
	local ret = io.open("log/console.log", "w+")
	if ret == nil then return end
	
	io.output(ret)
	io.write(consoleHistoryString)
	io.output():close()
end
