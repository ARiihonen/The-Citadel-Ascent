module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

function giveHealthImpl(amount)
	local function giveCharacterHealth(instance, amount)
		if instance then
			local comp = instance:findComponent(gameplay.damage.HealthComponent)
			if comp then
				comp:setHealth(amount)
			end
		end
	end
	
	local playerCharacters = common.CommonUtils.getAllLocalPlayerCharacters()
	for key, playerInstance in pairs(playerCharacters) do
		giveCharacterHealth(playerInstance, amount)
	end
	
	if trineTextChat then
		trineTextChat:sendChatMessage("CHEAT: Health", false)
	end
end

function setImmortalImpl(enabled)
	local function setCharacterImmortal(instance, enabled)
		if instance then
			local comp = instance:findComponent(gameplay.damage.HealthComponent)
			if comp then
				comp:setImmortal(enabled)
			end
		end
	end
	
	local playerCharacters = common.CommonUtils.getAllLocalPlayerCharacters()
	for key, playerInstance in pairs(playerCharacters) do
		setCharacterImmortal(playerInstance, enabled)
	end
	
	if trineTextChat then
		if enabled then
			trineTextChat:sendChatMessage("CHEAT: Immortal", false)
		else
			trineTextChat:sendChatMessage("CHEAT: Mortal", false)
		end
	end
end

function giveHealth()
	giveHealthImpl(100);
end

function makePlayerActorsImmortal()
	setImmortalImpl(true);
end

function makePlayerActorsMortal()
	setImmortalImpl(false);
end

function giveWizardItems()
	if true then return end -- THIS IS OLD TRINE FUNCTION
	
	local cm = common.CommonUtils.getCharacterSelectionManager();
	if cm == nil then
		return;
	end

	for i = 0, cm:getNumAllCharacters()-1 do
		local instance = cm:getFromAllCharactersByIndex(i)
		if instance and string.find(instance:getName(), "wizard") then
			local comp = instance:findComponent(gameplay.item.InventoryComponent)
			if comp then
				comp:setItemWithEvent("item_ball", 1)
				comp:setItemWithEvent("item_spiked_object", 1)
				comp:setItemWithEvent("item_improved_prison_box", 1)
				comp:setItemWithEvent("item_extraobjects", 1)
			end
		end
	end
end

function giveThiefItems()
	if true then return end -- THIS IS OLD TRINE FUNCTION
	
	local cm = common.CommonUtils.getCharacterSelectionManager();
	if cm == nil then
		return;
	end

	for i = 0, cm:getNumAllCharacters()-1 do
		local instance = cm:getFromAllCharactersByIndex(i)
		if instance and string.find(instance:getName(), "thief") then
			local comp = instance:findComponent(gameplay.item.InventoryComponent)
			if comp then
				comp:setItemWithEvent("item_vampiric_arrows", 1)
				comp:setItemWithEvent("item_heavy_bow", 1)
				comp:setItemWithEvent("item_multiple_arrows", 1)
				comp:setItemWithEvent("item_poison_gas", 1)				
			end
		end
	end
end

function giveWarriorItems()
	if true then return end -- THIS IS OLD TRINE FUNCTION
	
	local cm = common.CommonUtils.getCharacterSelectionManager();
	if cm == nil then
		return;
	end

	for i = 0, cm:getNumAllCharacters()-1 do
		local instance = cm:getFromAllCharactersByIndex(i)
		if instance and string.find(instance:getName(), "warrior") then
			local comp = instance:findComponent(gameplay.item.InventoryComponent)
			if comp then
				comp:setItemWithEvent("item_rampage", 1)
				comp:setItemWithEvent("item_slayer_sword", 1)
			end
		end
	end
end


function postStartInstanceRoot()
	--
	-- Here you can supply cheats e.g. to demo purposes etc.
	--
	
	--[[
	-- NOTE: For now Trine 3 doesn't need this as all skills are always abailable
	if gameBaseApplicationModule:getDemo() then
		if gameBaseApplicationModule:getDemoExpo() then
			-- Expo demo
			giveAllItems()
		elseif gameBaseApplicationModule:getDemoStage() then
			-- Stage demo
			giveAllItems()
		else
			-- Normal demo
			giveAllItems()
		end
	end
	]]--
