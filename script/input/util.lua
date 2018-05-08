module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

--require "input.binds"

function listControllers()
	local lastController = inputModule:getNumberOfControllers() - 1
	local cTable = { }
	for i = 0, lastController do
		local controller = inputModule:peekController(i)
		cTable[i + 1] = controller:getIDString()
	end
	return cTable
end


function printControllers()
	local names = listControllers()
	local str = ""
	for key,value in pairs(names) do str = str .. value .. "\n" end
	misc.util.printToConsole(str)
	return str
end


function printBinds(binds)
	local bo
	if type(binds) == "userdata" then
		if binds.getBindingByAction then 
			bo = binds
		else
			logger:error("Invalid parameter. Binds or string required")
			return
		end
	elseif type(binds) == "string" then
		bo = inputModule:getBindsByName(binds)
		if bo:getName() == "" then logger:error("No such binds found: " .. binds) return end
	else
		logger:error("Invalid parameter. Binds or string required")
		return
	end
	misc.util.printToConsole(tostring(bo))
	return tostring(bo)
end


function listBinds()
	local bindsNames = {}
	for i = 0, inputModule:getNumberOfBinds() - 1 do
		bindsNames[i + 1] = inputModule:getBindsByIndex(i):getName()
	end
	return bindsNames
end


function printBindsNames(strToMatch)
	local names = listBinds()
	local str = ""
	for key, value in pairs(names) do
		if not strToMatch or value:find(strToMatch) then
			str = str .. value .. "\n"
		end
	end
	misc.util.printToConsole(str)
	return str
end


function vibrateController(controllerNumber, motorOneSpeed, motorTwoSpeed, durationOne, durationTwo)
	local eTag = "input.util.vibrateController: "
	local controller = inputModule:getControllerDebug(controllerNumber)
	if not controller then
		logger:error(eTag .. "controller not found")
		return
	end
	
	if controller:getNumberOfVibrationMotors() < 1 then
		logger:error(eTag .. "controller has no vibration motors")
		return
	end
	
	controller:setVibration(0, motorOneSpeed, durationOne)
	if controller:getNumberOfVibrationMotors() >= 2 then
		controller:setVibration(1, motorTwoSpeed, durationTwo)
	end
end


function printKeyboardKeyNames()
	for i = 1, 255 do
		misc.util.printToConsole("" .. i .. ": " .. inputModule:getKeyboardKeyName(i))
	end
end


function printBindingActions()
	local msg = { }
	table.insert(msg, "Binding actions:")
	
	local bindsesNames = { }
	for i, name in ipairs({ "InputComponent", "GUI" }) do
		table.insert(bindsesNames, name .. " Keyboard Binds")
		table.insert(bindsesNames, name .. " Mouse Binds")
		table.insert(bindsesNames, name .. " Binds for XInput Gamepad (Xbox compatible)")
		table.insert(bindsesNames, name .. " Binds for Logitech Cordless RumblePad 2")
	end

	for i, name in ipairs(bindsesNames) do
		if inputModule:hasBinds(name) then
			table.insert(msg, "\n" .. name .. ":\n")
			local binds = input.Binds(inputModule:getBindsByName(name))
			table.insert(msg, tostring(binds))
		end
	end
	
	
	misc.util.printToConsole(table.concat(msg, "\n"))
end
