module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

require "debug.Assert"
require "debug.AutoReloadable"
require "editor.Util"

-- create this "package-like-thingy" for the plugins to use.
_G.plugin = { }

local thisModule = _M

selectionListeners = { }
addedGlobalSelectionListener = false
unselectCallbacksToCall = { }

declareReload(thisModule, [[selectionListeners]])
declareReload(thisModule, [[addedGlobalSelectionListener]])
declareReload(thisModule, [[unselectCallbacksToCall]])

-- A global variable for the HTML plugins scripting convenience
-- (this variable is set during specific listenToSelectionWithComponent callbacks for easy access to related selection components)
_G.listenedComponents = nil
_G.listenedEntities = nil


-- allows a HTML plugin (or even an application plugin, or even other editor scripts) to listen to selections with specific components
_G.editor.listenToSelectionWithComponent = function(pluginName, componentToListenTo, selectCallbackFunction, unselectCallbackFunction, listenToMultiselection)
	assert_string(pluginName)
	--assert_componenttype(componentToListenTo)
	assert_function(selectCallbackFunction)
	assert_function(unselectCallbackFunction)
	assert_boolean(listenToMultiselection)
	
	-- the all plugin shared listener hook
	if not addedGlobalSelectionListener then
		editor.ExternalUI.addSelectionChangeListener(selectionChangedImplWrap)
		addedGlobalSelectionListener = true
	end
	
	-- this specific component type filtered callback
	local listenEntry = { pluginName = pluginName, listenToComponent = componentToListenTo, selectCallback = selectCallbackFunction, unselectCallback = unselectCallbackFunction, listenToMultiselection = listenToMultiselection }	
	table.insert(selectionListeners, listenEntry)
end


-- HTML plugin functions (not valid for usage with .exe application plugins)
-- note, the propertyName and propertyValue here are the C# .NET Control property names and their values
_G.editor.setPluginValue = function(pluginName, elementId, propertyName, propertyValue)
	assert_string(pluginName)
	assert_string(elementId)
	assert_string(propertyName)
	
	local propertyValueStr = tostring(propertyValue)
	editor.Plugin.setPluginValueImpl(pluginName, elementId, propertyName, propertyValueStr)
end


-- sets the value of the given component
_G.editor.setComponentPropertyToValue = function(componentObject, propertyName, propertyValue)
	-- componentObject can be an actual object or UH pointing to it
	if (type(componentObject) == "userdata" and getScriptClassName(componentObject) == "UH") then
		componentObject = scene:getSceneInstanceManager():getInstanceByUH(componentObject)
	end
	-- the component does not exist anymore? (or an otherwise invalid parameter was given)
	if componentObject == nil then
		logger:warning("Attempting to set value for non-existing component object.")
		return
	end
	
	if (componentObject["set"..propertyName] == nil) then
		logger:error("Attempt to set the property \""..propertyName.."\" value for a component of class \""..componentObject:getClassName().."\" that has no such property.")
		return
	end

	--assert_component(componentObject)
	assert_string(propertyName)
	componentObject["set"..propertyName](componentObject, propertyValue)
end

