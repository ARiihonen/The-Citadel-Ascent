module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

-- UNUSED --
function enterFunctionTrace()
	if (lastTraceback == nil) then
		lastTraceback = { }
	end
	local tmp = getTracebackStringForUI()
	if (tmp) then
		table.insert(lastTraceback, tmp)
	end
end


-- UNUSED --
function leaveFunctionTrace()
	--table.remove(lastTraceback, #lastTraceback)
end


-- UNUSED --
function startLuaTrace()
	--debug.sethook(enterFunctionTrace, "l")
	_G.debug.sethook(debug.Trace.enterFunctionTrace, "c")
	-- this would remove the enter hook, need to combine in one "cr" hook maybe?
	--debug.sethook(debug.Trace.leaveFunctionTrace, "r")
end


-- UNUSED --
function stopLuaTrace()
	_G.debug.sethook()
end


-- UNUSED --
function sendLastTracebackToUI()
	if (not(lastTraceback == nil)) then
		if (#lastTraceback > 2) then
			sendTracebackToUI(lastTraceback[#lastTraceback - 2])
			--local tmp = table.concat(lastTraceback)
			--sendTracebackToUI(tmp)
			lastTraceback = { }		 
		end
	end
end


-- UNUSED --
function clearLastTraceback()
	lastTraceback = { }
end

--uiSendCallback = nil;


function setUISendCallbackFunction(func)
	--uiSendCallback = func;
end


function sendTracebackToUI(str)
	--if (uiSendCallback) then
	--	uiSendCallback(str)
	--end
	-- hax: need to do it like this to avoid problems with multiple states..
	if(externalUI)
	then
	  externalUI:sendUICommand("sync(\"LuaCallStackExplorer\", \""..str.."\")");
	end
end


function getTracebackStringForUI()
	local restore_hook = debug.gethook()
	-- do
	--	 return debug.traceback()
	-- end

	local ret = ""
	if (tracebacknumber == nil) then
		tracebacknumber = 0
	end
	tracebacknumber = tracebacknumber + 1 
	--ret = "[GUID(0x0,0x0,0x0,0x0),traceback,"..tracebacknumber..")]Lua call stack\r\n"	
	ret = "[GUID(0x0,0x0,0x0,0x0),traceback)]Lua call stack\r\n"	
	ret = ret .. "{\r\n"
	local level = 1
	while true do
		--local info = debug.getinfo(level, "Sl")
		local info = debug.getinfo(level)
		if not info then break end
		local myguidid = "[GUID(0x0,0x0,0x0,0x0),traceframe,".. level ..")]"
		if info.what == "C" then
			if (info.name ~= nil) then
				ret = ret .. myguidid .."[C] in function "..string.format("'%s'",info.name) .. "\r\n"
			else
				ret = ret .. myguidid .."[C] in function (unknown)".. "\r\n"
			end
		else
			local line = ""
			if (info.name ~= nil) then
				line = myguidid .. string.format("%s:%d - in function '%s'", info.short_src, info.currentline, info.name) .. "\r\n"
			else
				line = myguidid .. string.format("%s:%d in function (anonymous)", info.short_src, info.currentline) .. "\r\n"
			end
			if not(string.find(line, "data/script/debug/trace.lua")) then
				ret = ret .. line
			end
		end
		level = level + 1
	end
	ret = ret .. "}\r\n"
	
	if (restore_hook) then
		debug.sethook(restore_hook, "c")
	end
	
	return ret
end


-- UNUSED --
-- this function returns the given lua script line embedded inside trace calls
function addTraceToLuaLine(line)	
	local traceEnter = "local trace_function = function()\r\n";
	--local traceLeave = "\r\nend;\r\ndebug.Trace.startLuaTrace();\r\nlocal trace_ret = trace_function();\r\ndebug.Trace.stopLuaTrace();\r\ndebug.Trace.sendLastTracebackToUI();\r\nreturn trace_ret;\r\n";
	local traceLeave = "\r\nend;\r\ndebug.Trace.startLuaTrace();\r\nlocal trace_ret = trace_function();\r\ndebug.Trace.stopLuaTrace();\r\nreturn trace_ret;\r\n";
	return traceEnter .. line .. traceLeave
end

function getFirstScriptLocation()
	local restore_hook = debug.gethook()

	local ret = ""
	local level = 1
	while true do
		local info = debug.getinfo(level)
		if not info then break end
		if not(string.find(info.short_src, "data/") == nil) then -- error has valid script location
			local line;
			if (info.name ~= nil) then
				line = string.format("%s:%d - in function '%s'", info.short_src, info.currentline, info.name) .. "\r\n"
			else
				line = string.format("%s:%d in function (anonymous)", info.short_src, info.currentline) .. "\r\n"
			end
			if not(string.find(line, "data/script/debug/trace.lua")) then
				ret = line;
				break
			end
		end
		level = level + 1
	end
	
	if (restore_hook) then
		debug.sethook(restore_hook, "c")
	end
	
	return ret
end

function errorhandler(errmsg)
	local ret = getTracebackStringForUI()
	sendTracebackToUI(ret)
	
	if (string.find(errmsg, "data/") == nil) -- error doesn't yet have valid script location
  then
		return getFirstScriptLocation() .. " - " .. tostring(errmsg)
	else
		return errmsg
	end
end
