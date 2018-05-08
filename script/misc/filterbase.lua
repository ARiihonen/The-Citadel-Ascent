module(..., package.seeall)

_G.filters = {}

_G.filterName = ""
_G.filterDescription = ""

_G.createdFilter = {}

function _G.createFilter(filterIdString)
  _G.createdFilter = {}
  _G.createdFilter.expectingStart = true
  _G.defineFilterId = filterIdString
  return createdFilter
end

function _G.startFilterDefinition()
  if (not(_G.createdFilter.expectingStart)) then
    log:error("createFilter expected before startFilterDefinition")
  end
  _G.createdFilter.expectingStart = nil
  _G.createdFilter.expectingEnd = true

  _G.filterName = ""
  _G.filterDescription = ""
  _G.defineFilterObject = _G.defaultDefineFilterObject
  _G.defineFilterChildIteration = _G.defineFilterChildIteration
end

function _G.endFilterDefinition()
  if (not(_G.createdFilter.expectingEnd)) then
    log:error("startFilterDefinition expected before endFilterDefinition")
  end
  _G.createdFilter.expectingEnd = nil

  if (_G.defineFilterObject == _G.defaultDefineFilterObject) then
    log:error("You must have the defineFilterObject function definition in the filter.")
  end
  
  _G.createdFilter.filterObject = _G.defineFilterObject
  _G.createdFilter.filterChildIteration = _G.defineFilterChildIteration
  _G.createdFilter.valid = true
  
  --filteringModule.defineScriptedFilter(_G.defineFilterId, _G.filterName, _G.filterDescription);  
  --_G.createdFilter = {}  
end

function _G.defaultDefineFilterObject(obj)
  -- this triggering indicates that you have either omitted the defineFilterObject in your filter file
  -- or you somehow screwed up the filter start/end or something like that.
  log:error("You must have the defineFilterObject function definition in the filter.")
end

function _G.defaultDefineFilterChildIteration(obj)
  -- by default, any child is ok
  return true
end

function _G.validateFilter(filterobj)
  if (filterobj) then
    if (filterobj.valid) then
      return true
    end
  end  
  return false
end

-----------------------------------------------------------------------------------
-- a list of native filters...
-- NOTE: THIS IS SOME DEPRECATED STUFF, THE NATIVE FILTERS ARE HARD CODED + SCANNED FROM data/filter/native/...
-----------------------------------------------------------------------------------

--[[
function nativeFilter_Composite_AllowAll_AllowAll() 
  --filteringModule.defineNativeFilter("Composite_AllowAll_AllowAll", "All", "This filter allows any object.");
  _G.createdFilter = {}
  _G.createdFilter.native = true
  _G.createdFilter.nativeId = "Composite_AllowAll_AllowAll"
  _G.filterName = "All"
  _G.filterDescription = "This filter allows any object."
end

function nativeFilter_Composite_DenyAll_DenyAll() 
  --filteringModule.defineNativeFilter("Composite_DenyAll_DenyAll", "None", "This filter drops out all objects.");
  _G.createdFilter = {}
  _G.createdFilter.native = true
  _G.createdFilter.nativeId = "Composite_DenyAll_DenyAll"
  _G.filterName = "None"
  _G.filterDescription = "This filter drops out all objects."  
end
--]]
