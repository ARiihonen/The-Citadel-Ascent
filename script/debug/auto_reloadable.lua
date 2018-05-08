module(..., package.seeall)

require "debug.ReloadScripts"


-- NOTE: always use the global aliases at the end of this file instead of using these with the module name!


function nop() end

function nilPlaceholder() 
	logger:error("nilPlaceholder called.")
	-- this should never get called/used, but it is needed as a flag for nil objects
	-- (otherwise nil / non-nil changes in tables shuffle the table and break up any iteration in progress)
end

function initReloadables()
	if _G.reloadables == nil then
		_G.reloadables = {}
	end	
end

function reloadableObject(module, objectName)
	assert_luamodule(module)
	assert_string(objectName)

	local str = module._NAME
	
	initReloadables()
	if (_G.reloadables["reloadable_name_" .. str .. "__OBJ__" .. objectName] == nil) then	
		_G.reloadables["reloadable_name_" .. str .. "__OBJ__" .. objectName] = objectName;
		_G.reloadables["reloadable_packagename_" .. str .. "__OBJ__" .. objectName] = module._PACKAGE;
		_G.reloadables["reloadable_modulename_" .. str .. "__OBJ__" .. objectName] = string.sub(module._NAME, #module._PACKAGE + 1);
		_G.reloadables["reloadable_custom_" .. str .. "__OBJ__" .. objectName] = false;
		_G.reloadables["reloadable_manually_" .. str .. "__OBJ__" .. objectName] = false;
		_G.reloadables["preserved_value_" .. str .. "__OBJ__" .. objectName] = nilPlaceholder;
		_G.reloadables["has_preserved_value_" .. str .. "__OBJ__" .. objectName] = false;
	end
	
	return nil
end

-- Note, params must be a table of strings or numbers, you cannot generally store any userdata objects there!
-- (as those objects might get lost at reload)
function reloadableCustomObject(module, objectName, creatorFunctionName, deleterFunctionName, params)
	assert_luamodule(module)
	assert_string(objectName)
	assert_string(creatorFunctionName)
	assert_string(deleterFunctionName)
	assert_table(params)

	local str = module._NAME

	initReloadables()
	if (_G.reloadables["reloadable_name_" .. str .. "__OBJ__" .. objectName] == nil) then	
		_G.reloadables["reloadable_name_" .. str .. "__OBJ__" .. objectName] = objectName;
		_G.reloadables["reloadable_packagename_" .. str .. "__OBJ__" .. objectName] = module._PACKAGE;
		_G.reloadables["reloadable_modulename_" .. str .. "__OBJ__" .. objectName] = string.sub(module._NAME, #module._PACKAGE + 1);
		_G.reloadables["reloadable_custom_" .. str .. "__OBJ__" .. objectName] = true;
		_G.reloadables["reloadable_manually_" .. str .. "__OBJ__" .. objectName] = false;
		_G.reloadables["reloadable_creator_" .. str .. "__OBJ__" .. objectName] = creatorFunctionName;
		_G.reloadables["reloadable_deleter_" .. str .. "__OBJ__" .. objectName] = deleterFunctionName;
		_G.reloadables["reloadable_params_" .. str .. "__OBJ__" .. objectName] = params;	
		_G.reloadables["preserved_value_" .. str .. "__OBJ__" .. objectName] = nilPlaceholder;
		_G.reloadables["has_preserved_value_" .. str .. "__OBJ__" .. objectName] = false;
	end
end

-- Note, params must be a table of strings or numbers, you cannot generally store any userdata objects there!
-- (as those objects might get lost at reload)
function createReloadableCustomObject(module, objectName, creatorFunctionName, deleterFunctionName, params)
	assert_luamodule(module)
	assert_string(objectName)
	assert_string(creatorFunctionName)
	assert_string(deleterFunctionName)
	assert_table(params)
	
	local creator = module[creatorFunctionName]
	assert_function(creator)
	
	-- note, the module is supposed to create the object byitsef, rather than return the created object
	local success, noReturnPlease = pcall(creator, objectName, params)
	if (not(success)) then
		logger:warning("Creation of \""..objectName.."\", creator function \""..creatorFunctionName.."\" in module \""..module._NAME.."\" failed: " .. noReturnPlease)
	else
		if (noReturnPlease) then
			logger:warning("Creation of \""..objectName.."\", creator function \""..creatorFunctionName.."\" in module \""..module._NAME.."\" returned a value. The creator function is expected to set the module variable directly, and return nil.")
		end
	end	
	if module[objectName] == nil then
		logger:warning("Failed to restore \""..objectName.."\", creator function \""..creatorFunctionName.."\" in module \""..module._NAME.."\" set the variable to nil. (Note, this may be correct behaviour if nil creation is acceptable.)")
	end
	
	reloadableCustomObject(module, objectName, creatorFunctionName, deleterFunctionName, params)
	
	return module[objectName]
end

function manuallyReloadedObject(module, objectName)
	assert_luamodule(module)
	assert_string(objectName)

	local str = module._NAME
	
	initReloadables()
	if (_G.reloadables["reloadable_name_" .. str .. "__OBJ__" .. objectName] == nil) then	
		_G.reloadables["reloadable_name_" .. str .. "__OBJ__" .. objectName] = objectName;
		_G.reloadables["reloadable_packagename_" .. str .. "__OBJ__" .. objectName] = module._PACKAGE;
		_G.reloadables["reloadable_modulename_" .. str .. "__OBJ__" .. objectName] = string.sub(module._NAME, #module._PACKAGE + 1);
		_G.reloadables["reloadable_custom_" .. str .. "__OBJ__" .. objectName] = false;
		_G.reloadables["reloadable_manually_" .. str .. "__OBJ__" .. objectName] = true;
		_G.reloadables["preserved_value_" .. str .. "__OBJ__" .. objectName] = nilPlaceholder;
		_G.reloadables["has_preserved_value_" .. str .. "__OBJ__" .. objectName] = false;
	end
	
	return nil
end

-- NOTICE: this now happens AFTER reloadUninit, to allow the custom stuff to detach from the automatically preserved (and temp nilled) variables.
function preserveObjectsBeforeReloadUninit(module)	
	assert_luamodule(module)

	local str = module._NAME
	
	-- loop everything in _G.reloadables starting with "reloadable_"
	-- set matching "preserved_value_" to the objects value
	-- set the object value to nil
	
	local manually_reloadables = {}

	logger:debug("Checking for objects to preserve in module: "..str)

	-- note, since the table will hash these and mix up the order, doing some hacky things here...
	-- going through the table twice, first handling custom objects, then automatically preserved ones
	-- (as they may be dependent, but their preserve/restore should never be able to depend the other way around?)

	-- NOTE: could optimize this quite a bit
	
	for loopi=1,2 do

	if (loopi == 1) then
		logger:debug("Checking for custom handled objects to preserve in: "..str)
	else
		logger:debug("Checking for normal objects to preserve in: "..str)
	end
	
	local key = nil
	local value = nil
	for key,value in pairs(_G.reloadables) do
		if (string.sub(key, 1, #"reloadable_name_") == "reloadable_name_") then
			local endPart = string.sub(key, 1 + #"reloadable_name_")
			local moduleName = _G.reloadables["reloadable_modulename_" .. endPart]
			local packageName = _G.reloadables["reloadable_packagename_" .. endPart]
			local fullModuleName = packageName .. moduleName

			--logger:debug("Checking: "..fullModuleName.." vs "..str)
			--logger:debug("Checking: "..key.." vs "..str)
			
			-- is this object part of the module we are currently trying to preserve/restore?
			if (str == fullModuleName) then
				local manually = _G.reloadables["reloadable_manually_" .. endPart]
				local custom = _G.reloadables["reloadable_custom_" .. endPart]
				local creator = nil
				local deleter = nil
				if (custom == true) then
					creator = _G.reloadables["reloadable_creator_" .. endPart]
					deleter = _G.reloadables["reloadable_deleter_" .. endPart]
				end
				
				-- if loopi
				if ((loopi == 1 and custom == true) or (loopi == 2 and custom == false)) then
				
				if (manually == true) then
					logger:debug("Skipped: "..fullModuleName.."."..tostring(value))
					table.insert(manually_reloadables, value)
				else
					logger:debug("Preserving: "..fullModuleName.."."..tostring(value))
					
					-- set matching object value by "preserved_value_" 
					if (_G.reloadables["has_preserved_value_" .. endPart] == true) then
						logger:warning("A previously preserved value exists for variable \""..value .."\"")
					end
					if (deleter) then
						local deleterFunc = module[deleter]
						if (deleterFunc) then
							assert_function(deleterFunc)
							local params = _G.reloadables["reloadable_params_" .. endPart]
							local success, noReturnPlease = pcall(deleterFunc, value, params)
							if (not(success)) then
								logger:warning("Creation of \""..value.."\", creator function \""..deleter.."\" in module \""..fullModuleName.."\" failed: " .. noReturnPlease)
							else
								if (noReturnPlease) then
									logger:warning("Deletion of \""..value.."\", deleter function \""..deleter.."\" in module \""..fullModuleName.."\" returned a value when nil return value expected.")
								end
							end
							if module[value] then
								-- allowing functions to exist even after deletion (in case this is a callback add/remove to that function
								if (type(module[value]) ~= "function") then
									logger:error("Deletion of \""..value.."\" not done properly, deleter function \""..deleter.."\" of module \""..fullModuleName.."\" was run, but the variable value was not set to nil by the deleter.")
								end
							end
						else
							logger:error("Failed to delete \""..value.."\" for reload, deleter function \""..deleter.."\" was not found in module \""..fullModuleName.."\".")
						end
					else
						if (module[value] == nil) then
							_G.reloadables["preserved_value_" .. endPart] = nilPlaceholder
						else
							_G.reloadables["preserved_value_" .. endPart] = module[value]
						end
						module[value] = nil
					end
					_G.reloadables["has_preserved_value_" .. endPart] = true				
				end
				
				end
				-- end if loopi
				
			end
		end
	end
	
	end
	
	-- ensure that the package has no userdata, number or string types left.
	local amountOfInvalid = 0
	local key = nil
	local value = nil
	for key,value in pairs(module) do
		if key == "_NAME" or key == "_M" or key == "_PACKAGE" 
			or key == "reloadAllowed"
			or key == "lastModifiedSeconds" 
			or key == "lastModifiedHours" 
			or key == "reloadOnlyInEditor" 
			or key == "sourceFile"
			or key == "useSourceFile"
			or key == "stateCollection"
			or key == "isValidScriptedState"
		then
			-- these are ok
		else
			if (type(module[key])) ~= "function" then
				local seemsLikeModule = false
				local seemsLikeAiState = false
				if ((type(module[key])) == "table") then
					local firstChar = string.sub(key, 1, 1)
					if (string.upper(firstChar) == firstChar) then
						if (key._NAME) then
							seemsLikeModule = true
						end
						if (module[key]["isValidScriptedState"] == true) then
							seemsLikeAiState = true
						end
						--if (module.stateCollection) then
						--	seemsLikeAiState = true
						--end
					end
				end
				if (not(seemsLikeModule) and not(seemsLikeAiState)) then
					-- if this was marked as manually reloaded, everything is cool
					local was_manual = false
					for manualindex,manualkey in pairs(manually_reloadables) do
						if (manualkey == key) then was_manual = true end
					end
					if (not(was_manual)) then
						logger:warning("Module \"".. module._NAME .."\" has variable \"" .. key .. "\" that has not been properly handled for reload.")
						amountOfInvalid = amountOfInvalid + 1
					end
				end
			end
		end
	end

	if amountOfInvalid > 0 then
		logger:info("All used lua variables should either be local variables, or they should be marked for appropriate reload handling.")
	end
	
end

-- NOTICE: this now happens BEFORE reloadInit, to allow the custom stuff to use the automatically restored variables.
function restoreObjectsBeforeReloadInit(module)
	assert_luamodule(module)
	
	local str = module._NAME

	-- NOTE: could optimize this quite a bit
	
	for loopi=1,2 do
	
	local key = nil
	local value = nil
	for key,value in pairs(_G.reloadables) do
		if (string.sub(key, 1, #"reloadable_name_") == "reloadable_name_") then
			local endPart = string.sub(key, 1 + #"reloadable_name_")
			local moduleName = _G.reloadables["reloadable_modulename_" .. endPart]
			local packageName = _G.reloadables["reloadable_packagename_" .. endPart]
			local fullModuleName = packageName .. moduleName
			
			-- is this object part of the module we are currently trying to preserve/restore?
			if (str == fullModuleName) then
				local manually = _G.reloadables["reloadable_manually_" .. endPart]
				local custom = _G.reloadables["reloadable_custom_" .. endPart]
				local creator = nil
				local deleter = nil
				if (custom == true) then
					creator = _G.reloadables["reloadable_creator_" .. endPart]
					deleter = _G.reloadables["reloadable_deleter_" .. endPart]
				end

				-- if loopi
				if ((loopi == 2 and custom == true) or (loopi == 1 and custom == false)) then
				
				if (manually == true) then
					logger:debug("Skipped: "..fullModuleName.."."..tostring(value))
				else
					logger:debug("Restoring: "..fullModuleName.."."..tostring(value))
					
					-- set matching object value by "preserved_value_" 
					if (_G.reloadables["has_preserved_value_" .. endPart] == true) then
						if (creator) then
							local creatorFunc = module[creator]
							if (creatorFunc) then
								assert_function(creatorFunc)
								local params = _G.reloadables["reloadable_params_" .. endPart]
								local success, noReturnPlease = pcall(creatorFunc, value, params)
								if (not(success)) then
									logger:warning("Creation of \""..value.."\", creator function \""..creator.."\" in module \""..fullModuleName.."\" failed: " .. noReturnPlease)
								else
									if (noReturnPlease) then
										logger:warning("Creation of \""..value.."\", creator function \""..creator.."\" in module \""..fullModuleName.."\" returned a value. The creator function is expected to set the module variable directly, and return nil.")
									end
								end								
								if module[value] == nil then
									logger:warning("Failed to restore \""..value.."\", creator function \""..creator.."\" in module \""..fullModuleName.."\" set the variable to nil. (Note, this may be correct behaviour if nil creation is acceptable.)")
								end
							else
								logger:error("Failed to restore \""..value.."\", creator function \""..creator.."\" was not found in module \""..fullModuleName.."\".")
							end
						else
							if (_G.reloadables["preserved_value_" .. endPart] == nilPlaceholder) then
								module[value] = nil
							else
								module[value] = _G.reloadables["preserved_value_" .. endPart]							
							end
						end
						_G.reloadables["preserved_value_" .. endPart] = nilPlaceholder
						_G.reloadables["has_preserved_value_" .. endPart] = false
					else
						logger:warning("No preserved value found to restore variable \""..value .."\"")
					end				
				end
				
				end
				-- end if loopi
				
			end
		end
	end
	
	end
	
end


-- global aliases for easier use. always use these instead of using the fully qualified names.

if (debug.ReloadScripts.reloadInUse) then
	_G.declareReload = _M.reloadableObject
	_G.declareCustomReload = _M.reloadableCustomObject
	_G.declareManualReload = _M.manuallyReloadedObject
	_G.createCustomReloadObject = _M.createReloadableCustomObject
else
	_G.declareReload = _M.nop
	_G.declareCustomReload = _M.nop
	_G.declareManualReload = _M.nop
	_G.createCustomReloadObject = _M.createReloadableCustomObject
end

