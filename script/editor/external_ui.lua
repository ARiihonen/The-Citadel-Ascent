module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

require "editor.Util"
require "editor.Editor"
require "misc.AutoComplete"
require "editor.legacy_import"
require "mission.MissionChangeUtil"
require "gameplay.MusicUtil"
require "editor.LocaleAuthoring"
require "editor.BoneList"
require "editor.RagdollBoneList"

local thisModule = _M

---------------------------------------------------------------------------------------------
-- Memory limits

declareManualReload(thisModule, [[resourceUsageLimits]])
declareManualReload(thisModule, [[mb]])
declareReload(thisModule, [[selectionChangeListeners]])
declareReload(thisModule, [[selectedObjectsForParenting]])

selectionChangeListeners = {}

-- HACK: Trine 2 specific limits here
declareManualReload(thisModule, [[totalMemoryLimitPerLevelForArtistsPC]])
declareManualReload(thisModule, [[totalMemoryLimitPerLevelForArtistsPS3]])
declareManualReload(thisModule, [[totalMemoryLimitPerLevelForArtistsXbox360]])
declareManualReload(thisModule, [[totalMemoryLimitPerLevelForArtistsWiiU]])
totalMemoryLimitPerLevelForArtistsPC = 250;
totalMemoryLimitPerLevelForArtistsPS3 = 150;
totalMemoryLimitPerLevelForArtistsXbox360 = 150;
totalMemoryLimitPerLevelForArtistsWiiU = 200;
	
mb = 1024*1024

-- TODO: These are some very old limits done ages ago? Should re-evaluate and check the total memory counting (are those even correct values)
resourceUsageLimits = {		
	startOfList = 0	
	
	, totalMainMemoryUsage = 80 * mb
	, totalGraphicsMemoryUsage = 80 * mb
	, totalResourcesLoaded = 5000
	
	, animationMainMemoryUsage = 30 * mb
	, animationTreeMainMemoryUsage = 10 * mb
	, bonesMainMemoryUsage = 10 * mb
	, collisionMainMemoryUsage = 10 * mb
	, filterMainMemoryUsage = 1 * mb
	, luaMainMemoryUsage = 5 * mb
	, physicsMeshMainMemoryUsage = 5 * mb
	, ragdollMainMemoryUsage = 1 * mb
	, modelMainMemoryUsage = 20 * mb

	, fontGraphicsMemoryUsage = 1 * mb
	, shaderGraphicsMemoryUsage = 1 * mb
	, modelGraphicsMemoryUsage = 20 * mb
	, textureGraphicsMemoryUsage = 20 * mb
	
}

---------------------------------------------------------------------------------------------

-- it does not really matter if there get nil'led. they should always get cleared and reset for every call using them.
declareManualReload(thisModule, [[listOfInputEditorIds]])
declareManualReload(thisModule, [[listOfOutputEditorIds]])
declareManualReload(thisModule, [[haveSentErrorSendingError]])
declareManualReload(thisModule, [[sendingLogMessageToExternalUI]])
declareReload(thisModule, [[eventListenerFunction]])
declareReload(thisModule, [[loggerListenerFunction]])
declareReload(thisModule, [[timerListenerFunction]])

eventListenerFunction = nil
loggerListenerFunction = nil
timerListenerFunction = nil

local stickToCameraEnabled = nil
local selectedCameraAreas = {}
local lastViewedCamera = nil

-- For reloadScripts()
function reloadInit()
-- Though it might be desirable to call uninit and init during reload, we don't actually want to
-- do that in scene Lua. Scene Lua is not uninitialized properly, so it will leave logger and other
-- listeners dangling, if it ever gets initialized. On the other hand, we have to keep original
-- listener functions at hand and use them during uninitialization. In practice this means that if
-- listener function are changed, they will be reloaded along the other functions, but new versions
-- won't be passed to actual listeners.
--[[
	if reloadSafe.moduleSafe.ExternalUI then
		eventListenerFunction = reloadSafe.moduleSafe.ExternalUI.eventListenerFunction
		loggerListenerFunction = reloadSafe.moduleSafe.ExternalUI.loggerListenerFunction
		timerListenerFunction = reloadSafe.moduleSafe.ExternalUI.timerListenerFunction
	end
]]--
end


function reloadUninit()
--[[
	reloadSafe.moduleSafe.ExternalUI = { }
	reloadSafe.moduleSafe.ExternalUI.eventListenerFunction = eventListenerFunction
	reloadSafe.moduleSafe.ExternalUI.loggerListenerFunction = loggerListenerFunction
	reloadSafe.moduleSafe.ExternalUI.timerListenerFunction = timerListenerFunction
]]--
end


function initExternalUI()
	eventListenerFunction = receivedUIEvent
	loggerListenerFunction = externalUILoggerListener
	timerListenerFunction = update_error_list_hack
	externalUI:addUIEventListener(eventListenerFunction)
	logger:addLoggerListener(loggerListenerFunction)
	timer:addTimerListener(timerListenerFunction, 500)
end


function uninitExternalUI()
	externalUI:removeUIEventListener(eventListenerFunction)
	logger:removeLoggerListener(loggerListenerFunction)
	timer:removeTimerListener(timerListenerFunction)
	eventListenerFunction = nil
	loggerListenerFunction = nil
	timerListenerFunction = nil
end


-- Hack to to be able to query data from C#
local g_queriesFromCSharp = {};
local g_freeQueriesFromCSharp = {};

function createCSharpQuery(handler, data)
	local entry = { data = data, handler = handler };

	if #g_freeQueriesFromCSharp > 0 then
		local id = table.remove(g_freeQueriesFromCSharp);
		g_queriesFromCSharp[id] = entry;
		return id;
	else
		table.insert(g_queriesFromCSharp, entry);
		return #g_queriesFromCSharp;
	end
end

function deleteCSharpQuery(id)
	g_queriesFromCSharp[id] = nil;
	table.insert(g_freeQueriesFromCSharp, id);
end

function respondToQuery(id, data)
	local entry = g_queriesFromCSharp[id];
	entry.handler(unpack(entry.data), unpack(data));
	deleteCSharpQuery(id);
end


function undoTypeComponentAdd(pType, pComp)
	local function onReverse(self)
		local typ  = typeManager:findTypeByGUID(self:get("type"));
		local comp = typeManager:findTypeByGUID(self:get("comp"));
		typ:removeComponentType(comp:getUnifiedHandle());
		return true;
	end

	local function onOperate(self)
		local typ  = typeManager:findTypeByGUID(self:get("type"));
		local comp = typeManager:findTypeByGUID(self:get("comp"));
		typ:addComponentType(comp:getUnifiedHandle());
		return true;
	end

	local oper = createCustomLuaOperation(onReverse, onOperate, function() return true; end);
	oper:set("type", pType:getGUID());
	oper:set("comp", pComp:getGUID());
	return oper;
end

function undoTypeComponentRemove(pType, pComp)
	local function onReverse(self)
		local typ  = typeManager:findTypeByGUID(self:get("type"));
		local comp = typeManager:findTypeByGUID(self:get("comp"));
		typ:addComponentType(comp:getUnifiedHandle());
		return true;
	end

	local function onOperate(self)
		local typ  = typeManager:findTypeByGUID(self:get("type"));
		local comp = typeManager:findTypeByGUID(self:get("comp"));
		typ:removeComponentType(comp:getUnifiedHandle());
		return true;
	end

	local oper = createCustomLuaOperation(onReverse, onOperate, function() return true; end);
	oper:set("type", pType:getGUID());
	oper:set("comp", pComp:getGUID());
	return oper;
end


-- same as the bounceCommand on editor UI side but to the other way.
--
function bounceCommand(str)
	assert_string(str)

	externalUI:sendUICommand(str)
end

function editorTestCheck()
	if (externalUI:getRunTest()) then
		if (externalUI:getTestData() == "") then
			logger:error("Cannot run editor tests without specifying test data file.");
		else
			logger:info("Sending UI command to start the editor test...");
			local escaped = editor.Util.escapeQuotesAndBackslashes(externalUI:getTestData());
			externalUI:sendUICommand("runEditorTest(\""..escaped.."\")")
		end
	end	
end


function syncInstanceGraphRoot()
	if state.isEditorSyncEnabled and (not state:isEditorSyncEnabled()) then return end
	local listenerId = "SceneExplorer"
	local instanceGraphRoot = editor.Editor.getInstanceTreeForExternalUI(1)
	clearSyncDataListener(listenerId)
	externalUI:sendUICommand("sync(\""..listenerId.."\", \""..instanceGraphRoot.."\")")
end


function syncModuleTreeRoot(listenerId)
	assert_string(listenerId)
	
	if state.isEditorSyncEnabled and (not state:isEditorSyncEnabled()) then return end
	local ret = editor.Editor.getModuleTreeForExternalUI(1, filteringModule:getModuleTreeFilterString())
	clearSyncDataListener(listenerId)
	externalUI:sendUICommand("sync(\""..listenerId.."\", \""..ret.."\")")
end

function syncGUITreeRoot(listenerId)
	assert_string(listenerId)
	
	if state.isEditorSyncEnabled and (not state:isEditorSyncEnabled()) then return end
	-- unimplemented
	--local ret = editor.Editor.getGUITreeForExternalUI(1, filteringModule:getGUITreeFilterString())
	local ret = editor.Editor.getGUITreeForExternalUI(50, "0,All")
	if ret == nil then
		return
	end
	
	clearSyncDataListener(listenerId)
	externalUI:sendUICommand("sync(\""..listenerId.."\", \""..ret.."\")")
end

----------------------------------------------------------------------------------------------------------

function syncGUI3TreeRootWithDelay(listenerId)
	state:runLuaFuncWithDelay(100, function() syncGUI3TreeRoot(listenerId) end)
end

function syncGUI3TreeRoot(listenerId)
	assert_string(listenerId)
	if state.isEditorSyncEnabled and (not state:isEditorSyncEnabled()) then return end
	
	local ret = editor.Editor.getGUI3TreeForExternalUI(50, "0,All")
	clearSyncDataListener(listenerId)
	externalUI:sendUICommand("sync(\""..listenerId.."\", \""..ret.."\")")
end

function getGUI3RightClickMenuTypes(parentTypeName, listenerId)
	assert_string(parentTypeName)
	local parentType = typeManager:findTypeByName(parentTypeName)
	if not parentType then
		logger:error("Type with name " .. parentTypeName .. " not found.")
		return
	end
	-- If getChooseObjectTreeForExternalUI's return values change to human-readable things might break.
	-- Or if the linebreaks are stripped from non-human-readble... That'll definitely break things.
	local subTree = editor.Editor.getChooseObjectTreeForExternalUI(100, parentType, filteringModule:getTypeFilterString());
	externalUI:sendUICommand("sync(\""..listenerId.."\", \"rightClickSubTreeTypes ".. subTree .."\")")
end

function getGUI3RightClickMenuPrefabs(listenerId)
	local prefabs = editor.Editor.getGUI3PrefabList()
	externalUI:sendUICommand("sync(\""..listenerId.."\", \"rightClickSubTreePrefabs ".. prefabs .."\")")
end

function addChildToGUI3Widget(parentId, widgetTypeName)
	assert_string(parentId)
	assert_string(widgetTypeName)
	local obj = getObjectByEditorObjectId(parentId);
	if obj then
		editor.Editor.addChildToGUI3Widget(obj, widgetTypeName)
	end
end

function addChildToGUI3WidgetFromPrefab(parentId, widgetTypeName)
	assert_string(parentId)
	assert_string(widgetTypeName)
	local parent = getObjectByEditorObjectId(parentId);
	if parent then
		editor.Editor.addChildToGUI3WidgetFromPrefab(parent, widgetTypeName)
	else
		logger:error("Parent not found: " .. parentId)
	end
end

function removeGUI3Widget(selfId)
	assert_string(selfId)
	local obj = getObjectByEditorObjectId(selfId);
	if obj then
		editor.Editor.removeGUI3Widget(obj)
	end
end

function remakeGUI3Widget(selfId)
	assert_string(selfId)
	local obj = getObjectByEditorObjectId(selfId);
	if obj then
		editor.Editor.remakeGUI3Widget(obj)
	end
end

function addGUI3Window(selfId)
	assert_string(selfId)
	local obj = getObjectByEditorObjectId(selfId);
	if obj then
		editor.Editor.addGUI3Window(obj)
	end
end

function dragAndDropGUI3Widget(selfId, targetParentId)
	assert_string(selfId)
	local obj = getObjectByEditorObjectId(selfId);
	local parent = getObjectByEditorObjectId(targetParentId);
	if obj and parent then
		editor.Editor.dragAndDropGUI3Widget(obj, parent)
	end
end

function saveGUI3WidgetAsPrefab(selfId)
	assert_string(selfId)
	local obj = getObjectByEditorObjectId(selfId)
	if obj then
		editor.Editor.saveGUI3WidgetAsPrefab(obj)
	end
end


function startSavingGUI3WidgetAsType(guid)
	local obj = getObjectByGUID(guid)
	
	if not editor.Editor.canGUI3WidgetBeInherited(obj) then return end
	
	if obj then
		editor.Editor.prepareGUI3WidgetToBeSavedAsType(obj)
	else
		logger:error("Failed to fetch object with getObjectByGUID(" .. guid .. ").")
		sendGameLogMessageToExternalUI("Failed to inherit gui widget type.", 1)
		return;
	end
	
	startInheritingTypeFromInstance(guid)
end

function applyGUI3InstancePropertiesToType(guid)
	local instance = getInstanceByGUID(guid)
	if not instance then return; end
	if not rootWidget then logger:error("applyGUI3InstancePropertiesToType - rootWidget is NIL") return end
	rootWidget:applyPropertiesToType(instance)
end

function toggleGUI3PersistentGUIInTree()
	if not rootWidget then return end
	rootWidget:togglePersistentGUIInTree()
end

function toggleGUI3DebugInfo()
	if not rootWidget then return end
	rootWidget:toggleDebugInfo()
end

----------------------------------------------------------------------------------------------------------

function syncTypeGraphRoot(numOpt)
	if state.isEditorSyncEnabled and (not state:isEditorSyncEnabled()) then return end
	local listenerId = "TypeExplorer"
	if (numOpt) then
		listenerId = listenerId .. tostring(numOpt)
	end
	local typeGraphRoot = editor.Editor.getTypeTreeForExternalUI(1)
	clearSyncDataListener(listenerId)
	externalUI:sendUICommand("sync(\""..listenerId.."\", \""..typeGraphRoot.."\")")
end


function syncResourceGraphRoot()
	if state.isEditorSyncEnabled and not state:isEditorSyncEnabled() then return end
	local listenerId = "ResourceExplorer"
	local resourceGraphRoot = editor.Editor.getResourceTreeForExternalUI(1)
	clearSyncDataListener(listenerId)
	externalUI:sendUICommand("sync(\""..listenerId.."\", \""..resourceGraphRoot.."\")")
end

----------------------------------------------------------------------------------------------------------

function setDebugVisualizationSelfIlluminationForAllInstancesEnabledImpl(enabled)
	assert_boolean(enabled)

	if state ~= nil and state:getScenesLoaded() then	
		setDebugVisualizationPropertyForAllInstances("SelfIlluminationEnabled", enabled);
	end
end

function setDebugVisualizationWidgetForAllInstancesEnabledImpl(enabled)
	assert_boolean(enabled)
	
	if state ~= nil and state:getScenesLoaded() then	
		setDebugVisualizationPropertyForAllInstances("WidgetEnabled", enabled);
	end
end

function setDebugVisualizationTextForAllInstancesEnabledImpl(enabled)
	assert_boolean(enabled)

	if state ~= nil and state:getScenesLoaded() then	
		setDebugVisualizationPropertyForAllInstances("DebugTextEnabled", enabled);
	end
end

function setDebugVisualizationIconForAllInstancesEnabledImpl(enabled)
	assert_boolean(enabled)
	
	if state ~= nil and state:getScenesLoaded() then	
		setDebugVisualizationPropertyForAllInstances("IconEnabled", enabled);
	end
end

function setDebugVisualizationHighlightForAllInstancesEnabledImpl(enabled)
	assert_boolean(enabled)

	if state ~= nil and state:getScenesLoaded() then	
		setDebugVisualizationPropertyForAllInstances("HighlightEnabled", enabled);
	end
end

function setDebugVisualizationLinksForAllInstancesEnabledImpl(enabled)
	assert_boolean(enabled)
	
	if state ~= nil and state:getScenesLoaded() then	
		setDebugVisualizationPropertyForAllInstances("LinksEnabled", enabled);
	end
end

----------------------------------------------------------------------------------------------------------

-- note, the UI calls this before setFilter (at least if the search string has changed).
function setSearchString(listenerId, searchString)
	assert_string(listenerId)
	assert_string(searchString)
	
	if listenerId == "SceneExplorer" then
		filteringModule:setInstanceSearchString(searchString)
	elseif listenerId == "TypeExplorer" then
		filteringModule:setTypeSearchString(searchString)
	elseif listenerId == "ResourceExplorer" then
		filteringModule:setResourceSearchString(searchString)
	elseif listenerId == "ChooseObjectDialog" then
		filteringModule:setChooseObjectDialogSearchString(searchString)
	elseif listenerId == "AddComponentTypeDialog" then
		filteringModule:setAddComponentTypeDialogSearchString(searchString);
	end
end


function setFilter(listenerId, filterString, noApply)
	assert_string(listenerId)
	assert_string(filterString)
	assert_boolean_or_nil(noApply)

	if listenerId == "SceneExplorer" then
		editor.Editor.setInstanceTreeFilter(filterString)
		if not noApply then syncInstanceGraphRoot() end
	elseif listenerId == "TypeExplorer" then
		editor.Editor.setTypeTreeFilter(filterString)
		if not noApply then syncTypeGraphRoot() end
	elseif listenerId == "TypeExplorer2" then
		editor.Editor.setTypeTreeFilter(filterString)
		if not noApply then syncTypeGraphRoot(2) end
	elseif listenerId == "TypeExplorer3" then
		editor.Editor.setTypeTreeFilter(filterString)
		if not noApply then syncTypeGraphRoot(3) end
	elseif listenerId == "TypeExplorer4" then
		editor.Editor.setTypeTreeFilter(filterString)
		if not noApply then syncTypeGraphRoot(4) end
	elseif listenerId == "ResourceExplorer" then
		editor.Editor.setResourceTreeFilter(filterString)
		if not noApply then syncResourceGraphRoot() end
	elseif listenerId == "ChooseObjectDialog" then
		editor.Editor.setChooseObjectDialogFilter(filterString)
	elseif (listenerId == "AddComponentTypeDialog") then
		filteringModule:setAddComponentTypeDialogFilterString(filterString)
	elseif listenerId == "Selection" then
		filteringModule:setSelectionFilterString(filterString)
		if not noApply and state.applyEditorFilters then state:applyEditorFilters() end
	elseif listenerId == "Visibility" then
		filteringModule:setVisibilityFilterString(filterString)
		if not noApply and state.applyEditorFilters then state:applyEditorFilters() end
	elseif listenerId == "DebugVisualize" then
		filteringModule:setDebugVisualizeFilterString(filterString)
		if not noApply and state.applyEditorFilters then state:applyEditorFilters() end
	elseif (listenerId == "RecentObjectExplorer") then
		filteringModule:setRecentFilterString(filterString);
		if not noApply then syncRecentObjectRoot("RecentObjectExplorer") end
	elseif (listenerId == "ModuleExplorer") then
		filteringModule:setModuleTreeFilterString(filterString);
	elseif (listenerId == "GUIExplorer") then
		-- unimplemented
		--filteringModule:setGUITreeFilterString(filterString);
	else
		logger:error("Unidentified filter listener id.")
	end
end

function getFilter(listenerId)
	assert_string(listenerId)
	
	local filterString = ""
	if listenerId == "SceneExplorer" then
		filterString = filteringModule:getInstanceFilterString()
	elseif listenerId == "TypeExplorer" then
		filterString = filteringModule:getTypeFilterString()
	elseif listenerId == "TypeExplorer2" then
		filterString = filteringModule:getTypeFilterString()
	elseif listenerId == "TypeExplorer3" then
		filterString = filteringModule:getTypeFilterString()
	elseif listenerId == "TypeExplorer4" then
		filterString = filteringModule:getTypeFilterString()
	elseif listenerId == "ResourceExplorer" then
		filterString = filteringModule:getResourceFilterString()
	elseif listenerId == "Selection" then
		filterString = filteringModule:getSelectionFilterString()
	elseif listenerId == "Visibility" then
		filterString = filteringModule:getVisibilityFilterString()
	elseif listenerId == "DebugVisualize" then
		filterString = filteringModule:getDebugVisualizeFilterString()
	elseif listenerId == "RecentObjectExplorer" then
		filterString = filteringModule:getRecentFilterString()
	elseif (listenerId == "ChooseObjectDialog") then
		filterString = filteringModule:getChooseObjectDialogFilterString();
	elseif (listenerId == "AddComponentTypeDialog") then
		filterString = filteringModule:getAddComponentTypeDialogFilterString();
	elseif (listenerId == "ModuleExplorer") then
		filterString = filteringModule:getModuleTreeFilterString();
	elseif (listenerId == "GUIExplorer") then
		-- unimplemented
		filterString = "0,All";
	elseif (listenerId == "ObjectExplorer") then
		filterString = "0,All";
	else
		logger:error("Unidentified filter listener id.")	
	end
	return filterString;
end


function getFilterToEditor(listenerId, responseCommand)
	assert_string(listenerId)
	assert_string(responseCommand)
	
	externalUI:sendUICommand(responseCommand .. "(\"" .. getFilter(listenerId) .. "\")");
end


-- use this to clear any of the data trees in the editor UI, rather than doing it directly...
-- this way it goes through the same interface as data updates (so they remain in sync)
function clearSyncDataListener(listenerId)
	assert_string(listenerId)
	
	externalUI:sendUICommand("clearSyncDataListener(\"" .. listenerId .. "\")");
end


function sendValidateErrorList()
	updateErrorList();
	-- ping pong for delayed execution.
	externalUI:sendUICommand("bounceCommand(\"editor.ExternalUI.bounceCommand(\\\"validateErrorListSent()\\\")\")");
end


function dumpErrorList()
	local str = errorModule:createErrorDump(editor.Editor.getReadableGUIDString);
	clearSyncDataListener("ErrorList");
	externalUI:sendUICommand("sync(\"ErrorList\", \""..str.."\")");
end


function updateErrorList()
	-- Note, this is not the most optimal solution really...
	-- it should be possible to update the error list partially, currently this always
	-- either dumps the entire error list or nothing at all.
	if (not(errorModule:isErrorDumpUpToDate(editor.Editor.getReadableGUIDString))) then
		dumpErrorList()
	end
end


function addDebugStatsBreakpoint(scope, varname, value, condmask, condoperator)
	assert_string(scope)
	assert_string(varname)
	assert_string(value)
	assert_string(condmask)
	assert_string(condoperator)
	
	debugStatsModule:addDebugStatsBreakpoint(scope, varname, value, condmask, condoperator)
	dumpDebugStats()
end


function removeDebugStatsBreakpoint(scope, varname)
	assert_string(scope)
	assert_string(varname)
	
	debugStatsModule:removeDebugStatsBreakpoint(scope, varname)
	dumpDebugStats()
end


function dumpDebugStats()
	local str = debugStatsModule:createDebugStatsDumpString();
	clearSyncDataListener("DebugStatsExplorer");
	externalUI:sendUICommand("sync(\"DebugStatsExplorer\", \""..str.."\")");
end


function dumpProfiler()
	local str = profilerModule:createProfilerDumpString();
	clearSyncDataListener("ProfilerDumpExplorer");
	externalUI:sendUICommand("sync(\"ProfilerDumpExplorer\", \""..str.."\")");
end


function resetProfiler()
	profilerModule:resetProfiler();
	dumpProfiler()
end


function update_error_list_hack()
	editor.ExternalUI.updateErrorList()
end


-- splitting the log message half to "Object::method - message"
function splitLogMessage(msg)
	local ret = {};
	-- FIXME: this is totally incorrect. it should check for spaces around the -
	for msgPart in msg:gmatch("[^\-]*") do
		if msgPart ~= "" then
			table.insert(ret, msgPart);
		end
	end
	return ret;
end


sendingLogMessageToExternalUI = false;
haveSentErrorSendingError = false;

function externalUILoggerListener(msg, level)
	assert_string(msg)
	assert_number(level)
	
	-- if(level == 1)
	-- then
		-- change errors to warnings
	-- 	level = 2;
	-- end
	sendGameLogMessageToExternalUI(msg, level, true)
end


function sendGameLogMessageToExternalUI(msg, level, doOnlyGameLogMessage)
	assert_string(msg)
	assert_number(level)

	if(not errorModule:getErrorDumpEnabled()) then
		return
	end
	
	-- make sure we don't recursively keep sending errors about sending errors
	if (sendingLogMessageToExternalUI) then
		-- oh noes, error sending did an error, so give an error about that once...
		if (not(haveSentErrorSendingError)) then
			haveSentErrorSendingError = true
			logger:error("external_ui.sendGameLogMessageToExternalUI - Attempt to send an log message to UI caused another log message to be send. Suppressing any such messages to prevent infinite recursion.");
		end
		return
	end

	sendingLogMessageToExternalUI = true;

	-- need to escape " and \ (to \" and \\)
	msg = editor.Util.escapeQuotesAndBackslashes(msg);

	local splitted = splitLogMessage(msg)
	local caption = "";
	local msgPart = msg;
	if (#splitted > 1) then
		caption = splitted[1];
		msgPart = splitted[2];
		for i = 3,#splitted do
			msgPart = msgPart .. "-" .. splitted[i];
		end
	end

	if (level == 1) then
		externalUI:sendUICommand("gameLogMessage(\"" .. msgPart .. "\", \""..caption.."\", \"Error\")")
	elseif (level == 2) then
		externalUI:sendUICommand("gameLogMessage(\"" .. msgPart .. "\", \""..caption.."\", \"Warning\")")
	elseif (level == 3) then
		externalUI:sendUICommand("gameLogMessage(\"" .. msgPart .. "\", \""..caption.."\", \"Info\")")
	elseif (level == 4) then
		externalUI:sendUICommand("gameLogMessage(\"" .. msgPart .. "\", \""..caption.."\", \"Debug\")")
	else
		externalUI:sendUICommand("gameLogMessage(\"" .. msgPart .. "\", \""..caption.." (UNKNOWN ERROR LEVEL)\", \"Error\")")
	end

	if not doOnlyGameLogMessage then
		if (level == 1) then
			externalUI:sendUICommand("messageBox(\"" .. msgPart .. "\", \""..caption.."\", \"Error\")")
		elseif (level == 2) then
			externalUI:sendUICommand("messageBox(\"" .. msgPart .. "\", \""..caption.."\", \"Warning\")")
		elseif (level == 3) then
			externalUI:sendUICommand("messageBox(\"" .. msgPart .. "\", \""..caption.."\", \"Info\")")
		elseif (level == 4) then
			externalUI:sendUICommand("messageBox(\"" .. msgPart .. "\", \""..caption.."\", \"Debug\")")
		else
			externalUI:sendUICommand("messageBox(\"" .. msgPart .. "\", \""..caption.." (UNKNOWN ERROR LEVEL)\", \"Error\")")
		end
	end

	sendingLogMessageToExternalUI = false;
end


function syncComponentTypeGraphRoot(editorListenerTag)
	assert_string(editorListenerTag)

	local typ = typeManager:findTypeByName("ComponentBase");
	syncObject(editorListenerTag, typ);
end


function syncObjectGraphRoot(editorListenerTag)
	assert_string(editorListenerTag)
	
	if(state.isEditorSyncEnabled and (not state:isEditorSyncEnabled())) then return end
	-- Hopefully, the scene/type/resource explorers don't call this.
	-- if they do, this needs to be optimized so that it only sends the relevant data...
	-- (now it collects all of the trees to be sent out!)
	--logger:warning("syncObjectGraphRoot deprecated.")
	-- too lazy to fix this right now. :)

	local typeGraphRoot = editor.Editor.getTypeTreeForExternalUI(1);
	local instanceGraphRoot = editor.Editor.getInstanceTreeForExternalUI(1);
	local resourceGraphRoot = editor.Editor.getResourceTreeForExternalUI(1);
	externalUI:sendUICommand("sync(\""..editorListenerTag.."\", \""..typeGraphRoot..instanceGraphRoot..resourceGraphRoot.."\")");
end

function syncChooseObjectGraphRoot(editorListenerTag, propertyFlags)
	assert_string(editorListenerTag)
	assert_string(propertyFlags)
	
	if(state.isEditorSyncEnabled and (not state:isEditorSyncEnabled())) then return end
	local root = instanceManager:getTopmostInstanceRoot();
	local filterString = filteringModule:getChooseObjectDialogFilterString();
	
	if(string.find(propertyFlags, "EditorHint_Type_Type"))
	then
		root = typeManager:getTypeRoot();
	end
	
	if(string.find(propertyFlags, "EditorHint_Type_Resource"))
	then
		root = resourceManager:getResourceRoot();	
	end

	local mustInheritString = "EditorHint_MustInherit_";
	local mustInheritStringLength = mustInheritString:len();
	local s, e = string.find(propertyFlags, mustInheritString.."[%w]+");
	if(e and (e-s) > mustInheritStringLength)
	then
		local className = string.sub(propertyFlags, s+mustInheritStringLength, e);
		filteringModule:setChooseObjectDialogClassString(className)
	else
		filteringModule:setChooseObjectDialogClassString("")
	end
	
	local str = editor.Editor.getChooseObjectTreeForExternalUI(1, root, filterString);
	externalUI:sendUICommand("sync(\""..editorListenerTag.."\", \""..str.."\")");
end

function syncRecentObjectRoot(editorListenerTag)
	assert_string(editorListenerTag)
	
	if(state.isEditorSyncEnabled and (not state:isEditorSyncEnabled())) then return end
	local recentGraphRoot = editor.Editor.getRecentObjectTreeForExternalUI();
	externalUI:sendUICommand("sync(\""..editorListenerTag.."\", \""..recentGraphRoot.."\")");
end


function syncFilteredRecentObjectRoot(editorListenerTag, baseClass)
	assert_string(editorListenerTag)
	--assert_class_class(baseClass) :P
	
	if(state.isEditorSyncEnabled and (not state:isEditorSyncEnabled())) then return end
	local recentGraphRoot = editor.Editor.getRecentObjectTreeForExternalUI(baseClass);
	externalUI:sendUICommand("sync(\""..editorListenerTag.."\", \""..recentGraphRoot.."\")");
end


function syncRecentComponentTypes(editorListenerTag)
	assert_string(editorListenerTag)
	
	if(state.isEditorSyncEnabled and (not state:isEditorSyncEnabled())) then return end
	local recentGraphRoot = editor.Editor.getRecentObjectTreeForExternalUI("TypeBase", "ComponentBase");
	externalUI:sendUICommand("sync(\""..editorListenerTag.."\", \""..recentGraphRoot.."\")");
end


function addRecentObjectImpl(obj)
	assert_treenode(obj)

	if(obj:isInherited(engine.base.InstanceBase.getStaticObjectClass())) then
		if (state.addRecentGUID and state:isAddRecentInstanceAsInstance()) then
			state:addRecentGUID(obj:getGuid());
		end
		if (state:isAddRecentInstanceAsType()) then
			local typeUH = obj:getType()
			if (typeUH ~= UH_NONE) then
				typeObj = typeManager:getTypeByUH(typeUH)
				if (typeObj and state.addRecentGUID) then
					state:addRecentGUID(typeObj:getGuid());
				end
			end
		end
	else
		if state.addRecentGUID then
			state:addRecentGUID(obj:getGuid());
		end
	end
end


function addRecentObject(editorObjectId)
	assert_string(editorObjectId)
	
	if state.addRecentGUID then
		local obj = getObjectByEditorObjectId(editorObjectId);
		if obj then
			addRecentObjectImpl(obj)
		end
	end
end


function sceneObjectContextHitted(editorObjectId)
	assert_string(editorObjectId)
	
	externalUI:sendUICommand("contextHit(\"@object\", \"" .. editorObjectId .. "\")")
end


function sceneObjectsSelected(editorObjectIdList)
	assert_string(editorObjectIdList)
	
	externalUI:sendUICommand("setUIValue(\"@selectedObjectsList\", \""..editorObjectIdList.."\")");
end


-- this syncs the data of a single object to the external editor UI
-- this should normally be called by the automatic editor syncer components whenever the object changes
-- (assuming that the syncer component is added properly, see below for functions for that)
function syncObject(editorListenerTag, obj)
	assert_string(editorListenerTag)
	assert_treenode(obj)

	if(state.isEditorSyncEnabled and (not state:isEditorSyncEnabled())) then return end
	local objectTree = editor.Editor.getObjectTreeForExternalUI(obj, 1, 1, 1, getFilter(editorListenerTag));
	if not(objectTree == "\r\n")
	then
		externalUI:sendUICommand("sync(\""..editorListenerTag.."\", \""..objectTree.."\")");
	end
end


function syncObjects(editorListenerTag, objs)
	assert_string(editorListenerTag)
	assert_table(objs)
	
	if(state.isEditorSyncEnabled and (not state:isEditorSyncEnabled())) then return end
	
	local filterString = getFilter(editorListenerTag)
	local ret = {}
	for i,obj in ipairs(objs)
	do
		editor.Editor.appendObjectTreeForExternalUI(ret, obj, 1, 1, 1, filterString);
	end
	local objectTree = editor.Editor.dumpTableToString(ret, false);

	externalUI:sendUICommand("sync(\""..editorListenerTag.."\", \""..objectTree.."\")");
end

function getInstanceByGUID(guid)
	-- assert_guid(guid)
	
	local instance = nil;
	if scene then
		if scene then
			instance = scene:getSceneInstanceManager():findInstanceByGUID(guid);
		else
			logger:error("getInstanceByGUID - scene is nil.");
		end
	else
		if gameScene then
			instance = gameScene:getSceneInstanceManager():findInstanceByGUID(guid);
		else
			logger:error("getInstanceByGUID - gameScene is nil.");
		end
	end
	
	if instance then
		if instance:isInherited(engine.base.InstanceBase.getStaticObjectClass()) then
			return instance;
		end
	end
	return nil;	
end

function getTypeByUH(uh)
	-- assert_uh(uh)

	if typeManager then
		return typeManager:getTypeByUH(uh);
	else
		return nil;
	end
end

function getObjectByGUID(guid)
	-- assert_guid(guid)
	
	if guid then
		local ret = nil;

		if guid == GUID_NONE then
			return nil;
		end

		-- try to find a type for the guid
		ret = typeManager:findTypeByGUID(guid);
		-- try to find a resource for the guid
		if not ret then
			ret = resourceManager:findResourceByGUID(guid);
		end
		-- try to find an instance for the guid
		if not ret then
			if scene then
				ret = scene:getSceneInstanceManager():findInstanceByGUID(guid);
			else
				-- FIXME: need a proper scene instance manager, hacked this version for now.
				ret = gameScene:getSceneInstanceManager():findInstanceByGUID(guid);
			end
		end
		-- find module
		if not ret then
			ret = moduleTreeManager:findModuleTreeObjectByGUID(guid, state);
		end
		-- find gui object
		if not ret and guiRoot then
			ret = guiRoot:findWidgetByGUID(guid);
		end
		-- find gui <3 object
		if not ret and rootWidget ~= nil then
			ret = rootWidget:findWidgetByGUID(guid);
		end
		if not ret then
			if (not(allowMissingGuid)) then
				logger:warning("external_ui.getObjectByGUID - Failed to find object with " .. tostring(guid));
			end
		end
		return ret;
	else
		logger:error("external_ui.getObjectByGUID - Null guid parameter given.");
		return nil;
	end
end


-- converts the editor object ids ("guid ids") to actual objects.
-- NOTICE: this conversion loses information. The returned object is the "parent" object for that specific
-- guid id (whereas the guid id could be pointing to a specific property or such), see getGuidByEditorObjectId.
function getObjectByEditorObjectId(editorObjectId)
	assert_string(editorObjectId)
	
	local guidStr = getGuidByEditorObjectId(editorObjectId);
	if (not(guidStr)) then
		if (editorObjectId:sub(1, 5) == "GUID(") then			
			--it is handy to use normal guid in some cases. lets not warn.
			--logger:warning("external_ui.getObjectByEditorObjectId - Given editor object id string seemed to be a plain GUID string instead.");
			guidStr = editorObjectId;
		else
			logger:error("external_ui.getObjectByEditorObjectId - Given editor object id string was not a proper editor object id string (nor was it plain GUID). The string was: \"."..editorObjectId.."\"");
			return nil;
		end	
	end
	
	local guid = parseObjectFromStringValue(guidStr);
	if (guid) then
		return getObjectByGUID(guid);
	else
		logger:error("external_ui.getObjectByEditorObjectId - Guid string to guid object parsing failed.");
		return nil;
	end
end


-- converts the editor object ids ("guid ids") to actual guid
-- NOTICE: this conversion loses information, guid id contains more than just the object guid
-- it also contains information that the external editor can use to identify individual properties, etc. of
-- some specific object having the plain guid
function getGuidByEditorObjectId(editorObjectId)
	assert_string(editorObjectId)

	local guid = string.match(editorObjectId, "%[(GUID%([%w%s%,%']*%)).*%]");

	-- if (guid) then
	--	 logger:debug("the guid string for \""..editorObjectId.."\" was \""..guid.."\"");
	-- end

	if (guid) then
		return guid;
	else
		return nil;
	end
end

function findInstanceComponentByTypeUH(instance, typeUH)
	assert_treenode(instance)
	-- assert_uh(typeUH)

	local iter = ComponentVectorIterator(instance:getComponents());
	if not iter:hasInitFailed() then
		local instanceChildComp = iter:next()
		while not (instanceChildComp == nil) do
			if instanceChildComp:getType() == typeUH then
				return instanceChildComp;
			end
			instanceChildComp = iter:next();
		end
	end
	return nil;
end



-- this should be called by the external editor UI wheneven it wants to be automatically notified of some
-- object change. the editorObjectId parameter should be the same parameter that the dump gave to the editor for
-- that specific object. (they are known as the "guidId" tags in the editor, consisting of something like:
-- [GUID(0x12341234,0x12341234,0x12341234,0x12341234),123]
-- the tag format may vary and may not be in this exact format, but in overall, it is usually something that
-- contains the object/component GUID and additional information to identify a specific property/other data of it
-- the editor listener tag is a string that tells which editor window or other component is listening to the
-- object (as there may possibly be several of them) - each of the listener tags are assumed to be unique
-- so that any listener tag may be used on the object only once at any given time
-- (the listener tag is really just a sanity check, a simple ref count would do the same trick but could not
-- detect errors, such as identifying leaks or multiple listeners installed for the same ui component)
function addEditorListenerToObject(editorObjectId, editorListenerTag)
	assert_string(editorObjectId)
	assert_string(editorListenerTag)

	if FB_BUILD == "FB_DEBUG" then
		logger:debug("adding editor listener to editor id: " .. tostring(editorObjectId));
	end

	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj) then
		-- TODO: add the editor syncer component
		-- and also sync data for this specific object immediately
		syncObject(editorListenerTag, obj);
	end
end

