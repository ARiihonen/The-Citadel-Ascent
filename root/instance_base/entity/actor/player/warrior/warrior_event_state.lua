local moduleName = "gameplay.WarriorEventState"
module(moduleName, package.seeall)
gameplay.stateCollectionUtils.createReloadSupport(moduleName)


require "data/root/instance_base/entity/actor/player/trine_character_event_state.lua"

local states = {}
states.Event = gameplay.CharacterEventState.Event

gameplay.stateCollectionUtils.createStateCollection(moduleName, states);
gameplay.stateCollectionUtils.setCommonStateIfNotSet(moduleName, "Common", gameplay.CharacterEventState.Common);
stateCollection:setDefaultState("Event");

-------------------------------------------------------------------------------------------------

function Event:onEnter()
	Event.super.onEnter(self);
end

function Event:onExit()
	Event.super.onExit(self);
end

function Event:EventOnDamage()
	Event.super.EventOnDamage(self);
end

function Event:EventSlipperySurface()
	Event.super.EventSlipperySurface(self)
end

function Event:EventGrippingSurface()
	Event.super.EventGrippingSurface(self)
end

-- HACK: Event validator shut up
function Event:EventAnimPickupStart()
	-- nop
end

-------------------------------------------------------------------------------------------------
