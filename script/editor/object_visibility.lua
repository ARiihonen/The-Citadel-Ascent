module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

local thisModule = _M

declareReload(thisModule, [[visibilityWindowEnabled]])
declareReload(thisModule, [[firstIndex]])
declareReload(thisModule, [[lastIndex]])
declareReload(thisModule, [[setAllMarkerIndex]])
declareReload(thisModule, [[bindsCreated]])
bindsCreated = false
visibilityWindowEnabled = false

-- note, these values must match the limits in engine. (editor UI might differ by leaving out reserved bits)
-- (currently, int32 bits, with last bit reserved and left to zero - but still included in the strings)
firstIndex = 0
lastIndex = 31

-- hacky marker for the setters to tell that all bits are to be set/cleared
setAllMarkerIndex = -2

----------------------------------------------------------------------------------------------------------

-- returns true if given modelComp is non-nil and if it is a gameplay model component 
-- (not an editor visualization model)
function isModelComponentRelevant(modelComp)
	-- assert_component_or_nil(modelComp)
	
	if modelComp then 
		if modelComp:getVisibleInGame() then
			-- ok
			return true
		else
			-- editor helper probably?
			return false
		end		
	else
		return false
	end	
end

----------------------------------------------------------------------------------------------------------

-- returns true if given lightComp is non-nil (...and possible additional checks?)
function isLightComponentRelevant(lightComp)
	-- assert_component_or_nil(lightComp)
	
	if lightComp then 
		return true
	else
		return false
	end	
end

----------------------------------------------------------------------------------------------------------

declareReload(thisModule, [[selectedObjectModelVisibilityCountTable]])
declareReload(thisModule, [[selectedObjectShadowVisibilityCountTable]])
declareReload(thisModule, [[selectedObjectLightVisibilityCountTable]])
declareReload(thisModule, [[totalSelectedObjects]])
declareReload(thisModule, [[totalSelectedModelComponents]])
declareReload(thisModule, [[totalSelectedLightComponents]])
selectedObjectModelVisibilityCountTable = { }
selectedObjectShadowVisibilityCountTable = { }
selectedObjectLightVisibilityCountTable = { }
totalSelectedObjects = 0
totalSelectedModelComponents = 0
totalSelectedLightComponents = 0

function updateSelectedObjectsVisibilityMask(selectedInstance)
	-- note, this variable is not really relevant for anything (as some of the selected objects might be irrelevant to visibility)
	totalSelectedObjects = totalSelectedObjects + 1	

	-- model components
	local modelComp = selectedInstance:findComponent(rendering.ModelComponent);
	
	-- only process selected objects with models, and ignore editor only models (those are assumed to be helpers, never hide them)
	if (isModelComponentRelevant(modelComp)) then	
		local modelBitSet = modelComp:getVisibilityMaskBits()
		local shadowBitSet = modelComp:getShadowCasterMaskBits()
		
		for i = firstIndex,lastIndex do
			if modelBitSet:isBitSet(i) then
				selectedObjectModelVisibilityCountTable[i] = selectedObjectModelVisibilityCountTable[i] + 1
			end
			if shadowBitSet:isBitSet(i) then
				selectedObjectShadowVisibilityCountTable[i] = selectedObjectShadowVisibilityCountTable[i] + 1
			end
		end		
		totalSelectedModelComponents = totalSelectedModelComponents + 1		
	end
	
	-- light components
	local lightComp = selectedInstance:findComponent(lighting.PointLightComponent);
	if (lightComp == nil) then
		-- no luck with pointlight? try spotlight.
		lightComp = selectedInstance:findComponent(lighting.SpotLightComponent);
	end
	
	-- NOTE: only a spotlight or a pointlight per one entity is supported by current logic, not both of them!
	
	-- only process selected objects with lights, and ignore editor only models (those are assumed to be helpers, never hide them)
	if (isLightComponentRelevant(lightComp)) then	
		local lightBitSet = lightComp:getVisibilityMaskBits()
		
		for i = firstIndex,lastIndex do
			if lightBitSet:isBitSet(i) then
				selectedObjectLightVisibilityCountTable[i] = selectedObjectLightVisibilityCountTable[i] + 1
			end
		end		
		totalSelectedLightComponents = totalSelectedLightComponents + 1
	end
	
end

function selectionChanged()
	-- updates only if the window enabled, since the updates may cause a significant performance impact
	if (visibilityWindowEnabled) then
	
		-- reset the list of bits set and the count...
		selectedObjectModelVisibilityCountTable = { }
		selectedObjectShadowVisibilityCountTable = { }
		selectedObjectLightVisibilityCountTable = { }
		totalSelectedObjects = 0
		totalSelectedLightComponents = 0
		totalSelectedModelComponents = 0

		for i = firstIndex, lastIndex do
			selectedObjectModelVisibilityCountTable[i] = 0
			selectedObjectShadowVisibilityCountTable[i] = 0
			selectedObjectLightVisibilityCountTable[i] = 0
		end

		-- go through all the selected objects...
		editor.Editor.seekInstances("data/filter/native/nativefilter_composite_selectedineditor_allowall.fbfilt", nil, updateSelectedObjectsVisibilityMask)	
		
		-- construct the real model/shadow bit mask based on masks of the selected objects
		-- note, selModelMask, contains lights too
		local selModelMask = "" 
		local selShadowMask = ""
		local selModelAmbiguousMask = ""
		local selShadowAmbiguousMask = ""
		for i = firstIndex, lastIndex do
			if (selectedObjectModelVisibilityCountTable[i] > 0 or selectedObjectLightVisibilityCountTable[i] > 0) then
				selModelMask = "1"..selModelMask
				-- if not all of the objects had the model bit set, then the bit is ambiguous/undetermined
				if (selectedObjectModelVisibilityCountTable[i] ~= totalSelectedModelComponents
					or selectedObjectLightVisibilityCountTable[i] ~= totalSelectedLightComponents) then
					selModelAmbiguousMask = "1"..selModelAmbiguousMask
				else
					selModelAmbiguousMask = "0"..selModelAmbiguousMask
				end
			else
				selModelMask = "0"..selModelMask
				selModelAmbiguousMask = "0"..selModelAmbiguousMask
			end
			if (selectedObjectShadowVisibilityCountTable[i] > 0) then
				selShadowMask = "1"..selShadowMask
				-- if not all of the objects had the shadow bit set, then the bit is ambiguous/undetermined
				if (selectedObjectShadowVisibilityCountTable[i] ~= totalSelectedModelComponents) then
					selShadowAmbiguousMask = "1"..selShadowAmbiguousMask
				else
					selShadowAmbiguousMask = "0"..selShadowAmbiguousMask
				end
			else
				selShadowMask = "0"..selShadowMask
				selShadowAmbiguousMask = "0"..selShadowAmbiguousMask
			end
		end
	
		externalUI:sendUICommand("currentSelectionVisibilityMask(\""..selModelMask.."\", \""..selShadowMask.."\", \""..selModelAmbiguousMask.."\", \""..selShadowAmbiguousMask.."\")")
	end	
end

----------------------------------------------------------------------------------------------------------

function visibilityAreaChanged()
	
	if (visibilityWindowEnabled) then
		-- NOTE: could use another mask, similar to the ambigous masks of the selection to indicate possible union vs. intersection differences 
		-- (in case of the mask consisting of multiple areas)
		
		local multipleAreas = gameScene:areMultipleVisibilityAreasActive()
		local curAreaModelMask = gameScene:getActiveModelVisibilityMaskAsString() 
		local curAreaShadowMask = gameScene:getActiveShadowVisibilityMaskAsString() 
		externalUI:sendUICommand("currentVisibilityMask(\""..tostring(multipleAreas).."\", \""..curAreaModelMask.."\", \""..curAreaShadowMask.."\")")

		local forcedAreaIndex = gameScene:getForcedVisibilityMaskBitIndex();
		if (forcedAreaIndex ~= -1) then
			areaIndex = forcedAreaIndex
		else
			if (multipleAreas) then
				areaIndex = -1
			else
				areaIndex = gameScene:getActiveVisibilityMaskBitIndex()
			end
		end
		externalUI:sendUICommand("setActiveAreaIndex(\""..tostring(multipleAreas).."\", \""..areaIndex.."\", \""..forcedAreaIndex.."\")")
	end	
