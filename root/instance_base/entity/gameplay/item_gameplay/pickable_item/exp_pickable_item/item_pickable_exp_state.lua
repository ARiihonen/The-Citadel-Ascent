local moduleName = "gameplay.item.ItemPickableExpState"
module(moduleName, package.seeall)
gameplay.stateCollectionUtils.createReloadSupport(moduleName)


-- Full path required. gameplay.ItemPickableState only works if file is already loaded, which sort 
-- of makes calling require pointless.
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

	local largeExpBottle = false
	if(self:getNetSyncer():hasLocalMaster()) then
		if sceneInstanceManager then
			local upgradeManager = common.CommonUtils.getTrineUpgradeManager()
			if upgradeManager then
				local iPC = self:getFinalOwner():findComponent(gameplay.item.ItemPickableComponent)
				if iPC then
					local creatorUH = iPC:getCreatorUH()
					local creator = nil
					if creatorUH ~= UH_NONE then
						creator = sceneInstanceManager:getInstanceByUH(creatorUH)
					else
						creator = self:getFinalOwner():findComponent(trinebase.gameplay.TrineExperienceSpawnerComponent)
					end
					if creator then
						creator:experiencePicked(self:getFinalOwner(), iPC:getGiveAmount())
						if iPC:getGiveAmount() > 1 then
							largeExpBottle = true
						end
					else
						logger:error("ItemPickableExpState:Picked:onEnter - No creator found for item.")
					end
				else
					logger:error("ItemPickableExpState:Picked:onEnter - ItemPickableComponent not found.")
				end
			else
				logger:error("ItemPickableExpState:Picked:onEnter - upgradeManager is nil.")
			end
		else
			logger:error("ItemPickableExpState:Picked:onEnter - Invalid sceneInstanceManager.")
		end
		
	else
		-- just hide it on client (this will be reverted automatically if picking fails)
		local mc = self:getFinalOwner():getModelComponent()
		if(mc) then
			mc:setVisibilityEnabled(false)
		end
	end
				
	if largeExpBottle then
		Picked.showCollectionMessage(self, "hud.collection_messages_window.picked_up_large_experience_shard")
	else
		Picked.showCollectionMessage(self, "hud.collection_messages_window.picked_up_experience_shard")
	end

end

function Picked:onExit()
	Picked.super.onExit(self);
end

-------------------------------------------------------------------------------------------------
