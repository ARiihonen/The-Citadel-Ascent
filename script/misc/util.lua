module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

require "debug.Assert"

-- This resaves all types that inherit (directly or indirectly) from a static type that has a script. That's almost all types.
function kickStaticTypesWithScript()
	local function kickTypeAndChildren(data)
		local originalCollectAllChildren = data.collectAllChildren
		local typeObj = data.typeObj
		data.typesHandled = data.typesHandled + 1
		if typeObj:isStaticType() and typeObj:getTypeScript() ~= "" then
			typeObj:setScriptDirtyChildrenToo()
			data.collectAllChildren = true
			data.numKicked = data.numKicked + 1
		end
		if data.collectAllChildren then
			table.insert(data.typesToSave, typeObj:getGUID())
		end
		for i = 0, typeObj:getNumChildren() - 1 do
			data.typeObj = typeObj:getChild(i)
			kickTypeAndChildren(data)
		end
		data.collectAllChildren = originalCollectAllChildren
	end
	local data = { typesHandled = 0, numKicked = 0, typeObj = typeManager:getTypeRoot(), typesToSave = { }, collectAllChildren = false }
	local numKicked = kickTypeAndChildren(data)
	logger:info("Kicked " .. data.numKicked .. " types")
	logger:info("Need to save " .. #data.typesToSave .. " types")
	typeManager:saveTypeScripts(false, data.typesToSave)
end

function stopEffect(guid)
	local effectEntity = gameScene:getSceneInstanceManager():findInstanceByGUID(guid)
	if effectEntity then
		local effectComponent = effectEntity:findComponent(gameplay.effect.EffectComponent)
		if effectComponent then
			effectComponent:stopEffect()
		else
			logger:error("misc.util.stopEffect: Could not find effectComponent from effectEntity")
		end
	else
		logger:error("misc.util.stopEffect: Could not find effectEntity")
	end
end


function isSceneLua()
	-- Note: this is for debugging purposes only. On consoles there's only one lua
	local resultByDecodaname = decoda_name == nil
	local resultByGameScene = gameScene == nil
	if resultByDecodaname == resultByGameScene then
		return resultByDecodaname
	else
		logger:error("Conflicting results when trying to determine sceneness: resultByDecodaname = " .. 
				tostring(resultByDecodaname) .. ", resultByGameScene = " .. tostring(resultByGameScene))
		return resultByGameScene
	end
end


function goToTrailerMode()
	-- Add here commands needed by trailer recording (hiding gui, disabling music etc.
	cheat.makePlayerActorsImmortal()
	audioModule:setVolumeVocals(0)
	audioModule:setVolumeMusic(0)
	if debug.DebugStatsOverlayUtil.overlayWindow then
		debug.DebugStatsOverlayUtil.destroyDebugStatsOverlayWindow()
	end
	if fuiEffectManager then
		fuiEffectManager:hideFUI(0)
	end
	if gUIModule then
		gUIModule:setDisableRendering(true)
	end
end

function lsTable(table, dontUseConsole, indent, handledTables)
	local consolePrintFunc = postConsoleMessage
	if dontUseConsole then
		consolePrintFunc = function() end
	end

	local  indentString = ""
	if indent ~= nil then indentString = indent end
	
	local count = 0
	if type(table) ~= "table" then
		consolePrintFunc("Given variable is not a table")
		logger:debug("Given variable is not a table")
		return
	end
	if handledTables == nil then handledTables = { } end

	for name, value in pairs(table) do
		if (type(value) == "string") then
			local str = value
			if (#str > 20) then
				str = str:sub(1, 20) .. "..."
			end
			consolePrintFunc(indentString .. tostring(name) .. " (" .. type(value) .. ", " .. str .. ")")
			logger:debug(indentString .. tostring(name) .. " (" .. type(value) .. ", " .. str .. ")")		
		elseif type(value) == "number" then
			consolePrintFunc(indentString .. tostring(name) .. " (" .. type(value) .. ", " .. value .. ")")
			logger:debug(indentString .. tostring(name) .. " (" .. type(value) .. ", " .. tostring(value) .. ")")
		elseif type(value) == "boolean" then
			consolePrintFunc(indentString .. tostring(name) .. " (" .. type(value) .. ", " .. tostring(value) .. ")")
			logger:debug(indentString .. tostring(name) .. " (" .. type(value) .. ", " .. tostring(value) .. ")")
		elseif indent ~= nil and type(value) == "table" then
			local cyclic = handledTables[value]

			consolePrintFunc(indentString .. tostring(name) .. " (" .. type(value) .. (cyclic and ", cyclic ref" or "") .. ")")
			logger:debug(indentString .. tostring(name) .. " (" .. type(value) .. (cyclic and ", cyclic ref" or "") .. ")")
			handledTables[value] = true
			if not cyclic then lsTable(value, dontUseConsole, indentString .. "    ", handledTables) end
		else
			consolePrintFunc(indentString .. tostring(name) .. " (" .. type(value) .. ")")
			logger:debug(indentString .. tostring(name) .. " (" .. type(value) .. ")")
		end
		count = count + 1
		handledTables[value] = true
	end
	consolePrintFunc("Total " .. count .. " item(s)")
	logger:debug("Total " .. count .. " item(s)")
end


function testTypeComponentDependencies(tagErrors, dontPrintErrors)
	local problems = 0
	local subProblems = 0
	local function recursiveTest(typ)
		local errorMessage = typ:checkSubComponentDependencies(tagErrors)
		if errorMessage ~= "" then
			subProblems = subProblems + 1
			if not dontPrintErrors then
				logger:error("Not all dependencies of " .. typ:getName() .. " are satisfied: " .. errorMessage);
			end
		end
		errorMessage = typ:checkComponentDependencies(tagErrors)
		if errorMessage ~= "" then
			problems = problems + 1
			if not dontPrintErrors then
				logger:error("Not all dependencies of " .. typ:getName() .. "'s components are satisfied: " .. errorMessage);
			end
		end
		for i = 0, typ:getNumChildren() - 1 do
			recursiveTest(typ:getChild(i))
		end
	end
	recursiveTest(typeManager:getTypeRoot())
	logger:info("Found " .. problems .. " type(s) with unsatisfied component dependencies and " .. subProblems .. " type(s) with missing sub components")
end


function printAllComponentDependencies()
	local function recursion(typ)
		local dep = ""
		local optDep = ""
		local sub = ""
		local optSub = ""
		for i = 0, typ:getNumComponentDependencies() - 1 do
			dep = dep .. typ:getComponentDependency(i) .. ", "
		end
		for i = 0, typ:getNumOptionalComponentDependencies() - 1 do
			optDep = optDep .. typ:getOptionalComponentDependency(i) .. ", "
		end
		for i = 0, typ:getNumSubComponentDependencies() - 1 do
			sub = sub .. typ:getSubComponentDependency(i) .. ", "
		end
		for i = 0, typ:getNumOptionalSubComponentDependencies() - 1 do
			optSub = optSub .. typ:getOptionalSubComponentDependency(i) .. ", "
		end
		local result = ""
		if dep ~= "" then result = result .. "\tDependencies: " .. dep:sub(1, -3) .. "\n" end
		if optDep ~= "" then result = result .. "\tOptional dependencies: " .. optDep:sub(1, -3) .. "\n" end
		if sub ~= "" then result = result .. "\tSub dependencies: " .. sub:sub(1, -3) .. "\n" end
		if optSub ~= "" then result = result .. "O\tptional sub dependencies: " .. optSub:sub(1, -3) .. "\n" end
		if result ~= "" then result = "Dependencies for " .. typ:getName() .. "\n" .. result end
		for i = 0, typ:getNumChildren() - 1 do
			result = result .. recursion(typ:getChild(i))
		end
		return result
	end
	local result = recursion(typeManager:getTypeRoot())
	logger:info(result)
end


function _G.getInstanceType(instance) -- bah namespaces, who needs em
	if instance == nil then
		logger:error("Misc:Util:getInstanceType - Instance param is nil.");
		return nil;
	end	
	return typeManager:getTypeByUH(instance:getType())
end


function printToConsole(str)
	postConsoleMessage(str)
	local newLineOpt = string.find(str, "\n") and "\n" or ""
	logger:debug("printToConsole: " .. newLineOpt .. str)
end


function _G.isInstanceOfExactType(instanceUH, typeUH)
	-- assert_uh(instanceUH)
	-- assert_uh(typeUH)
	
	-- TODO: ...
	logger:error("isInstanceOfExactType unimplemented.")
end

-- NOTE: this possibly is somewhat identical to some of the common_utils?
function _G.isInstanceOfExactTypeName(instanceUH, typeNameString)
	-- assert_uh(instanceUH)
	assert_string(typeNameString)
	
	-- note, assuming scene instance
	-- FIXME: should support state instances as well...
	obj = gameScene:getSceneInstanceManager():getInstanceByUH(instanceUH)
	if (not(obj)) then
		logger:error("Failed to find an instance by given UH.")
		return false
	end
	
	if (not(obj.getType)) then
		return false
	end
	
	local typeUH = obj:getType()
	local type = typeManager:getTypeByUH(typeUH);
	if (not(type)) then
		return false
	end
	
	-- FIXME: this requires exact type name match, when should instead see if the object inherits the given type.
	local typename = type:getName();	
	if (typename == typeNameString) then
		return true
	else
		return false
	end	
end


function getWarpStateForPlayer(playerIndex)
	local pm = common.CommonUtils.getPlayerManager()
	if not pm then return nil end
	local character = pm:getCharacterInstanceForPlayer(playerIndex)
	if not character then
		logger:error("Could not find instance for player using index " .. tostring(playerIndex));
		return nil
	end
	local ws = character:getControllerComponent():findStateComponentByCollection("WarpState")
	if not ws then
		logger:error("Could not find warpstate for player " .. tostring(playerIndex))
	end
	return ws
end


function warpPlayerForward(playerIndex)
	local ws = getWarpStateForPlayer(playerIndex)
	if not ws then return end
	ws:doStateCall("warpForwardPressed")
end


function warpPlayerUp(playerIndex)
	local ws = getWarpStateForPlayer(playerIndex)
	if not ws then return end
	ws:doStateCall("warpUpPressed")
end


function warpPlayerDown(playerIndex)
	local ws = getWarpStateForPlayer(playerIndex)
	if not ws then return end
	ws:doStateCall("warpDownPressed")
end


-- From Lua users wiki (http://lua-users.org/wiki/SplitJoin)
function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end


function getSelectedPlayer(index)
	local cm = common.CommonUtils.getCharacterSelectionManager()
	if not cm then return nil end

	for i = 0, 8 do
		local character = cm:getLocalCharacterInstanceByIndex(i)
		local csc = character and character:findComponent(trinebase.gameplay.player.TrineCharacterSelectionComponent)
		local selected = csc and csc:isSelected()
		index = selected and index - 1 or index
		if index < 0 then return character end
	end
	return nil
end

function copyCharacterPosToClipboard(noError)
	local character = getSelectedPlayer(0)
	if not character then
		if not noError then 
			if trineTextChat then
				trineTextChat:sendChatMessage("cpCP2CB: no selected player", false)
			end
		end
		return false
	end
	local posStr = tostring(character:getTransformComponent():getPosition())
	scriptModule.copyStringToClipboard(posStr)
	
	if trineTextChat then
		trineTextChat:sendChatMessage("cpCP2CB: Character " .. character:getName() .. ", pos: " .. posStr, false)
	end
	
	return true
end


function pasteCharacterPosFromClipboard(noError)
	local character = getSelectedPlayer(0)
	if not character then
		if not noError then 
			if trineTextChat then
				trineTextChat:sendChatMessage("psCP2CB: no player", false)
			end
		end
		return false
	end
	local posStr = scriptModule.copyStringFromClipboard()
	local posFunc = loadstring("return " .. tostring(string.sub(posStr, 0, string.find(posStr, ")"))))
	if not posFunc then
		if not noError then 
			if trineTextChat then
				trineTextChat:sendChatMessage("psCP2CB: unable to parse position from clipboard", false)
			end
		end
		return false
	end
	character:getTransformComponent():setPosition(posFunc())
	if trineTextChat then
		trineTextChat:sendChatMessage("psCP2CB: Character " .. character:getName() .. "moved to pos " .. tostring(posFunc()), false)
	end
	local character = getSelectedPlayer(1)
	if character then
		character:getTransformComponent():setPosition(posFunc())
		if trineTextChat then
			trineTextChat:sendChatMessage("psCP2CB: Character " .. character:getName() .. "moved to pos " .. tostring(posFunc()), false)
		end
	end
	local character = getSelectedPlayer(2)
	if character then
		character:getTransformComponent():setPosition(posFunc())
		if trineTextChat then
			trineTextChat:sendChatMessage("psCP2CB: Character " .. character:getName() .. "moved to pos " .. tostring(posFunc()), false)
		end
	end
	return true
end
