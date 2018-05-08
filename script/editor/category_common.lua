module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

require "debug.Assert"
require "debug.AutoReloadable"

local thisModule = _M

function locateReference(guid)
	assert_string(guid)
	
	editor.ExternalUI.locateGUIDString(guid)
end

function locateReferenceWithoutFocus(guid)
	assert_string(guid)
	editor.ExternalUI.locateGUIDString(guid, nil, true)
end

function stringStartsWith(str, substr)
	assert_string(str)
	assert_string(substr)
	if (#str >= #substr) then
		-- TODO: optimize, very inefficient logic
		if string.sub(str, 1, #substr) == substr then
			return true
		end
	end
	return false
end


-- note, untested
-- locates an instance from the instance tree based on given name
function locateInstanceByName(instanceName)
	assert_string(instanceName)
	
	local inst = scene:getInstanceManager():findInstanceByName(instanceName)
	
	if (inst ~= nil) then
		editor.ExternalUI.locateGUIDString(tostring(inst:getGuid()))
	else
		logger:error("No instance found with name \""..instanceName.."\".")
	end
end

-- locates an object (given as editor id) in the category view
function locateEditorIdFromCategoryView(editorId)
	locateEditorIdFromCategoryViewImpl(editorId)
end

-- locates the TYPE of an object (given as editor id) in the category view
-- if the object is a type itself, locate it.
function locateTypeOfEditorIdFromCategoryView(editorId)
	if (stringStartsWith(editorId, "[GUID_NONE")) then
		logger:warningWithCaption("GUID_NONE editor id encountered. It cannot be located from the category view.", "Cannot locate GUID_NONE.")
		return
	end
	
	-- detect if the editorId is a type, detect if the editorId is an instance
	-- this can be done by looking at the specific GUID bytes... urgh.. lua string processing..
	local isType = false
	local isInstance = false
	
	if (stringStartsWith(editorId, "[GUID(")) then
		-- HACK: this is not pretty. and assumes no whitespaces.
		local typeByte = string.sub(editorId, 35, 2)
		if (typeByte == "55") then
			isType = true
		end
		if (typeByte == "33") then
			isInstance = true
		end
	end

	if not(isInstance or isType) then
		-- try to find it this way...
		local obj = editor.ExternalUI.getObjectByEditorObjectId(editorId)
		if (obj) then
			if (typeManager:isType(obj:getUnifiedHandle())) then
				isType = true
			end
			if (obj.getType) then
				-- probably an instance
				isInstance = true
			end
		end	
	end
	
	if (isType) then
		--logger:infoWithCaption("The given object is a type. Attempting to locate the given type itself.", "Locating the type itself")
		locateEditorIdFromCategoryViewImpl(editorId)
	elseif (isInstance) then
		-- TODO: get the instance pointed by the editorId...
		-- then dig out the type editor Id...
		-- and locate that
		local inst = editor.ExternalUI.getObjectByEditorObjectId(editorId)
		local typeUH = inst:getType()
		local typ = typeManager:getTypeByUH(typeUH)
		local tmpTable = { }
		editor.Editor.dumpBranchHeader(tmpTable, typ, false, 1)
		local typeEditorId = tmpTable[1]
		locateEditorIdFromCategoryViewImpl(typeEditorId)
	else
		logger:warningWithCaption("The given object is not an instance, so the relevant type cannot be located for it. Attempting to locate the given object itself.", "Cannot locate object type, not an instance")
	end
	
end
	
-- finds the given instance/type/resource/etc. editor id from the category window
-- uses automated logic to determine which window to seek from / open in
-- (to explicitly specify a window to seek in, use the locateEditorIdFromCategories function instead
function locateEditorIdFromCategoryViewImpl(editorId)
	assert_string(editorId)

	-- get the ACTUAL object that the editorId refers to (get guid out of editorId, seek based on that)
	-- then use the object type to really determine which of these we're dealing with

	local isParticleComponent = false -- a particle effect component
	local isParticleEffect = false    -- a particle effect type
	local isParticleSystem = false    -- a particle system entity type
	local isParticleSystemImplementation = false    -- a particle system implementation type
	local isColorProperty = false     -- a color property value
	local isQATask = false            -- a QA task entity

	-- HACK: for now, using the icon and name to guess the object type
	-- does this seem like a particle system component?
	-- if so, best find the 
	if (string.find(editorId, "EditorHint_Icon_ParticleComponent", 1, true)) then
		isParticleComponent = true
	else
		-- does this seem like a particle system itself?
		if (string.find(editorId, "EditorHint_Icon_Particle", 1, true)) then
			if (string.find(editorId, "ImplementationEntity", 1, true)) then
				isParticleSystem = true
			else
				isParticleSystemImplementation = true
			end
		end
	end
	
	if (string.find(editorId, ",PROP,", 1, true)) then
		if (string.find(editorId, ",TYPE,COL", 1, true)) then
			isColorProperty = true
		end
	end

	-- TODO: yeah, I don't really know how to detect these.
	if (string.find(editorId, "QATaskEntity", 1, true)) then		
		isQATask = true
	end
	
	-- now, there are some special cases, such as the particle editor ids... 
	-- we really don't want to seek the actual component or such, but rather the particle system
	local actuallySeekEditorId = editorId
	if (isParticleSystem) then
		-- ok, seek itself
	elseif (isParticleSystemImplementation) then
		-- TODO: seek the system instead
		-- actuallySeekEditorId = ...
	elseif (isParticleEffect) then
		-- TODO: seek the system instead
		-- actuallySeekEditorId = ...
	elseif (isParticleComponent) then
		-- TODO: seek the system instead
		-- actuallySeekEditorId = ...
	elseif (isQATask) then
		-- TODO: if it refers to some hansoft task, should perhaps seek that?
		-- actuallySeekEditorId = ...
	else
		-- just seek the id itself
	end


	-- then, decide which category window to really seek it in
	if (isParticleSystem or isParticleSystemImplementation or isParticleEffect or isParticleComponent) then
		-- ok, seek it primarily in the particle editor window (and as a failsafe in some other windows)... 
		-- if not shown in any existing window, seek all of the existing references and open in special "particle_systems" window
		locateEditorIdFromCategories(editorId, "particle_systems", "particle_systems", true, true, false, "particle_systems")
	elseif (isQATask) then
		-- ok, seek it primarily in the particle editor window (and as a failsafe in some other windows)... 
		-- TODO: seek from task windows
		--locateEditorIdFromCategories(editorId, "tasks", "local/my_tasks", true, true, false, "tasks")
	else
		-- otherwise, open in any available window (that happens to contain the editorId), or open a new window if there is a category reference to it, but no window open
		locateEditorIdFromCategories(editorId, nil, nil, true, true, true, nil)
	end
	
end


-- finds the given instance/type/resource/etc. editor id from the category window
-- seeking goes as follows (in the following order)
-- seekFromSpecialWindow, when a non-nil string is given, a category window that was opened with this special id will be searched
-- seekFromCategoryPath, when a non-nil string is given, a category window that is showing this category path will be used to seek the object from
-- seekFromAllOpenNonSpecialWindows, when true, the search occurs on all open category windows, except for the special id windows
-- seekFromAllOpenWindows, when true, the search occurs on all open category windows
-- seekAnywhereAndOpenWindow, when true, the search occurs on all existing category references - a new window is opened on find
-- seekAnywhereAndOpenSpecialWindow, when non-nil string, the search occurs on all existing category references - existing special window is used or a new special id window is opened on find
-- note, some combinations such as seekAnywhereAndOpenWindow=true and seekAnywhereAndOpenSpecialWindow="something" makes little sense, as the latter one can never occur.
function locateEditorIdFromCategories(editorId, seekFromSpecialWindow, seekFromCategoryPath, seekFromAllOpenNonSpecialWindows, seekFromAllOpenWindows, seekAnywhereAndOpenWindow, seekAnywhereAndOpenSpecialWindow)
	if (seekFromSpecialWindow == nil) then
		seekFromSpecialWindow = "nil"
	end
	if (seekFromCategoryPath == nil) then
		seekFromCategoryPath = "nil"
	end
	local maskString = "" -- bitmask :P
	if (seekFromAllOpenNonSpecialWindows) then maskString = maskString .. "1" else  maskString = maskString .. "0" end
	if (seekFromAllOpenWindows) then maskString = maskString .. "1" else  maskString = maskString .. "0" end
	if (seekAnywhereAndOpenWindow) then maskString = maskString .. "1" else  maskString = maskString .. "0" end
	if (seekAnywhereAndOpenSpecialWindow == nil) then
		seekAnywhereAndOpenSpecialWindow = "nil"
  end
	externalUI:sendUICommand("locateFromCategories(\"" .. editorId.. "\", \"" .. seekFromSpecialWindow .. "\", \"" .. seekFromCategoryPath .. "\", \""..maskString.."\", \"" .. seekAnywhereAndOpenSpecialWindow .. "\")")	
end
