module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

function setCommonStateIfNotSet(moduleName, stateName, baseState)
	local stateModule = debug.ReloadScripts.getLuaVarFromVarName(moduleName)
	if not stateModule then logger:error("Could not find stateModule") return end
	if not stateModule.stateCollection:isCommonStateSet() then 
		stateModule[stateName] = stateModule.stateCollection:setCommonState("Common", baseState)
	else
		stateModule[stateName] = stateModule.stateCollection:createStateLuaObject(stateName, baseState)
	end
end


-- Creates default reloadInit and reloadUninit functions and sets sourceFile variable to correct 
-- value. Also sets reloadAllowed to true, unless noReload is true.
function createReloadSupport(moduleName, noReload, onlyInEditor)
	local stateModule = debug.ReloadScripts.getLuaVarFromVarName(moduleName)
	if not stateModule then
		logger:error("Could not find stateModule")
		return
	end
	if noReload == true then stateModule["reloadAllowed"] = false else stateModule["reloadAllowed"] = true end
	stateModule["sourceFile"] = debug.ReloadScripts.getSourceFile(3)
	stateModule["useSourceFile"] = true
	stateModule["lastModifiedHours"] = luaState.getFileTimeStampHours(stateModule["sourceFile"])
	stateModule["lastModifiedSeconds"] = luaState.getFileTimeStampSeconds(stateModule["sourceFile"])
	if onlyInEditor then stateModule["reloadOnlyInEditor"] = true else stateModule["reloadOnlyInEditor"] = false end
	local function initFunc()
		_G[moduleName] = assert(loadstring("return " .. moduleName))()
	end
	local funcString = moduleName .. ".stateCollection:initOnReload(" .. moduleName .. ".stateCollection)"
	stateModule["reloadInit"] = assert(loadstring(funcString))
	funcString = "_G[\"" .. moduleName .. "\"] = nil"
	stateModule["reloadUninit"] = assert(loadstring(funcString))
end


-- Creates StateCollection and necessary tables to given module. Takes into account that this may 
-- be a script reload event: only creates new stateCollection and states if they don't already 
-- exist. Expects second parameter, stateInfoTable, to be a table that consists of state name (a 
-- string) and state that the new state inherits. If new state inherits no one, inherited state 
-- should be an empty string. If inherited state is a non-empty string, it is used as state name. 
-- Otherwise it is used as state as is.
function createStateCollection(moduleName, stateInfoTable)
	local stateModule = debug.ReloadScripts.getLuaVarFromVarName(moduleName)
	if not stateModule then
		logger:error("Could not find stateModule")
		return
	end
	stateModule.stateCollection = scriptedStateManager:findStateCollection(moduleName)
	if stateModule.stateCollection == nil then
		stateModule.stateCollection = scriptedStateManager:newStateCollection(moduleName)
	end
	for name, value in pairs(stateInfoTable) do
		local parent = value
		if type(value) == "string" then 
			if value == "" then 
				parent = nil 
			else
				parent = debug.ReloadScripts.getLuaVarFromVarName(value)
			end
		end
		if stateModule.stateCollection:findStateIndexByName(name) == -1 then
			stateModule[name] = stateModule.stateCollection:newState(name, parent)
		else
			stateModule[name] = stateModule.stateCollection:createStateLuaObject(name, parent)
		end
	end
end
