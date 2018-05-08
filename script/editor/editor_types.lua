module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

-- this file contains some editor type "overrides". (aliases)
-- when a property has the EditorHint_Type_... associated with it, then the string following that
-- will be considered as the type name, instead of the actual property type.

-- this file has to provide the conversion function used to simulate the types...
-- that is, for each editor type, there must be a function that looks like a constructor for the type, and
-- actually constructs an object of the real implementing type

-- FIXME: in reality, these need to be types, not just constructor functions - as it would be nice to be able
-- to access individual properties of such types. like .x .y and .z for the position

-- "Rotation" is "QUAT" in reality
function _G.Rotation(quatX, quatY, quatZ, quatW)
  return QUAT(quatX, quatY, quatZ, quatW)
end

-- "Position" is "VC3" in reality
function _G.Position(x,y,z)
  return VC3(x,y,z)
end

-- "Scale" is "VC3" in reality
function _G.Scale(x,y,z)
  return VC3(x,y,z)
end

-- "Size" is "VC3" in reality
function _G.Size(x,y,z)
  return VC3(x,y,z)
end

-- "Offset" is "VC3" in reality
function _G.Offset(x,y,z)
  return VC3(x,y,z)
end

-- "TCB" is "VC3" in reality (on the engine side... yet, editor has a separate TCB data class)
function _G.TCB(x,y,z)
  return VC3(x,y,z)
end

-- (Unused.)
_G.TCB_Smooth = TCB(0,0,0)
_G.TCB_Flat = TCB(1,0,0)
_G.TCB_Sharp = TCB(0,-1,0)

-- TCBPropertyArray is VC3PropertyArray
function _G.TCBPropertyArray(entryTable)
  return VC3PropertyArray(entryTable)
end

-- "Length" is "float" in reality
function _G.Length(x)
  return x
end

-- "Amount" is "int" in reality - which is number (float) in lua :)
-- FIXME: mount? :)
function _G.mount(x)
  return x
end

-- "ModelResource" is "UH" in reality
function _G.ModelResource(guid)
  local uh = resourceManager:findUHByGUID(guid)
  return UH(uh)
end

-- "AnimationResource" is "UH" in reality
function _G.AnimationResource(guid)
  local uh = resourceManager:findUHByGUID(guid)
  return UH(uh)
end

-- CustomStruct/CustomStructArray does not exist in C++ side, they needs to be converted to plain lua tables for further processing
function _G.CustomStruct(valueTypeInfo, ...)
	local valueTypeArr = split_compat(valueTypeInfo, ",")
	local ret = { valueTypeInfo = valueTypeArr, values = { } }
	for i,v in ipairs(arg) do
		table.insert(ret.values, v)
	end
	return ret
end

function _G.CustomStructArray(valueTypeInfo, valuePropertyMapping, curveInfoStr, arrayOfCustomStructs)
	local valueTypeArr = split_compat(valueTypeInfo, ",")
	local valuePropNameArr = split_compat(valuePropertyMapping, ",")
	local ret = { valueTypeInfo = valueTypeArr, valuePropertyMapping = valuePropNameArr, curveInfo = curveInfoStr, arrayOfCustomStructs = arrayOfCustomStructs }	
	return ret
end

-- "EditorAutoCompleteString" is a string in reality
-- not handled here.
--function _G.EditorAutoCompleteString(str)
--  return str
--end

_G.True = true
_G.False = false

-- Aliases for some specific rotations
_G.RotationIdentity = QUAT(0, 0, 0, 1)
_G.Rotated90DegClockwiseAroundY = QUAT(0, -0.707107, 0, 0.707107)
_G.Rotated90DegCounterClockwiseAroundY = QUAT(0, 0.707107, 0, 0.707107)
_G.Rotated90DegClockwiseAroundX = QUAT(-0.707107, 0, 0, 0.707107)
_G.Rotated90DegCounterClockwiseAroundX = QUAT(0.707107, 0, 0, 0.707107)
_G.Rotated90DegClockwiseAroundZ = QUAT(0, 0, 0.707107, 0.707107)
_G.Rotated90DegCounterClockwiseAroundZ = QUAT(0, 0, -0.707107, 0.707107)


