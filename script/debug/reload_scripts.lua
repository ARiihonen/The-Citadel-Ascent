module(..., package.seeall)

-- (Once again) Refactored reloadScripts (3.0 ish)
--
-- There are several LUA states running inside editor and game. To reload scripts in game scene 
-- (that includes state scripts) use reloadSceneScripts() or sceneExecute("reloadScripts()"). 
-- Plain reloadScripts() only reloads scripts in state LUA, which doesn't help much in gameplay 
-- hacking. To reload everything, use ReloadAllScripts(). Note that AFAIK none of the calls reloads 
-- editor state LUA scripts if called in game mode console.
--
-- Modules are ignored by default. Variable reloadAllowed must be true to reload. Note that it is 
-- preferrable to use debug.ReloadScripts.allowReload(...) or debug.ReloadScripts.allowReload(moduleName) 
-- instead (see for example data/script/input/binds.lua). Optional boolean parameter can be passed 
-- to indicate whether module should only be reloadable in editor mode (e.g. allowReload(..., true), 
-- true meaning that reload is only allowed in editor.
--
-- Calls function reloadUninit, if package has one, before unloading
-- Calls function reloadInit, if package has one, after loading
-- 
-- The above don't necessary have to be the same init and uninit functions that are called on 
-- actual init and uninit, mind you. Also, it is perfectly ok to have init without uninit or 
-- otherway around.
--
-- There is a separate function to be used with stateScripts: createReloadSupport(moduleName). It 
-- does everything allowReload() does and some stateScript specific stuff. Also creates reloadInit 
-- and reloadUninit functions, so if you need to create your own, your out of luck (= go hack 
-- createReloadSupport to accept arbitary functions that are called during unload and reload or 
-- something like that).
--
-- If package source file's path differs from what one might think based on package name, as is the 
-- case with most (all?) state scripts, sourceFile variable in package must be defined. This can be 
-- done with getSourceFile() function, but is done automatically by allowReload() and 
-- createReloadSupport().
--
-- As new version of reloadScripts is a lot more aggressive than previous ones, many modules can't 
-- handle reload anymore. I think I have finally found and nilled all places where modules are 
-- saved, thus breaking just about everything that saves or caches some state inside LUA (that's 
-- also why stateScripts need special reload handling).
--
-- ReloadScripts overwrites LUA's require function. 
-- 
-- If reloadScripts finds console, it will output there, in addition to log message, how many 
-- modules were found and how many of those were reloaded. However, scene LUA doesn't have console, 
-- so one has to read logs to check how that went (this is to be fixed among other things).
-- 
-- ReloadScripts uses global reloadSafe table to save data between reloads. If module needs to save 
-- some data of its own, it can create table to reloadSafe.moduleSafe and store its stuff there.
-- 


-- Returns path of callers source file, if one exists. By specifying level > 2 returns the path of 
-- caller's caller etc.
function getSourceFile(level)
	if not level then
		return (debug.getinfo(2, "S").source):sub(2)
	else
		return (debug.getinfo(level, "S").source):sub(2)
	end
end


-- Whether or not this is worth trying is debatable. Once it is broken, it can only be reloaded manually
sourceFile = getSourceFile()
useSourceFile = false
lastModifiedHours = luaState.getFileTimeStampHours(sourceFile)
lastModifiedSeconds = luaState.getFileTimeStampSeconds(sourceFile)
-- easy fix for unecessary warnings and stuff.
--reloadAllowed = true
reloadAllowed = false

-- Use this to turn reloading completely off. Note that in that case require() won't be replaced with safe version.
-- no such FB_BUILD exist, etc.
--if (FB_BUILD == "FB_FINAL_RELEASE" then
--	reloadInUse = false
--else
	reloadInUse = true
--end

-- a hacky variable that is set to true while reloading scene scripts :P
-- (state script reloading, UI specifically, will be skipped when this true)
reloadingSceneScripts = false;

function isModule(value)
	if value == _G then return false end
	if type(value) == "table" and value._M ~= nil then return true else return false end
end


function getPackageLoadedContent()
	local content = {}
	for name, value in pairs(package.loaded) do
		if isModule(value) then content[name] = { loaded = true } end
	end
	return content
end


if not _G["reloadSafe"] then
	_G["reloadSafe"] =  { }
	local reloadSafe = _G["reloadSafe"]
	reloadSafe.originalRequire = require
	reloadSafe.packageLoadedCache = getPackageLoadedContent()
	reloadSafe.packageLoadedCache[...] = { loaded = true }
	reloadSafe.requireOrder = { }
	table.insert(reloadSafe.requireOrder, ...)
	reloadSafe.requiredPackages = { }
	reloadSafe.moduleSafe = { }
end


function updateRequireOrder()
	local reloadSafe = _G["reloadSafe"]
	local foundOne = false
	for name, value in pairs(package.loaded) do
		if isModule(value) then
			if reloadSafe.packageLoadedCache[name] == nil then
				reloadSafe.packageLoadedCache[name] = { loaded = true }
				table.insert(reloadSafe.requireOrder, name)
				if foundOne then rsLog("warning", "Inserting more than one module during updateRequireOrder call") end
				foundOne = true
			end
		end
	end
end


function fbRequire(moduleName)
	local reloadSafe = _G["reloadSafe"]
	local newRequirement = not reloadSafe.requiredPackages[moduleName]
	if newRequirement then
		-- UpdateRequireOrder must be called first. One require may lead to another and we want to 
		-- make one update at a time, thus making sure the order is preserved. Another call is made 
		-- later to take care of those requires that don't spawn more requires. However, if this 
		-- requirement has been seen before, updateRequireOrder won't have any effect, so we can 
		-- just skip it.
		updateRequireOrder()
		reloadSafe.requiredPackages[moduleName] = true
	end
	local success = false
	local result = ""
	success, result = pcall(reloadSafe.originalRequire, moduleName)
	-- UpdateRequireOrder may need to be called regardless of success of require. Depends really on 
	-- what exactly require does during errors, but I would think that module command at the 
	-- beginning of a file would be run normally and wholly before any errors.
	if newRequirement then updateRequireOrder() end
	if success then
		-- If module is defined with module(...), it, apparently, must not be required by filename. 
		-- So if we see sourceFile variable with no corresponding variable in package.loaded, we 
		-- make sure useSourceFile is false.
		local freshModule = getLuaVarFromVarName(moduleName)
		if freshModule and freshModule.reloadAllowed then
			if freshModule.useSourceFile == nil then
				if logger then logger:error("Module \"" .. moduleName .. "\" has allowReload set but lacks useSourceFile variable") end
			elseif not freshModule.sourceFile then
				if logger then logger:error("Module \"" .. moduleName .. "\" has allowReload set but lacks sourceFile variable") end
			elseif not _G["package"]["loaded"][freshModule.sourceFile] then
				freshModule.useSourceFile = false
			end
		end
		return result
	else
		if logger then logger:error("Error requiring package \"" .. moduleName .. "\": " .. result) end
	end
end


if reloadInUse then
	_G["require"] = fbRequire
end


function rsLog(messageType, logMessage)
	table.insert(_G["reloadSafe"]["logMessages"], { type = messageType, message = logMessage })
end


function writeToLogAndClear(compactOutput)
	for index, logMessage in ipairs(_G["reloadSafe"]["logMessages"]) do
		local type = logMessage.type
		local message = logMessage.message
		if type == "error" then logger:error(message)
		elseif type == "warning" then logger:warning(message)
		elseif type == "info" then if (not(compactOutput)) then logger:info(message) end
		elseif type == "finalinfo" then logger:info(message)
		elseif type == "debug" then logger:debug(message)
		else logger:error("Invalid message type: " .. type) end
	end
	_G["reloadSafe"]["logMessages"] = { }
end


function printDebugInfo()
	local reloadSafe = _G["reloadSafe"]
	logger:debug("reloadScripts status:")
	logger:debug("packageLoadedCache: ")
	for name, value in pairs(reloadSafe.packageLoadedCache) do
		logger:debug("PLC: " .. name)
	end
	logger:debug("requireOrder: ")
	for index, name in ipairs(reloadSafe.requireOrder) do
		logger:debug("RO: " .. name)
	end
end


function reloadScripts()
	-- delay to next update for editor script safeness.
	app:requestReloadScripts()
end

function reloadSceneScripts()
	app:requestReloadSceneScripts()
end

function reloadSceneScriptsImpl()
	reloadingSceneScripts = true
	reloadScriptsImpl()
	reloadingSceneScripts = false
end

function reloadScriptsImpl()
	if not reloadInUse then
		logger:error("ReloadScripts is not in use")
		return
	end
	-- could assume false as well, but true is safer.
	local editorState = true
	if (state) then
		editorState = state:isEditorState()
	else
		if (logger) then
			logger:warning("No global state variable, cannot solve if this is an editor state or game state.")
		end
	end	
	_G["reloadSafe"]["logMessages"] = { }
	_G["reloadSafe"]["reloadables"] = _G["reloadables"]
	
	local compactOutput = false
	local modifiedReloaded = 0
	if (_G.externalUIModule) then
		if (_G.externalUIModule.getCompactReloadScriptInfo) then
			compactOutput = _G.externalUIModule:getCompactReloadScriptInfo()
		end
	end	
	
--	rsLog("debug", "Reload beginning...")
	local packageList = { }
	local totalPackageCount = 0
	local reloadablePackageCount = 0
	local reloadSafe = _G["reloadSafe"]
	-- Collect all reloadable modules (or their names and source file paths) to a table
	for index, name in ipairs(reloadSafe.requireOrder) do
		local infoTable = { }
		infoTable.name = name
		local mod = package.loaded[name]
		if not mod then 
			rsLog("info", "Could not find module \"" .. name .. "\". Presuming this is because failed reload. Attempting blind reload")
			if reloadSafe.packageLoadedCache[name] then
				-- If sourceFile is saved to packageLoadedCache and useSourceFile is set, it will be used
				infoTable.sourceFile = reloadSafe.packageLoadedCache[name]["sourceFile"]
				infoTable.useSourceFile =  reloadSafe.packageLoadedCache[name]["useSourceFile"] and true or false
			else
				rsLog("error", "Package " .. name .. " not found from packageLoadedCache")
			end
			totalPackageCount = totalPackageCount + 1
			infoTable.noUnload = true
			table.insert(packageList, infoTable)
			reloadablePackageCount = reloadablePackageCount + 1
		elseif type(mod) == "table" and mod._M ~= nil then
			totalPackageCount = totalPackageCount + 1
			if mod.reloadAllowed == true then
				-- TODO: a proper state only flag for the package...
				if reloadingSceneScripts and name:sub(1, 4) == "gui." then
					rsLog("info", "Module \"" .. name .. "\" skipped in scene reload (it is inteded for state access only)")
				elseif not editorState and mod.reloadOnlyInEditor then
					rsLog("info", "Module \"" .. name .. "\" skipped (reload allowed only in editor mode)")
					if (compactOutput) then
						local fileTimeStampHours = luaState.getFileTimeStampHours(mod.sourceFile)
						local fileTimeStampSeconds = luaState.getFileTimeStampSeconds(mod.sourceFile)
						if fileTimeStamp == -1 then
							rsLog("warning", "Could not read last modified time for module \"" .. name .. "\"")
						elseif ((mod.lastModifiedHours or -1) ~= fileTimeStampHours) or ((mod.lastModifiedSeconds or -1) ~= fileTimeStampSeconds) then
							rsLog("warning", "Module \"" .. name .. "\" has been modified but is not allowed to be reloaded (allowed in editor mode only).")
						end					
					end
				else
					if not (mod.useSourceFile ~= nil and mod.sourceFile) then
						rsLog("warning", "Cannot find source file name or source file usage policy for module \"" .. name .. "\". Reload may fail.")
					end
					if (not mod.lastModifiedHours) or (not mod.lastModifiedSeconds) then
						rsLog("warning", "Cannot find last modified time of module \"" .. name .. "\".")
					end
					infoTable.sourceFile =  mod.sourceFile
					infoTable.useSourceFile =  mod.useSourceFile and true or false
					-- If reload would fail, sourceFile must be saved somewhere (see above)
					reloadSafe.packageLoadedCache[name]["sourceFile"] = mod.sourceFile
					reloadSafe.packageLoadedCache[name]["useSourceFile"] = mod.useSourceFile and true or false
					infoTable.lastModifiedHours = mod.lastModifiedHours or -1
					infoTable.lastModifiedSeconds = mod.lastModifiedSeconds or -1
					table.insert(packageList, infoTable)
					reloadablePackageCount = reloadablePackageCount + 1
				end
			elseif mod.reloadAllowed == false or mod.reloadAllowed == nil then
				rsLog("info", "Module \"" .. name .. "\" skipped (reloadAllowed not true)")
				-- TODO: fix: cannot figure out module filename, since allowReload was never used with the module.
				-- thus, cannot currently properly warn about such files being modified but not reloaded
				--if (compactOutput) then
				--	local fileTimeStampHours = luaState.getFileTimeStampHours(mod.sourceFile)
				--	local fileTimeStampSeconds = luaState.getFileTimeStampSeconds(mod.sourceFile)
				--	if fileTimeStampHours == -1 then
				--		rsLog("warning", "Could not read last modified time for module \"" .. name .. "\"")
				--	elseif ((mod.lastModifiedHours or -1) ~= fileTimeStampHours) or ((mod.lastModifiedSeconds or -1) ~= fileTimeStampSeconds) then
				--		rsLog("warning", "Module \"" .. name .. "\" has been modified but is not allowed to be reloaded.")
				--	end
				--end
			else
				rsLog("warning", "Module \"" .. name .. "\" ignored as reloadAllowed is set to something else than true or false")
			end
		else
			rsLog("error", "Name in requireOrder refers to something else than module: " .. name)
		end
	end
	-- Remove all packages
	local index = reloadablePackageCount
	while index > 0 do
		local modInfo = packageList[index]
		if not modInfo.noUnload then unloadPackage(modInfo, true) end
		index = index - 1
	end
	
	_G["reloadables"] = _G["reloadSafe"]["reloadables"]

	-- Reload all packages
	local reloaded = 0
	local failedPackages = { }
	for index, info in ipairs(packageList) do
		local reloadRet = reloadPackage(info)
		if reloadRet == 1 then
			reloaded = reloaded + 1
		elseif reloadRet == 2 then
			reloaded = reloaded + 1
			modifiedReloaded = modifiedReloaded + 1
		elseif info.loadError then
			rsLog("error", info.loadError)
		else
			rsLog("error", "Internal error, no load error info available.")
		end
	end

	local retstr 
	if (not(compactOutput)) then
		retstr = "Reloaded " .. reloaded .. "/" .. totalPackageCount .. " modules."
	else
		if (modifiedReloaded > 0) then
			retstr = "Reloaded " .. modifiedReloaded .. " modified scripts (out of total "..totalPackageCount..")."
		else
			retstr = "No modified scripts were reloaded."
		end
	end
	rsLog("finalinfo", retstr)
	writeToLogAndClear(compactOutput)
	return retstr
end


-- Go through packages. Call reloadUninit, if available. Remove from loaded list
function unloadPackage(info, callUninit)
	local name = info.name
	local pack = package.loaded[name]
	if not pack then
		rsLog("error", "Could not find to unload module " .. name)
		return
	end
	if callUninit and pack.reloadUninit then
		if type(pack.reloadUninit) == "function" then
			local success = false
			local result = ""
			success, result = pcall(pack.reloadUninit, nil)
			if not success then rsLog("error", "Module " .. name .. " failed in reloadUninit() : " .. result) end
		else
			rsLog("warning", "Module \"" .. name .. "\" has member called \"reloadUninit\" that is not a function")
		end
	end
	if callUninit then
		local success = false
		local result = ""
		success, result = pcall(_G.debug.AutoReloadable.preserveObjectsBeforeReloadUninit, pack)
		if not success then rsLog("error", "Module " .. name .. " autoreload preserve failed: " .. result) end
	end
	if isInGlobal(name) then removeFromGlobal(name) else rsLog("error", "Module " .. name .. " not found from global scope") end
	if pack.sourceFile then
		package.loaded[pack.sourceFile] = nil
	end
	package.loaded[name] = nil
--	rsLog("info", "Module \"" .. name .. "\" unloaded")
end


-- Reload package. If function named reloadInit is found, it is called
-- returns 0 on error, 1 on successful un-modified file reload, 2 on successful modified file reload
function reloadPackage(info)
	local success = false
	local errorMsg = ""
	if info.useSourceFile == nil then
		info.loadError = "Module \"" .. info.name .. "\" has no useSourceFile variable set"
		return 0
	end
	if not info.sourceFile then
		info.loadError = "Module \"" .. info.name .. "\" has no source file name available"
		return 0
	end
	local modified = false
	if info.lastModifiedHours and info.lastModifiedSeconds then
		local fileTimeStampHours = luaState.getFileTimeStampHours(info.sourceFile)
		local fileTimeStampSeconds = luaState.getFileTimeStampSeconds(info.sourceFile)
		if fileTimeStampHours == -1 or fileTimeStampSeconds == -1 then
			rsLog("warning", "Could not read last modified time for module \"" .. info.name .. "\"")
		elseif (info.lastModifiedHours ~= fileTimeStampHours) or (info.lastModifiedSeconds ~= fileTimeStampSeconds) then
			rsLog("info", "Module \"" .. info.name .. "\" has been modified")
			modified = true
		end
	else
		rsLog("warning", "Module \"" .. info.name .. "\" has no last modified time available")
	end
	if info.useSourceFile then 
--		rsLog("debug", "Found sourceFile for " .. info.name)
		success, errorMsg = pcall(require, info.sourceFile)
	else
		success, errorMsg = pcall(require, info.name)
	end
	if not success then
		info.loadError = errorMsg
		return 0
	elseif not package.loaded[info.name] then
		info.loadError = "package.loaded[" .. info.name .."] is untrue. Load failed"
		return 0
	else
		local mod = package.loaded[info.name]
		mod.useSourceFile = info.useSourceFile
		mod.sourceFile = info.sourceFile
		local result = ""
		success, result = pcall(_G.debug.AutoReloadable.restoreObjectsBeforeReloadInit, package.loaded[info.name])
		if not success then rsLog("error", "Module " .. info.name .. " autoreload restore failed: " .. result) end
		if mod.reloadInit then
			if type(mod.reloadInit) == "function" then
--				rsLog("debug", "Found reloadInit for " .. info.name)
				success, errorMsg = pcall(package.loaded[info.name].reloadInit, nil)
				if not success then
					rsLog("error", "Module \"" .. info.name .. "\" failed in reloadInit() : " .. errorMsg)
				end
			else
				rsLog("warning", "Module \"" .. info.name .. "\" has member called \"reloadInit\" that is not a function")
			end
		end
--		rsLog("info", "Module \"" .. info.name .. "\" reloaded")
		if modified then
			return 2
		else
			return 1
		end
	end
end


function removeFromGlobal(name)
	if not isInGlobal(name) then
		rsLog("error", "Could not find and remove module " .. name)
		return false
	end
	local script = name .. " = nil"
	assert(loadstring(script))()
	-- At least states have shortcuts like _G["gameplay.ThiefMoveState"] defined. They actually 
	-- take care of those by themselves now, but this is left here in case the pattern is used 
	-- elsewhere.
	_G[name] = nil
	return true
end


function isInGlobal(name)
	-- Finds both _G["foo"]["bar"] type variables and _G["foo.bar"] type variables
	local script = "if " .. name .. " ~= nil then return true else return false end"
	if assert(loadstring(script))() == true then 
		return true 
	elseif _G[name] ~= nil then
		return true
	else
		return false 
	end
end


-- Sets up specified module so that it can be reloaded. This function must be called in the same 
-- context (file) as the corresponding module command.
function allowReload(moduleName, onlyInEditor)
	local mod = getLuaVarFromVarName(moduleName)
	if not mod then
		logger:error("Could not setup module " .. moduleName .. " for reloading")
		return
	end
	mod["sourceFile"] = getSourceFile(3)
	mod["useSourceFile"] = true
	mod["lastModifiedHours"] = luaState.getFileTimeStampHours(mod["sourceFile"])
	mod["lastModifiedSeconds"] = luaState.getFileTimeStampSeconds(mod["sourceFile"])
	mod["reloadAllowed"] = true
	if onlyInEditor then mod["reloadOnlyInEditor"] = true else mod["reloadOnlyInEditor"] = false end
end


function getLuaVarFromVarName(varName)
	-- We use loadstring since variable names may, and often do, have dots in them
	
	-- Fix for decoda error spam: proper variables should not have slashes in them so just return nil
	if string.find(varName, "/") then
		return nil
	end
	
	local success, result = pcall(loadstring("return " .. varName), nil)
	if success then
		return result
	else
		return nil
	end
end