function removeEditorListenerFromObject(editorObjectId, editorListenerTag)
	assert_string(editorObjectId)
	assert_string(editorListenerTag)
	
	logger:debug("removing editor listener from editor id: " .. tostring(editorObjectId));

	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj) then
		-- TODO: remove the editor syncer component
		-- and also sync data for this specific object immediately
		syncObject(editorListenerTag, obj);
	end
end


function syncObjectHierarchy(guid, listenerTag)
	-- assert_guid(guid)
	assert_string(listenerTag)
	
	if state.isEditorSyncEnabled and not state:isEditorSyncEnabled() then return end
	local obj = getObjectByGUID(guid);
	if obj then
		local flt = getFilter(listenerTag);
		-- ignore filters
		if(listenerTag == "TypeExplorer" or listenerTag == "ResourceExplorer")
		then
			flt = "0,All";
		end
		local str = editor.Editor.dumpSingleObject(obj, flt);
		externalUI:sendUICommand("sync(\""..listenerTag.."\", \""..str.."\")");
	end
end


function syncObjectPartialProperties(guid, listenerTag, props)
	-- assert_guid(guid)
	assert_string(listenerTag)
	assert_table(props)

	if state.isEditorSyncEnabled and (not state:isEditorSyncEnabled()) then return end
	local obj = getObjectByGUID(guid)
	if obj then
		local str = editor.Editor.dumpSingleObjectPartialProperties(obj, props)
		externalUI:sendUICommand("sync(\""..listenerTag.."\", \""..str.."\")")
	end
end


function sendEventTag(tagId)
	externalUI:sendUICommand("eventTag("..tagId..")")
end


function syncObjectProperties(guid, listenerTags)
	-- assert_guid(guid)
	assert_string(listenerTag)

	if(state.isEditorSyncEnabled and (not state:isEditorSyncEnabled())) then return end
	local obj = getObjectByGUID(guid);
 	if obj then
		for i,v in ipairs(listenerTags) do
			local str = editor.Editor.dumpSingleObject(obj, getFilter(v));
			externalUI:sendUICommand("sync(\""..v.."\", \""..str.."\")");
		end
	end
end


function syncEditorObjects(editorObjectIds, editorListenerTag)
	assert_table(editorObjectIds)
	assert_string(editorListenerTag)
	
	logger:debug("syncing " .. tostring(#editorObjectIds) .. " objects for the listener " .. tostring(editorListenerTag));
	local objs = {}
	for i,v in ipairs(editorObjectIds) do
		local obj = getObjectByEditorObjectId(v);
		if (obj) then
			table.insert(objs, obj);
		end
	end

	if(#objs > 0) then
		syncObjects(editorListenerTag, objs);
	end
end


function syncEditorObject(editorObjectId, editorListenerTag)
	assert_string(editorObjectId)
	assert_string(editorListenerTag)
	
	logger:debug("syncing object with editor id: " .. tostring(editorObjectId) .. " for the listener " .. tostring(editorListenerTag));

	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj) then
		syncObject(editorListenerTag, obj);
	end
end


function objectNameHasChanged(parentEditorObjectId)
	assert_string(parentEditorObjectId)
	
	logger:debug("object name changed for editor id: " .. tostring(parentEditorObjectId));

	-- refresh the object's parent in either typeexplorer or instanceexplorer...
	-- TODO: in reality, should refresh in all the editor windows that have a
	-- representation of the object in question.
	-- ...but only to those, as others won't know where to insert the data
	local obj = getObjectByEditorObjectId(parentEditorObjectId);
	if (obj) then
		-- trying to solve the parent object, (the hard way, and currently the only way?)
		local parentUH = obj:getParentUnifiedHandle()
		local parent = nil
		if (parentUH ~= UH_NONE) then
			if (typeManager:isType(parentUH)) then
				parent = typeManager:getTypeByUH(parentUH)
			elseif (resourceManager:isResource(parentUH)) then
				parent = resourceManager:getResourceByUH(parentUH)
			else
				-- else, it must be an instance? right...?
				parent = obj:getInstanceManager():getInstanceByUH(parentUH)
			end
		end
		if (parent == nil) then
			parent = obj
		end
		if (parent) then
			local uh = parent:getUnifiedHandle();
			local editorListenerTag = "SceneExplorer"
			if (typeManager:isType(uh)) then
				editorListenerTag = "TypeExplorer"
			end
			if (resourceManager:isResource(uh)) then
				editorListenerTag = "ResourceExplorer"
			end
			logger:debug("About to sync to: " .. editorListenerTag);
			logger:debug("With parent GUID: " .. tostring(parent:getGuid()));
			syncObject(editorListenerTag, parent)
		end
	else
		logger:debug("there was no such object.");
	end
end


function convertGUIDToUH(guid)
	-- assert_guid(guid)
	
	if guid == GUID_NONE then
		return UH_NONE;
	end
	local inst = gameScene:getSceneInstanceManager():findInstanceByGUID(guid);
	if inst then
		return inst:getUnifiedHandle();
	end
	local typo = typeManager:findTypeByGUID(guid);
	if typo then
		return typo:getUnifiedHandle();
	end
	local res = resourceManager:findResourceByGUID(guid);
	if res then
		return res:getUnifiedHandle();
	end
	return UH_NONE;
end

function findManagerForGUID(guid)
	if guid then
		local ret = nil;

		if guid == GUID_NONE then
			return nil;
		end

		-- try to find a type for the guid
		if typeManager:findTypeByGUID(guid) then
			return typeManager;
		elseif resourceManager:findResourceByGUID(guid) then
			return resourceManager;
		elseif scene:getInstanceManager():findInstanceByGUID(guid) then
			return scene:getInstanceManager()
		elseif scene:getSceneInstanceManager():findInstanceByGUID(guid) then
			return scene:getSceneInstanceManager();
		elseif moduleTreeManager:findModuleTreeObjectByGUID(guid, state) then
			return moduleTreeManager;
		elseif guiRoot and guiRoot:findWidgetByGUID(guid) then
			return guiRoot;
		elseif rootWidget ~= nil and rootWidget:findWidgetByGUID(guid) then
			return rootWidget;
		end
	end

	return nil;
end

function resetInstancingMask(editorObjectId)
	local obj = getObjectByEditorObjectId(editorObjectId)
	if (obj == nil or obj:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) or obj:isInherited(engine.base.resourcebase.ResourceBase.getStaticObjectClass())) then
		return
	end

	if not obj.getType then
		return
	end
	
	local typeUH = obj:getType()
	if typeUH == UH_NONE then
		return
	end

	local type = typeManager:getTypeByUH(typeUH)
	if (type ~= nil and type:doesInheritType(typeManager:findTypeByName("ModelComponent"))) then
		obj:setInstancingMask(0xFFFFFF)
		obj:setShadowInstancingMask(0xFFFFFF)
	end
end

local propertyChange = nil;
function startPropertyChange(firstSelectionEditorObjectId)
	local guidStr = getGuidByEditorObjectId(firstSelectionEditorObjectId);
	local guid    = parseObjectFromStringValue(guidStr);

	propertyChange = {};
	propertyChange.oper = createPropertyChangedOperation(findManagerForGUID(guid):getObjectManager());

	if propertyChange.oper == nil then
		propertyChange = nil;
		return;
	end

	propertyChange.oper:setName("Property Changed");
end

function endPropertyChange()
	if propertyChange == nil then
		return;
	end

	if propertyChange.oper:getPropertyCount() == 0 then
		propertyChange.oper:release();
	else
		state:addUndoOperation(propertyChange.oper);
	end

	propertyChange = nil;
end

function setCustomStructArrayObjectProperty(parentEditorObjectId, propertyName, valueString)
	assert_string(parentEditorObjectId)
	assert_string(propertyName)
	assert_string(valueString)
	
	--logger:info("parentobj is " .. parentEditorObjectId)
	--logger:info("property name is " .. propertyName)
	--logger:info("value string is " .. valueString)
	
	local obj = getObjectByEditorObjectId(parentEditorObjectId);
	if (obj) then
		local customStructArrayValue = parseObjectFromStringValue(valueString);
		if (customStructArrayValue == nil) then
			externalUI:sendUICommand("validation(\"@"..parentEditorObjectId.."\", \"Error\", \"Given custom struct array is not a valid value.\")")
			return
		end
		
		-- process the customStructArrayValue...
		-- .valueTypeInfo
		-- .valuePropertyMapping
		-- .arrayOfCustomStructs [...]
		  -- .valueTypeInfo
			-- .values [...]
		if (#customStructArrayValue.valuePropertyMapping ~= #customStructArrayValue.valueTypeInfo) then
			externalUI:sendUICommand("validation(\"@"..parentEditorObjectId.."\", \"Error\", \"Custom struct property mapping and value type info array sizes do not match.\")")
			return
		end
			
		local propArrays = {}
		
		-- construct property arrays (IntPropertyArray, VC3PropertyArray, etc.) from the custom struct, and set those to the appropriate properties in object
		for infoIdx,infoPropV in ipairs(customStructArrayValue.valuePropertyMapping) do
			local propName = infoPropV
			local propTypeStr = customStructArrayValue.valueTypeInfo[infoIdx]
			local propValues = { }
			for i,v in ipairs(customStructArrayValue.arrayOfCustomStructs) do
				-- TODO: additional data integrity validations...
				-- v.valueTypeInfo == customStructArrayValue.valueTypeInfo[infoIdx]
				local propArrayIndex = i
				local propValue = v.values[infoIdx]
				table.insert(propValues, propValue)
			end
			local propValueArray = _G[propTypeStr.."PropertyArray"](propValues)
			if propertyChange then
				propertyChange.oper:saveProperty(obj, propName);
			end
			obj:setPropertyValue(obj:findPropertyIndexByName(propName), propValueArray)
		end
	else
		logger:error("Property set failed: no object with id " .. tostring(parentEditorObjectId));
	end
end


function setArrayPropertyValueAtIndex(parentEditorObjectId, propertyName, arrayIndex, valueString)
	assert_string(parentEditorObjectId)
	assert_string(propertyName)
	assert_number(arrayIndex)
	assert_string(valueString)
	local obj = getObjectByEditorObjectId(parentEditorObjectId)
	if not obj then
		logger:error("Array Property value set failed: no object with id " .. tostring(parentEditorObjectId))
		return
	end
	local valueObject = parseObjectFromStringValue(valueString)
	if (valueObject == nil) then
		externalUI:sendUICommand("validation(\"@"..parentEditorObjectId.."\", \"Error\", \""..valueString.." is not a valid value.\")")
		return
	end
	local propertyIndex = obj:findPropertyIndexByName(propertyName)
	local propertyArray = propertyIndex >= 0 and obj:getPropertyValue(propertyIndex) or nil
	if not propertyArray then
		logger:error("Array Property value set failed: object has no property with name " .. tostring(propertyName))
		return
	end
	if obj:getPropertyTypeString(propertyIndex) ~= "COLPropertyArray" then
		logger:error("Only ColPropertyArrays supported. Sorry.")
		return
	end
	local newArray = COLPropertyArray(propertyArray)
	newArray:resize(propertyArray:getSize())
	for i = 0, propertyArray:getSize() - 1 do
		newArray:set(i, propertyArray:get(i))
	end
	local propertyArray = nil
	newArray:set(arrayIndex, valueObject)
	obj:setPropertyValue(propertyIndex, newArray)
end


-- TODO: this really should use a propagating event instead of directly setting the
-- value
function setObjectProperty(parentEditorObjectId, propertyName, valueString)
	assert_string(parentEditorObjectId)
	assert_string(propertyName)
	assert_string(valueString)

	logger:debug("setting value to editor id: " .. tostring(parentEditorObjectId) .. ", "..propertyName.." = "..valueString);

	local obj = getObjectByEditorObjectId(parentEditorObjectId);
	if (obj) then
		local valueObject = parseObjectFromStringValue(valueString);
		if (valueObject == nil) then
			externalUI:sendUICommand("validation(\"@"..parentEditorObjectId.."\", \"Error\", \""..valueString.." is not a valid value.\")")
			return
		end

		if (type(valueObject) == "string") then
			valueObject = editor.Util.unescapeLineBreaks(valueObject)
		end		

		-- check for duplicates when changing names (this is expensive so only doing it in editor)
		if(propertyName == "Name" and obj.checkForDuplicateName) then
			if(not obj:checkForDuplicateName(valueObject)) then
				return
			end
		end

		-- I assume there is some findPropertyByName type of function, but I don't know
		-- what it is... therefore doing it unefficiently like this:
		-- Edit: You assume right. The function's called findPropertyIndexByName.
		local maxProp = obj:getNumProperties();
		for i = 1,maxProp do
			local itername = obj:getPropertyName(i - 1);
			if (itername == propertyName) then
				if(obj:getPropertyTypeString(i - 1) == "UH") then
					-- convert GUID to UH
					valueObject = convertGUIDToUH(valueObject);
				elseif(obj:getPropertyTypeString(i - 1) == "StateContextHandle") then
					-- convert GUID to UH
					local obj = editor.Editor.convertGUIDToObject(valueObject);
					local sceneObj = obj:getInstanceManager():getContextInstanceRoot();
					valueObject = StateContextHandle(sceneObj:getUnifiedHandle(), obj:getUnifiedHandle());
				elseif(obj:getPropertyTypeString(i - 1) == "GlobalContextHandle") then
					-- convert GUID to UH
					local obj = editor.Editor.convertGUIDToObject(valueObject);
					local sceneObj = obj:getInstanceManager():getContextInstanceRoot();
					local stateObj = obj:getInstanceManager():getTopmostInstanceRoot();
					valueObject = GlobalContextHandle(stateObj:getUnifiedHandle(), StateContextHandle(sceneObj:getUnifiedHandle(), obj:getUnifiedHandle()));
				elseif(obj:getPropertyTypeString(i - 1) == "UHPropertyArray") then
					-- convert GUID to UH
					local uhTable = {}
					for k,v in pairs(valueObject) do
						uhTable[k] = convertGUIDToUH(v);
					end
					valueObject = UHPropertyArray(uhTable)
				elseif(obj:getPropertyTypeString(i - 1) == "StateContextHandlePropertyArray") then
					-- convert GUID to SCH
					local handleTable = {}
					for k,v in pairs(valueObject) do
						if(v == GUID_NONE)
						then
							handleTable[k] = StateContextHandle(UH_NONE, UH_NONE);
						else
							local obj = editor.Editor.convertGUIDToObject(v);
							local sceneObj = obj:getInstanceManager():getContextInstanceRoot();
							handleTable[k] = StateContextHandle(sceneObj:getUnifiedHandle(), obj:getUnifiedHandle());
						end
					end
					valueObject = StateContextHandlePropertyArray(handleTable)
				elseif(obj:getPropertyTypeString(i - 1) == "GlobalContextHandlePropertyArray") then
					-- convert GUID to GCH
					local handleTable = {}
					for k,v in pairs(valueObject) do
						if(v == GUID_NONE)
						then
							handleTable[k] = GlobalContextHandle(UH_NONE, StateContextHandle(UH_NONE, UH_NONE));
						else
							local obj = editor.Editor.convertGUIDToObject(v);
							local sceneObj = obj:getInstanceManager():getContextInstanceRoot();
							local stateObj = obj:getInstanceManager():getTopmostInstanceRoot();
							handleTable[k] = GlobalContextHandle(stateObj:getUnifiedHandle(), StateContextHandle(sceneObj:getUnifiedHandle(), obj:getUnifiedHandle()));
						end
					end
					valueObject = GlobalContextHandlePropertyArray(handleTable)
				elseif(obj:getPropertyTypeString(i - 1) == "DynamicStringPropertyArray") then
					-- convert string table to DynamicString
					valueObject = DynamicStringPropertyArray(valueObject)
				elseif(obj:getPropertyTypeString(i - 1) == "TemporaryHeapStringPropertyArray") then
					-- convert string table to TemporaryHeapString
					valueObject = TemporaryHeapStringPropertyArray(valueObject)
				end

				if propertyChange then
					propertyChange.oper:saveProperty(obj, propertyName);
				end
				obj:setPropertyValue(i - 1, valueObject)
				return
			end
		end
		logger:error("Property set failed: no property with name " .. propertyName .. " in " .. tostring(parentEditorObjectId));

	else
		logger:error("Property set failed: no object with id " .. tostring(parentEditorObjectId));
	end
end


-- UNUSED
-- parses the editorObjectId for the property's parent object and the property name
-- and stuff from the given parameter editor object id. sets that to given value
function setObjectPropertyByPropertyLine(propertyEditorObjectId, valueString)
	assert_string(propertyEditorObjectId)
	assert_string(valueString)
	
	logger:debug("setting value to editor id: " .. tostring(propertyEditorObjectId) .. " to " .. valueString);

	-- hack: incidentally, the property id contains the parent guid, so it works as the
	-- parent id directly..
	local parentId = propertyEditorObjectId
	-- still, need to parse the property name out of it...
	local propertyName = parsePropertyNameFromStringValue(propertyEditorObjectId);
	if (propertyName) then
		setObjectProperty(parentId, propertyName, valueString);
	else
		logger:error("Problem parsing property name out of: " .. tostring(propertyEditorObjectId));
	end
end

local g_keyframeChangeOper = nil;
local g_keyframeChangeOperDepth = 0;
local g_keyframeUpdateOnly = nil;
function startKeyframeChange(name, depth)
	if g_keyframeChangeOper then
		logger:error("Trying to start keyframe change when old one wasn't finished");
		g_keyframeChangeOper:release();
	end
	if depth == nil then
		g_keyframeChangeOperDepth = 0;
	else
		g_keyframeChangeOperDepth = depth;
	end

	g_keyframeChangeOper = createMultiOperation();
	g_keyframeChangeOper:setName(name);
	g_keyframeUpdateOnly = true;
end

function stopKeyframeChange()
	if g_keyframeChangeOper == nil then
		logger:error("Trying to stop keyframe change when it wasn't started at the first place.");
		return;
	end

	if g_keyframeChangeOper:getOperationCount() > 0 then
		if g_keyframeUpdateOnly then
			g_keyframeChangeOper:setName("COMBINED_KeyframeAdd"); -- Ultra hacky way to combine this operation with the previous one.

			local oper = state:getUndoOperation(0);
			if oper:getOperationName() == g_keyframeChangeOper:getOperationName() and oper:getName() == g_keyframeChangeOper:getName() then
				g_keyframeChangeOper:release();
				g_keyframeChangeOper = nil;
				return;
			end

			state:insertUndoOperation(0, g_keyframeChangeOper);
		else
			state:insertUndoOperation(g_keyframeChangeOperDepth, g_keyframeChangeOper);
		end
	else
		g_keyframeChangeOper:release();
	end

	g_keyframeChangeOper = nil;
end

function saveKeyframeState(obj)
	local oper = createPropertyChangedOperation(gameScene:getSceneInstanceManager():getObjectManager());
	oper:saveProperty(obj, "KeyFrameArrayValue");
	oper:saveProperty(obj, "KeyFrameArrayTimeMs");
	oper:saveProperty(obj, "SplineParameterArray");
	g_keyframeChangeOper:add(oper);
end

-- For keyframe slider: add keyframe value to keyframe component
function addKeyFrame(editorObjectId, valueString, ignoreOutputValues)
	assert_string(editorObjectId)
	assert_string(valueString)
	
	logger:debug("Adding keyframe to component: " .. tostring(editorObjectId) .. ", value = "..valueString);

	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj == nil) then
	    obj = getObjectByGUID(parseObjectFromStringValue(editorObjectId))
	end
	    
	if (obj) then
		local valueObject = parseObjectFromStringValue(valueString);
		if (valueObject == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..valueString.." is not a valid value.\")")
			return
		end	

		-- Hacky check
		if ignoreOutputValues then
			local propName = obj:getConnectionName();
			propName = propName:sub((propName:find("->") + 2));

			local uh = obj:getOutputObject();
			local inst = gameScene:getSceneInstanceManager():getInstanceByUH(uh);

			if inst then
				local inValue = inst["get" .. propName](inst);
				local outValue = obj:getOutValue();
				if inValue == outValue then
					return
				end
			end
		end


		if g_keyframeChangeOper then
			function onReverse(self)
				local obj  = getObjectByGUID(self:get("obj"));
				local time = self:get("time");
				if not self:get("update") then
					obj:deleteKeyFrame(time);
				end
				return true;
			end
			function onOperate(self)
				local obj  = getObjectByGUID(self:get("obj"));
				local time = self:get("time");
				obj:addKeyFrame(time);
				return true;
			end

			if obj:hasFrameAt(valueObject) == false then
				g_keyframeUpdateOnly = false;
			end

			local oper = createCustomLuaOperation(onReverse, onOperate, function() return true end);
			oper:set("obj", obj:getGUID());
			oper:set("time", valueObject);
			oper:set("update", g_keyframeUpdateOnly)
			g_keyframeChangeOper:add(oper);
		end

		obj:addKeyFrame(valueObject);
	else
		logger:error("Keyframe add failed: no object with id " .. tostring(editorObjectId));
	end
end


-- For keyframe slider: delete keyframe values from keyframe component
function deleteKeyFrames(editorObjectId, valuesString)
	assert_string(editorObjectId)
	assert_string(valuesString)
	
	logger:debug("Deleting keyframe from component: " .. tostring(editorObjectId) .. ", value = "..valuesString);

	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj == nil) then
	    obj = getObjectByGUID(parseObjectFromStringValue(editorObjectId))
	end
	
	if (obj) then
		local valueObject = parseObjectFromStringValue(valuesString);
		if (valueObject == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..valuesString.." is not a valid value.\")")
			return
		end		

		if g_keyframeChangeOper then
			g_keyframeUpdateOnly = false;
			saveKeyframeState(obj);
		end
		
		obj:deleteKeyFrames(valueObject);
	else
		logger:error("Keyframe deletion failed: no object with id " .. tostring(editorObjectId));
	end
end


-- For keyframe slider: move keyframe values in keyframe component
function moveKeyFrame(editorObjectId, oldValueString, newValueString)
	assert_string(editorObjectId)
	assert_string(oldValueString)
	assert_string(newValueString)
	
	logger:debug("Moving keyframe values of component: " .. tostring(editorObjectId) .. ", old value = "..oldValueString .. ", new value = "..newValueString);

	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj == nil) then
	    obj = getObjectByGUID(parseObjectFromStringValue(editorObjectId))
	end
	
	if (obj) then	    
		local valueObject1 = parseObjectFromStringValue(oldValueString);
		if (valueObject1 == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..oldValuesString.." is not a valid value.\")")
			return
		end		
		
		local valueObject2 = parseObjectFromStringValue(newValueString);
		if (valueObject2 == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..newValuesString.." is not a valid value.\")")
			return
		end			

		if g_keyframeChangeOper then
			g_keyframeUpdateOnly = false;
			saveKeyframeState(obj);
		end
		
		obj:moveKeyFrame(valueObject1, valueObject2);
	else
		logger:error("Keyframe move failed: no object with id " .. tostring(editorObjectId));
	end
end


-- For keyframe slider: update keyframe values in keyframe component
function updateKeyFrames(editorObjectId, valuesString)
	assert_string(editorObjectId)
	assert_string(valuesString)

	logger:debug("Updating keyframe component: " .. tostring(editorObjectId) .. ", value = "..valuesString);

	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj == nil) then	
	    obj = getObjectByGUID(parseObjectFromStringValue(editorObjectId))
	end
	
	if (obj) then	    
		local valueObject = parseObjectFromStringValue(valuesString);
		if (valueObject == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..valuesString.." is not a valid value.\")")
			return
		end		

		if g_keyframeChangeOper then
			g_keyframeUpdateOnly = false;
			saveKeyframeState(obj);
		end

		obj:updateKeyFrames(valueObject);
	else
		logger:error("Keyframe update failed: no object with id " .. tostring(editorObjectId));
	end
end

-- Create slider changed undo operation
function saveSliderUndoRecord(time)
	function saveNewTime(self, newTime)
		self:set("newTime", newTime);
	end

	function onReverse(self)
		local queryId = createCSharpQuery(saveNewTime, {self});
		externalUI:sendUICommand("setKeyframeSliderUndo(" .. queryId .. ", " .. self:get("time") .. ")");
		return true;
	end

	function onOperate(self)
		externalUI:sendUICommand("setKeyframeSliderUndo(0, " .. self:get("newTime") .. ")");
		return true;
	end

	local oper = createCustomLuaOperation(onReverse, onOperate, function() return true end);
	oper:setName("Slider Changed");
	oper:set("time", time);
	state:addUndoOperation(oper);
end


-- For keyframe slider: time in slider changed
function keyFrameTimeChange(editorObjectId, indexesString)
	assert_string(editorObjectId)
	assert_string(indexesString)
	
	logger:debug("Time changed in keyframe component: " .. tostring(editorObjectId) .. ", value = "..indexesString);

	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj == nil) then
	    obj = getObjectByGUID(parseObjectFromStringValue(editorObjectId))
	end
	
	if (obj) then	    
		local valueObject = parseObjectFromStringValue(indexesString);
		if (valueObject == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..indexesString.." is not a valid value.\")")
			return
		end		

		obj:updateTime(valueObject)
	else
		logger:error("Keyframe update failed: no object with id " .. tostring(editorObjectId));
	end
end


function keyFrameTimeRangeChange(editorObjectId, startTimeString, endTimeString)
	assert_string(editorObjectId)
	assert_string(startTimeString)
	assert_string(endTimeString)
	
	logger:debug("Time range changed in keyframe component: " .. tostring(editorObjectId));

	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj == nil) then	
	    obj = getObjectByGUID(parseObjectFromStringValue(editorObjectId))
	end
	
	if (obj) then	    
		local valueObject1 = parseObjectFromStringValue(startTimeString);
		if (valueObject1 == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..startTimeString.." is not a valid value.\")")
			return
		end		
		
			local valueObject2 = parseObjectFromStringValue(endTimeString);
		if (valueObject2 == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..endTimeString.." is not a valid value.\")")
			return
		end		

		obj:setStartTime(valueObject1)
		obj:setEndTime(valueObject2)
	else
		logger:error("Keyframe update failed: no object with id " .. tostring(editorObjectId));
	end
end


function keyFrameActualTimerTimeRangeChange(editorObjectId, startTimeString, endTimeString)
	assert_string(editorObjectId)
	assert_string(startTimeString)
	assert_string(endTimeString)
	
	logger:debug("Actual timer time range changed in keyframe component: " .. tostring(editorObjectId));

	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj == nil) then	
		obj = getObjectByGUID(parseObjectFromStringValue(editorObjectId))
	end
	
	if (obj) then	    
		local valueObject1 = parseObjectFromStringValue(startTimeString);
		if (valueObject1 == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..startTimeString.." is not a valid value.\")")
			return
		end		

		local valueObject2 = parseObjectFromStringValue(endTimeString);
		if (valueObject2 == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..endTimeString.." is not a valid value.\")")
			return
		end		

		-- loosely check for equality (for filtering out any UI rounding errors or such)
		local startDiff = obj:getStartTime():getSeconds() - valueObject1:getSeconds()
		if (startDiff < 0.001 or startDiff > 0.001) then
			obj:setStartTime(valueObject1)
		end
		
		local endDiff = obj:getEndTime():getSeconds() - valueObject2:getSeconds()
		if (endDiff < 0.001 or endDiff > 0.001) then
			obj:setEndTime(valueObject2)
		end
	else
		logger:error("Keyframe update failed: no object with id " .. tostring(editorObjectId));
	end
end


-- For keyframe slider: start editor playback
function keyFrameStartEditorPlayback(editorObjectId, startString, endString, repeatString)
	assert_string(editorObjectId)
	assert_string(startTimeString)
	assert_string(endTimeString)
	assert_string(repeatString)
	
	logger:debug("Editor playback start of keyframe component: " .. tostring(editorObjectId));

	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj == nil) then
	    obj = getObjectByGUID(parseObjectFromStringValue(editorObjectId))
	end
	
	if (obj) then	    
		local valueObject1 = parseObjectFromStringValue(startString);
		if (valueObject1 == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..startString.." is not a valid value.\")")
			return
		end		
		
		local valueObject2 = parseObjectFromStringValue(endString);
		if (valueObject2 == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..endString.." is not a valid value.\")")
			return
		end		
		
		local valueObject3 = parseObjectFromStringValue(repeatString);
		if (valueObject3 == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..repeatString.." is not a valid value.\")")
			return
		end	

        obj:startPlayback(valueObject1, valueObject2, valueObject3);
		--obj:keyFrameStartEditorPlayback(valueObject1, valueObject2, valueObject3);
	else
		logger:error("Keyframe update failed: no object with id " .. tostring(editorObjectId));
	end
end


-- For keyframe slider: stop editor playback
function keyFrameStopEditorPlayback(editorObjectId, resetString)
	assert_string(editorObjectId)
	assert_string(resetString)
	
	logger:debug("Editor playback stop of timer component: " .. tostring(editorObjectId));

	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj == nil) then
	    obj = getObjectByGUID(parseObjectFromStringValue(editorObjectId))
	end
	
	if (obj) then	    
		local valueObject = parseObjectFromStringValue(resetString);
		if (valueObject == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..resetString.." is not a valid value.\")")
			return
		end	
		
        obj:stopPlayback(valueObject)
	else
		logger:error("Keyframe update failed: no object with id " .. tostring(editorObjectId));
	end
end

-- For keyframe slider: pause editor playback
function keyFramePauseEditorPlayback(editorObjectId, pauseString)
	assert_string(editorObjectId)
	assert_string(pauseString)

	logger:debug("Editor playback stop of timer component: " .. tostring(editorObjectId));

	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj == nil) then
	    obj = getObjectByGUID(parseObjectFromStringValue(editorObjectId))
	end
	
	if (obj) then	    
		local valueObject = parseObjectFromStringValue(pauseString);
		if (valueObject == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..pauseString.." is not a valid value.\")")
			return
		end	
		
        obj:pausePlayback(valueObject)
	else
		logger:error("Keyframe update failed: no object with id " .. tostring(editorObjectId));
	end
end

-- For keyframe slider:reset editor playback
function keyFrameResetEditorPlayback(editorObjectId)
	assert_string(editorObjectId)
	
	logger:debug("Editor playback reset of timer component: " .. tostring(editorObjectId));

	local obj = getObjectByEditorObjectId(editorObjectId)
	if (obj == nil) then
	    obj = getObjectByGUID(parseObjectFromStringValue(editorObjectId))
	end
	
	if (obj) then		
        obj:resetPlayback()
	else
		logger:error("Keyframe update failed: no object with id " .. tostring(editorObjectId));
	end
end

-- For keyframe slider: set spline parameter values
function keyFrameSetInterpolationValues(editorObjectId, indexString, tString, cString, bString)
	assert_string(editorObjectId)
	assert_string(indexString)
	assert_string(tString)
	assert_string(cString)
	assert_string(bString)

	logger:debug("Editor set interpolation values of keyframe component: " .. tostring(editorObjectId));

	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj == nil) then
	    obj = getObjectByGUID(parseObjectFromStringValue(editorObjectId))
	end
	
	if (obj) then	    
		local valueObject1 = parseObjectFromStringValue(indexString);
		if (valueObject1 == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..indexString.." is not a valid value.\")")
			return
		end		
		
		local valueObject2 = parseObjectFromStringValue(tString);
		if (valueObject2 == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..tString.." is not a valid value.\")")
			return
		end		
		
		local valueObject3 = parseObjectFromStringValue(cString);
		if (valueObject3 == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..cString.." is not a valid value.\")")
			return
		end	
		
		local valueObject4 = parseObjectFromStringValue(bString);
		if (valueObject4 == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..bString.." is not a valid value.\")")
			return
		end		

        -- TODO_CH: Add check that we actually have a keyframe component
		obj:setInterpolationValues(valueObject1, valueObject2, valueObject3, valueObject4);

	else
		logger:error("Keyframe update failed: no object with id " .. tostring(editorObjectId));
	end
end

-- For keyframe slider: update names
function keyFrameUpdateConnectionName(editorObjectId)
	assert_string(editorObjectId)
	
	logger:debug("Editor update connection name of keyframe component: " .. tostring(editorObjectId))

	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj == nil) then
	    obj = getObjectByGUID(parseObjectFromStringValue(editorObjectId))
	end
	
	if (obj) then	  
        obj:updateConnectionName()
	else
		logger:error("Keyframe update failed: no object with id " .. tostring(editorObjectId))
	end
end

-- For keyframe slider: set connections active
function keyFrameSetConnectionsActive(editorObjectId)
	assert_string(editorObjectId)
	
	logger:debug("Editor set connections active of keyframe component: " .. tostring(editorObjectId))

	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj == nil) then
	    obj = getObjectByGUID(parseObjectFromStringValue(editorObjectId))
	end
	
	if (obj) then	  
        obj:setConnectionsActiveInEditor()
	else
		logger:error("Keyframe update failed: no object with id " .. tostring(editorObjectId))
	end
end

-- For keyframe slider: set property as active master
function setKeyframeMasterPre(guid)
	externalUI:sendUICommand("setKeyframeMasterPre(\"".. guid .."\")")
end
function setKeyframeMaster(editorObjectId, timePropertyId)

	if (editorObjectId == "\"GUID_NONE\"" and timePropertyId == "\"GUID_NONE\"") then	
		externalUI:setKeyFrameMasterTimer(GUID_NONE)
	else
		local obj = getObjectByEditorObjectId(editorObjectId);
		if (obj == nil) then
			obj = getObjectByGUID(parseObjectFromStringValue(editorObjectId))
		end
		if (obj ~= nil) then
			externalUI:setKeyFrameMasterTimer(obj:getGuid())
		end
	end
	
	externalUI:sendUICommand("setKeyframeMaster(\"".. editorObjectId .. "\", \"".. timePropertyId .."\")")
end

function setKeyFramePlayback(playback)
	externalUI:setKeyFramePlaybackState(playback);
end


-- For keyframe slider: get the type of the values
function getKeyframeValueString(editorObjectId)
	assert_string(editorObjectId)
	
	logger:debug("Editor get keyframe value string component: " .. tostring(editorObjectId));
	
	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj == nil) then
	    obj = getObjectByGUID(parseObjectFromStringValue(editorObjectId))
	end
	
	if (obj) then	
		local value = obj:getValueString()		
		externalUI:sendUICommand("setKeyframeValueString(\"" .. editorObjectId .. "\", \"".. tostring(value) .."\")")
	else
		logger:error("Keyframe update failed: no object with id " .. tostring(editorObjectId));
	end
end	
		

-- For keyframe slider: get keyframe values for keyframe graph
function getKeyframeValues(editorObjectId, startValue, endValue, step)
	assert_string(editorObjectId)
	assert_string(startValue)
	assert_string(endValue)
	assert_string(step)

	logger:debug("Editor get keyframe values from component: " .. tostring(editorObjectId));

	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj == nil) then
	    obj = getObjectByGUID(parseObjectFromStringValue(editorObjectId))
	end
	
	if (obj) then			
		local valueObject1 = parseObjectFromStringValue(startValue);
		if (valueObject1 == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..startValue.." is not a valid value.\")")
			return
		end		
		
		local valueObject2 = parseObjectFromStringValue(endValue);
		if (valueObject2 == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..endValue.." is not a valid value.\")")
			return
		end	
		
		local valueObject3 = parseObjectFromStringValue(step);
		if (valueObject3 == nil) then
			externalUI:sendUICommand("validation(\"@"..editorObjectId.."\", \"Error\", \""..step.." is not a valid value.\")")
			return
		end    	

		-- TODO_CH: Add check that we actually have a keyframe component
		local valueArray = obj:getKeyframeValues(valueObject1, valueObject2, valueObject3);
		
		externalUI:sendUICommand("setKeyframeValues(\"" .. editorObjectId .. "\", \"".. tostring(valueArray) .."\")")
	else
		logger:error("Keyframe update failed: no object with id " .. tostring(editorObjectId));
	end
end

function createKeyframeComponentToActiveTimer(timerEditorId, componentEditorId, componentTypeName)
	assert_string(timerEditorId)
	assert_string(componentEditorId)
	assert_string(componentTypeName)
	
	externalUI:sendUICommand("openKeyframeDialog()")
	
	local inputObj = getObjectByEditorObjectId(timerEditorId);
	if inputObj == nil then
		logger:error("Create keyframe component to active timer: failed to find input object with given id " .. timerEditorId)
		return
	end
 
	local outputObj = getObjectByEditorObjectId(componentEditorId);
	if (outputObj == nil) then
 		logger:error("Create keyframe component to active timer: failed to find output object with given id " .. componentEditorId)
		return
	end
	
	local outputPropIndex = parsePropertyNumberFromEditorId(componentEditorId)
	local outputPropName = outputObj:getPropertyName(outputPropIndex);
    
    createCustomPropAnimComponent(componentEditorId, timerEditorId, componentEditorId, componentTypeName, "InTime", "OutValue", {})        
end


function createKeyframeComponentToNewTimer(componentEditorId, editorListenerTag)  
	assert_string(componentEditorId)
	assert_string(editorListenerTag)

	externalUI:sendUICommand("openKeyframeDialog()")

	local ownerObj = getObjectByEditorObjectId(componentEditorId);
	if (ownerObj == nil) then
		logger:error("Create keyframe object to new timer: Failed to find object with given id " .. componentEditorId)
		return
	end


	local relatedFinalOwner = ownerObj
	if (ownerObj.getFinalOwner) then relatedFinalOwner = ownerObj:getFinalOwner() end

	-- If we already have a timer in the component, use that!
	local timerComp = relatedFinalOwner:findComponent(engine.component.AbstractTimerComponent)
	if timerComp then
		local timerGuid = timerComp:getGuid()
		externalUI:sendUICommand("newTimerComponentCreatedForKeyframe(\"" .. tostring(timerGuid) .. "\")")        
		externalUI:sendUICommand("openKeyframeDialog()")
		return
	end

	local custCompType = typeManager:findTypeByName("TimerComponent");
	if (not(custCompType)) then
	logger:error("Create keyframe object to new timer: Failed to find the required type \"" .. componentTypeName .. "\" for creation of the connection.")
		return
	end  
	ownerObj:getInstanceManager():createNewComponent(custCompType:getUnifiedHandle(), relatedFinalOwner, createdNewTimerForComponent, {editorListenerTag = editorListenerTag} );
end

function createdNewTimerForComponent(timerObj, params)
	assert_treenode(timerObj)
--	assert_string(params)
  
  	if timerObj == nil then
        logger:error("timer object is a nill value")
    end  
 
    local guid = timerObj:getGuid()
      
    externalUI:sendUICommand("newTimerComponentCreatedForKeyframe(\"" .. tostring(guid) .. "\")")
end


-- sends the entire type tree, instance tree and resource tree to the external editor UI
-- (this is a debug feature mostly, calling this could take up to several minutes if the trees are large!)
function syncFullObjectGraph(editorListenerTag)
	assert_string(editorListenerTag)
	
	if(state.isEditorSyncEnabled and (not state:isEditorSyncEnabled())) then return end
	typeGraph = editor.Editor.getTypeTreeForExternalUI(editor.Editor.InfiniteDepth);
	instanceGraph = editor.Editor.getInstanceTreeForExternalUI(editor.Editor.InfiniteDepth);
	resourceGraph = editor.Editor.getResourceTreeForExternalUI(editor.Editor.InfiniteDepth);
	externalUI:sendUICommand("sync(\""..editorListenerTag.."\", \""..typeGraph..instanceGraph..resourceGraph.."\")");
