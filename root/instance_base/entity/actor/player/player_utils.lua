local moduleName = "gameplay.player.PlayerUtils"
module(moduleName, package.seeall)
debug.ReloadScripts.allowReload(moduleName)

-------------------------------------------------------------------------------------------------
--
-- Wrapped error / debug messages (IMPL)
--

function logErrorImpl(msg)
	if msg == nil then
		logger:error("player_utils:logErrorImpl - Nil message given.");
		return;
	end	
	logger:error(msg);
end

function logWarningImpl(msg)
	if msg == nil then
		logger:error("player_utils:logWarningImpl - Nil message given.");
		return;
	end
	logger:warning(msg);
end

function logInfoImpl(msg)
	if msg == nil then
		logger:error("player_utils:logInfoImpl - Nil message given.");
		return;
	end
	logger:info(msg);
end

-------------------------------------------------------------------------------------------------
--
-- Error handling
--

function getGUID(obj)	
	return obj:getGuid()
end

function getGUIDStr(obj)
	return tostring(getGUID(obj));
end

function getFinalOwnerGUID(obj)
	if obj == nil then
		logErrorImpl("player_utils:getFinalOwnerGUID - Nil param given.");
	end

	local finalOwnerInstance = common.CommonUtils.getFinalOwnerInstance(obj);
	if finalOwnerInstance == nil then
		logErrorImpl("player_utils:getFinalOwnerGUID - No final owner instance found.");
	end
	
	return finalOwnerInstance:getGuid()
end

function getFinalOwnerGUIDStr(obj)
	return tostring(getFinalOwnerGUID(obj));
end

function getType(obj)
	if obj == nil then
		logErrorImpl("player_utils:getType - Nil param given.");
	end
	
	local type = common.CommonUtils.getTypeManager():getTypeByUH(obj:getType());
	return type;
end

function getTypeName(obj)

	if obj == nil then
		logErrorImpl("player_utils:getTypeName - Nil param given.");
	end

	local type = getType(obj);
	if type == nil then
		logErrorImpl("player_utils:getTypeName - No type found.");
	end
	
	return type:getName();
end

function getFinalOwnerType(obj)
	if obj == nil then
		logErrorImpl("player_utils:getFinalOwnerType - Nil param given.");
	end

	local finalOwnerInstance = common.CommonUtils.getFinalOwnerInstance(obj);
	if finalOwnerInstance == nil then
		logErrorImpl("player_utils:getFinalOwnerType - No final owner instance found.");
	end
	
	local type = common.CommonUtils.getTypeManager():getTypeByUH(finalOwnerInstance:getType());	
	return type;
end

function getFinalOwnerTypeName(obj)

	if obj == nil then
		logErrorImpl("player_utils:getFinalOwnerTypeName - Nil param given.");
	end

	local type = getFinalOwnerType(obj);
	if type == nil then
		logErrorImpl("player_utils:getFinalOwnerTypeName - No type found.");
	end
	
	return type:getName();
end

function getErrorStringForPlayerInstance(obj)	
	local str = " ( PlayerType: " .. getFinalOwnerTypeName(obj) .. " , PlayerInstance: " .. getFinalOwnerGUIDStr(obj) .. " ) ";
	return str;
end
	
	
-------------------------------------------------------------------------------------------------
--
-- Wrapped error / debug messages
--

function logError(msg)
	logErrorImpl(msg);
end

function logWarning(msg)
	logWarningImpl(msg);
end

function logInfo(msg)
	logInfoImpl(msg);
end

function logPlayerError(obj, msg)
	if obj == nil then
		if msg == nil then
			logErrorImpl("player_utils:logPlayerError - Nil obj and msg given.");
		else
			logErrorImpl("player_utils:logPlayerError - Nil obj given. Message was: " .. msg);		
		end
		return;
	end
	
	if msg == nil then
		logErrorImpl("player_utils:logPlayerError - Nil message given" .. " " .. getErrorStringForPlayerInstance(obj) .. ".");
		return;
	end
	
	logErrorImpl(msg .. " " .. getErrorStringForPlayerInstance(obj) .. ".");
end

