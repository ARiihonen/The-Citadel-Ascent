module(..., package.seeall)
--debug.ReloadScripts.allowReload(...)

function initUtil()
  -- nop
end

-- this is a crappy simulation of the usual regexp "escape()" function...
function regexpEscape(str)
  -- first, need to escape the escape char for regexp :P
  str = string.gsub(str, "[\\]", "\\\\") 
  -- and some others too to be on the safe side
  str = string.gsub(str, "[\"]", "\\\"") 
  return str
end

function escapeChars(str, chars)
  chars = regexpEscape(chars)
  return string.gsub(str, "(["..chars.."])", "\\%1") 
end

-- this can be used to escape a string. 
-- (it still does not escape newlines and stuff, so only simple one-line strings are supported)
-- TODO: make a more generic escapeString function for all those more complex cases.
function escapeQuotesAndBackslashes(str)
  return escapeChars(str, "\"\\");
end

function unescapeLineBreaks(str)
  local tmp = str
  tmp = string.gsub(tmp , "(%<%/%-lf%-%/%>)", "\n")
  tmp = string.gsub(tmp , "(%<%/%-cr%-%/%>)", "\r")
  return tmp
end

function escapeLineBreaks(str)
  local tmp = str
  tmp = string.gsub(tmp , "(\n)", "</-lf-/>")   
  tmp = string.gsub(tmp, "(\r)", "</-cr-/>")   
  return tmp
end

-- Entities and model component's can't share same names
-- NOTE: don't use brackets, LUA string.gsub may use them
-- NOTE: If you add new postfix, remember to add it to all HACKS as well :)
ModelComponentPostfix = "_ModCom"
StaticPhysicsComponentPostfix = "_StaPhyCom"
StaticBoxPhysicsComponentPostfix = "_StaBoxPhyCom"
BoxPhysicsComponentPostfix = "_BoxPhyCom"
CapsulePhysicsComponentPostFix = "_CapPhyCom";
CompoundPhysicsComponentPostFix = "_ComPhyCom";
ConvexCompoundPhysicsComponentPostfix = "_CoCoPhyCom"

function getTypeNamePostFix(typeName)
	if (typeName == "ModelComponent") then
		return ModelComponentPostfix;
	elseif (typeName == "StaticBoxPhysicsComponent") then
		return StaticBoxPhysicsComponentPostfix;
	elseif (typeName == "StaticMeshPhysicsComponent") then
		return StaticPhysicsComponentPostfix;
	elseif (typeName == "BoxPhysicsComponent") then
		return BoxPhysicsComponentPostfix;
	elseif(typeName == "CapsulePhysicsComponent") then
		return CapsulePhysicsComponentPostFix;
	elseif (typeName == "CompoundPhysicsComponent") then
		return CompoundPhysicsComponentPostFix;
	elseif (typeName == "ConvexCompoundPhysicsComponent") then
		return ConvexCompoundPhysicsComponentPostfix;
	end
	
	-- default to instance class id
	local classIdString = typeManager:findTypeByName(typeName):getInstanceClassId():getString();
	return "_" .. classIdString .. "";
end

function doesStringContainTypeNamePostFixes(str)
	
	if string.find(str, ModelComponentPostfix) ~= nil then
		return true
	end
	if string.find(str, BoxPhysicsComponentPostfix) ~= nil then
		return true
	end
	if string.find(str, BoxPhysicsComponentPostfix) ~= nil then
		return true
	end
	if string.find(str, CapsulePhysicsComponentPostFix) ~= nil then
		return true
	end
	if string.find(str, CompoundPhysicsComponentPostFix) ~= nil then
		return true
	end
	if string.find(str, ConvexCompoundPhysicsComponentPostfix) ~= nil then
		return true
	end
	return false;
end

function remapFilenameFolders(filename)
	local newFilename = filename;
	
	-- Some final folder remapping
	--newFilename = string.gsub(newFilename, "data/model/object/", "data/model/object/");
	newFilename = string.gsub(newFilename, "data/model/actor/", "data/model/object/actor/");
	newFilename = string.gsub(newFilename, "data/model/bullet/", "data/model/object/bullet/");
	newFilename = string.gsub(newFilename, "data/model/effect/", "data/model/object/effect/");
	newFilename = string.gsub(newFilename, "data/model/pointer/", "data/model/object/pointer/");
	newFilename = string.gsub(newFilename, "data/model/weapon/", "data/model/object/weapon/");
	newFilename = string.gsub(newFilename, "data/model/wear/", "data/model/object/wear/");
	--newFilename = string.gsub(newFilename, "data/texture/", "data/texture/");
	
	if string.find(newFilename, "skymodel/") ~= nil then
		newFilename = string.gsub(newFilename, "data/model/skymodel/", "data/model/scene/sky_model/");
		newFilename = string.gsub(newFilename, "sky_model/astralsky/", "sky_model/astral_sky/");
		newFilename = string.gsub(newFilename, "sky_model/desert/", "sky_model/desert_sky/");
		newFilename = string.gsub(newFilename, "sky_model/dragonsky/", "sky_model/dragon_sky/");
		newFilename = string.gsub(newFilename, "sky_model/emptysky/", "sky_model/empty_sky/");
		newFilename = string.gsub(newFilename, "sky_model/morning/", "sky_model/morning_sky/");
		newFilename = string.gsub(newFilename, "sky_model/night_swamp/", "sky_model/night_swamp_sky/");
		newFilename = string.gsub(newFilename, "sky_model/sareksky/", "sky_model/sarek_sky/");
		newFilename = string.gsub(newFilename, "sky_model/spookysky/", "sky_model/spooky_sky/");
	end

	return newFilename;