end


-- parses a string value into a new specific object (assuming the string is a proper value)
-- (for example: "VC3(0,0,0)" gets parsed to a new VC3 object with the value 0,0,0)
function parseObjectFromStringValue(value)
	assert_string(value)

--	Getting sick of this spam. Re-enable if it is necessary.
--	logger:debug("Parsing object from string \"" .. value .. "\".")
	local loadedFunction, errorMessage = loadstring("return " .. value)
	if not loadedFunction then
		logger:error("external_ui.parseObjectFromStringValue - " .. errorMessage)
		return nil
	end
	local ok, output = pcall(loadedFunction)
	if (ok == false) then
		logger:error("external_ui.parseObjectFromStringValue - " .. output)
		return nil
	else
--		logger:debug("Parsed type: " .. type(output) .. " with value: " .. tostring(output));
		return output
	end
end


function receivedUIEvent(eventString)
	assert_string(eventString)
	
	--logger:debug("Received UI Event: " .. eventString);
	local loadedFunction, errorMessage = loadstring(eventString);

	if not loadedFunction then
		-- TODO: should give the error/result to the editor instead?
		--logger:error("external_ui:receivedUIEvent - Error: " .. errorMessage .. ". eventString: " .. eventString);
		logger:error("external_ui:receivedUIEvent - Error processing event string: [" .. eventString .. "]. Error was: " .. errorMessage);
		return;
	end

	local ok, output = pcall(loadedFunction);

	-- TODO: should give the error/result to the editor instead?
	if ok == false then
		--logger:error("external_ui:receivedUIEvent - Output: " .. output .. ". eventString: " .. eventString);
		logger:error("external_ui:receivedUIEvent - Error running event string: [" .. eventString .. "]. Error was: " .. output);
		return;
	end
end


function getAutoCompleteSuggestions(lineStr, cursorPosition)
	assert_string(lineStr)
	assert_number(cursorPosition)

	-- logger:debug("Received get autocomplete suggestions event: " .. lineStr)
	str = lineStr:sub(1, cursorPosition);

	local matches, types, commonStart, identifier = misc.AutoComplete.getMatches(str)
	if commonStart:len() > identifier:len() then
		local startOfLine = str:sub(1, str:len() - identifier:len())
		local endOfLine = string.sub(lineStr, startOfLine:len() + identifier:len() + 1)
		local beforeCursor = startOfLine .. commonStart
		local cursorPos = beforeCursor:len()
		externalUI:sendUICommand("setUIValue(\"consoleTextBox\", \"" .. beforeCursor .. endOfLine .. "\", ".. cursorPos ..", 0)")
	else
		local addComma = false;
		local suggestions = ""
		for i, name in ipairs(matches) do
			if (addComma) then
				suggestions = suggestions .. ", ";
			else
				addComma = true;
			end
			suggestions = suggestions .. "\"" .. name .. "\"" -- " (" .. types[name] .. ")"
		end
		if (suggestions:len() == 0) then
			suggestions = "\"" + lineStr + "\"";
		end
		externalUI:sendUICommand("suggestUIValues(\"consoleTextBox\", " .. suggestions .. ")")
	end
end


function autoCompleteConsoleCommand(lineStr, cursorPosition)
	assert_string(lineStr)
	assert_number(cursorPosition)
	
	logger:error("autoCompleteConsoleCommand - deprecated.")
end


function runConsoleCommand(cmd)
	assert_string(cmd)

	logger:debug("Received external UI console command: " .. cmd)

	local loadedFunction, errorMessage = loadstring(cmd)

	if not loadedFunction then
		-- TODO: should give the error/result to the editor instead?
		logger:error("Error: " .. errorMessage)
		return
	end

	local ok, output = pcall(loadedFunction)

	-- TODO: should give the error/result to the editor instead?

	if ok == false then
		logger:error("Error: " .. output)
		return
	else
		logger:info(tostring(output))
	end
end


function stopInsertingType()
	if(state.deselectInsertTool) then
		state:deselectInsertTool()
	end
end


function informSelectionListChanged()
	if(state.selectionListHasChanged) then
		state:selectionListHasChanged()
	end
end


function startInsertingType(typeId)
	if(state.deselectInsertTool) then
		state:deselectInsertTool();
		-- insert new entity
		local typ = getObjectByEditorObjectId(typeId)
		if(typ and typ:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) ) then
			if(not typ:doesInheritType(typeManager:findTypeByName("Entity"))) then
				return
			end
			if(typ:isAbstractType()) then
				return
			end
			state:selectInsertTool(typ:getUnifiedHandle(), gameScene);
		 end
	 end
end


--[[
function newInstanceFunction(obj, params)
	-- make sure entity is selected
	obj:findComponent(editor.component.EditorSelectionComponent):setSelected(true);
end


function createNewInstanceFromType(typeId)
	local typ = getObjectByEditorObjectId(typeId)
	if(typ and typ:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) ) then
		if(not typ:doesInheritType(typeManager:findTypeByName("Entity"))) then
			sendGameLogMessageToExternalUI("Cannot create instance from '" .. typ:getName() .. "', does not inherit from Entity", 1);
			return
		end
		if(typ:isAbstractType()) then
			sendGameLogMessageToExternalUI("Cannot create instance from '" .. typ:getName() .. "', type is abstract", 1);
			return
		end
		-- TODO: always creates it in gameScene.. should somehow figure out which one
		state:selectInsertTool();
		local im = gameScene:getSceneInstanceManager();
		im:createNewInstance(typ:getUnifiedHandle(), newInstanceFunction, nil);
	end
end
--]]

function getComponentTypeListForInherit(typeName, instanceGUIDString)
	local debug = false
	local typ = typeManager:findTypeByName(typeName)
	if typ then
	
		local instance = nil;		
		if instanceGUIDString ~= nil and string.len(instanceGUIDString) > 0 then
			local instGuid = getGUIDFromGUIDString(instanceGUIDString);
			instance = getInstanceByGUID(instGuid);
			if debug and instance then
				logger:debug("Checking dirty properties for inherit new type from instance " .. instance:getName())
			end
		end
		
		local str = ""
		local iter = TypeComponentIterator(typ)
		local childCompTypeUH = iter:next()
		while childCompTypeUH do
			local childCompType = typeManager:getTypeByUH(childCompTypeUH)
			local cName = childCompType:getName()
			if debug then logger:debug("Checking " .. cName) end
			-- Ignore TransformComponent. If there are more, we might want to move the list to more
			-- configurable place.
			if cName ~= "TransformComponent" then
				if #str > 0 then
					str = str .. ", "
				end

				str = str .. "\"" .. cName
				
				local baseTypeName = childCompType:getBaseTypeName()
				str = str .. "|" .. baseTypeName;
				
				-- If we are inheriting instance, some of the components should forced to be inherited
				if instance then
					local instanceComp = findInstanceComponentByTypeUH(instance, childCompTypeUH)
					if instanceComp then
						local dirtyFound = false
						for propertyIndex = 0, instanceComp:getNumProperties() - 1 do
							local propName = instanceComp:getPropertyName(propertyIndex)
							-- Guid and Name are always dirty (type => instance tends to do that)
							if not dirtyFound and propName ~= "Guid" and propName ~= "Name" then
								if childCompType:findPropertyIndexByName(propName) ~= -1 then
									if not instanceComp:isPropertyValueInherited(propertyIndex) then
										if debug then logger:debug("Property " .. propName .. " is InheritDirty") end
										dirtyFound = true
										str = str .. "|" .. "[SELECTED]"
									else
										if debug then logger:debug("Property " .. propName .. " is not InheritDirty") end
									end
								else
									if debug then logger:debug("Property " .. propName .. " not found from type") end
								end
							else
								if instanceComp:isPropertyValueInherited(propertyIndex) then
									if debug then logger:debug("Skipping property " .. propName) end
								else
									if debug then logger:debug("Skipping dirty property " .. propName) end
								end
							end
						end
						-- TODO: Should check here if instance properties differs from type instance properties, if so, set selected
						-- HACK: Now just select all unique (not shared) components (this causes unnecessary inheritations)
-- 						if not c:isSharedComponentType() then
-- 							str = str .. "[SELECTED]"
-- 						end
					end
				end
				str = str .. "\""
			end
			childCompTypeUH = iter:next()
		end
		str = "typeListForInherit(" .. str .. ")"
		externalUI:sendUICommand(str)
	end		
end


function startCopyImpl(type)
	if type:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) then
		if type:isStaticType() then
			editorMessageBox("Cannot copy static type.", "Error copying type", "Error")
			return
		end
		local originalTypeName = type:getName()
		local suggestedCopyTypeName = originalTypeName .. "Copy"
		local copyCount = 0
		while typeManager:findTypeByName(suggestedCopyTypeName) do
			copyCount = copyCount + 1
			suggestedCopyTypeName = originalTypeName .. "Copy" .. copyCount
		end
		externalUI:sendUICommand("typeCopyStart(\"" .. originalTypeName .. "\", \"" .. suggestedCopyTypeName .. "\")")
	else
		logger:error("external_ui:startCopyImpl - Failed to copy type. Type don't seem to be type at all.")
	end
end

function startCopyType(typeId)
	local type = getObjectByEditorObjectId(typeId);
	if type then
		startCopyImpl(type)
	else
		logger:error("external_ui:startCopyType - No such Type found with given typeId.")
	end
end

function startCopyTypeFromInstance(guid)
	local instance = getInstanceByGUID(guid);
	if instance then
		local type = getTypeByUH(instance:getType());
		if type then
			startCopyImpl(type)
		else
			logger:error("external_ui:startCopyFromInstance - No such Type found with given typeId.")
		end
	else
		logger:error("external_ui:startCopyFromInstance - No such instance found with given GUID.");
	end
end

function copyType(originalTypeName, newTypeName)
	assert_string(originalTypeName)
	assert_string(newTypeName)
	
	local origType = typeManager:findTypeByName(originalTypeName)
	local newType = typeManager:findTypeByName(newTypeName)
	if not origType then
		logger:error("external_ui:copyType - Original Type not found with given name.")
		return
	end
	if newType then
		editorMessageBox("Type with given name \"".. newTypeName .."\" already exists.", "Error copying type", "Error")
		return
	end
	local resultType = typeManager:copyType(newTypeName, originalTypeName)
	logger:debug("external_ui:copyType - Copied type \""..originalTypeName.."\" to \""..newTypeName.."\".")
end

-- a temporary list used by deepCopyType...
deepCopyTypeImplList = { }
declareManualReload(thisModule, [[deepCopyTypeImplList]]);

deepCopyIgnoreErrorsEnabled = false
declareReload(thisModule, [[deepCopyIgnoreErrorsEnabled]]);

-- Generally speaking it is ill adviced to use this. (but just in case you want to do it anyway)
function deepCopyIgnoreErrors()
	deepCopyIgnoreErrorsEnabled = true
end

-- simulates the deep copy to see how many types will be cloned and returns true if cloning is ok for given parameters, false if not
-- also sets the data in the given errCodeTableOut to reflect the reason why it cannot be cloned in case of false
function canDeepCopyType(errCodeTableOut, originalTypeName, originalTypeNamePrefix, newTypeNamePrefix, deepCopyReferencedTypesToo, requireCorrectPrefix)	
	assert_table(errCodeTableOut)
	assert_string(originalTypeName)
	assert_string(originalTypeNamePrefix)
	assert_string(newTypeNamePrefix)
	assert_boolean(deepCopyReferencedTypesToo)
	assert_boolean(requireCorrectPrefix)
	
	deepCopyTypeImplList = { }
	local ok = deepCopyTypeListRelatedToCopyImpl(errCodeTableOut, originalTypeName, originalTypeNamePrefix, newTypeNamePrefix, deepCopyReferencedTypesToo, requireCorrectPrefix)
	deepCopyTypeImplList = { }
	if (ok) then
		return true
	else
		return false
	end
end
 
-- clones the type by cloning all of its components as well and optionally any type its references (a feature to be used carefully!)
-- TransformComponent is ignored during copy.
-- originalTypeName -- full type name (i.e. SomeExampleEffectEntity)
-- originalTypeNamePrefix -- original type prefix (i.e. SomeExample) - note, orignalTypeName must begin with this string
-- newTypeNamePrefix -- new type name prefix (i.e. DuplicatedExample)
-- deepCopyReferencedTypesToo -- when true, any type references are copied too! warning, careless use of this may cause excessive type cloning!!!
-- requireCorrectPrefix -- when true, any component/reference to be copied must have the correct prefix. when false, the original correct prefix is not required for the components 
-- or references, and in cases where the prefix does not exist, the new prefix is just prepended to the full type name (expect long bloated type names!)

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

function getDeepCopyName(typeName, originalTypeNamePrefix, newTypeNamePrefix)
	assert_string(typeName)
	assert_string(originalTypeNamePrefix)
	assert_string(newTypeNamePrefix)
	
	local newName = typeName
	if (stringStartsWith(newName, originalTypeNamePrefix)) then
		newName = string.sub(newName, 1 + #originalTypeNamePrefix)				
	end
	newName = newTypeNamePrefix .. newName
	
	logger:debug("Deep copy type name " .. typeName .. " will be " .. newName .. ", when original prefix is " .. originalTypeNamePrefix .. " and new prefix is " .. newTypeNamePrefix)
	
	return newName
end

userConfirmFunction = nil
userConfirmFunctionParams = { }
declareManualReload(thisModule, [[userConfirmFunction]])
declareManualReload(thisModule, [[userConfirmFunctionParams]])

-- call a given lua function with given params, but only if the editor user confirms by clicking yes to the given message
function userConfirmBeforeCallingFunction(confirmMsg, functionAfterConfirmedYes, ...)
	assert_string(confirmMsg)
	assert_function(functionAfterConfirmedYes)
	
	userConfirmFunction = functionAfterConfirmedYes
	userConfirmFunctionParams = arg
end
function userConfirmBeforeCallingFunctionYes()
	userConfirmFunction(unpack(userConfirmFunctionParams))
end
function userConfirmBeforeCallingFunctionNo()
	-- nop
end

-- This will change any component the given typeObj might have found in the listOfOldTypeComps, with the matching index in listOfNewTypeComps
-- the lists are tables of type names
function changeComponentTypes(typeObj, listOfOldTypeComps, listOfNewTypeComps)
	--assert_type(typeObj)
	assert_table(listOfOldTypeComps)
	assert_table(listOfNewTypeComps)
	if (#listOfOldTypeComps ~= #listOfNewTypeComps) then
		logger:error("changeComponentTypes the list of old comps and the list of new comps are not of same size.")
		return
	end
	
	-- the lists are expected to be type names
	if (#listOfOldTypeComps >= 1) then
		assert_string(listOfOldTypeComps[1])
		assert_string(listOfNewTypeComps[1])
	end
	
	local numCompTypes = typeObj:getNumComponentTypes()

	for listi = 1, #listOfOldTypeComps do
		for cidx = 0, numCompTypes-1 do
			local typeChildCompUH = typeObj:getComponentType(cidx)
			local typeChildComp = typeManager:getTypeByUH(typeChildCompUH)
			local childCompName = typeChildComp:getName()
			if (childCompName == listOfOldTypeComps[listi]) then
				-- this component needs to be replaced
				local newChildComp = typeManager:findTypeByName(listOfNewTypeComps[listi])
				if (newChildComp ~= nil) then
					typeObj:removeComponentType(typeChildCompUH)
					typeObj:addComponentType(newChildComp:getUnifiedHandle())
				else
					logger:error("changeComponentTypes failure, failed to find the new component \"" .. listOfNewTypeComps[listi] .. "\" to replace an old component \"" .. listOfOldTypeComps[listi] .. "\" with.")
				end
				break
			end
		end
	end		
end


-- This will change any referred type (via UH property / UH property array) the given typeObj might have found in the listOfOldTypeComps, with the matching index in listOfNewTypeComps
-- the lists are tables of type names
function changeReferredTypes(typeObj, listOfOldTypeComps, listOfNewTypeComps)
	--assert_type(typeObj)
	assert_table(listOfOldTypeComps)
	assert_table(listOfNewTypeComps)
	if (#listOfOldTypeComps ~= #listOfNewTypeComps) then
		logger:error("changeComponentTypes the list of old comps and the list of new comps are not of same size.")
		return
	end
	
	-- the lists are expected to be type names
	if (#listOfOldTypeComps >= 1) then
		assert_string(listOfOldTypeComps[1])
		assert_string(listOfNewTypeComps[1])
	end
	
	local t = typeObj

	for listi = 1, #listOfOldTypeComps do
	
		local numProps = t:getNumProperties()
		for propIdx = 0, numProps - 1 do
			local typeStr = t:getPropertyTypeString(propIdx)
			
			-- individual UH references
			if (typeStr == "UH") then
				--logger:debug("Reference property \"" .. t:getPropertyName(propIdx) .. "\" should perhaps be changed.")
				local refUH = t:getPropertyValue(propIdx)
				if (refUH ~= UH_NONE) then
					--logger:debug("Reference property \"" .. t:getPropertyName(propIdx) .. "\" is set to a UH value.")
					if (typeManager:isType(refUH)) then
						local refT = typeManager:getTypeByUH(refUH)
						if (refT ~= nil) then
							-- ok, we got the referred type, now ensure it isn't a cyclic reference
							local refTypeName = refT:getName()
							--logger:debug("Reference property \"" .. t:getPropertyName(propIdx) .. "\" refers to a type with name \"" .. refTypeName .. "\".")
							if (refTypeName == listOfOldTypeComps[listi]) then
								logger:debug("Reference property \"" .. t:getPropertyName(propIdx) .. "\" refers to a type with name \"" .. refTypeName .. "\". It needs to be changed.")
								-- this reference needs to be changed to point to the new name
								local newRefType = typeManager:findTypeByName(listOfNewTypeComps[listi])
								if (newRefType ~= nil) then
									t:setPropertyValue(propIdx, newRefType:getUnifiedHandle())
								else
									logger:error("changeReferredTypes failure, failed to find the new type \"" .. listOfNewTypeComps[listi] .. "\" to replace an old referred type \"" .. listOfOldTypeComps[listi] .. "\" with.")
								end
							end							
						else
							logger:error("Encountered a UH reference to a type, but that type did not exist. Deep copy type fails to copy the referred type.");
						end
					end
				end
			end
				
			-- UH array references
			if (typeStr == "UHPropertyArray") then
				--logger:debug("Reference property array \"" .. t:getPropertyName(propIdx) .. "\" should perhaps be changed.")
				local refUHArray = t:getPropertyValue(propIdx)
				for arrIdx = 0,refUHArray:getSize() - 1 do
					local refUH = refUHArray:get(arrIdx)
					if (refUH ~= UH_NONE) then
						--logger:debug("Reference property array \"" .. t:getPropertyName(propIdx) .. "\" index " .. tostring(arrIdx) .. " is set to a UH value.")
						if (typeManager:isType(refUH)) then
							local refT = typeManager:getTypeByUH(refUH)
							if (refT ~= nil) then
								-- ok, we got the referred type, now ensure it isn't a cyclic reference
								local refTypeName = refT:getName()
								--logger:debug("Reference property \"" .. t:getPropertyName(propIdx) .. "\" index " .. tostring(arrIdx) .. " refers to a type with name \"" .. refTypeName .. "\".")
								if (refTypeName == listOfOldTypeComps[listi]) then
									logger:debug("Reference property \"" .. t:getPropertyName(propIdx) .. "\" index " .. tostring(arrIdx) .. " refers to a type with name \"" .. refTypeName .. "\". It needs to be changed.")
									-- this reference needs to be changed to point to the new name
									local newRefType = typeManager:findTypeByName(listOfNewTypeComps[listi])
									if (newRefType ~= nil) then
										local newArrTable = { }
										for tempi = 0,refUHArray:getSize() - 1 do
											local tempv = refUHArray:get(tempi)
											if (tempi == arrIdx) then
												table.insert(newArrTable, newRefType:getUnifiedHandle())
											else
												table.insert(newArrTable, tempv)
											end
										end										
										local newArrayObj = UHPropertyArray(newArrTable)
										t:setPropertyValue(propIdx, newArrayObj)
										refUHArray = t:getPropertyValue(propIdx)
									else
										logger:error("changeReferredTypes failure, failed to find the new type \"" .. listOfNewTypeComps[listi] .. "\" to replace an old referred type \"" .. listOfOldTypeComps[listi] .. "\" with.")
									end									
								end							
							else
								logger:error("Encountered a UH reference to a type, but that type did not exist. Deep copy type fails to copy the referred type.");
							end
						end
					end				
				end
			end
		end
	end
end


-- creates a clone of the given type, changes the given prefix of the typename to the newly given one, the cloned type will have all of its component types cloned too
-- optionally clones all the references to any other types too
-- all of the cloned types should have the expected type prefix, however, if requireCorrectPrefix is false, it is not required, and then, any types not having the old prefix
-- will just be prepended with the new prefix
function deepCopyType(originalTypeName, originalTypeNamePrefix, newTypeNamePrefix, deepCopyReferencedTypesToo, requireCorrectPrefix)
	assert_string(originalTypeName)
	assert_string(originalTypeNamePrefix)
	assert_string(newTypeNamePrefix)
	assert_boolean(deepCopyReferencedTypesToo)
	assert_boolean(requireCorrectPrefix)

	logger:debug("Performing deepCopyType for (" .. originalTypeName .. ") " .. originalTypeNamePrefix .. " to " .. newTypeNamePrefix)
	
	local errCodeTable = { }
	
	deepCopyTypeImplList = { }
	local ok = deepCopyTypeListRelatedToCopyImpl(errCodeTable, originalTypeName, originalTypeNamePrefix, newTypeNamePrefix, deepCopyReferencedTypesToo, requireCorrectPrefix)
	if ok then
		-- process the deepCopyTypeImplList one by one 
		-- first, create a list of new names (one for each of the old names)
		local deepCopyNewNameList = { }
		for i=1,#deepCopyTypeImplList do
			local newName = getDeepCopyName(deepCopyTypeImplList[i], originalTypeNamePrefix, newTypeNamePrefix)
			table.insert(deepCopyNewNameList, newName)
		end
		-- then, creating a copy of each type/component type
		for i=1,#deepCopyTypeImplList do
			local oldName = deepCopyTypeImplList[i]
			local newName = deepCopyNewNameList[i]
			logger:debug("About to copy type from " .. oldName .. " to " .. newName)
			copyType(oldName, newName)
		end
		-- then, by replacing all of the component types of the entities with the new ones
		for i=1,#deepCopyNewNameList do
			local newName = deepCopyNewNameList[i]
			logger:debug("About to modify type ".. newName .. " to use correct new components.")
			local t = typeManager:findTypeByName(newName)
			changeComponentTypes(t, deepCopyTypeImplList, deepCopyNewNameList)
			if (deepCopyReferencedTypesToo) then
				changeReferredTypes(t, deepCopyTypeImplList, deepCopyNewNameList)
			end
		end
	else
		editorMessageBox(errCodeTable.msg, "Error")
	end
	deepCopyTypeImplList = { }
end


-- internal implementation of deepCopyType, modifies deepCopyTypeImplList, recurses what to copy
-- note, this may NOT modify anything (as it is used by the canDeepCopy... query too)
function deepCopyTypeListRelatedToCopyImpl(errCodeTableOut, originalTypeName, originalTypeNamePrefix, newTypeNamePrefix, deepCopyReferencedTypesToo, requireCorrectPrefix)
	assert_table(errCodeTableOut)
	assert_string(originalTypeName)
	assert_string(originalTypeNamePrefix)
	assert_string(newTypeNamePrefix)
	assert_boolean(deepCopyReferencedTypesToo)
	assert_boolean(requireCorrectPrefix)

	-- HACK: don't deep copy transform component
	if originalTypeName == "TransformComponent" then
		return true
	end
	
	if requireCorrectPrefix then
		if not stringStartsWith(originalTypeName, originalTypeNamePrefix) then
			local msg = "Cannot perform deepCopyType for \"" .. originalTypeName .. "\" because it does not follow the expected type naming convention."
			errCodeTableOut.code = 4
			errCodeTableOut.msg = msg
			return false
		end
	end	

	local t = typeManager:findTypeByName(originalTypeName)

	if t == nil then
		local msg = "Cannot perform deepCopyType for \"" .. originalTypeName .. "\" because no type exists with that name."
		errCodeTableOut.code = 5
		errCodeTableOut.msg = msg
		return false
	end

	local referenceMismatchWithOriginalPrefix = false
	local referenceMismatchWithOriginalPrefixName = ""	
	local componentMismatchWithOriginalPrefix = false
	local componentMismatchWithOriginalPrefixName = ""
	local cyclicReferences = false
		
	-- dig out components and their subcomponents (depth-first iteration) and list those
	-- then go through all of those, and dig out any references to other types, 
	-- do for all comps (+ optionally the comp refs)
	
	for cidx = 0, t:getNumComponentTypes() - 1 do
		local typeChildCompUH = t:getComponentType(cidx)
		local typeChildComp = typeManager:getTypeByUH(typeChildCompUH)
		local childCompName = typeChildComp:getName()
		local compOk = deepCopyTypeListRelatedToCopyImpl(errCodeTableOut, childCompName, originalTypeNamePrefix, newTypeNamePrefix, deepCopyReferencedTypesToo, requireCorrectPrefix)			
		
		-- TODO: if not compOk then ... some error occurred? ... see below for possible variables to set
		-- maybe this issue? (if errCodeTableOut.code == 4)?
		-- or perhaps should check this before even calling the recursive impl for the component!!!
		--componentMismatchWithOriginalPrefix = true
		--componentMismatchWithOriginalPrefixName = ""		
	end
		
		-- find all property references to other types, deep copy those too
	if deepCopyReferencedTypesToo then
		logger:debug("Deep copying references for \"" .. originalTypeName .. "\".")
		for propIdx = 0, t:getNumProperties() - 1 do
			local typeStr = t:getPropertyTypeString(propIdx)
			
			-- individual UH references
			if typeStr == "UH" then
				logger:debug("Reference property \"" .. t:getPropertyName(propIdx) .. "\" should perhaps be deep copied.")
				local refUH = t:getPropertyValue(propIdx)
				if (refUH ~= UH_NONE) then
					logger:debug("Reference property \"" .. t:getPropertyName(propIdx) .. "\" is set to a UH value.")
					if (typeManager:isType(refUH)) then
						local refT = typeManager:getTypeByUH(refUH)
						if (refT ~= nil) then
							-- ok, we got the referred type, now ensure it isn't a cyclic reference
							local refTypeName = refT:getName()
							logger:debug("Reference property \"" .. t:getPropertyName(propIdx) .. "\" refers to a type with name \"" .. refTypeName .. "\".")
							local refOk = true							
							if (refTypeName == originalTypeName) then
								refOk = false
								cyclicReferences = true; -- self reference?
								logger:debug("Cyclic type reference encountered.")
							end							
							for chki=1,#deepCopyTypeImplList do
								if (refTypeName == deepCopyTypeImplList[chki]) then
									refOk = false
									cyclicReferences = true; -- reference to one of the types already listed
									logger:debug("Cyclic type reference encountered.")
								end							
							end
							if (refOk) then
								local compOk = deepCopyTypeListRelatedToCopyImpl(errCodeTableOut, refTypeName, originalTypeNamePrefix, newTypeNamePrefix, deepCopyReferencedTypesToo, requireCorrectPrefix)			
								-- TODO: if not compOk then ... some error occurred? ... see below for possible variables to set								
							end
						else
							logger:error("Encountered a UH reference to a type, but that type did not exist. Deep copy type fails to copy the referred type.");
						end
					end
				end
			end
				
			-- UH array references
			if typeStr == "UHPropertyArray" then
				logger:debug("Reference property array \"" .. t:getPropertyName(propIdx) .. "\" should perhaps be deep copied.")
				local refUHArray = t:getPropertyValue(propIdx)
				for arrIdx = 0,refUHArray:getSize() - 1 do
					local refUH = refUHArray:get(arrIdx)
					if (refUH ~= UH_NONE) then
						logger:debug("Reference property array \"" .. t:getPropertyName(propIdx) .. "\" index " .. tostring(arrIdx) .. " is set to a UH value.")
						if (typeManager:isType(refUH)) then
							local refT = typeManager:getTypeByUH(refUH)
							if (refT ~= nil) then
								-- ok, we got the referred type, now ensure it isn't a cyclic reference
								local refTypeName = refT:getName()
								logger:debug("Reference property \"" .. t:getPropertyName(propIdx) .. "\" index " .. tostring(arrIdx) .. " refers to a type with name \"" .. refTypeName .. "\".")
								local refOk = true							
								if (refTypeName == originalTypeName) then
									refOk = false
									cyclicReferences = true; -- self reference?
									logger:debug("Cyclic type reference encountered.")
								end							
								for chki=1,#deepCopyTypeImplList do
									if (refTypeName == deepCopyTypeImplList[chki]) then
										refOk = false
										cyclicReferences = true; -- reference to one of the types already listed
										logger:debug("Cyclic type reference encountered.")
									end							
								end
								if (refOk) then
									local compOk = deepCopyTypeListRelatedToCopyImpl(errCodeTableOut, refTypeName, originalTypeNamePrefix, newTypeNamePrefix, deepCopyReferencedTypesToo, requireCorrectPrefix)			
									-- TODO: if not compOk then ... some error occurred? ... see below for possible variables to set								
								end
							else
								logger:error("Encountered a UH reference to a type, but that type did not exist. Deep copy type fails to copy the referred type.");
							end
						end
					end				
				end
			end
			
		end

		-- in case of error...
		-- maybe this issue?
		--referenceMismatchWithOriginalPrefix = true
		--referenceMismatchWithOriginalPrefixName = ""			
	end
	
	table.insert(deepCopyTypeImplList, originalTypeName)
	
	if referenceMismatchWithOriginalPrefix then 		
		-- To ignore this issue call editor.ExternalUI.deepCopyTypeIgnoreErrors() and retry (Warning, ignoring these errors may cause unexpected and excessive type tree cloning!)
		local msg = "Cannot perform deepCopyType for \""..originalTypeName.."\" because it has a reference to the type \""..referenceMismatchWithOriginalPrefixName.."\", which not follow the expected type naming convention. The reference may have been manually added ignoring the relevant type naming convention."
		errCodeTableOut.code = 1
		errCodeTableOut.msg = msg
		return false
	end
	
	if componentMismatchWithOriginalPrefix then 		
		-- To ignore this issue call editor.ExternalUI.deepCopyTypeIgnoreErrors() and retry (Warning, ignoring these errors may cause unexpected and excessive type tree cloning!)
		local msg = "Cannot perform deepCopyType for \""..originalTypeName.."\" because it has the component \""..componentMismatchWithOriginalPrefixName.."\", which not follow the expected type naming convention. The component may have been manually added ignoring the relevant naming convention."
		errCodeTableOut.code = 2
		errCodeTableOut.msg = msg
		return false
	end
	
	if cyclicReferences then 		
		local msg = "Cannot perform deepCopyType for \""..originalTypeName.."\" because it has cyclic type references."
		errCodeTableOut.code = 3
		errCodeTableOut.msg = msg
		return false
	end

	-- return true to indicate successful iteration (no cyclic references detected or other naming issues)
	return true
end


local g_startInheritingTypeOper = nil;
function startInheritingTypeImpl(type, instanceGUIDstring, componentTypeToReplaceGuidId, suggestedTypeName)
	if type and type:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) then
		-- TODO: some checks whether inheriting is allowed?
		local baseTypeName = type:getName()
		externalUI:sendUICommand("typeCreateStart(\"" .. baseTypeName .. "\", \"" .. instanceGUIDstring .. "\", \"" .. componentTypeToReplaceGuidId .. "\", \"" .. suggestedTypeName .. "\")")
	else
		sendGameLogMessageToExternalUI("Failed to inherit type.", 1)
	end
end


function startInheritingTypeFromType(baseTypeId)
	local type = getObjectByEditorObjectId(baseTypeId);
	if type then
		startInheritingTypeImpl(type, "", "", type:getName());
	else
		logger:error("external_ui:startInheritingTypeFromType - No such Type found with given baseTypeId.");
	end
end


function startInheritingTypeFromTypeToReplaceComponentType(baseTypeId, componentTypeToReplaceGuidId)
	local type = getObjectByEditorObjectId(baseTypeId);
	if type then
		local parentType = getObjectByEditorObjectId(componentTypeToReplaceGuidId);
		if parentType then
			local suggestedName = parentType:getName() .. type:getBaseTypeName();
			startInheritingTypeImpl(type, "", componentTypeToReplaceGuidId, suggestedName);
		else
			logger:error("external_ui:startInheritingTypeFromType - No such Type found with given componentTypeToReplaceGuidId.");
		end
	else
		logger:error("external_ui:startInheritingTypeFromType - No such Type found with given baseTypeId.");
	end
end


function startInheritingTypeFromInstance(guid)
	local instance = getInstanceByGUID(guid);
	if instance then
		local type = getTypeByUH(instance:getType());
		if type then
			startInheritingTypeImpl(type, tostring(guid), "", instance:getName());
		else
			logger:error("external_ui:startInheritingTypeFromInstance - No Type found for instance.");
		end
	else
		logger:error("external_ui:startInheritingTypeFromInstance - No such instance found with given GUID.");
	end
end


function startPrefabCreation(returnFunction, typeName, guidStr)
	local type = typeManager:findTypeByName(typeName)
	if type and type:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) then
		local baseTypeName = type:getName()
		externalUI:sendUICommand(returnFunction .. "(\"" .. baseTypeName .. "\", \"" .. guidStr .. "\")")
	else
		logger:error("external_ui:startPrefabCreation - Base Type not found")
	end
end

function startPrefabRename(guidStr)
	local foundCount = 0
	local foundNames = ""
	local numSelectedTypes = state:getNumSelectedTypes();
	if numSelectedTypes > 1 then
		for i = 0, numSelectedTypes - 1 do
			local type = state:getSelectedType(i)
			if type and type:doesInheritTypeByName("PrefabEntity") and type:getName() ~= "PrefabEntity" then
				if foundCount > 0 then foundNames = foundNames .. "|" end
				foundNames = foundNames .. type:getName()
				foundCount = foundCount + 1
			end
		end
	else
		local guid = getGUIDFromGUIDString(guidStr)
		local prefabType = typeManager:findTypeByGUID(guid)
		if prefabType and prefabType:doesInheritTypeByName("PrefabEntity") and prefabType:getName() ~= "PrefabEntity" then
			foundNames = prefabType:getName()
			foundCount = 1
		end
	end

	if foundCount == 0 then
		logger:error("external_ui:startPrefabRename - Couldn't find valid types")
		return
	end
	
	local isReplaceMode = (foundCount > 1)
	externalUI:sendUICommand("typePrefabRenameStart(\"" .. foundNames .. "\", \"" .. tostring(isReplaceMode) .. "\")")
end

function typeNameCheck(typeName, returnFunctionSuccess, returnFunctionFail)
	if(typeManager:findTypeByName(typeName) == nil) then
		externalUI:sendUICommand(returnFunctionSuccess .. "()");
	else
		logger:error("external_ui:typeNameCheck - TypeName already exists.")
		externalUI:sendUICommand(returnFunctionFail .. "()");
	end
end


function startDeletingType(typeId, interfaceComplexity)
	local typ = getObjectByEditorObjectId(typeId)
	if typ and typ:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) then
		local typeName = typ:getName()
		local numberOfReferences = typ:getNumObjectReferences()
		local numExclusiveComponents = typeManager:getNumExclusiveComponentTypes(typ);		
		externalUI:sendUICommand("typeDeleteFinish(\"" .. typeId .. "\", \"" .. typeName .. "\", \"" .. numberOfReferences .. "\", \"" .. interfaceComplexity .. "\", \"" .. numExclusiveComponents .. "\")")
	else
		sendGameLogMessageToExternalUI("Cannot delete, not a type " .. typeId, 1)
	end
end

function canReplaceComponentType(baseTypeName, componentTypeToReplaceGuidId)
	local oldType = typeManager:findTypeByName(baseTypeName)
	if not oldType then
		sendGameLogMessageToExternalUI("ExternalUI.canReplaceComponentType(): Cannot find base type by name '" .. baseTypeName:getName() .. "'", 1)
		externalUI:sendUICommand("typeCreateFail()")
		return false
	else
		local typToReplaceFrom = getObjectByEditorObjectId(componentTypeToReplaceGuidId)
		if typToReplaceFrom and typToReplaceFrom:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) then
			if typToReplaceFrom:findComponentType(oldType:getUnifiedHandle()) then
				return true;
			else
				sendGameLogMessageToExternalUI("ExternalUI.canReplaceComponentType(): Cannot find component type '" .. oldType:getName() .. "' to replace from type '" .. typToReplaceFrom:getName() .. "'", 1);
				externalUI:sendUICommand("typeCreateFail()")
				return false
			end
		elseif typToReplaceFrom and typToReplaceFrom:isInherited(engine.base.InstanceBase.getStaticObjectClass()) then
			if typToReplaceFrom:findComponentByExactType(oldType:getUnifiedHandle()) then
				return true;
			else
				sendGameLogMessageToExternalUI("ExternalUI.canReplaceComponentType(): Cannot find component type '" .. oldType:getName() .. "' to replace from type '" .. typToReplaceFrom:getName() .. "'", 1);
				externalUI:sendUICommand("typeCreateFail()")
				return false
			end
		else
			sendGameLogMessageToExternalUI("ExternalUI.canReplaceComponentType(): Cannot find type to replace component type from", 1);
			externalUI:sendUICommand("typeCreateFail()")			
			return false
		end
	end
	sendGameLogMessageToExternalUI("ExternalUI.canReplaceComponentType(): this should never happen (should fail before)", 1);
	externalUI:sendUICommand("typeCreateFail()")
	return false
end

function replaceComponentType(baseTypeName, componentTypeToReplaceGuidId, newComponentType, undoMultiOper)
	local oldType = typeManager:findTypeByName(baseTypeName)
	if not oldType then
		sendGameLogMessageToExternalUI("Cannot find base type by name '" .. baseTypeName:getName() .. "'", 1)
		externalUI:sendUICommand("typeCreateFail()")
		return false
	else
		local typToReplaceFrom = getObjectByEditorObjectId(componentTypeToReplaceGuidId)
		if typToReplaceFrom and typToReplaceFrom:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) then
			if typToReplaceFrom:findComponentType(oldType:getUnifiedHandle()) then
				if newComponentType then
					if newComponentType:isAbstractType() then
						sendGameLogMessageToExternalUI("New component type '" .. newComponentType:getName() .. "' is abstract, cannot add it.", 1);
						externalUI:sendUICommand("typeCreateFail()")
						return false;
					end
					-- all good
					local oldVal = typeManager:getTypeComponentDependencyChecking();
					typeManager:setTypeComponentDependencyChecking(false);
					typToReplaceFrom:removeComponentType(oldType:getUnifiedHandle());
					typToReplaceFrom:addComponentType(newComponentType:getUnifiedHandle());
					typeManager:setTypeComponentDependencyChecking(oldVal);
					return true;
				else
					sendGameLogMessageToExternalUI("ExternalUI.replaceComponentType(): newComponentType is nil", 1);
					externalUI:sendUICommand("typeCreateFail()");
					return false;
				end
			else
				sendGameLogMessageToExternalUI("Cannot find component type '" .. oldType:getName() .. "' to replace from type '" .. typToReplaceFrom:getName() .. "'", 1);
				externalUI:sendUICommand("typeCreateFail()")
				return false
			end
		elseif typToReplaceFrom and typToReplaceFrom:isInherited(engine.base.InstanceBase.getStaticObjectClass()) then
			if typToReplaceFrom:findComponentByExactType(oldType:getUnifiedHandle()) then
				if newComponentType then
					if newComponentType:isAbstractType() then
						sendGameLogMessageToExternalUI("New component type '" .. newComponentType:getName() .. "' is abstract, cannot add it.", 1);
						externalUI:sendUICommand("typeCreateFail()")
						return false;
					end
					-- all good
					local oldVal = typeManager:getTypeComponentDependencyChecking();
					typeManager:setTypeComponentDependencyChecking(false);
					local oldComp = typToReplaceFrom:findComponentByExactType(oldType:getUnifiedHandle())

					if undoMultiOper then
						local oper = createDeleteOperation(scene, typeManager);
						oper:saveObject(oldComp);
						undoMultiOper:add(oper);
					end

					local params = {}
					typToReplaceFrom:getInstanceManager():deleteInstanceInstantly(oldComp:getUnifiedHandle())
					typToReplaceFrom:getInstanceManager():createNewComponent(newComponentType:getUnifiedHandle(), typToReplaceFrom, function(obj, params) params.obj = obj end, params);

					if undoMultiOper then
						local oper = createInsertOperation(scene, typeManager);
						oper:saveObject(params.obj);
						undoMultiOper:add(oper);
					end

					typeManager:setTypeComponentDependencyChecking(oldVal);
					return true;
				else
					sendGameLogMessageToExternalUI("ExternalUI.replaceComponentType(): newComponentType is nil", 1);
					externalUI:sendUICommand("typeCreateFail()");
					return false;
				end
			else
				sendGameLogMessageToExternalUI("Cannot find component type '" .. oldType:getName() .. "' to replace from type '" .. typToReplaceFrom:getName() .. "'", 1);
				externalUI:sendUICommand("typeCreateFail()")
				return false
			end
		else
			sendGameLogMessageToExternalUI("Cannot find type to replace component type from", 1);
			externalUI:sendUICommand("typeCreateFail()")
			return false
		end
	end
	sendGameLogMessageToExternalUI("ExternalUI.replaceComponentType(): this should never happen (should fail before)", 1);
	externalUI:sendUICommand("typeCreateFail()")
	return false