-- sets an individual component (member variable) of the component property, such as the .x of a VC3 property, etc.
_G.editor.setComponentPropertyValueComponentToValue = function(componentObject, propertyName, propertyValueComponentName, propertyValue)
	assert_string(propertyName)
	assert_string(propertyValueComponentName)
	
	-- componentObject can be an actual object or UH pointing to it
	if (type(componentObject) == "userdata" and getScriptClassName(componentObject) == "UH") then
		componentObject = scene:getSceneInstanceManager():getInstanceByUH(componentObject)
	end
	-- the component does not exist anymore? (or an otherwise invalid parameter was given)
	if componentObject == nil then
		logger:warning("Attempting to set value for non-existing component object.")
		return
	end	

	if (componentObject["get"..propertyName] == nil) then
		logger:error("Attempt to set the property \""..propertyName.."\" value for a component of class \""..componentObject:getClassName().."\" that has no such property.")
		return
	end
	
	local tmp = componentObject["get"..propertyName](componentObject)
	-- HACK: color does not have the r,g,b members, but it has getRed,getGreen,getBlue - map to those...
	-- HACK: also hack, rotation does not have axis angle members, map angleX,angleY,angleZ as axis angles for QUAT via appropriate functions...
	if (propertyValueComponentName == "r" or propertyValueComponentName == "g" or propertyValueComponentName == "b") then
		if (tmp.getRed and tmp.getGreen and tmp.getBlue) then
			if (propertyValueComponentName == "r") then
				tmp = COL(propertyValue, tmp:getGreen(), tmp:getBlue())
			end
			if (propertyValueComponentName == "g") then
				tmp = COL(tmp:getRed(), propertyValue, tmp:getBlue())
			end
			if (propertyValueComponentName == "b") then
				tmp = COL(tmp:getRed(), tmp:getGreen(), propertyValue)
			end
			componentObject["set"..propertyName](componentObject, tmp)
		else
			logger:error("Attempting to set an r,g,b value to non COL type property?")
		end
	elseif (propertyValueComponentName == "angleX" or propertyValueComponentName == "angleY" or propertyValueComponentName == "angleZ") then
		if (tmp.makeFromAngles and tmp.getEulerAngles) then
			local euler = tmp:getEulerAngles()
			if (propertyValueComponentName == "angleX") then
				euler.x = propertyValue * 3.1415/180.0
			end
			if (propertyValueComponentName == "angleY") then
				euler.y = propertyValue * 3.1415/180.0
			end
			if (propertyValueComponentName == "angleZ") then
				euler.z = propertyValue * 3.1415/180.0
			end
			local tmp2 = QUAT(0,0,0,1)
			tmp2:makeFromAngles(euler.x, euler.y, euler.z)
			componentObject["set"..propertyName](componentObject, tmp2)
		else
			logger:error("Attempting to set an angleX,angleY,angleZ value to non QUAT type property?")
		end
	else
		if (tmp[propertyValueComponentName]) then
			tmp[propertyValueComponentName] = propertyValue
			componentObject["set"..propertyName](componentObject, tmp)	
		else
			logger:error("The property \""..propertyName.."\" does not have value component of name \""..propertyValueComponentName.."\".")
		end
	end
end


_G.editor.runPluginLuaString = function(luaStringToRun)
	local line = luaStringToRun
	local loadedFunction, errorMessage = loadstring(line)
	if not loadedFunction then
		logger:error("Lua string run error: " .. errorMessage)
		logger:debug("The string to run follows:\r\n" .. line)
		return
	end

  local ok, output = pcall(loadedFunction)
  if ok == false then
    logger:error("Lua string run error: " .. tostring(output))
		logger:debug("The string to run follows:\r\n" .. line)
    return
  else
		if (output ~= nil) then
			logger:warning("Lua string run returned value (when no return value is expected): " .. tostring(output))
		else
			-- ok
		end
  end	
end


_G.editor.toggleKeepOnTop = function(win, keepOnTopMenuItemName) 
	if not win.keepOnTop then
		win.keepOnTop = true
		editor.setPluginValue(pluginName, "_self", "TopMost", true)
		editor.setPluginValue(pluginName, keepOnTopMenuItemName, "Checked", true)
	else
		win.keepOnTop = nil
		editor.setPluginValue(pluginName, "_self", "TopMost", false)
		editor.setPluginValue(pluginName, keepOnTopMenuItemName, "Checked", false)
	end
end


_G.editor.pinPluginWindowLegacy = function(win, pinMenuItem) 
	if not win.pinnedToComponent then
		if (win.shownComponent) then
			win.pinnedToComponent = win.shownComponent:getUnifiedHandle()
			editor.setPluginValue(pluginName, pinMenuItem, "Checked", true)
		else
			win.pinnedToComponent = nil
			editor.setPluginValue(pluginName, pinMenuItem, "Checked", false)
		end
	else
		win.pinnedToComponent = nil
		editor.setPluginValue(pluginName, pinMenuItem, "Checked", false)
	end
end

