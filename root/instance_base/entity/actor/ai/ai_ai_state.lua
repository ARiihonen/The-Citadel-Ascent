local moduleName = "gameplay.actor.AiAiState"
module(moduleName, package.seeall)
gameplay.stateCollectionUtils.createReloadSupport(moduleName)

local states = {}
states.InActive = ""
states.Disabled = ""
states.Spawn = ""
states.WaitingForTarget = ""
states.Idle = ""
states.Destroyed = ""
states.DestroyedNoBody = ""
states.AIEnd = ""
states.Frozen = ""
states.TrappedInBox = ""
states.Bouncing = ""

gameplay.stateCollectionUtils.createStateCollection(moduleName, states)
gameplay.stateCollectionUtils.setCommonStateIfNotSet(moduleName, "Common", nil)
stateCollection:setDefaultState("InActive");

-------------------------------------------------------------------------------------------------

function transitionToDisabledStates(self)
	-- If ai is disabled, go to disabled state and start waiting for enabled event
	if not gameplay.ai.AiUtils.isAIEnabled(self) then	
		self:changeState("Disabled");
		return true;
	end
	
	-- If ai is inactive, go to inactive state and start waiting for activated event
	if not gameplay.ai.AiUtils.isAIActive(self) then	
		self:changeState("InActive");
		return;
	end
	
	return false;
end

-------------------------------------------------------------------------------------------------

function Common:EventOnDestroyed()
	--
	-- Engine may trigger AI destroyed event
	--	
	if gameplay.ai.AiUtils.isState(self, "Destroyed") then
		return;
	end
	
	if gameplay.ai.AiUtils.isState(self, "DestroyedNoBody") then
		return;
	end
	
	-- Cancel all old events
	self:cancelAllEvents();

	gameplay.ai.AiUtils.setAIDestroyed(self, true);
	self:changeState("Destroyed");
end

function Common:EventOnDestroyedNoBody()
	--
	-- Engine may trigger AI destroyedNoBody event (should lose the body/ragdoll)
	--	
	if gameplay.ai.AiUtils.isState(self, "Destroyed") then
		return;
	end
	
	if gameplay.ai.AiUtils.isState(self, "DestroyedNoBody") then
		return;
	end
	
	-- Cancel all old events
	self:cancelAllEvents();
	
	gameplay.ai.AiUtils.setAIDestroyed(self, true);
	self:changeState("DestroyedNoBody");
end

function Common:EventAIActivated()
	--
	-- Engine may trigger AI activated event
	--	
	if gameplay.ai.AiUtils.isState(self, "Destroyed") then
		return;
	end
	
	if gameplay.ai.AiUtils.isState(self, "DestroyedNoBody") then
		return;
	end
	
	if gameplay.ai.AiUtils.isState(self, "TrappedInBox") then
		return;
	end
	
	-- If ai is disabled, go to disabled state and start waiting for enabled event
	if not gameplay.ai.AiUtils.isAIEnabled(self) then	
		self:changeState("Disabled");
		return;
	end
	
	-- Cancel all old events
	self:cancelAllEvents();
	
	local frozeMe = self:getFinalOwner():findComponent(trinebase.gameplay.skills.TrineFrozeMeComponent)
	if frozeMe and frozeMe:isFrozen() then
		self:changeState("Frozen");
	else
		-- Start the AI! (Add some delay that the property Active gets set)
		self:delayedStateCall("startAI", gameplay.ai.AiUtils.getRandomInt(self, 20, 50)); -- Add some random that "Exceeded maximum limit for delayed state calls per frame" will shut up :)
	end
end

function Common:EventAIDeactivated()
	--
	-- Engine may trigger AI deactivated event
	--
	if gameplay.ai.AiUtils.isState(self, "Destroyed") then
		return;
	end
	
	if gameplay.ai.AiUtils.isState(self, "DestroyedNoBody") then
		return;
	end

	if gameplay.ai.AiUtils.isState(self, "TrappedInBox") then
		return;
	end

	-- Cancel all old events
	self:cancelAllEvents();
	
	-- If spawning, go to inactive state delayed
	if gameplay.ai.AiUtils.isState(self, "Spawn") then
		-- HACK value, all spawning should be finished in this time
		self:delayedChangeState("InActive", 7500);
		--gameplay.ai.AiUtils.logAIWarning(self, "Common:EventAIDeactivated - AI was spawning in to the scene when EventAIDeactivated was called, changing to InActive state after 7500 ms.");
		return;
	end
	
	self:changeState("InActive");
