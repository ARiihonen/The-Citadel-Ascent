local moduleName = "gameplay.item.ItemPickableHealthState"
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
	
	if(self:getNetSyncer():hasLocalMaster()) then
		local sce = common.CommonUtils.getScene()
		if not sce then
			logAIError(obj, "item_pickable_health_state:Picked:onEnter() - Scene is nil")
			return false;
		end
		
		-- Give health to all players
		local characterManager = common.CommonUtils.getCharacterSelectionManager()
		if characterManager then
			local charNum = characterManager:getNumAllCharacters()
			for i = 1,charNum do
				local playerInstance = characterManager:getFromAllCharactersByIndex(i-1)
				if playerInstance ~= nil then
					local healthC = playerInstance:findComponent(trinebase.gameplay.TrineHealthComponent)
					--local itemInventoryC = playerInstance:findComponent(game.gameplay.item.GameInventoryItemCollectionComponent)
					--local inventoryC = playerInstance:findComponent(gameplay.item.InventoryComponent)
					
					if healthC then
						-- increase health if not dead
						if healthC:getHealth() > 0 then
							--if inventoryC ~= nil then
								--if itemInventoryC ~= nil then
									local healthMultiplier = 1
									--if inventoryC:hasItem("item_crystal_h") then
									--	healthMultiplier = itemInventoryC:getCrystalHHealthPickupMultiplier()
									--end
									local iPC = self:getFinalOwner():findComponent(gameplay.item.ItemPickableComponent);	
									eventQueue:sendEventToMaster(healthC:getUnifiedHandle(), healthC.EventSetHealthRelative, {healthChange=iPC:getGiveAmount() * healthMultiplier});
								--else
									--logger:error("ItemPickableHealthState:Picked:onEnter - Player instance doesn't have GameInventoryItemCollectionComponent.");
								--end
							--else
								--logger:error("ItemPickableHealthState:Picked:onEnter - Player instance doesn't have InventoryComponent.")
							--end
						end
					else
						logger:error("ItemPickableHealthState:Picked:onEnter - Player instance doesn't have HealthComponent.");
					end
				end
			end
		end	
		-- Delete item instance
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
