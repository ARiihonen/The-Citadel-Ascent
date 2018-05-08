module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

local thisModule = _M



declareReload(thisModule, [[boneExposeCreationList]])
declareReload(thisModule, [[boneAnimateCreationList]])
declareReload(thisModule, [[animateEditorId]])
declareReload(thisModule, [[exposeEditorId]])
boneExposeCreationList = { }
boneAnimateCreationList = { }
animateEditorId = ""
exposeEditorId = ""

declareReload(thisModule, [[boneUnexposeCreationList]])
declareReload(thisModule, [[boneUnanimateCreationList]])
declareReload(thisModule, [[unanimateEditorId]])
declareReload(thisModule, [[unexposeEditorId]])
boneUnexposeCreationList = { }
boneUnanimateCreationList = { }
unanimateEditorId = ""
unexposeEditorId = ""

-- helper function, returns a component if the given entity object has a component of given type that has a BoneName property
-- that is set to the boneName parameter
function getComponentWithBoneName(obj, compType, boneName)
	assert_instance(obj)
	--assert_component_type(compType)
	assert_string(boneName)

	local iter = obj:findAllComponents(compType);
	local c = iter:next()
	while c do
		if c:getBoneName() == boneName then
			return c
		end
		c = iter:next()
	end
	return nil
end


-- helper function, returns true if the given entity object has a component of given type that has a BoneName property
-- that is set to the boneName parameter
function hasComponentWithBoneName(obj, compType, boneName)
	if getComponentWithBoneName(obj, compType, boneName) then
		return true
	else
		return false
	end
end


function isBoneExposed(obj, boneName)
	-- only entities supported atm, could add support for some kind of type tweaking as well.
	assert_entity(obj)
	assert_string(boneName)
	return hasComponentWithBoneName(obj, gameplay.ExposeModelBoneComponent, boneName);
end


function isBoneAnimated(obj, boneName)
	-- only entities supported atm, could add support for some kind of type tweaking as well.
	assert_entity(obj)
	assert_string(boneName)
	return hasComponentWithBoneName(obj, gameplay.AnimateModelBoneComponent, boneName);
end


function isAnimatedBoneConnected(obj, boneName)
	-- only entities supported atm, could add support for some kind of type tweaking as well.
	assert_entity(obj)
	assert_string(boneName)
	if not(isBoneAnimated(obj, boneName)) then
		logger:error("isAnimatedBoneConnected called for an unanimated bone.")
		return false
	end
	
	-- TODO: see if there are connections to the animate component or the related null
	
	return false
end


function isExposedBoneConnected(obj, boneName)
	-- only entities supported atm, could add support for some kind of type tweaking as well.
	assert_entity(obj)
	assert_string(boneName)
	if not(isBoneExposed(obj, boneName)) then
		logger:error("isExposedBoneConnected called for an unexposed bone.")
		return false
	end

	-- TODO: see if there are connections from the expose component or the related null
	
	return false
end


function doesExposedBoneHaveNull(obj, boneName)
	-- only entities supported atm, could add support for some kind of type tweaking as well.
	assert_entity(obj)
	assert_string(boneName)
	if not(isBoneExposed(obj, boneName)) then
		logger:error("doesExposedBoneHaveNull called for an unexposed bone.")
		return false
	end	
	
	local c = getComponentWithBoneName(obj, gameplay.ExposeModelBoneComponent, boneName)
	assert_component(c)

	if (c:getRelatedNullEntity() ~= UH_NONE) then
		return true
	else
		return false
	end
end


function doesAnimatedBoneHaveNull(obj, boneName)
	-- only entities supported atm, could add support for some kind of type tweaking as well.
	assert_entity(obj)
	assert_string(boneName)
	if not(isBoneAnimated(obj, boneName)) then
		logger:error("doesAnimatedBoneHaveNull called for an unanimated bone.")
		return false
	end	
	
	local c = getComponentWithBoneName(obj, gameplay.AnimateModelBoneComponent, boneName)
	assert_component(c)

	if (c:getRelatedNullEntity() ~= UH_NONE) then
		return true
	else
		return false
	end
