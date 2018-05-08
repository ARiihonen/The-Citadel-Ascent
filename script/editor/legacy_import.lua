module(..., package.seeall)

require "editor.Util"

--------------------------------------------------------------------------------------------------------------------------------
-- Import settings

cfg_EnableLevelImporting = true;
cfg_EnableLevelImportingFailMessage = "legacy_import: Level importing is disabled. All types (from Objects.fbt) and levels are already imported and being edited in the new engine. -Jari K. (2010.09.06)";

cfg_ImportTypes = true;
	cfg_ImportEntityTypes = true;
	cfg_ImportModelComponentTypes = true;
		cfg_ImportModelComp_ModelResource = true;
		cfg_ImportModelComp_Scale = true;
		cfg_ImportModelComp_AlphaBlending = true;
		cfg_ImportModelComp_UVScale = true;
		cfg_ImportModelComp_WRAP = true;
		cfg_ImportModelComp_SWAY = true;
	cfg_ImportPhysicsComponentTypes = true;
		cfg_ImportPhysicsStaticMeshComponentTypes = false; -- Don't create static physics, we use Collision Helpers manually
		cfg_ImportPhysicsStaticBoxComponentTypes = false;

cfg_ImportObjectInstances = true; -- cfg_ImportTypes needs to be TRUE if cfg_ImportObjectInstances is TRUE
cfg_ImportLightInstances = true;
cfg_ImportJointInstances = true;


cfg_LegacyUnitEntityTypeName = "LegacyUnitEntity";
--------------------------------------------------------------------------------------------------------------------------------

function isLevelImportingAllowed()
	return cfg_EnableLevelImporting;
end

function getEnableLevelImportingFailMessage()
	return cfg_EnableLevelImportingFailMessage;
end

--------------------------------------------------------------------------------------------------------------------------------
-- File name converting / validation
function validateFileNameAndFixIt(filename)
	local newFilename = filename;
	newFilename = editor.Util.validateFileNameAndFixIt(newFilename);	
	newFilename = string.lower(newFilename);
	return newFilename
end

function convertMissingResource(filename)
	local newFilename = filename;

	newFilename = string.gsub(newFilename, "missing.dds", "data/null/null.tga");
	--[[
	newFilename = string.gsub(newFilename, "missing.png", "data/null/null.tga");
	newFilename = string.gsub(newFilename, "missing.anm", "data/null/null.anm");
	newFilename = string.gsub(newFilename, "missing.s3d", "data/null/null.s3d");
	newFilename = string.gsub(newFilename, "missing.b3d", "data/null/null.b3d");
	newFilename = string.gsub(newFilename, "missing.ats", "data/null/null.ats");
	]]--	
	return newFilename;
end

function convertResourceFilename(filename)
	local newFilename = filename;
	
	-- Fix filename
	newFilename = validateFileNameAndFixIt(newFilename);
	
	newFilename = convertMissingResource(newFilename);
	return newFilename;
end

function convertFileName(filename)
	local name = editor.Util.convertFileName(filename);
	return name
end

function convertTypeName(typeName)
	local type = editor.Util.convertTypeName(typeName)
	return type
end

function convertTextureFileName(filename)
	if filename == nil then
		return "NONE!"
	end

	local fn = string.gsub(filename, "data/texture/", "data/root/instance_base/entity/texture/")
	return string.gsub(fn, ".avi", ".fba")
end

--------------------------------------------------------------------------------------------------------------------------------
-- Should we find a first scene or create a new one?
function getSceneInstanceManager()
	return gameScene:getSceneInstanceManager();
end

--------------------------------------------------------------------------------------------------------------------------------
-- Fix transformations

function getPosition(pos)
	-- Get it to origin
	pos.y = pos.y - 18.1643 - 2.0
	return pos
end

function getRotation(rot)
	return rot
end

--------------------------------------------------------------------------------------------------------------------------------
-- Property functions

function getTableAsString(table, prefix)
	-- Should we do this by concatenating a table?
	local result = ""

	for key, value in pairs(table) do
		if value == nil then
			-- Do nothing
		elseif(type(value) == "userdata") then
			-- Do nothing
		elseif(type(value) == "table") then
			result = result..getTableAsString(value, prefix..key..".")
		elseif(type(value) == "string") then
			result = result..prefix..key.."=\""..value.."\"\n"
		else
			result = result..prefix..key.."="..value.."\n"
		end
	end
	
	return result
end

function makePropertiesString(prop)
	--local result = getTableAsString(prop, "")
	--logger:error(result)
	--return result
	return getTableAsString(prop, "")
end

function getOrCreateTypeLegacy(typeName, parentTypeName, isLegacyType)
	return editor.Util.getOrCreateTypeLegacy(typeName, parentTypeName, isLegacyType)
end

function createDummyTypeHierarchyLegacy(type, parent, postfix, isLegacyType)
	return editor.Util.createDummyTypeHierarchyLegacy(type, parent, postfix, isLegacyType)
end

--------------------------------------------------------------------------------------------------------------------------------
-- Entity functions

function getEntityType(typeName, parentTypeName, params, isLegacyType)
	typeName = convertTypeName(typeName)
	parentTypeName = convertTypeName(parentTypeName)
	parentTypeName = createDummyTypeHierarchyLegacy(typeName, parentTypeName, "", isLegacyType)

	local type = getOrCreateTypeLegacy(typeName, parentTypeName, isLegacyType)
	return type
end

function initEntityType(type, params)
end

--------------------------------------------------------------------------------------------------------------------------------
-- ModelComponent functions

function getModelComponentType(typeName, parentTypeName, params, isLegacyType)
	typeName = convertTypeName(typeName)
	parentTypeName = convertTypeName(parentTypeName)
	parentTypeName = createDummyTypeHierarchyLegacy(typeName, parentTypeName, editor.Util.ModelComponentPostfix, isLegacyType)
	typeName = typeName..editor.Util.ModelComponentPostfix;

	local type = getOrCreateTypeLegacy(typeName, parentTypeName, isLegacyType)
	return type;
end

function hasSway(swayT)
	if tonumber(swayT[1]) == nil then
		return false
	end
	if tonumber(swayT[2]) == nil then
		return false
	end
	if tonumber(swayT[3]) == nil then
		return false
	end
	if tonumber(swayT[4]) == nil then
		return false
	end
	if tonumber(swayT[5]) == nil then
		return false
	end
	if tonumber(swayT[6]) == nil then
		return false
	end
	
	return true