end

function giveAllItems()
	if true then return end -- THIS IS OLD TRINE FUNCTION
	
	giveWizardItems();
	giveThiefItems();
	giveWarriorItems();
	
	giveAllItemModifiers();
	
	if trineTextChat then
		trineTextChat:sendChatMessage("CHEAT: Items", false)
	end
end

function giveWizardSkills()
	if true then return end -- THIS IS OLD TRINE FUNCTION
	
	local cm = common.CommonUtils.getCharacterSelectionManager();
	if cm == nil then
		return;
	end

	for i = 0, cm:getNumAllCharacters()-1 do
		local instance = cm:getFromAllCharactersByIndex(i)
		if instance and string.find(instance:getName(), "wizard") then
			local comp = instance:findComponent(gameplay.item.InventoryComponent)
			if comp then
				comp:setItemWithEvent("GlassObjects", 1)
				comp:setItemWithEvent("ConjuredObjectsAmount", 3)
			end
			local knockbackWindComp = instance:findComponent(trinebase.gameplay.KnockbackWindComponent)
			if knockbackWindComp then
				knockbackWindComp:setEnabled(true);
			end
		end
	end
end

function giveThiefSkills()
	if true then return end -- THIS IS OLD TRINE FUNCTION
	
	local cm = common.CommonUtils.getCharacterSelectionManager();
	if cm == nil then
		return;
	end

	for i = 0, cm:getNumAllCharacters()-1 do
		local instance = cm:getFromAllCharactersByIndex(i)
		if instance and string.find(instance:getName(), "thief") then
			local comp = instance:findComponent(gameplay.item.InventoryComponent)
			if comp then
				-- Insert Thief skills similar to items			
			end
		end
	end
end

function giveWarriorSkills()
	if true then return end -- THIS IS OLD TRINE FUNCTION
	
	local cm = common.CommonUtils.getCharacterSelectionManager();
	if cm == nil then
		return;
	end

	for i = 0, cm:getNumAllCharacters()-1 do
		local instance = cm:getFromAllCharactersByIndex(i)
		if instance and string.find(instance:getName(), "warrior") then
			local comp = instance:findComponent(gameplay.item.InventoryComponent)
			if comp then
				-- Insert Warrior skills similar to items
			end
		end
	end
end

function giveAllSkills()
	if true then return end -- THIS IS OLD TRINE FUNCTION
	
	giveWizardSkills()
	giveThiefSkills()
	giveWarriorSkills()
	
	if trineTextChat then
		trineTextChat:sendChatMessage("CHEAT: Skills", false)
	end
end

function kill(instance)
	local comp = instance:findComponent(gameplay.damage.HealthComponent)
	if not comp then return end
	if comp:getNetSyncer():hasLocalMaster() then
		comp:setHealth(0)
	end
end

function killSelected()
	local playerCharacters = common.CommonUtils.getSelectedLocalPlayerCharacters()
	for key, instance in pairs(playerCharacters) do
		if(instance) then	kill(instance) end
	end
end

function killAll()
	local playerCharacters = common.CommonUtils.getAllLocalPlayerCharacters()
	for key, instance in pairs(playerCharacters) do
		local instance = pam:getLocalCharacterInstanceByIndex(i)
		kill(instance)
	end
end

function unlockMissions()
	--NOTE: Doesn't really work at the moment because of new unlocking logic.
	missionManager:unlockAllMissions()
	
	local c = fuiManager:findComponent(game.gui.GameFUIChapterSelectionMenuComponent)
	if(c and c.refreshMissions) then
		c:refreshMissions()
	end
end

function warpToDestination(destinationPos)
	local playerCharacters = common.CommonUtils.getSelectedPlayerCharacters()
	for key, playerInstance in pairs(playerCharacters) do
		if playerInstance then
			local playerTransformComponent = playerInstance:findComponent(engine.component.TransformComponent);
			if playerTransformComponent then
				playerTransformComponent:setPosition(destinationPos)
			end
		end
	end

	--gameplay.util.warpCamera(0.2, false) --not needed in macbeth