end


function getAnimatedBoneNull(obj, boneName)
	-- only entities supported atm, could add support for some kind of type tweaking as well.
	assert_entity(obj)
	assert_string(boneName)
	if not(doesAnimatedBoneHaveNull(obj, boneName)) then
		logger:error("getAnimatedBoneNull called for a that has no null for animation.")
		return nil
	end
	
	local c = getComponentWithBoneName(obj, gameplay.AnimateModelBoneComponent, boneName)
	assert_component(c)

	local nullUH = c:getRelatedNullEntity()
	local nullEntity = obj:getInstanceManager():getInstanceByUH(nullUH)
	return nullEntity
end


function getExposedBoneNull(obj, boneName)
	-- only entities supported atm, could add support for some kind of type tweaking as well.
	assert_entity(obj)
	assert_string(boneName)
	if not(doesExposedBoneHaveNull(obj, boneName)) then
		logger:error("getExposedBoneNull called for a that has no null for exposing.")
		return nil
	end
	
	local c = getComponentWithBoneName(obj, gameplay.ExposeModelBoneComponent, boneName)
	assert_component(c)

	local nullUH = c:getRelatedNullEntity()
	local nullEntity = obj:getInstanceManager():getInstanceByUH(nullUH)
	return nullEntity
end


function verifyAnimateExposeNull(obj, comp, nullUH)
	assert_entity(obj) 
	assert_component(comp) 
	assert_uh(nullUH) 
	
	-- null entity exists?
	local nullEntity = obj:getInstanceManager():getInstanceByUH(nullUH)
	if (not nullEntity) then
		return false
	end
	
	-- null has the bone scripting component?
	local boneScriptingEntityComponent = nullEntity:findComponent(gameplay.BoneScriptingEntityComponent)
	if (not boneScriptingEntityComponent) then
		return false
	end
	
	-- the bone scripting component knows the correct owner?
	local ownerUHCheck = boneScriptingEntityComponent:getBoneOwnerEntity()
	if (ownerUHCheck ~= obj:getUnifiedHandle()) then
		return false
	end	
		
	-- the bone scripting component knowns the correct bone
	local nullBoneName = boneScriptingEntityComponent:getBoneName()
	if (nullBoneName ~= comp:getBoneName()) then
		return false
	end	
	
	-- the bone scripting component knowns its animate/expose purpose correctly (and has the ref to the component)
	if comp:inherits(gameplay.AnimateModelBoneComponent) then
		if (boneScriptingEntityComponent:getAnimate() == true and boneScriptingEntityComponent:getExpose() == false) then
			-- ok
		else
			return false
		end
		if (boneScriptingEntityComponent:getBoneAnimateComponent() ~= comp:getUnifiedHandle()) then
			return false
		end
	end
	if comp:inherits(gameplay.ExposeModelBoneComponent) then
		if (boneScriptingEntityComponent:getAnimate() == false and boneScriptingEntityComponent:getExpose() == true) then
			-- ok
		else
			return false
		end
		if (boneScriptingEntityComponent:getBoneExposeComponent() ~= comp:getUnifiedHandle()) then
			return false
		end
	end
	
	return true
end