end


function finishTypeCreation(typeScript, typeName, baseTypeName, componentTypeToReplaceGuidId)
	local newTyp = typeManager:findTypeByName(typeName);
	if newTyp == nil then
		logger:error("external_ui:finishTypeCreation - newTyp is nil. Cannot find type with name: " .. tostring(typeName));
	end
	
	if(#componentTypeToReplaceGuidId > 0) then
		replaceComponentType(baseTypeName, componentTypeToReplaceGuidId, newTyp, g_startInheritingTypeOper);
	end
	typeManager:setTypeScript(newTyp, typeScript);

	if g_startInheritingTypeOper then
		if g_startInheritingTypeOper:getOperationCount() > 0 then
			state:addUndoOperation(g_startInheritingTypeOper);
		else
			g_startInheritingTypeOper:release();
		end
		g_startInheritingTypeOper = nil;
	end
	
	if newTyp and newTyp:doesInheritTypeByName("BaseWidget") then
		syncGUI3TreeRoot("GUIExplorer")
	end
end


function cancelTypeCreation(typeName, baseTypeName, componentTypeToReplaceGuidId)
	local existingType = typeManager:findTypeByName(typeName)
	if(existingType ~= nil) then
		typeManager:deleteType(existingType)
	end
end


function tryToInheritType(newName, baseTypeName, componentTypeToReplaceGuidId, instanceGUIDString)

	-- check that component type to replace is valid
	if(#componentTypeToReplaceGuidId > 0) then
		if not canReplaceComponentType(baseTypeName, componentTypeToReplaceGuidId)
		then
			return
		end
	end

	-- check for type with conflicting name
	local existingType = typeManager:findTypeByName(newName)
	if(existingType) then
		sendGameLogMessageToExternalUI("Cannot create new type with name '" .. existingType:getName() .. "', one already exists", 1)
		externalUI:sendUICommand("typeCreateFail()")
	else
		local newTyp = typeManager:inheritNewType(newName, baseTypeName)
		if(newTyp) then
			-- Clear abstract flags
			newTyp:setAbstractType(false)
			newTyp:setGameAbstractType(false)
			
			-- If type is created from an instance, apply instance properties to the newType
			if string.len(instanceGUIDString) > 0 then
				local instGuid = getGUIDFromGUIDString(instanceGUIDString);
				local instance = getInstanceByGUID(instGuid);
				if instance then			
					local instanceType = typeManager:getTypeByUH(instance:getType());
					
					local setProperties = false;
					if instanceType and newTyp:doesInheritTypeByName(instanceType:getName()) then
						setProperties = true;
					else
						local instanceBaseType = typeManager:findTypeByName(baseTypeName);
						if instanceBaseType then
							local instanceComp = findInstanceComponentByTypeUH(instance, instanceBaseType:getUnifiedHandle());
							if instanceComp then
								instance = instanceComp;
								setProperties = true;
							end
						end
					end
					
					if setProperties and instance ~= nil then
						newTyp:assignTypeInstancePropertiesFromInstance(instance);
					else
						logger:error("external_ui:tryToInheritType - Cannot set instance properties to new Type, instance type is different.");
					end			
				else
					logger:error("external_ui:tryToInheritType - Cannot set instance properties to new Type, instance cannot be found.")
				end
			end

			typeManager:determineTypeScript(newTyp, nil)
			if(#componentTypeToReplaceGuidId > 0)
			then
				local typToReplaceFrom = getObjectByEditorObjectId(componentTypeToReplaceGuidId)
				if typToReplaceFrom:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) then
					typeManager:determineTypeScript(newTyp, typToReplaceFrom)
				else
					local oldType = typeManager:getTypeByUH(typToReplaceFrom:getType())
					typeManager:determineTypeScript(newTyp, oldType)
				end
			end
			
			local newTypeEntityGUIDString = "";
			if newTyp:doesInheritTypeByName("Entity") or newTyp:doesInheritTypeByName("BaseWidget")	then
				newTypeEntityGUIDString = tostring(newTyp:getGuid());
			end

			if g_startInheritingTypeOper then
				logger:error("Last undo operation '" .. g_startInheritingTypeOper:getOperationName() .. "' with name '" .. g_startInheritingTypeOper:getName() .. "' was not pushed to the stack or released");
				g_startInheritingTypeOper:release();
			end
			g_startInheritingTypeOper = createMultiOperation();
			g_startInheritingTypeOper:setName("Type Inherited");

			local oper = createInsertOperation(scene, typeManager);
			oper:saveObject(newTyp)
			g_startInheritingTypeOper:add(oper);

			externalUI:sendUICommand("typeCreateSuccess(\"" .. newTyp:getTypeScript() .. "\", \"[" .. tostring(newTyp:getGuid()) .. "]\", \"" .. newTypeEntityGUIDString .. "\")")
		else
			-- failed for some other reason..
			sendGameLogMessageToExternalUI("Failed to inherit '" .. newName .. "' from '" .. baseTypeName .. "'", 1)
			externalUI:sendUICommand("typeCreateFail()")
		end
	end
end


function startComponentTypeAdd(typeId)
	local typ = getObjectByEditorObjectId(typeId)
	if typ and typ:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) then
		if(not (typ:doesInheritType(typeManager:findTypeByName("InstanceBase")) or 
				typ:doesInheritType(typeManager:findTypeByName("ComponentBase")) or
				typ:doesInheritType(typeManager:findTypeByName("AbstractParticleEffectType")) or 
				typ:doesInheritType(typeManager:findTypeByName("AbstractGameplayEffectType")) or
				typ:doesInheritType(typeManager:findTypeByName("AbstractManagerInstance"))
		)) then
			sendGameLogMessageToExternalUI("Cannot add components to '" .. typ:getName() .. "', does not inherit from InstanceBase, ComponentBase, AbstractParticleEffectType or AbstractGameplayEffectType", 1);
			-- NOTE: Why this is commented out? Should be proper return (Though not gonna break this now by enabling it again)
			--return
		end
		externalUI:sendUICommand("componentTypeAddStart(\"" .. typeId .. "\")");
	end
end


-- Add and inherit works by first adding, then modifying added componentType in place. If user 
-- presses cancel, added componentType must be removed.
function cancelAddAndInherit(typeId, componentTypeId)
	local typ = getObjectByEditorObjectId(typeId)
	local componentTyp = getObjectByEditorObjectId(componentTypeId)
	if (not componentTyp) or (not typ) then
		sendGameLogMessageToExternalUI("Canceling add and inherit failed", 1);
		return
	end
	if not typ:removeComponentType(componentTyp:getUnifiedHandle()) then
		sendGameLogMessageToExternalUI("Canceling add and inherit failed. Could not remove component type", 1);
	end
end

function switchedToGame()
	-- Called when switched from editor state to game state for real
	
	-- Start mission music
	gameplay.MusicUtil.startCurrentMissionMusic()
end

function switchedToEditor()
	-- Called when switched from game state to editor state for real
	
	-- HACK: Need to reset this that we are sure that debug texts gets rendered (many editor feature relies on this)
	if renderingModule ~= nil then
		renderingModule:setShowDebugText(true);
	end
end

function tryToAddComponentType(typeOrInstanceId, componentTypeId, inheritAndAdd, typeOrInstanceOpt, componentTypeOpt, dontAnnounceSuccess)
	local typOrInst = typeOrInstanceOpt or getObjectByEditorObjectId(typeOrInstanceId)
	local componentTyp = componentTypeOpt or getObjectByEditorObjectId(componentTypeId)
	if((not componentTyp) or (not typOrInst)) then
		sendGameLogMessageToExternalUI("Adding component type failed", 1);
		externalUI:sendUICommand("componentTypeAddFail()");
		return
	end

	local isCPlusPlusAbstract = false;
	-- NOTE: Allow C++ types also (Also this check is a hacky check, inherited type might contain abstract keyword)
	--local lowerCaseComponentTyp = string.lower(componentTyp:getName());
	--if string.sub(lowerCaseComponentTyp, 1, 8) == "abstract" then
	--	isCPlusPlusAbstract = true;
	--end
	
	-- Never allow isCPlusPlusAbstract
	local isAbstract = false;
	if inheritAndAdd then
		-- Allow abstract flag if we are inheriting and adding the new type
		isAbstract = isCPlusPlusAbstract;
	else
		isAbstract = isCPlusPlusAbstract or componentTyp:isAbstractType();
	end

	if isAbstract then
		sendGameLogMessageToExternalUI("Cannot add abstract type '" .. componentTyp:getName() .. "' as component", 1);
		externalUI:sendUICommand("componentTypeAddFail()");
		return
	end

	if(not componentTyp:doesInheritType(typeManager:findTypeByName("ComponentBase"))) then
		sendGameLogMessageToExternalUI("Cannot add '" .. componentTyp:getName() .. "' as component, does not inherit from ComponentBase", 1);
		externalUI:sendUICommand("componentTypeAddFail()");
		return
	end
	
	if(typOrInst:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass())) then
		local typ = typOrInst
		
		if((not inheritAndAdd) and typ:findComponentType(componentTyp:getUnifiedHandle()))
		then
			sendGameLogMessageToExternalUI("Cannot add '" .. componentTyp:getName() .. "', it already exists", 1);
			externalUI:sendUICommand("componentTypeAddFail()");
			return
		end
		
		if(inheritAndAdd and typ:findComponentType(componentTyp:getUnifiedHandle()))
		then
			sendGameLogMessageToExternalUI("Cannot add and inherit from '" .. componentTyp:getName() .. "', since it is already present in " .. typ:getName(), 1);
			externalUI:sendUICommand("componentTypeAddFail()");
			return
		end

		local oper = undoTypeComponentAdd(typ, componentTyp);
		oper:setName("Component Added to Type");
		typ:addComponentType(componentTyp:getUnifiedHandle());
		state:addUndoOperation(oper);
	else
		local inst = typOrInst
		local params = {}
		inst:getInstanceManager():createNewComponent(componentTyp:getUnifiedHandle(), inst, function(obj, params) params.obj = obj; end, params);

		if(not params.obj) then
			sendGameLogMessageToExternalUI("Failed to create component from " .. componentTyp:getName(), 1);
			externalUI:sendUICommand("componentTypeAddFail()");
			return
		end

		local oper = createInsertOperation(scene, typeManager);
		oper:setName("Component Added to Entity");
		oper:saveObject(params.obj);
		state:addUndoOperation(oper);
	end
	
	if not dontAnnounceSuccess then
		externalUI:sendUICommand("componentTypeAddSuccess(\"" .. componentTyp:getName() .. "\", \"" .. typOrInst:getName() .. "\")");
	end
	return true
end


function addComponentTypeToSelectedInstances(componentTypeId)
	local numSelectedInstances = state:getNumSelected()
	local componentTyp = getObjectByEditorObjectId(componentTypeId)
	if not componentTyp then
		sendGameLogMessageToExternalUI("Adding component type failed", 1);
		externalUI:sendUICommand("componentTypeAddFail()");
		return
	end

	local infoStr = ""
	for i = 0, numSelectedInstances - 1 do
		local instance = state:getSelectedEntity(i)
		local lastInstanceToHandle = i == (numSelectedInstances - 1)
		if tryToAddComponentType("", componentTypeId, false, instance, componentTyp, not lastInstanceToHandle) then
			local name = instance:getName()
			local guidStr = "[ " .. tostring(instance:getGUID()) .. " ]"
			local instanceInfoStr = name ~= "" and (" " .. guidStr) or guidStr
			infoStr = infoStr .. instanceInfoStr .. ", "
		else
			local msg = "Failed to add component " .. componentTyp:getName() .. " to all selected instances. Component was added to " .. i .. " instances"
			if i > 0 then
				msg = msg .. ": " .. infoStr:sub(0, -3) .. "."
			else
				msg = msg .. "."
			end
			logger:error(msg)
			sendGameLogMessageToExternalUI(msg, 1);
			infoStr = infoStr .. "operation was not fully successful, "
			break
		end
	end
	infoStr = "Added component " .. componentTyp:getName() .. " to following instances: " .. infoStr
	logger:info(infoStr:sub(0, -3))
end


function addComponentTypeToSelectedTypes(componentTypeId)
	local numSelectedTypes = state:getNumSelectedTypes()
	local componentTyp = getObjectByEditorObjectId(componentTypeId)
	if not componentTyp then
		sendGameLogMessageToExternalUI("Adding component type failed", 1);
		externalUI:sendUICommand("componentTypeAddFail()");
		return
	end

	local infoStr = ""
	for i = 0, numSelectedTypes - 1 do
		local typ = state:getSelectedType(i)
		local lastTypeToHandle = i == (numSelectedTypes - 1)
		if tryToAddComponentType("", componentTypeId, false, typ, componentTyp, not lastTypeToHandle) then
			infoStr = infoStr .. typ:getName() .. ", "
		else
			local msg = "Failed to add component " .. componentTyp:getName() .. " to all selected types. Component was added to " .. i .. " types"
			if i > 0 then
				msg = msg .. ": " .. infoStr:sub(0, -3) .. "."
			else
				msg = msg .. "."
			end
			logger:error(msg)
			sendGameLogMessageToExternalUI(msg, 1);
			infoStr = infoStr .. "operation was not fully successful, "
			break
		end
	end
	infoStr = "Added component " .. componentTyp:getName() .. " to following types: " .. infoStr
	logger:info(infoStr:sub(0, -3))
end


local editorDeleteOperation = nil;
function startTypeDeletion()
	editorDeleteOperation = createDeleteOperation(gameScene, typeManager);
	editorDeleteOperation:setName("Type Deleted");
end


function stopTypeDeletion()
	if editorDeleteOperation:getObjectCount() > 0 then
		state:addUndoOperation(editorDeleteOperation);
	else
		editorDeleteOperation:release();
	end
end


function componentTypesDeleteCallback(state, index, componentType)
	if state == "start" then
		if editorDeleteOperation == nil then
			logger:error("Type deletion wasn't started!");
		end
	elseif state == "delete" then
		editorDeleteOperation:saveObject(componentType);
	elseif state == "end" then
	else
		logger:error("Unknown component deletion state in the callback function (undo-related).");
	end
end

function deleteTypeComponents(objId)
	local typ = getObjectByEditorObjectId(objId)
	if typ and typ:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) then
		typeManager:deleteExclusiveComponentTypesCallback(typ, componentTypesDeleteCallback)
	else
		sendGameLogMessageToExternalUI("Cannot delete type components: invalid object id", 1);
	end
end


function deleteType(objId)
	local typ = getObjectByEditorObjectId(objId)
	if typ and typ:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) then
		if typ:isStaticType() then
			sendGameLogMessageToExternalUI("Cannot delete static type '" .. typ:getName() .. "'", 1);
			return
		end
		editorDeleteOperation:saveObject(typ);
		state:runLuaFuncWithDelay(1, function() typeManager:deleteTypeAndScript(typ:getUnifiedHandle()) end);
	else
		sendGameLogMessageToExternalUI("Cannot delete type: invalid object id", 1);
	end
end


-- The super dangerous delete function!
-- deletes a type and ALL of its component types too
-- deletes ALL referred types as well if deleteReferredTypesToo is true (only if they have a single reference!)
-- WARNING: this will make no user confirmation popups about the delete, it will simply delete all of this stuff!!! 
-- (Any accidental references outside the intended types to delete may cause massive unintended loss of types!)
-- returns the number of types deleted
-- sanityCheckSubstringsOpt is a an optional table of strings, any type to get deleted must contain one of these substrings in their typename
-- if left to nil, then there is no sanity check, any type may get deleted! (with the exception of the TransformComponent :P)
function deepDeleteType(typeNameToDelete, deleteReferredTypesToo, sanityCheckSubstringsOpt)
	assert_string(typeNameToDelete)
	assert_boolean(deleteReferredTypesToo)
	assert_table_or_nil(sanityCheckSubstringsOpt)
	
	local typeObj = typeManager:findTypeByName(typeNameToDelete)
	local numTypesDeleted = 0
	if (typeObj ~= nil) then	
		numTypesDeleted = numTypesDeleted + deepDeleteTypeImpl(typeObj, deleteReferredTypesToo, sanityCheckSubstringsOpt)
	else
		logger:error("deepDeleteType failed, no type with the name \"" .. typeNameToDelete .. "\" exists.")
	end
	
	return numTypesDeleted
end

-- checks if the name string contains some of the substrings in the table
function doesMatchSubstringSanityCheck(name, substringsTable)
	assert_string(name)
	assert_table(substringsTable)
	for i=1,#substringsTable do
		if (string.find(name, substringsTable[i], 1, true)) then
			return true
		end
	end
	return false
end

function deepDeleteTypeImpl(typeObj, deleteReferredTypesToo, sanityCheckSubstringsOpt)
	--assert_type(typeObj)
	assert_boolean(deleteReferredTypesToo)
	
	local typeName = typeObj:getName()
	-- do the optional sanity check if given.
	if sanityCheckSubstringsOpt then
		if not doesMatchSubstringSanityCheck(typeName, sanityCheckSubstringsOpt) then
			logger:error("Type name \"".. typeName .."\" fails the deep delete name sanity check. Something may have gone badly wrong! Bailing out to prevent excessive deletion of types.")
			return 0
		end
	end
		
	local numTypesDeleted = 0
	local numCompTypes = typeObj:getNumComponentTypes()

	-- TODO: first, delete all referred types
	-- (loop through all the properties in typeObj, see which ones are UH or UHPropertyArray types, make a recursive call to all of the types pointed by those)
	if deleteReferredTypesToo then
		logger:debug("Deep deleting references for \"" .. typeName .. "\".")
		for propIdx = 0, typeObj:getNumProperties() - 1 do
			local typeStr = typeObj:getPropertyTypeString(propIdx)
			-- individual UH references
			if typeStr == "UH" then
				local propName = typeObj:getPropertyName(propIdx)
				logger:debug("Reference property \"" .. propName .. "\" should perhaps be deep copied.")
				local refUH = typeObj:getPropertyValue(propIdx)
				if refUH ~= UH_NONE then
					logger:debug("Reference property \"" .. propName .. "\" is set to a UH value.")
					if typeManager:isType(refUH) then
						-- Clear reference to deal with possible cyclic references
						typeObj:setPropertyValue(propIdx, UH_NONE)
						local refT = typeManager:getTypeByUH(refUH)
						-- Check for self-reference
						if refT ~= typeObj then
							if refT ~= nil then
								numTypesDeleted = numTypesDeleted + deepDeleteTypeImpl(refT, deleteReferredTypesToo, sanityCheckSubstringsOpt)
							else
								logger:error("Encountered a UH reference to a type, but that type did not exist.");
							end
						end
					end
				end
			end
				
			-- UH array references
			if typeStr == "UHPropertyArray" then
				local propName = typeObj:getPropertyName(propIdx)
				logger:debug("Reference property array \"" .. propName .. "\" should perhaps be deep copied.")
				local refUHArray = typeObj:getPropertyValue(propIdx)
				for arrIdx = 0, refUHArray:getSize() - 1 do
					local refUH = refUHArray:get(arrIdx)
					if refUH ~= UH_NONE then
						logger:debug("Reference property array \"" .. propName .. "\" index " .. tostring(arrIdx) .. " is set to a UH value.")
						if typeManager:isType(refUH) then
							-- Clear reference to deal with possible cyclic references
							refUHArray:set(arrIdx, UH_NONE)
							local refT = typeManager:getTypeByUH(refUH)
							-- Check for self-reference
							if refT ~= typeObj then
								if refT ~= nil then
									numTypesDeleted = numTypesDeleted + deepDeleteTypeImpl(refT, deleteReferredTypesToo, sanityCheckSubstringsOpt)
								else
									logger:error("Encountered a UH reference to a type, but that type did not exist.");
								end
							end
						end
					end				
				end
			end
			
		end
	end
	
	-- then list all component types
	local compTypeUHsToDelete = {}
	for cidx = 0, numCompTypes-1 do
		local typeChildCompUH = typeObj:getComponentType(cidx)
		if typeChildCompUH ~= UH_NONE then
				local typeChildComp = typeManager:getTypeByUH(typeChildCompUH)
				if typeChildComp ~= nil then
					local childCompName = typeChildComp:getName()
					if childCompName == "TransformComponent" then
						-- don't delete this :D
					else
						-- should perhaps not allow deletion of shared types? (because that seems a bit dangerous)						
						if not typeChildComp:isSharedComponentType() then
							table.insert(compTypeUHsToDelete, typeChildCompUH)
						else
							logger:warning("Leaving the shared component type \""..childCompName.."\" undeleted. If this component type should be deleted, clean it up manually.")
						end
					end			
				else
					logger:error("Failed to get type for: "..tostring(typeChildCompUH))
				end
		else
			logger:error("UH_NONE encountered as a component type. This should not happen.")
		end
	end
	-- then remove and delete the component types on the list
	for listi = 1, #compTypeUHsToDelete do
		local typeChildCompUH = compTypeUHsToDelete[listi]
		local typeChildComp = typeManager:getTypeByUH(typeChildCompUH)
		if typeChildComp ~= nil then
			typeObj:removeComponentType(typeChildCompUH)
			numTypesDeleted = numTypesDeleted + deepDeleteTypeImpl(typeChildComp, deleteReferredTypesToo, sanityCheckSubstringsOpt)
		else
			logger:error("Failed to get type for: "..tostring(typeChildCompUH))
		end
	end

	-- delete the type itself
	numTypesDeleted = numTypesDeleted + 1
	
	-- NOTE: This relies on runLuaFuncWithDelay executing being ordered (and the order being stable)
	-- All of these entries added there (within this single frame) are expected to be executed with that specific order.
	logger:debug("Deleting type "..tostring(typeObj:getName()))
	state:runLuaFuncWithDelay(1, function() typeManager:deleteTypeAndScript(typeObj:getUnifiedHandle()) end)
		
	return numTypesDeleted
end

function selectInstancesByFilter(multiLevelFilterString, makeSelected, ignoreSelectionFilter)
	stopInsertingType();

	local filterString = multiLevelFilterString
	local maxDepth = 99999 
	local forceParentsOfMatchesToMatch = false; 
	local root = instanceManager:getTopmostInstanceRoot() 
	local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilter(root, filterString, maxDepth, forceParentsOfMatchesToMatch) 
	local obj = resultIterator:next()  
	while (obj) do
		local allowSelection = false
		if (ignoreSelectionFilter) then
			allowSelection = true
		else
			allowSelection = filteringModule:doesNodeMatchMultiLevelFilter(obj, filteringModule:getSelectionFilterString())
		end
		
		if (allowSelection) then
			local selCom = obj:findComponent(editor.component.EditorSelectionComponent);
			if(obj.getFinalOwner and obj:getFinalOwner()) then
				selCom = obj:getFinalOwner():findComponent(editor.component.EditorSelectionComponent)
			end
			if(selCom) then
				selCom:setSelected(makeSelected);
			end		
		end
		obj = resultIterator:next()
	end
end


function selectAllInstances(objId)
	stopInsertingType();
	local typ = getObjectByEditorObjectId(objId)
	if typ and typ:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) then
		local i = 0;
		local inst = typ:getCreatedInstance(i);
		while not(inst == nil) do
			if (filteringModule:doesNodeMatchMultiLevelFilter(inst, filteringModule:getSelectionFilterString())) then
				local selCom = inst:findComponent(editor.component.EditorSelectionComponent);
				if(inst.getFinalOwner and inst:getFinalOwner()) then
					selCom = inst:getFinalOwner():findComponent(editor.component.EditorSelectionComponent)
				end
				if(selCom) then
					selCom:setSelected(true);
				end
			end

			i = i + 1;
			inst = typ:getCreatedInstance(i);
		end
	end
end


function deleteInstance(objId)
	local inst = getObjectByEditorObjectId(objId)
	if inst
		and inst:isInherited(engine.base.InstanceBase.getStaticObjectClass())
	then
		-- never delete dummy nodes
		if (not inst:isInherited(engine.instance.dummy.DummyNodeEntity.getStaticObjectClass())) then
			local oper = createDeleteOperation(gameScene, typeManager);
			oper:setName("Instance Deleted");
			oper:saveObject(inst);
			gameScene:getSceneInstanceManager():deleteInstance(inst:getUnifiedHandle());
			state:addUndoOperation(oper);
		end
	else
		sendGameLogMessageToExternalUI("Cannot delete instance: invalid object id", 1);
	end
end


function getDependencyListRecursively(listTable, comp)
	local list = ""
	if(listTable[comp])
	then
		return list
	end
	listTable[comp] = true;
	
	local iter = ComponentVectorIterator(comp:getOwner():getComponents());
	if not iter:hasInitFailed() then
		local instanceChildComp = iter:next()
		while not (instanceChildComp == nil) do
			if(instanceChildComp:hasDependency(comp, false))
			then
				list = list .. editor.Editor.getNameForDump(instanceChildComp) .. "," .. getDependencyListRecursively(listTable, instanceChildComp);
			end
			instanceChildComp = iter:next()
		end
	end
	return list
end

local deleteComponentOper = nil;
function deleteComponentAndDependenciesRecursively(comp)

	local iter = ComponentVectorIterator(comp:getOwner():getComponents());
	if not iter:hasInitFailed() then
		local instanceChildComp = iter:next()
		while not (instanceChildComp == nil) do
			if(instanceChildComp:hasDependency(comp, false))
			then
				deleteComponentAndDependenciesRecursively(instanceChildComp);
			end
			instanceChildComp = iter:next()
		end
	end

	deleteComponentOper:saveObject(comp);
	gameScene:getSceneInstanceManager():deleteInstance(comp:getUnifiedHandle());
end


function deleteComponentAndDependencies(objId)
	local comp = getObjectByEditorObjectId(objId)
	if comp and comp:isInherited(engine.base.ComponentBase.getStaticObjectClass()) then
		deleteComponentOper = createDeleteOperation(scene, typeManager);
		deleteComponentOper:setName("Component Deleted from Entity");

		deleteComponentAndDependenciesRecursively(comp)

		if deleteComponentOper:getObjectCount() > 0 then
			state:addUndoOperation(deleteComponentOper);
		else
			deleteComponentOper:release();
		end
		deleteComponentOper = nil;
	end
end


function deleteComponent(objId, ownerObjId)
	local comp = getObjectByEditorObjectId(objId)
	if comp and comp:isInherited(engine.base.ComponentBase.getStaticObjectClass()) then
		-- loop through all components and check for dependencies
		
		local dependencyListTable = {};
		local dependencyList = getDependencyListRecursively(dependencyListTable, comp);

		if(#dependencyList > 0)
		then
			externalUI:sendUICommand("confirmDeleteComponentAndDependencies(\"" .. objId .. "\", \"" .. editor.Editor.getNameForDump(comp) .. "\", \"" .. dependencyList .. "\")");
		else
			externalUI:sendUICommand("confirmDeleteComponent(\"" .. objId .. "\", \"" .. editor.Editor.getNameForDump(comp) .. "\")");
		end
	elseif comp and comp:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) and comp:doesInheritTypeByName("ComponentBase") then
		local owner = getObjectByEditorObjectId(ownerObjId)
		if owner and owner.removeComponentType then
			local oper = undoTypeComponentRemove(owner, comp);
			oper:setName("Remove Component from Type");
			owner:removeComponentType(comp:getUnifiedHandle())
			state:addUndoOperation(oper);
		else
			sendGameLogMessageToExternalUI("Cannot delete component: invalid owner object id", 1);
		end
	else
		sendGameLogMessageToExternalUI("Cannot delete component: invalid object id", 1);
	end
end


function suggestTypeFromModelResource(filename)
	local entityTypeName = editor.Util.convertTypeName(filename);

	local modelComponentTypeName = entityTypeName .. editor.Util.getTypeNamePostFix("ModelComponent");

	local outString = "suggestTypeFromModelResource(";

	outString = outString .. "\"Entity\", \"CheckAlways\", \"1\", \"" .. entityTypeName .. "\", \"Entity\"";
	outString = outString .. ", \"Model component\", \"CheckAlways\", \"1\", \"" .. modelComponentTypeName .. "\", \"ModelComponent\"";

	-- list all physics component types
	local physComponentBaseType = typeManager:getStaticDefaultType(physics.PhysicsComponent.getStaticClassId());
	local iter = ChildIterator(physComponentBaseType);
	local childType = iter:next();
	outString = outString .. ", \"Physics component\", \"\", \"" .. tostring(physComponentBaseType:getNumChildren()) .. "\"";
	while (not(childType == nil)) do
		local typeName = entityTypeName .. editor.Util.getTypeNamePostFix(childType:getName());
		outString = outString .. ", \"" .. typeName .. "\", \"" .. childType:getName() .. "\"";
		childType = iter:next();
	end

	-- list all hittable component types (not inherited!)
	local hittableComponentBaseType = typeManager:getStaticDefaultType(gameplay.hit.HittableComponent.getStaticClassId());
	local iter = ChildIterator(hittableComponentBaseType);
	local childType = iter:next();
	outString = outString .. ", \"Hittable component\", \"AddOnly\", \"" .. tostring(hittableComponentBaseType:getNumChildren()) .. "\"";
	while (not(childType == nil)) do
		outString = outString .. ", \"" .. childType:getName() .. "\", \"" .. childType:getName() .. "\"";
		childType = iter:next();
	end

	-- list breakable component
	outString = outString .. ", \"Breakable component\", \"NoDummyTypeHierarchy\", \"1\", \"" .. entityTypeName .. editor.Util.getTypeNamePostFix("BreakableComponent") .. "\", \"BreakableComponent\"";

	outString = outString .. ")";
	externalUI:sendUICommand(outString);
end


function startCreatingTypeFromModelResource(modelResId)
	local res = getObjectByEditorObjectId(modelResId);
	if res and res:isInherited(engine.base.resourcebase.ResourceBase.getStaticObjectClass()) and res:isInherited(rendering.ModelResource.getStaticObjectClass()) then
		local filename = res:getName();
		externalUI:sendUICommand("createTypeFromModelResource(\"" .. filename .. "\")");
 	else
		sendGameLogMessageToExternalUI("Cannot find resource: not a valid model resource id", 1);
	end
end


function startCreatingATSForResource(resourceId)
	local res = getObjectByEditorObjectId(resourceId);
	if res and res:isInherited(engine.base.resourcebase.ResourceBase.getStaticObjectClass()) then
		externalUI:sendUICommand("createAnimationTreeSetForFile(\"" .. set:getFilename() .. "\")");
 	else
		sendGameLogMessageToExternalUI("Cannot find resource: not a valid model resource id", 1);
	end
end


function createTypeCheckForExist(typeName)
	local result = "true";
	if(typeManager:findTypeByName(typeName) == nil) then
		result = "false";
	end
	externalUI:sendUICommand("createTypeExistResult(\"" .. editor.Util.escapeQuotesAndBackslashes(typeName) .. "\", \"" .. result .. "\")");
end


function createTypeFromModelResource(modelResName, typeNameList, silentFail)
	local separator = "/";

	local entityType = nil;
	local isLegacyType = false;
	local resource = resourceManager:findResourceByName(modelResName);

	local n = #typeNameList;
	local i = 1;


	-- Check for existing types
	while (i < n) do
		local flags = typeNameList[i+0]
		local newTypeName = typeNameList[i+1]
		local baseTypeName = typeNameList[i+2]
		i = i + 3;

		if not (string.find(flags,"AddOnly")) then
			-- Check full type name path, folder by folder if the type exists
			local existingType = nil;
			local newTypeNameFullPath = newTypeName;
			local plainFileName = editor.Util.getPlainFileName(newTypeNameFullPath, separator);
			local folderCount = editor.Util.getPathFolderCount(newTypeNameFullPath, separator);
			if (folderCount > 0) then
				existingType = typeManager:findTypeByName(plainFileName);
				if existingType ~= nil then
					while( existingType == nil ) do
						local strippedName = editor.Util.stripFilenameFromStart(newTypeNameFullPath, folderCount, separator);
						existingType = typeManager:findTypeByName(strippedName);
						folderCount = folderCount - 1;
						if(folderCount < 0) then
							break;
						end
					end
				end
			else
				existingType = typeManager:findTypeByName(newTypeName);
			end

			-- Check for type with conflicting name
			if (existingType) then
				if not silentFail then
					sendGameLogMessageToExternalUI("createTypeFromModelResource - Cannot create new type with name '" .. existingType:getName() .. "', one already exists.", 1);
					externalUI:sendUICommand("createNewTypeFailed()");
				end
				return false;
			end
		end
	end

	-- Now the actual type creations
	i = 1;
	while (i < n) do
		local flags = typeNameList[i+0]
		local newTypeName = typeNameList[i+1]
		local baseTypeName = typeNameList[i+2]
		i = i + 3;

		if (baseTypeName == "Entity") then
			-- special case hax: create entity
			if (newTypeName:len() > 0) then
				local parentTypeName = editor.Util.createDummyTypeHierarchy(newTypeName, "ObjectEntity", "", isLegacyType);
				entityType = editor.Util.getOrCreateType(newTypeName, parentTypeName, isLegacyType);
				if entityType then
					entityType:setAbstractType(false);
					entityType:setGameAbstractType(false);
					addRecentObjectImpl(entityType);
				end
			end
		else
			local compType = nil;

			if (string.find(flags,"AddOnly")) then
				-- add component
				compType = typeManager:findTypeByName(baseTypeName);
				if compType == nil then
					logger:error("createTypeFromModelResource - Failed to find component '" .. baseTypeName .. "' for AddOnly.");
				end
			elseif (string.find(flags,"NoDummyTypeHierarchy")) then
				-- inherit (normally)
				compType = typeManager:findTypeByName(newTypeName);
				if (not compType) then
					compType = typeManager:inheritNewType(newTypeName, baseTypeName);
					if compType then
						-- Clear abstract flags
						compType:setAbstractType(false);
						compType:setGameAbstractType(false);
						typeManager:setTypeScript(compType, "data/root/instance_base/entity/".. newTypeName ..".fbt");
					end
				else
					logger:info("createTypeFromModelResource - Component '" .. newTypeName .. "' already exists, using it.");
				end
				if compType == nil then
					logger:error("createTypeFromModelResource - Failed to inherit component '" .. newTypeName .. "' from '" .. baseTypeName .. "'");
				end
			else
				-- inherit with dummy type hierarchy
				local parentTypeName = editor.Util.createDummyTypeHierarchy(newTypeName, baseTypeName, editor.Util.getTypeNamePostFix(baseTypeName), isLegacyType);
				compType = editor.Util.getOrCreateType(newTypeName, parentTypeName, isLegacyType);
				if compType == nil then
					logger:error("createTypeFromModelResource - Failed to inherit component with hierarchy '" .. newTypeName .. "' from '" .. baseTypeName .. "'");
				else
					-- Clear abstract flags
					compType:setAbstractType(false);
					compType:setGameAbstractType(false);
				end
			end

			if compType ~= nil then
				if (entityType) then
					if compType:isAbstractType() then
						logger:error("createTypeFromModelResource - Failed to add component '" .. compType:getName() .. "' to the Entity, component type is abstract.");
					else
						entityType:addComponentType(compType:getUnifiedHandle());
					end
				else
					logger:error("createTypeFromModelResource - Failed to add component '" .. compType:getName() .. "' to the Entity, Entity doesn't exist (nil).");
				end

				addRecentObjectImpl(compType);

				-- Set model resource to model component
				local idx = compType:findPropertyIndexByName("Model");
				if (resource and idx >= 0) then
					compType:setPropertyValue(idx, resource:getUnifiedHandle());
				end
			end
		end
	end

	-- All ok?
	externalUI:sendUICommand("createNewTypeSucceeded()");
	return true
end


function startPicking(existingValue)
	if (state.setPickToolEnabled) then
		state:setPickToolEnabled(true);

		-- find existing object and select it
		state:clearSelection();
		if existingValue then
			local res = gameScene:getSceneInstanceManager():findInstanceByGUID(existingValue);
			if res then
				-- get entity
				if(res.getFinalOwner and res:getFinalOwner()) then
					res = res:getFinalOwner();
				end

				-- umm what is this start picking thing? is it supposed to use selection filtering or not?
				if (filteringModule:doesNodeMatchMultiLevelFilter(res, filteringModule:getSelectionFilterString())) then
					local selComponent = res:findComponent(editor.component.EditorSelectionComponent);
					if selComponent then
						selComponent:setSelected(true);
					end
				end
			end
		end
	end
end


function finishPicking()
	if (state.setPickToolEnabled) then
		state:setPickToolEnabled(false);
	end
	
	if(state.clearSelectionListSync) then
		state:clearSelectionListSync();
	end
end