function logPlayerWarning(obj, msg)
	if obj == nil then
		if msg == nil then
			logErrorImpl("player_utils:logPlayerWarning - Nil obj and msg given.");
		else
			logErrorImpl("player_utils:logPlayerWarning - Nil obj given. Message was: " .. msg);		
		end
		return;
	end

	if msg == nil then
		logErrorImpl("player_utils:logPlayerWarning - Nil message given" .. " " .. getErrorStringForPlayerInstance(obj) .. ".");
		return;
	end
	
	logWarningImpl(msg .. " " .. getErrorStringForPlayerInstance(obj) .. ".");
end

function logPlayerInfo(obj, msg)
	if obj == nil then
		if msg == nil then
			logErrorImpl("player_utils:logPlayerInfo - Nil obj and msg given.");
		else
			logErrorImpl("player_utils:logPlayerInfo - Nil obj given. Message was: " .. msg);		
		end
		return;
	end

	if msg == nil then
		logErrorImpl("player_utils:logPlayerInfo - Nil message given" .. " " .. getErrorStringForPlayerInstance(obj) .. ".");
		return;
	end
	
	logInfoImpl(msg .. " " .. getErrorStringForPlayerInstance(obj) .. ".");
end

function debugPrintPosition(obj, pos)
	if obj == nil then
		logErrorImpl("player_utils:debugPrintPosition - Nil obj given.");
		return;
	end
	
	if pos == nil then
		logErrorImpl("player_utils:debugPrintPosition - Nil pos given" .. " " .. getErrorStringForPlayerInstance(obj) .. ".");
		return;
	end
	
	logInfoImpl("DEBUG, player_utils - X: " .. tostring(pos.x) .. " Y: " .. tostring(pos.y) .. " Z: " .. tostring(pos.z) " " .. getErrorStringForPlayerInstance(obj) .. ".");
end

--------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--
-- Get components
--

function findComponentFromObjectByClass(obj, class)
	if obj ~= nil then
		local inst = nil;		
		if obj:isInherited(engine.base.ComponentBase.getStaticObjectClass()) and obj.getFinalOwner then
			inst = obj:getFinalOwner();
		else
			inst = obj;
		end
		
		if inst ~= nil then
			local comp = inst:findComponentByClass(class);
			if comp ~= nil then
				return comp;
			else
				-- Not an error
				return nil;
			end
		else
			logAIError(obj, "ai_utils:findComponentFromObjectByClassId - Instance is nil.");
			return nil;
		end
	else
		logAIError(obj, "ai_utils:findComponentFromObjectByClassId - Nil param given.");
		return nil;
	end
	logAIError(obj, "ai_utils:findComponentFromObjectByClassId - Something went wrong.");
	return nil;
end

---------------------------------------------------------------
--
-- Random number generation 
--

-- Returns random float [minValue, maxValue[ or [0, 1[
function getRandomFloat(obj, minValue, maxValue, useLUARandom)
	-- NOTE: minValue or/and maxValue can be nil

	local generator = getRandomGenerator(obj);
	local baseValue = 0;
	
	if useLUARandom then
		baseValue = math.random();
	else
		if generator ~= nil then
			baseValue = generator:getRandomFloat();
		else
			logger:error("getRandomFloat - RandomGenerator is nil, using math.random.");
			baseValue = math.random();
		end
	end
	
	if minValue ~= nil and maxValue ~= nil then
		return baseValue * (maxValue - minValue) + minValue;
	else
		return baseValue;
	end
end

-- Returns random int [minValue, maxValue]
function getRandomInt(obj, minValue, maxValue, useLUARandom)
	return math.floor(getRandomFloat(obj, minValue, maxValue + 1, useLUARandom));
end

function getRandomGenerator(obj)
	local finalOwner = obj;
	if obj.getFinalOwner then
		finalOwner = obj:getFinalOwner();
	end
	local rg = findComponentFromObjectByClass(obj, gameplay.RandomNumberGeneratorComponent.getStaticObjectClass());
	if rg ~= nil then
		return rg;
	end	
	if finalOwner ~= nil then
		logPlayerWarning(obj, "player_utils:getRandomGenerator - Could not find RandomGenerator");
	end	
	return nil;
end


