module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

require "debug.Assert"
require "debug.AutoReloadable"
require "editor.Util"

local thisModule = _M

local printDebugStuff = true

local function debugPrint(msg, funcName)
	logger:debug(_NAME .. ".debugPrint: Swapping debug print function")
	if printDebugStuff then
		enableDebug()
	else
		debugPrint = function(msg, funcName)
			-- nop
		end
	end

	debugPrint(msg, funcName)
end


function enableDebug()
	debugPrint = function(msg, funcName)
		funcName = funcName or "[N/A]"
		logger:debug(_NAME .. "." .. funcName .. ": " .. msg)
	end
end


local function logError(msg, funcName)
	funcName = funcName or "[N/A]"
	logger:error(_NAME .. "." .. funcName .. ": " .. msg)
end


local function logInfo(msg, funcName)
	funcName = funcName or "[N/A]"
	logger:info(_NAME .. "." .. funcName .. ": " .. msg)
end


-- This doesn't work. Need to consult Oskari
function checkAndFixParticleSystemTemplateTypes()
	local funcName = "checkAndFixParticleSystemTemplateTypes"

	local function checkAndFixGravityForce(typeName, expectedDirection)
		local typeObj = typeManager:findTypeByName(typeName)
		if not typeObj then
			logError("Could not find " .. typeName, funcName)
			return false
		end
		local propIndex = typeObj:findPropertyIndexByName("GravityForce")
		if propIndex ~= -1 then
			if typeObj:getPropertyValue(propIndex) ~= expectedDirection then
				logInfo("Fixing GravityForce direction for " .. typeName .. " (" .. tostring(typeObj:getPropertyValue(propIndex)) .. " => " .. tostring(expectedDirection) .. ")", funcName)
				typeObj:setPropertyValue(propIndex, expectedDirection)
				return true
			end
		else
			logError("Could not find GravityForce property from " .. typeName, funcName)
		end
		return false
	end

	local somethingFixed = false
	somethingFixed = checkAndFixGravityForce("TemplateUpwardLiftParticleForceComponent", engine.base.mathbase.GameDirections.sceneUpDirection * 9.81) or somethingFixed
	somethingFixed = checkAndFixGravityForce("TemplateDownwardGravityParticleForceComponent", engine.base.mathbase.GameDirections.sceneUpDirection * -9.81) or somethingFixed
	somethingFixed = checkAndFixGravityForce("TemplateForwardForceParticleForceComponent", engine.base.mathbase.GameDirections.entityForwardDirection * 9.81) or somethingFixed
	somethingFixed = checkAndFixGravityForce("TemplateBackwardForceParticleForceComponent", engine.base.mathbase.GameDirections.entityForwardDirection * -9.81) or somethingFixed

	if somethingFixed then
		logInfo("Something was fixed", funcName)
	else
		logInfo("Nothing to fix", funcName)
	end
end


-- locate a particle system, effect or component type (with the given type name)
-- selects the type so that its properties are shown in the properties window
-- should better be called "locateAndSelectTypeByName"
-- NOTICE: this is buggy if the object is being selected in the external particle editor plugin process 
-- (probably due to some optimization hack so that the object properties window does not update itself unless the editor has focus?)
function locateTypeByName(pluginName, typeName)
	local typeObj = typeManager:findTypeByName(typeName)
	if typeObj then
		local guid = typeObj:getGuid()
		editor.ExternalUI.locateGUID(guid, false, nil, true) --Particle editor locates always without focus.
		local tmpTable = { }
		editor.Editor.dumpBranchHeader(tmpTable, typeObj, false, 1)
		local editorId = tmpTable[1]
		editor.ExternalUI.selectTypes({ })
		editor.ExternalUI.listenToObjectPropertyChanges({ editorId })
		editor.ExternalUI.selectTypes({ editorId })
	end
end

function locateParticleCollectionTypeByName(pluginName, typeName)
	local typeObj = typeManager:findTypeByName(typeName)
	if typeObj then
		local iter = TypeComponentIterator(typeObj)
		local childCompTypeUH = iter:next()
		while not(childCompTypeUH == nil) do
			local childCompType = typeManager:getTypeByUH(childCompTypeUH)
			if childCompType:doesInheritTypeByName("ParticleEffectCollectionComponent") then
			
				local guid = childCompType:getGuid()
				editor.ExternalUI.locateGUID(guid, false, nil, true) --Particle editor locates always without focus.
				local tmpTable = { }
				editor.Editor.dumpBranchHeader(tmpTable, childCompType, false, 1)
				local editorId = tmpTable[1]
				editor.ExternalUI.selectTypes({ })
				editor.ExternalUI.listenToObjectPropertyChanges({ editorId })
				editor.ExternalUI.selectTypes({ editorId })

			end
				
			childCompTypeUH = iter:next()
		end

	end
end

function setEffectTypeVisibility(pluginName, paramsString)
	local splitted = split_compat(paramsString, ",")
	local typeName = splitted[1]
	local visible = splitted[2] == "True";
	local typeObj = typeManager:findTypeByName(typeName)
	if typeObj then

		-- find render components
		for j = 0, typeObj:getNumComponentTypes() - 1 do
			local typeChildCompUH = typeObj:getComponentType(j)
			local typeChildComp = typeManager:getTypeByUH(typeChildCompUH)
			if(typeChildComp:doesInheritTypeByName("ParticleRenderComponent")) then
				local guid = typeChildComp:getGuid()

				-- toggle visibility in all scenes
				local numParticleScenes = particleModule:getNumScenes()
				for i=1,numParticleScenes do
					local s = particleModule:getScene(i - 1)
					s:setRendererTypeTemporaryVisibility(guid, visible)
				end

			end
		end
	end
end

function preprocessChangedEffects() 
	-- TODO: check that this does process changed only?
	-- TODO: also, it would be nice to process with without the title, but only if it is really fast enough!
	app:processParticleResourcesWithTitle("Processing changed particle effects")
end

function forcePreprocessAllEffects() 
	-- TODO: set some flag / call some function that says that _ALL_ effects must be processed (cleaned first)
	-- or add another call which does that
	logger:error("forcePreprocessAllEffects - TODO")
	app:processParticleResourcesWithTitle("Processing all particle effects")
end


-- this typeName may be the particle system entity type, or any of the particle component types, etc. referred by the effect
function preprocessSingleEffect(typeName) 
	assert_string(typeName)
	
	local entityType = typeManager:findTypeByName(typeName)
	if entityType ~= nil then
		-- TODO: solve the matching particle system for this individual effect/component/...
		local particleSystemTypeName = typeName
		
		-- NOTE: current implementation assumes the app will dig out the types
		-- TODO: Should really preferrably dig them out here, and pass a list of individual particle effects to process
		app:processParticleResourceWithoutPopup(particleSystemTypeName)
	else
		-- Current hacky system of recognizing particle systems in editor is so bad and produces so many false 
		-- positives that it makes no sense to error here. It's just business as usual. See FBPropertyGrid.cs for 
		-- details.
		--logger:error("No particle system entity found with given type name \"" .. (typeName or "") .. "\". Thus, cannot pre-process the relevant particle types.")
	end
end


-- param true or false
function setForceAllEffectsActive(forceActive) 
	assert_boolean(forceActive)

	-- TODO: implement this
	-- notice, that this must NOT touch the individual effect AlwaysActive properties or such
	-- what it must do is tell the particle/effect scene that now all of them need to be active
	-- or alternatively, it may set some temporary, non-saved/non-visible runtime property/flag in the entities which forces them to be active (or clear it)
	logger:error("setForceAllEffectsActive")
end

-- param true or false
-- note, if this is set to true, it automatically sets setForceAllEffectsDisabled to false, if it is on
function setForceAllEffectsEnabled(forceEnabled) 
	assert_boolean(forceEnabled)

	-- TODO: implement this
	-- notice, that this must NOT touch the individual effect Enabled properties or such
	-- what it must do is tell the particle/effect scene that now all of them need to be enabled
	-- or alternatively, it may set some temporary, non-saved/non-visible runtime property/flag in the entities which forces them to be enabled (or clear it)
	logger:error("setForceAllEffectsEnabled")
end

-- param true or false
-- note, if this is set to true, it automatically sets setForceAllEffectsEnabled to false, if it is on
function setForceAllEffectsDisabled(forceDisabled) 
	assert_boolean(forceDisabled)
	
	-- TODO: implement this
	-- notice, that this must NOT touch the individual effect Enabled properties or such
	-- what it must do is tell the particle/effect scene that now all of them need to be enabled
	-- or alternatively, it may set some temporary, non-saved/non-visible runtime property/flag in the entities which forces them to be enabled (or clear it)
	logger:error("setForceAllEffectsDisabled")
end

-- param true or false
function setForceAllFluidEffectsDisabled(forceDisabled) 
	assert_boolean(forceDisabled)
	
	-- TODO: implement this
	-- notice, that this must NOT touch the individual effect Enabled properties or such
	-- what it must do is tell the particle/effect scene that now all of them need to be enabled
	-- or alternatively, it may set some temporary, non-saved/non-visible runtime property/flag in the entities which forces them to be enabled (or clear it)
	logger:error("setForceAllFluidEffectsDisabled")
end


function resumeAllEffects() 
	-- resume all paused effect instances (unfreeze them)

	-- NOTE: this might not be safe with particle editing/pre-processing...?
	local numParticleScenes = particleModule:getNumScenes()
	for i=1,numParticleScenes do
		local s = particleModule:getScene(i - 1)
		--s:setParticleUpdateEnabled(true)
		s:setPaused(false)
	end
end