end

function validateFileNameAndFixIt(filename)
	local retFilename = filename;
	--
	-- Fix the filenames (this is very hacky, should use same validator which ResourceManager fixResourceName uses!!!)
	--
	retFilename = string.gsub(retFilename, "-", "_");
	retFilename = string.gsub(retFilename, ",", "_");
	retFilename = string.gsub(retFilename, " ", "_");
	retFilename = string.gsub(retFilename, "{", "_");
	retFilename = string.gsub(retFilename, "}", "_");
	
	-- No @ flags, remove brackets
	if string.find(retFilename, "@") == nil then
		retFilename = string.gsub(retFilename, "%[", "_");
		retFilename = string.gsub(retFilename, "%]", "_");	
		retFilename = string.gsub(retFilename, "%(", "_");
		retFilename = string.gsub(retFilename, "%)", "_");
	end
	
	return retFilename;
end

function convertFileName(filename)
	local retFilename = filename;

	-- Fix filename
	retFilename = validateFileNameAndFixIt(retFilename);

	-- Remap
	retFilename = remapFilenameFolders(retFilename);

	-- To Trine2 format
	retFilename = string.gsub(retFilename, "data/model/", "data/root/instance_base/entity/");
	retFilename = string.gsub(retFilename, "/model/", "/");
	
	-- Just to be sure
	retFilename = string.gsub(retFilename, "data/object/", "data/root/instance_base/entity/object/");
	retFilename = string.gsub(retFilename, "data/legacy_unit/", "data/root/instance_base/entity/legacy_unit/");
	retFilename = string.gsub(retFilename, "object/legacy_unit/", "legacy_unit/");
	
	-- Cannot use this, breaks everything
	--retFilename = string.lower(retFilename);
	
	return retFilename;
end

function convertTypeName(typeName)
	local type = convertFileName(typeName);
	
	-- Trine1 and Trine2 folder structure has this
	type = string.gsub(type, "data/", "");
	
	-- Trine2 folder structure has these
	type = string.gsub(type, "root/", "");
	type = string.gsub(type, "instance_base/", "");
	type = string.gsub(type, "entity/", "");
	
	return type
end

function getPlainFileName(path, separator)
	local fileName = path;
	local pos = 0;
	local current = 0;
	while( not(current == nil) ) do
		current = string.find(fileName, separator, pos);
		if current ~= nil then
			pos = current + 1;
		end
	end
	if pos > 0 then
		return string.gsub(fileName, string.sub(fileName, 0, pos-1), "");
	else
		return fileName;
	end
end

function getPathFolderCount(path, separator)
	local pos = 0;
	local current = 0;
	local folderCount = 0;
	while( not(current == nil) ) do
		current = string.find(path, separator, pos);
		if current ~= nil then
			pos = current + 1;
			folderCount = folderCount + 1;
		end
	end
	return folderCount;
end

function stripFilenameFromStart(fileName, amount, separator)
	local name = fileName;

	if(amount > 0) then
		local pos = 0;
		local current = 0;
		local i = 0;
		while( not(current == nil) ) do
			-- string.find returns nil if subStr not found
			current = string.find(name, separator, pos);
			if current ~= nil then
				pos = current + 1;
				i = i + 1;				
				if(i == amount) then
					break;
				end
			end
		end
		name = string.gsub(name, string.sub(name, 0, pos-1), "");
	end	
	return name;
end

