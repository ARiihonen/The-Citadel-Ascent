local moduleName = "gameplay.CharacterEventState"
module(moduleName, package.seeall)
gameplay.stateCollectionUtils.createReloadSupport(moduleName)


local states = {}
states.Event = ""

gameplay.stateCollectionUtils.createStateCollection(moduleName, states);
gameplay.stateCollectionUtils.setCommonStateIfNotSet(moduleName, "Common", nil);
stateCollection:setDefaultState("Event");

-------------------------------------------------------------------------------------------------

function shouldIgnoreChestReward()
	-- Act normal
	return false;
end
	
function getInputComponent(self)
	if not self:getNetSyncer():hasLocalMaster() then return nil end
	
	local ic = self:getFinalOwner():findComponent(engine.component.AbstractInputComponent);
	if ic then
		return ic;
	else
		logger:error("TrineCharacterEventState:getInputComponent - AbstractInputComponent is missing.");
		return nil;
	end
end

-------------------------------------------------------------------------------------------------

function Common:EventOnDestroyed()
	Event.showHitEffect(self)
end

function Common:EventOnDestroyedNoBody()
	Event.showHitEffect(self)
end

-------------------------------------------------------------------------------------------------
	
function Event:onEnter()
	-- nop
end



function Event:onExit()
	-- nop
end

function Event:EventOnDamage()
	-- TODO: spawn some blood particle effect here
	local trophyDetectionManager = common.CommonUtils.getTrophyDetectionManager()
	--trophyDetectionManager:failSummerDip()
	trophyDetectionManager:playerDamaged()
	Event.showHitEffect(self)
end

function Event:showHitEffect()
--[[
-- NOTE: THIS IS OLD CODE, HANDLED WITH NEW FUI and WITH ART EFFECTS (colorEffectEntity)
	-- Open UI hit effect for local player hit
	if not self:getNetSyncer():hasLocalMaster() then return end

	-- Only show for selected characters
	local csc = self:getFinalOwner():findComponent(trinebase.gameplay.player.TrineCharacterSelectionComponent)
	if not csc or not csc:isSelected() or csc:getChangeInProgress() then return end

	if sceneInstanceManager then
		local effectManager = common.CommonUtils.getTrineUIEffectManager()
		if effectManager then
			local hitEffectComp = effectManager:findComponent(trinebase.gui.TrineUIHitEffectComponent)
			if hitEffectComp then
				hitEffectComp:showHitEffectImpl()
			else
				logger:error("TrineCharacterEventState:Event:EventOnDamage  - TrineUIHitEffectComponent is nil.")
			end
		else
			logger:error("TrineCharacterEventState:Event:EventOnDamage - TrineUIEffectManager in nil.")
		end
	else
		logger:error("TrineCharacterEventState:Event:EventOnDamage  - Invalid sceneInstanceManager.")
	end
]]--
end

function Event:EventSlipperySurface()
	-- TODO: stuff
	-- Character entered surface with low friction or steep angle
end

function Event:EventGrippingSurface()
	-- nop
end

-------------------------------------------------------------------------------------------------
-- Dummy events that event validator will shut up
function Event:EventAnimCreateRagdoll() end
function Event:EventAnimThrowFinished() end

-------------------------------------------------------------------------------------------------
-- Treasure chests and letters

function Event:onAnimChestEntered()
	if shouldIgnoreChestReward() then
		return;
	end

	-- master calls the rest of the stuff for all...
	if (self:getNetSyncer():hasLocalMaster()) then
		self:getFinalOwner():findComponent(gameplay.item.UsableItemTrackerComponent):flushNetSync()		
		self:sendGlobalCallToAll("Event", "onAnimChestEnteredSynced", 1)
	end
	self:delayedStateCall("EventAnimChestFinished", 2000)
end

function Event:onAnimChestEnteredSynced() 
	if shouldIgnoreChestReward() then
		return;
	end

	local treasureChestUH = self:getFinalOwner():findComponent(gameplay.item.UsableItemTrackerComponent):getLastItemUsed()
	if (treasureChestUH ~= UH_NONE) then
		local inst = sceneInstanceManager:getInstanceByUH(treasureChestUH)
		if (inst) then
			name = string.lower(inst:getName())

			-- HACK: letters are just treasure chests (might be invisible/differ visually though), but with a specific substring in the entity name 
			if (string.find(name, "letter", 1, true)) then
				-- letters are supposed to show locally only, thus this check, others should just ignore the whole thing.
				
				-- HACK: special cased this letter
				if (name == "seasurface_ruins_letter2") then
					local triggerName = name.."_trigger_target"
					local triggerInst = sceneInstanceManager:findInstanceByName(triggerName)
					if (triggerInst) then
						local triggerTimer = triggerInst:findComponent(gameplay.trigger.CinematicTimerTriggerComponent)
						if (triggerTimer) then
							triggerTimer:sendTriggerEventToAll()
						else
							logger:error("The instance \""..triggerName.."\" needs to have a CinematicTimerComponent.")
						end
					else
						logger:error("No instance with the name \""..triggerName.."\" found.")
					end
					-- the trigger will do this stuff...
					--state:runLuaString("gameplay.util.readLetterForAllPlayersForcibly([[seasurface_ruins_letter2]], false)")
				else	
					if (self:getNetSyncer():hasLocalMaster()) then
						state:runLuaString("gameplay.util.readLetter(\""..name.."\")")
					end				
				end			
			else
				-- (secret treasure is found after the animation completes...)
				-- nothing here
			end
		else
			logger:error("Did not find the treasure chest instance with given last used item UH.")
		end
	else
		-- Properties don't travel fast enough. This happens at least with letters.
		logger:error("No last used item UH.")
	end
