module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

local thisModule = _M

-- NOTE: This file is dumbed down and modified version of "bone_list.lua"

declareReload(thisModule, [[boneRagdollCreationList]])
declareReload(thisModule, [[ragdollEditorId]])
declareReload(thisModule, [[boneNameList]])
boneRagdollCreationList = { }
boneNameList = { }
ragdollEditorId = ""

function getObjectForEditorId(editorId)
	assert_string(editorId)

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
		if (i > 0) then
			boneList = boneList .. ","
		end
		boneList = boneList .. "\""..boneName.."\",\""..additionalInfo.."\"";
	end
	
	externalUI:sendUICommand("returnRagdollObjectBoneList(\""..editorId.."\", "..boneList..")")
end

function createRagdollPrefab(editorId, bones)
	assert_string(editorId)
	assert_table(bones)
	
	ragdollEditorId = editorId

	-- NOTE: The bone list given here is assumed to be in hierarchial order (parents always before their children)		
	boneRagdollCreationList = { }
	boneNameList = { }
	local obj = getObjectForEditorId(editorId)	
	for i = 1, #bones do
		local boneName = bones[i]
		table.insert(boneRagdollCreationList, { objUH=obj:getUnifiedHandle(), boneName=boneName })
		table.insert(boneNameList, boneName)
	end
	
	handleNextBone()	
end

function handleNextBone()
	if (#boneRagdollCreationList == 0) then
		-- NOTE: All done, delete contents of bonenamelist and create prefab
		while (#boneNameList > 0) do
			table.remove(boneNameList, 1)
		end
		externalUI:sendUICommand("createRagdollPrefabType()")
		return
	end
	
	local e = table.remove(boneRagdollCreationList, 1)
	local obj = gameScene:getSceneInstanceManager():getInstanceByUH(e.objUH)
	if (obj) then
		createRagdollBoneObject(obj, e.boneName)
	else
		logger:error("The owner object for the bone \""..e.boneName.."\" no-longer exists?");
		state:runLuaStringWithDelay("editor.BoneList.handleNextBone()", 1)
	end
end

function createRagdollBoneObject(obj, boneName)
	assert_instance(obj)
	assert_string(boneName)
	
	local ownerModelComp = obj:findComponent(rendering.ModelComponent)
	if (ownerModelComp == nil) then 
		return 
	end
	
	local parentBoneName = findRealParentNameRecursively(ownerModelComp, boneName)
	local boneDimensions = VC3(0,0,0)
	local currentBoneLength = 0.5
	boneDimensions.x = currentBoneLength
	boneDimensions.y = 0.5
	boneDimensions.z = boneDimensions.y
	
	local currentBonePosition = ownerModelComp:getRealBonePosition(boneName, VC3(0,0,0))
	local currentBoneRotation = ownerModelComp:getBoneRotation(boneName)
	
	local helperType = typeManager:findTypeByName("EditableRagdollBoneHelperEntity");
	if (helperType ~= nil) then
		local instCreateParams = { parentObj=obj, boneName=boneName, parentBoneName=parentBoneName, position=currentBonePosition, rotation=currentBoneRotation, boneDimensions=boneDimensions }
		gameScene:getSceneInstanceManager():createNewInstance(helperType:getUnifiedHandle(), createdHelperForRagdollBone, instCreateParams);
	end
end

function findRealParentNameRecursively(ownerModelComp, boneName)
	if (ownerModelComp == nil) then
		return ""
	end

	local parentBoneName = ownerModelComp:getParentBoneNameSilent(boneName)
	if (parentBoneName == "") then
		return parentBoneName
	end
	
	-- NOTE: Try to find if parent is within selection, if not then continue to go through parent bones
	for i = 1, #boneNameList do
		if (parentBoneName == boneNameList[i]) then
			return parentBoneName
		end
	end
	
	return findRealParentNameRecursively(ownerModelComp, parentBoneName)
end

function createdHelperForRagdollBone(obj, params)
	assert_instance(obj)
	assert_table(params)
	
	-- NOTE: Create the helpers to currently active layer
	local layer = state:getSelectedLayer()
	obj:setLayer(layer)
	
	local comp = obj:findComponent(physics.EditableRagdollBoneHelperComponent)
	local areaComp = obj:findComponent(area.BoxAreaComponent) --engine.component.AbstractAreaComponent)
	local transformComp = obj:findComponent(engine.component.TransformComponent)
	assert_component(comp)
	assert_component(areaComp)
	assert_component(transformComp)

	local parentObj = params.parentObj
	local parentTransformComp = parentObj:findComponent(engine.component.TransformComponent)
	assert_component(parentTransformComp)
	
	local parentObjPosition = parentTransformComp:getPosition()
	local boneName = params.boneName
	local parentBoneName = params.parentBoneName
	local initialPosition = params.position
	local initialRotation = params.rotation
	local boneDimensions = params.boneDimensions
	
	assert_instance(parentObj)
	assert_string(boneName)
	assert_string(parentBoneName)

	comp:setBoneName(boneName)
	comp:setParentBoneName(parentBoneName)
	comp:setShapeDimensions(boneDimensions)
	areaComp:setDimensions(boneDimensions)
	
	transformComp:setPosition(initialPosition)
	transformComp:setRotation(initialRotation)
	
	if (parentBoneName ~= "") then
		parentObj = findCorrectParentRecursively(parentObj, parentBoneName)
		if parentObj == nil then 
			parentObj = params.parentObj 
		end
	end
	editor.ExternalUI.parentObject(obj:getGuid(), parentObj:getGuid())
	if not obj:isStarted() then
		obj:start();
	end
	handleNextBone()
end

function findCorrectParentRecursively(obj, boneName)
	assert_instance(obj)
	assert_string(boneName)

	local comp = obj:findComponent(physics.EditableRagdollBoneHelperComponent)
	if comp ~= nil then
		if comp:getBoneName() == boneName then
			return comp:getFinalOwner()
		end
	end
	
	local retObj = obj;
	local numChildren = obj:getNumChildren() - 1
	for i = 0, numChildren do
		local child = obj:getChild(i)
		if child ~= nil then
			retObj = findCorrectParentRecursively(child, boneName)
			if retObj ~= nil then
				return retObj
			end
		end
	end
	
	return nil
end

function deleteChildrenWithHelper(editorId)
	local obj = getObjectForEditorId(editorId)
	if obj == nil then
		return
	end
	
	local instance = gameScene:getSceneInstanceManager():getInstanceByUH(obj:getUnifiedHandle())
	if instance == nil then
		return
	end

	-- FIXME: Rather hacky way to delete the created bonehelper instances from the model instance. Deleting "main" childs, deletes that one's childs as well. Anyways, fix at some point.
	for i = 0, instance:getNumChildren() - 1 do
		local child = instance:getChild(i)
		if child ~= nil then
			if child:findComponent(physics.EditableRagdollBoneHelperComponent) ~= nil then
				gameScene:getSceneInstanceManager():deleteInstance(child:getUnifiedHandle())
				i = i-1
			end
		end
	end
end