end

function hasWrap(wrapT)
	if tonumber(wrapT[1]) == nil then
		return false
	end
	if tonumber(wrapT[2]) == nil then
		return false
	end
	if tonumber(wrapT[3]) == nil then
		return false
	end
	if tonumber(wrapT[4]) == nil then
		return false
	end
	
	return true
end

function initModelComponentType(type, params)
	local filename = convertFileName(params.filename)

	if cfg_ImportModelComp_Scale then
		local scale = VC3(1,1,1);
		local alphaFade = true	
		for flag, value in string.gmatch(params.typename, "@(%a+)([.%d]+)") do
			-- Model scale
			if flag == "SA" then
				scale.x = tonumber(value);
				scale.y = tonumber(value);
				scale.z = tonumber(value);
			elseif flag == "SX" then
				scale.x = tonumber(value);
			elseif flag == "SY" then
				scale.y = tonumber(value);
			elseif flag == "SZ" then
				scale.z = tonumber(value);
			end
		end	
		for flag in string.gmatch(params.typename, "@(%a+)") do 
			if flag == "AFD" then
				alphaFade = false
			elseif flag == "MX" then
				if scale.x > 0 then
					scale.x = -scale.x
				end
			elseif flag == "MY" then
				if scale.y > 0 then
					scale.y = -scale.y
				end
			elseif flag == "MZ" then
				if scale.z > 0 then
					scale.z = -scale.z
				end
			end
		end
		-- From postfix, surely this is a bug?
		-- for flag, value in string.gmatch(params.typename, "@(%a+)([.%d]+)") do 
		--	if flag == "SA" then
		--		alphaFade = false
		--	end
		-- end
		if params.meta.filename_postfix then
			for flag, value in string.gmatch(params.meta.filename_postfix, "@(%a+)([.%d]+)") do 
				if flag == "SA" then
					scale.x = tonumber(value)
					scale.y = tonumber(value)
					scale.z = tonumber(value)
				elseif flag == "SX" then
					scale.x = tonumber(value)
				elseif flag == "SY" then
					scale.y = tonumber(value)
				elseif flag == "SZ" then
					scale.z = tonumber(value)
				end
			end

			for flag in string.gmatch(params.meta.filename_postfix, "@(%a+)") do 
				if flag == "AFD" then
					alphaFade = false
				elseif flag == "MX" then
					if scale.x > 0 then
						scale.x = -scale.x
					end
				elseif flag == "MY" then
					if scale.y > 0 then
						scale.y = -scale.y
					end
				elseif flag == "MZ" then
					if scale.z > 0 then
						scale.z = -scale.z
					end
				end
			end		
		end	
		if type:getInstanceProperty("Scale") ~= scale then
			type:setInstanceProperty("Scale", scale)
		end
		
		if cfg_ImportModelComp_AlphaBlending then
			if type:getInstanceProperty("AlphaBlendingFade") ~= alphaFade then
				type:setInstanceProperty("AlphaBlendingFade", alphaFade)
			end
		end
	end
	
	if cfg_ImportModelComp_UVScale then
		if params.meta.filename_postfix then
			local scaleUV = VC2(1,1);
			for flag, value in string.gmatch(params.meta.filename_postfix, "@(%a+)([.%d]+)") do
				if flag == "SU" then
					scaleUV.x = tonumber(value);
				elseif flag == "SV" then
					scaleUV.y = tonumber(value);
				end
			end
			if (type:getInstanceProperty("ScaleUV") ~= scaleUV) then
				type:setInstanceProperty("ScaleUV", scaleUV)
			end
		end
	end

	if cfg_ImportModelComp_WRAP then
		if params.meta.filename_postfix then
			for value in string.gmatch(params.meta.filename_postfix, "@WRAP(%d+)") do 
				local valueT = {}
				for n in string.gmatch(value, "%d") do
					table.insert(valueT, n)
				end

				if hasWrap(valueT) then
					local r = tonumber(valueT[1])
					local g = tonumber(valueT[2])
					local b = tonumber(valueT[3])
					local a = tonumber(valueT[4])

					type:setInstanceProperty("WrapLightR", r)
					type:setInstanceProperty("WrapLightG", g)
					type:setInstanceProperty("WrapLightB", b)
					type:setInstanceProperty("WrapLightA", a)
					type:setInstanceProperty("WrapLightEnabled", true)
				end
			end	
		end
	end

	if cfg_ImportModelComp_SWAY then
		if params.meta.filename_postfix then
			local hasSomeSWAYParams = false;
			local swaySet = false;
			if string.find(params.typename, "@SWAY") ~= nil or string.find(params.meta.filename_postfix, "@SWAY") ~= nil then
				hasSomeSWAYParams = true;
			end
			
			local swayT = {}
			for sway in string.gmatch(params.meta.filename_postfix, "@SWAY([.,%dF-]+)") do
				for value in string.gmatch(sway, ",*([.%dF-]+)") do
					table.insert(swayT, value)
				end

				if hasSway(swayT) then
					if(not type:getInstanceProperty("SwayingEnabled"))
					then
						type:setInstanceProperty("SwayingEnabled", true)
					end
					
					local newAmplitude = VC3(tonumber(swayT[1]), tonumber(swayT[2]), tonumber(swayT[3]));
					local newFrequency = VC3(tonumber(swayT[4]), tonumber(swayT[5]), tonumber(swayT[6]));
					if(type:getInstanceProperty("SwayAmplitude") ~= newAmplitude)
					then
						type:setInstanceProperty("SwayAmplitude", newAmplitude)
					end
					if(type:getInstanceProperty("SwayFrequency") ~= newFrequency)
					then
						type:setInstanceProperty("SwayFrequency", newFrequency)
					end
					
					if ((swayT[7] == "F") and (type:getInstanceProperty("SwayingFadeEnabled") == false)) then
						type:setInstanceProperty("SwayingFadeEnabled", true)
					end
					
					if not swaySet then
						swaySet = true;
					end
				else
					-- Print invalid values
					local swayValues = "";
					for key, swayValue in ipairs(swayT) do
						swayValues = swayValues .. "<" .. swayValue .. ">";
					end			
					logger:error("SWAY not properly configured, needs 6 number values. Type: " .. params.typename .. " SWAY values: " .. swayValues);
				end
			end
			
			-- Check again that all SWAYs are set
			if hasSomeSWAYParams then
				if not swaySet then
					logger:error("Type has SWAY params but SWAY is not set. Check the SWAY params: TypeName: " .. params.typename .. " FilenamePostFix: " .. params.meta.filename_postfix);
				end
			end
		end
	end
	
	if cfg_ImportModelComp_ModelResource then
		filename = convertResourceFilename(filename);
		local resource = resourceManager:findResourceByName(filename);
		if resource ~= nil then
			if(type:getInstanceProperty("Model") ~= resource:getUnifiedHandle())
			then
				type:setInstanceProperty("Model", resource:getUnifiedHandle())
			end

			-- Sideways flag
			--if params.meta.filename_postfix then
			--	for flag in string.gmatch(params.meta.filename_postfix, "@(%a+)") do 
			--		if flag == "SI" then
			--			resource:setSideways(true);
			--		end
			--	end	
			--end

			-- First, reset specular
			local newSpecularPower = 20.0;
			local newSpecularStrength = 2.0;

			-- Specular settings
			if params.meta.filename_postfix then
				-- Basic flags
				for flag, value in string.gmatch(params.meta.filename_postfix, "@(%a+)(%d+)") do 
					if flag == "SPEC" then
						newSpecularPower = (tonumber(value))
					elseif flag == "SPECS" then
						newSpecularStrength = (tonumber(value))
					end
				end	
			end

			if(resource:getSpecularPower() ~= newSpecularPower)
			then
			  resource:setSpecularPower(newSpecularPower);
			end
			
			if(resource:getSpecularStrength() ~= newSpecularStrength)
			then
			  resource:setSpecularStrength(newSpecularStrength);
			end
		else
			logger:error("Resource = \"" .. filename .. "\" NOT FOUND. ModelResource and specular properties not set.");
		end
	end