function isBoneOkForAutomatedOperations(obj, boneName)
	-- only entities supported atm, could add support for some kind of type tweaking as well.
	assert_entity(obj) 
	assert_string(boneName)	
	if (hasDuplicateBoneComponents(obj, boneName)) then
		return false
	end

	-- verify that any possible animate/expose components that have null counterparts, have matching 
	-- bone names, references to the owner object, etc. there.
	
	-- expose null ok? (if it exists)
	local c = getComponentWithBoneName(obj, gameplay.AnimateModelBoneComponent, boneName)
	if (c) then
		if (c:getRelatedNullEntity() ~= UH_NONE) then
			local ok = verifyAnimateExposeNull(obj, c, nullUH);			
			if (not ok) then
				return false
			end
		end		
	end
	
	-- animate null ok? (if it exists)
	local c = getComponentWithBoneName(obj, gameplay.ExposeModelBoneComponent, boneName)
	if (c) then
		local nullUH = c:getRelatedNullEntity();
		if (nullUH ~= UH_NONE) then
			local ok = verifyAnimateExposeNull(obj, c, nullUH);
			if (not ok) then
				return false
			end
		end
	end
	
	return true
end


-- finds the null entity for the given bone in given object (with given component type - animate/expose)
function findBoneNullFor(obj, boneName, compType)
	local comp = getComponentWithBoneName(obj, compType, boneName)
	if (comp) then
		if (comp:getRelatedNullEntity() ~= UH_NONE) then
			return comp:getInstanceManager():getInstanceByUH(comp:getRelatedNullEntity())
		end
	end
	
	return nil
end

-- returns the null object for the parent bone of given bone (if one exists)
-- NOTICE: returns a grand parent if no null for the parent bone (but one exists for a grand parent)
function findParentBoneNullFor(obj, boneName, compType)
	local modelComp = obj:findComponent(rendering.ModelComponent)
	if (not modelComp) then
		logger:error("No model component when trying to solve bone hierarchy?")
		return nil
	end

	-- solve the parent bone for boneName in the obj entity...
	local parentBoneExists = modelComp:hasParentBoneByBoneName(boneName)
	
	if (parentBoneExists) then
		local parentBoneName = modelComp:getParentBoneNameByBoneName(boneName)
		if (parentBoneName == "") then
			logger:error("Got an empty parent bone name for the bone \""..boneName.."\".")
			return nil
		end
		local foundParentNull = findBoneNullFor(obj, parentBoneName, compType)
		-- If not found, try recursively to find a grand parent instead
		if (foundParentNull) then
			return foundParentNull
		else
			return findParentBoneNullFor(obj, parentBoneName, compType)
		end
	else
		return nil
	end
end