end

function currentPlayerPos()
	local playerCharacters = common.CommonUtils.getSelectedPlayerCharacters()
	for key, playerInstance in pairs(playerCharacters) do
		if playerInstance then
			local playerTransformComponent = playerInstance:findComponent(engine.component.TransformComponent);
			if playerTransformComponent then
				return playerTransformComponent:getPosition()
			end
		end
	end
end

function nextExp()
	
	function nextExpRecursion(obj, type)
		for i = 0, obj:getNumChildren()-1 do
			local child = obj:getChild(i)
			local childType = typeManager:getTypeByUH(child:getType())
			if(childType:doesInheritType(type)) then
				local expSpawner = child:findComponent(trinebase.gameplay.TrineExperienceSpawnerComponent);
				if(expSpawner:getExperienceLeft() > 0) then
						local destinationPos = child:getTransformComponent():getPosition()
						warpToDestination(destinationPos)
					return
				end
			else
				nextExpRecursion(child, type)
			end
		end
	end
	
	local type = typeManager:findTypeByName("ExpPickableItem");
	nextExpRecursion(gameScene, type)
	
end

function nextEnemyExp()
	
	function nextExpRecursion(obj, type)
		for i = 0, obj:getNumChildren()-1 do
			local child = obj:getChild(i)
			local childType = typeManager:getTypeByUH(child:getType())
			if(not childType:doesInheritType(type)) then
				local expSpawner = child:findComponent(trinebase.gameplay.TrineExperienceSpawnerComponent);
				if(expSpawner and expSpawner:getExperienceLeft() > 0) then
						local destinationPos = child:getTransformComponent():getPosition()
						warpToDestination(destinationPos)
					return
				end
			end
			nextExpRecursion(child, type)
		end
	end
	
	local type = typeManager:findTypeByName("ExpPickableItem");
	nextExpRecursion(gameScene, type)
	
end


function nextChest()
	
	function nextChestRecursion(obj, type)
		for i = 0, obj:getNumChildren()-1 do
			local child = obj:getChild(i)
			local childType = typeManager:getTypeByUH(child:getType())
			if(childType:doesInheritType(type)) then
				local chestC = child:findComponent(trinebase.gameplay.elements.TrineChestComponent);
				if(chestC and not chestC:getHasBeenUsed() and chestC:getEnabled()) then
						local destinationPos = child:getTransformComponent():getPosition()
						warpToDestination(destinationPos)
					return
				end
			end
			nextChestRecursion(child, type)
		end
	end
	
	local type = typeManager:findTypeByName("TreasureChestEntity");
	nextChestRecursion(gameScene, type)
	
end

function giveTraps()
	local players = common.CommonUtils.getAllPlayerCharacters()
	for key, pInst in pairs(players) do
		local playerInv = pInst:findComponent(game.gameplay.PlayerInventoryComponent);
		if playerInv then
			playerInv:giveTraps()
		end
	end
end

function giveCraftingMaterials()
	local players = common.CommonUtils.getAllPlayerCharacters()
	for key, pInst in pairs(players) do
		local playerInv = pInst:findComponent(game.gameplay.PlayerInventoryComponent);
		if playerInv then
			playerInv:giveCraftingMaterials()
		end
	end
end

function giveCraftingRecipes()
	local players = common.CommonUtils.getAllPlayerCharacters()
	for key, pInst in pairs(players) do
		local playerInv = pInst:findComponent(game.gameplay.PlayerInventoryComponent);
		if playerInv then
			playerInv:giveCraftingRecipes()
		end
	end
end

function giveItems()
	local players = common.CommonUtils.getAllPlayerCharacters()
	for key, pInst in pairs(players) do
		local playerInv = pInst:findComponent(game.gameplay.PlayerInventoryComponent);
		if playerInv then
			playerInv:giveItems()
		end
	end
end

function giveAll()
	local players = common.CommonUtils.getAllPlayerCharacters()
	for key, pInst in pairs(players) do
		local playerInv = pInst:findComponent(game.gameplay.PlayerInventoryComponent);
		if playerInv then
			playerInv:giveAll()
		end
	end
