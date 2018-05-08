local moduleName = "gameplay.item.ItemPickableState"
module(moduleName, package.seeall)
gameplay.stateCollectionUtils.createReloadSupport(moduleName)


local states = {}
states.Spawn = ""
states.Idle = ""
states.Picked = ""

gameplay.stateCollectionUtils.createStateCollection(moduleName, states)

stateCollection:setDefaultState("Spawn");

-------------------------------------------------------------------------------------------------

function playOnPickEffect(self)
	local audioComponent = self:getFinalOwner():findComponent(audio.AudioComponent)
	if audioComponent then
		local iPC = self:getFinalOwner():findComponent(gameplay.item.ItemPickableComponent)
		if iPC then
			-- Note: using separate audio is legacy, but I don't care to reconf effect with audio.
			audioComponent:postEventLua(iPC:getOnPickAudioEvent())
			
			local effectType = iPC:getOnPickEffectEntityType()
			if effectType ~= UH_NONE then
				local dec = nil
				local fowner = self:getFinalOwner()
				for i = 0, fowner:getNumComponents() - 1 do
					local c = fowner:getComponent(i)
					if c:isInherited(gameplay.effect.DoEffectComponent.getStaticObjectClass())
						and not c:isInherited(gameplay.effect.DoEffectOnContactComponent.getStaticObjectClass())
					then
						dec = c
						break
					end
				end
				
				if dec then
					dec:spawnWithEffectEntityUH(effectType)
				else
					logger:error("gameplay.item.ItemPickableState - playOnPickEffect: Pick effect is specified but there's no DoEffectComponent")
				end
			end
		end
	end
end

-------------------------------------------------------------------------------------------------

function Spawn:onEnter()
	self:changeState("Idle");
end

function Spawn:onExit()
	--nop
end

-------------------------------------------------------------------------------------------------

function Idle:onEnter()
	--nop
end

function Idle:onExit()
	--nop
end

function Idle:EventAreaOnEnter()
	self:changeState("Picked");
end

-------------------------------------------------------------------------------------------------

function Picked:onEnter()
	-- nop
end

function Picked:onExit()
	--nop
end

function Picked:showCollectionMessage(localeKey)
	-- NOTE: This now works, but not in use for Trine 3
	--[[
	if sceneInstanceManager then
		local upgradeManager = common.CommonUtils.getTrineUpgradeManager()
		if upgradeManager then
			local messagesComp = upgradeManager:findComponent(trinebase.gui.TrineColMessagesGUIComponent)
			if messagesComp
			then
				local pickerInstance = gameplay.item.ItemUtils.getPickerInstance(self)
				if pickerInstance ~= nil and pickerInstance:getNetSyncer():hasLocalMaster() then
					local sendToAll = false
					messagesComp:addMessage(localeKey, sendToAll)
				end
			else
				logger:error("ItemPickableState:Picked:showCollectionMessage - TrineColMessagesGUIComponent is nil.")
			end
		else
			logger:error("ItemPickableState:Picked:showCollectionMessage - upgradeManager in nil.")
		end
	else
		logger:error("ItemPickableState.lua:Picked:showCollectionMessage - Invalid sceneInstanceManager.")
	end
	]]--
end

-------------------------------------------------------------------------------------------------