function validateGUIDForProperty(propertyFlags, objectGUID)
	local acceptedReadableGuid = editor.Editor.getReadableGUIDString(objectGUID);
	if(objectGUID == GUID_NONE) then
		-- all good
		externalUI:sendUICommand("guidValidForProperty(\""..editor.Util.escapeQuotesAndBackslashes(tostring(objectGUID)).."\", \""..acceptedReadableGuid.."\")");
		return
	end

	-- find object
	local obj = gameScene:getSceneInstanceManager():findInstanceByGUID(objectGUID);
	if not obj then
		obj = typeManager:findTypeByGUID(objectGUID);
	end
	if not obj then
		obj = resourceManager:findResourceByGUID(objectGUID);
	end
	if not obj then
		sendGameLogMessageToExternalUI("Cannot find object with GUID "..objectGUID, 1);
	end

	-- EditorHint_MustInherit_xxx
	local mustInheritString = "EditorHint_MustInherit_";
	local mustInheritStringLength = mustInheritString:len();
	local s, e = string.find(propertyFlags, mustInheritString.."[%w]+");
	if(e and (e-s) > mustInheritStringLength) then
		local className = string.sub(propertyFlags, s+mustInheritStringLength, e);
		if(not obj:isInheritedByClassName(className)) then
			-- check if this has a matching component which we would be interested in
			local foundAlternative = false;

			if obj.findComponentByClassName then
				local obj2 = obj:findComponentByClassName(className);
				if(obj2) then
					acceptedReadableGuid = editor.Editor.getReadableGUIDString(obj2:getGuid());
					foundAlternative = true;
				end
			end

			if not foundAlternative then
				-- Check if we are dealing with a type
				if obj.doesInheritTypeByName and obj:doesInheritTypeByName(className) then
					foundAlternative = true
				end
			end
			if not foundAlternative then
				if obj.getClassName then
					sendGameLogMessageToExternalUI("Cannot use object of class '" .. obj:getClassName() .. "', does not inherit from '" .. className .. "'", 1);
				else
					sendGameLogMessageToExternalUI("Cannot use object, does not inherit from '" .. className .. "'", 1);
				end
				return;
			end
		end
	end
	-- all good
	externalUI:sendUICommand("guidValidForProperty(\""..editor.Util.escapeQuotesAndBackslashes(tostring(objectGUID)).."\", \""..acceptedReadableGuid.."\")");
end


function replaceResource(oldGuid, newGuid)
	resourceManager:replaceResource(oldGuid, newGuid);
end


function validateResourceReplacement(oldName, newGuid)
	if(newGuid == GUID_NONE) then
		externalUI:sendUICommand("resourceReplacementValid()");
		return;
	end

	local newRes = resourceManager:findResourceByGUID(newGuid);
	if newRes then
		local oldResClassId = resourceManager:getResourceClassByFilename(oldName);
		if(newRes:isInheritedByClassId(oldResClassId)) then
			externalUI:sendUICommand("resourceReplacementValid()");
		else
			externalUI:sendUICommand("resourceReplacementInvalid(\"Replacement type does not match: " .. newRes:getClassName() .. " does not inherit '" .. oldResClassId:getString() .. "'\")");
		end
	else
		externalUI:sendUICommand("resourceReplacementInvalid(\"Replacement is not a resource\")");
	end
end


function validateResourceRename(oldName, newName, textBoxIndex)
	local result = resourceManager:validateResourceRename(oldName, newName);
	externalUI:sendUICommand("resourceRenameValidateResult(\"" .. textBoxIndex .. "\", \"" .. result .. "\")");
end


function validateFbxResourceName(newName, textBoxIndex)
	local result = resourceManager:validateResourceRename("", newName);
	externalUI:sendUICommand("fbxResourceNameValidateResult(\"" .. textBoxIndex .. "\", \"" .. result .. "\")");
end


function renameResources(nameTable, indexTable)
	local resultTable = resourceManager:renameResources(nameTable);
	local i = 1;
	while(i+1 <= #resultTable) do
		if(resultTable[i+0]) then
			externalUI:sendUICommand("resourceRenameSucceeded(\"" .. indexTable[1 + math.floor((i-1)/2)] .. "\", \"" .. resultTable[i+1] .. "\")");
		else
			externalUI:sendUICommand("resourceRenameFailed(\"" .. indexTable[1 + math.floor((i-1)/2)] .. "\", \"" .. resultTable[i+1] .. "\")");
		end
		i = i + 2;
	end
end


function selectInstances(editorObjectIdTable)
	if(state.clearSelection) then
		state:clearSelection();
	end

	for i,editorObjectId in pairs(editorObjectIdTable) do
		local obj = getObjectByEditorObjectId(editorObjectId);
		if (obj and obj.findComponent) then
			if (filteringModule:doesNodeMatchMultiLevelFilter(obj, filteringModule:getSelectionFilterString())) then
				local selCom = obj:findComponent(editor.component.EditorSelectionComponent);
				if(selCom) then
					selCom:setSelected(true);
				end
			end
		end
	end

	if(state.clearSelectionListSync) then
		state:clearSelectionListSync();
	end
end


function selectTypes(editorObjectIdTable)
	local guidTable = {}
	for i,editorObjectId in pairs(editorObjectIdTable) do
		local obj = getObjectByEditorObjectId(editorObjectId);
		table.insert(guidTable, obj:getGuid())
	end
	if(state.setSelectedTypes)
	then
		state:setSelectedTypes(guidTable);
	end
end


function selectResources(editorObjectIdTable)
	local guidTable = {}
	for i,editorObjectId in pairs(editorObjectIdTable) do
		local obj = getObjectByEditorObjectId(editorObjectId);
		table.insert(guidTable, obj:getGuid())
	end
	if(state.setSelectedResources)
	then
		state:setSelectedResources(guidTable);
	end
end


function locateComponentType(guidId)
	local comp = getObjectByEditorObjectId(guidId)
	if comp and comp:isInherited(engine.base.ComponentBase.getStaticObjectClass()) then
		locateGUID( typeManager:getTypeByUH(comp:getType()):getGuid(), false );
	elseif comp and comp:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) and comp:doesInheritTypeByName("ComponentBase") then
		locateGUID( comp:getGuid(), false );
	end
end

allowMissingGuid = false
declareReload(thisModule, [[allowMissingGuid]])

function locateEditorObjectId(editorObjectId)
	local guidStr = getGuidByEditorObjectId(editorObjectId);
	if guidStr then
		locateGUIDString(guidStr)
	end
end

function getGUIDFromGUIDString(guidstring)
	local loadedFunction, errorMessage = loadstring("return " .. guidstring)
	if loadedFunction then
		local ok, output = pcall(loadedFunction)
		if ok then
			return output;
		else
			logger:error("external_ui:getGUIDFromGUIDString - Parsing GUID failed: " .. output)
		end
	else
		logger:error("external_ui:getGUIDFromGUIDString - Parsing GUID failed: " .. errorMessage)
	end
end

function locateGUIDString(guidstring, allowMissingOptional, withoutFocus)
	assert_string(guidstring)
	assert_boolean_or_nil(allowMissingOptional)
	
	if (allowMissingOptional) then
		allowMissingGuid = true
	end
	
	locateGUID(getGUIDFromGUIDString(guidstring), false, nil, withoutFocus);
	
	allowMissingGuid = false
end

function locateType(guid, expandSiblings)
	local obj = getObjectByGUID(guid);
	if obj then
		if obj:isInherited(engine.base.ComponentBase.getStaticObjectClass()) then
			obj = obj:getFinalOwner();
		end

		if obj:isInherited(engine.base.InstanceBase.getStaticObjectClass()) then
			local refobj = typeManager:getTypeByUH( obj:getType() );
			if refobj then
				locateGUID(refobj:getGuid(), expandSiblings);
			end
		end
	end
end

function locateTypeByName(typeName)
	local obj = typeManager:findTypeByName(typeName)
	if obj == nil then
		return
	end
	locateGUID(obj:getGuid(), true)
end

function findModelComponentTypeFromGUID(guid)
	if guid == nil then
		logger:error("findModelComponentFromGUID - nil guid parameter given.");
		return nil;
	end

	local instance = nil;
	local type = nil;

	if guid == GUID_NONE then
		return nil;
	end

	-- Is it an instance?
	if scene then
		if scene then
			instance = scene:getSceneInstanceManager():findInstanceByGUID(guid);
		else
			logger:error("findModelComponentFromGUID - scene is nil.");
		end
	else
		if gameScene then
			instance = gameScene:getSceneInstanceManager():findInstanceByGUID(guid);
		else
			logger:error("findModelComponentFromGUID - gameScene is nil.");
		end
	end

	-- Found an instance?
	if instance then
		local iter = instance:findAllComponents(engine.component.AbstractModelComponent);
		local modelComponent = iter:next()
		while modelComponent do
			local modelComponentType = typeManager:getTypeByUH(modelComponent:getType());
			if modelComponentType then
				return modelComponentType;
			end
			modelComponent = iter:next()
		end
	end

	-- Is it a type?
	type = typeManager:findTypeByGUID(guid);
	-- Found a type?
	if type then
		local iter = TypeComponentIterator(type);
		local childCompTypeUH = iter:next();
		local modelCompType = typeManager:findTypeByName("ModelComponent");
		while (not(childCompTypeUH == nil)) do
			local childCompType = typeManager:getTypeByUH(childCompTypeUH);
			if childCompType then
				--if childCompType:isInherited(engine.component.AbstractModelComponent.getStaticObjectClass()) then
				if childCompType:doesInheritType(modelCompType) then
					return childCompType;
				end
			end
			childCompTypeUH = iter:next();
		end
	end
	return nil;
end


function getModelResourceGUIDFromModelComponent(modelComponent)
	if modelComponent ~= nil then
		local idx = modelComponent:findPropertyIndexByName("Model");
		if idx >= 0 then
			local resourceUH = modelComponent:getPropertyValue(idx);
			if resourceUH ~= UH_NONE then
				if resourceManager then
					local resource = resourceManager:getResourceByUH(resourceUH);
					if resource then
						return resource:getGuid();
					end
				else
					logger:error("getModelResourceGUIDFromModelComponent - resourceManager is nil.");
				end
			end
		end
	else
		logger:error("getModelResourceGUIDFromModelComponent - nil param given.");
	end
	return GUID_NONE;
end


--------------------------------------------------------------------------------------
-- ModelComponent locating
function locateTypeModelComponent(guid)
	local modelComponentType = findModelComponentTypeFromGUID(guid);
	if modelComponentType then
		-- Enable "Locate ModelComponent" button
		externalUI:sendUICommand("locateTypeModelComponentSuccess(\"".. editor.Util.escapeQuotesAndBackslashes(tostring(modelComponentType:getGuid())) .. "\")");
	end
end


function locateTypeModelComponentError()
	logger:error("No ModelComponent found for type.");
end


function locateInstanceModelComponent(guid)
	local modelComponentType = findModelComponentTypeFromGUID(guid)
	if modelComponentType then
		-- Enable "Locate ModelComponent" button
		externalUI:sendUICommand("locateInstanceModelComponentSuccess(\"".. editor.Util.escapeQuotesAndBackslashes(tostring(modelComponentType:getGuid())) .. "\")")
	end
end

function getLightComponentGuidFromInstance(guidStr)
	local instance = gameScene:getSceneInstanceManager():findInstanceByGUID(guidStr)
	if instance then
		local lightComp = instance:findComponent(engine.component.AbstractLightComponent)
		if lightComp then
			-- Enable "Locate ModelComponent" button
			return lightComp:getGuid()
		end
	else
		logger:error("No instance found for " ..  guidStr)
	end
	return nil
end


function locateInstanceLightComponent(guidStr)
	local lightCompGuid = getLightComponentGuidFromInstance(guidStr)
	if lightCompGuid then
		-- Enable "Modify color" button
		externalUI:sendUICommand("locateInstanceLightComponentSuccess(\"".. editor.Util.escapeQuotesAndBackslashes(tostring(lightCompGuid)) .. "\")")
	else
		externalUI:sendUICommand("locateInstanceLightComponentSuccess(\"\")")
	end
end


function locateInstanceLightComponentAndExecuteModify(guidStr)
	local lightCompGuid = getLightComponentGuidFromInstance(guidStr)
	if lightCompGuid then
		externalUI:sendUICommand("locateInstanceLightComponentSuccessAndExecute(\"".. editor.Util.escapeQuotesAndBackslashes(tostring(lightCompGuid)) .. "\")")
	else
		-- Nop. User probably just pressed shortcut button with no light selected
	end	
end


function locateInstanceModelComponentError()
	logger:error("No ModelComponent found for instance.")
end


function getTimerComponentGuidFromInstance(guidStr)
	local instance = gameScene:getSceneInstanceManager():findInstanceByGUID(guidStr)
	if instance then
		local timerComp = instance:findComponent(engine.component.AbstractTimerComponent)
		if timerComp then
			return timerComp:getGuid()
		end
	else
		logger:error("No instance found for " ..  guidStr)
	end
	return nil
end


function locateInstanceTimerComponent(guidStr)
	local timerCompGuid = getTimerComponentGuidFromInstance(guidStr)
	if timerCompGuid then
		externalUI:sendUICommand("locateInstanceTimerComponentSuccess(\"".. editor.Util.escapeQuotesAndBackslashes(tostring(timerCompGuid)) .. "\")")
	else
		externalUI:sendUICommand("locateInstanceTimerComponentSuccess(\"\")")
	end
end
--------------------------------------------------------------------------------------
-- ModelResource locating

function locateTypeModelResource(guid)
	local modelComponentType = findModelComponentTypeFromGUID(guid);
	if modelComponentType then
		local modelResourceGUID = getModelResourceGUIDFromModelComponent(modelComponentType);
		if modelResourceGUID then
			externalUI:sendUICommand("locateTypeModelResourceSuccess(\"".. editor.Util.escapeQuotesAndBackslashes(tostring(modelResourceGUID)) .. "\")");
		end
	end
end


function locateTypeModelResourceError()
	logger:error("No ModelResource found for type.");
end


function locateInstanceModelResource(guid)
	local modelComponentType = findModelComponentTypeFromGUID(guid);
	if modelComponentType then
		local modelResourceGUID = getModelResourceGUIDFromModelComponent(modelComponentType);
		if modelResourceGUID ~= GUID_NONE then
			externalUI:sendUICommand("locateInstanceModelResourceSuccess(\"".. editor.Util.escapeQuotesAndBackslashes(tostring(modelResourceGUID)) .. "\")");
		end
	end
end


function locateInstanceModelResourceError()
	logger:error("No ModelResource found for instance.");
end


--------------------------------------------------------------------------------------

function moveCameraToShowPosition(pos)
	local obj = gameScene:getSceneInstanceManager():findInstanceByName("EditorCamera")
	if not obj then
		-- If EditorCamera cannot be found, try game camera
		obj = gameScene:getSceneInstanceManager():findInstanceByName("camera")
	end
	if obj then
		local trans = obj:findComponent(engine.component.TransformComponent)
		local posWithOffset = pos
		if engine.base.mathbase.GameDirections.cameraForwardVector:getDotWith(VC3(1,1,1)) then
			posWithOffset = posWithOffset - engine.base.mathbase.GameDirections.cameraForwardVector * 10
		else
			posWithOffset = posWithOffset + engine.base.mathbase.GameDirections.cameraForwardVector * 10
		end
		trans:setPosition(posWithOffset)
		--trans:setRotation(IdentityRotation)
		trans:setRotation(Rotation(0,0,0,1))
	else
		logger:warning("moveCameraToShowPosition - Failed to find camera to move to the position.")
	end
end


function locateGUID(guid, expandSiblings, explorerNumberOpt, withoutFocus)
	local obj = getObjectByGUID(guid);
	if obj then
		local locateNodeFunctionStr = "locateNode";
		if withoutFocus == true then
			locateNodeFunctionStr = "locateNodeWithoutFocus";
		elseif expandSiblings then
			locateNodeFunctionStr = "locateNodeExpandSiblings";
		end

		if obj:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) then
			if (explorerNumberOpt) then
				externalUI:sendUICommand(locateNodeFunctionStr .. "(\"TypeExplorer"..tostring(explorerNumberOpt).."\", \"" .. editor.Util.escapeQuotesAndBackslashes(tostring(guid)) .. "\")");
			else
				externalUI:sendUICommand(locateNodeFunctionStr .. "(\"TypeExplorer\", \"" .. editor.Util.escapeQuotesAndBackslashes(tostring(guid)) .. "\")");
			end
		end

		if obj:isInherited(engine.base.ComponentBase.getStaticObjectClass()) then
			logger:info("Component " .. obj:getDebugString() .. " found.")
			obj = obj:getFinalOwner();
			guid = obj:getGuid();
		end

		if obj:isInherited(gui.BaseWidget.getStaticObjectClass()) then
			externalUI:sendUICommand(locateNodeFunctionStr .. "(\"GUIExplorer\", \"".. editor.Util.escapeQuotesAndBackslashes(tostring(guid)) .. "\")");
		end

		if obj:isInherited(engine.base.InstanceBase.getStaticObjectClass()) then
			externalUI:sendUICommand(locateNodeFunctionStr .. "(\"SceneExplorer\", \"".. editor.Util.escapeQuotesAndBackslashes(tostring(guid)) .. "\")");

			-- TODO: If component guid, should open component properties in propertyGrid and possibly highlight the whole component

			local trans = obj:findComponent(engine.component.TransformComponent);
			if (trans) then
				local pos = trans:getPosition();
				moveCameraToShowPosition(pos);
			end
		end

		if obj:isInherited(engine.base.resourcebase.ResourceBase.getStaticObjectClass()) then
			externalUI:sendUICommand(locateNodeFunctionStr .. "(\"ResourceExplorer\", \"".. editor.Util.escapeQuotesAndBackslashes(tostring(guid)) .. "\")");
		end

		if obj:isInherited(engine.base.resourcebase.DummyResourceHolder.getStaticObjectClass()) then
			sendGameLogMessageToExternalUI(tostring(guid) .. " points to a non-existing resource " .. obj:getName(), 1);
		end
	else
		if (not(allowMissingGuid)) then
			sendGameLogMessageToExternalUI("No object with " .. tostring(guid) .. " exists", 1);
		else
			editorMessageBox("No object with " .. tostring(guid) .. " exists in the scene.\r\nIf this was a game mode object, it may have been created dynamically during the game and there is no matching object in the editor scene.", "The object with given guid does not exist.", "Info")
		end
	end
end


selectedObjectsForParenting = {}

function rememberSelectedObjectsForParenting()
	selectedObjectsForParenting = {}
	local n = state:getNumSelected();
	for i = 0,n-1 do
		local e = state:getSelectedEntity(i)
		if(e) then
			table.insert(selectedObjectsForParenting, e:getGuid())
		end
	end
end

function rememberHighestHierarchyObjectsForParenting()
	selectedObjectsForParenting = {}
	local entityList = {}
	local n = state:getNumSelected();
	for i = 0,n-1 do
		local e = state:getSelectedEntity(i)
		if(e) then
			table.insert(entityList, e)
		end
	end
	
	for i = 1, #entityList do
		local foundParent = false
		local e = entityList[i]
		local parentGuid = e:getParent():getGUID()
		for j = 1, #entityList do
			if i ~= j and parentGuid == entityList[j]:getGUID() then
				foundParent = true
				break
			end
		end
		if not foundParent then
			table.insert(selectedObjectsForParenting, e:getGuid())
		end
	end
end

local parentListForUndo = {};
function parentPreviouslySelectedObjects(guidTarget)
	for k,v in pairs(selectedObjectsForParenting) do
		parentObject(v, guidTarget)
	end

	if #parentListForUndo > 0 then
		local function onReverse(self)
			local list = self:get("list");
			for i, v in ipairs(list) do
				local parent = gameScene:getSceneInstanceManager():findInstanceByGUID(v.oldParent);
				local obj    = gameScene:getSceneInstanceManager():findInstanceByGUID(v.obj);
				if parent and obj then
					parent:addChild(obj);
				else
					local str = "";
					if obj == nil then str = str .. " Cannot find obj with GUID " .. tostring(v.obj) .. "."; end
					if parent == nil then str = str .. " Cannot find parent with GUID " .. tostring(v.oldParent) .. "."; end
					logger:error("Parenting undo failed:" .. str);
				end
			end
			return true;
		end

		local function onOperate(self)
			local list = self:get("list");
			for i, v in ipairs(list) do
				local parent = gameScene:getSceneInstanceManager():findInstanceByGUID(v.newParent);
				local obj    = gameScene:getSceneInstanceManager():findInstanceByGUID(v.obj);
				if parent and obj then
					parent:addChild(obj);
				else
					local str = "";
					if obj == nil then str = str .. " Cannot find obj with GUID " .. tostring(v.obj) .. "."; end
					if parent == nil then str = str .. " Cannot find parent with GUID " .. tostring(v.newParent) .. "."; end
					logger:error("Parenting redo failed:" .. str);
				end
			end
			return true;
		end

		local oper = createCustomLuaOperation(onReverse, onOperate, function() return true; end);
		oper:setName("Entity Parented");
		oper:set("list", parentListForUndo);
		state:addUndoOperation(oper);
	end

	parentListForUndo = {};
	selectedObjectsForParenting = {};
end


function parentObject(guidSource, guidTarget)
	local objSource = getObjectByGUID(guidSource);
	local objTarget = getObjectByGUID(guidTarget);
	if(objSource and objTarget) then
		if(objSource:isInherited(engine.instance.Entity.getStaticObjectClass())) then
			if(objTarget:isInherited(engine.instance.Entity.getStaticObjectClass()) or objTarget:isInherited(engine.state.scene.SceneBase.getStaticObjectClass())) then
				if(objTarget:canAddChild(objSource)) then
					local entry = {};
					if objSource:getParent():isInherited(engine.instance.dummy.DummyNodeEntity.getStaticObjectClass()) then
						entry.oldParent = GUID(gameScene:getGUID());
					else
						entry.oldParent = GUID(objSource:getParent():getGUID());
					end
					entry.newParent = GUID(objTarget:getGUID());
					entry.obj = GUID(objSource:getGUID());
					table.insert(parentListForUndo, entry);

					objTarget:addChild(objSource);
				else
					sendGameLogMessageToExternalUI("Parenting given objects not supported. This is usually caused by a PhysicsComponent in the child.", 1);
				end
			else
				sendGameLogMessageToExternalUI("Cannot parent objects, parent must be an entity or a scene", 1);
			end
		else
			sendGameLogMessageToExternalUI("Cannot parent objects, child must be an entity", 1);
		end
	else
		sendGameLogMessageToExternalUI("Cannot parent objects, at least one GUID is invalid", 1);
	end
end


function mouseEnter()
	if state.mouseEnter then
		state:mouseEnter();
	end
end


function mouseLeave()
	if state.mouseLeave then
		state:mouseLeave();
	end
end


function copyEntities()
	if state.copyEntities then
		local success = state:copyEntities();
	end
end


function cutEntities()
	if state.cutEntities then
		local success = state:cutEntities();
	end
end


function pasteEntities()
	if state.pasteEntities then
		local success = state:pasteEntities();
	end
end


function pasteEntitiesInPlace()
	if state.pasteEntitiesInPlace then
		local success = state:pasteEntitiesInPlace();
	end
end


function changeInstanceType(objectGuid, typeGuid)
	local obj = getObjectByGUID(objectGuid)
	if(obj == nil) then
		sendGameLogMessageToExternalUI("Failed change instance type, instance not found", 1);
		return
	end
	local typeObj = getObjectByGUID(typeGuid);
	if(typeObj == nil) then
		sendGameLogMessageToExternalUI("Failed change instance type, type not found", 1);
		return
	end
	if not(typeObj:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass())) then
		sendGameLogMessageToExternalUI("Failed change instance type, invalid type given", 1);
		return
	end
	if(not typeObj:doesInheritTypeByName("Entity") and not typeObj:doesInheritTypeByName("BaseWidget") ) then
		sendGameLogMessageToExternalUI("Failed change instance type, type must inherit from Entity or BaseWidget", 1);
		return
	end

	if typeObj:doesInheritTypeByName("Entity") then
		state:changeInstanceType(obj, typeObj);
	elseif typeObj:doesInheritTypeByName("BaseWidget") then
		if rootWidget ~= nil then
			rootWidget:swapWidgetToAWidgetOfSpecifiedType(obj, typeObj)
		else
			sendGameLogMessageToExternalUI("Tried to swapWidgetToAWidgetOfSpecifiedType, but rootWidget was NULL.", 1)
		end
	end
end


function verifyChangeTypeForSelectedInstances(editorObjectId)
	stopInsertingType();
	local ns = state:getNumSelected();
	if(ns == 0) then
		sendGameLogMessageToExternalUI("Cannot change type: no entities selected", 1);
		return
	end
	local obj = getObjectByEditorObjectId(editorObjectId);
	if obj then
		externalUI:sendUICommand("changeTypeForSelectedInstancesVerify(\"" .. ns .. "\", \"" .. obj:getName() .. "\")");
	end
end


function changeTypeForSelectedInstances(typName)
	stopInsertingType()
	informSelectionListChanged()
	local typ = typeManager:findTypeByName(typName)
	local n = state:getNumSelected();

	if n == 0 then
		return;
	end

	local oper;
	local multiOper = createMultiOperation();
	multiOper:setName("Instance Type Changed");

	oper = createDeleteOperation(gameScene, typeManager);
	for i = 0,n-1 do
		local e = state:getSelectedEntity(i)
		oper:saveObject(e);
	end
	multiOper:add(oper);

	state:changeSelectedInstanceTypes(typ)

	oper = createInsertOperation(gameScene, typeManager);
	for i = 0,n-1 do
		local e = state:getSelectedEntity(i)
		oper:saveObject(e);
	end
	multiOper:add(oper);

	state:addUndoOperation(multiOper);
end


function resetEntityScales()
	local n = state:getNumSelected();
	if n == 0 then
		return
	end

	local oper = createPropertyChangedOperation(scene:getSceneInstanceManager():getObjectManager());
	oper:setName("Entity Scale Reset");

	for i = 0,n-1 do
		local e = state:getSelectedEntity(i)
		local c = e:findComponent(engine.component.AbstractModelComponent);
		if(c) then
			oper:saveProperty(c, "Scale");
			c:setScale(VC3(1,1,1))
		end
	end

	if oper:getPropertyCount() > 0 then
		state:addUndoOperation(oper);
	else
		oper:release();
	end
end


function resetEntityRotations()
	local n = state:getNumSelected();
	if n == 0 then
		return
	end

	local oper = createPropertyChangedOperation(scene:getSceneInstanceManager():getObjectManager());
	oper:setName("Entity Rotation Reset");

	for i = 0,n-1 do
		local e = state:getSelectedEntity(i)
		local c = e:findComponent(engine.component.TransformComponent);
		oper:saveProperty(c, "Rotation");
		c:setRotation(QUAT());
	end

	if oper:getPropertyCount() > 0 then
		state:addUndoOperation(oper);
	else
		oper:release();
	end
end


function flipEntitiesAroundZ()
	local insertingEntity = state:getEntityBeingInserted(0)
	if insertingEntity then
		local i = 0
		while insertingEntity do
			local tc = insertingEntity:findComponent(engine.component.TransformComponent);
			tc:setRotation(tc:getRotation() * QUAT(0,0,math.pi * 0.5));
			i = i + 1;
			insertingEntity = state:getEntityBeingInserted(i);
		end
	else
		local oper = createPropertyChangedOperation(scene:getSceneInstanceManager():getObjectManager());
		oper:setName("Entity Flipped Around Z");
		local n = state:getNumSelected();
		for i = 0,n-1 do
			local e = state:getSelectedEntity(i)
			local tc = e:findComponent(engine.component.TransformComponent);
			oper:saveProperty(tc, "Rotation");
			tc:setRotation(tc:getRotation() * QUAT(0,0,math.pi * 0.5));
		end

		if oper:getPropertyCount() > 0 then
			state:addUndoOperation(oper);
		else
			oper:release();
		end
	end
end


function startComponentTypeCopy(editorObjectId)
		local str = ""
		local obj = getObjectByEditorObjectId(editorObjectId);
		if obj then
			local nc = obj:getNumComponentTypes();
			for i = 0,nc-1 do
				local compUH = obj:getComponentType(i);
				local comp = typeManager:getTypeByUH(compUH);
				if(i > 0) then
					str = str .. ","
				end
				str = str .. "\"" .. tostring(comp:getGuid()) .. "\",\"" .. comp:getName() .. "\"";
			end
		end

		externalUI:sendUICommand("copyComponentTypeGuids("..str..")");
end

function startComponentTypePaste(editorObjectId, guidArray)
	local obj = getObjectByEditorObjectId(editorObjectId);
	if obj then

		local str = "";
		for i,v in pairs(guidArray) do
			local comp = typeManager:findTypeByGUID(v);
			if not(comp == nil) then
				local conflict = "";

				-- check that doesn't already exist
				if(obj:findComponentType(comp:getUnifiedHandle())) then
					conflict = "(duplicate)"
				else

					-- get all conflicting components
					local j = 0;
					while (true) do
						-- conflicting types aren't checked when components are normally added, 
						-- thus everything is totally broken from that point of view. Just check 
						-- for duplicates here
--						local conflictComp = obj:getConflictingComponentType(comp:getUnifiedHandle(), j);
						local conflictComp = nil
						if(conflictComp) then
							if(j > 0) then
								conflict = conflict .. ", "
							end
							conflict = conflict .. conflictComp:getName()
						else
							break
						end

						j = j + 1;
					end

				end

				if(#str > 0) then
					str = str .. ","
				end
				str = str .. "\"" .. tostring(comp:getGuid()) .. "\",\"" .. comp:getName() .. "\",\"" .. conflict .."\"";

			end
		end

		externalUI:sendUICommand("populateComponentTypePasteList("..str..")");
	end
end


function checkAllComponentDependenciesRecursively(typeObj, tagErrors)
	if not typeObj then logger:error("ExternalUI, checkAllComponentDependenciesRecursively, typeObj is nil") return end
	typeObj:checkComponentDependencies(tagErrors)
	typeObj:checkSubComponentDependencies(tagErrors)
	for i = 0, typeObj:getNumChildren() - 1 do
		checkAllComponentDependenciesRecursively(typeObj:getChild(i), tagErrors)
	end
end


function doComponentTypePaste(editorObjectId, guidArray)
	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj) then
		local str = "";
		local originalTypeComponentDependencyChecking = typeManager:getTypeComponentDependencyChecking()
		typeManager:setTypeComponentDependencyChecking(false)
		for i,v in pairs(guidArray) do
			local comp = typeManager:findTypeByGUID(v);
			if not(comp == nil) then
				if (obj:findComponentType(comp:getUnifiedHandle())) then
					sendGameLogMessageToExternalUI("Failed to add ".. comp:getName() .. ", a duplicate already exists", 1);
					return
				end

				-- remove all conflicting ones
				while (true) do
					-- conflicting types aren't checked when components are normally added, thus 
					-- everything is totally broken from that point of view
--					local conflictComp = obj:getConflictingComponentType(comp:getUnifiedHandle(), 0);
					local conflictComp = nil
					if (conflictComp) then
						obj:removeComponentType(conflictComp:getUnifiedHandle())
					else
						break;
					end
				end

				if comp:isAbstractType() then
					logger:error("doComponentTypePaste - Failed to paste component '" .. comp:getName() .. "', component type is abstract.");
				else
					obj:addComponentType( comp:getUnifiedHandle() );
				end
			end
		end
		typeManager:setTypeComponentDependencyChecking(originalTypeComponentDependencyChecking)
		if originalTypeComponentDependencyChecking then typeManager:testAllTypeComponentDepencies() end
	end

	externalUI:sendUICommand("componentPasteSuccess()");
end


function getCameraPosition()
	local obj = gameScene:getSceneInstanceManager():findInstanceByName("EditorCamera")
	if not obj then obj = gameScene:getSceneInstanceManager():findInstanceByName("camera") end
	if obj then
		local trans = obj:findComponent(engine.component.TransformComponent)
		if trans then
			return trans:getPosition(), trans:getRotation()
		end
	else
		logger:error("getCameraPosition - Failed to find editor or game camera.")
	end
	return VC3(0,0,0), QUAT(0, 0, 0, 1)
end


function getCameraPositionProjectedOnGameplay()
	local obj = gameScene:getSceneInstanceManager():findInstanceByName("EditorCamera");
	if obj then
		local trans = obj:findComponent(engine.component.TransformComponent);

		if trans then
			local pos = trans:getPosition();
			local rot = trans:getRotation();
			local upvec = VC3(0,0,1); -- hack, assuming the game has this as camera up vec
			local forwardvec = VC3(0,-1,0); -- hack, assuming the game has this as camera forward vec
			local dir = rot:getRotated(forwardvec);
			local planeNormalVector = VC3(0,-1,0); -- scene depth vector
			local range = planeNormalVector:getDotWith(pos) - 0.0; -- project at 0 height
			local ret = pos - (planeNormalVector * range); -- remove plane normal direction component.

			return ret;
		end
	else
		logger:error("getCameraPositionProjectedOnGameplay - Failed to find editor camera.")
	end
	return VC3(0,0,0);
end

function castCollisionRay()
	local obj = gameScene:getSceneInstanceManager():findInstanceByName("EditorCamera");
	if obj then
		local trans = obj:findComponent(engine.component.TransformComponent);

		if trans then
			local pos = trans:getPosition();
			local rot = trans:getRotation();
			local dir = rot:getRotated(engine.base.mathbase.GameDirections.cameraForwardVector);
			local dist = state:getStartAtPosRayCastLength();
			
			local collisionPos = state:castCollisionRay(pos, dir, dist);
			
			return collisionPos;
		end
	else
		logger:error("castCollisionRay - Failed to find editor camera.")
	end
	return VC3(0,0,0);
end

function resolveStartAtPosition()
	--local camPos = getCameraPositionProjectedOnGameplay();
	local camPos = VC3(0,0,0);
	
	if state:getSpawnAtCameraPos() then
		camPos = getCameraPosition();
	else
		camPos = castCollisionRay();
	end
	
	local spawnPos = VC3(camPos.x, camPos.y, camPos.z);

	state:setInitialStartPosition(spawnPos);
end

function resolveStopAtPosition()
	local gameCamera = gameScene:getSceneInstanceManager():findInstanceByName("camera");

	if gameCamera == nil then
		logger:error("resolveStopAtPosition - Failed to find editor camera.");
		return;
	end

	gameCameraTransform = gameCamera:findComponent(engine.component.TransformComponent);

	local camPos = gameCameraTransform:getPosition(); 
	local camRot = gameCameraTransform:getRotation(); 

	state:setStopWithPositionInfo(camPos, camRot);
	app:stopGame();
end


function stopGame()
	externalUI:sendUICommand("stopGame()");
end


function togglePause()
	local paused = gameStatusModule:getGamePauseStatus()
	if paused then
		gameStatusModule:removeGamePauseStatus("ExternalUI")
	elseif gameStatusModule:hasGamePauseStatus("ExternalUI") then
		gameStatusModule:setGamePauseStatus("ExternalUI", 1, true)
	end
end

function updateUIPauseState(paused)
	assert_boolean(paused)
	
	if paused then
		externalUI:sendUICommand("setGamePauseEnabled()");
	else
		externalUI:sendUICommand("setGamePauseDisabled()");
	end
end


function setCurrentMapFileNameToEditor(fileName)
	externalUI:sendUICommand("setCurrentMapFilename(\"" .. fileName .. "\")");
end

function setCurrentMapFileNameToEditorQA(fileName)
	-- This is called from State::loadScenes(...)
	externalUI:sendUICommand("setCurrentMapFilenameQA(\"" .. fileName .. "\")");
end


function openMap(fileName, fileType)
	local currentMapFileName = "";
	if fileName == nil or fileType == nil then
		setCurrentMapFileNameToEditor(currentMapFileName);
		logger:error("external_ui:openMap - At least one of the params was nill.");
		return
	end
	
	local success = state:loadScenes(fileName, fileType);
	if success then
		currentMapFileName = state:getCurrentMapFile();
	else
		-- Failed for some reason, load empty
		state:createNewEmptyMap(); -- This call let's FUI initialize normally
		logger:info("state:loadScenes failed for some reason, loaded an empty scene.");
	end
	setCurrentMapFileNameToEditor(currentMapFileName);
	externalUI:sendUICommand("openMapPostCall()");
end


function saveMap(fileName, fileType)
	local currentMapFileName = "";
	if fileName == nil or fileType == nil then
		setCurrentMapFileNameToEditor(currentMapFileName);
		logger:error("external_ui:saveMap - At least one of the params was nill.");
		return;
	end
	local success = state:saveScenes(fileName, fileType);
	if success then
		currentMapFileName = state:getCurrentMapFile();
	end
	setCurrentMapFileNameToEditor(currentMapFileName);
end


function getTypeSaveList(savingScenes)
	stopInsertingType(); -- just to avoid getting references for temp crap
	externalUI:sendUICommand("saveTypeList(" .. typeManager:getTypeSaveList(savingScenes) .. ")");
end


function getResourceSaveList(savingScenes)
	stopInsertingType(); -- just to avoid getting references for temp crap
	externalUI:sendUICommand("saveResourceList(" .. resourceManager:getResourceSaveList(savingScenes) .. ")");
end


function saveTypeScripts(savingAll, guidArray)
	local res = typeManager:saveTypeScripts(savingAll,guidArray);
	if(res) then
		externalUI:sendUICommand("savingTypeScriptsSucceeded()");
	else
		externalUI:sendUICommand("savingTypeScriptsFailed()");
	end
end


function validateTypeReplacement(oldGuid, newGuid)
	-- always accept none
	if(newGuid == GUID_NONE) then
		externalUI:sendUICommand("typeReplacementValid()");
		return;
	end

	local oldTypeWasComponent = false
	local oldType = typeManager:findTypeByGUID(oldGuid)
	if(oldType and oldType:getNumComponentTypeOwners() > 0) then
		oldTypeWasComponent = true;
	end

	local newTypeIsComponent = false
	local newType = typeManager:findTypeByGUID(newGuid)
	if(newType and newType:doesInheritTypeByName("ComponentBase")) then
		newTypeIsComponent = true;

	if newType:isAbstractType() then
		local msg = "Component type " .. newType:getName() .. " is abstract, cannot use it.";
		externalUI:sendUICommand("typeReplacementInvalid(\"" .. msg .. "\")");
		return;
	end
	end

	-- note: we cannot know with absolute certainty that the old type was NOT a component, so this is allowed to fail sometimes
	if(oldTypeWasComponent and (not newTypeIsComponent)) then
		local msg = "Cannot use " .. newType:getName() .. " because it's not a component";
		externalUI:sendUICommand("typeReplacementInvalid(\"" .. msg .. "\")");
	else
		externalUI:sendUICommand("typeReplacementValid()");
	end

end


function replaceMissingTypes(replacetable)
	typeManager:replaceMissingTypes(replacetable);
end


function checkMissingTypesBeforeSave()
	local result = typeManager:getNumMissingTypesWithInstances()
	externalUI:sendUICommand("missingTypesInSave(\"" ..result .. "\")");
end


function doSVNCommit(commitMap)
	state:doSVNCommit(commitMap);
end

function doTypeSVNCommit()
	state:doTypeSVNCommit();
end