end

function giveMetalPlate()
	local players = common.CommonUtils.getAllPlayerCharacters()
	for key, pInst in pairs(players) do
		local playerInv = pInst:findComponent(game.gameplay.PlayerInventoryComponent);
		if playerInv then
			playerInv:giveMetalPlate()
			end
		end
end

function giveItem(itemName)
	local players = common.CommonUtils.getAllPlayerCharacters()
	for key, pInst in pairs(players) do
		local playerInv = pInst:findComponent(game.gameplay.PlayerInventoryComponent);
		if playerInv then
			playerInv:giveItem(itemName)
		end
	end
end

function giveBow()
	local players = common.CommonUtils.getAllPlayerCharacters()
	for key, pInst in pairs(players) do
		local playerInv = pInst:findComponent(game.gameplay.PlayerInventoryComponent);
		if playerInv then
			playerInv:giveBow()
		end
	end
end

function giveBottles()
	local players = common.CommonUtils.getAllPlayerCharacters()
	for key, pInst in pairs(players) do
		local playerInv = pInst:findComponent(game.gameplay.PlayerInventoryComponent);
		if playerInv then
			for i=1,100 do
				playerInv:giveBottle()
			end
		end
	end
end

function giveBottle()
	local players = common.CommonUtils.getAllPlayerCharacters()
	for key, pInst in pairs(players) do
		local playerInv = pInst:findComponent(game.gameplay.PlayerInventoryComponent);
		if playerInv then
			playerInv:giveBottle()
		end
	end
end

function givePoisonDartMine()
	local players = common.CommonUtils.getAllPlayerCharacters()
	for key, pInst in pairs(players) do
		local playerInv = pInst:findComponent(game.gameplay.PlayerInventoryComponent);
		if playerInv then
			playerInv:givePoisonDartMine()
		end
	end
end

function giveDoublePoisonDartMine()
	local players = common.CommonUtils.getAllPlayerCharacters()
	for key, pInst in pairs(players) do
		local playerInv = pInst:findComponent(game.gameplay.PlayerInventoryComponent);
		if playerInv then
			playerInv:giveDoublePoisonDartMine()
		end
	end
end

function givePoisonDartMines()
	local players = common.CommonUtils.getAllPlayerCharacters()
	for key, pInst in pairs(players) do
		local playerInv = pInst:findComponent(game.gameplay.PlayerInventoryComponent);
		if playerInv then
			for i=1,10 do
				playerInv:givePoisonDartMine()
			end
		end
	end
end

function giveDoublePoisonDartMines()
	local players = common.CommonUtils.getAllPlayerCharacters()
	for key, pInst in pairs(players) do
		local playerInv = pInst:findComponent(game.gameplay.PlayerInventoryComponent);
		if playerInv then
			for i=1,10 do
				playerInv:giveDoublePoisonDartMine()
			end
		end
	end
end

function giveProximityMines()
	local players = common.CommonUtils.getAllPlayerCharacters()
	for key, pInst in pairs(players) do
		local playerInv = pInst:findComponent(game.gameplay.PlayerInventoryComponent);
		if playerInv then
			for i=1,10 do
				playerInv:giveProximityMine()
			end
		end
	end
end

function givePressureMines()
	local players = common.CommonUtils.getAllPlayerCharacters()
	for key, pInst in pairs(players) do
		local playerInv = pInst:findComponent(game.gameplay.PlayerInventoryComponent);
		if playerInv then
			for i=1,10 do
				playerInv:givePressureMine()
			end
		end
	end
end

function giveStickyBombs()
	local players = common.CommonUtils.getAllPlayerCharacters()
	for key, pInst in pairs(players) do
		local playerInv = pInst:findComponent(game.gameplay.PlayerInventoryComponent);
		if playerInv then
			for i=1,10 do
				playerInv:giveStickyBomb()
			end
		end
	end
end

function giveChainBombs()
	local players = common.CommonUtils.getAllPlayerCharacters()
	for key, pInst in pairs(players) do
		local playerInv = pInst:findComponent(game.gameplay.PlayerInventoryComponent);
		if playerInv then
			for i=1,10 do
				playerInv:giveChainBomb()
			end
		end
	end