end

----------------------------------------------------------------------------------------------------------

function changeForcedActiveVisibilityArea(forcedAreaIndex)
	assert_number(forcedAreaIndex)

	-- force the visibility mask to given index value
	gameScene:setForcedVisibilityMaskToIndex(forcedAreaIndex)
	
	-- removed this temp stuff, fully relying on the visibilityAreaChanged callback now.
	-- note, assuming that the above call cannot fail... thus, this following call should be ok..	
	--if (forcedAreaIndex ~= -1) then
	--	externalUI:sendUICommand("setActiveAreaIndex(\"false\", \""..forcedAreaIndex.."\", \""..forcedAreaIndex.."\")")
	--end
	-- else, cannot deduce the area index here, need to rely on visibilityAreaChanged occurring...
end

----------------------------------------------------------------------------------------------------------

function enableVisibilityWindow()
	externalUI:sendUICommand("enableVisibilityWindow()")
	visibilityWindowEnabled = true

	updateAreaInUseAndComments()
	
	-- bind shortcut keys for show/hide
	local thisModule = _M
	local params = { bindName = "-", buttonCatcherName = "UIButtonCatcher", module = thisModule }
	
	-- pad-divide and pad-multiply for hide/show
	--if (not(bindsCreated)) then
	--	createCustomReloadObject(thisModule, [[setSelectedVisibleInActiveArea]], [[createBind]], [[removeBind]], params)
	--	createCustomReloadObject(thisModule, [[setSelectedInvisibleInActiveArea]], [[createBind]], [[removeBind]], params)
	--	bindsCreated = true
	--end
end

----------------------------------------------------------------------------------------------------------

function disableVisibilityWindow()
	changeForcedActiveVisibilityArea(-1);
	externalUI:sendUICommand("disableVisibilityWindow()")	
	visibilityWindowEnabled = false
	
	-- TODO: unbind shortcut keys for show/hide... cannot be done using the current gui.UI.removeBind, as the createBind/removeBind functions
	-- do not consider the possibility of the object not existing, and thus, script reload would do some bad things.
end

----------------------------------------------------------------------------------------------------------
-- the key bind stuff...

-- key bind callback
function setSelectedVisibleInActiveArea()
	-- FIXME: only the editor UI knows the active area (well, we could solve it here too, since this script sends it to ui elsewhere), so need to ping-pong the 
	-- actual operation through the UI
	externalUI:sendUICommand("requestSetSelectionVisibleInActiveArea()")
	
	-- am I supposed to return true or false? I dunno. so lets just return true. :)
	return true
end

function setSelectedInvisibleInActiveArea()
	-- FIXME: only the editor UI knows the active area (well, we could solve it here too, since this script sends it to ui elsewhere), so need to ping-pong the 
	-- actual operation through the UI
	externalUI:sendUICommand("requestSetSelectionInvisibleInActiveArea()")
	
	-- am I supposed to return true or false? I dunno. so lets just return true. :)
	return true
end

-- forward the bind creations to gui.UI...
--function createBind(objName, params) return gui.UI.createBind(objName, params) end
--function removeBind(objName, params) return gui.UI.removeBind(objName, params) end

----------------------------------------------------------------------------------------------------------

declareReload(thisModule, [[areaIndicesInUseTable]])
areaIndicesInUseTable = { }

function updateAreaInUseAndCommentForSingleArea(areaInstance)
	local visTrigComp = areaInstance:findComponent(rendering.trigger.VisibilityTriggerComponent);
	
	local bitSet = visTrigComp:getTriggerVisibilityMaskBits()
	--local binaryStr = ""
	local foundIndex = false
	local areaIndex = -1
	local multipleIndices = false
	for i = firstIndex,lastIndex do
		if bitSet:isBitSet(i) then
			if (not(foundIndex)) then
				foundIndex = true
				areaIndex = i
			else
				multipleIndices = true
			end
			--binaryStr = "1"..binaryStr
		else
			--binaryStr = "0"..binaryStr
		end
	end
	if (foundIndex) then
		if (not(multipleIndices)) then
			-- we got the index!
			areaIndicesInUseTable[areaIndex] = true
			-- TODO: update the comment in the UI based on the comment in this area entity...
			-- externalUI:sendUICommand("setAreaCommet(\""..areaIndex.."\", \""..comment.."\")")
		else
			-- this area has multiple bits set - thus, the area seems to be of "deprecated" type.
			-- this is not supported by this visibility window. it now assumes that all areas have a single
			-- bit set (each has a single visibility group index assigned to them, rather than a mask)
			-- NOTE: assuming that the area component tags itself with a warning in this case, so we don't have to react here
			logger:warning("A visibility area trigger entity has multiple bits set, expecting only one bit per area.");
		end
	else		
		-- this area has no bits set? just ignoring it for now. 
		-- NOTE: assuming that the area component tags itself with a warning in such case, so we don't have to react here
		logger:warning("A visibility area trigger entity has no bits set, expecting one bit set per area.");
	end
end

function updateAreaInUseAndComments()
	-- filter all trigger objects, find out their mask, apply comment and in-use flags accordingly to UI

	areaIndicesInUseTable = { }	
	for i = firstIndex, lastIndex do
		areaIndicesInUseTable[i] = false
	end
	
	editor.Editor.seekInstances("VisibilityAreaTriggerFilter", nil, updateAreaInUseAndCommentForSingleArea)

	local binaryStr = ""
	for i = firstIndex, lastIndex do
		if (areaIndicesInUseTable[i]) then
			binaryStr = "1"..binaryStr
		else
			binaryStr = "0"..binaryStr
		end
	end
	
	externalUI:sendUICommand("setAreasInUseMask(\""..binaryStr.."\")")	
	
end

----------------------------------------------------------------------------------------------------------

-- hacky temp variables. set whenever changing the selected/unselected object flags
declareReload(thisModule, [[changeForArea]])
declareReload(thisModule, [[changeBitOn]])
changeForArea = -1
changeBitOn = false

-- internal helper function, called for each object while iterating
function changeModelVisibility(selectedInstance)
	local modelComp = selectedInstance:findComponent(rendering.ModelComponent);
	
	-- only process objects with proper models
	if (isModelComponentRelevant(modelComp)) then	
		local modelBitSet = modelComp:getVisibilityMaskBits()

		if (changeBitOn) then
			if (changeForArea == setAllMarkerIndex) then
				modelBitSet:setAllBits()
				modelComp:setVisibilityMaskBits(modelBitSet)
				-- hack, the last bit is reserved, keeping it cleared.
				modelBitSet:clearBit(lastIndex)
				modelComp:setVisibilityMaskBits(modelBitSet)
			else
				modelBitSet:setBit(changeForArea)
				modelComp:setVisibilityMaskBits(modelBitSet)
			end
		else
			if (changeForArea == setAllMarkerIndex) then
				modelBitSet:clearAllBits()
				modelComp:setVisibilityMaskBits(modelBitSet)
			else
				modelBitSet:clearBit(changeForArea)
				modelComp:setVisibilityMaskBits(modelBitSet)
			end
		end				
	end
	
	local lightComp = selectedInstance:findComponent(lighting.PointLightComponent);
	if (lightComp == nil) then
		-- no luck with pointlight? try spotlight.
		lightComp = selectedInstance:findComponent(lighting.SpotLightComponent);
	end

	-- only process objects with proper lights
	if (isLightComponentRelevant(lightComp)) then	
		local lightBitSet = lightComp:getVisibilityMaskBits()

		if (changeBitOn) then
			if (changeForArea == setAllMarkerIndex) then
				lightBitSet:setAllBits()
				lightComp:setVisibilityMaskBits(lightBitSet)
				-- hack, the last bit is reserved, keeping it cleared.
				lightBitSet:clearBit(lastIndex)
				lightComp:setVisibilityMaskBits(lightBitSet)
			else
				lightBitSet:setBit(changeForArea)
				lightComp:setVisibilityMaskBits(lightBitSet)
			end
		else
			if (changeForArea == setAllMarkerIndex) then
				lightBitSet:clearAllBits()
				lightComp:setVisibilityMaskBits(lightBitSet)
			else
				lightBitSet:clearBit(changeForArea)
				lightComp:setVisibilityMaskBits(lightBitSet)
			end
		end				
	end
	