function removeDuplicates(typeName, parentTypeName, separator, removePostfixes)
	local retTypeName = typeName;
	local retParentTypeName = parentTypeName;
	local tmpReplace = "";
	
	-- Remove duplicate path name from type	
	tmpReplace = retParentTypeName .. separator;
	retTypeName = string.gsub(retTypeName, tmpReplace, "");

	if removePostfixes then
		-- HACK: Remove duplicate path name from type with postfixes (Should use getTypeNamePostFix() method)
		tmpReplace = string.gsub(retParentTypeName, ModelComponentPostfix, "") .. separator;
		retTypeName = string.gsub(retTypeName, tmpReplace, "");
		tmpReplace = string.gsub(retParentTypeName, StaticPhysicsComponentPostfix, "") .. separator;
		retTypeName = string.gsub(retTypeName, tmpReplace, "");
		tmpReplace = string.gsub(retParentTypeName, StaticBoxPhysicsComponentPostfix, "") .. separator;
		retTypeName = string.gsub(retTypeName, tmpReplace, "");
		tmpReplace = string.gsub(retParentTypeName, BoxPhysicsComponentPostfix, "") .. separator;
		retTypeName = string.gsub(retTypeName, tmpReplace, "");
		tmpReplace = string.gsub(retParentTypeName, CapsulePhysicsComponentPostFix, "") .. separator;
		retTypeName = string.gsub(retTypeName, tmpReplace, "");
		tmpReplace = string.gsub(retParentTypeName, CompoundPhysicsComponentPostFix, "") .. separator;
		retTypeName = string.gsub(retTypeName, tmpReplace, "");
		tmpReplace = string.gsub(retParentTypeName, ConvexCompoundPhysicsComponentPostfix, "") .. separator;
		retTypeName = string.gsub(retTypeName, tmpReplace, "");
	end
	
	return retTypeName;
end

function addPostfixImpl(typeName, postfix, separator)
	local retTypeName = typeName;
	local result = 0;
	local pos = 0;
	result = string.find(typeName, postfix, pos);
	if result ~= nil then
		retTypeName = string.gsub(typeName, separator, postfix .. separator);
	end
	return retTypeName;
end

