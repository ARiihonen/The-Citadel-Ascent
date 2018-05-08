module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

require "debug.Assert"
require "debug.AutoReloadable"
require "editor.Util"

local thisModule = _M

declareManualReload(thisModule, [[InfiniteDepth]])

-- close enough to "infinite" :)
-- this can be used as the maxDepth parameter to the tree dumping functions to indicate 
-- requirement for a full tree dump
editor.Editor.InfiniteDepth = 9999999;

--
-- For now these affects directly to PropertyGrid component order, names and expanding functionality
--
declareReload(thisModule, [[opt_sync_data_class_name_as_first]])
declareReload(thisModule, [[opt_sync_data_class_name_as_second]])
declareReload(thisModule, [[opt_sync_data_parent_class_name_as_first]])
declareReload(thisModule, [[opt_sync_data_parent_class_name_as_second]])

opt_sync_data_class_name_as_first = 0;
opt_sync_data_class_name_as_second = 1;
opt_sync_data_parent_class_name_as_first = 2;
opt_sync_data_parent_class_name_as_second = 3;

declareReload(thisModule, [[cfgNameFormatStringBetweenBrackets]])
declareReload(thisModule, [[cfgNameFormatInSyncDataForInstances]])
declareReload(thisModule, [[cfgNameFormatInSyncDataForTypes]])

cfgNameFormatStringBetweenBrackets = " ";
cfgNameFormatInSyncDataForInstances = opt_sync_data_parent_class_name_as_first;
cfgNameFormatInSyncDataForTypes = opt_sync_data_parent_class_name_as_first;


function initEditor()
	externalUI:sendUICommand("initRevisionUtil(\"" .. app:getSourceRevisionString() .. "\")")
end


function tableConcat(table1, table2)
	for idx,v in pairs(table2) do table.insert(table1, v); end
end


function getNameWithoutFolder(name)
	assert_string(name)

	local ret = name

	local splitpos = ret:find("/", 1, true)
	while (not(splitpos == nil)) do
		ret = ret:sub(splitpos + 1)
		splitpos = ret:find("/", 1, true)
	end

	return ret;
end


function dumpClass(obj, humanreadable)
	assert_treenode(obj)
	assert_boolean(humanreadable)
	
	local ret = {};
	local propsid = "";
	if (not(humanreadable)) then
		propsid = "["..tostring(obj:getGuid())..",PROPS]";
	end	
	table.insert(ret, propsid .. "properties");
	table.insert(ret, "{");
	tableConcat(ret, dumpProps(obj, humanreadable));
	table.insert(ret, "}");
	return ret;
end


function getInstanceTypeName(obj)
	assert_treenode(obj)
	
	local extraTypeName = "";
	if obj ~= nil then
		if (not(obj.getType == nil)) then
			if (obj:isInherited(engine.base.InstanceBase.getStaticObjectClass())) then
				local typeUH = obj:getType()
				local type = typeManager:getTypeByUH(typeUH);
				if(type) then
					extraTypeName = type:getName();
				end
			end
		end
	end
	return extraTypeName;
end

function getObjectName(obj)
	assert_treenode(obj)
	
	local objName = "";
	if obj ~= nil then
		if (not(obj.getName == nil)) then
			if (not(obj:getName() == "")) then
				objName = getNameWithoutFolder(obj:getName());
			end
		end
	end
	return objName;
end

function getParentName(obj)
	assert_treenode(obj)

	local str = "";
	local curType = nil;
	local parentType = nil;
			
	if obj ~= nil then
		local baseClassForComponents = "ComponentBase";
		local lastParentName = "";			
		
		-- Get the type
		if (obj:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass())) then
			curType = obj;
			parentType = curType:getParentType();
		elseif (obj:isInherited(engine.base.InstanceBase.getStaticObjectClass())) then
			local typeUH = obj:getType()
			local type = typeManager:getTypeByUH(typeUH);
			if type ~= nil then
				curType = type;
				parentType = curType:getParentType();
			end
		end
		
		-- Find the "oldest" parent
		if curType ~= nil then
			
			if curType:isStaticType() then
				-- Self is static?
				lastParentName = getObjectName(curType);
			else
				while parentType ~= nil do
					local parentName = getObjectName(parentType);
					
					-- Found the ultimate base, break out
					if parentName == baseClassForComponents then
						break;
					end

					-- Static type, use this
					if parentType:isStaticType() then
						lastParentName = parentName;
						break;
					end
					
					-- Save old name
					lastParentName = parentName;
					
					-- Get older parent
					curType = parentType;
					parentType = curType:getParentType();
				end
			end
			str = lastParentName;
		end
	end
	
	-- Remove some crap from the string
	str = string.gsub(str, "Abstract", "");

	return str;
end

function getNameForDump(obj, isComponentType)
	local retName = "";
	local objClassName = tostring(obj:getClassName());
	local objName = getObjectName(obj);
	local extraTypeName = getInstanceTypeName(obj);	
	local parentName = getParentName(obj);
	
	-- If extraType name is the same, don't use it
	if string.len(extraTypeName) > 0 and extraTypeName == parentName then
		extraTypeName = "";
	end
	
	if cfgNameFormatInSyncDataForInstances == opt_sync_data_class_name_as_first then
		if string.len(extraTypeName) > 0 then
			retName = objClassName .. cfgNameFormatStringBetweenBrackets .. "(" .. extraTypeName .. ") ";
		else
			retName = objClassName;
		end
	elseif cfgNameFormatInSyncDataForInstances == opt_sync_data_class_name_as_second then
		if string.len(extraTypeName) > 0 then
			retName = extraTypeName .. cfgNameFormatStringBetweenBrackets .. "(" .. objClassName .. ") ";
		else
			retName = objClassName;
		end
	elseif cfgNameFormatInSyncDataForInstances == opt_sync_data_parent_class_name_as_first then
		if string.len(parentName) > 0 then
			if string.len(extraTypeName) > 0 then
				retName = parentName .. cfgNameFormatStringBetweenBrackets .. "(" .. extraTypeName .. ") ";
			else
				retName = parentName;
			end
		else
			if string.len(extraTypeName) > 0 then
				retName = objClassName .. cfgNameFormatStringBetweenBrackets .. "(" .. extraTypeName .. ") ";
			else
				retName = objClassName;
			end
		end
	elseif cfgNameFormatInSyncDataForInstances == opt_sync_data_parent_class_name_as_second then
		if string.len(parentName) > 0 then
			if string.len(extraTypeName) > 0 then
				retName = extraTypeName .. cfgNameFormatStringBetweenBrackets .. "(" .. parentName .. ") ";
			else
				retName = parentName;
			end
		else
			if string.len(extraTypeName) > 0 then
				retName = extraTypeName .. cfgNameFormatStringBetweenBrackets .. "(" .. objClassName .. ") ";
			else
				retName = objClassName;
			end
		end
	else
		local errorMsg = "editor:getNameForDump - Invalid cfgNameFormatInSyncDataForInstances value.";
		logger:error(errorMsg);
		retName = errorMsg;
	end
	
	-- Add also custom name
	if string.len(objName) > 0 then
		retName = retName .. " \"" .. objName .. "\"";
	end
	
	return retName;
end

function getNameForDumpComponentType(obj)
	local retName = "";
	local objClassName = tostring(obj:getClassName());
	local objName = getObjectName(obj);
	local parentName = getParentName(obj);
	
	-- If parent name is the same, don't use it
	if string.len(parentName) > 0 and parentName == objName then
		parentName = "";
	end

	if cfgNameFormatInSyncDataForTypes == opt_sync_data_class_name_as_first then
		if string.len(objName) > 0 then
			retName = objName .. " \"" .. objClassName .. "\"";
		else
			retName = objClassName;	
		end
	elseif cfgNameFormatInSyncDataForTypes == opt_sync_data_class_name_as_second then
		if string.len(objName) > 0 then
			retName = objClassName .. " \"" .. objName .. "\"";
		else
			retName = objClassName;	
		end
	elseif cfgNameFormatInSyncDataForTypes == opt_sync_data_parent_class_name_as_first then
		if string.len(objName) > 0 and string.len(parentName) > 0 then
			retName = objClassName .. " \"" .. parentName .. cfgNameFormatStringBetweenBrackets .. "(" .. objName .. ")\"";
		elseif string.len(objName) > 0 then
			retName = objClassName .. " \"" .. objName .. "\"";
		else
			retName = objClassName;	
		end
	elseif cfgNameFormatInSyncDataForTypes == opt_sync_data_parent_class_name_as_second then
		if string.len(objName) > 0 and string.len(parentName) > 0 then
			retName = objClassName .. " \"" .. objName .. cfgNameFormatStringBetweenBrackets .. "(" .. parentName .. ")\"";
		elseif string.len(objName) > 0 then
			retName = objClassName .. " \"" .. objName .. "\"";
		else
			retName = objClassName;	
		end
	else
		local errorMsg = "editor:getNameForDumpComponentType - Invalid cfgNameFormatInSyncDataForTypes value.";
		logger:error(errorMsg);
		retName = errorMsg;
	end
	return retName;
end

function getNameForDumpComponent(obj)
	return getNameForDump(obj, true);
end

function getNameForDumpBranchHeader(obj)
	return getNameForDump(obj, false);
end

function dumpComponent(obj, humanreadable)
	local ret = {};
		
	local id = "";
	if (not(humanreadable)) then
		id = "["..tostring(obj:getGuid());

		id = id .. ",FLAGS,";
		if (obj:getStringFlags() == "") then
			id = id .. "Editor_Selectable";
		else
			id = id .. obj:getStringFlags() .. "|Editor_Selectable";
		end
		
		id = id .. "]";
	end
	
	table.insert(ret, id .. getNameForDumpComponent(obj));
	table.insert(ret, "{");

	tableConcat(ret, dumpClass(obj, humanreadable));

	do -- subcomponents
		-- assume it is an instance
		local compid = "";
		if (not(humanreadable)) then
			compid = "["..tostring(obj:getGuid())..",COMP]";
		end
		table.insert(ret, compid .. "components");
		table.insert(ret, "{");
		local iter = nil;
		if (obj.getComponents) then
			iter = ComponentVectorIterator(obj:getComponents());			
			if (iter:hasInitFailed()) then
				logger:error("ComponentVectorIterator creation failed for an unknown reason. Object class name was: " .. obj:getClassName());
			end
		else
			logger:error("Object did not have getComponents, probably attempted to create the component iterator for a non-instance object. Object class name was: " .. obj:getClassName());
		end
		local childComp = iter:next();
		while (not(childComp == nil)) do
			
			tableConcat(ret, dumpComponent(childComp, humanreadable));
			
			childComp = iter:next();
		end
		table.insert(ret, "}");
	end -- subcomponents
	
	table.insert(ret, "}");
	
	return ret;