function createdNullForExposeAnimateModelBoneComponentImpl(nullObj, combinedParams, expose, animate)
	assert_instance(nullObj)
	assert_table(combinedParams)
	
	-- create the nulls to currently active layer
	local layer = state:getSelectedLayer()
	nullObj:setLayer(layer)
	
	local comp = nullObj:findComponent(gameplay.BoneScriptingEntityComponent)
	local transformComp = nullObj:findComponent(engine.component.TransformComponent)
	local scaleComp = nullObj:findComponent(engine.component.ScaleComponent)
	assert_component(comp)
	assert_component(transformComp)
	assert_component(scaleComp)

	local relatedComponentUH = combinedParams.relatedComponentUH
	local boneName = combinedParams.boneName
	local params = combinedParams.additionalParams
	local initialPosition = combinedParams.position
	local initialRotation = combinedParams.rotation
	local initialScale = combinedParams.scale
	local boneDimensions = combinedParams.boneDimensions
	
	assert_uh(relatedComponentUH)
	assert_string(boneName)
	assert_table(params)

	comp:setBoneName(boneName)
	if (animate and expose) then
		logger:error("Oops, both expose and animate are true. (Bugged)")
	end
	if (expose) then
		comp:setExpose(true)
	end
	if (animate) then
		comp:setAnimate(true)
	end

	-- the AnimateModelBoneComponent/ExposeModelBoneComponent
	local relatedComp = comp:getInstanceManager():getInstanceByUH(relatedComponentUH)
	if (not relatedComp) then
		logger:error("Failed to find the related component for the null (animateBones/exposeBones bugged).")
	end
	
	-- set the reference UH properties
	-- first from the actual entity to bone null 
	relatedComp:setRelatedNullEntity(comp:getFinalOwner():getUnifiedHandle())
	-- and then vice versa
	if (animate) then
		comp:setBoneAnimateComponent(relatedComp:getUnifiedHandle())
	end
	if (expose) then
		comp:setBoneExposeComponent(relatedComp:getUnifiedHandle())
	end
	comp:setBoneOwnerEntity(relatedComp:getFinalOwner():getUnifiedHandle())
	comp:setBoneDimensions(combinedParams.boneDimensions)
	
	transformComp:setPosition(initialPosition)
	transformComp:setRotation(initialRotation)	
	scaleComp:setScale(initialScale)
	
	-- handle additional parameters
	local visComp = nullObj:findComponent(engine.component.EditableScriptingEntityComponent)
	visComp:setVisualizationTextMode(engine.component.ScriptingVisualizationTextModeBone)
	if (expose) then
		visComp:setVisualizationShapeColor(COL(0,1,0))
	end
	if (animate) then
		visComp:setVisualizationShapeColor(COL(0,0,1))
	end
	if (not params.createVisualization) then
		visComp:setVisualizationShape(engine.component.ScriptingVisualizationShapeHiddenBone)
	end
	if (params.namedVisualization) then
		visComp:setEditorComment(boneName)
	end
	local wasUnderAnotherBone = false
	if (params.createHierarchy) then
		local ownerObj = relatedComp:getFinalOwner()
		local parentNullObj = nil
		if (animate) then
			parentNullObj = findParentBoneNullFor(ownerObj, boneName, gameplay.AnimateModelBoneComponent);
		elseif (expose) then
			parentNullObj = findParentBoneNullFor(ownerObj, boneName, gameplay.ExposeModelBoneComponent);
		end
		if (parentNullObj) then
			editor.ExternalUI.parentObject(nullObj:getGuid(), parentNullObj:getGuid())
			wasUnderAnotherBone = true
		end
	end
	if (params.nullsUnderEntityAsChildren) then
		if (not wasUnderAnotherBone) then
			editor.ExternalUI.parentObject(nullObj:getGuid(), relatedComp:getFinalOwner():getGuid())		
		end
	end
	
	if not nullObj:isStarted() then
		nullObj:start();
	end

	-- go handle the next one
	if (animate) then
		handleNextToAnimate()
	elseif (expose) then
		handleNextToExpose()
	else
		logger:error("No expose nor animate? bugged.");
	end
end

function createdNullForExposeModelBoneComponent(nullObj, combinedParams)
	createdNullForExposeAnimateModelBoneComponentImpl(nullObj, combinedParams, true, false)
end
function createdNullForAnimateModelBoneComponent(nullObj, combinedParams)
	createdNullForExposeAnimateModelBoneComponentImpl(nullObj, combinedParams, false, true)
end