function copyNameToClipboardForEditorId(editorObjectId)
	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj) then
		externalUI:sendUICommand("copyToClipboard(\"" .. obj:getName() .. "\")");
	else
		editorMessageBox("Failed to parse object from editor object id parameter", "Invalid editor object id", "Warning")
	end
end


function copyFilenameToClipboardForEditorId(editorObjectId)
	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj) then
		if (obj:isInherited(engine.base.resourcebase.ResourceBase.getStaticObjectClass())) then
			externalUI:sendUICommand("copyToClipboard(\"" .. obj:getFilename() .. "\")");
		else
			-- TODO: support for types, etc.
			logger:error("Encountered a non-resource object, don't know how to copy filename to clipboard for it.");
		end
	else
		editorMessageBox("Failed to parse object from editor object id parameter", "Invalid editor object id", "Warning")
	end
end


function openContainingFolderForEditorId(editorObjectId)
	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj) then
		if (obj:isInherited(engine.base.resourcebase.ResourceBase.getStaticObjectClass())) then
			externalUI:sendUICommand("openContainingFolder(\"" .. obj:getFilename() .. "\")");
		else
			-- TODO: support for types, etc.
			logger:error("Encountered a non-resource object, don't know how to open the containg folder for it.");
		end
	else
		editorMessageBox("Failed to parse object from editor object id parameter", "Invalid editor object id", "Warning")
	end
end


function openResourceExternallyForEditorId(editorObjectId)
	local obj = getObjectByEditorObjectId(editorObjectId);
	if (obj) then
		if (obj:isInherited(engine.base.resourcebase.ResourceBase.getStaticObjectClass())) then
			externalUI:sendUICommand("openResourceExternally(\"" .. obj:getFilename() .. "\")");
		else
			-- TODO: support for types, etc.?
			logger:error("Encountered a non-resource object, don't know how to open it.");
		end
	else
		editorMessageBox("Failed to parse object from editor object id parameter", "Invalid editor object id", "Warning")
	end
end

function createATSForResource(editorObjectId)
  local obj = getObjectByEditorObjectId(editorObjectId);
  if (obj) then
    if (obj:isInherited(engine.base.resourcebase.ResourceBase.getStaticObjectClass())) then
      externalUI:sendUICommand("createFileFromTemplateRelatedToFile(\"ats\", \"" .. obj:getFilename() .. "\")");
    else
      -- TODO: support for types, etc.?
      logger:error("Encountered a non-resource object, don't know how to open it.");
    end
  else
    editorMessageBox("Failed to parse object from editor object id parameter", "Invalid editor object id", "Warning")
  end  
end

function saveResources(savingAll, guidtable)
	local res = resourceManager:saveResources(savingAll, guidtable)
	if res then
		externalUI:sendUICommand("savingResourcesSucceeded()");
	else
		externalUI:sendUICommand("savingResourcesFailed()");
	end
end


function shouldSaveMap()
	if(state.shouldSaveScenes and state:shouldSaveScenes()) then
		externalUI:sendUICommand("shouldSaveMapResult(\"true\")");
	else
		externalUI:sendUICommand("shouldSaveMapResult(\"false\")");
	end
end


function resetCameraRotation()
	local obj = gameScene:getSceneInstanceManager():findInstanceByName("EditorCamera");
	if (obj) then
		local trans = obj:findComponent(engine.component.TransformComponent);
		trans:setRotation(QUAT(0,0,0,1))
	end
end


function resetCameraPosition()
	local cam = gameScene:getSceneInstanceManager():findInstanceByName("EditorCamera");

	-- find the center of the scene
	local center = VC3(0,0,0)
	local numObjects = 0
	do
		local root = instanceManager:getTopmostInstanceRoot()
		local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilter(root, "0,All", editor.Editor.InfiniteDepth, false)
		local obj = resultIterator:next()
		while (obj) do
			if not(obj:getUnifiedHandle() == cam:getUnifiedHandle()) then
				local trans = obj:findComponent(engine.component.TransformComponent);
				if trans then
					center = center + trans:getPosition();
					numObjects = numObjects + 1;
				end
			end

			obj = resultIterator:next()
		end
	end
	if(numObjects > 0)
	then
		center = center / numObjects;
	end

	if (cam) then
		local trans = cam:findComponent(engine.component.TransformComponent);
		center.y = 20;
		trans:setPosition(center)
	end
end

function resetCameraPositionToZero()
	local cam = gameScene:getSceneInstanceManager():findInstanceByName("EditorCamera");
	if (cam) then
		local trans = cam:findComponent(engine.component.TransformComponent);
		local pos = VC3(0,0,0);
		if engine.base.mathbase.GameDirections.cameraForwardVector:getDotWith(VC3(1,1,1)) then
			pos = pos - engine.base.mathbase.GameDirections.cameraForwardVector * 10;
		else
			pos = pos + engine.base.mathbase.GameDirections.cameraForwardVector * 10;
		end
		trans:setPosition(pos)
	end
end


function importObjects(filename)
	if not editor.legacy_import.isLevelImportingAllowed() then
		logger:error(editor.legacy_import.getEnableLevelImportingFailMessage());
		return;
	end
	
	dofile(filename);
	editor.legacy_import.finishImport();
end

function setParentTransforms(enabled)
	-- WARNING: extremely stupid hack
	engine.component.TransformComponent.temporarilyDisableParentTransforms(enabled == false);
end


function locateSelectedType(editorObjectId)
	local obj = getObjectByEditorObjectId(editorObjectId)
	if obj and obj:isInherited(engine.base.InstanceBase.getStaticObjectClass()) then
		-- TODO: These should be editor options
		local activateInsertWidget = true;
		local expandSiblings = true;

		-- get last selected entity
		locateType(obj:getGuid(), expandSiblings)
		if state.setInsertWidgetToBeActivated and activateInsertWidget then
			state:clearSelection();
			state:setInsertWidgetToBeActivated();
		end
	end
end


function getPlayerPosition(sceneInstanceManager)
	local pm = common.CommonUtils.getPlayerManager()
	local playerCharacters = { }
	if pm then
		playerCharacters = {
			pm:getCharacterInstanceForPlayer(0), 
			pm:getCharacterInstanceForPlayer(1), 
			pm:getCharacterInstanceForPlayer(2)
		}
	end
	
	for key, playerInstance in pairs(playerCharacters) do
		if playerInstance then
			local tfc = playerInstance:findComponent(engine.component.TransformComponent);
			if tfc then
				return tfc:getPosition()
			end
		end
	end
end


function warpPlayerButton(index)
	if not gameScene then
		logger:error("gameScene is nil")
		return
	end
	local sceneInstanceManager = gameScene:getSceneInstanceManager()
	if sceneInstanceManager then
		local pos = VC3(0,0,0)
		local spawnManager = common.CommonUtils.getGameSpawnManager();
		if spawnManager then
			if index == 0 then pos = spawnManager:getMissionSpawnPos() end
			if index == 1 then pos = spawnManager:getLastActivatedCheckpointPosition(false, VC3(0,0,0)) end
			if index == 2 then
				pos = spawnManager:getPrevCheckpointPosition(getPlayerPosition(sceneInstanceManager)) 
				-- Ignore spawnmanager's position if a checkpoint is configured with order numbers
				local uhArray = spawnManager:getCheckpointUHArray()
				if uhArray:getSize() > 0 then
					local checkpointEntity = sceneInstanceManager:getInstanceByUH(uhArray:get(0):getUH())
					if checkpointEntity ~= nil then
						local checkpointComp = checkpointEntity:findComponent(trinebase.gameplay.TrineCheckpointComponent)
						if checkpointComp ~= nil then
							if checkpointComp:getCheckpointOrderSortingEntityInstance() ~= UH_NONE then
								local checkpointOrderEntity = sceneInstanceManager:getInstanceByUH(checkpointComp:getCheckpointOrderSortingEntityInstance())
								if checkpointOrderEntity ~= nil then
									local checkpointOrderComp = checkpointOrderEntity:findComponent(trinebase.gameplay.CheckpointOrderSortingComponent)
									if checkpointOrderComp ~= nil and checkpointOrderComp:getValid() then
										pos = checkpointOrderComp:getPrevCheckpointPosition(getPlayerPosition(sceneInstanceManager))
									else
										logger:error("Checkpoint numbers are not correctly configured in CheckpointOrderSortingComponent! Using fallback.");
									end
								end
							end
						end
					end
				end
			end
			if index == 3 then
				pos = spawnManager:getNextCheckpointPosition(getPlayerPosition(sceneInstanceManager))
				-- Ignore spawnmanager's position if a checkpoint is configured with order numbers
				local uhArray = spawnManager:getCheckpointUHArray()
				if uhArray:getSize() > 0 then
					local checkpointEntity = sceneInstanceManager:getInstanceByUH(uhArray:get(0):getUH())
					if checkpointEntity ~= nil then
						local checkpointComp = checkpointEntity:findComponent(trinebase.gameplay.TrineCheckpointComponent)
						if checkpointComp ~= nil then
							if checkpointComp:getCheckpointOrderSortingEntityInstance() ~= UH_NONE then
								local checkpointOrderEntity = sceneInstanceManager:getInstanceByUH(checkpointComp:getCheckpointOrderSortingEntityInstance())
								if checkpointOrderEntity ~= nil then
									local checkpointOrderComp = checkpointOrderEntity:findComponent(trinebase.gameplay.CheckpointOrderSortingComponent)
									if checkpointOrderComp ~= nil and checkpointOrderComp:getValid() then
										pos = checkpointOrderComp:getNextCheckpointPosition(getPlayerPosition(sceneInstanceManager))
									else
										logger:error("Checkpoint numbers are not correctly configured in CheckpointOrderSortingComponent! Using fallback.");
									end
								end
							end
						end
					end
				end
			end
		else
			logger:error("spawnmanager not found")
			return
		end

		local pm = common.CommonUtils.getPlayerManager()
		local playerCharacters = { }
		if pm then
			playerCharacters = {
				pm:getCharacterInstanceForPlayer(0), 
				pm:getCharacterInstanceForPlayer(1), 
				pm:getCharacterInstanceForPlayer(2)
			}
		end
		for key, playerInstance in pairs(playerCharacters) do
			if playerInstance then
				local playerCharacterComponent = playerInstance:findComponent(trinebase.gameplay.Trine3DPlayerCharacterComponent)
				if playerCharacterComponent then
					playerCharacterComponent:forceIdleState()
				end

				local tfc = playerInstance:findComponent(engine.component.TransformComponent);
				if tfc then
					tfc:setPosition(pos)
				end
			end
		end
	end
end

function setGlowEnabled(enabled)
	renderingModule:setShowGlow(enabled)
end


function setSwayEnabled(enabled)
	renderingModule:setEnableSway(enabled)
end


function setFogEnabled(enabled)
	renderingModule:setShowFog(enabled)
end


function setForceAmbientLight(enabled)
	renderingModule:setForceAmbientLight(enabled)
end


function setEnableLOD(enabled)
	renderingModule:setLODEnabled(enabled)
end


function setEnableShadowLOD(enabled)
	renderingModule:setShadowLODEnabled(enabled)
end


function setWireframeMode(enabled)
	renderingModule:setWireframeMode(enabled)
end

function setShadowCasterMode(enabled)
	renderingModule:setShadowCasterVisualization(enabled)
end

function toggleDebugOverlay()
	debugComponent:toggleDebugStatsOverlay()
end


function clearDebugOverlay()
	if not debugStatsOverlay then
		toggleDebugOverlay()
	end
	debugStatsOverlay:clearOverlay()
end


function resetDebugOverlayToStuffed()
	-- this more or less just a test thingy.
	debug.DebugStatsOverlayUtil.clearOverlay()
	debug.DebugStatsOverlayUtil.addFrameratesToOverlay()
	debug.DebugStatsOverlayUtil.addParticlesToOverlay()
	debug.DebugStatsOverlayUtil.addVariableToOverlay("fb::engine::base::resourcebase::ResourceStatsManager", "animationMainMemoryUsage")
	debug.DebugStatsOverlayUtil.addVariableToOverlay("fb::engine::base::resourcebase::ResourceStatsManager", "totalMainMemoryUsage")
	debug.DebugStatsOverlayUtil.addVariableToOverlay("fb::engine::base::resourcebase::ResourceStatsManager", "totalGraphicsMemoryUsage")
	toggleDebugOverlay()
	toggleDebugOverlay()
end

function resetDebugOverlayToMemory()
	debug.DebugStatsOverlayUtil.clearOverlay()
	debug.DebugStatsOverlayUtil.addFrameratesToOverlay()
	debug.DebugStatsOverlayUtil.addVariableToOverlay("fb::rendering::TextureResource", "textureMemoryPC")
	debug.DebugStatsOverlayUtil.addVariableToOverlay("fb::rendering::TextureResource", "textureMemoryPS3")
	debug.DebugStatsOverlayUtil.addVariableToOverlay("fb::rendering::TextureResource", "textureMemoryXbox360")	
	debug.DebugStatsOverlayUtil.addVariableToOverlay("fb::rendering::TextureResource", "textureMemoryWiiU")	
	debug.DebugStatsOverlayUtil.addVariableToOverlay("fb::engine::base::resourcebase::ResourceStatsManager", "modelGraphicsMemoryUsage")
	debug.DebugStatsOverlayUtil.addSumLimitVariableToOverlay("totalMemoryLimitPerLevelForArtistsPC", "fb::rendering::TextureResource", "textureMemoryPC", "fb::engine::base::resourcebase::ResourceStatsManager", "modelGraphicsMemoryUsage", totalMemoryLimitPerLevelForArtistsPC * mb)
	debug.DebugStatsOverlayUtil.addSumLimitVariableToOverlay("totalMemoryLimitPerLevelForArtistsPS3", "fb::rendering::TextureResource", "textureMemoryPS3", "fb::engine::base::resourcebase::ResourceStatsManager", "modelGraphicsMemoryUsage", totalMemoryLimitPerLevelForArtistsPS3 * mb)
	debug.DebugStatsOverlayUtil.addSumLimitVariableToOverlay("totalMemoryLimitPerLevelForArtistsXbox360", "fb::rendering::TextureResource", "textureMemoryXbox360", "fb::engine::base::resourcebase::ResourceStatsManager", "modelGraphicsMemoryUsage", totalMemoryLimitPerLevelForArtistsXbox360 * mb)
	debug.DebugStatsOverlayUtil.addSumLimitVariableToOverlay("totalMemoryLimitPerLevelForArtistsWiiU", "fb::rendering::TextureResource", "textureMemoryWiiU", "fb::engine::base::resourcebase::ResourceStatsManager", "modelGraphicsMemoryUsage", totalMemoryLimitPerLevelForArtistsWiiU * mb)
	toggleDebugOverlay()
	toggleDebugOverlay()
end

function resetDebugOverlayToPointlight()
	debug.DebugStatsOverlayUtil.clearOverlay()
	debug.DebugStatsOverlayUtil.addFrameratesToOverlay()
	debug.DebugStatsOverlayUtil.addVariableToOverlay("fb::rendering::RenderingScene", "storm3d_TotalPointlights")
	debug.DebugStatsOverlayUtil.addVariableToOverlay("fb::rendering::RenderingScene", "storm3d_VisiblePointlights")
	toggleDebugOverlay()
	toggleDebugOverlay()
end

function resetDebugOverlayToFPS()
	debug.DebugStatsOverlayUtil.clearOverlay()
	debug.DebugStatsOverlayUtil.addFrameratesToOverlay()
	toggleDebugOverlay()
	toggleDebugOverlay()
end


function resetGraphToFPS()
	app:clearDebugStatGraphs()
	--app:addDebugStatGraph("fb::rendering::RenderingModule", "averageFPS", 2.0, VC3(0, 128, 0))
	app:addDebugStatGraph("fb::rendering::RenderingModule", "FPS", 2.0, VC3(0, 255, 0))
	app:addDebugStatGraph("fb::rendering::RenderingModule", "drawCalls", 0.2, VC3(255, 255, 0))
	app:addDebugStatGraph("fb::rendering::RenderingModule", "polygons", 0.0005, VC3(0, 255, 255))
end

function addFPSGraph()
	app:addDebugStatGraph("fb::rendering::RenderingModule", "FPS", 2.0, VC3(0, 255, 0))
end

function addFPSToOverlay()
	debug.DebugStatsOverlayUtil.addVariableToOverlay("fb::rendering::RenderingModule", "FPS")
end


function resetGraphToTimers()
	app:clearDebugStatGraphs()
	app:addDebugStatGraph("fb::gameplay::TimerComponent", "peakTimersRunningInGame", 1.0, VC3(0, 128, 128))
	app:addDebugStatGraph("fb::gameplay::TimerComponent", "totalTimersRunningInGame", 1.0, VC3(0, 255, 255))
	app:addDebugStatGraph("fb::gameplay::TimerComponent", "totalTimersEnabledInGame", 1.0, VC3(0, 0, 255))
end

function resetGraphToEffects()
	app:clearDebugStatGraphs()
	app:addDebugStatGraph("fb::gameplay::effect::EffectComponent", "effectsActive", 1.0, VC3(128, 64, 0))
	app:addDebugStatGraph("fb::particles::ParticleModule", "particleEffects", 1.0, VC3(255, 128, 0))
	app:addDebugStatGraph("fb::particles::ParticleModule", "particlesSimulated", 0.05, VC3(128, 128, 0))
	app:addDebugStatGraph("fb::particles::ParticleModule", "particlesRendered", 0.1, VC3(255, 255, 0))
end

function resetGraphToTimerAndParticleVsFPS()
	app:clearDebugStatGraphs()
	app:addDebugStatGraph("fb::gamebase::state::scene::Scene", "castRaysAllPerSecond", 0.1, VC3(255, 0, 0))
	app:addDebugStatGraph("fb::rendering::RenderingModule", "FPS", 2.0, VC3(0, 255, 0))
	app:addDebugStatGraph("fb::gameplay::TimerComponent", "totalTimersRunningInGame", 1.0, VC3(0, 255, 255))
	app:addDebugStatGraph("fb::particles::ParticleModule", "particlesSimulated", 0.1, VC3(128, 128, 0))
	app:addDebugStatGraph("fb::particles::ParticleModule", "particlesRendered", 0.1, VC3(255, 255, 0))
end

function resetGraphToTotalResourceMemoryUsage()
	app:clearDebugStatGraphs()
	app:addDebugStatGraph("fb::engine::base::resourcebase::ResourceStatsManager", "totalMainMemoryUsage", 0.000005, VC3(0, 255, 0))
	app:addDebugStatGraph("fb::engine::base::resourcebase::ResourceStatsManager", "totalGraphicsMemoryUsage", 0.000005, VC3(255, 128, 0))
end

function setGraphSamplingTime(samplingRateSeconds)
	assert_number(samplingRateSeconds)
	app:setGraphSamplingRate(samplingRateSeconds)
end

function resetDebugOverlayToTimerCounts()
	debug.DebugStatsOverlayUtil.clearOverlay()
	debug.DebugStatsOverlayUtil.addTimersToOverlay()
end


function resetDebugOverlayToParticleCounts()
	debug.DebugStatsOverlayUtil.clearOverlay()
	debug.DebugStatsOverlayUtil.addFrameratesToOverlay()
	debug.DebugStatsOverlayUtil.addParticlesToOverlay()
	toggleDebugOverlay()
	toggleDebugOverlay()
end

-- visibleBoolString should be "True" or "False" (notice the case)
function addResourceUsageStatsToOverlay(visibleBoolString, debugStatsName, limitName)
	assert_string(visibleBoolString)
	assert_string(debugStatsName)
	assert_string_or_nil(limitName)
	if (limitName == nil) then
		limitName = debugStatsName
	end
	
	if (visibleBoolString == "True") then	
		if (resourceUsageLimits[limitName]) then
			local limit = resourceUsageLimits[limitName]
			debug.DebugStatsOverlayUtil.addLimitVariableToOverlay("fb::engine::base::resourcebase::ResourceStatsManager", debugStatsName, limit)
		else
			debug.DebugStatsOverlayUtil.addVariableToOverlay("fb::engine::base::resourcebase::ResourceStatsManager", debugStatsName)
		end
	end
end

function resetToAllocatedResourcesStart()
	debug.DebugStatsOverlayUtil.clearOverlay()
	debug.DebugStatsOverlayUtil.addFrameratesToOverlay()
end

function resetToAllocatedResourcesEnd()
	toggleDebugOverlay()
	toggleDebugOverlay()
end