end

----------------------------------------------------------------------------------------------------------

-- internal helper function, called for each object while iterating
function changeShadowVisibility(selectedInstance)
	local modelComp = selectedInstance:findComponent(rendering.ModelComponent);
	
	-- only process objects with proper models
	if (isModelComponentRelevant(modelComp)) then	
		local modelBitSet = modelComp:getShadowCasterMaskBits()

		if (changeBitOn) then
			if (changeForArea == setAllMarkerIndex) then
				modelBitSet:setAllBits()
				modelComp:setShadowCasterMaskBits(modelBitSet)
				-- hack, the last bit is reserved, keeping it cleared.
				modelBitSet:clearBit(lastIndex)
				modelComp:setShadowCasterMaskBits(modelBitSet)
			else
				modelBitSet:setBit(changeForArea)
				modelComp:setShadowCasterMaskBits(modelBitSet)
			end
		else
			if (changeForArea == setAllMarkerIndex) then
				modelBitSet:clearAllBits()
				modelComp:setShadowCasterMaskBits(modelBitSet)
			else
				modelBitSet:clearBit(changeForArea)
				modelComp:setShadowCasterMaskBits(modelBitSet)
			end
		end				
	end
end

----------------------------------------------------------------------------------------------------------

function changeSelectedModelsVisibleInArea(areaIndex, visible)
	assert_number(areaIndex)
	assert_boolean(visible)
	
	-- loop all selected objects, set their model mask accordingly
	changeForArea = areaIndex
	changeBitOn = visible
	editor.Editor.seekInstances("data/filter/native/nativefilter_composite_selectedineditor_allowall.fbfilt", nil, changeModelVisibility)	

	-- NOTE: this might be unnecessary, if the dirty flag gets set, even when stuff inside the selection changes (rather than selected objects changing)
	selectionChanged()
end

----------------------------------------------------------------------------------------------------------

function changeSelectedShadowsVisibleInArea(areaIndex, visible)
	assert_number(areaIndex)
	assert_boolean(visible)
	
	-- loop all selected objects, set their shadow visible mask accordingly
	changeForArea = areaIndex
	changeBitOn = visible
	editor.Editor.seekInstances("data/filter/native/nativefilter_composite_selectedineditor_allowall.fbfilt", nil, changeShadowVisibility)	

	-- NOTE: this might be unnecessary, if the dirty flag gets set, even when stuff inside the selection changes (rather than selected objects changing)
	selectionChanged()
end
----------------------------------------------------------------------------------------------------------

function changeSelectedModelsVisibleInAllAreas(visible)
	assert_boolean(visible)
	
	-- loop all selected objects, set their model mask accordingly
	changeForArea = setAllMarkerIndex
	changeBitOn = visible
	editor.Editor.seekInstances("data/filter/native/nativefilter_composite_selectedineditor_allowall.fbfilt", nil, changeModelVisibility)	

	-- NOTE: this might be unnecessary, if the dirty flag gets set, even when stuff inside the selection changes (rather than selected objects changing)
	selectionChanged()
end

----------------------------------------------------------------------------------------------------------

function changeSelectedShadowsVisibleInAllAreas(visible)
	assert_boolean(visible)
	
	-- loop all selected objects, set their shadow visible mask accordingly
	changeForArea = setAllMarkerIndex
	changeBitOn = visible
	editor.Editor.seekInstances("data/filter/native/nativefilter_composite_selectedineditor_allowall.fbfilt", nil, changeShadowVisibility)	

	-- NOTE: this might be unnecessary, if the dirty flag gets set, even when stuff inside the selection changes (rather than selected objects changing)
	selectionChanged()
end

----------------------------------------------------------------------------------------------------------

function changeUnselectedModelsVisibleInArea(areaIndex, visible)
	assert_number(areaIndex)
	assert_boolean(visible)
	
	-- loop all unselected objects, set their model mask accordingly
	changeForArea = areaIndex
	changeBitOn = visible
	editor.Editor.seekInstancesWithMultiLevelFilter("0,data/filter/native/nativefilter_composite_selectedineditor_allowall.fbfilt|1,Invert", nil, changeModelVisibility)	

	-- NOTE: this might be unnecessary, if the dirty flag gets set, even when stuff inside the selection changes (rather than selected objects changing)
	selectionChanged()
end

----------------------------------------------------------------------------------------------------------

function changeUnselectedShadowsVisibleInArea(areaIndex, visible)
	assert_number(areaIndex)
	assert_boolean(visible)
	
	-- loop all unselected objects, set their shadow visible mask accordingly
	changeForArea = areaIndex
	changeBitOn = visible
	editor.Editor.seekInstancesWithMultiLevelFilter("0,data/filter/native/nativefilter_composite_selectedineditor_allowall.fbfilt|1,Invert", nil, changeShadowVisibility)	
	
	-- NOTE: this might be unnecessary, if the dirty flag gets set, even when stuff inside the selection changes (rather than selected objects changing)
	selectionChanged()
end

----------------------------------------------------------------------------------------------------------

-- sets the visibility mask of the active area (trigger), enabling or disabling the rendering of given other area inside the given first area
function changeModelsVisibleInArea(areaIndex, modelsIndex, visible)
	assert_number(areaIndex)
	assert_number(modelsIndex)
	assert_boolean(visible)
	
	-- TODO: find the related area trigger (to areaIndex), set its model mask bit (of number modelsIndex) to 1 or 0 based on visible	
	-- NOTE: this should never really be supported? as the current logic now assumes that each area trigger to have a single bit set.
	-- (so any other area bits should then be cleared to prevent the area from having "invalid" bit mask with multiple bits)
	-- (this would effectively change all the areas with given index to another index - as it cannot determine which of possibly many areas
	-- is meant for the change)
end

----------------------------------------------------------------------------------------------------------

-- sets the shadows mask of the active area (trigger), enabling or disabling the rendering of given other area inside the given first area
function changeShadowsVisibleInArea(areaIndex, shadowsIndex, visible)
	assert_number(areaIndex)
	assert_number(shadowsIndex)
	assert_boolean(visible)
	
	-- TODO: find the related area trigger (to areaIndex), set its shadow mask bit (of number modelsIndex) to 1 or 0 based on visible	
	-- unlike with the models visible mask, this one could perhaps be considered to allow random amount of bits being set.
	-- (assuming that the model bit is being used to identify which visibility group the area belongs to)
	-- NOTE: however, currently, there is no separate masks for model and shadow visibility in area triggers. the same mask is used for both.
	
end

----------------------------------------------------------------------------------------------------------

function locateAndSelectVisibilityAreaTrigger(areaTriggerInstance)
	-- TODO:
end

function locateAndSelectVisibilityAreaTrigger(areaIndex)
	-- TODO: create this kind of filter, need to be a bit tricky.. like with selectInstancesVisibleInArea .. to pass the appropriate parameter
	-- editor.Editor.seekInstances("VisibilityAreaTriggerWithGivenIndexFilter", nil, locateAndSelectVisibilityAreaTrigger)
end

----------------------------------------------------------------------------------------------------------

declareReload(thisModule, [[areaIndexToCheckForVisibility]])
declareReload(thisModule, [[checkForVisibilityOn]])
declareReload(thisModule, [[checkForLights]])
declareReload(thisModule, [[checkForModels]])
areaIndexToCheckForVisibility = -1
checkForVisibilityOn = false
checkForLights = false
checkForModels = false