function createdAnimateExposeModelBoneComponentImpl(comp, combinedParams, expose, animate)
	assert_component(comp)
	assert_table(combinedParams)
	
	local boneName = combinedParams.boneName
	local params = combinedParams.additionalParams
	
	assert_string(boneName)
	assert_table(params)
	
	comp:setBoneName(boneName)
	local ownerModelComp = comp:getFinalOwner():findComponent(rendering.ModelComponent)
	local boneDimensions = VC3(0,0,0)
	boneDimensions.x = 1.0
	boneDimensions.y = boneDimensions.x
	boneDimensions.z = 1.0
	
	-- dig out the current bone position/rotation/scale...
	local currentBonePosition = ownerModelComp:getRealBonePosition(boneName, VC3(0,0,0))
	local currentBoneRotation = ownerModelComp:getBoneRotation(boneName)
	local currentBoneScale = VC3(1,1,1) --ownerModelComp:getBoneScale(boneName)
	
	if (animate) then
		comp:setInPosition(currentBonePosition)
		comp:setInRotation(currentBoneRotation)
		comp:setInScale(currentBoneScale)
	end
	if (expose) then
		if (params.activeInEditor) then
			comp:setActiveInEditor(true)
		end
	end
	
	-- create null?
	if (params.createNull) then
		local nullType = typeManager:findTypeByName("BoneNullEntity");
		local instCreateParams = { position=currentBonePosition, rotation=currentBoneRotation, scale=currentBoneScale, boneDimensions=boneDimensions, relatedComponentUH=comp:getUnifiedHandle(), boneName=boneName, additionalParams=params }
		if (animate) then
			comp:getInstanceManager():createNewInstance(nullType:getUnifiedHandle(), createdNullForAnimateModelBoneComponent, instCreateParams);	
		elseif (expose) then
			comp:getInstanceManager():createNewInstance(nullType:getUnifiedHandle(), createdNullForExposeModelBoneComponent, instCreateParams);	
		else
			logger:error("No expose nor animate? bugged.");
		end
	else
		-- no null, go handle the next one
		if (animate) then
			handleNextToAnimate()
		elseif (expose) then
			handleNextToExpose()
		else
			logger:error("No expose nor animate? bugged.");
		end
	end
end

function createdExposeModelBoneComponent(comp, combinedParams)
	createdAnimateExposeModelBoneComponentImpl(comp, combinedParams, true, false)
end
function createdAnimateModelBoneComponent(comp, combinedParams)
	createdAnimateExposeModelBoneComponentImpl(comp, combinedParams, false, true)
end


function animateObjectBone(obj, boneName, params)
	-- only entities supported atm, could add support for some kind of type tweaking as well.
	assert_entity(obj) 
	assert_string(boneName)
	
	if (isBoneAnimated(obj, boneName)) then
		logger:error("Bone is already animated!")
		return
	end

  local compType = typeManager:findTypeByName("AnimateModelBoneComponent");
  obj:getInstanceManager():createNewComponent(compType:getUnifiedHandle(), obj, createdAnimateModelBoneComponent, { boneName=boneName, additionalParams=params });	
end


function exposeObjectBone(obj, boneName, params)
	-- only entities supported atm, could add support for some kind of type tweaking as well.
	assert_entity(obj) 
	assert_string(boneName)
	
	if (isBoneExposed(obj, boneName)) then
		logger:error("Bone is already exposed!")
		return
	end
	
  local compType = typeManager:findTypeByName("ExposeModelBoneComponent");
  obj:getInstanceManager():createNewComponent(compType:getUnifiedHandle(), obj, createdExposeModelBoneComponent, { boneName=boneName, additionalParams=params });	
end



function unexposeObjectBone(obj, boneName)
	-- only entities supported atm, could add support for some kind of type tweaking as well.
	assert_entity(obj) 
	assert_string(boneName)
	
	if (not isBoneExposed(obj, boneName)) then
		logger:error("Bone is not exposed!")
		state:runLuaStringWithDelay("editor.BoneList.handleNextToUnexposeWithMoreDelay()", 100)
		return
	end

	local instMan = obj:getInstanceManager()
	if (doesExposedBoneHaveNull(obj, boneName)) then
		local nullEntity = getExposedBoneNull(obj, boneName)
		if (not(nullEntity)) then
			logger:error("No bone \""..boneName.."\" null entity was found for delete. (Has it been manually deleted?)")
		else
			if (nullEntity:getNumChildren() > 0) then
				-- TODO: more complex logic that actually re-arranges the hierarchy...
				logger:error("Cannot unexpose bone, because it has a null in hierarchy, and the null has children. Unexpose the child bones first.");
				state:runLuaStringWithDelay("editor.BoneList.handleNextToUnexposeWithMoreDelay()", 1)
				return
			end
			instMan:deleteInstance(nullEntity:getUnifiedHandle())
		end
	end
	local c = getComponentWithBoneName(obj, gameplay.ExposeModelBoneComponent, boneName)
	instMan:deleteInstance(c:getUnifiedHandle())
	
	state:runLuaStringWithDelay("editor.BoneList.handleNextToUnexposeWithMoreDelay()", 100)
	return