_G.editor.pinPluginWindow = function(win, pinMenuItem) 
	if not win.pinnedToEntityUH then
		if (win.shownEntityUH) then
			win.pinnedToEntityUH = win.shownEntityUH
			editor.setPluginValue(pluginName, pinMenuItem, "Checked", true)
		else
			win.pinnedToEntityUH = nil
			editor.setPluginValue(pluginName, pinMenuItem, "Checked", false)
		end
	else
		win.pinnedToEntityUH = nil
		editor.setPluginValue(pluginName, pinMenuItem, "Checked", false)
	end
end

----- internal implementing functions... ------

-- (called automatically for all plugins)
function pluginAttached(pluginName)
	-- nothing much should be done here really... The (HTML-)plugin should rather use the body onload to call whatever script it wants to call on attach
end

function pluginDetached(pluginName)
	-- remove all the selection listeners for the plugin, if any exist
	local newList = { }
	for i,v in ipairs(selectionListeners) do
		if (v.pluginName == pluginName) then
			-- remove listener from the list
		else
			-- keep on the list
			table.insert(newList, v)
		end
	end	

	selectionListeners = newList
	
	local newUnselList = { }
	for i = 1,#unselectCallbacksToCall do
		if (unselectCallbacksToCall[i].pluginName == pluginName) then
			-- remove from list
		else
			-- keep on list
			table.insert(newUnselList, unselectCallbacksToCall[i])
		end		
	end

	unselectCallbacksToCall = newUnselList	
end


function setPluginValueImpl(pluginName, elementId, propertyName, propertyValueStr)
	assert_string(pluginName)
	assert_string(elementId)
	assert_string(propertyName)
	assert_string(propertyValueStr)
		
	editor.ExternalUI.editorPluginResponse(pluginName, "setPluginValue", elementId..","..propertyName..","..propertyValueStr)
end


declareReload(thisModule, [[selectedObjects]])
selectedObjects = { }

function addToSelectionList(obj)
	table.insert(selectedObjects, obj)
end


-- (this wrapper fixes the issue with this callback not getting changed on script reload.)
function selectionChangedImplWrap()
	editor.Plugin["selectionChangedImpl"]()
end

