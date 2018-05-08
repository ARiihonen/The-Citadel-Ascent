module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

require "editor.ExternalUI"


-- Util functions

-- callEditorCallback(4, "hei", "hoi")
function callEditorCallback(id, ...)
	local parameters = "\"" .. tostring(id) .. "\""

    for i,v in ipairs(arg) do
    	parameters = parameters .. ", \"" .. tostring(v) .. "\""
    end

    externalUI:sendUICommand("typeManagerCallbackFromLua(".. parameters ..")")
end

local separatorString = "%#$" --I hope this string is not found from type names.
function typeToInfoString(type)
	if type ~= nil then
		return tostring(type:getGuid()) .. 
			separatorString .. type:getName() .. 
			separatorString .. tostring(type:isStaticType()) .. 
			separatorString .. type:getNumObjectReferences() .. 
			separatorString .. type:getNumChildren() ..
			separatorString .. getNumberOfDescendantsOfType(type) ..
			separatorString .. getNumberOfDescendantReferencesOfType(type)
	end
	return "GUID_NONE"
end

function getNumberOfDescendantsOfType(type)
	local numChildren = type:getNumChildren()
	local descendants = numChildren

	for i = 0, numChildren-1 do
		local child = type:getChild(i)
		descendants = descendants + getNumberOfDescendantsOfType(child)
	end
	return descendants
end

function getNumberOfDescendantReferencesOfType(type)
	local numChildren = type:getNumChildren()
	local descendantReferences = 0

	for i = 0, numChildren-1 do
		local child = type:getChild(i)
		descendantReferences = descendantReferences + child:getNumObjectReferences() + getNumberOfDescendantReferencesOfType(child)
	end
	return descendantReferences
end


-- C# TypeManagerWrapper functions

function getTypeByName(id, typeName)
	local type = typeManager:findTypeByName(typeName)
	callEditorCallback(id, typeToInfoString(type))
end

function getTypeByGUID(id, typeGUID)
	local guid = editor.ExternalUI.parseObjectFromStringValue(guidStr)
	local type = typeManager:findTypeByGUID(guid)
	callEditorCallback(id, typeToInfoString(type))
end

function getTypeByGuidId(id, guidId)
	local type = editor.ExternalUI.getObjectByEditorObjectId(guidId)
	callEditorCallback(id, typeToInfoString(type))
end

function copyTypeValidation(id, guidStr, newTypeName)
	local guid = editor.ExternalUI.parseObjectFromStringValue(guidStr)
	local origType = typeManager:findTypeByGUID(guid)
	if origType:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) then
		if origType:isStaticType() then
			editor.ExternalUI.editorMessageBox("Cannot copy static type.", "Error copying type", "Error")
			callEditorCallback(id, "failure", "")
			return
		end
		local originalTypeName = origType:getName()
		local suggestedCopyTypeName = newTypeName
		local copyCount = 0
		while typeManager:findTypeByName(suggestedCopyTypeName) do
			copyCount = copyCount + 1
			suggestedCopyTypeName = newTypeName .. copyCount
		end
		callEditorCallback(id, "success", suggestedCopyTypeName)
		return
	else
		logger:error("type_manager_wrapper:copyTypeValidation - Failed to copy type. Type don't seem to be type at all.")
	end
	callEditorCallback(id, "failure", "")
end

function copyTypeExecution(id, guidStr, newTypeName)
	local guid = editor.ExternalUI.parseObjectFromStringValue(guidStr)
	local origType = typeManager:findTypeByGUID(guid)
	if origType == nil then
		editor.ExternalUI.editorMessageBox("TypeManagerWrapper:copyTypeExecution - invalid type", "Error copying type", "Error")
		return
	end

	local originalTypeName = origType:getName()

	assert_string(originalTypeName)
	assert_string(newTypeName)
	
	local origType = typeManager:findTypeByName(originalTypeName)
	local newType = typeManager:findTypeByName(newTypeName)
	if not origType then
		logger:error("type_manager_wrapper:copyTypeExecution - Original Type not found with given name.")
		return
	end
	if newType then
		editor.ExternalUI.editorMessageBox("Type with given name \"".. newTypeName .."\" already exists.", "Error copying type", "Error")
		return
	end
	local resultType = typeManager:copyType(newTypeName, originalTypeName)
	logger:debug("type_manager_wrapper:copyTypeExecution - Copied type \""..originalTypeName.."\" to \""..newTypeName.."\".")

	callEditorCallback(id, typeToInfoString(origType), typeToInfoString(resultType))
end