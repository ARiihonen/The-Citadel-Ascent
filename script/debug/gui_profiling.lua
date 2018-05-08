module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

----------------------------------------------------------------------------------------------------------

local thisModule = _M

-- (copy&pasted from editor script)
function seekResourcesWithMultiLevelFilter(multiLevelFilterString, classNameToSeek, seekResultFunction)
	assert_string(multiLevelFilterString)
	assert_string_or_nil(classNameToSeek)
	assert_function(seekResultFunction)

	local filterString = multiLevelFilterString
	local maxDepth = 99999
	local forceParentsOfMatchesToMatch = false;
	local root = resourceManager:getResourceRoot()

	local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilter(root, filterString, maxDepth, forceParentsOfMatchesToMatch)

	local totalObjectsChecked = 0
	local totalObjectsFound = 0

	local obj = resultIterator:next()
	while (obj) do
		local n = obj:getClassName()
		if (classNameToSeek == nil or n == classNameToSeek) then			
			seekResultFunction(obj);
			totalObjectsFound = totalObjectsFound + 1
			logger:debug("Accepting resource " .. obj:getName())
		else
			--logger:debug("Skipping resource " .. obj:getName())
		end

		totalObjectsChecked = totalObjectsChecked + 1
		obj = resultIterator:next()
	end
	
	logger:debug("Total ".. tostring(totalObjectsChecked) .. " objects iterated out of which " .. tostring(totalObjectsFound) .. " were found to be of given type.")	
end

function seekResources(filterResourceName, classNameToSeek, seekResultFunction)
	-- Note, this could be optimized, not to use the multi level filter... but assuming that that is not the biggest performance problem anyway
	local filterString = "0," .. filterResourceName
	seekResourcesWithMultiLevelFilter(filterString, classNameToSeek, seekResultFunction)
end

function makeLoadedTextureResourcesAlwaysLoaded()
	seekResources("data/filter/native/nativefilter_resource_is_loaded", "TextureResource", function (o) o:setAlwaysLoaded(true) end)
end