end

function Event:EventAnimChestFinished() 
	if shouldIgnoreChestReward() then
		return;
	end

	if (self:getNetSyncer():hasLocalMaster()) then
		self:getFinalOwner():findComponent(gameplay.item.UsableItemTrackerComponent):flushNetSync()		
		self:sendGlobalCallToAll("Event", "onEventAnimChestFinishedSynced", 1)
	end
end

function Event:onEventAnimChestFinishedSynced() 

	if shouldIgnoreChestReward() then
		return;
	end

	local treasureChestUH = self:getFinalOwner():findComponent(gameplay.item.UsableItemTrackerComponent):getLastItemUsed()
	if (treasureChestUH ~= UH_NONE) then
		local inst = sceneInstanceManager:getInstanceByUH(treasureChestUH)
		if (inst) then
			name = string.lower(inst:getName())

			-- HACK: letters are just treasure chests (might be invisible/differ visually though), but with a specific substring in the entity name 
			if (string.find(name, "letter", 1, true)) then
				-- (letters shown at the beginning of the animation)
				-- note, that letters should never cause this to finished event to happen. (because it apparently never happens via animation, unless explicitly called)
				-- now, this gets always called, just ignoring it for letter
				--logger:error("EventAnimChestFinished - called for a letter, this should not happen")
			else
			
				local finalOwner = self:getFinalOwner()
				if finalOwner ~= nil then
					local awardComponent = inst:findComponent(game.gameplay.item.GameAwardItemToCharacterComponent)

					if awardComponent ~= nil then
						local charSelComponent = finalOwner:findComponent(trinebase.gameplay.player.TrineCharacterSelectionComponent)
						if charSelComponent ~= nil then	
							-- Skill chests go by the entity name, while secret chests go by the name of the item they award
							if (string.find(name, "skillchest", 1, true) == nil) then
								name = awardComponent:getItemNameToGive()
							end
							awardComponent:giveItem(charSelComponent:getCharacterID())
						else
							logger:error("gameplay.CharacterEventState.Event:onEventAnimChestFinishedSynced - Failed to locate TrineCharacterSelectionComponent from the opening instance")
						end
					else
						logger:error("gameplay.CharacterEventState.Event:onEventAnimChestFinishedSynced - Couldnt locate GameAwardItemToCharacterComponent from the opened chest")
					end
				
					-- Should ask for first local player's controller here if trying to use self's 
					-- controller doesn't work. Self may be non-local player.
					-- Defaults
					local controllerType = "pad";
					if FB_PLATFORM_TYPE == "FB_CONSOLE" then
						controllerType = "pad";
					else
						controllerType = "kb_mouse";
						local ic = getInputComponent(self);
						if ic ~= nil then
							if ic:hasControllerOfType(input.controller.ControllerTypeJoystick) then
								controllerType = "pad";
							end
						end
					end
					
					state:runLuaString("gameplay.util.foundSecretTreasureChest(\""..name.."\", \""..controllerType.."\")");
				else
					logger:error("gameplay.CharacterEventState.Event:onEventAnimChestFinishedSynced -  Failed to get final owner")
				end
			end
		else
			logger:error("Did not find the treasure chest instance with given last used item UH.")
		end
	else
		logger:error("No last used item UH.")
	end
end

-------------------------------------------------------------------------------------------------

function Event:EventAnimChestEntered()
	if shouldIgnoreChestReward() then
		return;
	end

	-- This is here because anim event validtor keeps spamming about this
	-- TODO: Maybe this is really needed, maybe not? Impl is still missing as animations expects that this event is handled
end

-------------------------------------------------------------------------------------------------

function Event:UnderWaterOnEnter()
	--common.CommonUtils.getTrophyDetectionManager():enteredWater()
end

function Event:UnderWaterOnExit()
	--common.CommonUtils.getTrophyDetectionManager():exitedWater()
end

-------------------------------------------------------------------------------------------------
