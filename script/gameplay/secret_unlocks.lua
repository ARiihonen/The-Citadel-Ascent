module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

local thisModule = _M

declareManualReload(thisModule, [[secretSpecifications]])

-- specifications for available secrets

-- WARNING!!!
-- NEVER ADD ANY NEW SECRETS TO THE MIDDLE OF THIS LIST!!! 
-- NEVER REMOVE ANY SECRETS FROM THE MIDDLE OF THE LIST!!!
-- ALWAYS ADD THEM TO THE END OF THE LIST, OR EXISTING SECRET UNLOCK STATUSES WILL BE INCORRECT!!!
secretSpecifications = 
{
	 { missionId = "castle1", name = "item_necklace_l", iconNumber = 0, viewNumber = 1 }
	, { missionId = "castle1", name = "item_ring", iconNumber = 0, viewNumber = 1 }
	, { missionId = "courtyard1", name = "item_amulet_e", iconNumber = 0, viewNumber = 2 }
	, { missionId = "courtyard1", name = "item_vial_e", iconNumber = 0, viewNumber = 2 }
	, { missionId = "cemetery1", name = "item_leggings", iconNumber = 0, viewNumber = 3 }
	, { missionId = "cemetery1", name = "item_poison", iconNumber = 0, viewNumber = 3 }
	, { missionId = "crypt1", name = "item_amulet_s", iconNumber = 0, viewNumber = 4 }
	, { missionId = "crypt1", name = "item_crystal_e", iconNumber = 0, viewNumber = 4 }
	, { missionId = "darkcrypt1", name = "item_pendant_h", iconNumber = 0, viewNumber = 5 }
	, { missionId = "darkcrypt1", name = "item_bracers", iconNumber = 0, viewNumber = 5 }
	, { missionId = "castle2", name = "item_crystal_h", iconNumber = 0, viewNumber = 6 }
	, { missionId = "castle2", name = "item_boots", iconNumber = 0, viewNumber = 6 }
	, { missionId = "castle3", name = "item_statue", iconNumber = 0, viewNumber = 7 }
	, { missionId = "castle3", name = "item_blue_gem", iconNumber = 0, viewNumber = 7 }
	, { missionId = "forest1", name = "item_fish", iconNumber = 0, viewNumber = 8 }
	, { missionId = "forest1", name = "item_necklace_p", iconNumber = 0, viewNumber = 8 }
	, { missionId = "darkforest1", name = "item_prism", iconNumber = 0, viewNumber = 9 }
	, { missionId = "darkforest1", name = "item_vial_h", iconNumber = 0, viewNumber = 9 }
	, { missionId = "forest2", name = "item_amulet_f", iconNumber = 0, viewNumber = 10 }
	, { missionId = "forest2", name = "item_red_gem", iconNumber = 0, viewNumber = 10 }
	, { missionId = "mines1", name = "item_orb", iconNumber = 0, viewNumber = 11 }
	, { missionId = "mines1", name = "item_pendant_g", iconNumber = 0, viewNumber = 11 }
	, { missionId = "village1", name = "item_music_box1", iconNumber = 0, viewNumber = 12 }
	, { missionId = "village1", name = "item_resur_gem", iconNumber = 0, viewNumber = 12 }
	, { missionId = "castle5", name = "item_amulet_k", iconNumber = 0, viewNumber = 13 }
	, { missionId = "castle5", name = "item_crown", iconNumber = 0, viewNumber = 13 }
	
	-- WTF? This broke the "Treasure hunter" achievement.
	--[[
	, { missionId = "extra1", name = "extra1_chest1", iconNumber = 0, viewNumber = 14 }
	, { missionId = "extra1", name = "extra1_chest2", iconNumber = 0, viewNumber = 14 }
	, { missionId = "extra1", name = "extra1_chest3", iconNumber = 0, viewNumber = 14 }
	, { missionId = "extra1", name = "extra1_chest4", iconNumber = 0, viewNumber = 14 }
	, { missionId = "extra1", name = "extra1_chest5", iconNumber = 0, viewNumber = 14 }
	, { missionId = "extra1", name = "extra1_chest6", iconNumber = 0, viewNumber = 14 }
	, { missionId = "extra1", name = "extra1_chest7", iconNumber = 0, viewNumber = 14 }
	, { missionId = "extra1", name = "extra1_chest8", iconNumber = 0, viewNumber = 14 }
	, { missionId = "extra1", name = "extra1_chest9", iconNumber = 0, viewNumber = 14 }
	, { missionId = "extra1", name = "extra1_chest10", iconNumber = 0, viewNumber = 14 }
	]]--

}