end


function unanimateObjectBone(obj, boneName)
	-- only entities supported atm, could add support for some kind of type tweaking as well.
	assert_entity(obj) 
	assert_string(boneName)
	
	if (not isBoneAnimated(obj, boneName)) then
		logger:error("Bone is not animated!")
		state:runLuaStringWithDelay("editor.BoneList.handleNextToUnanimateWithMoreDelay()", 100)
		return
	end
	
	local instMan = obj:getInstanceManager()
	if (doesAnimatedBoneHaveNull(obj, boneName)) then
		local nullEntity = getAnimatedBoneNull(obj, boneName)
		if (not(nullEntity)) then
			logger:error("No bone \""..boneName.."\" null entity was found for delete. (Has it been manually deleted?)")
		else
			if (nullEntity:getNumChildren() > 0) then
				-- TODO: more complex logic that actually re-arranges the hierarchy...
				logger:error("Cannot unanimated bone, because it has a null in hierarchy, and the null has children. Unanimate the child bones first.");
				state:runLuaStringWithDelay("editor.BoneList.handleNextToUnanimateWithMoreDelay()", 1)
				return
			end
			instMan:deleteInstance(nullEntity:getUnifiedHandle())
		end
	end	
	local c = getComponentWithBoneName(obj, gameplay.AnimateModelBoneComponent, boneName)
	instMan:deleteInstance(c:getUnifiedHandle())
	
	state:runLuaStringWithDelay("editor.BoneList.handleNextToUnanimateWithMoreDelay()", 100)
	return
end


function startVisualizingExposedBones(editorId)
	-- TODO: actually consider the entity being selected
	rendering.EditableScriptingEntityVisualizerComponent.startVisualizingExposedBones()
end


function stopVisualizingExposedBones(editorId)
	-- TODO: actually consider the entity being selected
	rendering.EditableScriptingEntityVisualizerComponent.stopVisualizingExposedBones()
end


function hasDuplicateBoneComponents(obj, boneName)
	-- multiple animate components for the bone
	local iter = obj:findAllComponents(gameplay.AnimateModelBoneComponent);
	local count = 0
	local c = iter:next()
	while c do
		if c:getBoneName() == boneName then
			count = count + 1
		end
		c = iter:next()
	end
	if (count > 1) then
		return true
	end

	-- multiple expose components for the bone
	local iter = obj:findAllComponents(gameplay.ExposeModelBoneComponent);
	local count = 0
	local c = iter:next()
	while c do
		if c:getBoneName() == boneName then
			count = count + 1
		end
		c = iter:next()
	end	
	if (count > 1) then
		return true
	end
	
	return false
end


function getObjectForEditorId(editorId)
	assert_string(editorId)

	-- we apparently get a plain guid string here instead of editorId
	--local obj = editor.ExternalUI.getObjectByEditorObjectId(editorId);
	
	local guidStr = editorId;
	local guid = editor.ExternalUI.parseObjectFromStringValue(guidStr);
	local obj = nil
	if (guid) then
		obj = editor.ExternalUI.getObjectByGUID(guid);
	else
		logger:error("queryObjectBoneList - Guid string to guid object parsing failed.");
		return nil;
	end
	
	return obj
end