end

local insideDumpReferredDepth = 0

function dumpComponentType(typeUH, humanreadable)
	local typeObj = typeManager:getTypeByUH(typeUH)
	if typeObj == nil then
		local ret = {}
		table.insert(ret, "(missing component type)")
		return ret
	else
		local ret = {}

		local id = ""
		if not humanreadable then
			id = "["..tostring(typeObj:getGuid())

			local flags = "EditorHint_ComponentType"
			
			-- Add string flags
			if (typeObj:getStringFlags() ~= "") then
				flags = typeObj:getStringFlags() .. "|" .. flags
			end
			
			-- add shared flag
			if typeObj.isSharedComponentType and typeObj:isSharedComponentType() then
				flags = flags .. "|EditorHint_SharedComponentType"
			end
			
			if(#flags > 0) then
				id = id .. ",FLAGS," .. flags
			end
			
			id = id .. "]"
		end	
	
		table.insert(ret, id .. getNameForDumpComponentType(typeObj))
		table.insert(ret, "{")

		tableConcat(ret, dumpClass(typeObj, humanreadable))
		
		-- types have subcomponentttypes...
		do
			local compid = ""
			if not humanreadable then
				compid = "["..tostring(typeObj:getGuid())..",COMPTYPES]"
			end	
			table.insert(ret, compid .. "componenttypes")
			table.insert(ret, "{")
			local iter = TypeComponentIterator(typeObj)
			local childCompType = iter:next()
			while not(childCompType == nil) do
				tableConcat(ret, dumpComponentType(childCompType, humanreadable))
				
				childCompType = iter:next()
			end
			
			-- dump UH (GUID) refereces to other component types for certain component types (namely particles, possibly something else as well)			
			tableConcat(ret, dumpReferredComponentTypes(typeObj:getUnifiedHandle(), humanreadable))

			table.insert(ret, "}")
		end -- subcomponent types
		
		table.insert(ret, "}")
		
		return ret
	end
end


function dumpReferredComponentTypes(typeUH, humanreadable)
	insideDumpReferredDepth = insideDumpReferredDepth + 1
	
	local typeObj = typeManager:getTypeByUH(typeUH)
	local ret = {}
	if typeObj == nil then
		logger:error("Failed to find component type object with given UH.")
	else
		local dumpAllRefs = false
		local dumpFlaggedRefs = true
		
		-- particles dump references
		-- There is "EditorHint_ExpandReferences" flag checked for each of the properties, and if some prop has the flag, then that gets dumped here
		-- TODO: Also, it would be useful to have some right click context menu item "Expand Reference" or such, that would temporarily flag the specific reference (just some lua variable/array holding the expanded UHs/props?),
		-- and then re-dump the selected object to get it expanded
		if typeObj:getClassName() == "AbstractParticleEffectCollectionType" then
			dumpAllRefs = true
		end		
		--particleEffectCollectionComponentType = typeManager:findTypeByName("ParticleEffectCollectionComponent")
		--if typeObj:doesInheritType(particleEffectCollectionComponentType) then		
		--	dumpAllRefs = true
		--end		

		if (dumpAllRefs or dumpFlaggedRefs) then
			-- collect all property references that we would like to dump
			local refsToDump = {}
			local maxProp = typeObj:getNumProperties();
			for i = 1,maxProp do
				local propTypeString = typeObj:getPropertyTypeString(i - 1)
				local isUHProp = (propTypeString == "UH")	
				local isUHArrayProp = (propTypeString == "UHPropertyArray")
				if (isUHProp or isUHArrayProp) then
					local dumpThisRef = false
					if dumpAllRefs then
						dumpThisRef = true
					else
						if dumpFlaggedRefs then
							local flags = typeObj:getPropertyStringFlags(i - 1)
							local expandFlagPos = flags:find("EditorHint_ExpandReferences", 1, true)
							if (expandFlagPos) then
								dumpThisRef = true
							end
						end
					end

					-- never allow the Guid property to be expanded ("self reference")
					local propName = typeObj:getPropertyName(i - 1)
					if (propName == "Guid") then
						dumpThisRef = false
					end
					
					if dumpThisRef then
						if (isUHProp) then
							-- single UH ref
							local refUH = typeObj:getPropertyValue(i - 1)
							local alreadyOnTheList = false
							for checki,checkv in ipairs(refsToDump) do
								if (checkv == refUH) then
									alreadyOnTheList = true
								end
							end
							if not alreadyOnTheList then
								table.insert(refsToDump, refUH)
							end
						end
						if (isUHArrayProp) then
							-- array of UH refs
							local uhTable = typeObj:getPropertyValue(i - 1)
							local uhTableSize = uhTable:getSize()
							for i = 0,uhTableSize-1 do
								local refUH = uhTable:get(i)
								local alreadyOnTheList = false
								for checki,checkv in ipairs(refsToDump) do
									if (checkv == refUH) then
										alreadyOnTheList = true
									end
								end
								if not alreadyOnTheList then
									table.insert(refsToDump, refUH)
								end
							end
						end
					end
				end				
			end		

			-- dump em
			for i = 1,#refsToDump do
				local referredCompTypeUH = refsToDump[i]
				-- ignore UH_NONEs
				if (referredCompTypeUH ~= UH_NONE) then
					-- ignore any cyclic dependencies to self
					if (referredCompTypeUH ~= typeUH) then
						-- ignore references to final owner too (TODO: should make a more thorough check, one that considers mid-owner components too)
						local typeObjFinalOwner = typeObj
						local finalOwnerUH = typeUH
						if (typeObj.getFinalOwner) then
							typeObjFinalOwner = typeObj:getFinalOwner()
							finalOwnerUH = typeObjFinalOwner:getUnifiedHandle()
						end					
						if (referredCompTypeUH ~= finalOwnerUH) then
							-- even more failsafe, cut any reference expansion that seems to go way too deep
							if (insideDumpReferredDepth < 5) then
								tableConcat(ret, dumpComponentType(referredCompTypeUH, humanreadable))
							else
								logger:warning("Encountered an expanded component type reference that was recursing too deep. Preventing stack overflow by stopping further reference expansion.")
							end
						end
					end
				end
			end
		end
	end		

	insideDumpReferredDepth = insideDumpReferredDepth - 1
	
	return ret
end


function getReadableGUIDString(guid)
	local str = "";
	local obj = convertGUIDToObject(guid);
	if(obj)
	then
		str = getNameWithoutFolder(obj:getName());
		if(#str > 0) then str = str .. " " end
		local typename = getInstanceTypeName(obj);
		if(#typename > 0) then str = str .. typename .. " " end
	end
	str = str .. tostring(guid);
	return str
end


function convertUHtoGUID(parentObj, uh)
	if not(uh == UH_NONE) then
		local refobj = nil;
		if (typeManager:isType(uh)) then
			refobj = typeManager:getTypeByUH(uh);
		elseif (resourceManager:isResource(uh)) then
			refobj = resourceManager:getResourceByUH(uh);
			-- try to find DummyResourceHolder
			if (not refobj) then
				refobj = resourceManager:getDummyResourceByUH(uh);
			end
		else
			if(parentObj:isInherited(engine.base.InstanceBase.getStaticObjectClass()))
			then
				refobj = parentObj:getInstanceManager():getInstanceByUH(uh);
			else
				logger:error("Type or resource cannot refer to an instance!");
			end
		end			
		if (refobj) then
			return refobj:getGuid();
		else
			logger:warning("editor.convertUHtoGUID - The object referred by " .. tostring(uh) ..  " does not exist so no GUID can be solved for it. Parent: " .. parentObj:getName() );
		end
	end
	return GUID_NONE;
end

function convertSCHtoGUID(sch)
	local scene = instanceManager:getInstanceByUH(sch:getContextSceneUH());
	if(scene)
	then
		local obj = scene:getSceneInstanceManager():getInstanceByUH(sch:getUH());
		if(obj)
		then
			return obj:getGuid();
		else
			return GUID_NONE;
		end
	else
		return GUID_NONE;
	end
end

function convertSCHtoGUIDInSpecificState(sch, stateUH)
	if (state:getUnifiedHandle() ~= stateUH) then
		if (state:isEditorState()) then
			-- apparently this warning is annoying people and needs to be removed.
			--logger:warning("Attempt to solve a GUID for an object under different state. (Currently running script in editor state, but the global context handle referred to an object that is probably in the game state.)")
		else
			logger:warning("Attempt to solve a GUID for an object under different state. (Currently running script in game state, but the global context handle referred to an object that is probably in the editor state.)")
		end
		return GUID_NONE
	end
	
	local scene = instanceManager:getInstanceByUH(sch:getContextSceneUH());
	if(scene)
	then
		local obj = scene:getSceneInstanceManager():getInstanceByUH(sch:getUH());
		if(obj)
		then
			return obj:getGuid();
		else
			return GUID_NONE;
		end
	else
		return GUID_NONE;
	end
end

function convertGCHtoGUID(gch)
	-- TODO: need to bind global object manager.. even then this probably won't work because it's running at state context?
	local stateUH = gch:getContextStateUH()
	return convertSCHtoGUIDInSpecificState(gch:getStateHandle(), stateUH)
end


-- dumps either a CustomStruct or CustomStructArray flagged property.
-- (such properties are "virtual" properties that make a combo of up to 4 different properties in the object based on the virtual property specification string)
function dumpCustomStructProp(obj, humanreadable, i)
	local ret = {}
	local flags = obj:getPropertyStringFlags(i - 1)

	local infoStr = nil
	if (obj:getPropertyTypeString(i - 1) == "DynamicString") or (obj:getPropertyTypeString(i - 1) == "TemporaryHeapString") then
		local infoStr = tostring(obj:getPropertyValue(i - 1))
	else
		logger:error("Custom struct properties must be of string type and the string must contain appropriate information about the struct mapping.");
	end

	if (string.find(flags, "EditorHint_CustomStructArray", 1, true)) then

		local typeInfo = ""
		local propertyMappingInfo = ""
		local curveInfo = ""
		-- TODO: get the CurveInfo=... data from the property value
		local typeArray = {}
		local propertyMappingArray = {}
	
		local customStructInfoStr = obj:getPropertyValue(i - 1)
		local infoSplitted = split_compat(customStructInfoStr, ";")
		for infNum=1,#infoSplitted do
			local infoEntrySplitted = split_compat(infoSplitted[infNum], "=", 2)
			local infoKey = infoEntrySplitted[1]
			local infoValue = infoEntrySplitted[2]
			-- FIXME: this does not handle re-ordering of the values (in case they were incorrectly ordered in the info)
			-- (in other words, first specifying Value2 and the Value1 in the string will cause them to get incorrectly reversed)
			if (infoKey == "Value1" or infoKey == "Value2" or infoKey == "Value3" or infoKey == "Value4") then
				local valueTypeAndMapping = split_compat(infoValue, ",", 2)
				if (string.len(typeInfo) > 0) then
					typeInfo = typeInfo .. ","
				end
				table.insert(typeArray, valueTypeAndMapping[1])
				typeInfo = typeInfo .. valueTypeAndMapping[1]					
				if (string.len(propertyMappingInfo) > 0) then
					propertyMappingInfo = propertyMappingInfo .. ","
				end
				table.insert(propertyMappingArray, valueTypeAndMapping[2])
				propertyMappingInfo = propertyMappingInfo .. valueTypeAndMapping[2]
			end
			if infoKey == "CurveInfo" then
				curveInfo = infoValue
			end
		end
		
		local entries = { }

		-- first solve the array size and check that all of the array sizes match
		local arraySize = 0
		local propArrays = {}
		local sizeMismatch = false
		for fieldIndex = 1,#propertyMappingArray do
			local propIndex = obj:findPropertyIndexByName(propertyMappingArray[fieldIndex])

			if propIndex ~= -1 then
				local a = obj:getPropertyValue(propIndex)
				table.insert(propArrays, a)
				local tmpSize = a:getSize()
				if fieldIndex == 1 then
					arraySize = tmpSize
				else
					if arraySize ~= tmpSize then
						logger:error("CustomStruct property array sizes do not match! (Size of " .. propertyMappingArray[1] .. " is " .. tostring(arraySize) .. ", but size of " .. propertyMappingArray[fieldIndex] .. " is " .. tostring(tmpSize) .. ".)")
						sizeMismatch = true
					end
				end
			end
		end

		if sizeMismatch then
			arraySize = 0
			-- TODO: should probably just fix the arrays by padding too short ones with empty... (to prevent data loss disaster here)
			--flags = flags .. "|" .. "EditorHint_Error" -- or something like that.
		end
		
		-- then iterate them all dumping the values to the list...
		for arrIndex = 1,arraySize do
			local entryFieldValues = ""
			for fieldIndex = 1,#propertyMappingArray do
				if (fieldIndex > 1) then
					entryFieldValues = entryFieldValues .. ", "
				end
				local propArray = propArrays[fieldIndex]
				local val = propArray:get(arrIndex - 1)
				local valueAsString = tostring(val)
				-- HACK: allow VC3 -> TCB conversion here
				-- TODO: should probably really allow all kinds of value type re-mappings here as long as the component counts are the same (even VC3 -> COL?)
				-- (but then it would require the same mapping when setting the custom struct values too)
				if (typeArray[fieldIndex] == "TCB") then
					-- TODO: check if val is VC3
					valueAsString = "TCB(" .. tostring(val.x) .. "," .. tostring(val.y) .. "," .. tostring(val.z) .. ")"
				end
				entryFieldValues = entryFieldValues .. valueAsString
			end
			table.insert(entries, entryFieldValues)
		end
		
		local structValuesArray = "CustomStructArray(\""..typeInfo.."\", \""..propertyMappingInfo.."\", \""..curveInfo.."\", { "
		local allEntriesString = ""
		for entryNum = 1,#entries do
			if (entryNum > 1) then
				allEntriesString = allEntriesString .. ", "
			end
			allEntriesString = allEntriesString .. "CustomStruct(\""..typeInfo.."\", "..entries[entryNum]..")"
		end
		structValuesArray = structValuesArray .. allEntriesString
		structValuesArray = structValuesArray .. " })"
		
		local tmp = obj:getPropertyName(i - 1) .. " = " .. structValuesArray
		
		local id = "";
		if not humanreadable then
			id = "["..tostring(obj:getGuid())..",PROP,"..(i-1)..",TYPE,CustomStructArray,FLAGS,"..flags.."]"
		end
		table.insert(ret, id .. tmp)	
	else
		-- TODO: Add custom struct support, see below test case data for sample (and above array version too)
		logger:error("TODO - CustomStruct property type not yet supported. Only CustomStructArray.")
		
		-- TEMP: just some test case
		--local structValue = "CustomStruct(\"VC3,Time\", VC3(0,0,0), Time('0'))"		
		--local tmp = obj:getPropertyName(i - 1) .. " = " .. structValue		
		--local id = "";
		--if not humanreadable then
		--	id = "["..tostring(obj:getGuid())..",PROP,"..(i-1)..",TYPE,CustomStruct,FLAGS,"..flags.."]"
		--end
		--table.insert(ret, id .. tmp)	
	end
	
	return ret
end


function dumpProp(obj, humanreadable, i)
	local ret = {}
	local flags = obj:getPropertyStringFlags(i - 1)
	
	-- Note, this matches both "EditorHint_CustomStruct" and "EditorHint_CustomStructArray"
	if (string.find(flags, "EditorHint_CustomStruct", 1, true)) then
		-- this is a virtual custom struct property, handle specially (not supported for human readable)
		if (not humanreadable) then
			return dumpCustomStructProp(obj, humanreadable, i)
		end
	end

	-- add shared flag
	if obj.isSharedComponentType then
		if flags and #flags > 0 then
			flags = flags .. "|"
		end
		flags = flags .. "EditorHint_ComponentType"
		
		-- add instance class id flag
		local icid = obj:getInstanceClassId()
		flags = flags .. "|EditorHint_ComponentTypeInstanceClassId_" .. icid:getString()
		
		if(obj:isSharedComponentType()) then
			flags = flags .. "|EditorHint_SharedComponentType"
		end
	end

	-- add not-inherited flag
	if(obj:isPropertyValueInherited(i - 1)) then
		if(#flags > 0) then
			flags = flags .. "|"
		end
		flags = flags .. "PropertyValueInherited"
	
	else
		-- this is an instance
		if obj.getType then
			if flags and #flags > 0 then
				flags = flags .. "|"
			end
			flags = flags .. "EditorHint_ModifiedInstanceProperty"
		end
	end
	

	-- flag Conn_Out if connections out
	if(externalUI:getVisualizePropertyConnections()) then
		if(propertyAnimationModule:doesPropertyHaveConnectionsOut(obj:getUnifiedHandle(), obj:getPropertyName(i - 1))) then
			if(#flags > 0) then
				flags = flags .. "|"
			end
			-- Note, intentional prop conn "Out" when talking about connection "input" here.
			if(propertyAnimationModule:doesPropertyHaveMultipleConnectionsOut(obj:getUnifiedHandle(), obj:getPropertyName(i - 1))) then
				-- FIXME: these Out ref counts seem to be buggy or their handling in the editor gui has some bugs.
				--flags = flags .. "EditorHint_Conn_Out|EditorHint_Conn_MultipleOut"
				flags = flags .. "EditorHint_Conn_Out"
			else
				flags = flags .. "EditorHint_Conn_Out"
			end
		end
		
		-- flag Conn_In if connections in
		if(propertyAnimationModule:doesPropertyHaveConnectionsIn(obj:getUnifiedHandle(), obj:getPropertyName(i - 1))) then
			if(#flags > 0) then
				flags = flags .. "|"
			end
			-- Note, intentional prop conn "In" when talking about connection "output" here.
			if(propertyAnimationModule:doesPropertyHaveMultipleConnectionsIn(obj:getUnifiedHandle(), obj:getPropertyName(i - 1))) then
				flags = flags .. "EditorHint_Conn_In|EditorHint_Conn_MultipleIn"
			else
				flags = flags .. "EditorHint_Conn_In"
			end
		end
	end
	
	-- UHs must be converted to GUID for editing...
	local isUHProp = (obj:getPropertyTypeString(i - 1) == "UH")
	local isSCHProp = (obj:getPropertyTypeString(i - 1) == "StateContextHandle")
	local isGCHProp = (obj:getPropertyTypeString(i - 1) == "GlobalContextHandle")
	if(isUHProp or isSCHProp or isGCHProp) then
		local objGuid;
		if(isUHProp)
		then
			objGuid = convertUHtoGUID(obj, obj:getPropertyValue(i - 1));
		elseif(isSCHProp) then
			objGuid = convertSCHtoGUID(obj:getPropertyValue(i - 1))
		else
			objGuid = convertGCHtoGUID(obj:getPropertyValue(i - 1))
		end
		
		local tmp = obj:getPropertyName(i - 1) .. " = " .. getReadableGUIDString(objGuid)
		
		local id = ""
		if not humanreadable then
			id = "["..tostring(obj:getGuid())..",PROP,"..(i-1)..",TYPE,GUID,FLAGS,"..flags.."]"
		end
	
		table.insert(ret, id .. tmp)
	else
		local tmp = ""

		-- UHs must be converted to GUID for editing...
		if obj:getPropertyTypeString(i - 1) == "UHPropertyArray" then
			tmp = obj:getPropertyName(i - 1) .. " = UHPropertyArray({"
			local uhTable = obj:getPropertyValue(i - 1)
			local uhTableSize = uhTable:getSize()
			for i = 0,uhTableSize-1 do
				local uh = uhTable:get(i)
				tmp = tmp .. getReadableGUIDString(convertUHtoGUID(obj, uh))
				if(i+1 < uhTableSize) then
					tmp = tmp .. ", "
				end
			end
			tmp = tmp .. "})"
			
		elseif obj:getPropertyTypeString(i - 1) == "StateContextHandlePropertyArray" then
			tmp = obj:getPropertyName(i - 1) .. " = StateContextHandlePropertyArray({"
			local uhTable = obj:getPropertyValue(i - 1)
			local uhTableSize = uhTable:getSize()
			for i = 0,uhTableSize-1 do
				local uh = uhTable:get(i)
				tmp = tmp .. getReadableGUIDString(convertSCHtoGUID(uh))
				if(i+1 < uhTableSize) then
					tmp = tmp .. ", "
				end
			end
			tmp = tmp .. "})"
			
		elseif obj:getPropertyTypeString(i - 1) == "GlobalContextHandlePropertyArray" then
			tmp = obj:getPropertyName(i - 1) .. " = GlobalContextHandlePropertyArray({"
			local uhTable = obj:getPropertyValue(i - 1)
			local uhTableSize = uhTable:getSize()
			for i = 0,uhTableSize-1 do
				local uh = uhTable:get(i)
				tmp = tmp .. getReadableGUIDString(convertGCHtoGUID(uh))
				if(i+1 < uhTableSize) then
					tmp = tmp .. ", "
				end
			end
			tmp = tmp .. "})"
			
		elseif (obj:getPropertyTypeString(i - 1) == "DynamicStringPropertyArray") or (obj:getPropertyTypeString(i - 1) == "TemporaryHeapStringPropertyArray") then
			tmp = obj:getPropertyName(i - 1) .. " = " .. obj:getPropertyTypeString(i - 1) .. "({"
			local stringTable = obj:getPropertyValue(i - 1)
			local stringTableSize = stringTable:getSize()
			for i = 0,stringTableSize-1 do
				local str = editor.Util.escapeQuotesAndBackslashes(stringTable:get(i))
				local str = editor.Util.escapeLineBreaks(str)
				tmp = tmp .. "\"" .. tostring(str) .. "\""
				if i+1 < stringTableSize then
					tmp = tmp .. ", "
				end
			end
			tmp = tmp .. "})"
			
		elseif (obj:getPropertyTypeString(i - 1) == "DynamicString") or (obj:getPropertyTypeString(i - 1) == "TemporaryHeapString") then
			local escapedStrValue = editor.Util.escapeQuotesAndBackslashes(tostring(obj:getPropertyValue(i - 1)))
			local escapedStrValue = editor.Util.escapeLineBreaks(escapedStrValue)
			tmp = obj:getPropertyName(i - 1) .. " = \"" .. escapedStrValue .. "\""
		else
			tmp = obj:getPropertyName(i - 1) .. " = " .. tostring(obj:getPropertyValue(i - 1))
		end
		
		-- add enum choices
		if obj:getPropertyTypeString(i - 1) == "Enum" then
			local enumStrings = obj:getEnumPropertyStrings(i - 1)
			for idx,v in pairs(enumStrings) do
				if(#v > 0) then
					if(#flags > 0) then
						flags = flags .. "|"
					end
					flags = flags .. "EnumOption_" .. v
				end
			end
		end
		
		local id = "";
		if not humanreadable then
			id = "["..tostring(obj:getGuid())..",PROP,"..(i-1)..",TYPE,"..obj:getPropertyTypeString(i - 1)..",FLAGS,"..flags.."]"
		end

		table.insert(ret, id .. tmp)
	end
	return ret
end


function dumpProps(obj, humanreadable)
	local ret = {};
	
	if(clearEditorSyncDirtyFlagsForObject) then
		clearEditorSyncDirtyFlagsForObject(obj)
	end

	local maxProp = obj:getNumProperties();
	for i = 1,maxProp do
		tableConcat(ret, dumpProp(obj, humanreadable, i));
	end

	return ret;
end


function dumpBranchHeader(ret, obj, humanreadable, maxDepth)
	local id = "";
	if not humanreadable then	
		local guidid = tostring(obj:getGuid());
		
		guidid = guidid .. ",FLAGS,";
		if obj:getStringFlags() == "" then
			guidid = guidid .. "Editor_Selectable";
		else
			guidid = guidid .. obj:getStringFlags() .. "|Editor_Selectable";
		end

		-- Test hack
		--[[
		if obj:isInherited(engine.base.InstanceBase.getStaticObjectClass()) then
			if filteringModule:doesNodeMatchMultiLevelFilter(obj, filteringModule:getInstanceFilterString()) then
				guidid = guidid .. "|EditorHint_Tag_Warning";
			end
		end
		]]--

		-- add error flags if any
		if obj.getErrors then
			if obj:getErrors() > 0 then
				guidid = guidid .. "|EditorHint_Tag_Error";
			else
				if obj:getChildErrorsExist() then
					guidid = guidid .. "|EditorHint_Tag_Error";
					--guidid = guidid .. "|EditorHint_Tag_ChildError";
				else
					if obj:getWarnings() > 0 then
						guidid = guidid .. "|EditorHint_Tag_Warning";
					else
						if obj:getChildWarningsExist() then
							guidid = guidid .. "|EditorHint_Tag_Warning";
							--guidid = guidid .. "|EditorHint_Tag_ChildWarning";
						end
					end
				end
			end
			
			if obj:getClassName() == "ModelResource" then
				guidid = guidid .. "|Editor_CanCreateType";
			end
		end
		
		id = "["..guidid.."]";
	end
	
	local classLine = id .. getNameForDumpBranchHeader(obj);

	if (maxDepth == 0) then
		table.insert(ret, "[...]" .. classLine);
	else
		table.insert(ret, classLine);
	end
end

-- note, this has a horrible performance, and it gives bad results because it does not consider that a child object might match
function doesFilteringPass(obj)

	-- any selected object is passed through.
	if obj.findComponent then
		local selCom = obj:findComponent(editor.component.EditorSelectionComponent);
		if selCom then
			if selCom:getSelected() then
				return true
			end
		end
	end

	-- instances
	if obj:isInherited(engine.base.InstanceBase.getStaticObjectClass()) then
		if obj:getClassName() ~= "InstanceRoot" and (obj:getName() ~= "Scene" or obj:getName() ~= "gameScene") then
			if not filteringModule:doesNodeMatchMultiLevelFilter(obj, filteringModule:getInstanceFilterString()) then
				return false;
			end
		end
		return true;
	end
	
	-- note, for types, this kind of filtering totally sucks :)
	-- (the tree is pretty deep, and this method totally ignores any possible matches in children, thus making all 
	-- filters basically always fail early on in the tree)
	-- types
	if obj:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) then
		if obj:getClassName() ~= "TypeRoot" then
			if not filteringModule:doesNodeMatchMultiLevelFilter(obj, filteringModule:getTypeFilterString()) then
				return false;
			end
		end
		return true;
	end
	
	if obj:isInherited(engine.base.resourcebase.ResourceBase.getStaticObjectClass()) then
		if obj:getClassName() ~= "ResourceRoot" then
			if not filteringModule:doesNodeMatchMultiLevelFilter(obj, filteringModule:getResourceFilterString()) then
				return false;
			end
		end
		return true;
	end
	
	-- should never get here
	logger:error("Object type was unsupported.");
	return true;
end

-- helper function for the dumpBranch
function depthIncreasedImpl(retOut, prevObjStack, obj, prevDepth, newDepth, humanreadable)
	if (newDepth ~= prevDepth + 1) then
		-- all iterated nodes should have their parent in the dump
		logger:error("Iteration jumped more than +1 in node depth.");
	end
	
	local childid = "";
	if (not(humanreadable)) then
		childid = "["..tostring(prevObjStack[#prevObjStack]:getGuid())..",CHILDREN]";
	end
	table.insert(retOut, childid .. "children");
	table.insert(retOut, "{")
	
	table.insert(prevObjStack, obj);	
end

-- helper function for the dumpBranch
function depthDecreasedImpl(retOut, prevObjStack, prevDepth, newDepth)
	local i = prevDepth
	while (i > newDepth) do
		table.insert(retOut, "}"); -- close the self scope
		table.insert(retOut, "}"); -- close the enclosing children scope
		table.remove(prevObjStack);
		i = i - 1
	end
end


function belongToPropertyAnimationGroup(typeUH)
	if not propertyAnimationComponentType or not propertyConnectionType then
		propertyAnimationComponentType = typeManager:findTypeByName("AbstractPropertyAnimationComponent")
		propertyConnectionType = typeManager:findTypeByName("AbstractPropertyConnectionComponent")
	end
	if not propertyAnimationComponentType or not propertyConnectionType then
		logger:error("Could not find AbstractPropertyAnimationComponent or AbstractPropertyConnectionComponent type")
		return false
	end
	local typ = typeManager:getTypeByUH(typeUH)
	if typ and (typ:doesInheritType(propertyAnimationComponentType) or typ:doesInheritType(propertyConnectionType)) then
		return true
	end
	return false
end

function getNumChildrenWithFilter(obj, filterString)
	local numResults = 0;
	if(obj:getNumChildren() > 0)
	then
		local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilterWithDepth(obj, filterString, editor.Editor.InfiniteDepth, true)
		local resultEntry = resultIterator:next()
		while resultEntry do
			if (resultEntry:getDepth() == 1) then
				numResults = numResults + 1
			end
			resultEntry = resultIterator:next()
		end
	end
	return numResults
end

function dumpBranch(obj, humanreadable, maxDepth, propsDepth, compsDepth, filterString)
	-- new, filter using version of the branch sync data dump...
	local ret = {}
	
	if (filterString == nil) then
		logger:error("dumpBranch is expecting a filter string parameter.")
		return ret
	end

	local originalCompsDepth = compsDepth
	local originalPropsDepth = propsDepth
	
	-- parent stack
	local prevObjStack = {}
	
	local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilterWithDepth(obj, filterString, editor.Editor.InfiniteDepth, true)
	local resultEntry = resultIterator:next()
	
	if resultEntry == nil then
		return ret
	end
	local startDepth = resultEntry:getDepth()
	local atDepth = startDepth

	assert(startDepth == 0)
	
	table.insert(prevObjStack, resultEntry:getTreeNode())
	
	while resultEntry do
		if resultEntry:getDepth() <= maxDepth then
			local obj = resultEntry:getTreeNode()

			local maxDepthHax = maxDepth
			if resultEntry:getDepth() == maxDepth then
				maxDepthHax = 0
			end
			
			dumpBranchHeader(ret, obj, humanreadable, maxDepthHax)
			
			table.insert(ret, "{")

			if resultEntry:getDepth() == maxDepth then
				local ns = getNumChildrenWithFilter(obj, filterString);
				table.insert(ret, "[TOTALCHILDREN," .. tostring(ns) .. "]")
			end

			if propsDepth > 0 then
				tableConcat(ret, dumpClass(obj, humanreadable))
			end
		 
			 if compsDepth > 0 then
				-- different handling for instance vs type..
				if obj:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()) then
					-- types have componentttypes...
					local compid = ""
					if not humanreadable then
						compid = "["..tostring(obj:getGuid())..",COMPTYPES]"
					end
					local propertyAnimationComponentTypes = { }
					table.insert(ret, compid .. "componenttypes")
					table.insert(ret, "{")
					local iter = TypeComponentIterator(obj)
					local childCompType = iter:next()
					while not (childCompType == nil) do
						if belongToPropertyAnimationGroup(childCompType) then
							table.insert(propertyAnimationComponentTypes, childCompType)
						else
							tableConcat(ret, dumpComponentType(childCompType, humanreadable))
						end
						childCompType = iter:next()
					end
					if # propertyAnimationComponentTypes ~= 0 then
--						local guidStr = "[GUID('0x00000000','0x00000000','0x00000000','0x00000000'),"
						local guidStr = "[" .. tostring(obj:getGuid()) .. ","
						table.insert(ret, guidStr .. "FLAGS,EditorHint_Icon_PropertyAnimationComponent|EditorHint_ComponentType]PropertyAnimationComponents \"Property animation components\"")
						table.insert(ret, "{")
						table.insert(ret, guidStr .. "PROPS]properties")
						table.insert(ret, "{")
						table.insert(ret, guidStr .. "PROP,0,TYPE,DynamicString,FLAGS,ReadOnly|ExcludeFromType|EditorHint_ComponentType|EditorHint_ComponentTypeInstanceClassId_CLuC|PropertyValueInherited]Property animation component group = \"\"")
						table.insert(ret, "}")
						table.insert(ret, guidStr .. "COMPTYPES]componenttypes")
						table.insert(ret, "{")
						for key, value in pairs(propertyAnimationComponentTypes) do
							tableConcat(ret, dumpComponentType(value, humanreadable))
						end
						table.insert(ret, "}")
						table.insert(ret, "}")
					end

					-- dump UH (GUID) refereces to other component types for certain component types (namely particles, possibly something else as well)
					tableConcat(ret, dumpReferredComponentTypes(obj:getUnifiedHandle(), humanreadable))
					
					table.insert(ret, "}")					
				elseif obj:isInherited(engine.base.resourcebase.ResourceBase.getStaticObjectClass()) then
					-- no components at resources?
				elseif obj:isInherited(engine.base.InstanceBase.getStaticObjectClass()) then
					-- assume it is an instance
					local compid = ""
					if not humanreadable then
						compid = "["..tostring(obj:getGuid())..",COMP]"
					end
					table.insert(ret, compid .. "components")
					table.insert(ret, "{")
					local iter = nil
					if obj.getComponents then
						iter = ComponentVectorIterator(obj:getComponents());
						if iter:hasInitFailed() then
							logger:error("ComponentVectorIterator creation failed for an unknown reason. Object class name was: " .. obj:getClassName())
						end
					else
						logger:error("Object did not have getComponents, probably attempted to create the component iterator for a non-instance object. Object class name was: " .. obj:getClassName())
					end
					local propertyAnimationComponents = { }
					local childComp = iter:next()
					while not (childComp == nil) do
						if childComp:isInherited(engine.component.AbstractPropertyAnimationComponent.getStaticObjectClass()) or 
								childComp:isInherited(engine.component.AbstractPropertyConnectionComponent.getStaticObjectClass()) then
							table.insert(propertyAnimationComponents, childComp)
						else
							tableConcat(ret, dumpComponent(childComp, humanreadable))
						end
						childComp = iter:next()
					end
					if # propertyAnimationComponents ~= 0 then
--						local guidStr = "[GUID('0x00000000','0x00000000','0x00000000','0x00000000'),"
						local guidStr = "[" .. tostring(obj:getGuid()) .. ","
						table.insert(ret, guidStr .. "FLAGS,EditorHint_Icon_PropertyAnimationComponent|EditorHint_ComponentType]PropertyAnimationComponents \"Property animation components\"")
						table.insert(ret, "{")
						table.insert(ret, guidStr .. "PROPS]properties")
						table.insert(ret, "{")
						table.insert(ret, guidStr .. "PROP,0,TYPE,DynamicString,FLAGS,ReadOnly|ExcludeFromType|EditorHint_ComponentType|EditorHint_ComponentTypeInstanceClassId_CLuC|PropertyValueInherited]Property animation component group = \"\"")
						table.insert(ret, "}")
						table.insert(ret, guidStr .. "COMP]components")
						table.insert(ret, "{")
						for key, value in pairs(propertyAnimationComponents) do
							tableConcat(ret, dumpComponent(value, humanreadable))
						end
						table.insert(ret, "}")
						table.insert(ret, "}")
					end
					table.insert(ret, "}")
				end
			end
		end
		resultEntry = resultIterator:next()

		if resultEntry then
			local newDepth = resultEntry:getDepth()
			if newDepth <= maxDepth then
				-- modify these max depths based on depth delta (newDepth - atDepth)
				local depthDelta = (newDepth - atDepth)
				propsDepth = propsDepth - depthDelta
				compsDepth = compsDepth - depthDelta
			 	
				if newDepth > atDepth then
					-- the next one is a child for the previous object (assuming newDepth == atDepth + 1)
					depthIncreasedImpl(ret, prevObjStack, resultEntry:getTreeNode(), atDepth, newDepth, humanreadable)
					atDepth = newDepth
				elseif newDepth < atDepth then
					-- the next one is a child to some previously processed grandparent...
					-- now backtrack to that level (closing the object and children sub-scopes in between)
					depthDecreasedImpl(ret, prevObjStack, atDepth, newDepth, humanreadable)
					atDepth = newDepth
					-- then, continue as a child for that parent...
					-- oh and apparently need to close the sibling too at that level.
					table.insert(ret, "}")
				else
					-- the next one is going to be a sibling to the previous object, just close the object scope
					-- (still remaining within the same children sub-scope)
					table.insert(ret, "}")
				end
			end
		end
		
		-- end of branch dump.		
	end

	-- close the latest object scope as it is still open.
	table.insert(ret, "}")

	-- just for assertion...
	local depthDelta = (startDepth - atDepth)
	propsDepth = propsDepth - depthDelta
	compsDepth = compsDepth - depthDelta
	assert(propsDepth == originalPropsDepth)
	assert(compsDepth == originalCompsDepth)
	
	if atDepth > startDepth then
		depthDecreasedImpl(ret, prevObjStack, atDepth, startDepth, humanreadable)
		atDepth = startDepth
	end
	
	if #prevObjStack ~= 1 then
		logger:error("Bug in dumpBranch.")
	end
	table.remove(prevObjStack)
	
	return ret

--[[
	-- the old slow lua dump...

	local ret = {};
	
	-- hack: filtering...
	-- this won't work properly really. as it will filter out the parents of any matching children.
	if (not(doesFilteringPass(obj))) then 
		return ret; 
	end
	
	dumpBranchHeader(ret, obj, humanreadable, maxDepth);
	if (maxDepth == 0) then
		return ret;
	end	
	table.insert(ret, "{");

	if (propsDepth > 0) then
		tableConcat(ret, dumpClass(obj, humanreadable));
	end
 
	 if (compsDepth > 0) then
		-- different handling for instance vs type..	
		if (obj:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()))
		then
			-- types have componentttypes...
			local compid = "";
			if (not(humanreadable)) then
				compid = "["..tostring(obj:getGuid())..",COMPTYPES]";
			end	
			table.insert(ret, compid .. "componenttypes");
			table.insert(ret, "{");
			local iter = TypeComponentIterator(obj);
			local childCompType = iter:next();
			while not (childCompType == nil) do
				
				tableConcat(ret, dumpComponentType(childCompType, humanreadable));
				
				childCompType = iter:next();
			end	
			table.insert(ret, "}");
		elseif (obj:isInherited(engine.base.resourcebase.ResourceBase.getStaticObjectClass()))
		then
			-- no components at resources?
		else
			-- assume it is an instance
			local compid = "";
			if (not(humanreadable)) then
				compid = "["..tostring(obj:getGuid())..",COMP]";
			end
			table.insert(ret, compid .. "components");
			table.insert(ret, "{");
			local iter = nil;
			if (obj.getComponents) then
				iter = ComponentVectorIterator(obj:getComponents());
				if (iter:hasInitFailed()) then
					logger:error("ComponentVectorIterator creation failed for an unknown reason. Object class name was: " .. obj:getClassName());						
				end
			else
				logger:error("Object did not have getComponents, probably attempted to create the component iterator for a non-instance object. Object class name was: " .. obj:getClassName());						
			end
			local childComp = iter:next();
			while (not(childComp == nil)) do
				
				tableConcat(ret, dumpComponent(childComp, humanreadable));
				
				childComp = iter:next();
			end
			table.insert(ret, "}");
		end
	end

	-- has at least one child?	
	local iter = ChildIterator(obj);
	local childInst = iter:next();	
	if (not(childInst == nil)) then
		
			local childid = "";
			if (not(humanreadable)) then
				childid = "["..tostring(obj:getGuid())..",CHILDREN]";
			end
			table.insert(ret, childid .. "children");
			table.insert(ret, "{");
		 
			local iter = ChildIterator(obj);
			local childInst = iter:next();
			while (not(childInst == nil)) do
				
				local newPropsDepth = propsDepth - 1
				if (newPropsDepth < 0) then newPropsDepth = 0 end
				local newCompsDepth = compsDepth - 1
				if (newCompsDepth < 0) then newCompsDepth = 0 end
				tableConcat(ret, dumpBranch(childInst, humanreadable, maxDepth - 1, newPropsDepth, newCompsDepth));
				
				childInst = iter:next();
			end
			table.insert(ret, "}");
	
	end
		
	table.insert(ret, "}");
	
	return ret;
]]--
	
end


function dumpSpecificComponentBranch(obj, humanreadable, componentStack, dumpFunc) 
	
	if (not(componentStack == nil)) then
	
		local ret = {};
			
		dumpBranchHeader(ret, obj, humanreadable, 0);
		table.insert(ret, "{");
		
		if (obj:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()))
		then
			local compid = "";
			if (not(humanreadable)) then
				compid = "["..tostring(obj:getGuid())..",COMPTYPES]";
			end	
			table.insert(ret, compid .. "componenttypes");
		else
			local childid = "";
			if (not(humanreadable)) then
				childid = "["..tostring(obj:getGuid())..",COMP]";
			end
			table.insert(ret, childid .. "components");
		end
		
		table.insert(ret, "{");
		tableConcat(ret, dumpSpecificComponentBranch(componentStack.object, humanreadable, componentStack.next, dumpFunc));
		table.insert(ret, "}");
		
		table.insert(ret, "}");
		return ret;
	else
		return dumpFunc(obj, humanreadable);
	end
	
end


function recursiveReverseComponentBranchDump(obj, compStack, dumpFunc)
	if not(obj.getOwner == nil) and not(obj:getOwner() == nil) then
		local newCompStack = {}
		newCompStack.next = compStack
		newCompStack.object = obj
		return recursiveReverseComponentBranchDump(obj:getOwner(), newCompStack, dumpFunc)
	else
		return dumpSpecificComponentBranch(obj, false, compStack, dumpFunc)
	end
end


function recursiveReverseComponentTypeBranchDump(obj, compStack, dumpFunc)
	local ret = {}
	 
	if obj.getNumComponentTypeOwners and obj:getNumComponentTypeOwners() > 0 then
		local newCompStack = {}
		newCompStack.next = compStack
		newCompStack.object = obj
		local ncto = obj:getNumComponentTypeOwners()
		for i = 0,ncto-1 do
			tableConcat(ret, recursiveReverseComponentTypeBranchDump(obj:getComponentTypeOwner(i), newCompStack, dumpFunc))
		end		
	else
		tableConcat(ret, dumpSpecificComponentBranch(obj, false, compStack, dumpFunc))
	end
	
	return ret
end


function dumpPartialProperties(obj, humanreadable, props)	
	local ret = {};
	dumpBranchHeader(ret, obj, humanreadable, 0);
	table.insert(ret, "{");
		local propsid = "";
		if (not(humanreadable)) then
			propsid = "["..tostring(obj:getGuid())..",PROPS]";
		end	
		table.insert(ret, propsid .. "partialProperties");
		table.insert(ret, "{");
		for idx,v in pairs(props) do 
			tableConcat(ret, dumpProp(obj, humanreadable, v+1));
		end
		table.insert(ret, "}");
	table.insert(ret, "}");
	return ret;
end

function dumpSpecificBranch(obj, humanreadable, childStack, componentStack, filterString)
	local ret = {};

	assert(filterString ~= nil);
	
	if (childStack == nil) then
		-- just dump everything from this point on, too lazy to fix partial updates in UI
		return dumpBranch(obj, humanreadable, 1, 1, 1, filterString);
	end
		
	dumpBranchHeader(ret, obj, humanreadable, 0);
	table.insert(ret, "{");

	if (not(childStack == nil)) then
	
		local childid = "";
		if (not(humanreadable)) then
			childid = "["..tostring(obj:getGuid())..",CHILDREN]";
		end
		table.insert(ret, childid .. "children");
		table.insert(ret, "{");
		tableConcat(ret, dumpSpecificBranch(childStack.object, humanreadable, childStack.next, componentStack, filterString));
		if(obj:getNumChildren() > 1)
		then
			-- partial children update
			local ns = getNumChildrenWithFilter(obj, filterString);
			table.insert(ret, "[TOTALCHILDREN," .. tostring(ns) .. "]")
		end
		table.insert(ret, "}");	
		
--[[
	elseif (not(componentStack == nil)) then
	
		-- tableConcat(ret, dumpClass(obj, humanreadable));	
	
		if (obj:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass()))
		then
			local compid = "";
			if (not(humanreadable)) then
				compid = "["..tostring(obj:getGuid())..",COMPTYPES]";
			end	
			table.insert(ret, compid .. "componenttypes");
		else
			local childid = "";
			if (not(humanreadable)) then
				childid = "["..tostring(obj:getGuid())..",COMP]";
			end
			table.insert(ret, childid .. "components");
		end
		
		table.insert(ret, "{");
		tableConcat(ret, dumpSpecificBranch(componentStack.object, humanreadable, childStack, componentStack.next));
		table.insert(ret, "}");
		
	else
		tableConcat(ret, dumpClass(obj, humanreadable));	
--]]

	end
		
	table.insert(ret, "}");
	
	return ret;
end

function dumpTableToString(dumptable, humanreadable)
	local ret = ""
	-- if (humanreadable) then
	if (false) then
		-- human readable version adds scope indentation
		local i
		local depth = 0;
		for idx,v in pairs(dumptable) do 
			local skipit = false;
			if (v == "}") then depth = depth - 1; end
			if (not skipit) then
				for i = 1,depth do
					ret = ret .. "s";
				end
				ret = ret .. v;
				ret = ret .. "\r\n";
			end
			if (v == "{") then depth = depth + 1; end
		end
	else 
		-- non-human readable version skips indentation because it would make this slower and use bigger buffers
		ret = table.concat(dumptable, "\r\n");
		ret = ret .. "\r\n";
	end
	return ret;	
end


function recursiveReverseTreeDump(obj, childStack, compStack, filterString)
	if not (obj.getOwner == nil) and not (obj:getOwner() == nil) then
		local newCompStack = {};
		newCompStack.next = compStack;
		newCompStack.object = obj;
		return recursiveReverseTreeDump(obj:getOwner(), childStack, newCompStack, filterString);	
	elseif not (obj:getParent() == nil) then
		local newChildStack = {};
		newChildStack.next = childStack;
		newChildStack.object = obj;
		return recursiveReverseTreeDump(obj:getParent(), newChildStack, compStack, filterString);
	else
		return dumpSpecificBranch(obj, false, childStack, compStack, filterString);
	end
end


function dumpSingleObject(obj, filterString)
	local ret = recursiveReverseTreeDump(obj, nil, nil, filterString);
	local str = dumpTableToString(ret, false);
	return str;
end


function dumpSingleObjectPartialProperties(obj, props)
	local ret = {}
	
	-- dump component types recursively from all owners!
	if obj.getNumComponentTypeOwners and obj:getNumComponentTypeOwners() then
		ret = recursiveReverseComponentTypeBranchDump(obj, nil, function(obj, humanr) return dumpPartialProperties(obj,humanr,props) end)
		tableConcat(ret, dumpPartialProperties(obj, false, props))
	else
		-- dump components recursively from owner
		if obj.getOwner and obj:getOwner() then
			ret = recursiveReverseComponentBranchDump(obj, nil, function(obj, humanr) return dumpPartialProperties(obj,humanr,props) end)
			tableConcat(ret, dumpPartialProperties(obj, false, props))
		else
			ret = dumpPartialProperties(obj, false, props)
		end
	end
	
	local str = "[PARTIALUPDATE]\r\n" .. dumpTableToString(ret, false)
	return str
end


function testInstanceDump()
	-- return the instance tree in human readable format
	--collectgarbage("collect");
	local root = instanceManager:getTopmostInstanceRoot();	
	local ret = "Test instance dump:\r\n" .. dumpTableToString(dumpBranch(root, true, editor.Editor.InfiniteDepth, editor.Editor.InfiniteDepth, editor.Editor.InfiniteDepth, filteringModule:getInstanceFilterString()), true);	
	--collectgarbage("collect");
	-- logger:debug(ret);
	return ret;
end

function testTypeDump()
	-- return the type tree in human readable format
	--collectgarbage("collect");
	local root = typeManager:getTypeRoot();	
	local ret = "Test type dump:\r\n" .. dumpTableToString(dumpBranch(root, true, editor.Editor.InfiniteDepth, editor.Editor.InfiniteDepth, editor.Editor.InfiniteDepth, filteringModule:getTypeFilterString()), true);	
	--collectgarbage("collect");
	-- logger:debug(ret);
	return ret;
end

function getInstanceTreeForExternalUI(maxDepth)
	--collectgarbage("collect");
	local root = instanceManager:getTopmostInstanceRoot();	
	local ret = dumpTableToString(dumpBranch(root, false, maxDepth, 0, 0, filteringModule:getInstanceFilterString()), false);
	--collectgarbage("collect");
	return ret;
end

function getTypeTreeForExternalUI(maxDepth)
	--collectgarbage("collect");
	local root = typeManager:getTypeRoot();	
	local ret = dumpTableToString(dumpBranch(root, false, maxDepth, 0, 0, filteringModule:getTypeFilterString()), false);
	--collectgarbage("collect");
	return ret;
end

function getChooseObjectTreeForExternalUI(maxDepth, root, filterString)
	--collectgarbage("collect");
	local ret = dumpTableToString(dumpBranch(root, false, maxDepth, 0, 0, filterString), false);
	--collectgarbage("collect");
	return ret;
end

function getModuleTreeForExternalUI(maxDepth, filterString)
	--collectgarbage("collect");
	local root = moduleTreeManager:getModuleTreeObjectRoot();	
	local ret = dumpTableToString(dumpBranch(root, false, maxDepth, 0, 0, filterString), false);
	--collectgarbage("collect");
	return ret;
end

function getGUI3TreeForExternalUI(maxDepth, filterString)
	if rootWidget == nil then
		logger:error("RootWidget is NIL. GUI <3 is probably disabled in global settings.")
		return "\r\n";
	end
	local root = rootWidget
	local ret = dumpTableToString(dumpBranch(root, false, maxDepth, 0, 0, filterString), false);
	return ret;
end

function addChildToGUI3Widget(parent, widgetTypeName)
	if rootWidget == nil then return; end
	rootWidget:addChildToWidget(parent, widgetTypeName)
end

function addChildToGUI3WidgetFromPrefab(parent, prefabName)
	if rootWidget == nil then return; end
	rootWidget:addChildFromPrefabToWidget(parent, prefabName)
end

function getGUI3PrefabList()
	if rootWidget == nil then return; end
	return rootWidget:getPrefabFilenames();
end

function removeGUI3Widget(self)
	if rootWidget == nil then return; end
	rootWidget:removeWidget(self)
end

function remakeGUI3Widget(self)
	if rootWidget == nil then return; end
	rootWidget:remakeWidget(self)
end

function dragAndDropGUI3Widget(self, parent)
	if rootWidget == nil then return; end
	rootWidget:dragAndDropWidgetToNewParent(self, parent)
end

function canGUI3WidgetBeInherited(self)
	if rootWidget == nil then return false end
	if self == nil then return false end
	return rootWidget:canWidgetBeInherited(self)
end

function prepareGUI3WidgetToBeSavedAsType(self)
	if rootWidget == nil then return; end
	rootWidget:prepareWidgetToBeSavedAsType(self)
end

function saveGUI3WidgetAsPrefab(self)
	if rootWidget == nil then return; end
	rootWidget:saveWidgetAsPrefab(self)
end

function convertGUIDToObject(guid)
	if guid == GUID_NONE then
		return nil;
	end	
	local inst = nil;
	if gameScene then
		local instancemanager = gameScene:getSceneInstanceManager();
	if instancemanager == nil then
		logger:error("editor::convertGUIDToObject - gameScene instancemanager is nil.");
		return nil;
	end
		inst = instancemanager:findInstanceByGUID(guid);
	else
	local instancemanager = scene:getSceneInstanceManager();
	if instancemanager == nil then
		logger:error("editor::convertGUIDToObject - scene instancemanager is nil.");
		return nil;
	end
		inst = instancemanager:findInstanceByGUID(guid);
	end
	if(inst)
	then
		return inst;
	end
	local typo = typeManager:findTypeByGUID(guid);
	if(typo)
	then
		return typo;
	end
	local res = resourceManager:findResourceByGUID(guid);
	if(res)
	then
		return res;
	end
	return nil;
end

function getRecentObjectTreeForExternalUI(baseClass, typeName)
	--collectgarbage("collect");
	if(state.getRecentGUID == nil)
	then
		return "";
	end
	local ret = "";
	local i = 0;
	
	-- TODO: optimize, this should rather be implemented as a (filtered) iterator received from engine directly
	-- for now, doing the filtering here, which is not very effective.
	
	local guid = state:getRecentGUID(i);
	local tbl = {}
	while (not(guid == GUID_NONE))
	do
		local object = convertGUIDToObject(guid);
		if(object and (baseClass == nil or object:isInheritedByClassName(baseClass)) and (typeName == nil or object:doesInheritTypeByName(typeName)))
		then
			-- note, there seems to be a bit of overlap here... :)
			-- the other filtering above is one used by the dialogs, the filtering below is the one user sets by clicking one of the 
			-- editor filter buttons. umm.
			if (filteringModule:doesNodeMatchMultiLevelFilter(object, filteringModule:getRecentFilterString())) then			
				dumpBranchHeader(tbl, object, false, 0);
			end
		end
		i = i + 1;
		guid = state:getRecentGUID(i);
	end
	ret = dumpTableToString(tbl, false);
	--collectgarbage("collect");
	return ret;
end

-- returns the appropriate filter string from the filteringModule for specific object 
-- the selection of the filter string is based on the type of the object, and this really just applies to the tree views.
-- (any other use cases, such as selection, should probably use other filters intended for that case)
function getDefaultFilterStringForObject(obj)
	local ret;
	if (obj:isInherited(engine.base.InstanceBase.getStaticObjectClass())) then	
		ret = filteringModule:getInstanceFilterString()
	elseif (obj:isInherited(engine.base.typebase.TypeBase.getStaticObjectClass())) then
		ret = filteringModule:getTypeFilterString()
	elseif (obj:isInherited(engine.base.resourcebase.ResourceBase.getStaticObjectClass())) then
		ret = filteringModule:getResourceFilterString()
	else
		ret = "0,All";
	end
	return ret;
end

function getObjectTreeForExternalUI(obj, maxDepth, propsDepth, compsDepth, filterString)
	--collectgarbage("collect");
	local ret;
	ret = dumpTableToString(dumpBranch(obj, false, maxDepth, propsDepth, compsDepth, filterString), false);
	--collectgarbage("collect");
	return ret;
end

function appendObjectTreeForExternalUI(ret, obj, maxDepth, propsDepth, compsDepth, filterString)
	--collectgarbage("collect");
	tableConcat(ret, dumpBranch(obj, false, maxDepth, propsDepth, compsDepth, filterString));
	--collectgarbage("collect");
end

function getResourceTreeForExternalUI(maxDepth)
	--collectgarbage("collect");
	--local ret = "[GUID(todo)]ResourceRoot\r\n{\r\n}\r\n";
	local root = resourceManager:getResourceRoot();	
	local ret = dumpTableToString(dumpBranch(root, false, maxDepth, 0, 0, filteringModule:getResourceFilterString()), false);
	--collectgarbage("collect");
	return ret
end

function contextHitObject(objId)
	logger:debug("contextHitObject: "..objId)
	editor.ExternalUI.sceneObjectContextHitted(objId)
end

function selectedObjects(objIdList)
	logger:debug("selectedObjects: "..objIdList);
	editor.ExternalUI.sceneObjectsSelected(objIdList);
end

function selectObject(obj)
	-- DEPRECATED
	logger:error("selectObject deprecated.");
	if (obj) then
		local id = "["..tostring(obj:getGuid()).."]";
		--editor.ExternalUI.sceneObjectSelected(id);
	else
		logger:error("editor.selectObject expects instance object as parameter.");
	end
end

function unselectObject(obj)
	-- DEPRECATED
	logger:error("unselectObject deprecated.");
	if (obj) then
		local id = "["..tostring(obj:getGuid()).."]";
		--editor.ExternalUI.sceneObjectSelected(id);
	else
		logger:error("editor.selectObject expects instance object as parameter.");
	end	
end

function setInstanceTreeFilter(filterString)
	if (filterString == "") then
		logger:error("Someone is trying to set an empty filter string..");
	end
	filteringModule:setInstanceFilterString(filterString);
end

function setTypeTreeFilter(filterString)
	filteringModule:setTypeFilterString(filterString);
end

function setResourceTreeFilter(filterString)
	filteringModule:setResourceFilterString(filterString);
end

function setChooseObjectDialogFilter(filterString)
	filteringModule:setChooseObjectDialogFilterString(filterString);
end

-- helper func for replacing instances
-- the filterResourceName parameter can usually just be "All"
-- requires exact types for typeNameToReplace and typeNameToReplaceWith 
-- note, the typeNameToReplace param is optional, and may be nil, but in that case using the "All" filter is a BIG mistake!
-- the replacer function is the initializer function for the new object, it must also delete the old one (original is given as param).
function replaceInstances(filterResourceName, typeNameToReplace, typeNameToReplaceWith, replacerFunction)
	assert_string(filterResourceName)
	assert_string_or_nil(typeNameToReplace)
	assert_string(typeNameToReplaceWith)
	assert_function(replacerFunction)

	local filterString = "0," .. filterResourceName
	local maxDepth = 99999
	local forceParentsOfMatchesToMatch = false;
	local root = instanceManager:getTopmostInstanceRoot()

	local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilter(root, filterString, maxDepth, forceParentsOfMatchesToMatch)

	local totalObjectsChecked = 0
	local totalObjectsModified = 0

	local obj = resultIterator:next()
	while (obj) do

		local typeUH = obj:getType()
		local type = typeManager:getTypeByUH(typeUH);
		if(type) then
			local typename = type:getName();
			if (typeNameToReplace == nil or typename == typeNameToReplace) then
			
				local newType = typeManager:findTypeByName(typeNameToReplaceWith);
				if (not newType) then 
					logger:error("Failed to find the type \""..typeNameToReplaceWith.."\" to replace with.")
				end
				
				obj:getInstanceManager():createNewInstance(newType:getUnifiedHandle(), replacerFunction, { original=obj } );
				totalObjectsModified = totalObjectsModified + 1
			end
		end

		totalObjectsChecked = totalObjectsChecked + 1
		obj = resultIterator:next()
	end
	
	logger:info("Total ".. tostring(totalObjectsChecked) .. " objects iterated out of which " .. tostring(totalObjectsModified) .. " were modified.")	
end

function seekInstancesWithMultiLevelFilter(multiLevelFilterString, typeNameToSeek, seekResultFunction)
	assert_string(multiLevelFilterString)
	assert_string_or_nil(typeNameToSeek)
	assert_function(seekResultFunction)

	local filterString = multiLevelFilterString
	local maxDepth = 99999
	local forceParentsOfMatchesToMatch = false;
	local root = instanceManager:getTopmostInstanceRoot()

	local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilter(root, filterString, maxDepth, forceParentsOfMatchesToMatch)

	local totalObjectsChecked = 0
	local totalObjectsFound = 0

	local obj = resultIterator:next()
	while (obj) do

		local typeUH = obj:getType()
		local type = typeManager:getTypeByUH(typeUH);
		if(type) then
			local typename = type:getName();
			if (typeNameToSeek == nil or typename == typeNameToSeek) then			
				seekResultFunction(obj);
				totalObjectsFound = totalObjectsFound + 1
				--logger:debug("Accepting type " .. typename)
			else
				--logger:debug("Skipping type " .. typename)
			end
		end

		totalObjectsChecked = totalObjectsChecked + 1
		obj = resultIterator:next()
	end
	
	logger:debug("Total ".. tostring(totalObjectsChecked) .. " objects iterated out of which " .. tostring(totalObjectsFound) .. " were found to be of given type.")	
end

function seekInstances(filterResourceName, typeNameToSeek, seekResultFunction)
	-- Note, this could be optimized, not to use the multi level filter... but assuming that that is not the biggest performance problem anyway
	local filterString = "0," .. filterResourceName
	seekInstancesWithMultiLevelFilter(filterString, typeNameToSeek, seekResultFunction)
end


function superhackReplace()
	function superhackReplacerFunc(obj, params)
		-- put it in center of screen (well, approximately)
		obj:findComponent(engine.component.TransformComponent):setPosition(params.original:findComponent(engine.component.TransformComponent):getPosition());
		obj:findComponent(area.BoxAreaComponent):setOffset(params.original:findComponent(area.BoxAreaComponent):getOffset());
		obj:findComponent(area.BoxAreaComponent):setDimensions(params.original:findComponent(area.BoxAreaComponent):getDimensions());
		local fooType = typeManager:findTypeByName("SuperHackHack1DefaultConstantVectorComponent");
		if (not fooType) then
			logger:error("No SuperHackHack1DefaultConstantVectorComponent type");
		end
		
		local fooType2 = typeManager:findTypeByName("SuperHackHack2DefaultConstantVectorComponent");
		local c = params.original:findComponentByType(fooType:getUnifiedHandle());
		if (not c) then logger:error("No SuperHackHack2DefaultConstantVectorComponent"); end
		local p = c:getOutVector();
		p = VC3(p.x, p.y + 10.0, p.z + 5.0)
		obj:findComponent(trinebase.gameplay.TrineCameraPropertiesComponent):setPositionOffset(p);
		
		local tp = params.original:findComponentByType(fooType2:getUnifiedHandle()):getOutVector();
		tp = VC3(tp.x, tp.y, tp.z + 3.0)										
		obj:findComponent(trinebase.gameplay.TrineCameraPropertiesComponent):setTargetOffset(tp);

		params.original:getInstanceManager():deleteInstance(params.original:getUnifiedHandle());
	end

	replaceInstances("All", "SuperHackHack", "AdvancedCameraAreaEntity", superhackReplacerFunc)
end

-- fixes some old camera areas...
function oldCameraAreaFix()
	function oldCameraAreaFixFunc(obj, params)
		-- fix the target with y depth being 10 meters off, re-project target on zero plane after fix
		local transPos = obj:findComponent(engine.component.TransformComponent):getPosition();
		local targOff = obj:findComponent(trinebase.gameplay.TrineCameraPropertiesComponent):getTargetOffset();
		targOff = VC3(targOff.x, targOff.y - 10.0, targOff.z)
		local posOff = obj:findComponent(trinebase.gameplay.TrineCameraPropertiesComponent):getPositionOffset();
		local targPos = transPos + targOff
		local camPos = transPos + posOff 
		local dirVec = targPos - camPos
		local dirNorm = dirVec:getNormalized()	
		targPos = engine.base.mathbase.util.intersectDirectionOnPlane(camPos, dirNorm, VC3(0,1,0), 0, 99999.0, 0.0)
		targOff = targPos - transPos
		obj:findComponent(trinebase.gameplay.TrineCameraPropertiesComponent):setTargetOffset(targOff);
	end

	seekInstances("All", "AdvancedCameraAreaEntity", oldCameraAreaFixFunc)
end

-- should iterate all, but find none (not even the InstanceRoot,d since it seems to be iterating the scenes only here...)
-- NOTE: not sure if that behaviour was originally intended, or if the iteration can only cope with children of the root.
function dummySeekTest()
	seekInstances("All", "InstanceRoot", function() end)
end

-- should iterate a random amount and consider all of them a found.
function dummySeekTest2()
	seekInstances("RandomFilterTest", nil, function() end)
end


-- returns a singular instance of given type in the scene (or inherited one depending on allowInherited param) 
-- if there is no such instance, or there are multiple instances, returns nil
function findSingleInstanceOfType(typeName, allowInherited)
	assert_string(typeName)
	assert_boolean(allowInherited)
	
	local tmp = { }
	seekInstances("All", nil, 
		function(obj, params)
			local typeObjUH = obj:getType()
			local typeObj = typeManager:getTypeByUH(typeObjUH)
			if (allowInherited) then
				if (typeObj:doesInheritTypeByName(typeName)) then
					table.insert(tmp, obj)
				end
			else
				if (typeObj:getName() == typeName) then
					table.insert(tmp, obj)
				end
			end
		end
	)
	if (#tmp == 1) then
		return tmp[1]
	else
		return nil
	end
end

-- TEST HACK: DON'T USE THIS :)
function deleteAllStaticModels()
	function deleteIfStaticModel(obj, params)
		if (obj:getNumComponents() == 6) then -- assuming it has some visualizers and stuff, this is gonna be the magic number
			if (obj:findComponent(rendering.ModelComponent)) then
				obj:getInstanceManager():deleteInstance(obj:getUnifiedHandle());
			end
		end
	end
	seekInstances("All", nil, deleteIfStaticModel)
end

-- TEST HACK: DON'T USE THIS :)
function deleteAllStaticLights()
	function deleteIfStaticLight(obj, params)
		if (obj:getNumComponents() == 7) then -- assuming it has some visualizers and stuff, this is gonna be the magic number
			if (obj:findComponent(lighting.PointLightComponent)
				or obj:findComponent(lighting.SpotLightComponent)) then
				obj:getInstanceManager():deleteInstance(obj:getUnifiedHandle());
			end
		end
	end
	seekInstances("All", nil, deleteIfStaticLight)
end

function getResourceTopListForExternalUIImpl(topListNodeName, additionalFilter, sizeGetterFunctionName, numTopEntries)
	local root = resourceManager:getResourceRoot();
	local maxDepth = editor.Editor.InfiniteDepth
	local forceParentsOfMatchesToMatch = false
	local ret = ""
	
	local filterString = filteringModule:getResourceFilterString()
	-- HACK: no minimal sizes please, to keep the lua tables sensible size...
	filterString = filterString .. "|9,"..additionalFilter
	local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilter(root, filterString, maxDepth, forceParentsOfMatchesToMatch)	
	
	-- iterate all objects to a list of all resources, which is then sorted by size
	local obj = resultIterator:next()
	local sortedTableOfResources = { }
	while (obj) do
		local sizeBytes = obj[sizeGetterFunctionName](obj)
		table.insert(sortedTableOfResources, { size=sizeBytes, o=obj })
		obj = resultIterator:next()
	end
	table.sort(sortedTableOfResources, function (a,b) return a.size > b.size end)
	
	ret = ret .. "[GUID_NONE,FLAGS,EditorHint_Icon_Folder|EditorHint_Resources_Unique_"..topListNodeName.."]"..topListNodeName.."\r\n"
	ret = ret .. "{\r\n"
	ret = ret .. "[GUID_NONE,FLAGS,EditorHint_Resources_Unique_"..topListNodeName..",CHILDREN]children\r\n"
	ret = ret .. "{\r\n"	
	
	-- iterate the first n objects from the sorted table
	local num = 0
	for num=1,numTopEntries do
		if (sortedTableOfResources[num]) then
			local obj = sortedTableOfResources[num].o			
			local singlenodedump = dumpTableToString(dumpBranch(obj, false, 1, 1, 1, filterString), false);
			ret = ret .. singlenodedump			
		end
		num = num + 1
	end

	ret = ret .. "}\r\n"
	ret = ret .. "}\r\n"
		
	return ret
end

function getResourceTopListForExternalUI(numMainTopEntries, numGraphicsTopEntries, graphicsUsageWithDependencies)
	local ret = ""
	ret = ret .. "[GUID_NONE,FLAGS,EditorHint_Icon_Folder|EditorHint_Resources_Unique_TopList]TopResources(Filtered)\r\n"
	ret = ret .. "{\r\n"
	ret = ret .. "[GUID_NONE,FLAGS,EditorHint_Resources_Unique_TopList,CHILDREN]children\r\n"
	ret = ret .. "{\r\n"	
	if (numMainTopEntries > 0) then
		if (numMainTopEntries > 50) then
			ret = ret .. getResourceTopListForExternalUIImpl("TopMainMemoryUsage", "All", "getMemoryUsed", numMainTopEntries)
		else
			ret = ret .. getResourceTopListForExternalUIImpl("TopMainMemoryUsage", "data/filter/native/nativefilter_resource_size_exceeds_50kbytes_main", "getMemoryUsed", numMainTopEntries)
		end
	end
	local graphicsMemFunctionForSorting = "getGraphicsMemoryUsed";
	if (true) then
		graphicsMemFunctionForSorting = "getGraphicsMemoryUsedWithDependencies"
	end
	if (numGraphicsTopEntries > 0) then
		if (numGraphicsTopEntries > 50) then
			ret = ret .. getResourceTopListForExternalUIImpl("TopGraphicsMemoryUsage", "data/filter/native/nativefilter_resource_size_exceeds_1bytes_graphics", graphicsMemFunctionForSorting, numGraphicsTopEntries)
		else
			ret = ret .. getResourceTopListForExternalUIImpl("TopGraphicsMemoryUsage", "data/filter/native/nativefilter_resource_size_exceeds_50kbytes_graphics", graphicsMemFunctionForSorting, numGraphicsTopEntries)
		end
	end
	ret = ret .. "}\r\n"
	ret = ret .. "}\r\n"
	return ret
end


-- returns the value of the type object property
-- this needs to be used instead of directly getting the property value, as the type property getters are not always bound
function getTypeProperty(typeObj, propertyName)
	assert_string(propertyName)
	
	local numProps = typeObj:getNumProperties()
	for i = 0,numProps-1 do
		if (typeObj:getPropertyName(i) == propertyName) then
			return typeObj:getPropertyValue(i)
		end
	end
	
	local typeObjName = "(Unknown)"
	if (typeObj.getName) then typeObjName = typeObj:getName() end
	logger:error("Type \""..tostring(typeObj).."\" does not have property named \""..tostring(propertyName).."\".")
	return nil
end


-- sets the value of a type object property
function setTypeProperty(typeObj, propertyName, value)
	assert_string(propertyName)
	
	local numProps = typeObj:getNumProperties()
	for i = 0,numProps-1 do
		if (typeObj:getPropertyName(i) == propertyName) then
			typeObj:setPropertyValue(i, value)
			return
		end
	end
	
	local typeObjName = "(Unknown)"
	if (typeObj.getName) then typeObjName = typeObj:getName() end
	logger:error("Type \""..tostring(typeObj).."\" does not have property named \""..tostring(propertyName).."\".")
end