function isSkillAlreadyFound(theSkillName)
	logger:error("Calling old Trine function: gameplay.SecretUnlocks.isSkillAlreadyFound()");
	if true then return false end
	
	for i=0, common.CommonUtils.getCharacterSelectionManager():getNumCharacters() -1 do
		local character = common.CommonUtils.getCharacterSelectionManager():getLocalCharacterInstanceByIndex(i)
		if character ~= nil then
			local inventoryComp = character:findComponent(gameplay.item.InventoryComponent)
			if inventoryComp ~= nil then
				if (inventoryComp:hasItem(theSkillName)) then
					return true
				end
			else
				logger:error("Couldnt find inventory component on player character")
			end
		else
			logger:error("Nil character given from getLocalCharacterInstanceByIndex for index: " .. i)
		end
	end
	
	return false
end

-- set a secret unlock status to 0 or 1
function setSecretStringBit(idNum, value)
	assert_number(idNum)
	assert_number(value)
	
	local secretString = gameModule:getUnlockedSecrets()

	-- pad with zeroes until adequate length to hold this id
	while(string.len(secretString) <= idNum) do
		secretString = secretString .. "0"
	end
	
	if (value ~= 0 and value ~= 1) then
		-- currently, there should be only ones and zeroes, though they might be supported in the future
		logger:warning("Setting a non zero or one value character to the secret string.");
	end
	
	-- TODO: this is not very optimal perhaps... :P
	if (idNum == 0) then
		secretString = tostring(value) .. string.sub(secretString, 2)
	elseif (idNum == string.len(secretString) - 1) then
		secretString = string.sub(secretString, 1, idNum) .. tostring(value)
	else
		secretString = string.sub(secretString, 1, idNum) .. tostring(value) .. string.sub(secretString, idNum + 2)
	end
	
	gameModule:setUnlockedSecrets(secretString)
	gameState:saveOptionsInNextLoadingScreen()
end


-- returns the value of the secret unlock status in the string (0 or 1)
function getSecretStringBit(idNum)
	assert_number(idNum)
	
	local secretString = gameModule:getUnlockedSecrets()
	
	-- If demo, clear all secrets
	if gameBaseApplicationModule:getDemo() then
		secretString = "";
	end
	
	if (idNum >= string.len(secretString)) then
		-- the string is not long enough, the secret must still be unlocked (return zero)
		return 0
	else
		local c = string.sub(secretString, idNum + 1, idNum + 1)
		local v = tonumber(c)
		if (v ~= 0 and v ~= 1) then
			-- currently, there should be only ones and zeroes, though they might be supported in the future
			logger:warning("Parsed a non zero or one value character out of the secret string.");
		end
		return v
	end	
end


function unlockSecretById(idNum)
	assert_number(idNum)
	
	setSecretStringBit(idNum, 1)
end


-- returns true if non-zero value
function isSecretUnlockedById(idNum)
	assert_number(idNum)
	local val = getSecretStringBit(idNum)
	if (val ~= 0) then
		return true
	else
		return false
	end
end

-- mysteriously solves the secret unlock id number from given mission id and the treasure chest entity name
-- notice, that the treasure chest name here is not necessarily a full entity name, but just a portion of it
-- you'll need to give the right portion here. (currently "concept", "poem", "piece1" or "piece2")
function getSecretIdByMissionIdAndSecretName(missionId, secretName)
	assert_string(missionId)
	assert_string(secretName)	
	
	for i = 1,#secretSpecifications do
		if (secretSpecifications[i].missionId == missionId and secretSpecifications[i].name == secretName) then
			return i - 1
		end
	end
	
	-- no such secret listed
	return -1
end

-- Like getSecretIdByMissionIdAndSecretName, but omits mission ID check
function getSecretIdBySecretName(secretName)
	assert_string(secretName)	
	
	for i = 1,#secretSpecifications do
		if (secretSpecifications[i].name == secretName) then
			return i - 1
		end
	end
	
	-- no such secret listed
	return -1
end

function getSecretIconNumber(idNum)
	assert_number(idNum)
	
	return secretSpecifications[idNum + 1].iconNumber
end


function getSecretViewNumber(idNum)
	assert_number(idNum)
	
	return secretSpecifications[idNum + 1].viewNumber
end

-- hackity hack... 
function getSecretName(treasureChestEntityName)
	assert_string(treasureChestEntityName)	

	-- No so hackity hackity hack in Trine 1, but not that useful either :)
	return treasureChestEntityName;
end


-- returns true if the secret is unlocked at given mission id and given (exact) secret name
function isSecretUnlockedByMissionIdAndSecretName(missionId, secretName, noError)
	assert_string(missionId)
	assert_string(secretName)	
	
	local secretIdNum = getSecretIdByMissionIdAndSecretName(missionId, secretName)
	if (secretIdNum == -1) then
		if(not noError) then
			logger:error("No secret id number can be solved for mission \""..tostring(missionId).."\" and secret name \""..tostring(secretName).."\"")
		end
		return false
	end
	
	return isSecretUnlockedById(secretIdNum)
