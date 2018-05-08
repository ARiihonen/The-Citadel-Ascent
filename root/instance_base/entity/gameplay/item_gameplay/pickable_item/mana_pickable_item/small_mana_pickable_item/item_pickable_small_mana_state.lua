local moduleName = "gameplay.item.ItemPickableSmallManaState"
module(moduleName, package.seeall)
gameplay.stateCollectionUtils.createReloadSupport(moduleName)


require "data/root/instance_base/entity/gameplay/item_gameplay/pickable_item/mana_pickable_item/item_pickable_mana_state.lua"


local states = {}
states.Spawn = gameplay.item.ItemPickableManaState.Spawn
states.Idle = gameplay.item.ItemPickableManaState.Idle
states.Picked = gameplay.item.ItemPickableManaState.Picked

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
	Picked.super.onEnter(self);
	Picked.showCollectionMessage(self, "hud.collection_messages_window.picked_up_mana_potion")	
end

function Picked:onExit()
	Picked.super.onExit(self);
end

-------------------------------------------------------------------------------------------------