end

function giveDecoyToys()
	local players = common.CommonUtils.getAllPlayerCharacters()
	for key, pInst in pairs(players) do
		local playerInv = pInst:findComponent(game.gameplay.PlayerInventoryComponent);
		if playerInv then
			for i=1,10 do
				playerInv:giveDecoyToy()
			end
		end
	end
end

function giveProximityMine()
	local players = common.CommonUtils.getAllPlayerCharacters()
	for key, pInst in pairs(players) do
		local playerInv = pInst:findComponent(game.gameplay.PlayerInventoryComponent);
		if playerInv then
			playerInv:giveProximityMine()
		end
	end
end

function givePressureMine()
	local players = common.CommonUtils.getAllPlayerCharacters()
	for key, pInst in pairs(players) do
		local playerInv = pInst:findComponent(game.gameplay.PlayerInventoryComponent);
		if playerInv then
			playerInv:givePressureMine()
		end
	end
end
----[[
-- Same kind of code already exists in spawn manager, use it instead
function warpToCheckpoint(sign)
	local currentPos = currentPlayerPos()

	local finalDest = nil
	local finalDist = 1000000
	function recurse(type, obj)
		for i = 0, obj:getNumChildren()-1 do
			local child = obj:getChild(i)
			local childType = typeManager:getTypeByUH(child:getType())
			local destinationPos = child:getTransformComponent():getPosition()
			local epsilon = 0.1
			local dist = sign * (destinationPos.x - currentPos.x)
			if(childType:doesInheritType(type) and dist > epsilon and dist < finalDist) then
				local checkPoint = child:findComponent(trinebase.gameplay.TrineCheckpointComponent);
				if(checkPoint) then
					finalDest = destinationPos
					finalDist = dist
				end
			end
			recurse(type, child)
		end
	end

	local type = typeManager:findTypeByName("CheckpointEntity");
	local obj = gameScene

	recurse(type, obj)

	if finalDest then
		warpToDestination(finalDest)
	end
end

function nextCheckpoint()
	warpToCheckpoint(1)
end

function prevCheckpoint()
	warpToCheckpoint(-1)
end
--]]

function giveAllItemModifiers()
	if true then return end -- THIS IS OLD TRINE FUNCTION
	
	local cm = common.CommonUtils.getCharacterSelectionManager();
	if cm == nil then
		return;
	end

	for i = 0, cm:getNumAllCharacters()-1 do
		local instance = cm:getFromAllCharactersByIndex(i)
		if instance then
			local comp = instance:findComponent(gameplay.item.InventoryComponent)
			if comp then
				-- Divide common items to characters
				if string.find(instance:getName(), "wizard") then
					comp:setItemWithEvent("item_soul_link_1", 1)
					comp:setItemWithEvent("item_leather_spandex", 1);
					comp:setItemWithEvent("item_light_bolt", 1)
					comp:setItemWithEvent("item_fire_element", 1)
					comp:setItemWithEvent("item_ice_element", 1)
				elseif string.find(instance:getName(), "warrior") then
					comp:setItemWithEvent("item_second_wind", 1)
					comp:setItemWithEvent("item_healing_death", 1)
					comp:setItemWithEvent("item_platemail", 1)
					comp:setItemWithEvent("item_fire_element", 1)
					comp:setItemWithEvent("item_ice_element", 1)
				elseif string.find(instance:getName(), "thief") then
					comp:setItemWithEvent("item_explorers_talisman", 1)
					comp:setItemWithEvent("item_soul_link_2", 1)
					comp:setItemWithEvent("item_spring_shoes", 1)
					comp:setItemWithEvent("item_fire_element", 1)
				end
    		end 
    	end     
    end    
end	
                
function abTestHack()
	logger:info("AB toggle")

	local sceneInstanceManager = gameScene:getSceneInstanceManager()
	local playerCharacters = common.CommonUtils.getSelectedPlayerCharacters()
	
	for key, playerInstance in pairs(playerCharacters) do
		if playerInstance then
			local component = playerInstance:findComponent(trinebase.gameplay.character.TrinePlayerCharacterComponent);
			if component then
				component:setABTestHack(not component:getABTestHack())
			end
		end
	end
