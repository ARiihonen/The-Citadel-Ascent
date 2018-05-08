module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

-- "Do the lua expression only once" (disable self). 
-- This is done in game mode only, not in the editor, even if the expression was evaluated in the editor.
-- This can be used as an optimization hack really, when some special event / complex logic is going to be triggered based on the input values.
function _G.disableExpression()
	-- TODO: need flag to indicate this...
	-- _G.disableCallerCustomLuaExpression = true
end



function _G.runCapture(team1AreaName, team2AreaName, propertyEntityName)
	if (InFloat1 > _G.OutFloat2 + 0.1) then
		if (InFloat1 > _G.OutFloat2 + 2) then
			_G.OutFloat2 = InFloat1
		else
			_G.OutFloat2 = _G.OutFloat2 + 0.1
		end
	else
		return
	end
	
	assert_string(team1AreaName)
	assert_string(team2AreaName)
	assert_string(propertyEntityName)
	
	local area1 = scene:getSceneInstanceManager():findInstanceByName(team1AreaName)
	local area2 = scene:getSceneInstanceManager():findInstanceByName(team2AreaName)
	local props = scene:getSceneInstanceManager():findInstanceByName(propertyEntityName)
	
	local t1Occupied = false
	local t2Occupied = false
	t1Occupied = area1:findComponent(area.CollectorAreaComponent):getHasCollectedInstances()
	t2Occupied = area2:findComponent(area.CollectorAreaComponent):getHasCollectedInstances()

	local valuesOutComp = props:findComponent(propertyanimation.proputil.FloatSelectComponent)

	if (t1Occupied and t2Occupied) then
		local v = valuesOutComp:getInFloat3()
		v = 0
		valuesOutComp:setInFloat1(0)
		valuesOutComp:setInFloat2(0)
		valuesOutComp:setInFloat3(v)
		valuesOutComp:setInFloat4(0)
		valuesOutComp:setInFloat5(0)
	elseif (t1Occupied) then
		local v = valuesOutComp:getInFloat3()
		v = v - 100
		valuesOutComp:setInFloat4(1)
		valuesOutComp:setInFloat5(0)
		if (v < -5000) then
			v = -5000
			valuesOutComp:setInFloat1(1)
			valuesOutComp:setInFloat2(0)
		end
		valuesOutComp:setInFloat3(v)
	elseif (t2Occupied) then
		local v = valuesOutComp:getInFloat3()
		v = v + 100
		valuesOutComp:setInFloat4(0)
		valuesOutComp:setInFloat5(1)
		if (v > 5000) then
			v = 5000
			valuesOutComp:setInFloat1(0)
			valuesOutComp:setInFloat2(1)
		end
		valuesOutComp:setInFloat3(v)
	else
		valuesOutComp:setInFloat4(0)
		valuesOutComp:setInFloat5(0)
		--[[
		local v = valuesOutComp:getInFloat3()
		if (v > 0) then
			v = v - 100
			if (v < 0) then
				v = 0
				valuesOutComp:setInFloat1(0)
				valuesOutComp:setInFloat2(0)
			end
		elseif (v < 0) then
			v = v + 100
			if (v > 0) then
				v = 0
				valuesOutComp:setInFloat1(0)
				valuesOutComp:setInFloat2(0)
			end
		end
		valuesOutComp:setInFloat3(v)
		]]
	end
end