-- select/unselect the objects that are either visible or invisible in given area (based on model visibility, not shadow)
-- areaIndex - the visibility group area index
-- makeMelected - selects when this is true, else unselects
-- visible - when true, requires the object to be visible in the area, otherwise requires it to be invisible
function selectInstancesVisibleInArea(areaIndex, visible, makeSelected, allowModels, allowLights)
	assert_number(areaIndex)
	assert_boolean(visible)
	assert_boolean(makeSelected)
	assert_boolean(allowModels)
	assert_boolean(allowLights)

	areaIndexToCheckForVisibility = areaIndex
	checkForVisibilityOn = visible
	checkForModels = allowModels
	checkForLights = allowLights
	editor.ExternalUI.selectInstancesByFilter("0,ModelVisibleInGivenArea", makeSelected, false)
	areaIndexToCheckForVisibility = -1
end

-- the ModelVisibleInGivenArea filter will call back to this to check if the object is visible.
function isInstanceVisibleInGivenArea(objUH)
	if (areaIndexToCheckForVisibility == -1) then
		-- this is an error really.
		return false
	end
	
	obj = gameScene:getSceneInstanceManager():getInstanceByUH(objUH)
	if (not(obj)) then
		logger:error("Failed to find an instance by given UH.")
		return false
	end
	
	if (checkForModels) then
		local modelComp = obj:findComponent(rendering.ModelComponent);
	
		-- only allow objects with proper models
		if (isModelComponentRelevant(modelComp)) then	
			local modelBitSet = modelComp:getVisibilityMaskBits()
			
			local objVisibilityInArea = modelBitSet:isBitSet(areaIndexToCheckForVisibility)
			
			if (objVisibilityInArea == checkForVisibilityOn) then
				return true
			end
		end
	end
	
	if (checkForLights) then
		local lightComp = obj:findComponent(lighting.PointLightComponent);
		if (lightComp == nil) then
			-- no luck with pointlight? try spotlight.
			lightComp = obj:findComponent(lighting.SpotLightComponent);
		end
		
		-- only allow proper lights
		if (isLightComponentRelevant(lightComp)) then	
			local lightBitSet = lightComp:getVisibilityMaskBits()
			
			local objVisibilityInArea = lightBitSet:isBitSet(areaIndexToCheckForVisibility)
			
			if (objVisibilityInArea == checkForVisibilityOn) then
				return true
			end
		end
	end
	
	return false
end



------------------------------------------------------------------------------------------------
-- automated visibility optimization scripts 
------------------------------------------------------------------------------------------------

function listOccludedModelsInCurrentView()
	local ret = { }
	
	local renderingScene = gameScene:getRenderingScene()

	-- filter out any UHs that for some reason don't seem valid anymore...
	local num = renderingScene:getNumOccludedModelGUIDs()
	for i = 0,num-1 do
		local modelGUID = renderingScene:getOccludedModelGUIDByIndex(i)
		table.insert(ret, modelGUID)
	end
	
	return ret
end

function listModelsInCurrentViewImpl(filterFunc)
	local ret = { }
	
	local renderingScene = gameScene:getRenderingScene()

	-- filter out any UHs that for some reason don't seem valid anymore...
	local num = renderingScene:getNumRenderedModelUHs()
	for i = 0,num-1 do
		local modelUH = renderingScene:getRenderedModelUHByIndex(i)
		local modelComp = gameScene:getSceneInstanceManager():getInstanceByUH(modelUH)
		if (modelComp) then
			if (filterFunc(modelComp)) then
				table.insert(ret, modelUH)
			end
		else
			logger:error("A model component instance did not exist with reported UH.")
		end
	end
	
	return ret
end

function listLightsInCurrentViewImpl(filterFunc)
	local ret = { }
	
	local renderingScene = gameScene:getRenderingScene()

	-- filter out any UHs that for some reason don't seem valid anymore...
	local num = renderingScene:getNumRenderedLightUHs()
	for i = 0,num-1 do
		local lightUH = renderingScene:getRenderedLightUHByIndex(i)
		local lightComp = gameScene:getSceneInstanceManager():getInstanceByUH(lightUH)
		if (lightComp) then
			if (filterFunc(lightComp)) then
				table.insert(ret, lightUH)
			end
		else
			logger:error("A light component instance did not exist with reported UH.")
		end
	end
	
	return ret
end

-- for models, see also shouldTryToOptimizeLight
function shouldTryToOptimize(modelComp)
	local owner = modelComp:getFinalOwner()
	
	if (not(owner:getAllowOptimization())) then
		-- does not allow other kind of optimization, don't optimize occlusion either
		return false
	end
	
	if (owner:findComponent(physics.PhysicsComponent)) then
		-- seems dynamic
		return false
	end
	
	if (owner:findComponent(animation.AnimationComponent)) then
		-- seems animated
		return false
	end
	
	if (owner:findComponent(propertyanimation.PropertyConnectionComponent)) then
		-- property animated
		return false
	end

	-- HACK: do this for background objects only
	local transComp = owner:findComponent(engine.component.TransformComponent)
	local pos = transComp:getPosition()
	if (pos.y > 0.0) then
		-- "foreground object" apparently, rather than background..
		-- seems to be too close to the screen, probably just getting frustum-culled, not occlusion-culled
		-- (ignore those due to camera area transition issues)
		return false
	end
	
	return true
end

-- for lights, see also shouldTryToOptimize for models
function shouldTryToOptimizeLight(lightComp)
	local owner = lightComp:getFinalOwner()
	
	if (not(owner:getAllowOptimization())) then
		-- does not allow other kind of optimization, don't optimize occlusion either
		return false
	end

	if (owner:findComponent(propertyanimation.PropertyConnectionComponent)) then
		-- property animated
		return false
	end
	
	local lightComp = owner:findComponent(lighting.PointLightComponent)
	if (not lightComp) then
		-- interested only in point lights for now.
		return false
	end

	-- it is not okay to optimize lights that reach the gameplay area, as they might affect some dynamic objects	
	local transComp = owner:findComponent(engine.component.TransformComponent)
	local pos = transComp:getPosition()
	if (pos.y + lightComp:getRange() > -2.0) then
		return false
	end
	
	return true
end

function listModelsInCurrentView()
	return listModelsInCurrentViewImpl(function() return true end)
end

function listLightsInCurrentView()
	return listLightsInCurrentViewImpl(function() return true end)
end

function listOptimizableModelsInCurrentView()
	return listModelsInCurrentViewImpl(shouldTryToOptimize)
end

function listOptimizableLightsInCurrentView()
	return listLightsInCurrentViewImpl(shouldTryToOptimizeLight)
end

local allOptimizationInProgress = false
local objectOptimizationInProgress = false

declareReload(thisModule, [[optimizationList]])
declareReload(thisModule, [[optimizationIndex]])
optimizationList = { }
optimizationIndex = 0

-- these are new phases that just make all the objects tagged/untagged
-- so that the entire screen can be checked in one frame to see if there could be anything of interested
-- (if there is, then proceed to actually test one-by-one)
declareReload(thisModule, [[allObjectQuickTestPassPhase]])
declareReload(thisModule, [[allObjectQuickTestDonePassPhase]])
allObjectQuickTestPassPhase = false
allObjectQuickTestDonePassPhase = false

declareReload(thisModule, [[optimizationSubAreaX]])
declareReload(thisModule, [[optimizationSubAreaY]])
optimizationSubAreaX = 0
optimizationSubAreaY = 0

local optimizationGlobalOffsetX = 0
local optimizationGlobalOffsetY = 0
local optimizationGlobalOffsetZ = 0
declareReload(thisModule, [[optimizationGlobalOffsetIndex]])
optimizationGlobalOffsetIndex = 1
local optimizationGlobalOffsetPattern = { {0,0,0}, {-1.5,0,0}, {1.5,0,0}, {-3.0,0,0}, {3.0,0,0}, {0,0,-3.0}, {0,0,3.0}, {0,-3,0}, {0,3,0} }

declareReload(thisModule, [[optimizeOnlyFarCoop]])
optimizeOnlyFarCoop = false

-- the slack actually now depends on area size... (these values change)
-- 0.125 is 12.5% extra slack at the area edges, to be used for large areas
-- 0.25 is 25% extra slack at the area edges, to be used for smaller areas
local subAreaSlackX = 0.125
local subAreaSlackY = 0.125
-- max 100% extra slack at the area edges
local maxSubAreaSlackX = 1.0
local maxSubAreaSlackY = 1.0