end

function moveTime()
	local manager = gameScene:getSceneInstanceManager():findInstanceByName("GameplayTimeManagerInst")
	manager:setSimulationActiveTime(Time(1696)) -- Max time for properties apparently?
end

function stopTime()
	local manager = gameScene:getSceneInstanceManager():findInstanceByName("GameplayTimeManagerInst")
	manager:setSimulationActiveTime(Time(0))
end

function makeAiBlindAndDeaf()
	function recurseInstances(inst)
		if not inst then
			logger:error("Calling recurseInstances with NIL instance in cheat.makeAiBlindAndDeaf")
			return
		end
		
		local alertnessComp = inst:findComponent(game.gameplay.ai.AlertnessComponent)
		if alertnessComp then
			local name = typeManager:getTypeByUH(inst:getType()):getName() .. " (" .. inst:getName() .. ")"
			
			local alertnessAreaComp = alertnessComp:findComponent(area.CapsuleAreaComponent)
			if alertnessAreaComp then
				alertnessAreaComp:setEnabled(false)
			else
				logger:error(name .. " AlertnessComponent did not have AbstractAreaComponent as a subcomponent");
			end
			
			local soundComp = inst:findComponent(trinebase.gameplay.SoundListenerComponent)
			if soundComp then
				soundComp:setEnabled(false)
			else
				logger:warning("Could not find trinebase.gameplay.SoundListenerComponent in " .. name)
			end
			
			logger:info(name .. " is now blind and deaf")
			return
		end
		
		for i = 0, inst:getNumChildren()-1 do
			recurseInstances(inst:getChild(i))
		end
	end
	
	recurseInstances(gameScene:getSceneInstanceManager():getTopmostInstanceRoot())
end

function letThereBeLight()
	function recurseInstances(inst)
		if not inst then
			logger:error("Calling recurseInstances with NIL instance in cheat.letThereBeLight")
			return
		end
		
		local ambientLightComponent = inst:findComponent(lighting.AmbientLightComponent)
		if ambientLightComponent then
			ambientLightComponent:setIntensity(1)
			return
		end
		
		for i = 0, inst:getNumChildren()-1 do
			recurseInstances(inst:getChild(i))
		end
	end
	
	recurseInstances(gameScene:getSceneInstanceManager():getTopmostInstanceRoot())
end

function makeChildUndetectable()
	function recurseInstances(inst)
		if not inst then
			logger:error("Calling recurseInstances with NIL instance in cheat.makeChildUndetectable")
			return
		end
		
		local gcucc = inst:findComponent(game.gameplay.character.GameCharacterUnderCommandComponent);
		if gcucc then
			local actorArea = inst:findComponent(area.BoxAreaComponent)
			if actorArea then
				gameScene:getSceneInstanceManager():deleteInstanceInstantly(actorArea:getUnifiedHandle());
			end
		end
		
		for i = 0, inst:getNumChildren()-1 do
			recurseInstances(inst:getChild(i))
		end
	end
	
	recurseInstances(gameScene:getSceneInstanceManager():getTopmostInstanceRoot())
end

function makeChildNotMove()
	function recurseInstances(inst)
		if not inst then
			logger:error("Calling recurseInstances with NIL instance in cheat.makeChildUndetectable")
			return
		end
		
		local gcucc = inst:findComponent(game.gameplay.character.GameCharacterUnderCommandComponent);
		if gcucc then
			gcucc:disableNavigationAndFollowing();
		end
		
		for i = 0, inst:getNumChildren()-1 do
			recurseInstances(inst:getChild(i))
		end
	end
	
	recurseInstances(gameScene:getSceneInstanceManager():getTopmostInstanceRoot())
end

