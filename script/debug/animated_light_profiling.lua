module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

----------------------------------------------------------------------------------------------------------

local thisModule = _M

declareReload(thisModule, [[offedTimers]])
declareReload(thisModule, [[timersOff]])

-- (copy&pasted from editor script)
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

function animatedLightsOff()
	seekInstances("All", "AnimatedPointLightEntity", function (o) o:findComponent(gameplay.TimerComponent):setEnabled(false) end)
end

function animatedLightsOn()
	seekInstances("All", "AnimatedPointLightEntity", function (o) o:findComponent(gameplay.TimerComponent):setEnabled(true) end)
end

timersOff = false
offedTimers = { }

function allTimersOff()
	if (timersOff) then
		return
	end
	timersOff = true
	offedTimers = { }
	local offfunc = function (o) 
		if o:findComponent(gameplay.TimerComponent) then 
			if o:findComponent(gameplay.TimerComponent):getEnabled() == true then
				table.insert(offedTimers, o) 
				o:findComponent(gameplay.TimerComponent):setEnabled(false) 
			end
		end
	end
	seekInstances("All", nil, offfunc)
end

function allTimersOn()
	-- restore ones that were set off only
	--seekInstances("All", nil, function (o) if o:findComponent(gameplay.TimerComponent) then o:findComponent(gameplay.TimerComponent):setEnabled(true) end)
	if (not(timersOff)) then
		return
	end
	
	for i=1,#offedTimers do
		local o = offedTimers[i]
		o:findComponent(gameplay.TimerComponent):setEnabled(true)
	end
	
	timersOff = false
	offedTimers = { }
end