function addPostfixes(typeName, parentTypeName, separator)
	local retTypeName = typeName;
	local retParentTypeName = parentTypeName;
	-- HACK: (Should use getTypeNamePostFix() method
	retTypeName = addPostfixImpl(retTypeName, ModelComponentPostfix, separator);
	retTypeName = addPostfixImpl(retTypeName, StaticPhysicsComponentPostfix, separator);
	retTypeName = addPostfixImpl(retTypeName, StaticBoxPhysicsComponentPostfix, separator);
	retTypeName = addPostfixImpl(retTypeName, BoxPhysicsComponentPostfix, separator);
	retTypeName = addPostfixImpl(retTypeName, CapsulePhysicsComponentPostFix, separator);
	retTypeName = addPostfixImpl(retTypeName, CompoundPhysicsComponentPostFix, separator);
	retTypeName = addPostfixImpl(retTypeName, ConvexCompoundPhysicsComponentPostfix, separator);
	return retTypeName;
end

function removePostfixes(typeName)
	local retTypeName = typeName;	
	-- HACK: (Should use getTypeNamePostFix() method
	retTypeName = string.gsub(retTypeName, ModelComponentPostfix, "");
	retTypeName = string.gsub(retTypeName, StaticPhysicsComponentPostfix, "");
	retTypeName = string.gsub(retTypeName, StaticBoxPhysicsComponentPostfix, "");
	retTypeName = string.gsub(retTypeName, BoxPhysicsComponentPostfix, "");
	retTypeName = string.gsub(retTypeName, CapsulePhysicsComponentPostFix, "");
	retTypeName = string.gsub(retTypeName, CompoundPhysicsComponentPostFix, "");
	retTypeName = string.gsub(retTypeName, ConvexCompoundPhysicsComponentPostfix, "");
	return retTypeName;
end

function isTypeValid(type, typeNameFullPath, separator)
	if not type then
		logger:error("Invalid params given (type).");
		return false;
	end
	
	if not typeNameFullPath then
		logger:error("Invalid params given (typeNameFullPath).");
		return false;
	end
		
	local retTypeFilename = type:getTypeFileName();				
	local tmpRetTypeFilename = removePostfixes(retTypeFilename);
	local tmpTypeNameFullPath = removePostfixes(typeNameFullPath);		
	-- Type already exists?
	if tmpRetTypeFilename == tmpTypeNameFullPath then
		-- ok, correct type
		return true;
	else
		-- Not the correct type, keep looking
		return false;
	end
end

function getOrCreateTypeLegacy(typeNameFullPath, parentTypeNameFullPath, isLegacyType)	
	--
	-- Strip unnecessary paths from typeNameFullPath and parentTypeNameFullPath
	--
	local separator = "/";
		
	local retTypeName = typeNameFullPath;
	local retParentTypeName = parentTypeNameFullPath;

	-- Parent, find correct parent
	local parentType = nil;
	local parentTypeFolderCount = getPathFolderCount(parentTypeNameFullPath, separator);
	local retParentTypeStrippedName = "";

	if(parentTypeFolderCount > 0) then
		retParentTypeStrippedName = getPlainFileName(parentTypeNameFullPath, separator);
		parentType = typeManager:findTypeByName(retParentTypeStrippedName);
		if parentType then
			if isTypeValid(parentType, parentTypeNameFullPath, separator) then
				-- ok
			else
				parentType = nil;
			end
		end

		while( parentType == nil ) do
			retParentTypeStrippedName = stripFilenameFromStart(parentTypeNameFullPath, parentTypeFolderCount, separator);
			parentType = typeManager:findTypeByName(retParentTypeStrippedName);
			
			if parentType then
				if isTypeValid(parentType, parentTypeNameFullPath, separator) then
					break;
				else
					parentType = nil;
				end
			end
			
			parentTypeFolderCount = parentTypeFolderCount - 1;
			if(parentTypeFolderCount < 0) then
				break;
			end
		end
	else
		retParentTypeStrippedName = retParentTypeName;
		parentType = typeManager:findTypeByName(retParentTypeStrippedName);
		
		-- Try again without postfixes
		if(parentType == nil) then
			retParentTypeStrippedName = removePostfixes(retParentTypeStrippedName);
			parentType = typeManager:findTypeByName(retParentTypeStrippedName);			
		end
	end
	
	if(parentType == nil) then
		logger:error("util::getOrCreateTypeLegacy - MAJOR ERROR! -> Parent type doesn't exist: \"" .. retParentTypeStrippedName .. "\" for type: \"" .. retTypeName .. "\". Make sure that you give Type Name with full path!");
		return nil;
	end
	
	-- Remove duplicate path name from type	
	retTypeName = removeDuplicates(retTypeName, retParentTypeName, separator, true);
	
	-- Type itself, find unique name for the type
	local retType = nil;
	local typeFolderCount = getPathFolderCount(typeNameFullPath, separator);
	local retTypeStrippedName = "";

	if(typeFolderCount > 0) then

		retTypeStrippedName = getPlainFileName(retTypeName, separator);
		retType = typeManager:findTypeByName(retTypeStrippedName);
		
		while( not(retType == nil) ) do
			retTypeStrippedName = stripFilenameFromStart(typeNameFullPath, typeFolderCount, separator);
	
			-- Remove duplicate path name from type	
			retTypeStrippedName = removeDuplicates(retTypeStrippedName, retParentTypeName, separator, true);
			
			retType = typeManager:findTypeByName(retTypeStrippedName);
			if retType then
				if isTypeValid(retType, typeNameFullPath, separator) then
					break;
				end
			end

			typeFolderCount = typeFolderCount - 1;
			if(typeFolderCount < 0) then
				if retType then
					if isTypeValid(retType, typeNameFullPath, separator) then
						-- ok
					else
						-- Still not valid found, create unique
						retTypeStrippedName = typeNameFullPath;
						retType = nil;
					end
				end
				break;
			end
		end
	else
		retTypeStrippedName = retTypeName;
		retType = typeManager:findTypeByName(retTypeStrippedName);
	end
	
	if(retType == nil and string.len(retTypeStrippedName) > 0 and string.len(retParentTypeStrippedName) > 0) then
		-- Avoid duplicates
		local tmpType = typeManager:findTypeByName(retTypeStrippedName);

		-- not able to find "foo", look for "bar/foo" in parent instead
		if(tmpType == nil) then
			local stringToEndWith = "/" .. retTypeStrippedName;
			for i = 0, parentType:getNumChildren() - 1 do
				local child = parentType:getChild(i)
				local endOfName = string.sub(child:getName(), 1 + string.len(child:getName()) - string.len(stringToEndWith))
				if(endOfName == stringToEndWith) then
					if isTypeValid(child, typeNameFullPath, separator) then
						tmpType = child
						break
					end
				end
			end
		end

		if(tmpType == nil) then	
			retType = typeManager:inheritNewType(retTypeStrippedName, retParentTypeStrippedName);
			if retType then
				local typeIsPropablyAFolder = false;
				if retType:doesInheritTypeByName("ObjectEntity") or retType:doesInheritTypeByName("LegacyUnitEntity") or retType:doesInheritTypeByName("ComponentBase") then
					if string.find(retTypeStrippedName, ".s3d") ~= nil then
						typeIsPropablyAFolder = false;
					else
						typeIsPropablyAFolder = true;
					end
				end

				if isLegacyType then
					-- These legacy types should never be inserted to the scene, but allow them in the game
					if typeIsPropablyAFolder then
						retType:setAbstractType(true);
						retType:setGameAbstractType(true);
					else
						retType:setAbstractType(true);
						retType:setGameAbstractType(false);				
					end
				else
					if typeIsPropablyAFolder then
						retType:setAbstractType(true);
						retType:setGameAbstractType(true);
					else
						retType:setAbstractType(false);
						retType:setGameAbstractType(false);				
					end
				end

				local uniqueTypeNameFullPath = typeNameFullPath;
				
				-- Make type script name also unique
				local uniqueScriptName = string.gsub(retTypeStrippedName, separator, "_");			
				local tmpFolderCount = getPathFolderCount(uniqueTypeNameFullPath, separator);
				if(tmpFolderCount > 0) then
					local pos = 0;
					local current = 0;
					while( not(current == nil) ) do
						current = string.find(uniqueTypeNameFullPath, separator, pos);
						if current ~= nil then
							pos = current + 1;
						end
					end
					if pos > 0 then
						uniqueTypeNameFullPath = string.sub(uniqueTypeNameFullPath, 0, pos-1);
						uniqueTypeNameFullPath = uniqueTypeNameFullPath .. uniqueScriptName;
					end
				end
				
				uniqueTypeNameFullPath = string.gsub(uniqueTypeNameFullPath, "data/root/instance_base/entity/", "");
				local typeScriptPath = "data/root/instance_base/entity/".. uniqueTypeNameFullPath ..".fbt";
				typeManager:setTypeScript(retType, typeScriptPath);
				retType:setTypeFileName(typeNameFullPath);
			else
				logger:error("util::getOrCreateTypeLegacy - MAJOR ERROR! -> inheritNewType failed for type \"" + retTypeStrippedName + "\" from baseType \"" + retParentTypeStrippedName "\".");
				return nil;
			end
		else
			retType = tmpType;
		end
	end	
	return retType
end

function getOrCreateType(typeNameFullPath, parentTypeNameFullPath, isLegacyType)

	-- Use same format as legacy uses
	return getOrCreateTypeLegacy(typeNameFullPath, parentTypeNameFullPath, isLegacyType)
	
	--[[
	local retType = typeManager:findTypeByName(typeNameFullPath)	
	if retType == nil then	
		retType = typeManager:inheritNewType(typeNameFullPath, parentTypeNameFullPath)
		-- Clear abstract flags
		if not isLegacyType then
			retType:setAbstractType(false);
			retType:setGameAbstractType(false);
		end
		typeNameFullPath = string.gsub(typeNameFullPath, "data/root/instance_base/entity/", "");
		typeManager:setTypeScript(retType, "data/root/instance_base/entity/"..typeNameFullPath..".fbt");
	end	
	return retType
	]]--
end

function createDummyTypeHierarchyLegacy(type, parent, postfix, isLegacyType)
	-- ToDo: Mark created types as dummy
	local loopType = ""
	for dir in string.gmatch(type, "(.-)/") do 
		if loopType == "" then
			loopType = dir
			getOrCreateTypeLegacy(loopType..postfix, parent, isLegacyType)
		else
			loopType = loopType.."/"..dir
			getOrCreateTypeLegacy(loopType..postfix, parent..postfix, isLegacyType)
		end

		parent = loopType
	end

	return parent..postfix
end

function createDummyTypeHierarchy(type, parent, postfix, isLegacyType)
	-- ToDo: Mark created types as dummy
	
	-- Use same format as legacy uses
	return createDummyTypeHierarchyLegacy(type, parent, postfix, isLegacyType);
	
	--[[
	local loopType = ""
	for dir in string.gmatch(type, "(.-)/") do 
		if loopType == "" then
			loopType = dir
			getOrCreateType(loopType..postfix, parent, isLegacyType)
		else
			loopType = loopType.."/"..dir
			getOrCreateType(loopType..postfix, parent..postfix, isLegacyType)
		end

		parent = loopType
	end

	return parent..postfix
	]]--
end

----------------------------------------------------------------------------------------------------------------------------
--
-- Mass stuff
--

function getEnumMassFromNumericMass(mass)
	if mass == nil then
		logger:error("At least one of the params was nil.");
		return engine.component.AbstractPhysicsComponent.MassNotSet;
	end
	
	-- NOTE: See also C++ PhysicsComponentBase::getNumericMass(..)
	
	--[[
	// Trine 1 masses
	very_very_light mass = 0.5
	very_light mass = 1
	light mass = 5
	medium mass = 10
	heavy mass = 20
	100_kg mass = 30
	200_kg mass = 40
	+200_kg mass = 50
	extreme_heavy mass = 160
	]]--
	
	if(mass > 0.0 and mass < 1.0) then 
		return engine.component.AbstractPhysicsComponent.MassVeryLightLevel1;
	elseif(mass >= 1.0 and mass < 1.5) then 
		return engine.component.AbstractPhysicsComponent.MassVeryLightLevel1;
	elseif(mass >= 1.5 and mass < 2.5) then 
		return engine.component.AbstractPhysicsComponent.MassVeryLightLevel3;
	elseif(mass >= 2.5 and mass < 5.0) then 
		return engine.component.AbstractPhysicsComponent.MassLightLevel1;
	elseif(mass >= 5.0 and mass < 7.5) then 
		return engine.component.AbstractPhysicsComponent.MassLightLevel2;
	elseif(mass >= 7.5 and mass < 10.0) then 
		return engine.component.AbstractPhysicsComponent.MassLightLevel3;
	elseif(mass >= 10.0 and mass < 20.0) then 
		return engine.component.AbstractPhysicsComponent.MassMediumLevel1;
	elseif(mass >= 20.0 and mass < 30.0) then 
		return engine.component.AbstractPhysicsComponent.MassMediumLevel2;
	elseif(mass >= 30.0 and mass < 40.0) then 
		return engine.component.AbstractPhysicsComponent.MassMediumLevel3;
	elseif(mass >= 40.0 and mass < 60.0) then 
		return engine.component.AbstractPhysicsComponent.MassHeavyLevel1;
	elseif(mass >= 60.0 and mass < 80.0) then 
		return engine.component.AbstractPhysicsComponent.MassHeavyLevel2;
	elseif(mass >= 80.0 and mass < 100.0) then 
		return engine.component.AbstractPhysicsComponent.MassHeavyLevel3;
	elseif(mass >= 100.0 and mass < 200.0) then 
		return engine.component.AbstractPhysicsComponent.MassMassiveLevel1;
	elseif(mass >= 200.0 and mass < 300.0) then 
		return engine.component.AbstractPhysicsComponent.MassMassiveLevel2;
	elseif(mass >= 300.0) then
		return engine.component.AbstractPhysicsComponent.MassMassiveLevel3;
	end

	logger:error("No MassEnum found.");
	return engine.component.AbstractPhysicsComponent.MassNotSet;
end

----------------------------------------------------------------------------------------------------------------------------
--
-- Type modifying (helper for setting some property to all types and instances)
--

function setPropertyValueToAllTypes(propertySetterName, newValue)
	if propertySetterName == nil or newValue == nil then
		logger:error("At least one of the params was nil.");
		return;
	end
	logger:info("setPropertyValueToAllTypes started...");
	
	-- For types
	local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilter(typeManager:getTypeRoot(), "0,data/filter/native/nativefilter_composite_allowall_allowall.fbfilt", 99999, false);
	local obj = resultIterator:next();
	while (not(obj == nil)) do
		-- TODO: Construct obj.propertySetterName here and obj:propertySetterName(newValue);
		logger:error("TODO: setPropertyValueToAllTypes(propertySetterName, newValue)");
		obj = resultIterator:next();		
	end
	
	-- For instances
	local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilter(instanceManager:getTopmostInstanceRoot(), "0,data/filter/native/nativefilter_composite_allowall_allowall.fbfilt", 99999, false);
	local obj = resultIterator:next();
	while (not(obj == nil)) do
		-- TODO: Construct obj.propertySetterName here and obj:propertySetterName(newValue);
		logger:error("TODO: setPropertyValueToAllTypes(propertySetterName, newValue)");
		obj = resultIterator:next();		
	end	
	logger:info("setPropertyValueToAllTypes Finished.");
end

----------------------------------------------------------------------------------------------------------------------------
-- Property setting helpers

function setBoolPropertyByNameForComponent(propertyName, enabled, comp)
	local index = comp:findPropertyIndexByName(propertyName);
	if index >= 0 then
		comp:setPropertyValue(index, enabled);
	else
		logger:error("util:setBoolPropertyByNameForComponent - No such property found with given name \"" .. propertyName .. "\".");
	end
end

function forInstancesMatchingName(name, fn)
	local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilter(instanceManager:getTopmostInstanceRoot(), "0,data/filter/native/nativefilter_composite_allowall_allowall.fbfilt", editor.Editor.InfiniteDepth, false)
	local obj = resultIterator:next();
	while (not(obj == nil)) do
	
		local allow = true;
		if string.len(name) > 0 and typeManager then
			allow = false;
			local type = typeManager:getTypeByUH( obj:getType() );
			if type then
				if type:doesInheritTypeByName(name) then
					allow = true;
				end
			end
		end
	
		if allow then
			fn(obj)
		end
		obj = resultIterator:next();
	end
end

function forAllComponentsRecursively(instance, fn)
	if instance.getComponents then			
		local iter = ComponentVectorIterator(instance:getComponents());
		if not iter:hasInitFailed() then
			local childComp = iter:next()
			while not (childComp == nil) do
				fn(childComp)
				forAllComponentsRecursively(childComp, fn)
				childComp = iter:next();
			end
		else
			logger:error("util:setDebugVisualizerPropertyForAllInstances - Component iterator init failed, cannot loop trough child components.");
		end
	end		
end

function setComponentBoolPropertyForAllInstances(propertyName, enabled, mustInheritCompTypeClassId, instanceTypeNameFilterString)
	forInstancesMatchingName(instanceTypeNameFilterString, function(instance)
		forAllComponentsRecursively(instance, function(comp)
			if comp:isInheritedByClassId(mustInheritCompTypeClassId) then
				setBoolPropertyByNameForComponent(propertyName, enabled, comp);
			end
		end)
	end)
end

function setAbstractModelComponentBoolPropertyForHelperEntityInstances(propertyName, enabled)
	setComponentBoolPropertyForAllInstances(propertyName, enabled, engine.component.AbstractModelComponent.getStaticClassId(), "HelperEntity");
end

----------------------------------------------------------------------------------------------------------------------------
--
-- Dependency check helper scritps
--
function doesTypeInheritType(type, otherType)
	if type == nil then
		logger:error("Util:doesTypeInheritType - Missing type parameter.");
		return false;
	end
	
	if otherType == nil then
		logger:error("Util:doesTypeInheritType - Missing otherType parameter.");
		return false;
	end
	
	return type:doesInheritType(otherType);
end

function doesTypeHaveDependencyToType(type, dependedType)
	if type == nil then
		logger:error("Util:doesTypeHaveDependencyToTypeByName - Missing type parameter.");
		return false;
	end
	
	local numComponentDependencies = type:getNumComponentDependencies();
	for i = 0, numComponentDependencies-1 do
		local dependencyName = type:getComponentDependency(i);
		local dependencyType = typeManager:findTypeByName(dependencyName);
		if dependencyType ~= nil then
			if doesTypeInheritType(dependencyType, dependedType) then
				return true;
			end
		end
	end
	
	local numOptionalComponentDependencies = type:getNumOptionalComponentDependencies();
	for i = 0, numOptionalComponentDependencies-1 do
		local dependencyName = type:getOptionalComponentDependency(i);
		local dependencyType = typeManager:findTypeByName(dependencyName);
		if dependencyType ~= nil then
			if doesTypeInheritType(dependencyType, dependedType) then
				return true;
			end
		end
	end
	
	local numSubComponentDependencies = type:getNumSubComponentDependencies();
	for i = 0, numSubComponentDependencies-1 do
		local dependencyName = type:getSubComponentDependency(i);
		local dependencyType = typeManager:findTypeByName(dependencyName);
		if dependencyType ~= nil then
			if doesTypeInheritType(dependencyType, dependedType) then
				return true;
			end
		end
	end
	
	local numOptionalSubComponentDependencies = type:getNumOptionalSubComponentDependencies();
	for i = 0, numOptionalSubComponentDependencies-1 do
		local dependencyName = type:getOptionalSubComponentDependency(i);
		local dependencyType = typeManager:findTypeByName(dependencyName);
		if dependencyType ~= nil then
			if doesTypeInheritType(dependencyType, dependedType) then
				return true;
			end
		end
	end
	
	return false;
end


----------------------------------------------------------------------------------------------------------------------------

function fixWoodCollision()
	local root = instanceManager:getTopmostInstanceRoot()
	local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilter(root, "0,All", editor.Editor.InfiniteDepth, false)
	local type = typeManager:findTypeByName("dynamic_collision_wood.s3d")
	local obj = resultIterator:next()
	while (obj) do
		if(obj:getType() == type:getUnifiedHandle()) then
			local mdl = obj:findComponent(engine.component.AbstractModelComponent);
			local phys = obj:getPhysicsComponent();
			if(mdl and phys)
			then
				local originalPhysType = typeManager:getTypeByUH(phys:getType())
				originalPhysType:resetInstancePropertyValue(phys, "Dimensions")
				phys:setDimensions(phys:getDimensions() * mdl:getScale())
			end
		end

		obj = resultIterator:next()
	end
end


function fixLockJointTypes()
	local root = typeManager:getTypeRoot()
	local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilter(root, "0,All", editor.Editor.InfiniteDepth, false)
	local obj = resultIterator:next()
	while (obj) do
		if(obj and obj.getNumComponentTypes)
		then
			local nct = obj:getNumComponentTypes();
			for i = 0, nct-1 do
				local t = typeManager:getTypeByUH(obj:getComponentType(i))
				if(t:doesInheritTypeByName("LockJointComponent"))
				then
					obj:removeComponentType(obj:getComponentType(i))
					break
				end
			end
		end
		obj = resultIterator:next()
	end
end


function setShadowCasterBitsOfDynamicObjects()
	local recurse = function(recurseFunc, instance)
		if instance.getPhysicsComponent and instance.getModelComponent then
			local pc = instance:getPhysicsComponent()
			if pc and (pc:isDynamic() or pc:getIsKinematicActor()) then
				local mc = instance:getModelComponent()
				if mc then
					local bits = mc:getShadowCasterMaskBits()
					bits:setAllBits()
					mc:setShadowCasterMaskBits(bits)
				end
			end
		end
		for i = 0, instance:getNumChildren() - 1 do
			local child = instance:getChild(i)
			recurseFunc(recurseFunc, child)
		end
	end
	
	recurse(recurse, gameScene:getSceneInstanceManager():getTopmostInstanceRoot())
end


function resetShadowCasterBitsOfDynamicObjects()
	local recurse = function(recurseFunc, instance)
		if instance.getPhysicsComponent and instance.getModelComponent then
			local pc = instance:getPhysicsComponent()
			if pc and (pc:isDynamic() or pc:getIsKinematicActor()) then
				local mc = instance:getModelComponent()
				if mc then
					editor.ExternalUI.resetPropertyValue(mc:getGuid(), "ShadowCasterMaskBits")
				end
			end
		end
		for i = 0, instance:getNumChildren() - 1 do
			local child = instance:getChild(i)
			recurseFunc(recurseFunc, child)
		end
	end
	
	recurse(recurse, gameScene:getSceneInstanceManager():getTopmostInstanceRoot())
end


-------------------------------------------------------------------------------------------------
--
-- Instance spawning
--

-- Callback
function createInstanceObject(object, params)
	
	if object == nil then
		logError("editor.Util:createInstanceObject - Object is nil.");
		return;
	end
	
	if params == nil then
		logError("editor.Util:createInstanceObject - Params are nil.");
		return;
	end

	local trans = object:getTransformComponent();
	if trans then
		trans:setPosition(params.objectPos);
	end
end

function spawnInstanceByTypeNameNearPlayerWithOffset(typeName, offset)	
	if typeName == nil then
		logError("editor.Util:spawnInstanceByTypeNameNearPlayerWithOffset - Given param typeName was nil.");
		return;
	end
	
	if offset == nil then
		logError("editor.Util:spawnInstanceByTypeNameNearPlayerWithOffset - Given param offset was nil.");
		return;
	end

	local type = typeManager:findTypeByName(typeName);
	
	spawnInstanceByTypeNearPlayerWithOffset(type, offset);
end

function spawnInstanceByTypeNearPlayerWithOffset(type, offset)	
	if type == nil then
		logError("editor.Util:spawnInstanceByTypeNearPlayerWithOffset - Given param type was nil.");
		return;
	end
	
	if offset == nil then
		logError("editor.Util:spawnInstanceByTypeNearPlayerWithOffset - Given param offset was nil.");
		return;
	end
	
	local playerPos = getRandomPlayerPosition();
	playerPos = VC3(playerPos.x + offset.x, playerPos.y + offset.y, playerPos.z + offset.z);
	
	if type == nil then
		logError("editor.Util:spawnInstanceByTypeNearPlayerWithOffset - No such type found with given name: \"" .. typeName .. "\".");
		return;
	end
	
	common.CommonUtils.getSceneInstanceManager():createNewInstance(type:getUnifiedHandle(), createInstanceObject, {objectPos = playerPos});	
end

function spawnInstanceByTypeNameNearPlayer(typeName)
	if typeName == nil then
		logError("editor.Util:spawnInstanceByTypeNameNearPlayer - Given param typeName was nil.");
		return;
	end
	local type = typeManager:findTypeByName(typeName);
	spawnInstanceByTypeNearPlayer(type);
end

function spawnInstanceByTypeNearPlayer(type)
	if type == nil then
		logError("editor.Util:spawnInstanceByTypeNearPlayer - Given param type was nil.");
		return;
	end
	spawnInstanceByTypeNearPlayerWithOffset(type, engine.base.mathbase.GameDirections.sceneUpDirection * 5.0);
end


-------------------------------------------------------------------------------------------------
--
-- Spawning helper functions
--

function getRandomPlayerPosition()
	local sce = common.CommonUtils.getScene();
	
	if sce == nil then
		logError("ai_utils_debug:getRandomPlayerPosition - Scene is nil.");
		return;
	end
	-- Add players
	local pm = common.CommonUtils.getPlayerManager()
	local playerCharacters = { }
	if pm then
		playerCharacters = {
			pm:getCharacterInstanceForPlayer(0), 
			pm:getCharacterInstanceForPlayer(1), 
			pm:getCharacterInstanceForPlayer(2)
		}
	end
	-- Get closest player
	for key, playerInstance in pairs(playerCharacters) do
		if playerInstance then
			local tfc = playerInstance:getTransformComponent();
			if tfc then			
				return tfc:getPosition();
			end		
		end		
	end
	
	logInfo("ai_utils_debug:getRandomPlayerPosition - No (alive) players found, cannot find player position");
	return VC3(0,0,0);
end


----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------