end

--------------------------------------------------------------------------------------------------------------------------------
-- PhysicsComponent functions

function getPhysicsComponentType(typeName, parentTypeName, postFix, isLegacyType)
	typeName = convertTypeName(typeName)
	parentTypeName = convertTypeName(parentTypeName)
	parentTypeName = createDummyTypeHierarchyLegacy(typeName, parentTypeName, postFix, isLegacyType)
	typeName = typeName..postFix;

	local type = getOrCreateTypeLegacy(typeName, parentTypeName, isLegacyType)
	return type;
end

function setPhysicsCommonStuff(entityType, type, params)
	if(params.meta.collision_group)
  then
    if(params.meta.collision_group == "nocollision")
    then
      type:setInstanceProperty("CollisionGroup", engine.component.AbstractPhysicsComponent.CollisionGroupNoCollision)
    end
   
    if(params.meta.collision_group == "dynamic_terrain_object_no_static")
    then
      type:setInstanceProperty("CollisionGroup", engine.component.AbstractPhysicsComponent.CollisionGroupDynamicNoStatic)
    end
    
    if(params.meta.collision_group == "dynamic_terrain_object_no_containment")
    then
      type:setInstanceProperty("Containment", engine.component.AbstractPhysicsComponent.ContainmentNone)
    end
  end   
end