end

function Common:EventAIEnabled()	
	--
	-- Engine may trigger AI enabled event
	--	
	if gameplay.ai.AiUtils.isState(self, "Destroyed") then
		return;
	end
	
	if gameplay.ai.AiUtils.isState(self, "DestroyedNoBody") then
		return;
	end
	
	-- NOTE: Hmm, this should be allowed (don't remember why it isn't so commenting it out :) -Jari)
	--if gameplay.ai.AiUtils.isState(self, "InActive") then
	--	gameplay.ai.AiUtils.logAIError(self, "AiAiState:Common:EventAIEnabled - Trying to enable AI which isn't active yet. AI gets activated by activation area, shouldn't enable the AI before that. Nothing happens now.");
	--	return;
	--end	
	-- If ai is inactive, go to inactive state and start waiting for activated event
	if not gameplay.ai.AiUtils.isAIActive(self) then	
		self:changeState("InActive");
		return;
	end
	
	-- Cancel all old events
	self:cancelAllEvents();
	
	self:changeState("Idle");
end

function Common:EventAIDisabled()
	--
	-- Engine may trigger AI disabled event
	--
	
	if gameplay.ai.AiUtils.isState(self, "Destroyed") then
		return;
	end
	
	if gameplay.ai.AiUtils.isState(self, "DestroyedNoBody") then
		return;
	end
	
	-- NOTE: Hmm, this should be allowed (don't remember why it isn't so commenting it out :) -Jari)
	--if gameplay.ai.AiUtils.isState(self, "InActive") then
	--	gameplay.ai.AiUtils.logAIError(self, "AiAiState:Common:EventAIDisabled - Trying to disable AI which isn't active yet. AI gets activated by activation area, shouldn't disable the AI before that. Nothing happens now.");
	--	return;
	--end
	
	-- Cancel all old events
	self:cancelAllEvents();
	
	self:changeState("Disabled");
end

function Common:EventCinematicEnabled()
	--
	-- Engine may trigger cinematic enabled event
	--
	
	if gameplay.ai.AiUtils.isState(self, "Destroyed") then
		return;
	end
	
	if gameplay.ai.AiUtils.isState(self, "DestroyedNoBody") then
		return;
	end
	
	local cc = gameplay.ai.AiUtils.getAICharacterComponent(self);
	if cc ~= nil then
		if not cc:getCinematicEnabled() then
			cc:setCinematicEnabled(true);
		end
	end
	
	-- Cancel all old events
	self:cancelAllEvents();

	self:changeState("Disabled");
end

function Common:EventCinematicDisabled()
	--
	-- Engine may trigger cinematic disabled event
	--
	
	if gameplay.ai.AiUtils.isState(self, "Destroyed") then
		return;
	end
	
	if gameplay.ai.AiUtils.isState(self, "DestroyedNoBody") then
		return;
	end
	
	local cc = gameplay.ai.AiUtils.getAICharacterComponent(self);
	if cc ~= nil then
		if cc:getCinematicEnabled() then
			cc:setCinematicEnabled(false);
		end
	end
	
	if not gameplay.ai.AiUtils.isState(self, "Idle") then
		-- Cancel all old events
		self:cancelAllEvents();
		
		if transitionToDisabledStates(self) then
			return;
		end

		self:changeState("Idle");
	end
end

function Common:EventOnFrozen()
	if gameplay.ai.AiUtils.isState(self, "Destroyed") then
		return;
	end
	
	if gameplay.ai.AiUtils.isState(self, "DestroyedNoBody") then
		return;
	end
	
	if gameplay.ai.AiUtils.isState(self, "Grabbed") then
		return;
	end
	
	if gameplay.ai.AiUtils.isState(self, "TrappedInBox") then
		self:doStateCall("onFrozen")
		return;
	end

	self:changeState("Frozen")
end

function Common:EventStartSlowFreeze()
	--nop
end

function Common:EventStopSlowFreeze()
	--nop
end

function Common:EventLevitateStart()
	self:delayedCommonStateCall("startLevitationStartAudio", gameplay.ai.AiUtils.getRandomInt(self, 1000, 2000, true))
end

function Common:startLevitationStartAudio()	
	gameplay.ai.AiUtils.startLevitationStartAudio(self);
end

function Common:EventLevitateStop()
	gameplay.ai.AiUtils.stopLevitationStartAudio(self);
end

function Common:EventTrappedInBox()
	self:changeState("TrappedInBox")
end