end


-- returns true if the secret is unlocked based on mission id and treasure chest entity name
-- note, the treasure chest name is not necessary the secret name, a portion of it should contain the secret name
function isSecretUnlockedByMissionIdAndTresureEntityName(missionId, treasureChestName)
	assert_string(missionId)
	assert_string(treasureChestName)	

	--local secretName = getSecretName(treasureChestName)
	return isSecretUnlockedByMissionIdAndSecretName(missionId, treasureChestName)
end


-- unlocks the secret. calling this is the "easy" way to integrate to some existing stuff
function unlockSecretByMissionIdAndTresureEntityName(missionId, treasureChestName)
	if (string.find(treasureChestName, "skillchest", 1, true)) then
		return
	end
	
	local secretName = getSecretName(treasureChestName)	
	local secretIdNum = getSecretIdByMissionIdAndSecretName(missionId, secretName)
	if (secretIdNum == -1) then
		logger:error("No secret id number can be solved for mission \""..tostring(missionId).."\" and entity name \""..tostring(treasureChestName).."\"")
		return
	end
	
	unlockSecretById(secretIdNum)
end

function unlockSecretBySecretName(secretName)
	local secretIdNum = getSecretIdBySecretName(secretName)
	if (secretIdNum == -1) then
		-- It's ok to fail because this will be called with upgrade names also
		return
	end
	unlockSecretById(secretIdNum)
end

-- unlocks the secret. calling this is the "easy" way to integrate to some existing stuff
function getSecretIdByMissionIdAndTresureEntityName(missionId, treasureChestName)
	local secretName = getSecretName(treasureChestName)	
	local secretIdNum = getSecretIdByMissionIdAndSecretName(missionId, secretName)
	if (secretIdNum == -1) then
		logger:error("No secret id number can be solved for mission \""..tostring(missionId).."\" and entity name \""..tostring(treasureChestName).."\"")
		return -1
	end
	return secretIdNum
end

function allSecretsInLevel(missionId)
	assert_string(missionId)
	local count = getNumberOfTotalSecretsForMission(missionId)

	return (count > 0 and getNumberOfUnlockedSecretsForMission(missionId) == count)
end

function checkSecretTrophyNoScene(missionId, missionNum)
	assert_string(missionId)
	assert_number(missionNum)
	
	--if allSecretsInLevel(missionId) then
	--	gameState:unlockTrophy("pro_diving")
	--	state:unlockTrophy("level" .. missionNum .. "_chest")
	--end
end

function checkAllSecretsTrophy()
	local secMainLocked = 0
	local secMainUnlocked = 0
	
	for i = 1,#secretSpecifications do
		if not isSecretUnlockedById(i - 1) then
			secMainLocked = secMainLocked + 1
		else
			secMainUnlocked = secMainUnlocked + 1
		end
	end
	
	if (secMainUnlocked > 0 and secMainLocked == 0) then
		state:unlockTrophy("find_all_secrets")
	end
end

-- returns the number of unlocked secrets for the given mission 
function getNumberOfUnlockedSecretsForMission(missionId)
	assert_string(missionId)
	
	local sum = 0
	for i = 1,#secretSpecifications do
		if (secretSpecifications[i].missionId == missionId) then
			if (isSecretUnlockedById(i - 1)) then
				sum = sum + 1
			end
		end
	end
	return sum
end

-- returns the viewNumber for a mission
function getMissionViewNumber(missionId)
	assert_string(missionId)

	for i = 1, #secretSpecifications do
		if secretSpecifications[i].missionId == missionId then
			return secretSpecifications[i].viewNumber
		end
	end
	logger:error("getMissionViewNumber - No secrets found in mission '" .. missionId .. "'")
	return -1
end

-- returns the total number of secrets for the given mission 
function getNumberOfTotalSecretsForMission(missionId)
	assert_string(missionId)
	
	local sum = 0
	for i = 1,#secretSpecifications do
		if (secretSpecifications[i].missionId == missionId) then
			sum = sum + 1
		end
	end
	return sum
end


-- resets all secrets to locked
function resetAllSecretsToLocked()
	-- just make the string all empty (alternatively it could be set to all zeroes)
	gameModule:setUnlockedSecrets("")
	gameState:saveOptionsInNextLoadingScreen()
end


-- unlocks all secrets
function cheatGiveAllSecrets()
	for i = 1,#secretSpecifications do
		unlockSecretById(i - 1)
	end
end