function setPhysicsDynamicStuff(entityType, type, params)
	local enumMass = editor.Util.getEnumMassFromNumericMass(params.physicsMass);
	if(type:getInstanceProperty("Mass") ~= enumMass)
	then
		type:setInstanceProperty("Mass", enumMass);
	end
	
	local lockPositionX = false;
	local lockPositionY = false;
	local lockPositionZ = false;
	local lockRotationX = false;
	local lockRotationY = false;
	local lockRotationZ = false;
  local lockJointName = ""
	
  if(params.meta.physics_disable_y_axis_movement and params.meta.physics_disable_y_axis_movement == "1")
  then
    lockJointName = lockJointName .. "PY";
    lockPositionY = true;
  end

  if(params.meta.physics_rotation_disable)
  then
    if(string.find(params.meta.physics_rotation_disable, "x"))
    then
      lockJointName = lockJointName .. "RX";
      lockRotationX = true;
    end
    if(string.find(params.meta.physics_rotation_disable, "y"))
    then
      lockJointName = lockJointName .. "RY";
      lockRotationY = true;
    end 
    if(string.find(params.meta.physics_rotation_disable, "z"))
    then
      lockJointName = lockJointName .. "RZ";
      lockRotationZ = true;
    end
  end

  if(#lockJointName > 0)
  then
    lockJointName = "LockJoint" .. lockJointName;
    local ljType = typeManager:findTypeByName(lockJointName);
    if(not ljType)
    then
      ljType = typeManager:inheritNewType(lockJointName, "LockJointComponent");
      typeManager:setTypeScript(ljType, "data/root/component_base/abstract_joint/joint/general_joint/lock_joint/" .. lockJointName .. ".fbt");
      ljType:setInstanceProperty("PositionLockX", lockPositionX);
      ljType:setInstanceProperty("PositionLockY", lockPositionY);
      ljType:setInstanceProperty("PositionLockZ", lockPositionZ);
      ljType:setInstanceProperty("RotationLockX", lockRotationX);
      ljType:setInstanceProperty("RotationLockY", lockRotationY);
      ljType:setInstanceProperty("RotationLockZ", lockRotationZ);
    end
    entityType:addComponentType(ljType:getUnifiedHandle());
  end
end

function initBoxPhysicsType(type, params)
	local newDim = params.physicsData1 * 2;
	if(type:getInstanceProperty("Dimensions") ~= newDim)
	then
		type:setInstanceProperty("Dimensions", newDim)
	end
		
end

function initConvexCompoundPhysicsType(type, params)
  -- convex compound doesn't collide with static physics or containment planes by default
  type:setInstanceProperty("CollisionGroup", engine.component.AbstractPhysicsComponent.CollisionGroupDynamicNoStatic)
  type:setInstanceProperty("Containment", engine.component.AbstractPhysicsComponent.ContainmentNone)
end

function initStaticPhysicsType(type, params)
  type:setInstanceProperty("CollisionGroup", engine.component.AbstractPhysicsComponent.CollisionGroupStatic)

	-- This is now done on C++

	--local filename = convertFileName(params.filename)
	--local cookname = filename .. ".cook"
	--local resource = resourceManager:findResourceByName(cookname)
	--if resource == nil then
	--	resourceManager:manuallyAddFile(cookname)
	--	resource = resourceManager:findResourceByName(cookname)
	--end	
	--if resource ~= nil then
	--	type:setInstanceProperty("Mesh", resource:getUnifiedHandle())
	--end	
end

--------------------------------------------------------------------------------------------------------------------------------
-- Object creation functions

function initObjectFunc(obj, params)
	local trans = obj:findComponent(engine.component.TransformComponent);
	
	local objPos = getPosition(params.pos);
	
	local objType = typeManager:getTypeByUH(obj:getType());
	if objType and objType:doesInheritTypeByName(cfg_LegacyUnitEntityTypeName) then
		trans:setPosition(VC3(objPos.x, 0.0, objPos.z));
	else
		trans:setPosition(objPos);
	end
	
	local rot = getRotation(params.rot);

	-- Do we need to do some trickery?
	local rotationModifiedFromPostfix = false;
	local rotationModifiedFromFilename = false;
	if params.properties.meta.filename_postfix then		
		-- Handle first @SI
		for flag in string.gmatch(params.properties.meta.filename_postfix, "@(%a+)") do
			if flag == "SI" then
				local q = QUAT(0,0,0,1);
				q:makeFromAngles(math.pi * 0.5, 0, 0);
				rot = q * rot;
				rotationModifiedFromPostfix = true;
				--logger:error("@SI set from filename_postfix for: " .. params.properties.typename);
			end
		end	
		
		-- Next handle @90, @180 etc.
		for flag in string.gmatch(params.properties.meta.filename_postfix, "@(%d+)") do
			local flagNumber = tonumber(flag);
			if flagNumber ~= nil and flagNumber ~= 0.0 then		
				local q = QUAT(0,0,0,1);
				q:makeFromAngles(0, math.pi * (flagNumber / 180.0), 0);
				rot = q * rot;
				rotationModifiedFromPostfix = true;
				--logger:error("@degrees set from filename_postfix for: " .. params.properties.typename);
			end
		end	
	end
	
	-- Lazy ass copypasta (filename_postfix didn't contain @degrees flags, try to search them from filename, e.g. legacy units use this)
	if params.properties.typename and rotationModifiedFromPostfix == false then
	
		-- Handle first @SI
		for flag in string.gmatch(params.properties.typename, "@(%a+)") do
			if flag == "SI" then
				local q = QUAT(0,0,0,1);
				q:makeFromAngles(math.pi * 0.5, 0, 0);
				rot = q * rot;
				rotationModifiedFromFilename = true;
				--logger:error("@SI set from filename for: " .. params.properties.typename);
			end
		end	
		
		-- Next handle @90, @180 etc.
		for flag in string.gmatch(params.properties.typename, "@(%d+)") do
			local flagNumber = tonumber(flag);
			if flagNumber ~= nil and flagNumber ~= 0.0 then		
				local q = QUAT(0,0,0,1);
				q:makeFromAngles(0, math.pi * (flagNumber / 180.0), 0);
				rot = q * rot;
				rotationModifiedFromFilename = true;
				--logger:error("@degrees set from filename for: " .. params.properties.typename);
			end
		end	
	end
	
	if rotationModifiedFromPostfix and rotationModifiedFromFilename then
		logger:error("@SI and @degrees rotations set from filenamePostix and from filename, duplicate rotation may occur for: " .. params.properties.typename);
	end
	
	--trans:setRotation(getRotation(params.rot))
	trans:setRotation(rot)

	--[[ local o1 = obj:findComponent(physics.LegacyStaticMeshPhysicsComponent)
	local o2 = obj:findComponent(physics.BoxPhysicsComponent)
	if o1 and o2 then
		logger:error(params.properties.filename)
		logger:error(params.properties.filename)
		logger:error(params.properties.filename)
		logger:error(params.properties.filename)
		logger:error("NOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO!")
		logger:error("NOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO!")
		logger:error("NOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO!")
		logger:error("NOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO!")
		logger:error("NOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO!")
		logger:error("NOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO!")
	end
	-- ]]

	params.handles[params.ueoh] = obj
end

function allowTypeMapping(entityType)
	if entityType == nil then
		return false;
	end	
	if entityType:doesInheritTypeByName(cfg_LegacyUnitEntityTypeName) then
		return true;
	end	
	return false;
end

function getMappedAIHelperType(entityType)	
	local matchType = nil;
		
	local typeName = entityType:getName();
	
	if entityType == nil then
		return matchType;
	end
	
	if not(entityType:doesInheritTypeByName("ai_moves") or entityType:doesInheritTypeByName("helper/ai_moves")) then
		return matchType;
	end

	local matchTypeName = "InvalidMatchTypeName";
	if string.find(typeName, "jump_left_1x35") ~= nil or string.find(typeName, "jump_right_1x35") ~= nil then
		matchTypeName = "Jump1x35GenericAIPathHelper";
	elseif string.find(typeName, "jump_left_2x1") ~= nil or string.find(typeName, "jump_right_2x1") ~= nil then
		matchTypeName = "Jump2x1GenericAIPathHelper";
	elseif string.find(typeName, "jump_left_4x3") ~= nil or string.find(typeName, "jump_right_4x3") ~= nil then
		matchTypeName = "Jump4x3GenericAIPathHelper";
	elseif string.find(typeName, "jump_left_5x3") ~= nil or string.find(typeName, "jump_right_5x3") ~= nil then
		matchTypeName = "Jump5x3GenericAIPathHelper";
	elseif string.find(typeName, "ledge_500mm_left") ~= nil or string.find(typeName, "ledge_500mm_right") ~= nil then
		matchTypeName = "Ledge1000GenericAIPathHelper";
	elseif string.find(typeName, "ledge_1000mm_left") ~= nil or string.find(typeName, "ledge_1000mm_right") ~= nil then
		matchTypeName = "Ledge1000GenericAIPathHelper";
	elseif string.find(typeName, "ledge_left") ~= nil or string.find(typeName, "ledge_right") ~= nil then
		matchTypeName = "Ledge1500GenericAIPathHelper";
	elseif string.find(typeName, "ledge_down_left") ~= nil or string.find(typeName, "ledge_down_right") ~= nil then
		matchTypeName = "LedgeDownGenericAIPathHelper";
	elseif string.find(typeName, "jump_left_chain_4x3") ~= nil or string.find(typeName, "jump_right_chain_4x3") ~= nil then
		matchTypeName = "JumpChain4x3GenericAIPathHelper";
	elseif string.find(typeName, "jump_left_chain_5x3") ~= nil or string.find(typeName, "jump_right_chain_5x3") ~= nil then
		matchTypeName = "JumpChain5x3GenericAIPathHelper";
	elseif string.find(typeName, "climb_left") ~= nil or string.find(typeName, "climb_right") ~= nil then
		matchTypeName = "ClimbGenericAIPathHelper";
	elseif string.find(typeName, "walk_left") ~= nil then
		matchTypeName = "LeftGenericWalkAIPathHelper";
	elseif string.find(typeName, "walk_right") ~= nil then
		matchTypeName = "RightGenericWalkAIPathHelper";
	end
	matchType = typeManager:findTypeByName(matchTypeName);

	if matchType == nil then
		logger:error("legacy_import:getAIHelperType - Didn't find matching AIHelper entity for: " .. typeName);
	end
	return matchType;
end

function getMappedCheckpointType(entityType)	
	local matchType = nil;
		
	local typeName = entityType:getName();
	
	if entityType == nil then
		return matchType;
	end
	
	if not(entityType:doesInheritTypeByName("checkpoint") or entityType:doesInheritTypeByName("use_item/checkpoint") or 
			entityType:doesInheritTypeByName("t2_checkpoint") or entityType:doesInheritTypeByName("use_item/t2_checkpoint") ) then
		return matchType;
	end

	local matchTypeName = "InvalidMatchTypeName";
	if string.find(typeName, "statue_castle") ~= nil then
		matchTypeName = "SwampCheckpoint";
	elseif string.find(typeName, "statue_desert") ~= nil then
		matchTypeName = "SwampCheckpoint";
	elseif string.find(typeName, "statue_blood") ~= nil then
		matchTypeName = "SwampCheckpoint";
	elseif string.find(typeName, "statue_forest") ~= nil then
		matchTypeName = "SwampCheckpoint";
	elseif string.find(typeName, "checkpoint_ball") ~= nil then
		matchTypeName = "SwampCheckpoint";
	elseif string.find(typeName, "checkpoint_ball_witch") ~= nil then
		matchTypeName = "WitchCheckpoint";		
	elseif string.find(typeName, "statue_witch") ~= nil then
		matchTypeName = "WitchCheckpoint";
	end
	matchType = typeManager:findTypeByName(matchTypeName);
	
	if matchType == nil then
		logger:error("legacy_import:getMappedCheckpointType - Didn't find matching Checkpoint entity for: " .. typeName);
	end
	return matchType;
end

function createObject(tm, params)
	if not cfg_ImportObjectInstances then
		return;
	end
	
	if not cfg_ImportTypes then
		logger:error("legacy_import:createObject - Trying to import object without importing the types.");
		return;
	end
	
	local entityType = tm.entityType;
	
	local foundHackMatch = false;
	
	if not(foundHackMatch) and allowTypeMapping(entityType) then
		-- Try to map AI helpers to their corresponding types
		local mappedType = getMappedAIHelperType(entityType);
		if mappedType ~= nil then
			entityType = mappedType;
			
			-- Shift a bit up (pivots are in different place)
			local posZ = params.pos.z;
			local typeName = entityType:getName();
			if string.find(typeName, "Ledge1000") ~= nil then
				posZ = params.pos.z + 1.0;
			elseif string.find(typeName, "Ledge1500") ~= nil then
				posZ = params.pos.z + 1.5;
			elseif string.find(typeName, "Ledge2500") ~= nil then
				posZ = params.pos.z + 2.5;
			end
			params.pos = VC3(params.pos.x, params.pos.y + 2.0, posZ);
			foundHackMatch = true;
		end
	end
	
	if not(foundHackMatch) and allowTypeMapping(entityType) then
		-- Try to map Checkpoints to their corresponding types
		local mappedType = getMappedCheckpointType(entityType);
		if mappedType ~= nil then
			-- Shift a bit up (pivots are in different place)
			local posZ = params.pos.z;
			local typeName = entityType:getName();
			if string.find(typeName, "checkpoint_ball") ~= nil then
				--posZ = params.pos.z + 1.25; -- Should be in correct pos
			elseif string.find(typeName, "statue") ~= nil then
				posZ = params.pos.z + 2.5;
			end
			params.pos = VC3(params.pos.x, params.pos.y, posZ);

			entityType = mappedType;
			
			foundHackMatch = true;
		end
	end
	return getSceneInstanceManager():createNewInstance(entityType:getUnifiedHandle(), initObjectFunc, params);
end

--------------------------------------------------------------------------------------------------------------------------------
-- Joint creation functions

function getJointLocalPosition(object, jointPos)
	local trans = object:findComponent(engine.component.TransformComponent)
	local pos = trans:getPosition()
	local rot = trans:getRotation()	
	
	--local posMat = MAT()
	--posMat:createTranslationMatrix(pos)
	--local rotMat = MAT()
	--rotMat:createRotationMatrix(rot)
	--rotMat:multiply(posMat)
	--local tm = rotMat
	--tm = tm:getInverse()

	--return tm:getTransformedVector(jointPos)
end

function initJoinFunc(joint, params)
	if not cfg_ImportJointInstances then
		return;
	end

	local trans = joint:findComponent(engine.component.TransformComponent)
	local jointPosition = getPosition(params.position)
	trans:setPosition(jointPosition)

	local linkedAToStatic = false;
	local linkedBToStatic = false;
	
	local jointComponent = joint:getJointComponent()
	local objectA = params.handles[params.meta.object_id_a]
	if objectA ~= nil then
		local physicsComponent = objectA:getPhysicsComponent()
		local staticPhysicsComponent = objectA:findComponent(physics.LegacyStaticMeshPhysicsComponent)
		
		-- Prevent linking to static physics
		if physicsComponent ~= nil and staticPhysicsComponent == nil then
			jointComponent:setComponent0(physicsComponent:getUnifiedHandle())
		else
			-- This actually may not be an error, in trine1 joints have been linked to static objects, now just ignore the static object
			--logger:error("Joint without a physics component to link to.");
			linkedAToStatic = true;
		end	
	end

	local objectB = params.handles[params.meta.object_id_b]
	if objectB ~= nil then
		local physicsComponent = objectB:getPhysicsComponent()
		local staticPhysicsComponent = objectB:findComponent(physics.LegacyStaticMeshPhysicsComponent)

		-- Prevent linking to static physics
		if physicsComponent ~= nil and staticPhysicsComponent == nil then
			jointComponent:setComponent1(physicsComponent:getUnifiedHandle())
		else
			linkedBToStatic = true;
		end
	end
	
	if ((linkedAToStatic and not(linkedBToStatic)) or jointComponent:getComponent0() == UH_NONE) then
		-- Swap
		jointComponent:setComponent0(jointComponent:getComponent1());
		jointComponent:setComponent1(UH_NONE);
	end
	
	if (linkedAToStatic and linkedBToStatic) then
		logger:error("Tried to create joint without a physics components. Joint UH: " .. tostring(jointComponent:getUnifiedHandle()));
	end

	-- Apply properties
	local m = params.meta

	function tonegative(f)
		if f > 0 then
			return -f
		end
		return f
	end

	function topositive(f)
		if f < 0 then
			return -f
		end
		return f
	end

	if m.break_force and m.break_force ~= "0" then
		jointComponent:setBreakForce(topositive(tonumber(m.break_force)))
	end
	if m.drive_force then
		local df = VC2(0,0)
		df.x = tonumber(m.drive_force)
		--df.y = df.x
		df.y = 0
		jointComponent:setRotationDriveForce(df)
	end
	if m.drive_velocity then
		local dv = VC3(0,0,0)
		dv.x = tonumber(m.drive_velocity)
		--dv.y = dv.x
		--dv.z = dv.x
		dv.y = 0
		dv.z = 0
		jointComponent:setRotationDriveVelocity(dv)
	end
	
	if m.limit_high_angle and m.limit_high_angle ~= "none" then
		if jointComponent.setRotationLimitHighAngle then
			-- NOTE: Some joints don't have this??
			jointComponent:setRotationLimitHighAngle(tonumber(m.limit_high_angle))
		end
	else
		if jointComponent.setRotationLimitHighAngle then
			jointComponent:setRotationLimitHighAngle(360)
		end
	end
	if m.limit_high_spring_damping then
		-- NOTE: REMOVED in PhysX2 -> PhysX3 update
		--jointComponent:setRotationLimitHighDamping(tonumber(m.limit_high_spring_damping))
	end
	if m.limit_high_spring_force then
		-- NOTE: REMOVED in PhysX2 -> PhysX3 update
		--jointComponent:setRotationLimitHighSpring(tonumber(m.limit_high_spring_force))
	end
	if m.limit_high_spring_restitution then
		-- NOTE: REMOVED in PhysX2 -> PhysX3 update
		--jointComponent:setRotationLimitHighRestitution(tonumber(m.limit_high_spring_restitution))
	end

	if jointComponent.setRotationLimitLowAngle then
		if m.limit_low_angle and m.limit_low_angle ~= "none" then
			jointComponent:setRotationLimitLowAngle(tonumber(m.limit_low_angle))
		else
			jointComponent:setRotationLimitLowAngle(-360)
		end
	end
	
	if m.limit_low_spring_damping then
		-- NOTE: REMOVED in PhysX2 -> PhysX3 update
		--jointComponent:setRotationLimitLowDamping(tonumber(m.limit_low_spring_damping))
	end
	if m.limit_low_spring_force then
		-- NOTE: REMOVED in PhysX2 -> PhysX3 update
		--jointComponent:setRotationLimitLowSpring(tonumber(m.limit_low_spring_force))
	end
	if m.limit_low_spring_restitution then
		-- NOTE: REMOVED in PhysX2 -> PhysX3 update
		--jointComponent:setRotationLimitLowRestitution(tonumber(m.limit_low_spring_restitution))
	end
	
	-- HACK: Remove me, this is just a test...
	-- Set some magic value by default that joint will be NX_D6JOINT_MOTION_FREE???
	-- if jointComponent:getRotationLimitHighAngle() == 0 and jointComponent:getRotationLimitLowAngle() == 0 then
	-- 	jointComponent:setRotationLimitHighAngle(10);
	-- end

	if m.pos_damping then
		jointComponent:setPositionLimitDamping(tonumber(m.pos_damping))
	end
	if m.pos_spring then
		jointComponent:setPositionLimitSpring(tonumber(m.pos_spring))
	end

	-- Unimplemented
	--properties.meta.pos_limit_x = "0,0"
	--properties.meta.pos_limit_y = "0,0"
	--properties.meta.pos_limit_z = "0,0"

	-- And anchor
	-- NOTE: REMOVED in PhysX2 -> PhysX3 update
	--jointComponent:setGlobalAnchor(jointPosition)
	-- Replacing property?
	jointComponent:setGlobalPosition(jointPosition)

	-- This info string should be saved with the joint
	local info = makePropertiesString(params.meta)
end

function createJoint(params)
	if not cfg_ImportJointInstances then
		return;
	end

	parentTypeName = "GeneralJointEntity"
	typeName = string.gsub(params.name, "C, joint/", "");
	
	local result = nil;
	local resultPos = 0;
	
	result = string.find(typeName, "hinge/x", resultPos);
	if result ~= nil then
		parentTypeName = "HingeJoint"
		typeName = string.gsub(typeName, "hinge/x", "XHingeJoint");
	end

	result = string.find(typeName, "hinge/y", resultPos);
	if result ~= nil then
		parentTypeName = "HingeJoint"
		typeName = string.gsub(typeName, "hinge/y", "YHingeJoint");
	end
	
	result = string.find(typeName, "hinge/z", resultPos);
	if result ~= nil then
		parentTypeName = "HingeJoint"
		typeName = string.gsub(typeName, "hinge/z", "ZHingeJoint");
	end

	result = string.find(typeName, "pulley", resultPos);
	if result ~= nil then
		parentTypeName = "LegacyPulleyJointEntity"
		typeName = string.gsub(typeName, "pulley", "PulleyJointEntity");
	end
	
	result = string.find(typeName, "d3joint", resultPos);
	if result ~= nil then
		--parentTypeName = "GeneralJointEntity"
		--typeName = string.gsub(typeName, "d3joint", "d3Joint");
		logger:error("Unsupported joint type (d3joint).");
		return nil;
	end
	local isLegacyType = false;
	parentTypeName = createDummyTypeHierarchyLegacy(typeName, parentTypeName, "", isLegacyType)
	local entityType = getOrCreateTypeLegacy(typeName, parentTypeName, isLegacyType)

	return getSceneInstanceManager():createNewInstance(entityType:getUnifiedHandle(), initJoinFunc, params);
end

--------------------------------------------------------------------------------------------------------------------------------
-- Create entity and related types

function createTypes(tm)
	if not cfg_ImportTypes then
		return;
	end
	
	local properties = tm.properties;
	
	local isLegacyType = properties.useLegacyUnitEntityType;
	
	if cfg_ImportEntityTypes then
		-- Main entity	
		if properties.useLegacyUnitEntityType then
			-- object to legacy_unit
			properties.typename = string.gsub(properties.typename, "data/model/", "data/model/legacy_unit/");
			properties.typename = string.gsub(properties.typename, "object/", "");
			tm.entityType = getEntityType(properties.typename, cfg_LegacyUnitEntityTypeName, properties, isLegacyType);
			
		else
			if string.find(properties.typename, "/skymodel/") ~= nil or string.find(properties.typename, "/sky_model/") ~= nil then
			
				if string.find(properties.typename, "/astralsky/") ~= nil or string.find(properties.typename, "/astral_sky/") ~= nil then
					tm.entityType = typeManager:findTypeByName("AstralSky");
				elseif string.find(properties.typename, "/desert/") ~= nil or string.find(properties.typename, "/desert_sky/") ~= nil then
					tm.entityType = typeManager:findTypeByName("DesertSky");
				elseif string.find(properties.typename, "/dragonsky/") ~= nil or string.find(properties.typename, "/dragon_sky/") ~= nil then
					tm.entityType = typeManager:findTypeByName("DragonSky");
				elseif string.find(properties.typename, "/emptysky/") ~= nil or string.find(properties.typename, "/empty_sky/") ~= nil then
					tm.entityType = typeManager:findTypeByName("EmtpySky");
				elseif string.find(properties.typename, "/morning/") ~= nil or string.find(properties.typename, "/morning_sky/") ~= nil then
					tm.entityType = typeManager:findTypeByName("MorningSky");
				elseif string.find(properties.typename, "/night_swamp/") ~= nil or string.find(properties.typename, "/night_swamp_sky/") ~= nil then
					tm.entityType = typeManager:findTypeByName("NightSwampSky");
				elseif string.find(properties.typename, "/sareksky/") ~= nil or string.find(properties.typename, "/sarek_sky/") ~= nil then
					tm.entityType = typeManager:findTypeByName("SarekSky");
				elseif string.find(properties.typename, "/spookysky/") ~= nil or string.find(properties.typename, "/spooky_sky/") ~= nil then
					tm.entityType = typeManager:findTypeByName("SpookySky");			
				end			
				if tm.entityType == nil then
					logger:error("No skymodel found, using default ObjectEntity.");
					tm.entityType = getEntityType(properties.typename, "ObjectEntity", properties, isLegacyType);
				end			
			else
				tm.entityType = getEntityType(properties.typename, "ObjectEntity", properties, isLegacyType);
			end
		end
		initEntityType(tm.entityType, params);
	end

	if cfg_ImportModelComponentTypes then
		-- Model component
		if properties.useLegacyUnitEntityType then
			tm.modelType = getModelComponentType(properties.typename, "LegacyUnitModelComponent", properties, isLegacyType);
		else
			tm.modelType = getModelComponentType(properties.typename, "ModelComponent", properties, isLegacyType);
		end		
		initModelComponentType(tm.modelType, properties);
		tm.entityType:addComponentType(tm.modelType:getUnifiedHandle());
	end
	
	if cfg_ImportPhysicsComponentTypes then
		-- Physics components
		local needNetSync = false
		local physicsType = tonumber(tm.properties.physicsType);
		
		-- HACK: Axel rose (remove physics)
		if string.find(properties.typename, "axel_rose") ~= nil then
			physicsType = -1;
		end
		
		-- HACK: Remove physics from collison helpers, they should be configured manually
		if string.find(properties.typename, "collision_solid") ~= nil then
			physicsType = 9876;
		elseif string.find(properties.typename, "collision_firethru") ~= nil then
			physicsType = 9876;
		end
		
		
		if physicsType == 2 then
			-- Box Physics
			tm.physicsType = getPhysicsComponentType(properties.typename, "LegacyBoxPhysicsComponent", editor.Util.BoxPhysicsComponentPostfix, isLegacyType)
			initBoxPhysicsType(tm.physicsType, properties)
			tm.entityType:addComponentType(tm.physicsType:getUnifiedHandle())
			setPhysicsCommonStuff(tm.entityType, tm.physicsType, properties)
			setPhysicsDynamicStuff(tm.entityType, tm.physicsType, properties)	
		elseif physicsType == 6 then
			-- ConvexCompound Physics
			tm.physicsType = getPhysicsComponentType(properties.typename, "LegacyConvexCompoundPhysicsComponent", editor.Util.ConvexCompoundPhysicsComponentPostfix, isLegacyType)
			initConvexCompoundPhysicsType(tm.physicsType, properties)		
			tm.entityType:addComponentType(tm.physicsType:getUnifiedHandle())
			setPhysicsCommonStuff(tm.entityType, tm.physicsType, properties)
			setPhysicsDynamicStuff(tm.entityType, tm.physicsType, properties)
		elseif physicsType == 1 then
			-- Static Physics
			if cfg_ImportPhysicsStaticMeshComponentTypes then
				tm.physicsType = getPhysicsComponentType(properties.typename, "LegacyStaticMeshPhysicsComponent", editor.Util.StaticPhysicsComponentPostfix, isLegacyType)
				initStaticPhysicsType(tm.physicsType, properties)
				tm.entityType:addComponentType(tm.physicsType:getUnifiedHandle())
				setPhysicsCommonStuff(tm.entityType, tm.physicsType, properties)
			end
		elseif physicsType == 9876 then
			-- Static Box Physics
			if cfg_ImportPhysicsStaticBoxComponentTypes then
				tm.physicsType = getPhysicsComponentType(properties.typename, "LegacyStaticBoxPhysicsComponent", editor.Util.StaticPhysicsComponentPostfix, isLegacyType)
				initStaticPhysicsType(tm.physicsType, properties)
				tm.entityType:addComponentType(tm.physicsType:getUnifiedHandle())
				setPhysicsCommonStuff(tm.entityType, tm.physicsType, properties)
			end
		end

		if needNetSync == true then
			-- Should we create a hierarchy for this one as well?
			-- local type = typeManager:findTypeByName("NetSyncComponent")
			-- if type ~= nil then
			-- 	tm.entityType:addComponentType(type:getUnifiedHandle())
			-- end
		end
	end
end

--------------------------------------------------------------------------------------------------------------------------------
-- Light creation functions

function initPointLightFunc(light, params)
	if not cfg_ImportLightInstances then
		return;
	end

	light:getTransformComponent():setPosition(getPosition(params.position))

	local lightComponent = light:getLightComponent()
	lightComponent:setRange(params.radius)
	lightComponent:setColor(params.color)
	lightComponent:setIntensity(params.meta.intensity)

	if params.meta.affectSolid == 1 then
		lightComponent:setRenderSolidObjects(true)
	else
		lightComponent:setRenderSolidObjects(false)
	end

	if params.meta.affectAlpha == 1 then
		lightComponent:setRenderAlphaObjects(true)
	else
		lightComponent:setRenderAlphaObjects(false)
	end

	if params.meta.useWrap == 1 then
		lightComponent:setWrapLight(true)
	else
		lightComponent:setWrapLight(false)
	end

	-- This info string should be saved with the light
	local info = makePropertiesString(params.meta)
end

function createPointlight(params)
	if not cfg_ImportLightInstances then
		return;
	end

	local type = typeManager:findTypeByName("PointLightEntity")	
	getSceneInstanceManager():createNewInstance(type:getUnifiedHandle(), initPointLightFunc, params);
end

function initSpotLightFunc(light, params)
	if not cfg_ImportLightInstances then
		return;
	end

	local transformComponent = light:getTransformComponent()
	transformComponent:setPosition(getPosition(params.position))
	transformComponent:setRotationAngles(tonumber(params.meta.yAngle), tonumber(params.meta.angle), 0)

	local lightComponent = light:getLightComponent()
	lightComponent:setRange(params.range)
	lightComponent:setFov(params.fov * 180.0 / math.pi)
	lightComponent:setColor(params.color)
	lightComponent:setIntensity(params.meta.intensity)
	lightComponent:setConeMultiplier(params.meta.cone)
	if params.meta.shadow == 1 then
		lightComponent:setShadows(true)
	else
		lightComponent:setShadows(false)
	end
	lightComponent:setShadowStrength(params.meta.shadowStrength)
	if params.meta.fade == 1 then
		lightComponent:setFade(true)
	else
		lightComponent:setFade(false)
	end
	if params.meta.coneOnly == 1 then
		lightComponent:setConeOnly(true)
	else
		lightComponent:setConeOnly(false)
	end

	if params.meta.useWrap == 1 then
		lightComponent:setWrapLight(true)
	else
		lightComponent:setWrapLight(false)
	end

	if params.meta.isOrtho == 1 then
		lightComponent:setOrthogonalProjection(true)
	else
		lightComponent:setOrthogonalProjection(false)
	end

	if params.meta.texture then
		local texture1 = convertTextureFileName(params.meta.texture)
		
		if texture1 == nil then
			logger:warning("SpotLight, Trying to search texture with nil name. (" .. tostring(lightComponent:getUnifiedHandle()) .. ")");
		else
			texture1 = convertResourceFilename(texture1);
			if string.len(texture1) ~= 0 then
				local r1 = resourceManager:findResourceByName(texture1)
				if r1 ~= nil then
					lightComponent:setProjectionTexture(r1:getUnifiedHandle())
				else
					logger:error("SpotLight, Texturename = \"" .. texture1 .. "\" NOT FOUND. (" .. tostring(lightComponent:getUnifiedHandle()) .. ")");
				end
			end
		end
	end

	if params.meta.coneTexture then
		local texture2 = convertTextureFileName(params.meta.coneTexture)
				
		if texture2 == nil then
			logger:warning("SpotLight, Trying to search texture (coneTexture) with nil name. (" .. tostring(lightComponent:getUnifiedHandle()) .. ")");
		else
			texture2 = convertResourceFilename(texture2);				
			if string.len(texture2) ~= 0 then
				local r2 = resourceManager:findResourceByName(texture2)
				if r2 ~= nil then
					lightComponent:setConeTexture(r2:getUnifiedHandle())
				else
					logger:error("SpotLight, Texturename = \"" .. texture2 .. "\" (coneTexture) NOT FOUND. (" .. tostring(lightComponent:getUnifiedHandle()) .. ")");
				end
			end
		end
	end

	-- This info string should be saved with the light
	local info = makePropertiesString(params.meta)
end

function createSpotlight(params)
	if not cfg_ImportLightInstances then
		return;
	end

	local type = typeManager:findTypeByName("SpotLightEntity")	
	getSceneInstanceManager():createNewInstance(type:getUnifiedHandle(), initSpotLightFunc, params);
end

function initAmbientLightFunc(light, params)
	if not cfg_ImportLightInstances then
		return;
	end

	local transformComponent = light:getTransformComponent()
	transformComponent:setPosition(getPosition(params.position))

	local lightComponent = light:getLightComponent()
	if lightComponent then
		lightComponent:setColor1(params.color1)
		lightComponent:setColor2(params.color2)
		lightComponent:setFactor(params.factor)
	else
		logger:error("No AmbientLightComponent found.");
	end
end

function createAmbientlight(params)
	if not cfg_ImportLightInstances then
		return;
	end

	local type = typeManager:findTypeByName("AmbientLightEntity")	
	getSceneInstanceManager():createNewInstance(type:getUnifiedHandle(), initAmbientLightFunc, params);
end

--------------------------------------------------------------------------------------------------------------------------------
-- Importer helper methods

-- Finalize 
function finishImport()
	app:finishLoading()
	app:processResources()
	state:rebalanceInstanceTree()
end

function clearAllErrorTags()
	app:clearAllErrorTags();
end

function loadEmptyScene()
	state:loadEmpty();
end

function loadEmptySceneAndClearErrors()
	clearAllErrorTags();
	state:loadEmpty();
end

function saveAllResourcesAndTypes()
	resourceManager:saveAllResources();
	state:saveTypes();
	app:processResources();
end

function saveScene(filename)
	state:saveScenes(filename, engine.state.EditorFile);
end

function importObjects(filename)
	dofile(filename);
end

function importLevel(from, to, runAndStopGameAfterImport)
	if not isLevelImportingAllowed() then
		logger:error(getEnableLevelImportingFailMessage());
		return;
	end	

	if from == nil or to == nil then
		logger:error("legacy_import:importLevel - \"From\" or \"To\" param is nil.");
		return;
	end
		
	loadEmptyScene();
	
	importObjects(from);
	finishImport();
	saveAllResourcesAndTypes();
	saveScene(to, trinebase.state.EditorFile);
	
	if runAndStopGameAfterImport then
		app:finishLoading();
		app:processResourcesWithTitle("Starting game (multi-import)...");
		app:startGame();
		app:stopGame();
	end
end

--------------------------------------------------------------------------------------------------------------------------------