function selectionChangedImpl()
	-- (to prevent script reload issues.)
	local unselectCallbacksToCall = editor.Plugin["unselectCallbacksToCall"]
	local selectionListeners = editor.Plugin["selectionListeners"]
	
	-- call maching unselect for all previously called select callbacks
	for i = 1,#unselectCallbacksToCall do
		unselectCallbacksToCall[i].func()
	end
	editor.Plugin["unselectCallbacksToCall"] = { }
	unselectCallbacksToCall = editor.Plugin["unselectCallbacksToCall"]

	for i,v in ipairs(selectionListeners) do
		_G.listenedComponents = { all = { }, first = nil }
		_G.listenedEntities = { all = { }, first = nil }

		local compType = v.listenToComponent
		local pluginName = v.pluginName
		local shouldCall = false

		selectedObjects = { }
		editor.Editor.seekInstances("data/filter/native/nativefilter_composite_selectedineditor_allowall.fbfilt", nil, addToSelectionList)	

		-- create the list of components for which this call is made for 
		-- add all of them to .all, and set .first = all[1] (if such exists)
		for seli = 1,#selectedObjects do
			local obj = selectedObjects[seli]
			local listenedComp = obj:findComponent(compType);
			if (listenedComp ~= nil) then
				table.insert(listenedComponents.all, listenedComp)
				table.insert(listenedEntities.all, obj)
			end			
		end
		
		if (#_G.listenedComponents.all == 1 or (#_G.listenedComponents.all > 1 and v.listenToMultiselection)) then
			shouldCall = true
		
			_G.listenedComponents.first = _G.listenedComponents.all[1]
			_G.listenedEntities.first = _G.listenedEntities.all[1]
		end
		
		if (shouldCall) then
			-- call it
			v.selectCallback()
			table.insert(unselectCallbacksToCall, { pluginName = v.pluginName, func = v.unselectCallback })
		end		

		_G.listenedComponents = nil
		_G.listenedEntities = nil
	end		
end


----- The automapping to properties based on element id -----

_G.editor.listenToAutoMappedProperties = function(win, allIds, allIdTypes, listenToComponents, selectionCallbackFunc, unselectionCallbackFunc, allowMultiselection)
	assert_table(win)
	assert_string(allIds)
	assert_string(allIdTypes)
	assert_table(listenToComponents)
	assert_function(selectionCallbackFunc)
	assert_function(unselectionCallbackFunc)
	assert_boolean(allowMultiselection)
	
	win.allIds = split_compat(allIds, ",")
	win.allIdTypes = split_compat(allIdTypes, ",")
	win.listenToComponents = listenToComponents
	win.selectionCallbackFunc = selectionCallbackFunc
	for i=1,#listenToComponents do
		editor.listenToSelectionWithComponent(pluginName, listenToComponents[i], selectionCallbackFunc, unselectionCallbackFunc, allowMultiselection)
	end
end

_G.editor.autoMapPluginPropertiesSelection = function(win)
	assert_table(win)
	
	if win.pinnedToEntityUH then
		return
	end
	
	if (listenedEntities.first) then
		win.shownEntityUH = listenedEntities.first:getUnifiedHandle()
	else
		win.shownEntityUH = nil
	end
	
	editor.setPluginValue(pluginName, "_self", "Enabled", true)
	editor.setPluginValue(pluginName, "timer", "Enabled", true)
end

_G.editor.autoMapPluginPropertiesUnselection = function(win)
	assert_table(win)

	if win.pinnedToEntityUH then
		return
	end
	
	win.shownEntityUH = nil
	
	editor.setPluginValue(pluginName, "_self", "Enabled", false)
	editor.setPluginValue(pluginName, "timer", "Enabled", false)
end

-- returns the component type object (e.g. engine.component.TransformComponent or such), for the matching string ("engine.component.TransformComponent" or such)
-- if containsPropertyName is true, then assumes that the last entry after last dot is a property name (e.g. engine.component.TransformComponent.Position)
-- if containsPropertyName is true, then returns 2 values, component and property name
-- returns nil if the given string does not contain enough dots to specify at least the component and property name (or some other error)
function getComponentTypeByName(compNameString, containsPropertyName)
	assert_string(compNameString)
	assert_boolean(containsPropertyName)
	
	local propNameEntries = 0
	if (containsPropertyName) then
		propNameEntries = 1
	end
	
	local splitted = split_compat(compNameString, ".")
	if (#splitted >= 1 + propNameEntries) then
		local propName = splitted[#splitted]
		local componentSeek = _G
		for componentSeekI = 1,#splitted-propNameEntries do
			local tmpp = componentSeek[splitted[componentSeekI]]
			if (tmpp and type(tmpp) == "table") then
				componentSeek = tmpp
			else
				logger:error("The component name parsed from element id is not valid. Namespace \""..tostring(splitted[componentSeekI]).."\" does not exist (parsed from string \""..tostring(compNameString).."\").")
				return nil
			end
		end
		if (containsPropertyName) then
			return componentSeek, propName
		else
			return componentSeek
		end
	else
		return nil
	end
end

_G.editor.autoMapPluginPropertiesUpdate = function(win)
	assert_table(win)
	assert_table(win.allIds)
	assert_table(win.allIdTypes)
	
	if (win.shownEntityUH) then
		local entObj = scene:getSceneInstanceManager():getInstanceByUH(win.shownEntityUH)
		if (entObj == nil) then
			win.shownEntityUH = nil
			editor.setPluginValue(pluginName, "_self", "Enabled", false)
			editor.setPluginValue(pluginName, "timer", "Enabled", false)
			return
		end
		
		local ctypes = win.listenToComponents
		for i=1,#ctypes do
			local compType = ctypes[i]
			local listenedComp = entObj:findComponent(compType);
			if (listenedComp ~= nil) then
				for idNum=1,#win.allIds do
					local componentSeek,propName = editor.Plugin.getComponentTypeByName(win.allIds[idNum], true)
					if (componentSeek ~= nil) then						
						if (componentSeek == compType) then
							local getter = listenedComp["get"..propName]
							if (getter) then
								local propertyValue = getter(listenedComp)
								if (win.allIdTypes[idNum] == "label") then
									editor.setPluginValue(pluginName, win.allIds[idNum], "Text", propertyValue)
									editor.setPluginValue(pluginName, win.allIds[idNum], "Enabled", true)
								elseif (win.allIdTypes[idNum] == "input") then
									if (type(propertyValue) == "boolean") then
										-- HACK: assume this is a checkbox
										editor.setPluginValue(pluginName, win.allIds[idNum], "Checked", propertyValue)
										editor.setPluginValue(pluginName, win.allIds[idNum], "Enabled", true)
									else
										-- HACK: assume this is a text box
										editor.setPluginValue(pluginName, win.allIds[idNum], "Text", propertyValue)
										editor.setPluginValue(pluginName, win.allIds[idNum], "Enabled", true)
									end
								elseif (win.allIdTypes[idNum] == "slider") then
									editor.setPluginValue(pluginName, win.allIds[idNum], "Value", propertyValue)
									editor.setPluginValue(pluginName, win.allIds[idNum], "Enabled", true)
								else
									-- TODO: additional types?
									logger:error("The element \""..win.allIds[idNum].."\" type \""..win.allIdTypes[idNum].."\" is of unsupported for automapping properties.")
									editor.setPluginValue(pluginName, win.allIds[idNum], "Enabled", false)
								end
							else
								logger:error("No property of name \""..propName.."\" exists in the component (parsed from string \""..win.allIds[idNum].."\").")
								editor.setPluginValue(pluginName, win.allIds[idNum], "Enabled", false)
							end
						end
					else
						if (win.allIdTypes[idNum] == "timer" or win.allIdTypes[idNum] == "h1" or win.allIdTypes[idNum] == "label" 
							or win.allIdTypes[idNum] == "hr" or win.allIdTypes[idNum] == "contextmenu") then
							-- ok to ignore these element types
						else
							logger:error("Cannot automap element to property, the element id is not in the format: namespace.ComponentClass.PropertyName")
						end
					end
				end
			else
				-- disable all ids that are listening to this component - as the component does not exist for the selected entity
				for idNum=1,#win.allIds do
					local componentSeek,propName = editor.Plugin.getComponentTypeByName(win.allIds[idNum], true)
					if (componentSeek ~= nil) then
						if (componentSeek == compType) then
							editor.setPluginValue(pluginName, win.allIds[idNum], "Enabled", false)
						end
					end
				end
			end
		end		
	else
		editor.setPluginValue(pluginName, "_self", "Enabled", false)
		editor.setPluginValue(pluginName, "timer", "Enabled", false)
	end
end

_G.editor.pinPluginAutoMappedProperties = function(win, pinMenuItem)
	assert_table(win)
	assert_string(pinMenuItem)
	
	editor.pinPluginWindow(win, pinMenuItem)
end

_G.editor.setAutoMappedValue = function(pluginName, id, value)
	local win = plugin[pluginName]
	if (win.shownEntityUH) then
		local entObj = scene:getSceneInstanceManager():getInstanceByUH(win.shownEntityUH)
		if (entObj == nil) then
			return
		end
		
		local componentSeek,propName = editor.Plugin.getComponentTypeByName(id, true)
		if (componentSeek ~= nil) then
			local componentObject = entObj:findComponent(componentSeek);		
			editor.setComponentPropertyToValue(componentObject, propName, value)
		end
	end
end


_G.editor.propertyAutoMapPluginFunctions = function(pluginName, listenToComponents)	
	local win = { }
	plugin[pluginName] = win
	
	win.toggleKeepOnTop = function(menuItemId) 
		editor.toggleKeepOnTop(win, menuItemId)
	end		
	win.pin = function(menuItemId) 
		editor.pinPluginAutoMappedProperties(win, menuItemId)
	end				
	win.tick = function() 
		win.myUpdate()
	end
	win.load = function(allIds, allIdTypes) 
		editor.listenToAutoMappedProperties(win, allIds, allIdTypes, listenToComponents, win.myListenedSelection, win.myListenedUnselection, false)		
		win.myUpdate()
	end		
	win.myListenedSelection = function() 
		editor.autoMapPluginPropertiesSelection(win)
		win.myUpdate()
	end
	win.myListenedUnselection = function() 
		editor.autoMapPluginPropertiesUnselection(win)
	end		
	win.myUpdate = function()
		editor.autoMapPluginPropertiesUpdate(win)
	end
end
