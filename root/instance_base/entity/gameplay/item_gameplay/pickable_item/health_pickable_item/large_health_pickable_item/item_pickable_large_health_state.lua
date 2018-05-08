local moduleName = "gameplay.item.ItemPickableLargeHealthState"
module(moduleName, package.seeall)
gameplay.stateCollectionUtils.createReloadSupport(moduleName)


require "data/root/instance_base/entity/gameplay/item_gameplay/pickable_item/health_pickable_item/item_pickable_health_state.lua"


local states = {}
states.Spawn = gameplay.item.ItemPickableHealthState.Spawn
states.Idle = gameplay.item.ItemPickableHealthState.Idle
states.Picked = gameplay.item.ItemPickableHealthState.Picked

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
	Picked.showCollectionMessage(self, "hud.collection_messages_window.picked_up_large_health_potion")	
end

function Picked:onExit()
	Picked.super.onExit(self);
end

-------------------------------------------------------------------------------------------------