-------------------------------------------------------------------------------------------------

function InActive:onEnter()	
	-- Enable default context
	gameplay.ai.AiUtils.enableDefaultAnimationContext(self);
	
	-- AI is enabled, start the AI delayed
	self:delayedStateCall("delayedAIStartIfNearCamera", 50);	
end

function InActive:onExit()
	-- Disable default context
	gameplay.ai.AiUtils.disableDefaultAnimationContext(self);
end

function InActive:delayedAIStartIfNearCamera()
	-- If ai is disabled, go to disabled state and start waiting for enabled event
	if not gameplay.ai.AiUtils.isAIEnabled(self) then	
		self:changeState("Disabled");
		return;
	end
		
	-- If AI starts e.g. near the camera, should try to enable it right away
	if gameplay.ai.AiUtils.isAIActive(self) then				
		-- AI is enabled, start the AI delayed
		self:delayedStateCall("startAI", gameplay.ai.AiUtils.getRandomInt(self, 20, 50)); -- Add some random that "Exceeded maximum limit for delayed state calls per frame" will shut up :)
	end
end

function InActive:startAI()
	if not gameplay.ai.AiUtils.isAIActive(self) then
		-- Not an error
		--gameplay.ai.AiUtils.logAIError(self, "AiAiState:InActive:startAI - Trying to start the AI but AI isn't active.");
		return;
	end
	
	-- Make sure that weapon contexts are enabled
	gameplay.ai.AiUtils.enableWeaponContexts(self);
	
	self:changeState("Spawn");
end

-------------------------------------------------------------------------------------------------

function Disabled:onEnter()
	-- Enable default context
	gameplay.ai.AiUtils.enableDefaultAnimationContext(self);
end

function Disabled:onExit()
	-- Disable default context
	gameplay.ai.AiUtils.disableDefaultAnimationContext(self);
end

-------------------------------------------------------------------------------------------------

function Spawn:onEnter()
	-- nop
end

function Spawn:onExit()
	-- nop
end

function Spawn:EventTargetSet()
	-- Spawn effect (sound)
	gameplay.ai.AiUtils.spawnEnemyEffectSpot(self);
end

function Spawn:EventTargetSpotted()
	-- Spawn effect (sound)
	-- NOTE: Duplicate sound! See EventTargetSet
	--gameplay.ai.AiUtils.spawnEnemyEffectSpot(self);
end

-------------------------------------------------------------------------------------------------

function WaitingForTarget:onEnter()	
	-- Just to be sure, clear all context to get fresh start
	gameplay.ai.AiUtils.getAnimationComponent(self):debugClearAllContexts(); -- HACK/LEGACY: debugClearAllContexts() should be for debugging only
	
	-- Enable default context
	gameplay.ai.AiUtils.enableDefaultAnimationContext(self);
	
	self:delayedStateCall("spawnIdleEffect", gameplay.ai.AiUtils.getRandomInt(self, getInstanceType(self):getIdleSoundInterValMin(), getInstanceType(self):getIdleSoundInterValMax(), true));
end

function WaitingForTarget:onExit()
	-- Disable default context
	gameplay.ai.AiUtils.disableDefaultAnimationContext(self);
end

function WaitingForTarget:EventTargetSet()
	-- Spawn effect (sound)
	gameplay.ai.AiUtils.spawnEnemyEffectSpot(self);
end

function WaitingForTarget:spawnIdleEffect()
	-- Spawn effect (sound)
	gameplay.ai.AiUtils.spawnEnemyEffectIdle(self);
	
	self:delayedStateCall("spawnIdleEffect", gameplay.ai.AiUtils.getRandomInt(self, getInstanceType(self):getIdleSoundInterValMin(), getInstanceType(self):getIdleSoundInterValMax(), true));
end

function WaitingForTarget:EventTargetSpotted()
	-- Spawn effect (sound)
	-- NOTE: Duplicate sound! See EventTargetSet
	--gameplay.ai.AiUtils.spawnEnemyEffectSpot(self);
end

-------------------------------------------------------------------------------------------------

function Idle:onEnter()
	-- Spawn effect (sound)
	gameplay.ai.AiUtils.spawnEnemyEffectIdle(self);
	
	self:delayedStateCall("spawnIdleEffect", gameplay.ai.AiUtils.getRandomInt(self, getInstanceType(self):getIdleSoundInterValMin(), getInstanceType(self):getIdleSoundInterValMax(), true));
end

function Idle:onExit()
	-- nop
end