function setDebugOverlayToCombinedResources(memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
	addResourceUsageStatsToOverlay(memory, "totalMainMemoryUsage")
	addResourceUsageStatsToOverlay(peakMemory, "peakTotalMainMemoryUsage")
	addResourceUsageStatsToOverlay(graphics, "totalGraphicsMemoryUsage")
	addResourceUsageStatsToOverlay(peakGraphics, "peakTotalGraphicsMemoryUsage")
	addResourceUsageStatsToOverlay(loaded, "totalResourcesLoaded")
	addResourceUsageStatsToOverlay(peakLoaded, "peakTotalResourcesLoaded")
end

function setDebugOverlayToResourcesImpl(name, peakName, memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
	assert_string(name)
	assert_string(peakName)
	addResourceUsageStatsToOverlay(memory, name.."MainMemoryUsage")
	addResourceUsageStatsToOverlay(peakMemory, peakName.."MainMemoryUsage", name.."MainMemoryUsage")
	addResourceUsageStatsToOverlay(graphics, name.."GraphicsMemoryUsage")
	addResourceUsageStatsToOverlay(peakGraphics, peakName.."GraphicsMemoryUsage", name.."GraphicsMemoryUsage")
	addResourceUsageStatsToOverlay(loaded, name.."ResourcesLoaded")
	addResourceUsageStatsToOverlay(peakLoaded, peakName.."ResourcesLoaded", name.."ResourcesLoaded")
end

function setDebugOverlayToAnimationResources(memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
	setDebugOverlayToResourcesImpl("animation", "peakAnimation", memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
end

function setDebugOverlayToAnimationTreeResources(memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
	setDebugOverlayToResourcesImpl("animationTree", "peakAnimationTree", memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
end	

function setDebugOverlayToBonesResources(memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
	setDebugOverlayToResourcesImpl("bones", "peakBones", memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
end
	
function setDebugOverlayToCollisionResources(memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
	setDebugOverlayToResourcesImpl("collision", "peakCollision", memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
end

function setDebugOverlayToFilterResources(memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
	setDebugOverlayToResourcesImpl("filter", "peakFilter", memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
end

function setDebugOverlayToFontResources(memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
	setDebugOverlayToResourcesImpl("font", "peakFont", memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
end

function setDebugOverlayToLuaResources(memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
	setDebugOverlayToResourcesImpl("lua", "peakLua", memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
end

function setDebugOverlayToPhysicsMeshResources(memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
	setDebugOverlayToResourcesImpl("physicsMesh", "peakPhysicsMesh", memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
end

function setDebugOverlayToModelResources(memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
	setDebugOverlayToResourcesImpl("model", "peakModel", memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
end

function setDebugOverlayToPathNodeResources(memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
	setDebugOverlayToResourcesImpl("pathNode", "peakPathNode", memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
end

function setDebugOverlayToRagdollResources(memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
	setDebugOverlayToResourcesImpl("ragdoll", "peakRagdoll", memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
end

function setDebugOverlayToScriptResources(memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
	setDebugOverlayToResourcesImpl("script", "peakScript", memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
end

function setDebugOverlayToShaderResources(memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
	setDebugOverlayToResourcesImpl("shader", "peakShared", memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
end

function setDebugOverlayToTextureResources(memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
	setDebugOverlayToResourcesImpl("texture", "peakTexture", memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
end

function setDebugOverlayToTextureTotalResources(memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
	setDebugOverlayToResourcesImpl("textureTotal", "peakTextureTotal", memory, peakMemory, graphics, peakGraphics, loaded, peakLoaded)
end


function fixBitSetPropertyBitNames(guid, propertyName)
	local obj = getObjectByGUID(guid)
	if obj then
		if obj:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) then
			obj:fixTypeBitSetPropertyBitNames(propertyName)
		elseif obj:isInherited(engine.base.InstanceBase.getStaticObjectClass()) then
			local originalType = typeManager:getTypeByUH(obj:getType())
--			originalType:resetInstancePropertyValue(obj, propertyName)
		elseif obj:isInherited(engine.base.resourcebase.ResourceBase.getStaticObjectClass()) then
--			obj:resetPropertyValue(propertyName)
		elseif obj:isInherited(engine.module.AbstractModuleTreeObject.getStaticObjectClass()) then
--			obj:resetPropertyValue(propertyName)
		end
	end
end


function resetPropertyValue(guid, propertyName)
	local obj = getObjectByGUID(guid)
	if obj then
		local oper = createPropertyChangedOperation(findManagerForGUID(guid):getObjectManager());
		oper:setName("Property Resetted");
		oper:saveProperty(obj, propertyName);

		if obj:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) then
			obj:resetTypePropertyValue(propertyName)
		elseif obj:isInherited(engine.base.InstanceBase.getStaticObjectClass()) then
			local originalType = typeManager:getTypeByUH(obj:getType())
			originalType:resetInstancePropertyValue(obj, propertyName)
		elseif obj:isInherited(engine.base.resourcebase.ResourceBase.getStaticObjectClass()) then
			obj:resetPropertyValue(propertyName)
		elseif obj:isInherited(engine.module.AbstractModuleTreeObject.getStaticObjectClass()) then
			obj:resetPropertyValue(propertyName)
		else
			oper:release();
			return;
		end

		state:addUndoOperation(oper);
	end
end

function applyPropertyValueToType(guid, propertyName)
	local obj = getObjectByGUID(guid)
	if obj then
		if obj:isInherited(engine.base.InstanceBase.getStaticObjectClass()) then
			local originalType = typeManager:getTypeByUH(obj:getType())
		
			local oper = createPropertyChangedOperation(findManagerForGUID(originalType:getGuid()):getObjectManager());
			oper:setName("Property applied to type");
			oper:saveProperty(originalType, propertyName);

			local idx1 = obj:findPropertyIndexByName(propertyName)
			local idx2 = originalType:findPropertyIndexByName(propertyName)
			originalType:setPropertyValue(idx2, obj:getPropertyValue(idx1))

			state:addUndoOperation(oper);

			resetPropertyValue(guid, propertyName)
		end

	end
end


function setSyncEnabled(enabled)
	if enabled then
		state:setEditorSyncEnabled(true)

		-- need to resync all
		syncInstanceGraphRoot()
		syncTypeGraphRoot()
		syncResourceGraphRoot()
        state:updateSelectionValues()
	else
		state:setEditorSyncEnabled(false)
	end
end


function ignoreModelResourceTypeCreation(nameList)
	for k,v in pairs(nameList) do
		local res = resourceManager:findResourceByName(v)
		if res and res.setIgnoreTypeCreation then
			res:setIgnoreTypeCreation(true)
		end
	end
end


function editorMessageBox(message, caption, level)
	if not message then
		logger:error("editor.extenal_ui.editorMessageBox: message missing")
		message = "Insert message here"
	end
	if not caption then
		logger:error("editor.extenal_ui.editorMessageBox: caption missing")
		caption = "Insert caption here"
	end
	if not level then
		logger:error("editor.extenal_ui.editorMessageBox: level missing")
		level = "Error"
	end
	externalUI:sendUICommand("messageBox(\"" .. message .. "\", \"" .. caption .. "\", \"" .. level .. "\")")
end


function createDefaultTypesFromModelResources(nameList, recursionDepth)
	local failList = { }
	local namePostfix = ""
	recursionDepth = recursionDepth or 0
	for i = 1, recursionDepth do namePostfix = namePostfix .. "_" end
	for k,v in pairs(nameList) do
		local entityTypeName = editor.Util.convertTypeName(v) .. namePostfix
		local modelComponentTypeName = entityTypeName .. editor.Util.getTypeNamePostFix("ModelComponent")
		if createTypeFromModelResource(v, {"", entityTypeName, "Entity", "", modelComponentTypeName, "ModelComponent"}, true) == false then
			table.insert(failList, v)
		end
	end
	if # failList > 0 then
		if recursionDepth == 0 then
			local message = "Failed to create some of the default types for resources ("
			for k,v in pairs(failList) do
				message = message .. v .. ", "
			end
			message = string.sub(message, 1, -2)
			message = message .. "). Trying again with different name (default name + _)"
			editorMessageBox(message, "Failed to create types", "Info")
			if createDefaultTypesFromModelResources(failList, 1) == true then
				editorMessageBox("Succeeded: Default types created with alternative names", "Create types", "Info")
			else
				return false
			end
		elseif recursionDepth == 10 then
			local failed = table.concat(failList, ", ")
			editorMessageBox("Failed to create some of the default types for resources: " .. failed, "Failed to create types", "Error")
			for i = 1, # failList do externalUI:sendUICommand("createNewTypeFailed()") end
			return false
		else
			return createDefaultTypesFromModelResources(failList, recursionDepth + 1)
		end
	end
	return true
end


function processResource(editorObjectId)
	local obj = getObjectByEditorObjectId(editorObjectId)
	if obj then
		app:processResource(obj)
	end
end


function cleanResource(editorObjectId)
	local obj = getObjectByEditorObjectId(editorObjectId)
	if obj then
		app:cleanResource(obj)
	end
end


function deleteResource(editorObjectId)
	local obj = getObjectByEditorObjectId(editorObjectId)
	if obj then
		app:deleteResource(obj)
	end
end


function listTextureResourceTypes()
	local obj = resourceManager:findResourceByName("data/null/null.tga")
	if obj then
		local types = ""
		local idx = obj:findPropertyIndexByName("Type")
		local enumStrings = obj:getEnumPropertyStrings(idx)
		for idx,v in pairs(enumStrings) do
			if #v > 0 then
				if #types > 0 then
					types = types .. ","
				end
				types = types .. "\"" .. v .. "\""
			end
		end

		externalUI:sendUICommand("listTextureResourceTypes(" .. types .. ")")
	end
end


function setTextureResourceType(resName, typ)
	local obj = resourceManager:findResourceByName(resName)
	if obj then
		obj:setType(typ)
	else
		sendGameLogMessageToExternalUI("Failed to set type for "..resName, 1)
	end
end


function saveTypesForNewResourceDialog()
	externalUI:sendUICommand("saveTypesForNewResourceDialog(" .. typeManager:getTypeSaveList(false) .. ")")
end


function saveResourcesByName(nameList)
	local guidtable = {}
	for k,v in pairs(nameList) do
		local obj = resourceManager:findResourceByName(v)
		if(obj) then
			table.insert(guidtable, obj:getGuid())
		end
	end
	resourceManager:saveResources(false, guidtable)
end


function doSVNCommitForResourcesAndReferencedTypes(nameList)
	local guidtable = {}
	for k,v in pairs(nameList) do
		local obj = resourceManager:findResourceByName(v)
		if obj then
			table.insert(guidtable, obj:getGuid())
		end
	end
	state:doSVNCommitForResourcesAndReferencedTypes(guidtable)
end


function addRecentObjectsFromResources(nameList)
	local guidtable = {}
	for k,v in pairs(nameList) do
		local obj = resourceManager:findResourceByName(v)
		if obj then
			addRecentObjectImpl(obj)
		end
	end
end

function setAlwaysLoadedAndIncludedBitsetsForResourceList(nameList, alwaysLoaded, alwaysIncluded, notAlwaysLoaded, notAlwaysIncluded)
	for k,v in pairs(nameList) do
		local obj = resourceManager:findResourceByName(v)
		if obj then
			if alwaysLoaded then
				obj:setAlwaysLoaded(alwaysLoaded)
			end
			
			if alwaysIncluded then
				obj:setAlwaysIncluded(alwaysIncluded)
			end
			
			if notAlwaysLoaded then
				obj:setNotAlwaysLoaded(notAlwaysLoaded)
			end
			
			if notAlwaysIncluded then
				obj:setNotAlwaysIncluded(notAlwaysIncluded)
			end			
		end
	end
end


function syncSingleLayer(layerEnum, layerName)
	if state:isLayerVisible(layerEnum) then
		if state:getSelectedLayer() == layerEnum then
			externalUI:sendUICommand("setLayerSelectedInUI(\"" .. layerName .. "\")")
		elseif state:isLayerActive(layerEnum) then
			externalUI:sendUICommand("setLayerActiveInUI(\"" .. layerName .. "\")")
		else
			externalUI:sendUICommand("setLayerInactiveInUI(\"" .. layerName .. "\")")
		end
	else
		externalUI:sendUICommand("setLayerHiddenInUI(\"" .. layerName .. "\")")
	end
end


function syncLayersView()
	-- TODO: instead of copy&paste, it would ne nicer to actually loop the enum names and stuff...
	syncSingleLayer(engine.base.LayerDefault, "Default")
	syncSingleLayer(engine.base.LayerCollision, "Collision")
	syncSingleLayer(engine.base.LayerCustom1, "Custom1")
	syncSingleLayer(engine.base.LayerCustom2, "Custom2")
	syncSingleLayer(engine.base.LayerCustom3, "Custom3")
	syncSingleLayer(engine.base.LayerCustom4, "Custom4")
	syncSingleLayer(engine.base.LayerCustom5, "Custom5")
	syncSingleLayer(engine.base.LayerCustom6, "Custom6")
	syncSingleLayer(engine.base.LayerCustom7, "Custom7")
	syncSingleLayer(engine.base.LayerCustom8, "Custom8")
	syncSingleLayer(engine.base.LayerCustom9, "Custom9")
	syncSingleLayer(engine.base.LayerNoSave, "NoSave")
	syncSingleLayer(engine.base.LayerLocal, "Local")
end

-- Accepts editor object ids and normal guid strings
function syncReferencesList(editorObjectId)
	local obj = getObjectByEditorObjectId(editorObjectId)
	if not obj then
		logger:error("external_UI.syncReferencesList: could not retrieve object based on guid string: " ..guidStr)
		return
	end
	local listenerId = "ReferencesList"
	externalUI:sendUICommand("sync(\"" .. listenerId .. "\", \"" .. obj:getName() .. ":" .. tostring(obj:getGuid()) .. ":" .. obj:getReferenceDataString() .. "\")")
	externalUI:sendUICommand("openReferencesList()")
end

function splitString(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

function createTimerListReferenceString(referenceString)
	local SEP = ':'
	local splitted = splitString(referenceString, SEP)
	if not #splitted == 3 then
		return
	end
	local refType = splitted[1]
	local name = splitted[2]
	local guid = splitted[3]

	local active = false
	local entityName = ""

	if refType == "INST" then
		local component = getObjectByGUID(getGUIDFromGUIDString(guid))
		if component ~= nil and component:isInherited(engine.base.ComponentBase.getStaticObjectClass()) then
			active = component:getActivated()
			entityName = component:getFinalOwner():getName()
			if string.len(entityName) == 0 then
				local refobj = typeManager:getTypeByUH( component:getFinalOwner():getType() );
				if refobj ~= nil then
					entityName = refobj:getName()
				end
			end
		end
	end

	return refType .. SEP .. name .. SEP .. guid .. SEP .. tostring(active) .. SEP .. entityName
end

function syncTimerList(editorObjectId)
	local refType = typeManager:findTypeByName("TimerComponent")
	if not refType then
		logger:error("external_UI.syncTimerList couldn't find TimerComponent type")
		return
	end

	local InSep = '®'
	local OutSep = '\n' -- LUA isn't good at writing weird separator characters

	local referenceData = refType:getReferenceDataString()
	local references = splitString(referenceData, InSep)
	local timerListReferenceData = ""
	local first = true

	for k,v in pairs(references) do
		local str = createTimerListReferenceString(v)
		if string.len(str) > 0 then
			if not first then
				timerListReferenceData = timerListReferenceData .. OutSep
			end
			timerListReferenceData = timerListReferenceData .. str
			first = false
		end
	end


--[[
	start, stop = string.find(referenceData, ":")

	if (start < 0) return


	local name = string.sub(referenceData, start, stop)
	logger:error(name)

]]--

	local listenerId = "TimerList"
	externalUI:sendUICommand("sync(\"" .. listenerId .. "\", \"" .. timerListReferenceData .. "\")")
end

function tryToOpenChooseObjectDialogPropertyGUID(parentGuid, objectGuid, objectTypeString)
	--
	-- Try to get correct ResourcePathNode from parentGuid if objectGuid is GUID_NONE
	--

	local retGuid = GUID_NONE

	if objectGuid == nil then
		logger:error("tryToOpenChooseObjectDialogPropertyGUID - Invalid objectGuid parameter given (nil).")
		externalUI:sendUICommand("openChooseObjectDialogPropertyGUIDFailed()")
		return
	end

	if objectTypeString == nil then
		logger:error("tryToOpenChooseObjectDialogPropertyGUID - Invalid objectTypeString parameter given (nil).")
		externalUI:sendUICommand("openChooseObjectDialogPropertyGUIDFailed()")
		return
	end

	if objectGuid == GUID_NONE then
		-- Parent guid isn't valid, don't try to resolve the ResourcePathNode
		if parentGuid ~= nil and parentGuid ~= GUID_NONE then
			if objectTypeString == "Type" then
				-- nop
			elseif objectTypeString == "Resource" then
				local path = ""
				local typ = nil

				-- Type?
				if typ == nil then
					typ = typeManager:findTypeByGUID(parentGuid)
				end

				-- Instance?
				if typ == nil then
					local instance = nil
					if scene then
						instance = scene:getSceneInstanceManager():findInstanceByGUID(parentGuid)
					else
						instance = gameScene:getSceneInstanceManager():findInstanceByGUID(parentGuid)
					end
					if instance then
						local typeUH = UH_NONE

						if(instance.getFinalOwner and instance:getFinalOwner()) then
							-- Get owner type
							typeUH = instance:getFinalOwner():getType()
						else
							-- Self
							typeUH = instance:getType()
						end

						if (typeUH ~= UH_NONE) then
							typ = typeManager:getTypeByUH(typeUH)
						end
					end
				end

				if typ then
					local typeScriptPath = typ:getTypeScript()
					if typeScriptPath ~= nil and string.len(typeScriptPath) > 0 then
						local fileName = editor.Util.getPlainFileName(typeScriptPath, "/")
						path = string.gsub(typeScriptPath, "/" .. fileName, "")
					end
				else
					-- NOTE: If this happens, parentGUID was probably a resource
					-- TODO: Support resources also if needed
					logger:error("tryToOpenChooseObjectDialogPropertyGUID - No type found for given GUID, current impl doesn't support Resources.")
				end

				-- Path resolved, try to resolve ResourcePathNode guid
				if path ~= nil and string.len(path) > 0 then
					local resource = resourceManager:findResourceByName(path)
					if resource then
						retGuid = resource:getGuid()
					end

					if retGuid == GUID_NONE then
						-- This should never happen
						logger:error("tryToOpenChooseObjectDialogPropertyGUID - No ResourcePathNode found with given path.")
					end
				end
			elseif objectTypeString == "Instance" then
				-- nop
			else
				logger:error("tryToOpenChooseObjectDialogPropertyGUID - Invalid objectTypeString parameter given.")
				externalUI:sendUICommand("openChooseObjectDialogPropertyGUIDFailed()")
				return
			end
		end
	end
	-- Finally open the "ChooseObjectDialog"
	externalUI:sendUICommand("openChooseObjectDialogPropertyGUID(\"".. editor.Util.escapeQuotesAndBackslashes(tostring(retGuid)) .. "\")")
end

----------------------------------------------------------------------------------------------------------
-- Debug visualizer options

function setDebugVisualizationPropertyForAllInstances(propertyName, enabled)
	editor.Util.setComponentBoolPropertyForAllInstances(propertyName, enabled, engine.component.AbstractDebugVisualizerComponent.getStaticClassId(), "");
end

function setDebugVisualizationSelfIlluminationEnabled(enabled)
	if state ~= nil and state.setDVSelfIlluminationEnabled then
		state:setDVSelfIlluminationEnabled(enabled);
	end
	setDebugVisualizationSelfIlluminationForAllInstancesEnabledImpl(enabled);
end

function setDebugVisualizationWidgetEnabled(enabled)
	if state ~= nil and state.setDVWidgetEnabled then
		state:setDVWidgetEnabled(enabled);
	end
	setDebugVisualizationWidgetForAllInstancesEnabledImpl(enabled);
end

function setDebugVisualizationTextEnabled(enabled)
	if state ~= nil and state.setDVTextEnabled then
		state:setDVTextEnabled(enabled);
	end
	setDebugVisualizationTextForAllInstancesEnabledImpl(enabled);
end

function setDebugVisualizationIconEnabled(enabled)
	if state ~= nil and state.setDVIconEnabled then
		state:setDVIconEnabled(enabled);
	end
	setDebugVisualizationIconForAllInstancesEnabledImpl(enabled);
end

function setDebugVisualizationHighlightEnabled(enabled)
	if state ~= nil and state.setDVHighlightEnabled then
		state:setDVHighlightEnabled(enabled);
	end
	setDebugVisualizationHighlightForAllInstancesEnabledImpl(enabled);
end

function setDebugVisualizationLinksEnabled(enabled)
	if state ~= nil and state.setDVLinksEnabled then
		state:setDVLinksEnabled(enabled);
	end
	setDebugVisualizationLinksForAllInstancesEnabledImpl(enabled);
end

function isNumResultsBelowLimit(rootObject, filterString, limit)
	local numResults = 0;
	local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilterWithDepth(rootObject, filterString, editor.Editor.InfiniteDepth, true)
	local resultEntry = resultIterator:next()
	while resultEntry do
		numResults = numResults + 1
		if(numResults > limit)
		then
			return false
		end
		resultEntry = resultIterator:next()
	end
	return true
end


function sendExpandRootAndAllChildren(listenerId)
	local filterString = getFilter(listenerId)
	local rootObj;
	if(listenerId == "TypeExplorer")
	then
		rootObj = typeManager:getTypeRoot();
	elseif(listenerId == "ResourceExplorer")
	then
		rootObj = resourceManager:getResourceRoot();
	elseif(listenerId == "SceneExplorer")
	then
		rootObj = instanceManager:getTopmostInstanceRoot();
	else
		return
	end
	
	-- check that doesn't attempt to expand too much
	local maxResults = 200
	if(not isNumResultsBelowLimit(rootObj, filterString, maxResults))
	then
	
		-- haxhax solution to avoid closing the tree when erasing search string
		if(listenerId == "SceneExplorer")
		then
			--[[
			if(state.getNumSelected)
			then
				local i = 0;
				while(i < state:getNumSelected())
				do
					locateGUID(state:getSelectedEntity(i):getGuid(), false)
					i = i + 1
				end
			end
			--]]
		elseif(listenerId == "TypeExplorer")
		then
			if(state.getNumSelectedTypes)
			then
				local i = 0;
				while(i < state:getNumSelectedTypes())
				do
					locateGUID(state:getSelectedType(i):getGuid(), false)
					i = i + 1
				end
			end
		elseif(listenerId == "ResourceExplorer")
		then
			if(state.getNumSelectedResources)
			then
				local i = 0;
				while(i < state:getNumSelectedResources())
				do
					locateGUID(state:getSelectedResource(i):getGuid(), false)
					i = i + 1
				end
			end
		end
		
		return
	end
	
	externalUI:sendUICommand("expandRootAndAllChildren(\""..listenerId.."\")")
end


function sendExpandRootAndAllChildrenForChooseObjectDialog(propertyFlags, listenerId)
	sendExpandRootAndAllChildrenForDialog(propertyFlags, listenerId, filteringModule:getChooseObjectDialogFilterString())
end


-- This function is used by sendExpandRootAndAllChildrenForChooseObjectDialog and 
-- sendExpandRootAndAllChildrenForAddComponentTypeDialog
function sendExpandRootAndAllChildrenForDialog(propertyFlags, listenerId, filterString)
	local root = instanceManager:getTopmostInstanceRoot()
	
	if(string.find(propertyFlags, "EditorHint_Type_Type")) then
		root = typeManager:getTypeRoot()
	end
	
	if(string.find(propertyFlags, "EditorHint_Type_Resource")) then
		root = resourceManager:getResourceRoot()
	end
	
	if root == nil then
		logger:error("external_ui:sendExpandRootAndAllChildrenForDialog - root is nil, cannot continue.")
		return
	end
	
	-- check that doesn't attempt to expand too much
	local maxResults = 200
	if(not isNumResultsBelowLimit(root, filterString, maxResults)) then
		--logger:debug("external_ui:sendExpandRootAndAllChildrenForDialog - Too many results. No auto expand. FilterString: " .. filterString)
		return
	end	
	externalUI:sendUICommand("expandRootAndAllChildren(\""..listenerId.."\")")
end


function sendExpandRootAndAllChildrenForAddComponentTypeDialog(propertyFlags, listenerId)
	sendExpandRootAndAllChildrenForDialog(propertyFlags, listenerId, filteringModule:getAddComponentTypeDialogFilterString())
end


function editorStateCall(func, ...)
	if(func)
	then
		func(state, unpack(arg))
	end
end

function listenToObjectPropertyChanges(editorObjIdList)
	local instanceList = {}
	local allList = {}
	for idx,v in pairs(editorObjIdList)
	do
		local obj = getObjectByEditorObjectId(v);
		if(obj and obj:isInherited(engine.base.InstanceBase.getStaticObjectClass()))
		then
			table.insert(instanceList, obj);
		end
		if(obj) then
			table.insert(allList, obj:getGuid());
		end
	end
	app:listenToInstancePropertyChanges(instanceList);
	if(state.setPropertyWindowObjects) then
		state:setPropertyWindowObjects(allList);
	end
end


----------------------------------------------------------------------------------------------------------
-- editor property connection stuff...

listOfInputEditorIds = {}
listOfOutputEditorIds = {}

function clearConnectionInputList()
  listOfInputEditorIds = {}
end
	
function clearConnectionOutputList()
  listOfOutputEditorIds = {}
end
	
function addEditorIdToConnectionInputList(editorId)
	if not(listOfInputEditorIds) then clearConnectionInputList() end
  table.insert(listOfInputEditorIds, editorId)
end

function addEditorIdToConnectionOutputList(editorId)
	if not(listOfOutputEditorIds) then clearConnectionOutputList() end
  table.insert(listOfOutputEditorIds, editorId)
end

function addConnectionBetweenInputOutput()
	-- first check the input/output amounts
	local useFirstInputForAllOutputs = false
	if (#listOfInputEditorIds < 1 or #listOfOutputEditorIds < 1) then
		logger:error("At least one input and one output is required for a connection.")
		return
	end
	if (#listOfInputEditorIds > 1 and #listOfOutputEditorIds > 1) then
		if (#listOfInputEditorIds ~= #listOfOutputEditorIds) then
			logger:error("Only single input to multiple output, or multiple inputs to the same amount of outputs is supported.")
			return
		end
	end
	if (#listOfInputEditorIds == 1 and #listOfOutputEditorIds > 1) then
	  useFirstInputForAllOutputs = true
	end
	
	local makeMaintainOffset = propertyAnimationModule:getCreatedConnectionsMaintainOffset()
	local makeActiveInEditor = propertyAnimationModule:getCreatedConnectionsActiveInEditorByDefault()
	
	-- then actually connect those...
	for i = 1,#listOfOutputEditorIds do
		createConnectionBetweenEditorIds(listOfInputEditorIds[1], listOfOutputEditorIds[i], makeMaintainOffset, makeActiveInEditor)
	end
	
end

function addLuaExpressionConnectionBetweenInputOutput(luaExpr)
	-- first check the input/output amounts
  -- FIXME: in reality, should support multiple inputs/outputs...
	-- specifically, at most 2 of each input/output type. (as that is supported by the lua expression component)
	if (not(#listOfInputEditorIds == 1 and #listOfOutputEditorIds == 1)) then
		logger:error("One input and one output is required for a lua expression connection (other amounts TODO).")
		return
	end

	createLuaExpressionComponent(luaExpr, listOfOutputEditorIds[1], listOfInputEditorIds[1], listOfOutputEditorIds[1])
	-- Note, need to postpone the creation of the connections after the component has been created.
	-- (the createdLuaExpressionComponent callback handles those)
end

function addCustomComponent(componentTypeName, propValues)
  -- HACK: creating an unconnected custom component, but creation of such component still currently requires you to specify the 
  -- input and output properties (though they are unused)
	if (not(#listOfInputEditorIds == 1 and #listOfOutputEditorIds == 1)) then
		logger:error("One input and one output is required for a custom component connection (other amounts TODO).")
		return
	end

	createCustomPropAnimComponent(listOfOutputEditorIds[1], nil, nil, componentTypeName, nil, nil, propValues)
end

function addCustomComponentConnectionBetweenInputOutput(componentTypeName, inputPropName, outputPropName, propValues)
	-- first check the input/output amounts
  -- FIXME: in reality, should support multiple inputs/outputs...
	-- specifically, at most 2 of each input/output type. (as that is supported by the lua expression component)
	if (not(#listOfInputEditorIds == 1 and #listOfOutputEditorIds == 1)) then
		logger:error("One input and one output is required for a custom component connection (other amounts TODO).")
		return
	end

	createCustomPropAnimComponent(listOfOutputEditorIds[1], listOfInputEditorIds[1], listOfOutputEditorIds[1], componentTypeName, inputPropName, outputPropName, propValues)
	-- Note, need to postpone the creation of the connections after the component has been created.
	-- (the createdCustomPropComponent callback handles those)
end

--[[
inputOutputChainOwnerId = nil
inputOutputChainInputId = nil
inputOutputChainOutputId = nil

inputOutputChainPreviousId = nil
inputOutputChainPreviousOutputProp = nil

function startInputOutputChain(inputPropName, outputPropName)
	if (not(#listOfInputEditorIds == 1 and #listOfOutputEditorIds == 1)) then
		logger:error("One input and one output is required for a chain of custom connections (other amounts TODO).")
		return
	end
	
	inputOutputChainOwnerId = listOfOutputEditorIds[1]
	inputOutputChainInputId = listOfInputEditorIds[1]
	inputOutputChainOutputId = listOfOutputEditorIds[1]
end

function addChainedCustomComponentConnection(componentTypeName, inputPropName, outputPropName, propValues)
	createCustomPropAnimComponent(listOfOutputEditorIds[1], listOfInputEditorIds[1], listOfOutputEditorIds[1], componentTypeName, inputPropName, outputPropName, propValues)	
	
	-- these need to be set by the component creation...
	-- inputOutputChainPreviousId 
	-- inputOutputChainPreviousOutputProp
	
	-- note, this is a bit broblematic due to the delayed object creation (has to be done in the initialization of the last component)
end

function endInputOutputChain()
	-- TODO: end the chain by adding a connection between the last created component to the inputOutputChainOutputId
	-- note, this is a bit broblematic due to the delayed object creation (has to be done in the initialization of the last component)
end
]]--

function parsePropertyNumberFromEditorId(editorId)
	local propPosPair = string.find(editorId, ",PROP,", 1)
	if (propPosPair) then
		local indexStr = string.sub(editorId, propPosPair)
		local nextCommaPos = string.find(indexStr, ",", 7)
		if (nextCommaPos) then
			indexStr = string.sub(indexStr, 7, nextCommaPos - 1)
			local index = tonumber(indexStr);
			if (index) then
				return index
			else
				logger:error("Failed to parse the property number out of the given editor id (parsed string is not a number).")
				return -1
			end
		else
			logger:error("Failed to parse the property number out of the given editor id (ending comma missing).")
			return -1
		end
	else
	  logger:error("The given editor id is not one referring to a property.")
	  return -1
	end
end

function createConnectionBetweenEditorIds(inputEditorId, outputEditorId, makeMaintainOffset, makeActiveInEditor)
	local inputObj = getObjectByEditorObjectId(inputEditorId);
	if (not(inputObj)) then
		logger:error("failed to find input object with given editor id.")
		return
	end
	local outputObj = getObjectByEditorObjectId(outputEditorId);
	if (not(outputObj)) then
		logger:error("failed to find output object with given editor id.")
		return
	end
	
	-- parse property names
	local inputPropIndex = parsePropertyNumberFromEditorId(inputEditorId)
	local outputPropIndex = parsePropertyNumberFromEditorId(outputEditorId)
	local inputPropName = inputObj:getPropertyName(inputPropIndex);
	local outputPropName = outputObj:getPropertyName(outputPropIndex);

	createConnectionBetween(inputObj, inputPropName, outputObj, outputPropName, makeMaintainOffset, makeActiveInEditor)
end

function createConnectionBetween(inputObj, inputPropName, outputObj, outputPropName, makeMaintainOffset, makeActiveInEditor)
  local outputFinalOwner = outputObj
	if (outputObj.getFinalOwner) then outputFinalOwner = outputObj:getFinalOwner() end
  local connCompType = typeManager:findTypeByName("PropertyConnectionComponent");
  outputFinalOwner:getInstanceManager():createNewComponent(connCompType:getUnifiedHandle(), outputFinalOwner, createdPropertyConnectionComponent, { inputInstance=inputObj:getUnifiedHandle(), outputInstance=outputObj:getUnifiedHandle(), inputPropName=inputPropName, outputPropName=outputPropName, makeActiveInEditor=makeActiveInEditor, makeMaintainOffset=makeMaintainOffset } );	
end

function createdPropertyConnectionComponent(connComp, params)	
	connComp:setInputInstance(params.inputInstance)
	connComp:setOutputInstance(params.outputInstance)
	connComp:setInputPropertyName(params.inputPropName)
	connComp:setOutputPropertyName(params.outputPropName)
	if (params.makeActiveInEditor) then
		connComp:setActiveInEditor(true)
	end
	if (params.makeMaintainOffset) then
		connComp:setMaintainOffset(true)
	end
	
	syncObjectHierarchy(connComp:getInstanceManager():getInstanceByUH(params.inputInstance):getGuid(), "SceneExplorer")
	syncObjectHierarchy(connComp:getInstanceManager():getInstanceByUH(params.outputInstance):getGuid(), "SceneExplorer")

  -- HACK: add the missing visualizer.
  local vis = typeManager:findTypeByName("PropertyConnectionVisualizerComponent");
  if (not(vis)) then
    logger:error("Failed to solve type for PropertyConnectionVisualizerComponent");
  end
  local visUH = vis:getUnifiedHandle();
	connComp:getInstanceManager():createNewComponent(visUH, connComp:getFinalOwner(), visualizerCreatedDummy, nil)
	--	
end

-- HACK: ...
function visualizerCreatedDummy(comp, params)
  -- nop
end
--


function createdLuaExpressionComponent(luaExprCompObj, params)
	luaExprCompObj:setExpression(params.expr)

  -- accept nil input/output params too.
	if (not(params.inputEditorId) and not(params.outputEditorId)) then
	else
		local inputObj = getObjectByEditorObjectId(params.inputEditorId);
		if (not(inputObj)) then
			logger:error("failed to find input object with given editor id.")
			return
		end
		local outputObj = getObjectByEditorObjectId(params.outputEditorId);
		if (not(outputObj)) then
			logger:error("failed to find output object with given editor id.")
			return
		end

		-- parse property	names
		local inputPropIndex = parsePropertyNumberFromEditorId(params.inputEditorId)
		local outputPropIndex = parsePropertyNumberFromEditorId(params.outputEditorId)
		local inputPropName = inputObj:getPropertyName(inputPropIndex);
		local outputPropName = outputObj:getPropertyName(outputPropIndex);
		
		-- get property type based on the above index. 
		local inputPropTypeString = inputObj:getPropertyTypeString(inputPropIndex)  -- or something like this
		local outputPropTypeString = outputObj:getPropertyTypeString(outputPropIndex)  -- or something like this
		if (inputPropTypeString ~= outputPropTypeString) then
		  logger:warning("Input and output property types mismatch.");
		end
		
		-- select lua expr property input and output name based on type...
		-- such as: inBool1, inInt1, inFloat1, inVector1, inColor1, inRotation1, etc.
		local luaInPropTypeName = ""
		local luaOutPropTypeName = ""
		
		-- <LIST_OF_PROP_CONN_TYPES_HERE>
		if (inputPropTypeString == "Bool") then luaInPropTypeName = "Bool" end
		if (inputPropTypeString == "Int") then luaInPropTypeName = "Int" end
		if (inputPropTypeString == "Float") then luaInPropTypeName = "Float" end
		if (inputPropTypeString == "VC3") then luaInPropTypeName = "Vector" end
		if (inputPropTypeString == "COL") then luaInPropTypeName = "Color" end
		if (inputPropTypeString == "QUAT") then luaInPropTypeName = "Rotation" end
		if (inputPropTypeString == "Time") then luaInPropTypeName = "Time" end
		if (inputPropTypeString == "DynamicString") then luaInPropTypeName = "String" end
		if (inputPropTypeString == "UH") then luaInPropTypeName = "UH" end -- CURRENTLY UNSUPPORTED!
		
		-- <LIST_OF_PROP_CONN_TYPES_HERE>
		if (outputPropTypeString == "Bool") then luaOutPropTypeName = "Bool" end
		if (outputPropTypeString == "Int") then luaOutPropTypeName = "Int" end
		if (outputPropTypeString == "Float") then luaOutPropTypeName = "Float" end
		if (outputPropTypeString == "VC3") then luaOutPropTypeName = "Vector" end
		if (outputPropTypeString == "COL") then luaOutPropTypeName = "Color" end
		if (outputPropTypeString == "QUAT") then luaOutPropTypeName = "Rotation" end
		if (outputPropTypeString == "Time") then luaOutPropTypeName = "Time" end
		if (outputPropTypeString == "DynamicString") then luaOutPropTypeName = "String" end -- CURRENTLY UNSUPPORTED!
		if (outputPropTypeString == "UH") then luaOutPropTypeName = "UH" end -- CURRENTLY UNSUPPORTED!
		
		local luaOutPropName = "Out"..luaOutPropTypeName.."1"
		local luaInPropName = "In"..luaInPropTypeName.."1"
		
		local makeMaintainOffset = propertyAnimationModule:getCreatedConnectionsMaintainOffset()
		local makeActiveInEditor = propertyAnimationModule:getCreatedConnectionsActiveInEditorByDefault()
		
		createConnectionBetween(inputObj, inputPropName, luaExprCompObj, luaInPropName, false, makeActiveInEditor)
		createConnectionBetween(luaExprCompObj, luaOutPropName, outputObj, outputPropName, makeMaintainOffset, makeActiveInEditor)
	end
end

-- the given relatedToEditorId is supposed to be the output property editorId (or its owner component/instance) editorId,
-- since the lua expression component is created as a component for the owner instance
-- the given complete function will be called when the object is created
function createLuaExpressionComponent(luaExpr, relatedToEditorId, inputEditorId, outputEditorId)
	-- use createdLuaExpressionComponent as init func param
	
	local relatedObj = getObjectByEditorObjectId(relatedToEditorId);
	if (not(relatedObj)) then
		logger:error("failed to find output object with given editor id.")
		return
	end
  local relatedFinalOwner = relatedObj
	if (relatedObj.getFinalOwner) then relatedFinalOwner = relatedObj:getFinalOwner() end
	
  local luaExprCompType = typeManager:findTypeByName("CustomLuaExpressionComponent");
  relatedObj:getInstanceManager():createNewComponent(luaExprCompType:getUnifiedHandle(), relatedFinalOwner, createdLuaExpressionComponent, { expr=luaExpr, inputEditorId=inputEditorId, outputEditorId=outputEditorId } );
end


function createdCustomPropAnimComponent(customPropAnimCompObj, params)

	-- loop all the stuff in params.propValueParams and set their values accordingly...
	for name,value in pairs(params.propValueParams) do 
		local idx = customPropAnimCompObj:findPropertyIndexByName(name)
		if (idx ~= -1) then
			customPropAnimCompObj:setPropertyValue(idx, value)
		else
			logger:error("Failed to find property of name \"".. name .."\" in the component being added.")
		end		
	end

  -- accept nil input/output params too.
	if (not(params.inputEditorId) and not(params.outputEditorId)) then
	else
		local inputObj = getObjectByEditorObjectId(params.inputEditorId);
		if (not(inputObj)) then
			logger:error("Failed to find input object with given editor id.")
			return
		end
		local outputObj = getObjectByEditorObjectId(params.outputEditorId);
		if (not(outputObj)) then
			logger:error("Failed to find output object with given editor id.")
			return
		end

		-- parse property	names
		local inputPropIndex = parsePropertyNumberFromEditorId(params.inputEditorId)
		local outputPropIndex = parsePropertyNumberFromEditorId(params.outputEditorId)
		local inputPropName = inputObj:getPropertyName(inputPropIndex);
		local outputPropName = outputObj:getPropertyName(outputPropIndex);
		
		-- get property type based on the above index. 
		local inputPropTypeString = inputObj:getPropertyTypeString(inputPropIndex)  -- or something like this
		local outputPropTypeString = outputObj:getPropertyTypeString(outputPropIndex)  -- or something like this
		-- the types may mismatch, it depends on the component in-between them
		--if (inputPropTypeString ~= outputPropTypeString) then
		--  logger:warning("Input and output property types mismatch.");
		--end
		-- they must match those of the component in-between though.
		local compInputPropIndex = customPropAnimCompObj:findPropertyIndexByName(params.inputPropName)
		local compOutputPropIndex = customPropAnimCompObj:findPropertyIndexByName(params.outputPropName)			
		local compInputPropTypeString = customPropAnimCompObj:getPropertyTypeString(compInputPropIndex)
		local compOutputPropTypeString = customPropAnimCompObj:getPropertyTypeString(compOutputPropIndex)
		
		local compOutPropName = params.outputPropName
		local compInPropName = params.inputPropName
		
		local makeMaintainOffset = propertyAnimationModule:getCreatedConnectionsMaintainOffset()
		local makeActiveInEditor = propertyAnimationModule:getCreatedConnectionsActiveInEditorByDefault()
		
		if (inputPropTypeString == compInputPropTypeString) then
			createConnectionBetween(inputObj, inputPropName, customPropAnimCompObj, compInPropName, false, makeActiveInEditor)	
		else
			logger:error("Input property type is of type \"".. inputPropTypeString .."\", when expected \"".. compInputPropTypeString .."\".");
		end
		if (outputPropTypeString == compOutputPropTypeString) then
			createConnectionBetween(customPropAnimCompObj, compOutPropName, outputObj, outputPropName, makeMaintainOffset, makeActiveInEditor)		
		else
			logger:error("Input property type is of type \"".. outputPropTypeString .."\", when expected \"".. compOutputPropTypeString .."\".");
		end
		
	end
end

-- the given relatedToEditorId is supposed to be the output property editorId (or its owner component/instance) editorId,
-- since the lua expression component is created as a component for the owner instance
-- the given complete function will be called when the object is created
function createCustomPropAnimComponent(relatedToEditorId, inputEditorId, outputEditorId, componentTypeName, inputPropName, outputPropName, propValueParams)
	-- use createdCustomPropAnimComponent as init func param
	
	local relatedObj = getObjectByEditorObjectId(relatedToEditorId);
	if (not(relatedObj)) then
		logger:error("Failed to find related object with given editor id.")
		return
	end
    local relatedFinalOwner = relatedObj
	if (relatedObj.getFinalOwner) then relatedFinalOwner = relatedObj:getFinalOwner() end
	
    local custCompType = typeManager:findTypeByName(componentTypeName);
    if (not(custCompType)) then
		logger:error("Failed to find the required type \"" .. componentTypeName .. "\" for creation of the connection.")
        return
    end  
    relatedObj:getInstanceManager():createNewComponent(custCompType:getUnifiedHandle(), relatedFinalOwner, createdCustomPropAnimComponent, 
        { inputEditorId=inputEditorId, outputEditorId=outputEditorId, inputPropName=inputPropName, outputPropName=outputPropName, propValueParams=propValueParams } );
end



function deleteAllPropertyConnectionsToAndFromEditorId(editorId)
	local relatedObj = getObjectByEditorObjectId(editorId);
	if (not(relatedObj)) then
		logger:error("failed to find object with given editor id.")
		return
	end

	local propIndex = parsePropertyNumberFromEditorId(editorId)
	local propName = relatedObj:getPropertyName(propIndex);

	propertyAnimationModule:deleteAllConnectionsToAndFromProperty(relatedObj, propName, state)
	
	syncObjectHierarchy(relatedObj:getGuid(), "SceneExplorer")
end


function showConnectionsFromEditorId(editorId, inputs)
	local relatedObj = getObjectByEditorObjectId(editorId);
	if (not(relatedObj)) then
		logger:error("failed to find object with given editor id.")
		return
	end

	local propIndex = parsePropertyNumberFromEditorId(editorId)
	local propName = relatedObj:getPropertyName(propIndex);

	local connList = propertyAnimationModule:getConnectionListForProperty(relatedObj, propName, inputs, false)

	local listenerId = "ReferencesList"
	externalUI:sendUICommand("sync(\"" .. listenerId .. "\", \"" .. connList .. "\")")
	externalUI:sendUICommand("openReferencesList()")
end


function disableNetSyncForOutputEditorId(editorId)
	local relatedObj = getObjectByEditorObjectId(editorId);
	if (not(relatedObj)) then
		logger:error("failed to find object with given editor id.")
		return
	end

	local propIndex = parsePropertyNumberFromEditorId(editorId)
	local propName = relatedObj:getPropertyName(propIndex);

	local connList = propertyAnimationModule:getConnectionListForProperty(relatedObj, propName, false, true)
	
	local listenerId = "PropertyModifier"
	externalUI:sendUICommand("sync(\"" .. listenerId .. "\", \"" .. connList .. "\")")
	externalUI:sendUICommand("setUIValue(\"@PropertyModifierWindow.luaExpressionTextBox\", \"editor.PropertyModifier.changePropertyValue(editor.PropertyModifier.propModGetFinalOwner(${guid}), [[NetSyncMode]], engine.base.NetSyncModeDisabledRecursively)\")")
end


----------------------------------------------------------------------------------------------------------
-- AI toolbar stuff
--

function aiDisableAI(enabled)
	-- HACK: / TODO: Trine 2 specific ai enabling/disabling here. AiEnabled property should be in some engine ai character component
	
	local enableAI = false;	
	if enabled then
		enableAI = false;
	else
		enableAI = true;
	end	
	-- NOTE: This enables visualization for players etc. as well
	local rootTypeName = "ActorEntity";
	editor.Util.setComponentBoolPropertyForAllInstances("AiEnabled", enableAI, trinebase.gameplay.ai.Trine3DAICharacterComponent.getStaticClassId(), rootTypeName);
end

function aiVisualizeAIPathHelpers(enabled)
	debug.Visualize.visualizeAIPathHelpers(enabled);
end

function aiVisualizeAIPathHelperAreas(enabled)
	debug.Visualize.visualizeAIPathHelperAreas(enabled);
end

function visualizeTargetComponentsAndNavigationComponents(enabled)
	debug.Visualize.visualizeTargetComponents(enabled);
	debug.Visualize.visualizeNavigationComponents(enabled);
end

function visualizeNavigationMesh(enabled)
	pathfindModule:setVisualizeNavigationMesh(enabled);
end

function visualizeNavigationMeshWithRange(enabled)
	pathfindModule:setVisualizeNavigationMeshWithRange(enabled);
end

function aiVisualizeAIAreas(enabled)
	debug.Visualize.visualizeAIAreas(enabled);
end

function aiVisualizeAINetSyncs(enabled)
	debug.Visualize.visualizeAINetSyncs(enabled);
end

function visualizeAllNetSyncs(enabled)
	debug.Visualize.visualizeAllNetSyncs(enabled);
end

function aiVisualizeAIProperties(enabled)
	debug.Visualize.visualizeAIProperties(enabled);
end

----------------------------------------------------------------------------------------------------------
-- Misc toolbar stuff
--

function visualizePhysicsCollisions(enabled)
	local scene = common.CommonUtils.getScene()
	if not scene then
		logger:error("editor.ExternalUI.visualizePhysicsCollisions: Cannot toggle physics collision visualization, couldn't get scene.") 
		return 
	end

	local physicsScene = scene:getPhysicsScene()
	if not physicsScene then
		logger:error("editor.ExternalUI.visualizePhysicsCollisions: Cannot toggle physics collision visualization, couldn't get physics scene.")
		return
	end

	state:setVisualizePhysicsCollisions(enabled)
	physicsScene:setVisualizePhysicsCollisionsNew(enabled)
	if enabled then
		renderingModule:setGeometryEnabled(false)
	else
		renderingModule:setGeometryEnabled(true)
	end
end

function updatePhysicsCollisionVisualization()
	local scene = common.CommonUtils.getScene()
	if not scene then
		logger:error("editor.ExternalUI.updatePhysicsCollisionVisualization: Cannot update physics collision visualization, couldn't get scene.") 
		return 
	end

	local physicsScene = scene:getPhysicsScene()
	if not physicsScene then
		logger:error("editor.ExternalUI.updatePhysicsCollisionVisualization: Cannot update physics collision visualization, couldn't get physics scene.")
		return
	end
	if physicsScene:getVisualizePhysicsCollisionsNew() then
		physicsScene:setVisualizePhysicsCollisionsNew(true)
	end
end

function toggleModelRendering()
	if renderingModule:getGeometryEnabled() then
		renderingModule:setGeometryEnabled(false)
	else
		renderingModule:setGeometryEnabled(true)
	end
end

----------------------------------------------------------------------------------------------------------

function insertEntity(typeId)
	if(state.selectInsertTool)
	then
		-- in editor: just use insert tool
		startInsertingType(typeId)
	else
	
		local typ = getObjectByEditorObjectId(typeId)

		if(typ) then
			if(not typ:doesInheritType(typeManager:findTypeByName("Entity"))) then
				sendGameLogMessageToExternalUI("Cannot create instance from '" .. typ:getName() .. "', does not inherit from Entity", 1);
				return
			end
			if(typ:isAbstractType()) then
				sendGameLogMessageToExternalUI("Cannot create instance from '" .. typ:getName() .. "', type is abstract", 1);
				return
			end
			editor.Util.spawnInstanceByTypeNearPlayer(typ)

			--old way:
			--local im = gameScene:getSceneInstanceManager();
			--im:createNewInstance(typ:getUnifiedHandle(), newInstanceFunction, nil);
		end
	end
end


----------------------------------------------------------------------------------------------------------


function addQATaskEntityAtCamera(taskId)
	local function newInstanceFunction(obj, params)
		if not obj then logger:error("addQATaskEntityAtCamera::newInstanceFunction - obj is nil") return end
		-- Paranoid test
		if not obj.getGuid then logger:error("addQATaskEntityAtCamera::newInstanceFunction - obj is nil") return end
		local qaComp = obj:findComponent(editor.component.QualityAssuranceTaskComponent)
		if not qaComp then logger:error("addQATaskEntityAtCamera::newInstanceFunction - obj doesn't appear to have QualityAssuranceTaskComponent") return end
		qaComp:setId(params.taskId)
		if state.getSelectedLayer then obj:setLayer(state:getSelectedLayer()) end
		externalUI:sendUICommand("deliverQATaskGuid(\"" .. params.taskId .. "\", \"" .. tostring(obj:getGuid()) .. "\")")
	end
	
	local typ = typeManager:findTypeByName("QualityAssuranceTaskEntity")
	if typ then
		local params = {}
		params["taskId"] = taskId
		-- If available, use scene, otherwise use gameScene (first one in game, second one always)
		local s = scene
		if not s then
			s = gameScene
		end
		
		if s then
			if not s:isStarted() then
				-- don't create during loading
				state:runLuaStringWithDelay("editor.ExternalUI.addQATaskEntityAtCamera(" .. taskId .. ")", 1000)
			else
				s:getSceneInstanceManager():createNewInstance(typ:getUnifiedHandle(), newInstanceFunction, params)
			end
		end
	else
		logger:error("addQATaskEntityAtCamera - Could not find type of QualityAssuranceTaskEntity")
	end
end


function updateQATaskEntity(guidStr, id, description, position)
	local guid = parseObjectFromStringValue(guidStr)
	if guid then
		local task = getInstanceByGUID(guid)
		if task then
			local qaComp = task:findComponent(editor.component.QualityAssuranceTaskComponent)
			if qaComp then
				qaComp:updateFromEditor(id, description, parseObjectFromStringValue(position))
			else
				logger:error("updateQATask - Could not find QualityAssuranceTaskComponent")
			end
		else
			-- This may not be an error. If this happens often, it probably isn't.
			-- Edit: Happens sometimes on map change.
			-- logger:error("updateQATask - Could not find task with guid " .. tostring(guid))
		end
	else
		logger:error("updateQATask - Could not parse guid from string " .. guidStr)
	end
end

function flattenedCameraPosition()
	local camPos = getCameraPosition()
	if not camPos then
		logger:error("startAddPositionedQATaskAtCamera - Error getting camera position")
		return nil
	end
	if engine.base.mathbase.GameDirections.cameraIs2d then
		local flat = engine.base.mathbase.GameDirections.sceneMostFlatAxis
		camPos = camPos - flat * camPos:getDotWith(flat)
	end
	return camPos
end

function startAddPositionedQATaskAtCamera()
	local position = flattenedCameraPosition()
	if position then
		externalUI:sendUICommand("sync(\"TaskList\", \"CameraPosition\", \"" .. tostring(position) .. "\")")
	end
end

function startAddPositionedQATaskAtCharacter()
	local scene = common.CommonUtils.getScene()
	if not scene then return end
	
	local instanceManager = scene:getSceneInstanceManager()
	if not instanceManager then return end
	
	local pm = common.CommonUtils.getPlayerManager()
	if pm ~= nil then
		local instance = pm:getCharacterInstanceForPlayer(0);
		if instance ~= nil then
			local playerPos = instance:getTransformComponent():getPosition();
			externalUI:sendUICommand("sync(\"TaskList\", \"CameraPosition\", \"" .. tostring(playerPos) .. "\")")
			return
		end
	else
		logger:error("startAddPositionedQATaskAtCharacter: Couldn't get PlayerManager.")
	end

	logger:error("Couldn't find active character from scene.")
end

function sendQATaskEntityUpdate(id, positionStr)
	externalUI:sendUICommand("sync(\"TaskList\", \"".. id .. "\", \"" .. positionStr .. "\")")
end


function addQATask(description, map, positioned)
	local mapStr
	local positionedStr
	if not description then description = "N/A" end
	if map then mapStr = "true" else mapStr = "false" end
	if positioned then positionedStr = "true" else positionedStr = "false" end
	externalUI:sendUICommand("addQATask(\"" .. description .. "\", \"" .. mapStr .. "\", \"" .. positionedStr .. "\")")
end


function deleteQATaskEntity(guidStr)
	local guid = parseObjectFromStringValue(guidStr)
	if guid then
		local task = getInstanceByGUID(guid)
		if task then
			-- If available, use scene, otherwise use gameScene (first one in game, second one always)
			if scene then
				scene:getSceneInstanceManager():deleteInstance(task:getUnifiedHandle())
			else
				gameScene:getSceneInstanceManager():deleteInstance(task:getUnifiedHandle())
			end
		else
			-- When map is closed, everything gets deleted of course. Seems like that at least 
			-- sometimes that happens before we have time to explicitly delete QATaskEntities. So 
			-- this isn't necessarily an error.
			--logger:error("deleteQATaskEntity - Could not find task with guid " .. tostring(guid))
		end
		externalUI:sendUICommand("acknowledgeQATaskEntityDeletion(\"" .. tostring(guidStr) .. "\")")
	else
		logger:error("deleteQATaskEntity - Could not parse guid from string " .. guidStr)
	end
end


function locateQATask(guidStr)
	local guid = getGUIDFromGUIDString(guidStr)
	if guid then
		local inst = getInstanceByGUID(guid)
		if inst then
			if not inst:isInherited(engine.instance.Entity.getStaticObjectClass()) then
				logger:error("editor.externalUI - locateQATask() - Given GUID points to something else than QATaskEntity")
				return
			end
			moveCameraToShowPosition(inst:getTransformComponent():getPosition())
		else
			logger:error("editor.externalUI - locateQATask() - No object found for given GUID")
		end
	end
end


function setEmergencyQATaskVisualization(emergency, normal)
	if emergency then
		useEmergencyQAVisualization = true
	else
		useEmergencyQAVisualization = nil
	end
	
	if not normal then
		return
	end
	
	local qaEntityType = typeManager:findTypeByName("QualityAssuranceTaskEntity")
	local qaEntityTypeUH = qaEntityType:getUnifiedHandle()
	
	-- If available, use scene, otherwise use gameScene (first one in game, second one always)
	local root = gameScene:getSceneInstanceManager():getTopmostInstanceRoot()
	if scene then
		root = scene:getSceneInstanceManager():getTopmostInstanceRoot()
	end
	local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilter(root, "0,All", editor.Editor.InfiniteDepth, false)
	local obj = resultIterator:next()
	
	while obj do
		if obj:getType() == qaEntityTypeUH then
			local aec = obj:findComponent(gameplay.effect.AttachEffectComponent)
			aec:setEnabled(emergency)
			local esevc = obj:findComponent(rendering.EditableScriptingEntityVisualizerComponent)
			esevc:setVisible(true)
		end
		obj = resultIterator:next()
	end
end


--------------------------------------------------------------------------------

function exportMapAsOBJ(filename, exportOnlySelection, exportOnlySolid)
	if state.exportMapAsOBJ then
		state:exportMapAsOBJ(filename, exportOnlySelection, exportOnlySolid);
	end
end


function selectDuplicateObjects()
	state:clearSelection()
	local objects = {}
	local types = {}
	local root = instanceManager:getTopmostInstanceRoot()
	local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilter(root, "0,All", editor.Editor.InfiniteDepth, false)
	local obj = resultIterator:next()
	obj = resultIterator:next()
	while (obj) do
		table.insert(objects, obj)
		table.insert(types, obj:getType())
		obj = resultIterator:next()
	end
	for i = 1, # objects do
		for j = i+1, # objects do
			if types[i] == types[j] then
				if isDuplicate(objects[i], objects[j]) then
					local editorSelectionComponent = objects[i]:findComponent(editor.component.EditorSelectionComponent)
					if editorSelectionComponent then
						editorSelectionComponent:setSelected(true)
					end
				end
			end
		end		
	end
end


function isDuplicate(obj1, obj2)
	local trans1 = obj1:findComponent(engine.component.TransformComponent)
	local trans2 = obj2:findComponent(engine.component.TransformComponent)
	if trans1 and trans2 then
		local pos1 = trans1:getPosition()
		local pos2 = trans2:getPosition()
		if math.abs(pos1.x-pos2.x) + math.abs(pos1.y-pos2.y) + math.abs(pos1.z-pos2.z) < 0.02 then
			local rot1 = trans1:getRotation()
			local rot2 = trans2:getRotation()
			if math.abs(rot1.x-rot2.x) + math.abs(rot1.y-rot2.y) + math.abs(rot1.z-rot2.z) + math.abs(rot1.w-rot2.w) < 0.02 then
				local model1 = obj1:findComponent(rendering.ModelComponent)
				local model2 = obj2:findComponent(rendering.ModelComponent)	
				if model1 and model2 then
					local scale1 = model1:getScale()
					local scale2 = model2:getScale()
					if math.abs(scale1.x-scale2.x) + math.abs(scale1.y-scale2.y) + math.abs(scale1.z-scale2.z) < 0.02 then
						return true
					end
				else
					return true
				end
			end
		end
	end
	return false
end


function updatePropertyDescription(guidStr, propertyIndex, propertyGridId)
	local guid = parseObjectFromStringValue(guidStr)
	if guid then
		local obj = getObjectByGUID(guid)
		if obj then
			local description = obj:getPropertyDescription(propertyIndex)
			externalUI:sendUICommand("deliverPropertyDescription(\"" .. propertyGridId .. "\", \"" .. description .. "\")")
		end
	end
end


function updateComponentDescription(ownerGuidStr, componentName, propertyGridId)
	local guid = parseObjectFromStringValue(ownerGuidStr)
	if guid then
		local owner = getObjectByGUID(guid)
		if owner then
			local description = ""
			if owner:isInherited(engine.base.InstanceBase.getStaticObjectClass()) then
				local componentType = typeManager:findTypeByName(componentName)
				if componentType then
					local component = nil;
					-- Special cased root handling
					if propertyGridId == 0 then
						component = owner;
					else
						component = owner:findComponentByExactType(componentType:getUnifiedHandle());
					end
					if component ~= nil then
						description = "References: " .. component:getReferenceString()
						if component:getErrors() ~= 0 then
							description = description .. "\nErrors: " .. component:getErrors()
						end
						if component:getWarnings() ~= 0 then
							description = description .. "\nErrors: " .. component:getWarnings()
						end
					end
				end
			elseif owner:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) then
				local componentType = typeManager:findTypeByName(componentName)
				if componentType then
					description = "References: " .. componentType:getReferenceString()
					if componentType:getErrors() ~= 0 then
						description = description;
					end
					if componentType:getWarnings() ~= 0 then
						description = description;
					end
				end
			else
				return
			end
			externalUI:sendUICommand("deliverPropertyDescription(\"" .. propertyGridId .. "\", \"" .. description .. "\")")
		end
	end
end

-- CAMERA BUTTONS STUFF
function setCameraCurrentViewToSelectedArea()

	--[[
	-- NOTE: This code should only be enabled on Epic branch!
	-- EPIC SUPER HACK!!!
	-- Reuse the "View->Area" editor button for Epic (it's broken anyway)
	do
		epicMoveCameraToTarget()
		return
	end
	]]--

    local filterString = "0,data/filter/native/nativefilter_composite_denyall_denyall|1,data/filter/native/nativefilter_orcomposite_selectedineditor_allowall" 
    local maxDepth = 99999 
    local forceParentsOfMatchesToMatch = false; 
    local root = instanceManager:getTopmostInstanceRoot() 
    local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilter(root, filterString, maxDepth, forceParentsOfMatchesToMatch) 
    local obj = resultIterator:next()  
    local traPos, traPosZ, posOff, tarOff, position, target, direction, directionNormalized = nil
    local selectedObjects = {}
    while (obj) do
        table.insert(selectedObjects, obj)
        obj = resultIterator:next()
    end 
    if (#selectedObjects == 0) then
        logger:error("No camera area selected")
        return
    elseif (#selectedObjects > 1) then
        logger:error("You can't set camera view to more than one camera area at a time")
        return
    else
        for i, obj in pairs(selectedObjects) do
            local sceneInstanceManager = gameScene:getSceneInstanceManager()  
            local camSys = sceneInstanceManager:findInstanceByName("EditorCamera")
            if camSys then
                local transComp = camSys:findComponent(engine.component.TransformComponent)
                if transComp then
                    position = transComp:getPosition()
                else
                    logger:error("No TransformComponent found")
                    return
                end
                local camComp = camSys:findComponent(rendering.CameraComponent)
                if camComp then
                    target = camComp:getOutCurrentCameraTargetPosition()
                end
            else
                logger:error("No EditorCamera found")
                return
            end
            local transComp = obj:findComponent(engine.component.TransformComponent)  
            if transComp then
                traPos = transComp:getPosition()
            else
                logger:error("No TransformComponent found")
                return
            end 
			local rot = transComp:getRotation()
			local invRot = rot:getInverse()
            direction = target - position
            directionNormalized = direction:getNormalized()
            posOff = position - traPos
			local normal = rot:getRotated(VC3(0,0,1))
            tarOff = engine.base.mathbase.util.intersectDirectionOnPlane(position, directionNormalized, normal, normal:getDotWith(traPos))
            local tarOffFinal = tarOff - traPos
            local camComp = obj:findComponent(trinebase.gameplay.TrineCameraPropertiesComponent)
            if camComp then
                camComp:setPositionOffset(invRot:getRotated(posOff))
                camComp:setTargetOffset(invRot:getRotated(tarOffFinal) + VC3(0, 0, 0.1))
            else
                logger:error("No TrineCameraPropertiesComponent found")
                return
            end
        end
    end 
end


-- obj is the camera area entity objects
-- absoluteNormalizedOffset 
--   when true, x/y/zOffset are normalized absolute offsets within the area 0.0 - 1.0 (Left-Right, Top-Bottom), absolute meaning the original entity position gets ignored
--   when false, x/y/zOffset are relative offset (meters) to the original entity position
-- (notice, that the entity position is the "base pose position" for the player, this is the camera you normally set in the editor, and any player offset to that gets applied
-- based on the follow factors. Those offset values are two ways of providing this, either in relation to the camera's default position or as an absolute position within the area thus ignoring the camera default position)
-- by using the absoluteNormalizedOffset you can get the camera area corner views (assuming the area is centered at gameplay area), i.e. view when the player is specific corner
--   player in top left corner: 0.0, 0.5, 1.0
--   player in top right corner: 1.0, 0.5, 1.0
--   player in bottom left corner: 0.0, 0.5, 0.0
--   player in bottom right corner: 1.0, 0.5, 0.0
function applyCameraAreaToView(obj, absoluteNormalizedOffset, xOffset, yOffset, zOffset, absGlobalXOffsetOpt, absGlobalYOffsetOpt, absGlobalZOffsetOpt)
	assert_entity(obj)
	assert_boolean(absoluteNormalizedOffset)
	assert_number(xOffset)
	assert_number(yOffset)
	assert_number(zOffset)
	assert_number_or_nil(absGlobalXOffsetOpt)
	assert_number_or_nil(absGlobalYOffsetOpt)
	assert_number_or_nil(absGlobalZOffsetOpt)

	local traRot;
	local transComp = obj:findComponent(engine.component.TransformComponent)  
	if transComp then
			traPos = transComp:getPosition()
			traRot = transComp:getRotation()
	else
			logger:error("No TransformComponent found")
			return false
	end
	local camComp = obj:findComponent(trinebase.gameplay.TrineCameraPropertiesComponent)
	if camComp then
			posOff = camComp:getPositionOffset()
			tarOff = camComp:getTargetOffset()   
			posFollow = camComp:getPositionFollowFactor()
			tarFollow = camComp:getTargetFollowFactor()   
			uVec = camComp:getUpVector()
			dofScale = camComp:getDepthOfFieldScale()
			dofSharp = camComp:getDepthOfFieldFocalSharpRange()
			dofBlur = camComp:getDepthOfFieldFocalBlurRange()
			dofDepth = camComp:getDepthOfFieldWorldDepth()
			fov = camComp:getFOV()
			range = camComp:getRange()
	else
			logger:error("No TrineCameraPropertiesComponent found")
			return false
	end        
	position = traPos + traRot:getRotated(posOff)
	target = traPos + traRot:getRotated(tarOff + VC3(0, 0, 0.1));		

	-- apply offset...
	local offsetVec = VC3(xOffset, yOffset, zOffset)
	if (absoluteNormalizedOffset) then
		-- calculate the position from the bottom-left corner based on the dimensions and normalized relative position
		local areaComp = obj:findComponent(area.BoxAreaComponent)
		local posWithNormOffset = traPos
		if areaComp then
			local areaDim = areaComp:getDimensions()
			local halfDim = areaDim * 0.5
			local areaOffset = areaComp:getOffset()
			-- NOTE: this stuff works for unrotated areas only!
			local globalCenter = traPos + areaOffset
			local globalMinCorner = globalCenter - halfDim
			posWithNormOffset = globalMinCorner + (offsetVec * areaDim)
		else
			logger:error("No BoxAreaComponent found")
			return false		
		end
		local diffToTraPos = posWithNormOffset - traPos
		
		position = position + (diffToTraPos * posFollow)
		target = target + (diffToTraPos * tarFollow)
	else	
		position = position + (offsetVec * posFollow)
		target = target + (offsetVec * tarFollow)
	end
	
	if (absGlobalXOffsetOpt ~= nil) then
		position = position + VC3(absGlobalXOffsetOpt, 0, 0)
		target = target + VC3(absGlobalXOffsetOpt, 0, 0)
	end
	if (absGlobalYOffsetOpt ~= nil) then
		position = position + VC3(0, absGlobalYOffsetOpt, 0)
		target = target + VC3(0, absGlobalYOffsetOpt, 0)
	end
	if (absGlobalZOffsetOpt ~= nil) then
		position = position + VC3(0, 0, absGlobalZOffsetOpt)
		target = target + VC3(0, 0, absGlobalZOffsetOpt)
	end
	
	fVec = target - position
	fVecNormalized = fVec:getNormalized()
	finalQUAT = engine.base.mathbase.util.directionToRotationFreePitch(fVecNormalized, QUAT.identity, uVec,
	engine.base.mathbase.GameDirections.cameraForwardVector, engine.base.mathbase.GameDirections.cameraUpVector)       
	local sceneInstanceManager = gameScene:getSceneInstanceManager()
	local camSys = sceneInstanceManager:findInstanceByName("EditorCamera")
	if camSys then
			local transComp = camSys:findComponent(engine.component.TransformComponent)
			if transComp then
					transComp:setPosition(position)
					transComp:setRotation(finalQUAT)
			else
					logger:error("No TransformComponent found")
					return false
			end
			local camComp = camSys:findComponent(rendering.CameraComponent)
			if camComp then
					camComp:setDepthOfFieldScale(dofScale)
					camComp:setDepthOfFieldFocalSharpRange(dofSharp)
					camComp:setDepthOfFieldFocalBlurRange(dofBlur)
					camComp:setDepthOfFieldWorldDepth(dofDepth)
					camComp:setCameraFOV(fov)
					camComp:setCameraRange(range)
					return true
			else
					logger:error("No CameraComponent found")
					return false
			end
	else
			logger:error("No EditorCamera found")
			return false
	end     
end

camToViewUseAbsoluteNormalizedOffset = false
camToViewOffsetX = 0.0
camToViewOffsetY = 0.0
camToViewOffsetZ = 0.0
camToViewVelX = 0.0
camToViewVelY = 0.0
camToViewVelZ = 0.0
declareReload(thisModule, [[camToViewUseAbsoluteNormalizedOffset]])
declareReload(thisModule, [[camToViewOffsetX]])
declareReload(thisModule, [[camToViewOffsetY]])
declareReload(thisModule, [[camToViewOffsetZ]])
declareReload(thisModule, [[camToViewVelX]])
declareReload(thisModule, [[camToViewVelY]])
declareReload(thisModule, [[camToViewVelZ]])

function setCameraAreaToViewSettings(useAbsoluteNormalizedOffset, offsetX, offsetY, offsetZ, velX, velY, velZ)
	camToViewUseAbsoluteNormalizedOffset = useAbsoluteNormalizedOffset
	camToViewOffsetX = offsetX
	camToViewOffsetY = offsetY
	camToViewOffsetZ = offsetZ
	camToViewVelX = velX
	camToViewVelY = velY
	camToViewVelZ = velZ
end

function glideCameraAreaValues()
	-- TODO: get the actual state/scene time and assume the velocity values are in normalized offsets per second, calculate accordingly
	-- HACK: applying velocities for gliding with the assumption of this getting called 30 FPS... 
	local timeDelta = 1 / 30;
	if (camToViewVelX ~= 0) then
		camToViewOffsetX = camToViewOffsetX + camToViewVelX * timeDelta;
		if (camToViewOffsetX > 1.0) then
			camToViewOffsetX = 0.0
		end
		if (camToViewOffsetX < 0.0) then
			camToViewOffsetX = 1.0
		end
	end
	if (camToViewVelY ~= 0) then
		camToViewOffsetY = camToViewOffsetY + camToViewVelY * timeDelta;
		if (camToViewOffsetY > 1.0) then
			camToViewOffsetY = 0.0
		end
		if (camToViewOffsetY < 0.0) then
			camToViewOffsetY = 1.0
		end
	end
	if (camToViewVelZ ~= 0) then
		camToViewOffsetZ = camToViewOffsetZ + camToViewVelZ * timeDelta;
		if (camToViewOffsetZ > 1.0) then
			camToViewOffsetZ = 0.0
		end
		if (camToViewOffsetZ < 0.0) then
			camToViewOffsetZ = 1.0
		end
	end
end

lastAppliedCameraGuid = GUID_NONE
declareReload(thisModule, [[lastAppliedCameraGuid]])

function setCameraSelectedAreaToCurrentView()
    local filterString = "0,data/filter/native/nativefilter_composite_denyall_denyall|1,data/filter/native/nativefilter_orcomposite_selectedineditor_allowall" 
    local maxDepth = 99999 
    local forceParentsOfMatchesToMatch = false; 
    local root = instanceManager:getTopmostInstanceRoot() 
    local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilter(root, filterString, maxDepth, forceParentsOfMatchesToMatch) 
    local obj = resultIterator:next()  
    local traPos, posOff, tarOff, fVec, uVec, position, target, finalQUAT, fVecNormalized, dofScale, dofSharp, dofBlur, dofDepth, fov, range = nil
    local selectedObjects = {}
    while (obj) do
        table.insert(selectedObjects, obj)
        obj = resultIterator:next()
    end 
    if (#selectedObjects == 0) then
        logger:error("No camera area selected")
        return
    elseif (#selectedObjects > 1) then
        logger:error("You can't select more than one camera area as a view")
        return
    else
        for i, obj in pairs(selectedObjects) do
						lastAppliedCameraGuid = obj:getGuid()
						applyCameraAreaToView(obj, camToViewUseAbsoluteNormalizedOffset, camToViewOffsetX, camToViewOffsetY, camToViewOffsetZ)
        end
    end   
end

function loopedCameraAreaPropertiesToCurrentView() 
	local sceneInstanceManager = gameScene:getSceneInstanceManager()
	local traPos, posOff, tarOff, fVec, uVec, position, target, finalQUAT, fVecNormalized, dofScale, dofSharp, dofBlur, dofDepth, fov, range = nil
	for i, objGUID in pairs(selectedCameraAreas) do
		local obj = sceneInstanceManager:findInstanceByGUID(objGUID)
		if(not obj) then
			table.remove(selectedCameraAreas, i)
		else
			glideCameraAreaValues()
			return applyCameraAreaToView(obj, camToViewUseAbsoluteNormalizedOffset, camToViewOffsetX, camToViewOffsetY, camToViewOffsetZ)
		end
	end
end

function stickCameraToCameraArea()
	stickToCameraEnabled = true
	local filterString = "0,data/filter/native/nativefilter_composite_denyall_denyall|1,data/filter/native/nativefilter_orcomposite_selectedineditor_allowall" 
    local maxDepth = 99999 
    local forceParentsOfMatchesToMatch = false; 
    local root = instanceManager:getTopmostInstanceRoot() 
    local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilter(root, filterString, maxDepth, forceParentsOfMatchesToMatch) 
    local obj = resultIterator:next()
	if obj ~= nil and obj:findComponent(trinebase.gameplay.TrineCameraPropertiesComponent) then
		lastViewedCamera = GUID(obj:getGuid())
	end
	if obj == nil or not obj:findComponent(trinebase.gameplay.TrineCameraPropertiesComponent) then
		selectedCameraAreas = {}
		table.insert(selectedCameraAreas, lastViewedCamera)
		stickToCameraImpl()
		return
	end
	while (obj) do
		table.insert(selectedCameraAreas, GUID(obj:getGuid()))
		obj = resultIterator:next()
	end
	if (#selectedCameraAreas == 0) then
		if lastViewedCamera ~= nil then
			selectedCameraAreas = {}
			table.insert(selectedCameraAreas, lastViewedCamera)
			stickToCameraImpl()
			return
		else
			logger:error("No camera area selected")
			stickToCameraEnabled = false
			return
		end
	end
	if (#selectedCameraAreas > 1) then
        logger:error("You can't select more than one camera area as a view")
		unstickCameraFromCameraArea()
        return
	end

	stickToCameraImpl()
end

function stickToCameraImpl()
	if not stickToCameraEnabled then
		return
	end
	if loopedCameraAreaPropertiesToCurrentView() then
		state:runLuaStringWithDelay("editor.ExternalUI.stickToCameraImpl()", 3)
	end
end

function unstickCameraFromCameraArea()
	stickToCameraEnabled = false
	selectedCameraAreas = {}
end
----------------------------------------------------------------------------------------------------------

function takeScreenShot()
	state:takeScreenShot();
end

----------------------------------------------------------------------------------------------------------

-- a function called whenever the object selections change in the editor
function editorSelectionChanged()
	-- tell the object visibility window script that it may need to update
	if (editor.ObjectVisibility) then
		editor.ObjectVisibility.selectionChanged()
	else
		logger:error("editor.ObjectVisibility is missing.");
	end
	
	for i = 1,#selectionChangeListeners do
		selectionChangeListeners[i]()
	end
end

----------------------------------------------------------------------------------------------------------

function selectedWidget(editorId)
	local obj = getObjectByEditorObjectId(editorId);
	if (obj and guiRoot) then
		guiRoot:setDebugWidget(obj)
	end
end

----------------------------------------------------------------------------------------------------------

function selectedGui3Widget(editorId)
	local obj = getObjectByEditorObjectId(editorId);
	if (obj and rootWidget ~= nil) then
		rootWidget:setDebugWidget(obj)
	end
end

----------------------------------------------------------------------------------------------------------

function reloadSoundBanks()
	audioModule:reloadBanks()
end

----------------------------------------------------------------------------------------------------------

-- NOTICE: this is editor UI/dev cheat thingy! Do NOT use this function for final game scripting!
function loadNextMission()
	if (state:isEditorState()) then
		logger:error("loadNextMission is only available during the game mode.")
		return
	end
	
	mission.MissionChangeUtil.changeToNextMissionDirectly()
end

----------------------------------------------------------------------------------------------------------

function setCustomResourceSizeLimit(limitKilobytes)
	filteringModule:setCustomResourceSizeLimitKilobytes(limitKilobytes)
end

----------------------------------------------------------------------------------------------------------

function setCustomResourceGraphicsSizeLimit(limitKilobytes)
	filteringModule:setCustomResourceGraphicsSizeLimitKilobytes(limitKilobytes)
end

----------------------------------------------------------------------------------------------------------

function setResourceSizeFilterPlatform(resourcePlatform)
	filteringModule:setResourceSizeFilteringPlatform(resourcePlatform)
end

----------------------------------------------------------------------------------------------------------

function resourcesTopList(numMainEntries, numGraphicsEntries)
	if state.isEditorSyncEnabled and not state:isEditorSyncEnabled() then return end
	local listenerId = "ResourceExplorer"
	local resourceGraphRoot = editor.Editor.getResourceTopListForExternalUI(numMainEntries, numGraphicsEntries)
	clearSyncDataListener(listenerId)
	externalUI:sendUICommand("sync(\""..listenerId.."\", \""..resourceGraphRoot.."\")")
end

----------------------------------------------------------------------------------------------------------

function resolveAllConnectionConflicts()
	-- HACK: must clear the errors first, otherwise any remaining conflicts won't be noticed at map reload...
	app:clearAllErrorTags()
	
	-- HACK: prevent errors that occur temporarily during adding of the individual conflict resolvers...
	propertyAnimationModule:setDisableConflictResolverErrors(true)
	
	local numResolversAdded = 0
	local numPossiblyConflictingInstance = propertyAnimationModule:getNumPossiblyConnectionConflictingInstances();
	
	local custCompType = typeManager:findTypeByName("PropertyConnectionConflictResolverComponent");
	if (not(custCompType)) then
		logger:error("Failed to find the required type \"PropertyConnectionConflictResolverComponent\" for conflict resolve.")
		return
	end  
		
	for i=0,numPossiblyConflictingInstance-1 do
		local uh = propertyAnimationModule:getPossiblyConnectionConflictingInstance(i);
		
		-- does it really still really need conflict resolving?
		-- if so, add the connection conflict resolver component...		
		
		-- start by solving the final owner (entity)
		local instance = nil
		if scene then
			instance = scene:getSceneInstanceManager():getInstanceByUH(uh);
		else
			if gameScene then
				instance = gameScene:getSceneInstanceManager():getInstanceByUH(uh);
			else
				logger:error("gameScene and scene are nil.");
			end
		end
		
		if (instance.getFinalOwner) then
			logger:error("Expected the conflict list to contain an entity instance, but got some component instead?")
			instance = getFinalOwner:getFinalOwner()
		end
		
		-- now, see how many conflict resolvers already exist
		local numberOfConflicts = 0
		local numberOfUnhandledConflicts = 0
		local numberOfConflictHandlersOriginally = 0

		local iter = instance:findAllComponents(propertyanimation.PropertyConnectionConflictResolverComponent);
		local resolverComponent = iter:next()
		while resolverComponent do
			numberOfConflictHandlersOriginally = numberOfConflictHandlersOriginally + 1
			resolverComponent = iter:next()
		end		

		-- then, count how many unhandled conflicts there are...
		-- TODO: how the heck to do this for real...? just loop through all of the properties, and see which ones have more than one connection in?
		local conflictProps = { } -- contains instance UH and property name for each property which conflicts
		local iter = instance:findAllComponents(propertyanimation.PropertyConnectionComponent);
		local connComp = iter:next()
		while connComp do
			local seemsToConflict = false
			local iter2 = instance:findAllComponents(propertyanimation.PropertyConnectionComponent);
			local connComp2 = iter2:next()
			while connComp2 do
				if (connComp:getUnifiedHandle() ~= connComp2:getUnifiedHandle()) then
					if (connComp:getOutputInstance() == connComp2:getOutputInstance()
						and connComp:getOutputPropertyName() == connComp2:getOutputPropertyName()) 
					then
						local alreadyInTheList = false
						local propUHAndName = tostring(connComp:getOutputInstance())..tostring(connComp:getOutputPropertyName())
						for k,v in pairs(conflictProps) do
							if (v == propUHAndName) then
								alreadyInTheList = true
							end
						end
						if not(alreadyInTheList) then
							table.insert(conflictProps, propUHAndName)
						end
					end
				end
				connComp2 = iter2:next()
			end
			connComp = iter:next()
		end		
		
		-- (apparently this many properties had conflicts in the entity.)
		numberOfConflicts = #conflictProps
		
		numberOfUnhandledConflicts = numberOfConflicts - numberOfConflictHandlersOriginally
				
		local handleSetNumber = numberOfConflictHandlersOriginally
		while (numberOfUnhandledConflicts > 0) do
			numberOfUnhandledConflicts = numberOfUnhandledConflicts - 1

			instance:getInstanceManager():createNewComponent(custCompType:getUnifiedHandle(), instance, createdCustomPropAnimComponent,
				{ inputEditorId=nil, outputEditorId=nil, inputPropName=nil, outputPropName=nil, propValueParams={ ConflictSetNumber = handleSetNumber } } );
			
			numResolversAdded = numResolversAdded + 1
			handleSetNumber = handleSetNumber + 1
		end
	end

	local numstr = tostring(numResolversAdded)
	if (numResolversAdded == 0) then
		editorMessageBox("There were no known connection conflicts that needed to be resolved.\r\nIf there are conflicts, then the automatic connection conflict detection may have failed and you may have to resolve any possible conflicts manually.", "No connection conflicts to resolve.", "Info")	
	else
		editorMessageBox("Connection conflict resolver components were added to known conflict cases.\r\nTo see if the conflicts have been automatically resolved, you should save and reload the map to verify that no more conflicts exist.\r\nThe error list has been cleared to make spotting the conflicts easier.", numstr.." connection conflict resolve components were added.", "Info")	
	end
	
	-- HACK: super hacky thingies, ping pong for delayed execution.
	externalUI:sendUICommand("bounceCommand(\"editor.ExternalUI.restoreConflictResolverErrors()\")");
end

function restoreConflictResolverErrors()
	-- HACK: restore errors...
	propertyAnimationModule:setDisableConflictResolverErrors(false)
end

----------------------------------------------------------------------------------------------------------

function resetAllConnectionConflictResolvers()
	-- TODO: there should be some sensible filter for this case... filtering only entities containing the conflict resolver component...
	local filterString = "0,All"
	local maxDepth = editor.Editor.InfiniteDepth 
	local forceParentsOfMatchesToMatch = false; 
	local root = instanceManager:getTopmostInstanceRoot()
	local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilter(root, filterString, maxDepth, forceParentsOfMatchesToMatch)
	local obj = resultIterator:next()
	while (obj) do
		local citer = obj:findAllComponents(propertyanimation.PropertyConnectionConflictResolverComponent);
		local conflictRes = citer:next()
		while conflictRes do
			conflictRes:setReset(true)
			conflictRes = citer:next()
		end
		obj = resultIterator:next()
	end	
end

----------------------------------------------------------------------------------------------------------

function visualizeWidgetEventChain()
	-- rewind to the start of current chain
	local rewinding = true
	while (rewinding) do
		rewinding = engine.gui.Widget.prevDebugHistoryEntry()
	end
	
	-- then slowly step by step move to the end of the chain, selecting when widgets for each step
	-- TODO: these should really be just tagged as some numbered icons or such in the gui tree! this is just a back quick hack
	visualizeNextWidgetInEventChainImpl(1)
end

function selectCurrentlyTracedWidget()
	editor.ExternalUI.clearSyncDataListener("GUIExplorer")
	editor.ExternalUI.syncGUITreeRoot("GUIExplorer")
	
	local uh = engine.gui.Widget.getCurrentDebugHistoryWidgetUH()
	local guid = nil
	if (uh ~= UH_NONE and guiRoot) then
		local widget = guiRoot:getWidgetByUH(uh)
		if (widget) then	
			guid = widget:getGuid()
			locateGUID(guid, true)
		end
	end
end

function visualizeNextWidgetInEventChainImpl(num)
	editor.ExternalUI.clearSyncDataListener("GUIExplorer")
	editor.ExternalUI.syncGUITreeRoot("GUIExplorer")
	
	local uh = engine.gui.Widget.getCurrentDebugHistoryWidgetUH()
	local guid = nil
	local name = nil
	if (uh ~= UH_NONE and guiRoot) then
		local widget = guiRoot:getWidgetByUH(uh)
		if (widget) then	
			guid = widget:getGuid()
			name = widget:getName()
			locateGUID(guid, true)
		end
	end

	local numstr = tostring(num)
	if (num < 10) then
		numstr = "0"..numstr
	end		
	logger:info("Event #"..numstr.." - "..tostring(guid).." - "..tostring(name).." - "..tostring(engine.gui.Widget.getCurrentDebugHistoryInfo()))	
	
	local nextAvail = engine.gui.Widget.nextDebugHistoryEntry()
	if nextAvail then
		local nextnum = num + 1
		state:runLuaStringWithDelay("editor.ExternalUI.visualizeNextWidgetInEventChainImpl("..tostring(nextnum)..")", 500)
	end
end

----------------------------------------------------------------------------------------------------------

function dumpAllWidgetEventChains()
	-- rewind to the very first chain
	local rewinding = true
	while (rewinding) do
		rewinding = engine.gui.Widget.prevDebugHistory()
	end

	local fwd = true
	while (fwd) do
		dumpWidgetEventChain()
		fwd = engine.gui.Widget.nextDebugHistory()
	end	
end

function dumpWidgetEventChain()
	-- rewind to the start of current chain
	local rewinding = true
	while (rewinding) do
		rewinding = engine.gui.Widget.prevDebugHistoryEntry()
	end
	
	dumpWidgetEventChainImpl(1)
end

function dumpWidgetEventChainImpl(num)
	local uh = engine.gui.Widget.getCurrentDebugHistoryWidgetUH()
	local guid = nil
	local name = nil
	if (uh ~= UH_NONE and guiRoot) then
		local widget = guiRoot:getWidgetByUH(uh)
		if (widget) then	
			guid = widget:getGuid()
			name = widget:getName()
		end
	end

	local numstr = tostring(num)
	if (num < 10) then
		numstr = "0"..numstr
	end		
	logger:info("Event #"..numstr.." - "..tostring(guid).." - "..tostring(name).." - "..tostring(engine.gui.Widget.getCurrentDebugHistoryInfo()))	
	
	local nextAvail = engine.gui.Widget.nextDebugHistoryEntry()
	if nextAvail then
		local nextnum = num + 1
		editor.ExternalUI.dumpWidgetEventChainImpl(nextnum)
	end
end

----------------------------------------------------------------------------------------------------------

function setTreatCollisionsAsDebugVisualization(enabled)
	state:setTreatCollisionsAsDebugVisualization(enabled)
end

function setGameVisualizationMode(enabled)
	state:setGameVisualizationMode(enabled)
end

function setScreenOverscanMask(visible)
	debugComponent:toggleOverscanOverlay()
end

function setUndoRedoInfo(undoName, redoName)
	externalUI:sendUICommand("setUndoRedoInfo(\""..undoName.."\", \""..redoName.."\")")	
end

-- the editor UI calls this to query about an entity having bones (for a menu item)
-- this will send an event to the UI once it knows the result
function queryObjectHasBones(editorId)
	assert_string(editorId)
	
	-- we apparently get a plain guid string here instead
	--local obj = getObjectByEditorObjectId(editorId);
	local guidStr = editorId;
	local guid = parseObjectFromStringValue(guidStr);
	local obj = nil
	if (guid) then
		obj = getObjectByGUID(guid);
	else
		logger:error("external_ui.queryObjectHasBones - Guid string to guid object parsing failed.");
		return nil;
	end
	
	if obj == nil then
		logger:error("Failed to query for object having bones, no object with given id " .. editorId)
		return
	end
	
	local hasBones = false
	local modelComp = obj:findComponent(rendering.ModelComponent)
	if (modelComp) then
		if (modelComp:hasBones()) then
			hasBones = true
		end
	end

	local escapedId = editor.Util.escapeQuotesAndBackslashes(editorId);
	externalUI:sendUICommand("resultObjectHasBones(\""..editorId.."\", \""..tostring(hasBones).."\")")
end

function addMapPositionBasedErrorTagTaskRequested(guidStr)
	local guid = getGUIDFromGUIDString(guidStr);
	local obj = nil
	if (guid) then
		obj = getObjectByGUID(guid);
		local finalOwner = obj:getFinalOwner()
		if (finalOwner == nil) then
			finalOwner = obj
		end
		local transComp = finalOwner:findComponent(engine.component.TransformComponent)
		if (transComp ~= nil) then
			local pos = transComp:getPosition();
			externalUI:sendUICommand("addMapPositionBasedErrorTagTaskImpl(\""..tostring(guid).."\", \""..tostring(pos).."\")")		
		else
			logger:error("external_ui.addMapPositionBasedErrorTagTaskRequested - Failed to find a TransformComponent to get the position from.");
		end
	else
		logger:error("external_ui.addMapPositionBasedErrorTagTaskRequested - Guid string to guid object parsing failed.");
	end	
end

function addMapPositionBasedErrorTagTaskRequestedAtCamPos()
	local position = flattenedCameraPosition()
	if position then
		externalUI:sendUICommand("addMapPositionBasedErrorTagTaskImpl(\"GUID_NONE\", \""..tostring(position).."\")")
	end
end

function tagAllRunningTimers()
	local filterString = "0,All"
	local maxDepth = editor.Editor.InfiniteDepth 
	local forceParentsOfMatchesToMatch = false; 
	local root = instanceManager:getTopmostInstanceRoot()
	local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilter(root, filterString, maxDepth, forceParentsOfMatchesToMatch)
	local obj = resultIterator:next()
	local totalTimersRunning = 0
	while (obj) do
		local citer = obj:findAllComponents(gameplay.TimerComponent);
		local timerComp = citer:next()
		while timerComp do
			if (timerComp:getEnabled() and timerComp:getActivated()) then
				totalTimersRunning = totalTimersRunning + 1
				timerComp:tagWithCustomInfo("Running timer tagged.")
			end
			timerComp = citer:next()
		end
		obj = resultIterator:next()
	end	
	logger:info("Total running timers tagged: " .. tostring(totalTimersRunning))
end

function placeholderSoundCompleted(id)
	audioModule:placeholderSoundCompleted(id)
end

function playPlaceholderSound(filename, id)
	if (externalUI) then
		externalUI:sendUICommand("playPlaceholderSound(\""..filename.."\", \""..tostring(id).."\")");
	end
end


function doHighQualityTextureProcessingForSelected()
	local filterString = "0,data/filter/native/nativefilter_composite_denyall_denyall|1,data/filter/native/nativefilter_orcomposite_selectedineditor_allowall" 
	local maxDepth = 99999 
	local forceParentsOfMatchesToMatch = false; 
	local root = instanceManager:getTopmostInstanceRoot() 
	local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilter(root, filterString, maxDepth, forceParentsOfMatchesToMatch) 
	local obj = resultIterator:next()  
	local traPos, traPosZ, posOff, tarOff, position, target, direction, directionNormalized = nil
	local selectedObjects = {}
	while (obj) do
		table.insert(selectedObjects, obj)
		obj = resultIterator:next()
	end 
	
	local prevMode = renderingModule:getHighQualityTextureCompression()
	renderingModule:setHighQualityTextureCompression(true)	
	
	local textureUHsToProcess = { }
	
	for i=1,#selectedObjects do
		local obj = selectedObjects[i]
		if (obj:isInherited(engine.base.InstanceBase.getStaticObjectClass())) then
			local modelComp = obj:findComponent(rendering.ModelComponent)
			if (modelComp) then
				local modelResUH = modelComp:getModel()
				if (modelResUH ~= UH_NONE) then
					local modelRes = resourceManager:getResourceByUH(modelResUH)
					if (modelRes) then
						local uhTable = modelRes:getTextureArray()
						local uhTableSize = uhTable:getSize()
						for i = 0,uhTableSize-1 do
							local refUH = uhTable:get(i)
							local alreadyExists = false
							for i=1,#textureUHsToProcess do
								if textureUHsToProcess[i] == refUH then 
									alreadyExists = true 
								end
							end
							if not alreadyExists then
								table.insert(textureUHsToProcess, refUH)
							end
						end						
					end
				end
			end
		end
	end

	for i=1,#textureUHsToProcess do
		local refUH = textureUHsToProcess[i]
		local textureRes = resourceManager:getResourceByUH(refUH)
		--logger:info("Going to process the texture with high quality: "..tostring(textureRes:getFilename()))
		app:cleanResource(textureRes)
		app:processResource(textureRes)
	end
	
	renderingModule:setHighQualityTextureCompression(prevMode)	
end


function injectLuaScript(luaStr)
	local line = luaStr
	local loadedFunction, errorMessage = loadstring(line)
	if not loadedFunction then
		logger:error("Script inject error: " .. errorMessage)
		return
	end

  local ok, output = pcall(loadedFunction)
  if ok == false then
    logger:error("Script inject error: " .. tostring(output))
    return
  else
		if (output ~= nil) then
			logger:info("Script inject returned value: " .. tostring(output))
		else
			logger:info("Script injected.")
		end
  end
end


function editorPluginResponse(pluginName, funcName, retStr)
	assert_string(pluginName)
	assert_string(funcName)
	assert_string(retStr)

	externalUI:sendUICommand("sendToPlugin(\""..pluginName.."\", \""..funcName.."\", \""..retStr.."\")")
end


function addSelectionChangeListener(selectionChangeCallbackFunction)
	assert_function(selectionChangeCallbackFunction)
	
	table.insert(selectionChangeListeners, selectionChangeCallbackFunction)
end


function openFBXDialogForResource(editorObjectId)
  local obj = getObjectByEditorObjectId(editorObjectId);
  if (obj) then
    if (obj:isInherited(engine.base.resourcebase.ResourceBase.getStaticObjectClass())) then
      app:openFBXDialogForResource(obj:getGuid());
    else
      logger:error("Encountered a non-resource object, don't know how to open it.");
    end
  else
    editorMessageBox("Failed to parse object from editor object id parameter", "Invalid editor object id", "Warning")
  end  
end

function preProcessNavigationMesh()
	local aiNavigationManager = common.CommonUtils.getSceneInstanceManager():findInstanceByName("NavigationManagerInst");
	if aiNavigationManager ~= nil then
		local build = true;
		local buildingMaps = false;
		local buildingMOD = false;
		aiNavigationManager:buildOrLoadNavigationMeshes(build, buildingMaps, buildingMOD)
	else
		logger:error("preProcessNavigationMesh - Navigation build failed, NavigationManagerInst is missing.");
	end	
end

function epicMoveCameraToTarget()
	-- Locate the main target
	local instanceManager = common.CommonUtils.getSceneInstanceManager()
	local epicBattleInstance = instanceManager:findInstanceByName("battle");
	local epicBattleCameraDirectorComponent = epicBattleInstance:findComponent(epicquestbase.gameplay.EpicBattleCameraDirectorComponent)
	local mainTargetInstance = instanceManager:getInstanceByUH(epicBattleCameraDirectorComponent:getMainTarget())
	local mainTargetComponent = mainTargetInstance:findComponent(epicquestbase.gameplay.camera.EpicCameraTargetComponent)

	-- Locate the editor camera
	local camera = instanceManager:findInstanceByName("EditorCamera")
	if not camera then camera = instanceManager:findInstanceByName("camera") end
	local cameraTransform = camera:findComponent(engine.component.TransformComponent)

	local oldPos = cameraTransform:getPosition()
	mainTargetComponent:forceCameraToThis(camera:getUnifiedHandle())
	local newPos = cameraTransform:getPosition()

	newPos.x = oldPos.x

	-- Keep the X axis position of the original one, just adjust height and zoom.
	cameraTransform:setPosition(newPos)
end

function collectSpriteScaledFromCurrentLevel()
	-- NOTE: This only works in EpicQuest for now.
	if scene ~= nil and scene.calculateOptimalSpriteSizes ~= nil then
		scene:calculateOptimalSpriteSizes()
	else
		logger:error("external_ui.collectSpriteScaledFromCurrentLevel - Collecting sprite scales is only implemented in EpicQuest for now.");
	end
end