function queryObjectBoneList(editorId)
	assert_string(editorId)
	
	local obj = getObjectForEditorId(editorId)
	
	if obj == nil then
		logger:error("Failed to query for object bone list, no object with given id " .. editorId)
		return
	end
	
	local hasBones = false
	local modelComp = obj:findComponent(rendering.ModelComponent)
	if (modelComp) then
		if (modelComp:hasBones()) then
			hasBones = true
		end
	end
	
	if (not hasBones) then
		logger:error("Object has no bones when querying the bone list.")
		return
	end

	local escapedId = editor.Util.escapeQuotesAndBackslashes(editorId);
	
	local boneList = ""
	local numBones = modelComp:getNumBones();
	for i = 0,numBones-1 do
		local boneName = modelComp:getBoneNameByIndex(i);
		local additionalInfo = "";
		
		-- dig out additional info...
		if hasDuplicateBoneComponents(obj, boneName) then
			additionalInfo = additionalInfo .. "UNSUPPORTED (Misconfigured / manually edited?),"
		else
			local hasBoneAnimate = isBoneAnimated(obj, boneName)
			local hasBoneExpose = isBoneExposed(obj, boneName)
			if (hasBoneAnimate) then
				additionalInfo = additionalInfo .. "Animated,"
				if (not doesAnimatedBoneHaveNull(obj, boneName)) then
					additionalInfo = additionalInfo .. "NoAnimatedNull,"
				end
			end
			if (hasBoneExpose) then
				additionalInfo = additionalInfo .. "Exposed,"
				if (not doesExposedBoneHaveNull(obj, boneName)) then
					additionalInfo = additionalInfo .. "NoExposedNull,"
				end
			end
		end
		
		if (i > 0) then
			boneList = boneList .. ","
		end
		boneList = boneList .. "\""..boneName.."\",\""..additionalInfo.."\"";
	end
	
	externalUI:sendUICommand("resultObjectBoneList(\""..editorId.."\", "..boneList..")")
end