function pauseAllEffects() 
	-- pause all effect instances (freeze them, don't stop/delete them!)
	
	-- NOTE: this might not be safe with particle editing/pre-processing...?
	local numParticleScenes = particleModule:getNumScenes()
	for i=1,numParticleScenes do
		local s = particleModule:getScene(i - 1)
		--s:setParticleUpdateEnabled(false)
		s:setPaused(true)
	end
end


function restartAllEffects() 
	-- restart all effect instances	
	local numParticleScenes = particleModule:getNumScenes()
	for i=1,numParticleScenes do
		local s = particleModule:getScene(i - 1)
		s:restartAllEffects()
	end
end

function stringEndsWith(str, substr)
	assert_string(str)
	assert_string(substr)
	if (#str >= #substr) then
		-- TODO: optimize, very inefficient logic
		if string.sub(str, 0 - #substr) == substr then
			return true
		end
	end
	return false
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


-- deletes an entire particle system 
function deleteParticleSystem(pluginName, effectTypeName)
	assert_string(effectTypeName)
	
	-- don't allow deleting the templates!
	if (stringStartsWith(effectTypeName, "Template")) then
		logger:error("Sanity check failed. Attempt to delete a template particle effect. Preventing the operation.")
		return
	end
	
	-- sanity check to prevent a total disaster...
	if (stringEndsWith(effectTypeName, "ParticleSystemEntity")) then
		local numTypesDeleted = editor.ExternalUI.deepDeleteType(effectTypeName, true, { "Particle", "Effect" })
		logger:info("A total of " .. tostring(numTypesDeleted) .. " related types were deleted while deleting the particle system \"" .. effectTypeName .. "\".")
	else
		-- don't allow use of this for anything but the automatically created particle effect types (as this could cause potentially massive type destruction when done on anything else)
		logger:error("Sanity check failed. Attempt to delete a particle system entity, that does not seem like a particle system entity. Preventing the operation to prevent a possible disaster.")
	end	
end


local function sendToPlugin(pluginName, params)
	if not pluginName then pluginName = "particleComponents" end
	local function quoteString(string)
		return "\"" .. string .. "\""
	end

	local cmd = "sendToPlugin(" .. quoteString(pluginName)
	for i, param in ipairs(params) do
		cmd = cmd .. ", " .. quoteString(param)
	end
	cmd = cmd .. ")"
	externalUI:sendUICommand(cmd)
end


-- called by the categorizer particle effect creation
-- NOTE: this is a particle SYSTEM creation (legacy naming issue here)
-- param must be in format "categoryWindowInstanceId,typeNameToDuplicateWithPostfix,newEffectNameWithoutPostifix"
function duplicateCategorizedEffect(pluginName, paramsString)
	assert_string(paramsString)

	logger:debug("At duplicate categorized effect " .. paramsString)
	
	local splitted = split_compat(paramsString, ",")
	local windowInstanceId = splitted[1]
	local typeName = splitted[2]
	local newEffectName = splitted[3]
	assert_string(windowInstanceId)
	assert_string(typeName)
	assert_string(newEffectName)

	duplicateEffect(typeName, newEffectName);
	
	local createdType = typeManager:findTypeByName(newEffectName .. "ParticleSystemEntity")
	if (createdType == nil)  then
		logger:error("Duplication failed, no particle system entity type exists with the new type name.")
	end
	local tmpTable = { }
	editor.Editor.dumpBranchHeader(tmpTable, createdType, false, 1)
	local createdEditorId = tmpTable[1]
	
	-- make it non-abstract so they can be placed in the scene (in case it was duplicated from a template that are abstract)
	createdType:setAbstractType(false)
	createdType:setGameAbstractType(false)
	sendToPlugin(pluginName, { "editor.ParticleSystems.duplicateCategorizedEffect", windowInstanceId .. "<-SEP->" .. createdEditorId } )
	-- externalUI:sendUICommand("sendToPlugin(\"ParticleSystems\", \"editor.ParticleSystems.duplicateCategorizedEffect\", \""..windowInstanceId.."<-SEP->"..createdEditorId.."\")")
end


-- Used by copy-paste. Duplicates one effect type from particle system to another.
-- Assumes that there is only one collectionComponent and collectionType.
function duplicateSingleEffectType(pluginName, paramsString)
	assert_string(paramsString)

	logger:debug("At duplicate single effect type " .. paramsString)
	
	local splitted = split_compat(paramsString, ",")
	local effectTypeName = splitted[1] -- Full particle effect type name
	local oldParticleSystemTypeName = splitted[2] -- Full particle system type name
	local newParticleSystemTypeName = splitted[3] -- Full particle system type name
	assert_string(effectTypeName)
	assert_string(oldParticleSystemTypeName)
	assert_string(newParticleSystemTypeName)
	
	
	-- Check if parameter types are valid and find prefixes
	
	-- Do the types exist?
	local effectType = typeManager:findTypeByName(effectTypeName)
	local oldSystemType = typeManager:findTypeByName(oldParticleSystemTypeName)
	local newSystemType = typeManager:findTypeByName(newParticleSystemTypeName)
	
	if (effectType == nil) then
		local msg = effectTypeName .. " not found"
		logger:error(msg)
		sendToPlugin(pluginName, { "editor.ParticleSystems.duplicateSingleEffectType", msg} )
		return
	elseif (oldSystemType == nil) then
		local msg = oldParticleSystemTypeName .. " not found"
		logger:error(msg)
		sendToPlugin(pluginName, { "editor.ParticleSystems.duplicateSingleEffectType", msg} )
		return
	elseif (newSystemType == nil) then
		local msg = newParticleSystemTypeName .. " not found"
		logger:error(msg)
		sendToPlugin(pluginName, { "editor.ParticleSystems.duplicateSingleEffectType", msg} )
		return
	end
	
	local particleSystemPostfix = "ParticleSystemEntity"
	local particleEffectPostfix = "ParticleEffectType"
	
	-- Is the naming correct?
	if (not stringEndsWith(oldParticleSystemTypeName, particleSystemPostfix) or 
		not stringEndsWith(newParticleSystemTypeName, particleSystemPostfix)) then
		local msg = "Atleast one of the particle systems is missing postfix " .. particleSystemPostfix .. ": " .. oldParticleSystemTypeName .. ", " .. newParticleSystemTypeName
		logger:error(msg)
		sendToPlugin(pluginName, { "editor.ParticleSystems.duplicateSingleEffectType", msg} )
		return
	end
	
	local oldParticleSystemPrefix = string.sub(oldParticleSystemTypeName, 1, #oldParticleSystemTypeName - #particleSystemPostfix)
	
	local newParticleSystemPrefix = string.sub(newParticleSystemTypeName, 1, #newParticleSystemTypeName - #particleSystemPostfix)
	
	if (not stringStartsWith(effectTypeName, oldParticleSystemPrefix) or 
		not stringEndsWith(effectTypeName, particleEffectPostfix)) then
		logger:error("Particle effect name doesn't follow the structure: <particleSystemName><effectName>" .. particleEffectPostfix)
	end
	
	-- The nick name part of type name
	local particleEffectName = string.sub(effectTypeName, #oldParticleSystemPrefix + 1, #effectTypeName - #particleEffectPostfix)
	
	-- If particle effect with the same name exists, add number to the end
	local oldParticleEffectName = particleEffectName
	local newEffectTypeName = ""
	local safetyCounter = 100
	while safetyCounter > 0 do
		safetyCounter = safetyCounter - 1
		newEffectTypeName = newParticleSystemPrefix .. particleEffectName .. particleEffectPostfix
		if (typeManager:findTypeByName(newEffectTypeName) == nil) then
			break
		end
		local endNumber = tonumber(string.match(particleEffectName, "%d+$"))
		if (endNumber == nil) then
			particleEffectName = particleEffectName .. "2"
		else
			local numLen = string.len(tostring(endNumber))
			particleEffectName = string.sub(particleEffectName, 1, #particleEffectName - numLen) .. tostring(endNumber+1)
		end
	end
	
	-- Do the real stuff. Create components and types
	editor.ExternalUI.deepCopyType(effectTypeName, oldParticleSystemPrefix .. oldParticleEffectName, newParticleSystemPrefix .. particleEffectName, true, true)
	
	-- Check if the type was created
	local newEffectType = typeManager:findTypeByName(newEffectTypeName)
	if (newEffectType == nil) then
		local msg = "Unable to find duplicated type " .. newEffectTypeName
		logger:error(msg)
		sendToPlugin(pluginName, { "editor.ParticleSystems.duplicateSingleEffectType", msg} )
		return
	end
	
	local collectionComponent = nil;
	local collectionComponentPostfix = "EffectCollectionComponent"

	-- Find collection component of the new particle system
	for cidx = 0, newSystemType:getNumComponentTypes() - 1 do
		local typeChildCompUH = newSystemType:getComponentType(cidx)
		local typeChildComp = typeManager:getTypeByUH(typeChildCompUH)
		local typeChildCompName = typeChildComp:getName()
		if (stringEndsWith(typeChildCompName, collectionComponentPostfix)) then
			collectionComponent = typeChildComp
			break
		end
	end
	
	if (collectionComponent == nil) then
		local msg = "Couldn't find " .. EffectCollectionComponent .. " from " .. newEffectTypeName
		logger:error(msg)
		sendToPlugin(pluginName, { "editor.ParticleSystems.duplicateSingleEffectType", msg} )
		return
	end
	
	local collectionTypePostfix = "CollectionType"
	local collectionType = nil;
	
	-- Find collection type of the new particle system
	for propIdx = 0, collectionComponent:getNumProperties() - 1 do
		local propName = collectionComponent:getPropertyName(propIdx)
		if (propName == "DefaultEffectType") then
			local propValue = collectionComponent:getPropertyValue(propIdx)
			if (propValue ~= UH_NONE) then
				collectionType = typeManager:getTypeByUH(propValue)
				break;
			end
		end
	end
	
	if (collectionType == nil) then
		local msg = "Couldn't find DefaultEffectType from " .. collectionComponent:getName()
		logger:error(msg)
		sendToPlugin(pluginName, { "editor.ParticleSystems.duplicateSingleEffectType", msg} )
		return
	end
	
	-- Add the created particle effect to collection type
	local uhPropArray = collectionType:getEffectArray()
	local uhTable = {}
	for arrIdx = 0,uhPropArray:getSize() - 1 do
		local refUH = uhPropArray:get(arrIdx)
		table.insert(uhTable, refUH)
	end
	table.insert(uhTable, newEffectType:getUnifiedHandle())
	local newUHArray = UHPropertyArray(uhTable)
	collectionType:setEffectArray(newUHArray)
	
	-- Send async response
	sendToPlugin(pluginName, { "editor.ParticleSystems.duplicateSingleEffectType", newEffectType:getName()} )
end


-- also used to "createNewEffect" (by simply giving a template effect as parameter)
-- NOTE: this is a particle SYSTEM duplication (legacy naming issue here)
-- notice, the typeName is the full typename (with postfix), whereas the newEffectName is the one without the postfix.
function duplicateEffect(typeName, newEffectName)
	logger:debug("At duplicate effect (" .. typeName .. ") to " .. newEffectName)

	assert_string(typeName)
	assert_string(newEffectName)
	-- using the given type name, duplicate the type (under EffectEntity)
	-- duplicate all components/referred types/types referred by the referred types/etc.
	-- a.k.a. do a deep clone
	local typeObj = typeManager:findTypeByName(typeName)
	if (typeObj == nil) then
		logger:debug("Type \"" .. typeName .. "\" was not found.")
		if (stringStartsWith(typeName, "Template")) then
			editor.ExternalUI.editorMessageBox("No type with the name \""..typeName.."\" was found.\r\nThe requested particle system template type seems to be missing.", "Particle System Duplication/Creation Failed", "Error")		
			return
		else
			editor.ExternalUI.editorMessageBox("No type with the name \""..typeName.."\" was found.\r\nPerhaps the particle system category entry is pointing to a deleted particle effect type?", "Particle System Duplication/Creation Failed", "Error")		
			return
		end
	end
	
	local effectPostfix = "ParticleSystemEntity"
	if (stringEndsWith(typeName, effectPostfix)) then
		local oldPrefix = string.sub(typeName, 1, #typeName - #effectPostfix) -- a.k.a. old effect name (without the entity typename postfix)
		assert_string(oldPrefix)
		local errCodeTable = { }
		local okToCopy = editor.ExternalUI.canDeepCopyType(errCodeTable, typeName, oldPrefix, newEffectName, true, true)
		if (okToCopy) then
			-- do it...
			logger:debug("Going to deep copy particle system entity from (" .. typeName .. ") " .. oldPrefix .. " to " .. newEffectName)
			editor.ExternalUI.deepCopyType(typeName, oldPrefix, newEffectName, true, true)
		else
			logger:debug("Naming convention issue detected for particle system deep copy from (" .. typeName .. ") " .. oldPrefix .. " to " .. newEffectName)
			local okToCopyWithBadNaming = editor.ExternalUI.canDeepCopyType(errCodeTable, typeName, oldPrefix, newEffectName, true, false)
			if okToCopyWithBadNaming then
				logger:debug("User approved (naming convention issue) deep copy particle system entity from (" .. typeName .. ") " .. oldPrefix .. " to " .. newEffectName)
				-- type naming issues, allow the user to skip those if really sure about it...
				editor.ExternalUI.userConfirmBeforeCallingFunction(
					"There is a component or referred type naming convention issue in the particle system being duplicated. This may be caused by some manual modifications done to the type. Duplicating the particle system may not be safe and may result in unexpected or excessive number of types being created. Do you want to ignore the issue and continue anyway?", 
					editor.ExternalUI.deepCopyType, typeName, oldPrefix, newEffectName, true, false
				)
			else
				editor.ExternalUI.editorMessageBox("Particle system creation cannot be done due to the following error.\r\n\r\n" .. errCodeTable.msg, "Particle System Duplication/Creation Failed", "Error")
			end
		end
	else
		-- user trying to duplicate something totally different as a particle system? (or has done the particle system incorrectly manually, and is now trying to duplicate it)
		if (typeObj:doesInheritTypeByName("AbstractParticleSystemEntity")) then
			editor.ExternalUI.editorMessageBox("The particle system \""..typeName.."\" cannot be duplicated because it does not follow the expected particly system entity naming convention.\r\nIf you have created the particle system manually, it is likely that you can only handle it manually (the automated particle system tools cannot successfully handle it).", "Particle System Duplication/Creation Failed", "Error")
		else
			editor.ExternalUI.editorMessageBox("The type \""..typeName.."\" cannot be duplicated because it does not seem to be a particle system type (or it has been manually created).\r\nIf it is a manually created particle system, it is likely that you can only handle it manually (the automated particle system tools cannot successfully handle it).", "Particle System Duplication/Creation Failed", "Error")
		end
	end
end


-- queried by find uncategorized particle effect types
function queryAllExistingParticleEffectTypesForUncategorized(pluginName, dummyStringParam)
	local effs = getAllExistingParticleEffectTypes() 
	sendToPlugin(pluginName, { "ListUncategorizedParticleSystems", "editor.ParticleSystems.queryAllExistingParticleEffectTypesForUncategorized", effs } )
	-- externalUI:sendUICommand("sendToPlugin(\"ListUncategorizedParticleSystems\", \"editor.ParticleSystems.queryAllExistingParticleEffectTypesForUncategorized\", \""..effs.."\")")
end

-- queried by particle effect creation 
function queryAllExistingParticleEffectTypesForCreation(pluginName, dummyStringParam)
	local effs = getAllExistingParticleEffectTypes() 
	sendToPlugin(pluginName, { "CreateParticleSystem", "editor.ParticleSystems.queryAllExistingParticleEffectTypesForCreation", effs } )
	-- externalUI:sendUICommand("sendToPlugin(\"CreateParticleSystem\", \"editor.ParticleSystems.queryAllExistingParticleEffectTypesForCreation\", \""..effs.."\")")
end


-- Now, we have to support Trine 3, which means we need to support Trine 2 legacy effects all around...
function listLegacyEffectsImpl(ret, parentType)
	local numEffs = parentType:getNumChildren()
	for i=1,numEffs do
		local childObj = parentType:getChild(i - 1)
		local childName = childObj:getName()
		if (childName ~= "AbstractParticleSystemEntity") then
			local tmpTable = { }
			editor.Editor.dumpBranchHeader(tmpTable, childObj, false, 1)
			local editorId = tmpTable[1]
			if (childObj:getNumChildren() == 0) then
				if (ret ~= "") then
					ret = ret .. "<-PPP->"
				end
				ret = ret .. childName .. "<-EID->" .. editorId
			else
				ret = listLegacyEffectsImpl(ret, childObj)
			end
		end
	end		
	return ret
end


-- returns a string containing particle system type names and editorId strings with <-EID-> string in between them. Multiple entries are separated by <-PPP-> strings.
function getAllExistingParticleEffectTypes() 
	local ret = ""	

	-- see all types under AbstractParticleSystemEntity (even templates, it is the job of the UI to detect "Template..." particle effects)
	local parentType = typeManager:findTypeByName("AbstractParticleSystemEntity")
	if (parentType ~= nil) then
		local numEffs = parentType:getNumChildren()
		for i=1,numEffs do
			local childObj = parentType:getChild(i - 1)
			local childName = childObj:getName()
			if (ret ~= "") then
				ret = ret .. "<-PPP->"
			end
			local tmpTable = { }
			editor.Editor.dumpBranchHeader(tmpTable, childObj, false, 1)
			local editorId = tmpTable[1]
			ret = ret .. childName .. "<-EID->" .. editorId
		end		
	else
		logger:error("The expected AbstractParticleSystemEntity entity type is missing.")
	end
	
	-- legacy effects
	local parentType = typeManager:findTypeByName("EffectEntity")
	if (parentType ~= nil) then
		ret = listLegacyEffectsImpl(ret, parentType)
	else
		logger:error("The expected EffectEntity entity type is missing.")
	end
	
	return ret
end


-- queried by the system components windows
-- sends the list of particle system entities in the particle system entity
function queryParticleSystemEntities(pluginName, particleSystemTypeName)
	local effs = getAllExistingParticleEffectTypes() 
	sendToPlugin(pluginName, { "editor.ParticleSystems.queryParticleSystemEntities", effs } )
	-- externalUI:sendUICommand("sendToPlugin(\"ParticleComponents\", \"editor.ParticleSystems.queryParticleSystemEntities\", \""..effs.."\")")
end


-- queried by particle system components windows
-- sends the list of effects in the particle system entity
-- paramString should be the particle system entity type name (full name with postfix)
function queryParticleSystemEntityEffects(pluginName, particleSystemTypeName)
	local effs = getParticleSystemEffects(particleSystemTypeName)
	sendToPlugin(pluginName, { "editor.ParticleSystems.queryParticleSystemEntityEffects", effs } )
	-- externalUI:sendUICommand("sendToPlugin(\"ParticleComponents\", \"editor.ParticleSystems.queryParticleSystemEntityEffects\", \""..effs.."\")")
end

-- sends the list of components in the particle effect (within a particle system entity)
-- paramString should be the "effect_type_name" (full names with postfix, note, this is the effect collection name, not the entity name!)
function queryParticleSystemEntityEffectComponents(pluginName, effectTypeName)
	local comps  = getParticleEffectComponents(effectTypeName) 
	sendToPlugin(pluginName, { "editor.ParticleSystems.queryParticleSystemEntityEffectComponents", comps } )
	-- externalUI:sendUICommand("sendToPlugin(\"ParticleComponents\", \"editor.ParticleSystems.queryParticleSystemEntityEffectComponents\", \""..comps.."\")")
end


-- NOTE: this does not really rename the effect type in question, but sets the CustomEffectName property value in it.
function renameEffect(pluginName, paramsString)
	local splitted = split_compat(paramsString, ",")
	local effectTypeName = splitted[1]
	local newName = splitted[2]
	
	local typeObj = typeManager:findTypeByName(effectTypeName)
	if (typeObj ~= nil) then
		typeObj:setCustomEffectName(newName)
	else
		logger:error("Could not find the effect type to rename.")
	end
end

-- This will parse the short name of the effect type (or use the virtual CustomEffectName property when allowed)
-- For example:
-- Should you have a particle system named "MyEffect"...
-- Then, it should have a matching "MyEffectParticleSystemCollectionType" type.
-- Which might contains individual effects, such as "MyEffectSmokeParticleEffectType"
-- Thus, the name of this individual effect would be "Smoke" (MyEffect + Smoke + ParticleEffectType)
-- If that effect is later on renamed in the particle components UI, the actual type won't change, it will just get the CustomEffectName property set to non-default. (and then that will be shown as the name of the effect in the UI)
function parseParticleEffectShortName(effectTypeObj, particleSystemNamePrefix, allowVirtualEffectName)
	local effShortName = "INVALID_TYPENAME"

	local effectTypeName = effectTypeObj:getName()
	
	if (allowVirtualEffectName) then
		if (effectTypeObj.getCustomEffectName) then
			if (effectTypeObj:getCustomEffectName() ~= "") then
				return effectTypeObj:getCustomEffectName()
			end
		end
	end
	
	-- parse off the particle system prefix from the start
	if (stringStartsWith(effectTypeName, particleSystemNamePrefix)) then
		local noPrefixName = string.sub(effectTypeName, 1 + string.len(particleSystemNamePrefix))
		-- parse off "ParticleEffectType" from the end
		if (stringEndsWith(noPrefixName, "ParticleEffectType")) then
			-- whatever was in between those was the individual effect name
			effShortName = string.sub(noPrefixName, 1, -1 - string.len("ParticleEffectType"))
		end
	end
	
	return effShortName
end


-- audio/light/... effect component, activation area too, etc.
function parseOtherEffectShortName(effectTypeObj, particleSystemNamePrefix, allowVirtualEffectName)
	local effShortName = "INVALID_TYPENAME"

	local effectTypeName = effectTypeObj:getName()
	
	if (allowVirtualEffectName) then
		if (effectTypeObj.getCustomEffectName) then
			if (effectTypeObj:getCustomEffectName() ~= "") then
				return effectTypeObj:getCustomEffectName()
			end
		end
	end
	
	-- parse off the particle system prefix from the start
	if (stringStartsWith(effectTypeName, particleSystemNamePrefix)) then
		local noPrefixName = string.sub(effectTypeName, 1 + string.len(particleSystemNamePrefix))
		
		-- parse off "???" from the end
		if (stringEndsWith(noPrefixName, "EffectComponent")) then
			-- whatever was in between those was the individual effect name
			effShortName = string.sub(noPrefixName, 1, -1 - string.len("EffectComponent"))
		elseif (stringEndsWith(noPrefixName, "ActivationAreaComponent")) then
			-- whatever was in between those was the individual effect name
			effShortName = "ActivationArea"
		end
	end
	
	return effShortName
end


-- return a <-PPP-> separated list of the particle effects in the collection
function getParticleSystemEffectsFromCollectionImpl(collectionUH, particleSystemNamePrefixCheck)
	local ret = ""
	local collectionTypeObj = typeManager:getTypeByUH(collectionUH)
	
	local collectionTypeName = collectionTypeObj:getName()
	local systemNamePrefix = "INVALID"
	if (stringEndsWith(collectionTypeName, "ParticleSystemCollectionType")) then
		systemNamePrefix = string.sub(collectionTypeName, 1, -1 - string.len("ParticleSystemCollectionType"))
	end
	
	-- some legacy crap?
	if (not collectionTypeObj.getEffectArray) then
		ret = ret .. "ERROR: Referred effect type is not a collection!<-EID->[GUID_NONE,FLAGS,] Unexpected effect type"
		return ret
	end
	
	-- sanity check, particle system and the collection should use the same name prefix
	if (systemNamePrefix ~= particleSystemNamePrefixCheck) then
		ret = ret .. "ERROR: Referred effect type naming inconsistency!<-EID->[GUID_NONE,FLAGS,] Incorrectly named effect type"
		return ret
	end
	
	local uhPropArray = collectionTypeObj:getEffectArray()
	for arrIdx = 0,uhPropArray:getSize() - 1 do
		local refUH = uhPropArray:get(arrIdx)
		if (refUH ~= UH_NONE) then
			local refCompType = typeManager:getTypeByUH(refUH)
			if (refCompType ~= nil) then
				local effShortName = parseParticleEffectShortName(refCompType, systemNamePrefix, true)
				local tmpTable = { }
				editor.Editor.dumpBranchHeader(tmpTable, refCompType, false, 1)
				local effEditorId = tmpTable[1]
				if (ret ~= "") then
						ret = ret .. "<-PPP->"
				end
				local lifetime = refCompType:getParticleLifetime()
				local maxp = refCompType:getMaxParticleAmount()
				ret = ret .. effShortName .. "<-LT->".. tostring(lifetime) .."<-MAXP->".. tostring(maxp) .."<-EID->" .. effEditorId
			else
				-- Someone has perhaps deleted an effect type manually or otherwise screwed up?
				ret = ret .. "ERROR: Referred effect type missing!<-EID->[GUID_NONE,FLAGS,] Missing effect type"
			end
		else
			-- Unless someone has manually been screwing up things, these UH_NONEs should never exist in the collections!
			ret = ret .. "ERROR: UH_NONE reference found in collection!<-EID->[GUID_NONE,FLAGS,] UH_NONE Reference"
		end
	end

	return ret
end

-- returns a string containing particle system type names and editorId strings with <-EID-> string in between them. Multiple entries are separated by <-PPP-> strings.
-- Fire<-EID->[GUID(...),FLAGS,...] MyEffectFireParticleSystemComponent<-PPP->Smoke<-EID->[GUID(...),FLAGS,...] MyEffectSmokeParticleSystemComponent
-- Note, this also lists the non-particle effects in the particle system!
-- those will have an asterisk (*) in front of the name, and the name will actually be the type designation for the effect / special thingy (CameraShake, ActivationArea, etc.)
function getParticleSystemEffects(particleSystemTypeName)

	local systemNamePrefix = "INVALID"
	if (stringEndsWith(particleSystemTypeName, "ParticleSystemEntity")) then
		systemNamePrefix = string.sub(particleSystemTypeName, 1, -1 - string.len("ParticleSystemEntity"))
	end
	
	local typeObj = typeManager:findTypeByName(particleSystemTypeName)
	if (typeObj ~= nil) then
	
		-- Do not use this anymore! No more 2 separate effect entities
		--typeObj = digOutImplementingParticleSystemType(typeObj)
		--if (typeObj == nil) then
		--	return "ERROR: Particle system has no supported implementing effect component or it refers to UH_NONE!<-EID->[GUID_NONE,FLAGS,] InvalidParticleSystem"
		--end

		local iter = TypeComponentIterator(typeObj)
		local childCompTypeUH = iter:next()
		local effs = ""
		while childCompTypeUH do
			local childCompType = typeManager:getTypeByUH(childCompTypeUH)
			local cName = childCompType:getName()
			if (cName == "TransformComponent") then
				-- skip this
			elseif (childCompType:doesInheritType(typeManager:findTypeByName("EffectComponent")) ) then
				-- skip this
			elseif (childCompType:doesInheritType(typeManager:findTypeByName("AttachEffectComponent")) ) then
				-- skip this
			elseif (childCompType:doesInheritType(typeManager:findTypeByName("ParticleEffectCollectionComponent")) ) then
				-- the DefaultEffectType property should point to a type of AbstractParticleEffectCollectionType class...
				-- go list the effects in EffectArray property in there.
				local collectionUH = editor.Editor.getTypeProperty(childCompType, "DefaultEffectType")
				if (collectionUH ~= UH_NONE) then
					if effs ~= "" then 
						effs = effs .. "<-PPP->"
					end
					effs = effs .. getParticleSystemEffectsFromCollectionImpl(collectionUH, systemNamePrefix)
				else
					return "ERROR: Particle effect collection reference is UH_NONE<-EID->[GUID_NONE,FLAGS,] MissingType"					
				end
			else
				-- these are some custom effect...
				local tmpTable = { }
				editor.Editor.dumpBranchHeader(tmpTable, childCompType, false, 1)
				local editorId = tmpTable[1]
				if effs ~= "" then 
					effs = effs .. "<-PPP->"
				end
				-- asterisk marks some other effect than particle effect (just listed by the particle editor UI, not really supported)
				local shortCName = parseOtherEffectShortName(childCompType, systemNamePrefix, true)
				effs = effs .. "*" .. shortCName .. "<-LT->N/A<-MAXP->N/A<-EID->" .. editorId
			end
			
			childCompTypeUH = iter:next()
		end	
		return effs
	else
		return "ERROR: Particle system is missing!<-EID->[GUID_NONE,FLAGS,] MissingType"
	end
end



-- returns a string containing particle system type names and editorId strings with <-EID-> string in between them. Multiple entries are separated by <-PPP-> strings.
function getParticleEffectComponents(effectTypeName) 
	local effectTypeObj = typeManager:findTypeByName(effectTypeName)
	if (effectTypeObj ~= nil) then
		local ret = ""
		
		local iter = TypeComponentIterator(effectTypeObj)
		local childCompTypeUH = iter:next()
		local effs = ""
		while childCompTypeUH do
			local childCompType = typeManager:getTypeByUH(childCompTypeUH)
			if (childCompType:doesInheritType(typeManager:findTypeByName("AbstractParticleComponent")) ) then
				local childCompName = childCompType:getName() 
				local tmpTable = { }
				editor.Editor.dumpBranchHeader(tmpTable, childCompType, false, 1)
				local editorId = tmpTable[1]
				if (ret ~= "") then
					ret = ret .. "<-PPP->"
				end
				local childCompPurposeName = "(Unknown)"
				local purposePropIndex = childCompType:findPropertyIndexByName("Purpose")
				if purposePropIndex ~= -1 then
					childCompPurposeName = tostring(childCompType:getPropertyValue(purposePropIndex))
				end
				
				ret = ret .. childCompPurposeName .. "<-EID->" .. editorId
			else
				ret = ret .. "ERROR: Effect contains an unsupported component.<-EID->[GUID_NONE,FLAGS,] UnsupportedType"
			end			
			childCompTypeUH = iter:next()
		end	
			
		return ret
	else
		return "ERROR: Effect type is missing!<-EID->[GUID_NONE,FLAGS,] MissingType"
	end
end


-- add some other effect than a particle effect to a particle system "ModelParticle", "Light", "CameraShake", "Audio", "SelfIllumination" or "ActivationArea"
function addNewOtherEffect(pluginName, paramsString)
	local splitted = split_compat(paramsString, ",")
	local particleSystemTypeName = splitted[1]
	local shortEffectName = splitted[2]	
	addNewOtherEffectImpl(pluginName, particleSystemTypeName, shortEffectName)
	sendToPlugin(pluginName, { "editor.ParticleSystems.addNewOtherEffect",  "ok" } )
end


function addNewOtherEffectImpl(pluginName, particleSystemTypeName, shortEffectName)
	assert_string(particleSystemTypeName)
	assert_string(shortEffectName)
	
	if (shortEffectName == "ModelParticle") then
		addNewModelParticleEffect(pluginName, particleSystemTypeName, "ModelEffect")
	elseif (shortEffectName == "Light") then
		addNewLightEffect(pluginName, particleSystemTypeName, "LightEffect")
	elseif (shortEffectName == "CameraShake") then
		addNewCameraShakeEffect(pluginName, particleSystemTypeName, "CameraShakeEffect")
	elseif (shortEffectName == "Audio") then
		logger:error("TODO - addNewOtherEffectImpl, audio effect")	
	elseif (shortEffectName == "SelfIllumination") then
		logger:error("TODO - addNewOtherEffectImpl, self illumination effect")	
	elseif (shortEffectName == "ActivationArea") then
		logger:error("TODO - addNewOtherEffectImpl, activation area")	
	else
		logger:error("addNewOtherEffectImpl, unrecognized other effect type.")
		return
	end
end

function addNewModelParticleEffect(pluginName, particleSystemTypeName, effectName)

	local particleSystem = typeManager:findTypeByName(particleSystemTypeName)
	if (particleSystem == nil) then
		logger:error("Unable to find entity type " .. particleSystemTypeName)
		return
	end

	local newName = particleSystemTypeName .. "ModelParticleEffectComponent"
	local baseTypeName = "ModelParticleEffectComponent"
	local componentTypeToReplaceGuidId = ""
	local instanceGUIDString = ""
	
	editor.ExternalUI.tryToInheritType(newName, baseTypeName, componentTypeToReplaceGuidId, instanceGUIDString)
	
	local component = typeManager:findTypeByName(newName)
	
	if (component ~= nil) then
		if (state.isEditorSyncEnabled) then
			--nop
		end
		
		local lowerCaseEffectName = particleSystemTypeName:lower()
		
		-- FIXME: Sorry about hard coding
		local typeScript = "data/root/component_base/abstract_breakable_model/breakable_model/model_particle_effect/"..lowerCaseEffectName.."model_particle_effect/"..lowerCaseEffectName.."model_particle_effect_component.fbt"
		
		editor.ExternalUI.finishTypeCreation(typeScript, newName, baseTypeName, "")
		
		local componentUH = component:getUnifiedHandle()
		particleSystem:addComponentType(componentUH)
	else
		logger:error("Error while inheriting ModelParticleEffectComponent for model particle effect")
	end
end

function addNewCameraShakeEffect(pluginName, particleSystemTypeName, effectName)

	local particleSystem = typeManager:findTypeByName(particleSystemTypeName)
	if (particleSystem == nil) then
		logger:error("Unable to find entity type " .. particleSystemTypeName)
		return
	end

	local baseTypeName = "ShakeEffectComponent"
	local newName = particleSystemTypeName .. baseTypeName
	local componentTypeToReplaceGuidId = ""
	local instanceGUIDString = ""
	
	editor.ExternalUI.tryToInheritType(newName, baseTypeName, componentTypeToReplaceGuidId, instanceGUIDString)
	
	local component = typeManager:findTypeByName(newName)
	
	if (component ~= nil) then
		if (state.isEditorSyncEnabled) then
			--nop
		end
		
		local lowerCaseEffectName = particleSystemTypeName:lower()
		
		-- FIXME: Sorry about hard coding
		local typeScript = "data/root/component_base/abstract_gameplay/shake_effect/"..lowerCaseEffectName.."shake_effect/"..lowerCaseEffectName.."shake_effect_component.fbt"
		
		editor.ExternalUI.finishTypeCreation(typeScript, newName, baseTypeName, "")
		
		local componentUH = component:getUnifiedHandle()
		particleSystem:addComponentType(componentUH)
	else
		logger:error("Error while inheriting "..baseTypeName.." for shake particle effect")
	end
end

function addNewLightEffect(pluginName, particleSystemTypeName, effectName)

	local particleSystem = typeManager:findTypeByName(particleSystemTypeName)
	if (particleSystem == nil) then
		logger:error("Unable to find entity type " .. particleSystemTypeName)
		return
	end

	local baseTypeName = "LightEffectComponent"
	local newName = particleSystemTypeName .. baseTypeName
	local componentTypeToReplaceGuidId = ""
	local instanceGUIDString = ""
	
	editor.ExternalUI.tryToInheritType(newName, baseTypeName, componentTypeToReplaceGuidId, instanceGUIDString)
	
	local component = typeManager:findTypeByName(newName)
	
	if (component ~= nil) then
		if (state.isEditorSyncEnabled) then
			--nop
		end
		
		local lowerCaseEffectName = particleSystemTypeName:lower()
		
		-- FIXME: Sorry about hard coding
		local typeScript = "data/root/component_base/abstract_gameplay/light_effect/"..lowerCaseEffectName.."light_effect/"..lowerCaseEffectName.."light_effect_component.fbt"
		
		editor.ExternalUI.finishTypeCreation(typeScript, newName, baseTypeName, "")
		
		local componentUH = component:getUnifiedHandle()
		particleSystem:addComponentType(componentUH)
		
		-- LightEffectComponent created. Now create PointLightComponent and link it to LightEffectComponent::LightComponentType
		
		baseTypeName = "ParticleEffectLightEntityPointLightComponent"
		newName = particleSystemTypeName .. baseTypeName
		editor.ExternalUI.tryToInheritType(newName, baseTypeName, "", "")
		local lightComponent = typeManager:findTypeByName(newName)
		if (lightComponent ~= nil) then
			typeScript = "data/root/component_base/abstract_light/point_light/particle_effect_light_entity_point_light/"..lowerCaseEffectName.."point_light_component/"..lowerCaseEffectName.."point_light_component.fbt"
			editor.ExternalUI.finishTypeCreation(typeScript, newName, baseTypeName, "")
			local lightComponentUH = lightComponent:getUnifiedHandle()
			
			local idx = component:findPropertyIndexByName("LightComponentType")
			if (idx >= 0) then
				component:setPropertyValue(idx, lightComponentUH)
			end
		end
	else
		logger:error("Error while inheriting "..baseTypeName.." for light effect")
	end
end


-- THIS FUNCTION IS NO LONGER IN USE!!!!!!!!
-- THE PARTICLE SYSTEMS NOW AGAIN HAVE ONLY 1 ENTITY PER LEVEL PLACED PARTICLE SYSTEM!
-- ultra hackery thing... 
-- must first solve the reference from the level placeable/etc. entity to the actual implementing (non-level-placeable) effect entity
function digOutImplementingParticleSystemType(typeObj)
	local foundImplementingType = false
	local implementingTypeObj = nil
	local iter = TypeComponentIterator(typeObj)
	local childCompTypeUH = iter:next()
	while childCompTypeUH do			
		local childCompType = typeManager:getTypeByUH(childCompTypeUH)
		if (childCompType:doesInheritType(typeManager:findTypeByName("AttachEffectComponent")) ) then
			-- we found it, this is particle system that uses an attached effect component 
			local implementingTypeUH = childCompType:getEffectType()
			if (implementingTypeUH ~= UH_NONE) then
				foundImplementingType = true
				implementingTypeObj = typeManager:getTypeByUH(implementingTypeUH)
			else
				logger:error("Particle system has UH_NONE as implementing entity!")
				return
			end
		end
		-- TODO: elseif, try to see if there is one of the OnContactEffectComponent or such components here... solve the implementing effect from those

		childCompTypeUH = iter:next()
	end	

	if not foundImplementingType then
		logger:error("Particle system has no supported implementing effect component!")
		return
	end
	
	typeObj = implementingTypeObj
	
	return typeObj
end

-- create new effect
function addNewParticleEffect(pluginName, paramsString)
	local splitted = split_compat(paramsString, ",")
	local particleSystemTypeName = splitted[1]
	local shortEffectName = splitted[2]	
	addNewParticleEffectImpl(pluginName, particleSystemTypeName, shortEffectName, "TemplateNew")
end

-- (called by the particle component modification UI on new effect creation)
-- create new effect from template
function addNewParticleEffectFromTemplate(pluginName, paramsString)
	local splitted = split_compat(paramsString, ",")
	local particleSystemTypeName = splitted[1]
	local shortEffectName = splitted[2]
	local effectTemplatePrefix = splitted[3]
	addNewParticleEffectImpl(pluginName, particleSystemTypeName, shortEffectName, effectTemplatePrefix)
	sendToPlugin(pluginName, { "editor.ParticleSystems.addNewParticleEffectFromTemplate",  "ok" } )
	-- externalUI:sendUICommand("sendToPlugin(\"ParticleComponents\", \"editor.ParticleSystems.addNewParticleEffectFromTemplate\", \"ok\")")
end


-- creates a new effect an existing particle system
-- (if the particle system does not have an existing particle effect collection component/type, they will be created)
function addNewParticleEffectImpl(pluginName, particleSystemTypeName, shortEffectName, effectTemplatePrefix)
	assert_string(particleSystemTypeName)
	assert_string(shortEffectName)
	assert_string(effectTemplatePrefix)

	-- the name of this particle system (the name prefix)
	local systemNamePrefix = nil
	if (stringEndsWith(particleSystemTypeName, "ParticleSystemEntity")) then
		systemNamePrefix = string.sub(particleSystemTypeName, 1, -1 - string.len("ParticleSystemEntity"))
	end
	
	-- if the type name already exists, do some random hackery...
	local nameConflicts = true
	local setCustomNameTo = nil
	while (nameConflicts) do		
		local fullTypeNameToBeCreated = systemNamePrefix .. shortEffectName .. "ParticleEffectType"
		local typeExistCheck = typeManager:findTypeByName(fullTypeNameToBeCreated)
		if (typeExistCheck == nil) then
			-- ok to continue
			nameConflicts = false
		else
			nameConflicts = true
			if (setCustomNameTo == nil) then
				setCustomNameTo = shortEffectName  -- preserve the user given name, set it as the virtual CustomEffectName property
				logger:warning("Created effect type name conflicts with an existing one, modifying the actual effect type name to create, and setting the CustomEffectName property to the requested name.")
			end
			-- change the name (by adding "Dup" at the end of it, as many times as necessary)
			shortEffectName = shortEffectName .. "Dup"
		end
	end

	-- particle system does not match naming convention
	if (not systemNamePrefix) then
		local msg = "Invalid particle system type name."
		logger:error(msg)
		sendToPlugin(pluginName, { "editor.ParticleSystems.addNewParticleEffect", msg } )
		-- externalUI:sendUICommand("sendToPlugin(\"ParticleComponents\", \"editor.ParticleSystems.addNewParticleEffect\", \"" .. msg .. "\")")
		return
	end
	
	local typeObj = typeManager:findTypeByName(particleSystemTypeName)
	local collectionCompObj = nil
	if (typeObj ~= nil) then

		-- Do not use this anymore! No more 2 separate effect entities
		--typeObj = digOutImplementingParticleSystemType(typeObj)
	
		-- see if the collection component already exists?
		local iter = TypeComponentIterator(typeObj)
		local childCompTypeUH = iter:next()
		local effs = ""
		while childCompTypeUH do
			local childCompType = typeManager:getTypeByUH(childCompTypeUH)
			if (childCompType:doesInheritType(typeManager:findTypeByName("ParticleEffectCollectionComponent")) ) then
				collectionCompObj = childCompType
			end			
			childCompTypeUH = iter:next()
		end	
		
		-- the collection component did not exist, create it
		if (not collectionCompObj) then		
			editor.ExternalUI.deepCopyType(effectTemplatePrefix.."EffectCollectionComponent", effectTemplatePrefix, systemNamePrefix, true, true)
			
			-- the new name should be...
			local expectedCollectionCompName = systemNamePrefix .. "EffectCollectionComponent"
			local createdTypeObj = typeManager:findTypeByName(expectedCollectionCompName)
			if (createdTypeObj ~= nil) then
				-- all ok
				collectionCompObj = createdTypeObj
			else
				local msg = "Something went wrong with particle collection component creation! New incorrect types may have been created."
				logger:error(msg)
				sendToPlugin(pluginName, { "editor.ParticleSystems.addNewParticleEffect" , msg } )
				-- externalUI:sendUICommand("sendToPlugin(\"ParticleComponents\", \"editor.ParticleSystems.addNewParticleEffect\", \"" .. msg .. "\")")
				return
			end			
		end		
		
		-- now, create the actual effect
		if (collectionCompObj) then
			editor.ExternalUI.deepCopyType("TemplateNewParticleEffectType", "TemplateNew", systemNamePrefix .. shortEffectName, true, true)
			local expectedActualEffectTypeName = systemNamePrefix .. shortEffectName .. "ParticleEffectType"
			local createdTypeObj = typeManager:findTypeByName(expectedActualEffectTypeName)
			if (createdTypeObj ~= nil) then

				-- all ok, add the reference to the new effect
				local actualCollectionTypeUH = editor.Editor.getTypeProperty(collectionCompObj, "DefaultEffectType")
				local actualCollectionTypeObj = typeManager:getTypeByUH(actualCollectionTypeUH)
				local uhPropArray = actualCollectionTypeObj:getEffectArray()
				-- create a new uh array with the new object.
				local uhTable = {}
				for arrIdx = 0,uhPropArray:getSize() - 1 do
					local refUH = uhPropArray:get(arrIdx)
					table.insert(uhTable, refUH)
				end
				table.insert(uhTable, createdTypeObj:getUnifiedHandle())
				local newUHArray = UHPropertyArray(uhTable)
				actualCollectionTypeObj:setEffectArray(newUHArray)
				
				-- do we need to set the custom name? (in case of type name conflict)
				if (setCustomNameTo ~= nil) then
					createdTypeObj:setCustomEffectName(setCustomNameTo)
				end
				
			else
				local msg = "Something went wrong with effect type deep copy! New incorrect types may have been created."
				logger:error(msg)
				sendToPlugin(pluginName, { "editor.ParticleSystems.addNewParticleEffect", msg } )
				-- externalUI:sendUICommand("sendToPlugin(\"ParticleComponents\", \"editor.ParticleSystems.addNewParticleEffect\", \"" .. msg .. "\")")
				return
			end
		end		
	else
		local msg = "Cannot create particle effect, particle system type is missing."
		logger:error(msg)
		sendToPlugin(pluginName, { "editor.ParticleSystems.addNewParticleEffect", msg } )
		-- externalUI:sendUICommand("sendToPlugin(\"ParticleComponents\", \"editor.ParticleSystems.addNewParticleEffect\", \"" .. msg .. "\")")
	end
	
	sendToPlugin(pluginName, { "editor.ParticleSystems.addNewParticleEffect", "ok" } )
	-- externalUI:sendUICommand("sendToPlugin(\"ParticleComponents\", \"editor.ParticleSystems.addNewParticleEffect\", \"ok\")")
end


-- deletes an effect from the particle system
-- NOTICE: the given particle effect type must be a PARTICLE effect. (see also, deleteOtherEffect)
function deleteParticleEffect(pluginName, paramsString)
	local splitted = split_compat(paramsString, ",")
	local particleSystemTypeName = splitted[1]
	local particleEffectTypeName = splitted[2]
	deleteParticleEffectImpl(pluginName, particleSystemTypeName, particleEffectTypeName)
	
	preprocessSingleEffect(particleSystemTypeName)
end


function deleteParticleEffectImpl(pluginName, particleSystemTypeName, particleEffectTypeName)
	assert_string(particleSystemTypeName)
	assert_string(particleEffectTypeName)
	
	-- don't allow deleting the templates!
	if (stringStartsWith(particleEffectTypeName, "Template")) then
		logger:error("Sanity check failed. Attempt to delete a template particle effect. Preventing the operation.")
		return
	end
	if (stringStartsWith(particleSystemTypeName, "Template")) then
		logger:error("Sanity check failed. Attempt to delete an effect from a template particle system. Preventing the operation.")
		return
	end
		
	-- the system type obj
	local typeObj = typeManager:findTypeByName(particleSystemTypeName)

	-- the actual implementing type please
-- Do not use this anymore! No more 2 separate effect entities
	--typeObj = digOutImplementingParticleSystemType(typeObj)
	
	local collectionCompObj = nil
	if (typeObj ~= nil) then
		-- find the collection component
		local iter = TypeComponentIterator(typeObj)
		local childCompTypeUH = iter:next()
		local effs = ""
		while childCompTypeUH do
			local childCompType = typeManager:getTypeByUH(childCompTypeUH)
			if (childCompType:doesInheritType(typeManager:findTypeByName("ParticleEffectCollectionComponent")) ) then
				collectionCompObj = childCompType
			end			
			childCompTypeUH = iter:next()
		end	
		
		if (collectionCompObj) then
			-- ok, found the collection, remove the effect from its reference list and proceed to delete the effect...
			local actualCollectionTypeUH = editor.Editor.getTypeProperty(collectionCompObj, "DefaultEffectType")
			local actualCollectionTypeObj = typeManager:getTypeByUH(actualCollectionTypeUH)
			if (actualCollectionTypeObj ~= nil) then
				local uhPropArray = actualCollectionTypeObj:getEffectArray()
				-- create a new uh array with the new object.
				local uhTable = {}
				local wasFound = false
				for arrIdx = 0,uhPropArray:getSize() - 1 do
					local refUH = uhPropArray:get(arrIdx)
					local refT = typeManager:getTypeByUH(refUH)
					if (refT ~= nil) then
						if (refT:getName() == particleEffectTypeName) then
							-- found it. (do not keep this in the list.)
							wasFound = true
						else
							table.insert(uhTable, refUH)
						end
					else
						logger:warning("Encountered a reference to non-existing effect type in the collection. (Ignoring this issue as it is not related to current deletion operation, but it may cause problems later on!)")
						table.insert(uhTable, refUH)
					end
				end
				local newUHArray = UHPropertyArray(uhTable)
				actualCollectionTypeObj:setEffectArray(newUHArray)

				if not wasFound then
					logger:error("The effect being deleted was not found in the effect collection. This should not have happened! Bailing out to prevent a disaster.")
					return
				end
				
				-- sanity check to prevent a total disaster...
				if (stringEndsWith(particleEffectTypeName, "ParticleEffectType")) then
					local numTypesDeleted = editor.ExternalUI.deepDeleteType(particleEffectTypeName, true, { "Particle", "Effect" })
					logger:info("A total of " .. tostring(numTypesDeleted) .. " related types were deleted while deleting the particle effect \"" .. particleEffectTypeName .. "\".")
				else
					-- don't allow use of this for anything but the automatically created particle effect types (as this could cause potentially massive type destruction when done on anything else)
					logger:error("Sanity check failed. Attempt to delete a particle effect, that does not seem like a particle effect. Preventing the operation to prevent a possible disaster.")
					return
				end	
			else
				logger:error("The particle system collection component did not refer to collection effect type.")
				return
			end
		else
			logger:error("Failed to find the particle system collection component.")
			return
		end		
	else
		logger:error("Failed to find the particle system type.")
		return
	end
	
	sendToPlugin(pluginName, { "editor.ParticleSystems.deleteParticleEffect", "ok" } )
	-- externalUI:sendUICommand("sendToPlugin(\"ParticleComponents\", \"editor.ParticleSystems.deleteParticleEffect\", \"ok\")")
end


-- delete something else than a particle effect from a particle system
function deleteOtherEffect(pluginName, paramsString)
	local splitted = split_compat(paramsString, ",")
	local particleSystemTypeName = splitted[1]
	local otherEffectTypeName = splitted[2]
	deleteOtherEffectImpl(pluginName, particleSystemTypeName, otherEffectTypeName)
end

function deleteOtherEffectImpl(pluginName, particleSystemTypeName, otherEffectTypeName)
	assert_string(particleSystemTypeName)
	assert_string(otherEffectTypeName)
	
	-- Do NOT deep delete their references too, as that might cause a total disaster (due to some special effects perhaps referring to player types and such!)
	
	if (stringEndsWith(otherEffectTypeName, "ModelParticleEffectComponent") or
		stringEndsWith(otherEffectTypeName, "LightEffectComponent") or
		stringEndsWith(otherEffectTypeName, "ShakeEffectComponent")) then
		--Lets remove a component from the particle system
		local typeObj = typeManager:findTypeByName(particleSystemTypeName)
		local compObj = typeManager:findTypeByName(otherEffectTypeName)
		if (typeObj ~= nil and compObj ~= nil) then
		
			if stringEndsWith(otherEffectTypeName, "LightEffectComponent") then
				-- Delete PointLightComponent that we have created for this effect entity.
				local idx = compObj:findPropertyIndexByName("LightComponentType")
				if (idx >= 0) then
					local pointLightUH = compObj:getPropertyValue(idx)
					compObj:setPropertyValue(idx, UH_NONE)
					if pointLightUH ~= UH_NONE then
						typeManager:deleteType(typeManager:getTypeByUH(pointLightUH))
					end
				end
			end
		
			local typeChildCompUH = compObj:getUnifiedHandle()
			if not typeObj:removeComponentType(typeChildCompUH) then
				logger:error("Error removing component " .. otherEffectTypeName .. " from " .. particleSystemTypeName)
			else
				typeManager:deleteType(compObj)
				sendToPlugin(pluginName, { "editor.ParticleSystems.deleteOtherEffect", "ok" } )
				return
			end
		end
	end
	
	logger:error("Error in editor.ParticleSystems.deleteOtherEffect")
	sendToPlugin(pluginName, { "editor.ParticleSystems.deleteOtherEffect", "failed" } )

end


-- get rid of previous preview effect (if one exists in the scene)
function removeParticlePreviewInstances()
	for i=1,10 do
		local oldPrevEnt = scene:getSceneInstanceManager():findInstanceByName("_particle_preview_" .. tostring(i) .. "_")
		if (oldPrevEnt) then
			scene:getSceneInstanceManager():deleteInstance(oldPrevEnt:getUnifiedHandle());
		end
	end
end


function makeParticlePreviewInstance(inst, params)
	inst:setName("_particle_preview_" .. tostring(params.num) .. "_")
	inst:getTransformComponent():setPosition(params.position)	
	local effComp = inst:findComponent(gameplay.effect.EffectComponent)
	if (effComp) then
		if (effComp:getSanityHint() == gameplay.effect.EffectComponent.SanityHintContinuousLoopingLevelEffect
			or effComp:getSanityHint() == gameplay.effect.EffectComponent.SanityHintTriggeredNonLoopingLevelEffect) then
			-- nop, these are level effects, it is totally fine that they keep their sanity checks on
		else
			-- the non-level effects are allowed to be previewed in scene too. don't spam warnings for no good reason.
			effComp:setSanityHint(gameplay.effect.EffectComponent.SanityHintCustomEffectIgnoreSanity)
		end
	else
		logger:error("Particle preview instance is missing effect component.")
	end
	--inst:setRotation(params.rotation)
	inst:setNoSaveFlag()
end


-- particleSystemTypeNames is a comma separated list of the particle system entity type names to preview
-- at least 1, at most 10 type names required (no whitespaces please!)
function previewParticleSystems(pluginName, particleSystemTypeNames)
	-- get rid of previous preview effect
	removeParticlePreviewInstances()
		
	-- FIXME: If this preview gets called multiple times fast enough, then multiple particle system preview entities will appear!
	-- (note, the user cannot normally click the button fast enough, but if there are some messageboxes/jams or such occurring while clicking, it might happen)
	
	-- HACK: prevent issues with duplicate names (due to old preview removes being delayed by a few frames)
	state:runLuaStringWithDelay("editor.ParticleSystems.previewParticleSystemsDelayed1(\""..particleSystemTypeNames.."\")", 1)
end

function previewParticleSystemsDelayed1(particleSystemTypeNames)
	state:runLuaStringWithDelay("editor.ParticleSystems.previewParticleSystemsDelayed2(\""..particleSystemTypeNames.."\")", 1)
end

function previewParticleSystemsDelayed2(particleSystemTypeNames)
	local cam = scene:getSceneInstanceManager():findInstanceByName("EditorCamera")
	if (cam) then
		local transf = cam:getTransformComponent()
		local camPos = transf:getPosition()
		
		-- FIXME: this incorrect, should dig out cameraForwardVector instead (since it may differ from entity forward vector... which makes no sense though)
		local camForwardDir = cam:getRotatedEntityForwardVector() 
		
		local metersInFrontOfCamera = 5
		
		local splitted = split_compat(particleSystemTypeNames, ",")
		
		for i=1,#splitted do
			-- FIXME: add camera side vector * i-1 to the preview pos... or something
			-- HACK: currently just offsetting 1 meter per effect num on the X-axis
			local numOffsetX = i-1
			
			local previewPos = VC3(camPos.x + camForwardDir.x * metersInFrontOfCamera + numOffsetX, camPos.y + camForwardDir.y * metersInFrontOfCamera, camPos.z + camForwardDir.z * metersInFrontOfCamera)
			local typeObj = typeManager:findTypeByName(splitted[i])
			if (typeObj ~= nil) then
				scene:getSceneInstanceManager():createNewInstance(typeObj:getUnifiedHandle(), makeParticlePreviewInstance, { num=i, position=previewPos } );
			end
		end		
	else
		logger:error("No editor camera found, cannot preview particle effect.")
	end
end


-- simply sets the particle lifetime of a particle effect
-- the paramsString parameter needs to be "<effectTypeName>,<lifetimeValue>" (for example, "MyEffUnnamed1ParticleEffectType,0.1")
function setParticleEffectLifetime(paramsString)
	local splitted = split_compat(paramsString, ",")
	local particleEffectTypeName = splitted[1]
	local valueStr = splitted[2]
	
	local value = editor.ExternalUI.parseObjectFromStringValue(valueStr)
	local typeObj = typeManager:findTypeByName(particleEffectTypeName)
	if (typeObj ~= nil) then
		typeObj:setParticleLifetime(value)
	else
		logger:error("Failed to find the particle effect type with name \""..particleEffectTypeName.."\".")
	end
	
	preprocessSingleEffect(particleEffectTypeName)	
end


-- simply sets the max amount of particles of a particle effect
-- the paramsString parameter needs to be "<effectTypeName>,<maxParticlesValue>" (for example, "MyEffUnnamed1ParticleEffectType,100")
function setParticleEffectMaxParticles(paramsString)
	local splitted = split_compat(paramsString, ",")
	local particleEffectTypeName = splitted[1]
	local valueStr = splitted[2]
	
	local value = editor.ExternalUI.parseObjectFromStringValue(valueStr)
	local typeObj = typeManager:findTypeByName(particleEffectTypeName)
	if (typeObj ~= nil) then
		typeObj:setMaxParticleAmount(value)
	else
		logger:error("Failed to find the particle effect type with name \""..particleEffectTypeName.."\".")
	end
	
	preprocessSingleEffect(particleEffectTypeName)	
end

-- adds a new component by cloning from a template to the given particle effect type
-- params string must be in format "ParticleEffectTypeName,TemplateTypeName"
-- For example: "MyEffectUnnamed1ParticleEffectType,TemplateUpwardSprayEmitterParticleEmitterComponent"
-- (which might result into the new component with the name "MyEffectUnnamed1Comp1ParticleEmitterComponent" (assuming no other existing components in the effect)
function addParticleEffectComponent(pluginName, paramsString)
	local splitted = split_compat(paramsString, ",")
	local particleEffectTypeName = splitted[1]
	local templateTypeName = splitted[2]

	logger:debug("Add particle component from template \""..templateTypeName.."\" to the effect \""..particleEffectTypeName.."\"")
	
	local effectTypeObjToAddTo = typeManager:findTypeByName(particleEffectTypeName)
	if (effectTypeObjToAddTo == nil) then
		logger:error("No effect type with the name \""..particleEffectTypeName.."\" was found.")
		return
	end

	-- this is currently the only easy way to figure out the particle template prefix from a type name...
	local addComponentTemplateTypeBaseName = nil
	local addComponentTemplateTypePrefix = nil

	local knownParticleComponentPostfixes = {
		"ParticleForceComponent",
		"ParticleEmitterComponent",
		"ParticleRenderComponent",
		"ParticleDrainComponent",
		"ParticleCollisionComponent",
		"ParticleFluidSyncComponent"
	}
	for i=1,#knownParticleComponentPostfixes do
		if (stringEndsWith(templateTypeName, knownParticleComponentPostfixes[i])) then
			addComponentTemplateTypeBaseName = knownParticleComponentPostfixes[i]
			addComponentTemplateTypePrefix = string.sub(templateTypeName, 1, -1 - string.len(knownParticleComponentPostfixes[i]))
		end
	end
	if (addComponentTemplateTypeBaseName == nil or addComponentTemplateTypePrefix == nil) then
		logger:error("Failure, component template type name did not have any of the supported type name postfix, and thus the prefix/postfix cannot be solved out of the type name.")
		return
	end
	
	-- solve the combined system name + effect name prefix (everything before the "ParticleEffectType" postfix)
	local systemAndEffectNamePrefix = nil
	if (stringEndsWith(particleEffectTypeName, "ParticleEffectType")) then
		systemAndEffectNamePrefix = string.sub(particleEffectTypeName, 1, -1 - string.len("ParticleEffectType"))
	else
		logger:error("Failure, effect type name did not the expected type name postfix (perhaps a manually created effect type?), and thus the correct name prefix cannot be solved out of the type name.")
		return
	end

	local addComponentTemplateTypeName = templateTypeName
	local oldPrefix = addComponentTemplateTypePrefix  -- template prefix
	local newComponentPrefixName
	for compNum = 1, 20 do
		newComponentPrefixName = systemAndEffectNamePrefix .. "Comp" .. compNum .. addComponentTemplateTypeBaseName
		if typeManager:findTypeByName(newComponentPrefixName .. addComponentTemplateTypeBaseName) then
			-- Try again with next number
			newComponentPrefixName = nil
		else
			-- Great, we found free name
			break
		end
	end
	
	if not newComponentPrefixName then
		editor.ExternalUI.editorMessageBox("Could not create" .. errCodeTable.msg, "Particle Component Creation Failed", "Error")
		return
	end

	-- duplicate the given template component to the new effect prefix
	local errCodeTable = { }
	local okToCopy = editor.ExternalUI.canDeepCopyType(errCodeTable, addComponentTemplateTypeName, oldPrefix, newComponentPrefixName, true, true)
	if (okToCopy) then
		-- do it...
		logger:debug("Going to deep copy particle component from (" .. addComponentTemplateTypeName .. ") " .. oldPrefix .. " to " .. newComponentPrefixName)
		editor.ExternalUI.deepCopyType(addComponentTemplateTypeName, oldPrefix, newComponentPrefixName, true, true)
	else
		logger:debug("Naming convention issue detected for particle component deep copy from (" .. addComponentTemplateTypeName .. ") " .. oldPrefix .. " to " .. newComponentPrefixName)
		local okToCopyWithBadNaming = editor.ExternalUI.canDeepCopyType(errCodeTable, addComponentTemplateTypeName, oldPrefix, newComponentPrefixName, true, false)
		if okToCopyWithBadNaming then
			logger:debug("User approved (naming convention issue) deep copy particle component from (" .. addComponentTemplateTypeName .. ") " .. oldPrefix .. " to " .. newComponentPrefixName)
			-- type naming issues, allow the user to skip those if really sure about it...
			editor.ExternalUI.userConfirmBeforeCallingFunction(
				"There is a component or referred type naming convention issue in the particle component being duplicated. This may be caused by some manual modifications done to the type. Duplicating the particle component may not be safe and may result in unexpected or excessive number of types being created. Do you want to ignore the issue and continue anyway?", 
				editor.ExternalUI.deepCopyType, addComponentTemplateTypeName, oldPrefix, newComponentPrefixName, true, false
			)
		else
			editor.ExternalUI.editorMessageBox("Particle component creation cannot be done due to the following error.\r\n\r\n" .. errCodeTable.msg, "Particle Component Creation Failed", "Error")
		end
	end
	
	-- then add the newly created component type to the effect type
	local newlyCreatedComponentTypeName = newComponentPrefixName..addComponentTemplateTypeBaseName
	
	local createdCompTypeObj = typeManager:findTypeByName(newlyCreatedComponentTypeName)
	if (createdCompTypeObj ~= nil) then
		 effectTypeObjToAddTo:addComponentType(createdCompTypeObj:getUnifiedHandle())
	else
		-- something bugged during deepCopyType?
		logger:error("Failure during particle effect component type creation. The resulting compoonent type with the expected name \""..newlyCreatedComponentTypeName.."\" does not exist.")
		return
	end
	
	preprocessSingleEffect(particleEffectTypeName)
end


-- deletes the given particle component from the given effect
-- expects a parameter string "ParticleEffectTypeName,ParticleComponentTypeName"
function deleteParticleComponent(pluginName, paramsString)
	local splitted = split_compat(paramsString, ",")
	local particleEffectTypeName = splitted[1]
	local particleComponentTypeName = splitted[2]
	deleteParticleComponentImpl(particleEffectTypeName, particleComponentTypeName)
	
	preprocessSingleEffect(particleEffectTypeName)
end

function deleteParticleComponentImpl(particleEffectTypeName, particleComponentTypeName)
	local effectTypeObj = typeManager:findTypeByName(particleEffectTypeName)
	if (effectTypeObj == nil) then
		logger:error("No effect type with the name \""..particleEffectTypeName.."\" was found.")
		return
	end
	local compTypeObj = typeManager:findTypeByName(particleComponentTypeName)
	if (compTypeObj == nil) then
		logger:error("No component type with the name \""..particleComponentTypeName.."\" was found.")
		return
	end
	
	effectTypeObj:removeComponentType(compTypeObj:getUnifiedHandle());
	local numTypesDeleted = editor.ExternalUI.deepDeleteType(particleComponentTypeName, true, { "Particle" })
	if numTypesDeleted > 1 then
		-- components should not refer to anything else? thus, only one type should ever be deleted
		-- maybe this was some special case, or manually modified type. whichever the case was, the deepDeleteType may have deleted something that it should not have in such case
		logger:warning("A total of " .. tostring(numTypesDeleted) .. " related types were deleted while deleting the particle component \"" .. particleComponentTypeName .. "\". Usually only one type should get deleted for the component. Something may have possibly gone horribly wrong!")
	else
		logger:debug("A total of " .. tostring(numTypesDeleted) .. " related types were deleted while deleting the particle component \"" .. particleComponentTypeName .. "\".")
	end
end


function restartEffectByTypeName(pluginName, typeName)
	local typ = typeManager:findTypeByName(typeName)
	if typ then

		local i = 0;
		local inst = typ:getCreatedInstance(i);
		while not(inst == nil) do

			--local aec = findComponentFromObjectByClass(inst,gameplay.effect.AttachEffectComponent.getStaticObjectClass());
			--if(aec) then
			--	aec:setEnabled(false)
			--	aec:setEnabled(true)
			--end
			
			-- local pec = inst:findComponentByClass(particles.ParticleEffectComponent.getStaticObjectClass());
			-- if(pec) then
			-- 	pec:resetEffect()
			-- end
			
			-- local abm = inst:findComponentByClass(engine.component.AbstractBreakableModelComponent.getStaticObjectClass());
			-- if(abm) then
			-- 	abm:restartEffect()
			-- end
			local ec = inst:findComponentByClass(gameplay.effect.EffectComponent.getStaticObjectClass());
			if ec then
				ec:resetEffect();
				ec:doEffect( { } );
			end
			
			i = i + 1;
			inst = typ:getCreatedInstance(i);
		end

	end
end