function changeCharacter()
	function recurseInstances(inst)
		if not inst then
			logger:error("Calling recurseInstances with NIL instance in cheat.changeCharacter")
			return
		end
		
		local selectionComponent = inst:findComponent(game.gameplay.MacbethPlayerActorChangeComponent);
		if selectionComponent then
			selectionComponent:toggleBetweenCharacters();
		end
		
		for i = 0, inst:getNumChildren()-1 do
			recurseInstances(inst:getChild(i))
		end
	end
	
	recurseInstances(gameScene:getSceneInstanceManager():getTopmostInstanceRoot())
end

function testRunToMissionExit()
	function recurseInstances(inst)
		if not inst then
			logger:error("Calling recurseInstances with NIL instance in cheat.testRunToMissionExit")
			return
		end
		
		local aiNavigationComponent = inst:findComponent(game.gameplay.ai.MacBethAINavigationComponent);
		if aiNavigationComponent then
			aiNavigationComponent:testRunToAIMissionExit();
		end
		
		local aiCharacterComponent = inst:findComponent(game.gameplay.ai.MacBethAICharacterComponent);
		if aiCharacterComponent then
			aiCharacterComponent:testConfiguration();
		end
		
		for i = 0, inst:getNumChildren()-1 do
			recurseInstances(inst:getChild(i))
		end
	end
	
	recurseInstances(gameScene:getSceneInstanceManager():getTopmostInstanceRoot())
end

function teleportActors(lilyToShadwen)
	local actorManager = gameScene:getSceneInstanceManager():findInstanceByName("MacbethPlayerActorManagerInst");
	if not actorManager then
		return
	end
	if not actorManager:getSpawnLily() or not actorManager:getSpawnShadwen() then
		return
	end
	local lily = gameScene:getSceneInstanceManager():getInstanceByUH(actorManager:getChildInstance():getUH());
	local shadwen = gameScene:getSceneInstanceManager():getInstanceByUH(actorManager:getAdultInstance():getUH());
	if lily == nil or shadwen == nil then
		return
	end
	local lilyTransform = lily:findComponent(engine.component.TransformComponent);
	local shadwenTransform = shadwen:findComponent(engine.component.TransformComponent)
	if lilyTransform == nil or shadwenTransform == nil then
		return
	end
	if lilyToShadwen then
		lilyTransform:setPosition(shadwenTransform:getPosition());
	else
		shadwenTransform:setPosition(lilyTransform:getPosition());
	end
end

function killAllGuards()
	function recurseInstances(inst)
		local alertnessComp = inst:findComponent(game.gameplay.ai.AlertnessComponent)
		if alertnessComp then
			local comp = inst:findComponent(gameplay.damage.HealthComponent)
			if comp then
				comp:setHealth(0)
			end
			return
		end
		
		for i = 0, inst:getNumChildren()-1 do
			recurseInstances(inst:getChild(i))
		end
	end
	
	recurseInstances(gameScene:getSceneInstanceManager():getTopmostInstanceRoot())
end

function teleportToExit()
	function recurseInstances(inst)		
		local exitComp = inst:findComponent(gameplay.MissionExitComponent)
		if exitComp then
			local comp = inst:findComponent(engine.component.TransformComponent);
			return comp:getPosition()
		end
		
		for i = 0, inst:getNumChildren()-1 do
			local result = recurseInstances(inst:getChild(i));
			if(result) then
				return result;
			end
		end
		return nill;
	end
	
	local exitPos = recurseInstances(gameScene:getSceneInstanceManager():getTopmostInstanceRoot())
	if(not exitPos) then
		logger:error("cheat.teleportToExit cannot find exit")
		return
	end
	
	local actorManager = gameScene:getSceneInstanceManager():findInstanceByName("MacbethPlayerActorManagerInst");
	if not actorManager then
		return
	end
	local lily = gameScene:getSceneInstanceManager():getInstanceByUH(actorManager:getChildInstance():getUH());
	local shadwen = gameScene:getSceneInstanceManager():getInstanceByUH(actorManager:getAdultInstance():getUH());
	if lily  then
		local lilyTransform = lily:findComponent(engine.component.TransformComponent);
		lilyTransform:setPosition(exitPos);
	end
	if shadwen then
		local shadwenTransform = shadwen:findComponent(engine.component.TransformComponent)
		shadwenTransform:setPosition(exitPos);
	end
end
