local moduleName = "gameplay.item.ItemPickableManaState"
module(moduleName, package.seeall)
gameplay.stateCollectionUtils.createReloadSupport(moduleName)


require "data/root/instance_base/entity/gameplay/item_gameplay/pickable_item/item_pickable_state.lua"


local states = {}
states.Spawn = gameplay.item.ItemPickableState.Spawn
states.Idle = gameplay.item.ItemPickableState.Idle
states.Picked = gameplay.item.ItemPickableState.Picked

gameplay.stateCollectionUtils.createStateCollection(moduleName, states)

stateCollection:setDefaultState("Spawn");

-------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------

function Spawn:onEnter()
	Spawn.super.onEnter(self);
end

function Spawn:onExit()
	Spawn.super.onExit(self);
end

-------------------------------------------------------------------------------------------------

function Idle:onEnter()
	Idle.super.onEnter(self);
end

function Idle:onExit()
	Idle.super.onExit(self);
end

function Idle:EventAreaOnEnter()
	Idle.super.EventAreaOnEnter(self);
end

-------------------------------------------------------------------------------------------------

function Picked:onEnter()

	gameplay.item.ItemPickableState.playOnPickEffect(self);
	
	if(self:getNetSyncer():hasLocalMaster())
	then
		local sce = common.CommonUtils.getScene()
		if not sce then
			logger:error(obj, "item_pickable_mana_state:Picked:onEnter() - Scene is nil")
			return false;
		end
		
		-- Give mana to all players
		local characterManager = common.CommonUtils.getCharacterSelectionManager()
		if characterManager then
			local charNum = characterManager:getNumAllCharacters()
			for i = 1,charNum do
				local playerInstance = characterManager:getFromAllCharactersByIndex(i-1)
				if playerInstance ~= nil then
					local manaC = playerInstance:findComponent(trinebase.gameplay.TrineManaComponent)
					local inventoryC = playerInstance:findComponent(game.gameplay.item.GameInventoryItemCollectionComponent)
					if manaC then
						local iPC = self:getFinalOwner():findComponent(gameplay.item.ItemPickableComponent);
						local manaToGive = iPC:getGiveAmount()
						if inventoryC ~= nil then
							manaToGive = inventoryC:multiplyPickedupMana(manaToGive)
						else
							logger:error("ItemPickableManaState:Picked:onEnter - Player instance doesn't have GameInventoryItemCollectionComponent.") 
						end
						eventQueue:sendEventToMaster(manaC:getUnifiedHandle(), manaC.EventSetManaRelative, {manaChange=manaToGive});
					else
						logger:error("ItemPickableManaState:Picked:onEnter - Player instance doesn't have ManaComponent.");
					end
				end
			end
		end	
		
		sceneInstanceManager:deleteInstance(self:getFinalOwner():getUnifiedHandle());
	else
		-- just hide it on client (this will be reverted automatically if picking fails)
		local mc = self:getFinalOwner():getModelComponent()
		if(mc) then
			mc:setVisibilityEnabled(false)
		end
	end
	
end

function Picked:onExit()
	Picked.super.onExit(self);
end

-------------------------------------------------------------------------------------------------
