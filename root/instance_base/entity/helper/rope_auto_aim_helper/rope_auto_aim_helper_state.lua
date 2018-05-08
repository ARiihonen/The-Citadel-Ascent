local moduleName = "gameplay.RopeAutoAimHelperState"
module(moduleName, package.seeall)
gameplay.stateCollectionUtils.createReloadSupport(moduleName)


local states = {}
states.Idle = ""

gameplay.stateCollectionUtils.createStateCollection(moduleName, states)

stateCollection:setDefaultState("Idle");

-------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------

function Idle:onEnter()
	-- nop
end

function Idle:onExit()
	-- nop
end

function Idle:onAreaEnter()
-- Seems to be old crap code. RopeAutoAimComponent::addAutoAimHelper doesn't work with UHs. Since 
-- RopeAutoAimComponent isn't subcomponent of RopeComponent, this doesn't error.
-- 	if not scene then
-- 		logger:error("RopeAutoAimHelperState: scene is nil")
-- 		return
-- 	end
-- 	if sceneInstanceManager then
-- 		local thiefInstance = sceneInstanceManager:getInstanceByUH(scene:getThief())
-- 		if thiefInstance then
-- 			ropeComp = thiefInstance:findComponent(trinebase.gameplay.skills.RopeComponent)
-- 			if ropeComp then
-- 				ropeAutoAimComp = ropeComp:findComponent(trinebase.gameplay.RopeAutoAimComponent)
-- 				if ropeAutoAimComp then
-- 					ropeAutoAimComp:addAutoAimHelper(self:getFinalOwner():getUnifiedHandle())
-- 				end
-- 			end
-- 		end
-- 	else
-- 		logger:error("RopeAutoAimHelperState: sceneInstanceManager is nil")	
-- 	end
end

function Idle:onAreaExit()
-- Seems to be old crap code. RopeAutoAimComponent::addAutoAimHelper doesn't work with UHs. Since 
-- RopeAutoAimComponent isn't subcomponent of RopeComponent, this doesn't error.
-- 	if not scene then
-- 		logger:error("RopeAutoAimHelperState: scene is nil")
-- 		return
-- 	end
-- 	if sceneInstanceManager then
-- 		local thiefInstance = sceneInstanceManager:getInstanceByUH(scene:getThief())
-- 		if thiefInstance then
-- 			ropeComp = thiefInstance:findComponent(trinebase.gameplay.skills.RopeComponent)
-- 			if ropeComp then
-- 				ropeAutoAimComp = ropeComp:findComponent(trinebase.gameplay.RopeAutoAimComponent)
-- 				if ropeAutoAimComp then
-- 					ropeAutoAimComp:removeAutoAimHelper(self:getFinalOwner():getUnifiedHandle())
-- 				end
-- 			end
-- 		end
-- 	else
-- 		logger:error("RopeAutoAimHelperState: sceneInstanceManager is nil")	
-- 	end
end

-------------------------------------------------------------------------------------------------