function Idle:EventTargetSet()
	-- Spawn effect (sound)
	gameplay.ai.AiUtils.spawnEnemyEffectSpot(self);
end

function Idle:EventTargetSpotted()
	-- Spawn effect (sound)
	-- NOTE: Duplicate sound! See EventTargetSet
	--gameplay.ai.AiUtils.spawnEnemyEffectSpot(self);
end

function Idle:spawnIdleEffect()
	-- Spawn effect (sound)
	gameplay.ai.AiUtils.spawnEnemyEffectIdle(self);
	
	self:delayedStateCall("spawnIdleEffect", gameplay.ai.AiUtils.getRandomInt(self, getInstanceType(self):getIdleSoundInterValMin(), getInstanceType(self):getIdleSoundInterValMax(), true));
end

-------------------------------------------------------------------------------------------------

function Destroyed:onEnter()
	if getInstanceType(self):getSpawnEnemyEffectDeathOnDestroyedEnter() then
		-- Spawn effect (sound)
		gameplay.ai.AiUtils.spawnEnemyEffectDeath(self);
	end
	
	gameplay.ai.AiUtils.removeUnnecessaryComponentsOnDestroyed(self);
	
	local hittable = self:getFinalOwner():findComponent(gameplay.hit.HittableComponent)
	if hittable then
		local weapon = sceneInstanceManager:getInstanceByUH(hittable:getLastWeaponHitInstance())
		if weapon then
			local hammer = weapon:findComponent(trinebase.gameplay.weapon.FlyingHammerComponent)
			if hammer then
				hammer:hammerKilled()
			end
			scene:aiKilled(self:getFinalOwner():getUnifiedHandle(), hittable:getLastWeaponHitInstance())
		end
	end
	
	local floatingInfo = self:getFinalOwner():findComponent(trinebase.gameplay.skills.FloatingInfoComponent)
	if floatingInfo then
		floatingInfo:setFloatingStyle(trinebase.gameplay.skills.FloatingNormalAndGravity)
	end
end

function Destroyed:onExit()
	self:cancelAllEvents();
end

-------------------------------------------------------------------------------------------------

function DestroyedNoBody:onEnter()
	-- NOTE: Spawn always reward! DO THIS FIRST!
	if self:getNetSyncer():hasLocalMaster() then
		-- Handle reward spawning, spawn still something even if failed
		gameplay.ai.AiUtils.spawnReward(self);
	end
	
	if getInstanceType(self):getSpawnEnemyEffectDeathOnDestroyedEnter() then
		-- Spawn effect (sound)
		gameplay.ai.AiUtils.spawnEnemyEffectDeath(self);
	end
	
	-- No need because the AI is about to be deleted instantly
	--gameplay.ai.AiUtils.removeUnnecessaryComponentsOnDestroyed(self);
	
	-- This deletes the AI instantly
	self:changeState("AIEnd");
end

function DestroyedNoBody:onExit()
	-- nop
end

-------------------------------------------------------------------------------------------------

function AIEnd:onEnter()	
	if not self:getNetSyncer():hasLocalMaster() then
		return;
	end
	common.CommonUtils.getSceneInstanceManager():deleteInstance(self:getFinalOwner():getUnifiedHandle());
end

function AIEnd:onExit()
	-- nop
end

-------------------------------------------------------------------------------------------------

function Frozen:onEnter()
	gameplay.ai.AiUtils.moveStateStopNoError(self)
	
	-- Make sure that AI doesn't move
	gameplay.ai.AiUtils.disableRootMotionY(self);
	gameplay.ai.AiUtils.disableRootMotionZ(self);
	
	gameplay.ai.AiUtils.getAnimationComponent(self):setRootMotionErrorCompensationDistance(0.0)
	
	gameplay.ai.AiUtils.setAnimationContextEnabledIfHasContext(self, gameplay.ai.AiUtils.getAnimationContextNameFrozen(), true)
	
	-- Disable all weapon damages
	gameplay.ai.AiUtils.disableWeaponDamages(self);
	
	gameplay.ai.AiUtils.disablePushEachOthers(self)
end

function Frozen:onExit()
	gameplay.ai.AiUtils.enablePushEachOthers(self)
	
	gameplay.ai.AiUtils.getAnimationComponent(self):setRootMotionErrorCompensationDistance(0.25) -- TODO: Return original one...
	gameplay.ai.AiUtils.setAnimationContextEnabledIfHasContext(self, gameplay.ai.AiUtils.getAnimationContextNameFrozen(), false)
end