-- HACK: using this kind of slack to spread the test results to multiple sub-areas within the same camera area
-- (this way, we don't have to do the actual testing loop with appropriate slack for each of the sub areas individually - which would really be the correct way to do it)
-- but, with this hack, we spread each test result not only to the actual tested sub area, but also to the other sub-areas within this slack value
-- TODO: the same feature could be used to quickly optimize the areas with 0 target+position follow factors on X or Y axis, by essentially using the internal slack that
-- spans across the entire area, and thus, testing a single sub-area within each row/column would suffice to fill all of the relevant sub-areas.
-- (these values change on-the-fly)
local subAreaInternalSlackX = 0.125
local subAreaInternalSlackY = 0.125

-- stepping size, the smaller, the better result, the bigger the faster the precalc will be
-- highest value for the area splitting (of constant 4) is 0.25 before this will start to result in bugs
-- NOTE: these are now variable values too, they change based on area
local subAreaStepX = 0.0624
local subAreaStepY = 0.124
local subAreaHackStepX = 0.000505
local subAreaHackStepY = 0.001005

local reallyNeedToTestThisObject = false

function optimizeNextObjectInListPhase1()
	local modelUH = optimizationList[optimizationIndex]
	local testComp = gameScene:getSceneInstanceManager():getInstanceByUH(modelUH)

	-- do nothing to the model
	-- begin testing (takes a screenshot)
	local renderingScene = gameScene:getRenderingScene()
	if (allObjectQuickTestPassPhase or allObjectQuickTestDonePassPhase) then
		reallyNeedToTestThisObject = renderingScene:beginVisibilityCacheObjectTesting(testComp:getGuid(), true)
	else
		reallyNeedToTestThisObject = renderingScene:beginVisibilityCacheObjectTesting(testComp:getGuid(), false)
	end
	
	if reallyNeedToTestThisObject then
		-- flag the model visually for the next frame
		-- (need to do it now, cos there might be a frame lag for those settings to actually get applied)
		if (not allObjectQuickTestDonePassPhase) then
			testComp:setTempOptimizationVisualization(true, false)
		end

		if (allObjectQuickTestPassPhase or allObjectQuickTestDonePassPhase) then
			optimizeNextObjectInListPhase2()
		else
			state:runLuaStringWithDelay("editor.ObjectVisibility.optimizeNextObjectInListPhase2()", 1)
		end
	else
		optimizeNextObjectInListPhase2()
	end	
end

local skippetySkip = 0

function optimizeNextObjectInListPhase2()
	local modelUH = optimizationList[optimizationIndex]
	local testComp = gameScene:getSceneInstanceManager():getInstanceByUH(modelUH)

	-- test (take a screenshot of the currently modified version)
	local renderingScene = gameScene:getRenderingScene()
	if (allObjectQuickTestPassPhase or allObjectQuickTestDonePassPhase) then
		renderingScene:testVisibilityCacheObject(testComp:getGuid(), true)
	else
		renderingScene:testVisibilityCacheObject(testComp:getGuid(), false)
	end
	
	if (reallyNeedToTestThisObject) then
		if (not allObjectQuickTestPassPhase) then
			testComp:setTempOptimizationVisualization(false, false)
		end
	end	

	-- end testing (for some possible parallelization, this should be done later on, just before the next test begins, but that's not really supported now anyway)
	if (allObjectQuickTestPassPhase or allObjectQuickTestDonePassPhase) then
		renderingScene:endVisibilityCacheObjectTesting(true)
	else
		renderingScene:endVisibilityCacheObjectTesting(false)
	end
	
	local wasVisible = renderingScene:wasLastTestedObjectVisible()
	--if (wasVisible) then
		--logger:info("Model " .. tostring(modelUH) .. " was visible.")
	--else
		--logger:info("Model " .. tostring(modelUH) .. " was invisible.")
	--end
	
	-- optimize the next object if one available in the list, otherwise done
	optimizationIndex = optimizationIndex + 1
	if (optimizationIndex	<= #optimizationList) then
		if (((reallyNeedToTestThisObject and not(allObjectQuickTestPassPhase or allObjectQuickTestDonePassPhase))) or skippetySkip > 100) then
			skippetySkip = 0
			state:runLuaStringWithDelay("editor.ObjectVisibility.optimizeNextObjectInListPhase1()", 1)
		else
			-- don't want to stack overflow...
			skippetySkip = skippetySkip + 1
			optimizeNextObjectInListPhase1()
		end
	else
		if (allObjectQuickTestPassPhase) then
			allObjectQuickTestPassPhase = false
			allObjectQuickTestDonePassPhase = true
			optimizationIndex = 1
			renderingScene:screenshotForCompare2()
			state:runLuaStringWithDelay("editor.ObjectVisibility.optimizeNextObjectInListPhase1()", 1)
		else
			if (allObjectQuickTestDonePassPhase) then
				allObjectQuickTestDonePassPhase = false
				if renderingScene:doScreenshotsDiffer() then
					optimizationIndex = 1
					state:runLuaStringWithDelay("editor.ObjectVisibility.optimizeNextObjectInListPhase1()", 1)
				else
					-- no point in doing one-by-one checks.
					optimizeCurrentCameraSubAreaObjectsImplDone()
				end				
			else
				optimizeCurrentCameraSubAreaObjectsImplDone()
			end
		end
	end
end

local optimizeCameraAreaUH = nil

function optimizeCurrentCameraSubAreaObjectsImpl()
	local camObj = gameScene:getSceneInstanceManager():getInstanceByUH(optimizeCameraAreaUH)
	editor.ExternalUI.applyCameraAreaToView(camObj, true, optimizationSubAreaX, 0.5, optimizationSubAreaY, optimizationGlobalOffsetX, optimizationGlobalOffsetY, optimizationGlobalOffsetZ)

	--logger:info("Optimizing sub-area " .. tostring(optimizationSubAreaX) .. ", " .. tostring(optimizationSubAreaY))

	-- must delay to ensure models in view list is correct
	state:runLuaStringWithDelay("editor.ObjectVisibility.optimizeCurrentCameraSubAreaObjectsImplDelayedWait1()", 1)
end

function optimizeCurrentCameraSubAreaObjectsImplDelayedWait1()
	state:runLuaStringWithDelay("editor.ObjectVisibility.optimizeCurrentCameraSubAreaObjectsImplDelayedWait2()", 1)
end
function optimizeCurrentCameraSubAreaObjectsImplDelayedWait2()
	state:runLuaStringWithDelay("editor.ObjectVisibility.optimizeCurrentCameraSubAreaObjectsImplDelayedWait3()", 1)
end
function optimizeCurrentCameraSubAreaObjectsImplDelayedWait3()
	state:runLuaStringWithDelay("editor.ObjectVisibility.optimizeCurrentCameraSubAreaObjectsImplDelayedWait4()", 1)
end
function optimizeCurrentCameraSubAreaObjectsImplDelayedWait4()
	state:runLuaStringWithDelay("editor.ObjectVisibility.optimizeCurrentCameraSubAreaObjectsImplDelayed()", 1)
end

function optimizeCurrentCameraSubAreaObjectsImplDelayed()

	local renderingScene = gameScene:getRenderingScene()

-- TEMP
--subAreaInternalSlackX	= 0
--subAreaInternalSlackY = 0
	
	local clampedMinX = optimizationSubAreaX - subAreaInternalSlackX
	if (clampedMinX < 0.0) then
		clampedMinX = 0.0
	end
	if (clampedMinX > 1.0) then
		clampedMinX = 1.0
	end
	local clampedMinY = optimizationSubAreaY - subAreaInternalSlackY
	if (clampedMinY < 0.0) then
		clampedMinY = 0.0
	end
	if (clampedMinY > 1.0) then
		clampedMinY = 1.0
	end
	local clampedMaxX = optimizationSubAreaX + subAreaInternalSlackX
	if (clampedMaxX < 0.0) then
		clampedMaxX = 0.0
	end
	if (clampedMaxX > 1.0) then
		clampedMaxX = 1.0
	end
	local clampedMaxY = optimizationSubAreaY + subAreaInternalSlackY
	if (clampedMaxY < 0.0) then
		clampedMaxY = 0.0
	end
	if (clampedMaxY > 1.0) then
		clampedMaxY = 1.0
	end
	renderingScene:beginVisibilityCacheCameraSubAreaTestingNormalizedRange(clampedMinX, clampedMinY, clampedMaxX, clampedMaxY)

	local modelsInView = listOptimizableModelsInCurrentView()
	local lightsInView = listOptimizableLightsInCurrentView()
	local combinedList = modelsInView
	for li=1,#lightsInView do
		table.insert(combinedList, lightsInView[li])
	end
	optimizationList = combinedList	
	optimizationIndex = 1
	if (optimizationIndex	<= #optimizationList) then
		objectOptimizationInProgress = true
		allObjectQuickTestPassPhase = true
		allObjectQuickTestDonePassPhase = false
		renderingScene:screenshotForCompare1()
		state:runLuaStringWithDelay("editor.ObjectVisibility.optimizeNextObjectInListPhase1()", 1)
	else
		logger:warning("No models in view to optimize.")
		optimizeCurrentCameraSubAreaObjectsImplDone()
	end
end

local doHackStepX = false
local doHackStepY = false

function optimizeCurrentCameraSubAreaObjectsImplDone()
	local renderingScene = gameScene:getRenderingScene()
	renderingScene:endVisibilityCacheCameraSubAreaTesting()

	-- add optimizationSubAreaX by some small appropriate value
	-- 
	if (doHackStepX) then
		doHackStepX = false
		optimizationSubAreaX = optimizationSubAreaX + subAreaHackStepX
	else
		doHackStepX = true
		optimizationSubAreaX = optimizationSubAreaX + subAreaStepX
	end
	if (optimizationSubAreaX > 1.0 + subAreaSlackX) then
		doHackStepX = false
		optimizationSubAreaX = -subAreaSlackX
		if (doHackStepY) then
			doHackStepY = false
			optimizationSubAreaY = optimizationSubAreaY + subAreaHackStepY
		else
			doHackStepY = true
			optimizationSubAreaY = optimizationSubAreaY + subAreaStepY
		end
	end
	local allDoneWithSlack = false
	if (optimizationSubAreaY > 1.0 + subAreaSlackY) then
		-- all done with the sub-areas 
		-- but more hacks approach, the global absolute slack...
		doHackStepX = false
		doHackStepY = false
		optimizationSubAreaX = -subAreaSlackX
		optimizationSubAreaY = -subAreaSlackY
	
		-- still, do the global slack stuff...
		if (optimizationGlobalOffsetIndex < #optimizationGlobalOffsetPattern) then
			optimizationGlobalOffsetIndex = optimizationGlobalOffsetIndex + 1 
			optimizationGlobalOffsetX = optimizationGlobalOffsetPattern[optimizationGlobalOffsetIndex][1]
			optimizationGlobalOffsetY = optimizationGlobalOffsetPattern[optimizationGlobalOffsetIndex][2]
			optimizationGlobalOffsetZ = optimizationGlobalOffsetPattern[optimizationGlobalOffsetIndex][3]
		else
			allDoneWithSlack = true
		end
	end
	
	if (allDoneWithSlack) then
		optimizeCurrentCameraAreaObjectsImplDone()
	else
		-- time for the next sub-area... (or possibly the same sub area at a different position for small steps)
		optimizeCurrentCameraSubAreaObjectsImpl()
	end
end

-- this can only be called if a camera area for optimization was selected earlier
function optimizeCurrentCameraAreaObjectsImpl()

	previewNoCameraAreaOptimization()
	gameScene:getRenderingScene():setStoreRenderedModelIds(true)
	gameScene:getRenderingScene():setStoreRenderedLightIds(true)
	gameScene:getParticleScene():setParticleUpdateEnabled(false)
	state:setGameVisualizationMode(true)
	-- dynamic objects hidden (FIXME: the dynamic objects filter is not really correct, so not all dynamic really get hidden here)
	filteringModule:setVisibilityFilterString("0,data/filter/native/nativefilter_composite_staticentities_allowall|0,data/filter/native/nativefilter_composite_aihelper_allowall|0,data/filter/native/nativefilter_composite_lights_allowall|0,data/filter/native/nativefilter_composite_audio_allowall|0,data/filter/native/nativefilter_composite_camera_area_allowall|0,data/filter/native/nativefilter_composite_respawn_area_allowall|0,data/filter/native/nativefilter_composite_rope_area_allowall|0,data/filter/native/nativefilter_composite_animation_area_allowall|0,data/filter/native/nativefilter_composite_other_area_allowall|0,data/filter/native/nativefilter_composite_legacyunit_allowall|0,data/filter/native/nativefilter_composite_otherinstances_allowall|2,data/filter/native/nativefilter_visiblelayersfilter")
	-- no debug vis
	filteringModule:setDebugVisualizeFilterString("0,None")
	state:applyEditorFilters()
	--debug.DebugStatsOverlayUtil.clearOverlay()
	if (debugComponent) then
		debugComponent:toggleDebugStatsOverlay()
	end
	renderingModule:setShowGlow(false)
	renderingModule:setEnableSway(false)
	renderingModule:setAntiAliasSamples(2)
	--gameScene:getRenderingScene():setUseVisibilityCache(false)

	-- determine appropriate slack based on area size
	local camObj = gameScene:getSceneInstanceManager():getInstanceByUH(optimizeCameraAreaUH)
	if (camObj) then
		-- TODO: could really rather calculate this so that the slack would always match specified absolute amount of meters
		local areaComp = camObj:findComponent(area.BoxAreaComponent)
		local d = areaComp:getDimensions()
		if (d.x < 15.0) then
			subAreaSlackX = 0.125  -- slack around the whole cam area
			subAreaInternalSlackX = 0.0625 --0.125 -- internal slack within area, between sub-areas
		else
			subAreaSlackX = 0.125 
			subAreaInternalSlackX = 0.0625
		end
		if (d.y < 15.0) then
			subAreaSlackY = 0.125
			subAreaInternalSlackY = 0.0625
		else
			subAreaSlackY = 0.125
			subAreaInternalSlackY = 0.0625
		end
		local propsComp = camObj:findComponent(trinebase.gameplay.TrineCameraPropertiesComponent)
		local posFollow = propsComp:getPositionFollowFactor()
		local tarFollow = propsComp:getTargetFollowFactor()
		subAreaStepX = 0.124
		subAreaStepY = 0.124
		subAreaHackStepX = 0.001005
		subAreaHackStepY = 0.001005
		if (posFollow.x == 0 and tarFollow.x == 0) then
			subAreaStepX = 1
			subAreaHackStepX = 1
			subAreaInternalSlackX = 2 -- ensure spreading the test result to entire camera area sub-row
		end
		if (posFollow.y == 0 and tarFollow.y == 0) then
			subAreaStepY = 1
			subAreaHackStepY = 1
			subAreaInternalSlackY = 2 -- ensure spreading the test result to entire camera area sub-column
		end		
	end

	-- using some slack around the area to make sure no popping occurs when there are camera area gaps 
	optimizationSubAreaX = -subAreaSlackX
	optimizationSubAreaY = -subAreaSlackY
	doHackStepX = false
	doHackStepY = false
	
	-- more horrible hacks! some absolute (non-camera area conf relative slack)
	optimizationGlobalOffsetX = 0.0
	optimizationGlobalOffsetY = 0.0
	optimizationGlobalOffsetZ = 0.0
	optimizationGlobalOffsetIndex = 1
	
	optimizeCurrentCameraSubAreaObjectsImpl()
end

function optimizeCurrentView()
	-- solve current camera area / sub area
end

function optimizeLastViewedCamera()
	optimizationCameraAreaList = { }
	optimizationCameraAreaIndex = 0
	if (editor.ExternalUI.lastAppliedCameraGuid ~= GUID_NONE) then
		local camObj = gameScene:getSceneInstanceManager():findInstanceByGUID(editor.ExternalUI.lastAppliedCameraGuid)
		optimizeCameraArea(camObj:getUnifiedHandle())
	end
end

local currentlyOptimizingCameraAreaGuid = GUID_NONE

function previewLastOptimizedCameraArea()
	gameScene:setPreviewCameraAreaOptimization(currentlyOptimizingCameraAreaGuid)  -- , 0.5, 0.5
end

function previewLastViewedCameraAreaOptimization()
	gameScene:setPreviewCameraAreaOptimization(editor.ExternalUI.lastAppliedCameraGuid)  -- , 0.5, 0.5
end

--function previewLastViewedCameraAreaOptimizationAtSubArea(subPosX, subPosY)
--	gameScene:setPreviewCameraAreaOptimization(editor.ExternalUI.lastAppliedCameraGuid, subPosX, subPosY)
--end

function previewNoCameraAreaOptimization()
	gameScene:setPreviewCameraAreaOptimization(GUID_NONE) -- , 0.5, 0.5
end

function optimizeCameraArea(cameraAreaUH)	
	local renderingScene = gameScene:getRenderingScene()
	
	optimizeCameraAreaUH = cameraAreaUH
	
	local camObj = gameScene:getSceneInstanceManager():getInstanceByUH(cameraAreaUH)
	editor.ExternalUI.applyCameraAreaToView(camObj, true, 0.5, 0.5, 0.5, 0, 0, 0)

	currentlyOptimizingCameraAreaGuid = camObj:getGuid()
	renderingScene:beginVisibilityCacheCameraAreaTesting(currentlyOptimizingCameraAreaGuid)
	
	--app:clearAllErrorTags()
	
	logger:info("Optimizing camera area: "..tostring(currentlyOptimizingCameraAreaGuid))
	
	-- loop position from corner to corner to create sub areas
	-- set that info to the grid vis cache
	-- then finally, optimize all the objects in the current view
	optimizeCurrentCameraAreaObjectsImpl()
end

local inVisibilityPatchingMode = false

function beginCameraOptimizationPatchMode()
	renderingModule:setVisualizeOcclusionWithColor(true)
	inVisibilityPatchingMode = true
	--debug.DebugStatsOverlayUtil.addVariableToOverlay("fb::rendering::GridVisibilityCache", "occludedPercentage")	
end

function endCameraOptimizationPatchMode()
	renderingModule:setVisualizeOcclusionWithColor(false)
	inVisibilityPatchingMode = false
end

-- list of guids
local patchList = { }
local patchIndex = 0

function patchCameraAreaOptimizationObjectPhase1()
	local modelGuid = patchList[patchIndex]
	
	gameScene:getRenderingScene():beginVisibilityCacheObjectPatchTesting(modelGuid)
	
	state:runLuaStringWithDelay("editor.ObjectVisibility.patchCameraAreaOptimizationObjectPhase2()", 1)	
end

function patchCameraAreaOptimizationObjectPhase2()
	local modelGuid = patchList[patchIndex]
	
	gameScene:getRenderingScene():testVisibilityCacheObjectPatch(modelGuid)
	local wasPatched = gameScene:getRenderingScene():endVisibilityCacheObjectPatchTesting()
	
	if (wasPatched) then
		logger:info("Patched incorrectly occluded " .. tostring(modelGuid))
	end

	patchIndex = patchIndex + 1
	if (patchIndex <= #patchList) then
		state:runLuaStringWithDelay("editor.ObjectVisibility.patchCameraAreaOptimizationObjectPhase1()", 1)	
	else
		patchCameraAreaOptimizationForCurrentViewImplDone()
	end
end

function patchCameraAreaOptimizationForCurrentViewImpl()
	local modelsOccluded = listOccludedModelsInCurrentView()
	patchList = modelsOccluded
	patchIndex = 1

	if (patchIndex <= #patchList) then
		state:runLuaStringWithDelay("editor.ObjectVisibility.patchCameraAreaOptimizationObjectPhase1()", 1)	
	else
		patchCameraAreaOptimizationForCurrentViewImplDone()
	end
end

local debugStatsWasVisibleBeforePatch = false
local waitingForNextPatch = false
local waitingForNextPatchCounter = 0
local extraLongWait = false

function beginWaitUntilNextThingToPatch()
	if (not(inVisibilityPatchingMode)) then
		return
	end
	
	if (waitingForNextPatch) then
		return
	end

	renderingModule:setShowFog(false)
	waitingForNextPatch = true
	waitingForNextPatchCounter = 50 * 1000 -- approx 10-50 seconds depending on fps (10-50 * 1000msec)
	state:runLuaStringWithDelay("editor.ObjectVisibility.waitUntilNextThingToPatchImpl()", 10)	
end

function endWaitUntilNextThingToPatch()
	waitingForNextPatch = false
end

function waitUntilNextThingToPatchImpl()
	if (not(waitingForNextPatch)) then
		return
	end

	-- sample screen every 10 msec for some totally red pixels suddenly appearing
	if (gameScene:getRenderingScene():shouldTryToPatchVisibilityCacheForCurrentScreen()) then
		waitingForNextPatch = false
		waitingForNextPatchCounter = 0
		extraLongWait = true
		patchCameraAreaOptimizationForCurrentView()
	else
		if (waitingForNextPatch) then
			waitingForNextPatchCounter = waitingForNextPatchCounter - 10
			if (waitingForNextPatchCounter < 0) then
				waitingForNextPatch = false
				waitingForNextPatchCounter = 0
			else
				state:runLuaStringWithDelay("editor.ObjectVisibility.waitUntilNextThingToPatchImpl()", 10)	
			end
		end
	end
end

function patchCameraAreaOptimizationForCurrentView()
	if (not(inVisibilityPatchingMode)) then
		return
	end
	waitingForNextPatch = false
	
	local t = gameScene:getSceneInstanceManager():findInstanceByName("thief0")
	if (t) then
		local m = t:findComponent(rendering.ModelComponent)
		if (m) then
			m:setVisibilityEnabled(false)
		end
	end
	t = gameScene:getSceneInstanceManager():findInstanceByName("warrior0")
	if (t) then
		local m = t:findComponent(rendering.ModelComponent)
		if (m) then
			m:setVisibilityEnabled(false)
		end
	end
	t = gameScene:getSceneInstanceManager():findInstanceByName("wizard0")
	if (t) then
		local m = t:findComponent(rendering.ModelComponent)
		if (m) then
			m:setVisibilityEnabled(false)
		end
	end

	gameScene:getRenderingScene():setStoreRenderedModelIds(true)
	gameScene:getRenderingScene():setStoreRenderedLightIds(true)
	gameScene:getParticleScene():setParticleUpdateEnabled(false)
	if debugStatsOverlay then
		debugStatsWasVisibleBeforePatch = true
		if debugComponent then
			debugComponent:toggleDebugStatsOverlay()
		end
	else
		debugStatsWasVisibleBeforePatch = false
		if debugComponent then
			debugComponent:toggleDebugStatsOverlay()
		end
	end
	renderingModule:setShowGlow(false)
	renderingModule:setEnableSway(false)
	gameScene:getRenderingScene():beginVisibilityCachePatching()
	
	gameStatusModule:setGamePauseStatus("patchCameraAreaOptimization", 10, true)
	
	if (extraLongWait) then
		extraLongWait = false
		state:runLuaStringWithDelay("editor.ObjectVisibility.patchCameraAreaOptimizationForCurrentViewImpl()", 3000)
	else
		state:runLuaStringWithDelay("editor.ObjectVisibility.patchCameraAreaOptimizationForCurrentViewImpl()", 1000)
	end
end

function patchCameraAreaOptimizationForCurrentViewImplDone()
	gameStatusModule:removeGamePauseStatus("patchCameraAreaOptimization")
	
	gameScene:getRenderingScene():endVisibilityCachePatching()
	gameScene:getRenderingScene():saveVisibilityCachePatchingResult()
	gameScene:getRenderingScene():setStoreRenderedModelIds(false)
	gameScene:getRenderingScene():setStoreRenderedLightIds(false)
	gameScene:getParticleScene():setParticleUpdateEnabled(true)
	if (not debugStatsOverlay) and debugStatsWasVisibleBeforePatch then
		if debugComponent then
			debugComponent:toggleDebugStatsOverlay()
		end
	end
	renderingModule:setShowGlow(true)
	renderingModule:setEnableSway(true)
	
	
	local t = gameScene:getSceneInstanceManager():findInstanceByName("thief0")
	if (t) then
		local m = t:findComponent(rendering.ModelComponent)
		if (m) then
			m:setVisibilityEnabled(true)
		end
	end
	t = gameScene:getSceneInstanceManager():findInstanceByName("warrior0")
	if (t) then
		local m = t:findComponent(rendering.ModelComponent)
		if (m) then
			--m:setVisibilityEnabled(true)
		end
	end
	t = gameScene:getSceneInstanceManager():findInstanceByName("wizard0")
	if (t) then
		local m = t:findComponent(rendering.ModelComponent)
		if (m) then
			m:setVisibilityEnabled(true)
		end
	end	
	
end

local optimizationCameraAreaList = { }
local optimizationCameraAreaIndex = 0

function getDistanceOfCameraAreas(area1, area2)
	local areaObj1 = gameScene:getSceneInstanceManager():findInstanceByGUID(area1)
	local areaObj2 = gameScene:getSceneInstanceManager():findInstanceByGUID(area2)
	if (areaObj1 ~= nil and areaObj2 ~= nil) then
		-- FIXME: should really look at the area dimensions, offset and all that! and compare their closeness
		-- for now, just using the transform position to approximate
		local p1 = areaObj1:findComponent(engine.component.TransformComponent):getPosition()
		local p2 = areaObj2:findComponent(engine.component.TransformComponent):getPosition()
		local diff = p1 - p2
		local dist = diff:getLength()
		return dist
	end	
	
	return 99999
end

function addNearbyCameraAreasToKnownWarpAreas(fromCameraArea)
	local renderingScene = gameScene:getRenderingScene()
	
	local knownAllNearbyAreasList = nil
	knownAllNearbyAreasList = { }
	function listCameraAreaForKnownAreas(obj, params)
		table.insert(knownAllNearbyAreasList, obj:getGuid())
	end
	editor.Editor.seekInstances("All", "AdvancedCameraAreaEntity", listCameraAreaForKnownAreas)
	editor.Editor.seekInstances("All", "FarCoopTrineCameraAreaEntity", listCameraAreaForKnownAreas)
	editor.Editor.seekInstances("All", "NormalTrineCameraAreaEntity", listCameraAreaForKnownAreas)
	
	-- haxity hack. superior sorting logic to getting 7 best entries (maybe I should have just called sort?) :P
	knownClosestNearbyAreasList = { { g=GUID_NONE, d=999 },  { g=GUID_NONE, d=999 },  { g=GUID_NONE, d=999 },  { g=GUID_NONE, d=999 },  { g=GUID_NONE, d=999 }, { g=GUID_NONE, d=999 }, { g=GUID_NONE, d=999 } }
	for i = 1,#knownAllNearbyAreasList do
		local toCameraArea = knownAllNearbyAreasList[i]
		if (toCameraArea ~= fromCameraArea) then		
			local biggestD = 0
			local biggestJ = 0
			for j = 1,#knownClosestNearbyAreasList do
				if (knownClosestNearbyAreasList[j].d > biggestD) then
					biggestD = knownClosestNearbyAreasList[j].d
					biggestJ = j
				end
			end
			local dist = getDistanceOfCameraAreas(fromCameraArea, toCameraArea)
			if (biggestJ ~= 0) then
				if (dist < biggestD) then
					knownClosestNearbyAreasList[biggestJ].d = dist
					knownClosestNearbyAreasList[biggestJ].g = toCameraArea
				end
			end
		end
	end	
	
	local finalList = { }
	for i = 1,#knownClosestNearbyAreasList do
		if (knownClosestNearbyAreasList[i].g ~= GUID_NONE) then 
			renderingScene:addVisibilityCacheKnownWarpArea(fromCameraArea, knownClosestNearbyAreasList[i].g)
			logger:info("Adding nearby camera area as known warp area: "..tostring(knownClosestNearbyAreasList[i].g))	
		end
	end
	
end

function optimizeCurrentCameraAreaObjectsImplDone()
	-- save the current camera area cache
	objectOptimizationInProgress = false

	local renderingScene = gameScene:getRenderingScene()
	renderingScene:endVisibilityCacheCameraAreaTesting()
	-- HACK: add nearby camera areas to the warp list
	addNearbyCameraAreasToKnownWarpAreas(currentlyOptimizingCameraAreaGuid)
	
	renderingScene:saveVisibilityCacheTestingResult(currentlyOptimizingCameraAreaGuid)
	
	-- optimize the next camera area if one available in the list
	optimizationCameraAreaIndex = optimizationCameraAreaIndex + 1
	if (optimizationCameraAreaIndex <= #optimizationCameraAreaList) then
		optimizeCameraArea(optimizationCameraAreaList[optimizationCameraAreaIndex])
	else
		-- all done
		optimizeAllCameraAreasDone()
	end	
end

function optimizeAllCameraAreasDone()
	allOptimizationInProgress = false
	gameScene:getRenderingScene():setStoreRenderedModelIds(false)
	gameScene:getRenderingScene():setStoreRenderedLightIds(false)
	renderingModule:setShowGlow(true)
	renderingModule:setEnableSway(true)
	state:setGameVisualizationMode(false)
end

function cancelOptimizeAllCameraAreas()
	optimizationIndex = #optimizationList
	optimizationCameraAreaIndex = #optimizationCameraAreaList
	optimizationSubAreaX = 1.0 + maxSubAreaSlackX
	optimizationSubAreaY = 1.0 + maxSubAreaSlackY
	optimizationGlobalOffsetIndex = #optimizationGlobalOffsetPattern
end


declareReload(thisModule, [[skipNumAreasAtStartGlobal]])
skipNumAreasAtStartGlobal = 0

function optimizeAllCameraAreas(skipNumAreasAtStartOpt)
	if (allOptimizationInProgress or objectOptimizationInProgress) then
		logger:error("Cannot start optimization, previous optimization is still in progress.")
		return
	end

	optimizationCameraAreaList = { }
	
	allOptimizationInProgress = true
	
	-- loop through all camera areas, do optimize
	function listCameraAreaForOptimization(obj, params)
		table.insert(optimizationCameraAreaList, obj:getUnifiedHandle())
	end
	if not(optimizeOnlyFarCoop) then
		editor.Editor.seekInstances("All", "AdvancedCameraAreaEntity", listCameraAreaForOptimization)	
		editor.Editor.seekInstances("All", "NormalTrineCameraAreaEntity", listCameraAreaForOptimization)
	end
	editor.Editor.seekInstances("All", "FarCoopTrineCameraAreaEntity", listCameraAreaForOptimization)
	
	optimizationCameraAreaIndex = 1
	
	if (skipNumAreasAtStartOpt) then
		optimizationCameraAreaIndex = optimizationCameraAreaIndex + skipNumAreasAtStartOpt
	end
	
	optimizationCameraAreaIndex = optimizationCameraAreaIndex + skipNumAreasAtStartGlobal
	
	if (optimizationCameraAreaIndex <= #optimizationCameraAreaList) then
		optimizeCameraArea(optimizationCameraAreaList[optimizationCameraAreaIndex])
	end
end

function printModelsInCurrentView()
	local modelsInView = listModelsInCurrentView()
	local optiModelsInView = listOptimizableModelsInCurrentView()
	for i = 1,#modelsInView do
		logger:info("Model in view UH: "..tostring(modelsInView[i]))
	end
	logger:info("Total models in view "..#modelsInView .. " of which " ..#optiModelsInView.. " are optimizable.")
end

function printCurrentViewOcclusionStats()
end

function printOccludedObjectsInCurrentView()
end

function selectOccludedObjectsInCurrentView()
end

function printVisibleObjectsInCurrentView()
end

function selectVisibleObjectsInCurrentView()
end
