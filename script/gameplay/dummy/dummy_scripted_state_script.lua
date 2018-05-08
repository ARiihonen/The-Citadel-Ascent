local moduleName = "gameplay.Dummy.DummyScriptedStateScript"
module(moduleName, package.seeall)
gameplay.stateCollectionUtils.createReloadSupport(moduleName)


local states = {}
states.Dummy = ""

gameplay.stateCollectionUtils.createStateCollection(moduleName, states)

gameplay.stateCollectionUtils.setCommonStateIfNotSet(moduleName, "Common", nil)

stateCollection:setDefaultState("Dummy");

-------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------

function Common:EventOnDestroyed()
	-- nop
end

-------------------------------------------------------------------------------------------------

function Dummy:onEnter()
	-- nop
end

function Dummy:onExit()
	-- nop
end

-------------------------------------------------------------------------------------------------