function Frozen:EventOnUnFrozen()
	local ignoreAIPathHelpers = false;
	if gameplay.actor.ai.enemy.WalkWithHelpersAiState.transitionToNormalAI(self, ignoreAIPathHelpers) then
		return;
	else
		gameplay.ai.AiUtils.logAIError(self, "AiState:AiState:EventOnUnFrozen - Transition to normal AI failed, AI is probably jammed.");
		self:changeState("Idle");
	end
end

function Frozen:EventOnDamage()
	-- nop
end

function Frozen:EventAnimStaggerFinished()
	-- nop
end

function Frozen:EventLevitateStart()
	-- nop
end

function Frozen:EventSquashStart()
	-- TODO: dont allow squash when frozen?
end

-------------------------------------------------------------------------------------------------

function TrappedInBox:onEnter()
	gameplay.ai.AiUtils.moveStateStopNoError(self)

	gameplay.ai.AiUtils.setAnimationContextEnabledIfHasContext(self, "trapped", true)
	
	-- Disable all weapon damages
	gameplay.ai.AiUtils.disableWeaponDamages(self);
	
	local frozeMe = self:getFinalOwner():findComponent(trinebase.gameplay.skills.TrineFrozeMeComponent)
	if frozeMe:isFrozen() then
		self:doStateCall("onFrozen")
	end
	
	-- Make sure that AI doesn't move
	gameplay.ai.AiUtils.disableRootMotionForAllAxixes(self)

	gameplay.ai.AiUtils.disablePushEachOthers(self)
end

function TrappedInBox:onExit()
	gameplay.ai.AiUtils.enablePushEachOthers(self)

	gameplay.ai.AiUtils.setAnimationContextEnabledIfHasContext(self, "trapped", false)

	-- Allow movement again
	gameplay.ai.AiUtils.enableRootMotionX(self);
end

function TrappedInBox:EventOnDamage()
	-- nop
end

function TrappedInBox:EventAnimStaggerFinished()
	-- nop
end

function TrappedInBox:EventLevitateStart()
	-- nop
end

function TrappedInBox:EventSquashStart()
	-- nop
end

function TrappedInBox:onFrozen()
	gameplay.ai.AiUtils.setAnimationContextEnabledIfHasContext(self, gameplay.ai.AiUtils.getAnimationContextNameFrozen(), true)
end

function TrappedInBox:EventOnUnFrozen()
	gameplay.ai.AiUtils.setAnimationContextEnabledIfHasContext(self, gameplay.ai.AiUtils.getAnimationContextNameFrozen(), false)
end

function TrappedInBox:EventFreedFromBox()
	local ignoreAIPathHelpers = false
	gameplay.actor.ai.enemy.WalkWithHelpersAiState.transitionToNormalAI(self, ignoreAIPathHelpers)
end

-------------------------------------------------------------------------------------------------

-- NOTE: These events are unnecessary, they are defined that the event validator is happy :) (Should exlude this state from the validator)
function Idle:EventOnDamage() end
function Idle:EventAnimStaggerFinished() end
function Idle:EventLevitateStart() end
function Idle:EventSquashStart() end

function WaitingForTarget:EventOnDamage() end
function WaitingForTarget:EventAnimStaggerFinished() end
function WaitingForTarget:EventLevitateStart() end
function WaitingForTarget:EventSquashStart() end

function Spawn:EventOnDamage() end
function Spawn:EventAnimStaggerFinished() end
function Spawn:EventLevitateStart() end
function Spawn:EventSquashStart() end

function InActive:EventOnDamage() end
function InActive:EventAnimStaggerFinished() end
function InActive:EventLevitateStart() end
function InActive:EventSquashStart() end

function Disabled:EventOnDamage() end
function Disabled:EventAnimStaggerFinished() end
function Disabled:EventLevitateStart() end
function Disabled:EventSquashStart() end

function Destroyed:EventOnDamage() end
function Destroyed:EventAnimStaggerFinished() end
function Destroyed:EventLevitateStart() end
function Destroyed:EventSquashStart() end

function DestroyedNoBody:EventOnDamage() end
function DestroyedNoBody:EventAnimStaggerFinished() end
function DestroyedNoBody:EventLevitateStart() end
function DestroyedNoBody:EventSquashStart() end

function AIEnd:EventOnDamage() end
function AIEnd:EventAnimStaggerFinished() end
function AIEnd:EventLevitateStart() end
function AIEnd:EventSquashStart() end

-------------------------------------------------------------------------------------------------