-- helper function to process the delayed creation of bones in order
function handleNextToExpose()
	if (#boneExposeCreationList == 0) then
		-- all done. refresh the view.
		queryObjectBoneList(exposeEditorId)
		return
	end
	
	-- process the next in queue...
	local e = table.remove(boneExposeCreationList, 1)
	local obj = gameScene:getSceneInstanceManager():getInstanceByUH(e.objUH)
	if (obj) then
		exposeObjectBone(obj, e.boneName, e.params)
	else
		logger:error("The owner object for the bone \""..e.boneName.."\" to expose no-longer exists?");
		state:runLuaStringWithDelay("editor.BoneList.handleNextToExpose()", 1)
	end
end

-- helper function to process the delayed creation of bones in order
function handleNextToAnimate()
	if (#boneAnimateCreationList == 0) then
		-- all done. refresh the view.
		queryObjectBoneList(animateEditorId)
		return
	end
	
	-- process the next in queue...
	local e = table.remove(boneAnimateCreationList, 1)
	local obj = gameScene:getSceneInstanceManager():getInstanceByUH(e.objUH)
	if (obj) then
		animateObjectBone(obj, e.boneName, e.params)
	else
		logger:error("The owner object for the bone \""..e.boneName.."\" to animate no-longer exists?");
		state:runLuaStringWithDelay("editor.BoneList.handleNextToAnimate()", 1)
	end
end


-- helper function to process the delayed creation of bones in order
function handleNextToUnexposeWithMoreDelay()
	-- TODO: would really need a delete callback to be able to do this safely (but such does not exist?)
	state:runLuaStringWithDelay("editor.BoneList.handleNextToUnexpose()", 1)
end
function handleNextToUnexpose()
	if (#boneUnexposeCreationList == 0) then
		-- all done. refresh the view.
		-- FIXME: this is bugged, so the refresh is done with a small delay, to reduce some bugginess
		state:runLuaStringWithDelay("editor.BoneList.queryObjectBoneList(editor.BoneList.unexposeEditorId)", 500)
		return
	end
	
	-- process the next in queue...
	local e = table.remove(boneUnexposeCreationList, 1)
	local obj = gameScene:getSceneInstanceManager():getInstanceByUH(e.objUH)
	if (obj) then
		unexposeObjectBone(obj, e.boneName)
	else
		logger:error("The owner object for the bone \""..e.boneName.."\" to unexpose no-longer exists?");
		state:runLuaStringWithDelay("editor.BoneList.handleNextToUnexpose()", 1)
	end
end

-- helper function to process the delayed creation of bones in order
function handleNextToUnanimateWithMoreDelay()
	-- TODO: would really need a delete callback to be able to do this safely (but such does not exist?)
	state:runLuaStringWithDelay("editor.BoneList.handleNextToUnanimate()", 1)
end
function handleNextToUnanimate()
	if (#boneUnanimateCreationList == 0) then
		-- all done. refresh the view. 
		-- FIXME: this is bugged, so the refresh is done with a small delay, to reduce some bugginess
		state:runLuaStringWithDelay("editor.BoneList.queryObjectBoneList(editor.BoneList.unanimateEditorId)", 500)
		return
	end
	
	-- process the next in queue...
	local e = table.remove(boneUnanimateCreationList, 1)
	local obj = gameScene:getSceneInstanceManager():getInstanceByUH(e.objUH)
	if (obj) then
		unanimateObjectBone(obj, e.boneName)
	else
		logger:error("The owner object for the bone \""..e.boneName.."\" to unanimate no-longer exists?");
		state:runLuaStringWithDelay("editor.BoneList.handleNextToUnanimate()", 1)
	end
end


-- known params are:
--   params.createNull
--   params.createHierarchy
--   params.createVisualization
--   params.namedVisualization
--   params.activeInEditor
--   params.nullsUnderEntityAsChildren

function unexposeBones(editorId, bones, params)
	assert_string(editorId)
	assert_table(bones)

	unexposeEditorId = editorId
	
	local obj = getObjectForEditorId(editorId)	
	-- notice the children first order here
	for i = #bones, 1, -1 do
		local boneName = bones[i]
		if (isBoneExposed(obj, boneName)) then
			table.insert(boneUnexposeCreationList, { objUH=obj:getUnifiedHandle(), boneName=boneName })
		end
	end

	handleNextToUnexpose()
end

function exposeBones(editorId, bones, params)
	assert_string(editorId)
	assert_table(bones)

	exposeEditorId = editorId
	
	-- NOTE: the bone list given here is assumed to be in hierarchial order (parents always before their children)
	boneExposeCreationList = { }
	local obj = getObjectForEditorId(editorId)	
	for i = 1, #bones do
		local boneName = bones[i]
		if (not isBoneExposed(obj, boneName)) then
			table.insert(boneExposeCreationList, { objUH=obj:getUnifiedHandle(), boneName=boneName, params=params })
		end
	end
	
	handleNextToExpose()
end


function unanimateBones(editorId, bones, params)
	assert_string(editorId)
	assert_table(bones)

	unanimateEditorId = editorId
	
	local obj = getObjectForEditorId(editorId)	
	-- notice the children first order here
	for i = #bones, 1, -1 do
		local boneName = bones[i]
		if (isBoneAnimated(obj, boneName)) then	
			table.insert(boneUnanimateCreationList, { objUH=obj:getUnifiedHandle(), boneName=boneName })
		end
	end

	handleNextToUnanimate()	
end


-- (see exposeBones for the possible params)

function animateBones(editorId, bones, params)
	assert_string(editorId)
	assert_table(bones)
	
	animateEditorId = editorId

	-- NOTE: the bone list given here is assumed to be in hierarchial order (parents always before their children)		
	boneAnimateCreationList = { }
	local obj = getObjectForEditorId(editorId)	
	for i = 1, #bones do
		local boneName = bones[i]
		if (not isBoneAnimated(obj, boneName)) then
			table.insert(boneAnimateCreationList, { objUH=obj:getUnifiedHandle(), boneName=boneName, params=params })
		end
	end
	
	handleNextToAnimate()	
end
