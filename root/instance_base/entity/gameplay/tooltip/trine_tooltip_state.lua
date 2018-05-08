local moduleName = "gameplay.TrineTooltipState"
module(moduleName, package.seeall)
gameplay.stateCollectionUtils.createReloadSupport(moduleName)

local states = {}
states.Idle = ""
states.Show = ""

gameplay.stateCollectionUtils.createStateCollection(moduleName, states)

stateCollection:setDefaultState("Idle")

local thisModule = _M

declareReload(thisModule, [[trineTooltipStateShowingTooltip]])
declareReload(thisModule, [[trineTooltipStateInTooltipArea]])
declareReload(thisModule, [[trineTooltipStateJumpDone]])
declareReload(thisModule, [[trineTooltipStateChangeTimer]])
declareReload(thisModule, [[trineTooltipStateChangeTimerUpdated]])
declareReload(thisModule, [[trineTooltipStateChangeTimerNewStage]])
declareReload(thisModule, [[wiiUTooltips]])
declareReload(thisModule, [[activePlayerIndex]])

-- globals
trineTooltipStateShowingTooltip = false
trineTooltipStateInTooltipArea = false
trineTooltipStateJumpDone = false
trineTooltipStateChangeTimer = 0
trineTooltipStateChangeTimerUpdated = false
trineTooltipStateChangeTimerNewStage = 0
activePlayerIndex = 0

-------------------------------------------------------------------------------------------------

function uninitScene()
trineTooltipStateShowingTooltip = false
trineTooltipStateInTooltipArea = false
trineTooltipStateJumpDone = false
end

-------------------------------------------------------------------------------------------------

function disableTooltip(self)
	self:getFinalOwner():findComponent(trinebase.gameplay.TrineTooltipsComponent):setEnabled(false)
end

function bothConditionsDone(self)
	local ttc = self:getFinalOwner():findComponent(trinebase.gameplay.TrineTooltipsComponent)
	if ttc then
		if ttc:getCondition1Done() and ttc:getCondition2Done() then
			return true
		else
			return false
		end
	else
		logger:error("trine_tooltip_state.lua: TrineTooltipsComponent not found")
	end
	return false
end
	
function getAnyThiefOnRope()
	local sce = common.CommonUtils.getScene()
	if sce == nil then
		logger:error("trineTooltipState:startShowingTooltip - Scene is nil.")
		return
	end
	local characterManager = common.CommonUtils.getCharacterSelectionManager()
	local playerCharacters = { }
	if characterManager then
		playerCharacters = {
			characterManager:getCharacterInstanceForPlayer(0), 
			characterManager:getCharacterInstanceForPlayer(1), 
			characterManager:getCharacterInstanceForPlayer(2)
		}
	end

	-- Set tooltip
	local maxStage = 0
	for key, playerInstance in pairs(playerCharacters) do
		local characterComponent = playerInstance:findComponent(trinebase.gameplay.TrineCharacterComponent)
		if characterComponent then
			local trs = characterComponent:findStateComponentByCollection("ThiefRopeState")
			if trs and trs:getCurrentState() == "OnRope" then
				return true
			end
		end
	end
	
	return false
end

	
function startShowingTooltip(self)
	local ttc = self:getFinalOwner():findComponent(trinebase.gameplay.TrineTooltipsComponent)
	if ttc then
		if ttc:getEnabled() then
			ttc:setStage(0)
			local tooltipType = ttc:getTooltipType()
			
			if tooltipType == trinebase.gameplay.TooltipJump then
				if trineTooltipStateJumpDone then
					ttc:setEnabled(false)
					return
				end
			elseif tooltipType == trinebase.gameplay.TooltipWeaponChange then
				
				-- does somebody have hammer already
				local sce = common.CommonUtils.getScene()
				if sce == nil then
					logger:error("trineTooltipState:startShowingTooltip - Scene is nil.")
					return
				end
				local characterManager = common.CommonUtils.getCharacterSelectionManager()
				local playerCharacters = { }
				if characterManager then
					playerCharacters = {
						characterManager:getCharacterInstanceForPlayer(0), 
						characterManager:getCharacterInstanceForPlayer(1), 
						characterManager:getCharacterInstanceForPlayer(2)
					}
				end
				for key, playerInstance in pairs(playerCharacters) do
					local wsc = playerInstance:findComponent(trinebase.gameplay.weapon.TrineWeaponSelectionComponent)
					if wsc then
						if wsc:getSelectedWeaponName() == "Hammer" then
							ttc:setEnabled(false)
							return
						end
					end
				end
				
			elseif tooltipType == trinebase.gameplay.TooltipLevitate then
				-- Find wizards
				local sce = common.CommonUtils.getScene()
				if sce == nil then
					logger:error("trineTooltipState:startShowingTooltip - Scene is nil.")
					return
				end
				local characterManager = common.CommonUtils.getCharacterSelectionManager()
				local playerCharacters = { }
				if characterManager then
					playerCharacters = {
						characterManager:getCharacterInstanceForPlayer(0), 
						characterManager:getCharacterInstanceForPlayer(1), 
						characterManager:getCharacterInstanceForPlayer(2)
					}
				end

				-- Set tooltip
				local maxStage = 0
				for key, playerInstance in pairs(playerCharacters) do
					local characterComponent = playerInstance:findComponent(trinebase.gameplay.TrineCharacterComponent)
					if characterComponent then
						local fs = characterComponent:findStateComponentByCollection("WizardFloatingState")
						if fs then
							if (fs:getCurrentState() == "Idle") then
								-- Nop
							elseif (fs:getCurrentState() == "PointingOnFloatable") and maxStage < 1 then
								maxStage = 1
							else
								maxStage = 1
								break
							end
						end
					end
				end
				ttc:setStage(maxStage)
			elseif tooltipType == trinebase.gameplay.TooltipGrapplingHook then
				if getAnyThiefOnRope() then
					ttc:setStage(1)
				end
			elseif tooltipType == trinebase.gameplay.TooltipRopeWindUp then
				if not(getAnyThiefOnRope()) then
					return
				end
			elseif tooltipType == trinebase.gameplay.TooltipDoubleJump then
				if getAnyThiefOnRope() then
					return
				end
				ttc:setStage(1)
			end
			self:changeState("Show")
		end
	else
		logger:error("trine_tooltip_state.lua: TrineTooltipsComponent not found")
	end
end
	
function showCorrectTooltip(self)
	local ttc = self:getFinalOwner():findComponent(trinebase.gameplay.TrineTooltipsComponent)
	if ttc then
	
		--WIIU
		if FB_PLATFORM == "FB_WIIU" or inputModule:getEditorTouchscreenEmulationEnabled() then
			generateWiiUTooltips(ttc)
			return
		end
		
		local tooltipType = ttc:getTooltipType()
		local localeKey = ""
		local button1 = gameplay.tooltips.ButtonNone
		local button2 = gameplay.tooltips.ButtonNone
		
		if tooltipType == trinebase.gameplay.TooltipCustom then		
			localeKey = ttc:getTextLocaleForCustomTooltip()
			button1 = ttc:getCustomTooltipButton1()
			button2 = ttc:getCustomTooltipButton2()
		elseif tooltipType == trinebase.gameplay.TooltipMove then
			localeKey = "hud.tutorial_tooltips.move"
			button1 = gameplay.tooltips.ButtonLAnalogStick
			button2 = gameplay.tooltips.ButtonNone
		elseif tooltipType == trinebase.gameplay.TooltipJump then 
			localeKey = "hud.tutorial_tooltips.jump"
			button1 = gameplay.tooltips.ButtonA
			button2 = gameplay.tooltips.ButtonNone
		elseif tooltipType == trinebase.gameplay.TooltipJumpLonger then
			localeKey = "hud.tutorial_tooltips.jump_longer"
			button1 = gameplay.tooltips.ButtonA
			button2 = gameplay.tooltips.ButtonNone
		elseif tooltipType == trinebase.gameplay.TooltipLevitate then
			if ttc:getStage() == 0 then
				localeKey = "hud.tutorial_tooltips.move_cursor_to_object"
				button1 = gameplay.tooltips.ButtonRAnalogStick
				button2 = gameplay.tooltips.ButtonNone
			elseif ttc:getStage() == 1 then
				localeKey = "hud.tutorial_tooltips.levitate"
				button1 = gameplay.tooltips.ButtonLTrigger
				button2 = gameplay.tooltips.ButtonRAnalogStick
			elseif ttc:getStage() == 2 then
			    localeKey = "hud.tutorial_tooltips.cantlevitate"
			    button1 = gameplay.tooltips.ButtonNone
			    button2 = gameplay.tooltips.ButtonNone
			else
			    logger:error("trine_tooltip_state: invalid stage.")
			end
		elseif tooltipType == trinebase.gameplay.TooltipConjureBox then 
			localeKey = "hud.tutorial_tooltips.draw_square"
			button1 = gameplay.tooltips.ButtonLTrigger
			button2 = gameplay.tooltips.ButtonRAnalogStick
		elseif tooltipType == trinebase.gameplay.TooltipSword then 
			localeKey = "hud.tutorial_tooltips.sword"
			button1 = gameplay.tooltips.ButtonX
			button2 = gameplay.tooltips.ButtonNone
		elseif tooltipType == trinebase.gameplay.TooltipShield then 
			localeKey = "hud.tutorial_tooltips.shield"
			button1 = gameplay.tooltips.ButtonRAnalogStick
			button2 = gameplay.tooltips.ButtonNone
		elseif tooltipType == trinebase.gameplay.TooltipBow then 
			localeKey = "hud.tutorial_tooltips.bow"
			button1 = gameplay.tooltips.ButtonRAnalogStick
			button2 = gameplay.tooltips.ButtonNone
		elseif tooltipType == trinebase.gameplay.TooltipGrapplingHook then 
			if ttc:getStage() == 0 then
				localeKey = "hud.tutorial_tooltips.grappling_hook"
				button2 = gameplay.tooltips.ButtonRTrigger
			else
				localeKey = "hud.tutorial_tooltips.swing_and_release"
				button1 = gameplay.tooltips.ButtonLAnalogStick
				button2 = gameplay.tooltips.ButtonA
			end
		elseif tooltipType == trinebase.gameplay.TooltipBounce then 
			localeKey = "hud.tutorial_tooltips.bounce"
			button1 = gameplay.tooltips.ButtonA
			button2 = gameplay.tooltips.ButtonNone
		elseif tooltipType == trinebase.gameplay.TooltipDoubleJump then 
			localeKey = "hud.tutorial_tooltips.double_jump"
			button1 = gameplay.tooltips.ButtonA
			button2 = gameplay.tooltips.ButtonNone
			ttc:showTooltipWithCustomPicture(localeKey, button1, "data/gui/hud/tutorial/wall_jump.png")
			return
		elseif tooltipType == trinebase.gameplay.TooltipRopeWindUp then 
			localeKey = "hud.tutorial_tooltips.rope_windup"
			button1 = gameplay.tooltips.ButtonLAnalogStick
			button2 = gameplay.tooltips.ButtonNone
		elseif tooltipType == trinebase.gameplay.TooltipCharacterChange then
			localeKey = "hud.tutorial_tooltips.character_change"
			button1 = gameplay.tooltips.ButtonLB
			if FB_GCLUSTER_ENABLED == "FB_TRUE" then
				button2 = gameplay.tooltips.ButtonNone
			else
				button2 = gameplay.tooltips.ButtonRB
			end
		elseif tooltipType == trinebase.gameplay.TooltipWeaponChange then
			localeKey = "hud.tutorial_tooltips.weapon_change"
			button1 = gameplay.tooltips.ButtonY
			button2 = gameplay.tooltips.ButtonNone
		elseif tooltipType == trinebase.gameplay.TooltipLevitationRotate then
			localeKey = "hud.tutorial_tooltips.rotate_object"
			button1 = gameplay.tooltips.ButtonLAnalogStick
			button2 = gameplay.tooltips.ButtonNone
		elseif tooltipType == trinebase.gameplay.TooltipIceraft then			
			localeKey = "hud.tutorial_tooltips.ice_bow"
			ttc:showTooltipWithCustomPicture(localeKey, button1, "data/gui/hud/tutorial/iceraft.png")
			return
		end
		
		if tooltipType == trinebase.gameplay.TooltipCustom and ttc:getCustomTooltipHideControllerPic() then	
			ttc:showTooltipWithCustomPicture(localeKey, button1, "")
		else
			ttc:showTooltip(localeKey, button1, button2)
		end
	else
		logger:error("trine_tooltip_state.lua: TrineTooltipsComponent not found")
	end
end

function hideTooltip(self)
	local ttc = self:getFinalOwner():findComponent(trinebase.gameplay.TrineTooltipsComponent)
	if ttc then
		ttc:hideTooltip()
	else
		logger:error("trine_tooltip_state.lua: TrineTooltipsComponent not found")
	end
end

function setCurrentTooltipToThis(self)
	local sceneInstanceManager = scene:getSceneInstanceManager()
	if sceneInstanceManager then
		local upgradeManager = common.CommonUtils.getTrineUpgradeManager()
		if upgradeManager then
			upgradeManager:setCurrentTooltipUH( StateContextHandle(scene:getUnifiedHandle(), self:getFinalOwner():getUnifiedHandle()) )
			trineTooltipStateInTooltipArea = true
		else
			logger:error("trine_tooltip_state.lua: upgradeManager not found")
		end
	else
		logger:error("trine_tooltip_state.lua: sceneInstanceManager is nil")
	end
end

function setCurrentTooltipToNone()
	local sceneInstanceManager = scene:getSceneInstanceManager()
	if sceneInstanceManager then
		local upgradeManager = common.CommonUtils.getTrineUpgradeManager()
		if upgradeManager then
			upgradeManager:setCurrentTooltipUH( StateContextHandle(UH_NONE, UH_NONE) )
			trineTooltipStateInTooltipArea = false
		else
			logger:error("trine_tooltip_state.lua: upgradeManager not found")
		end
	else
		logger:error("trine_tooltip_state.lua: sceneInstanceManager is nil")
	end
end

-------------------------------------------------------------------------------------------------

function Idle:onEnter()
	-- nop
end

function Idle:onExit()
	-- nop
end

function Idle:setPlayerOneActive()
	activePlayerIndex = 1
end

function Idle:setPlayerTwoActive()
	activePlayerIndex = 2
end

function Idle:setPlayerThreeActive()
	activePlayerIndex = 3
end

function Idle:onAreaEnter()
	setCurrentTooltipToThis(self)
	startShowingTooltip(self)
end

function Idle:onAreaExit()
	setCurrentTooltipToNone()
end

function Idle:setEnabled()
	local ttc = self:getFinalOwner():findComponent(trinebase.gameplay.TrineTooltipsComponent)
	if ttc then
		ttc:setStage(0)
		ttc:setCondition1Done(false)
		ttc:setCondition2Done(true)
	else
		logger:error("trine_tooltip_state.lua: TrineTooltipsComponent not found")
	end
end

function Idle:forceStartShowingTooltip()
	local ttc = self:getFinalOwner():findComponent(trinebase.gameplay.TrineTooltipsComponent)
	if ttc then
		if ttc:getEnabled() then
			if ttc:getTooltipType() == trinebase.gameplay.TooltipDoubleJump then
				ttc:setStage(1)
			else
				ttc:setStage(0)
			end
			self:changeState("Show")
		end
	else
		logger:error("trine_tooltip_state.lua: TrineTooltipsComponent not found")
	end
end

function Idle:forceHideTooltip()
	-- nop
end

-------------------------------------------------------------------------------------------------

function Show:onEnter()
	gameplay.TrineTooltipState.trineTooltipStateShowingTooltip = true
	showCorrectTooltip(self)
end

function Show:onExit()
	gameplay.TrineTooltipState.trineTooltipStateShowingTooltip = false
	hideTooltip(self)
end

function Show:onAreaEnter()
	setCurrentTooltipToThis(self)
end

function Show:onAreaExit()
	local ttc = self:getFinalOwner():findComponent(trinebase.gameplay.TrineTooltipsComponent)
	if ttc then
		if ttc:getTooltipType() == trinebase.gameplay.TooltipCharacterChange then
			-- don't allow hiding character change tooltip, so it dont flash when player changing character (exiting area) (character change tooltip is hidden with delete instance trigger in level)
			return
		end
	end
	setCurrentTooltipToNone()
	self:changeState("Idle")
end

function Show:setDisabled()
	setCurrentTooltipToNone()
	self:changeState("Idle")
end

function Show:conditionDone()
	if bothConditionsDone(self) then
		disableTooltip(self)
	end
end

function Show:stageChange()
	showCorrectTooltip(self)
end

function Show:forceStartShowingTooltip()
	-- nop
end

function Show:forceHideTooltip()
	self:changeState("Idle")
end

-------------------------------------------------------------------------------------------------

--WIIU STUFF

wiiUTooltips = {
	["trinebase.gameplay.TooltipMove"] = {
									"hud.tutorial_tooltips.move",
									{gameplay.tooltips.ButtonLAnalogStick, gameplay.tooltips.ButtonNone}, -- DRC
									{gameplay.tooltips.ButtonLAnalogStick, gameplay.tooltips.ButtonNone}, -- Remote + Classic
									{gameplay.tooltips.ButtonLAnalogStick, gameplay.tooltips.ButtonNone},  -- Remote + Nunchuk
									{gameplay.tooltips.ButtonLAnalogStick, gameplay.tooltips.ButtonNone},  -- GamepadPro
									{gameplay.tooltips.WiiUDPad, gameplay.tooltips.ButtonNone}  -- Remote
									},
	["trinebase.gameplay.TooltipJump"] = {
									"hud.tutorial_tooltips.jump",
									{gameplay.tooltips.ButtonA, gameplay.tooltips.ButtonLTrigger}, -- DRC
									{gameplay.tooltips.ButtonA, gameplay.tooltips.ButtonLTrigger}, -- Remote + Classic
									{gameplay.tooltips.WiiURemoteButtonZ, gameplay.tooltips.ButtonNone}, -- Remote + Nunchuk
									{gameplay.tooltips.ButtonA, gameplay.tooltips.ButtonLTrigger},  -- GamepadPro
									{gameplay.tooltips.WiiURemote2, gameplay.tooltips.ButtonNone}  -- Remote
									},
	["trinebase.gameplay.TooltipJumpLonger"] = {
									"hud.tutorial_tooltips.jump_longer",
									{gameplay.tooltips.ButtonA, gameplay.tooltips.ButtonLTrigger}, -- DRC
									{gameplay.tooltips.ButtonA, gameplay.tooltips.ButtonLTrigger}, -- Remote + Classic
									{gameplay.tooltips.WiiURemoteButtonZ, gameplay.tooltips.ButtonNone}, -- Remote + Nunchuk
									{gameplay.tooltips.ButtonA, gameplay.tooltips.ButtonLTrigger},  -- GamepadPro
									{gameplay.tooltips.WiiURemote2, gameplay.tooltips.ButtonNone}  -- Remote
									},
  	["trinebase.gameplay.TooltipConjureBox"] = {
									"hud.tutorial_tooltips.draw_square",
									{gameplay.tooltips.ButtonRTrigger, gameplay.tooltips.ButtonRAnalogStick}, -- DRC
									{gameplay.tooltips.ButtonRTrigger, gameplay.tooltips.ButtonRAnalogStick}, -- Remote + Classic
									{gameplay.tooltips.ButtonB, gameplay.tooltips.ButtonNone}, -- Remote + Nunchuk
									{gameplay.tooltips.ButtonRTrigger, gameplay.tooltips.ButtonRAnalogStick},  -- GamepadPro
									{gameplay.tooltips.WiiUSensor, gameplay.tooltips.ButtonB}  -- Remote
									},
	["trinebase.gameplay.TooltipSword"] = {
									"hud.tutorial_tooltips.sword",
									{gameplay.tooltips.ButtonRTrigger, gameplay.tooltips.ButtonNone}, -- DRC
									{gameplay.tooltips.ButtonRTrigger, gameplay.tooltips.ButtonNone}, -- Remote + Classic
									{gameplay.tooltips.ButtonA, gameplay.tooltips.ButtonNone}, -- Remote + Nunchuk
									{gameplay.tooltips.ButtonRTrigger, gameplay.tooltips.ButtonNone},  -- GamepadPro
									{gameplay.tooltips.WiiURemote1, gameplay.tooltips.ButtonNone}  -- Remote
									},
	["trinebase.gameplay.TooltipShield"] = {
									"hud.tutorial_tooltips.shield",
									{gameplay.tooltips.ButtonRAnalogStick, gameplay.tooltips.ButtonNone}, -- DRC
									{gameplay.tooltips.ButtonRAnalogStick, gameplay.tooltips.ButtonNone}, -- Remote + Classic
									{gameplay.tooltips.ButtonB, gameplay.tooltips.ButtonNone}, -- Remote + Nunchuk
									{gameplay.tooltips.ButtonRAnalogStick, gameplay.tooltips.ButtonNone},  -- GamepadPro
									{gameplay.tooltips.WiiUSensor, gameplay.tooltips.ButtonB}  -- Remote
									},
	["trinebase.gameplay.TooltipBow"] = {
									"hud.tutorial_tooltips.bow",
									{gameplay.tooltips.ButtonRAnalogStick, gameplay.tooltips.ButtonNone}, -- DRC
									{gameplay.tooltips.ButtonRAnalogStick, gameplay.tooltips.ButtonNone}, -- Remote + Classic
									{gameplay.tooltips.ButtonB, gameplay.tooltips.ButtonNone}, -- Remote + Nunchuk
									{gameplay.tooltips.ButtonRAnalogStick, gameplay.tooltips.ButtonNone},  -- GamepadPro
									{gameplay.tooltips.WiiUSensor, gameplay.tooltips.ButtonB}  -- Remote
									},
	["trinebase.gameplay.TooltipBounce"] = {
									"hud.tutorial_tooltips.bounce",
									{gameplay.tooltips.ButtonA, gameplay.tooltips.ButtonLTrigger}, -- DRC
									{gameplay.tooltips.ButtonA, gameplay.tooltips.ButtonLTrigger}, -- Remote + Classic
									{gameplay.tooltips.WiiURemoteButtonZ, gameplay.tooltips.ButtonNone}, -- Remote + Nunchuk
									{gameplay.tooltips.ButtonA, gameplay.tooltips.ButtonLTrigger},  -- GamepadPro
									{gameplay.tooltips.WiiURemote2, gameplay.tooltips.ButtonNone}  -- Remote
									},
	["trinebase.gameplay.TooltipRopeWindUp"] = {
									"hud.tutorial_tooltips.rope_windup",
									{gameplay.tooltips.ButtonLAnalogStick, gameplay.tooltips.ButtonNone}, -- DRC
									{gameplay.tooltips.ButtonLAnalogStick, gameplay.tooltips.ButtonNone}, -- Remote + Classic
									{gameplay.tooltips.ButtonLAnalogStick, gameplay.tooltips.ButtonNone}, -- Remote + Nunchuk
									{gameplay.tooltips.ButtonLAnalogStick, gameplay.tooltips.ButtonNone},  -- GamepadPro
									{gameplay.tooltips.WiiUDPad, gameplay.tooltips.ButtonNone}  -- Remote
									},
	["trinebase.gameplay.TooltipCharacterChange"] = {
									"hud.tutorial_tooltips.character_change",
									{gameplay.tooltips.ButtonRB, gameplay.tooltips.ButtonNone}, -- DRC
									{gameplay.tooltips.ButtonRB, gameplay.tooltips.ButtonNone}, -- Remote + Classic
									{gameplay.tooltips.WiiUDPad, gameplay.tooltips.ButtonNone}, -- Remote + Nunchuk
									{gameplay.tooltips.ButtonRB, gameplay.tooltips.ButtonNone},  -- GamepadPro
									{gameplay.tooltips.ButtonNone, gameplay.tooltips.ButtonNone}  -- Remote
									},
	["trinebase.gameplay.TooltipWeaponChange"] = {
									"hud.tutorial_tooltips.weapon_change",
									{gameplay.tooltips.ButtonY, gameplay.tooltips.ButtonNone}, -- DRC
									{gameplay.tooltips.ButtonY, gameplay.tooltips.ButtonNone}, -- Remote + Classic
									{gameplay.tooltips.WiiUDPad, gameplay.tooltips.ButtonNone}, -- Remote + Nunchuk
									{gameplay.tooltips.ButtonY, gameplay.tooltips.ButtonNone},  -- GamepadPro
									{gameplay.tooltips.WiiUDPadDown, gameplay.tooltips.ButtonNone}  -- Remote
									},
	["trinebase.gameplay.TooltipLevitationRotate"] = {
									"hud.tutorial_tooltips.rotate_object",
									{gameplay.tooltips.ButtonLAnalogStick, gameplay.tooltips.ButtonNone}, -- DRC
									{gameplay.tooltips.ButtonLAnalogStick, gameplay.tooltips.ButtonNone}, -- Remote + Classic
									{gameplay.tooltips.ButtonLAnalogStick, gameplay.tooltips.ButtonNone}, -- Remote + Nunchuk
									{gameplay.tooltips.ButtonLAnalogStick, gameplay.tooltips.ButtonNone},  -- GamepadPro
									{gameplay.tooltips.WiiUDPad, gameplay.tooltips.ButtonNone}  -- Remote
									},									
}

function getWiiUController(playerIndex)
	local controller = gui.hud.HintMessage.getWiiUControllerType(playerIndex)
	local ret
	if controller == 5 then
		ret = input.controller.ControllerSubTypeWiiUDRC
	elseif controller == 6 then
		ret = input.controller.ControllerSubTypeWiiURemoteClassic
	elseif controller == 7 then
		ret = input.controller.ControllerSubTypeWiiURemoteNunchuk
	elseif controller == 8 then
		ret = input.controller.ControllerSubTypeWiiUProController
	elseif controller == 9 then
		ret = input.controller.ControllerSubTypeWiiURemote
	end
	return ret
end

function generateWiiUTooltips(ttc)
	local tooltipType = ttc:getTooltipType()
	local localeKey = ""
	local button1 = gameplay.tooltips.ButtonNone
	local button2 = gameplay.tooltips.ButtonNone
	
	local controller = getWiiUController(activePlayerIndex)
	--local tilted = gui.hud.HintMessage.isRemoteTilted(controller, activePlayerIndex)
	
	-- Filter out custom, "not ordinary" tooltips first
	if tooltipType == trinebase.gameplay.TooltipCustom then		
		localeKey = ttc:getTextLocaleForCustomTooltip()
		button1 = ttc:getCustomTooltipButton1()
		button2 = ttc:getCustomTooltipButton2()
	elseif tooltipType == trinebase.gameplay.TooltipLevitate then
		if ttc:getStage() == 0 then
			localeKey = "hud.tutorial_tooltips.move_cursor_to_object"
			if controller == input.controller.ControllerSubTypeWiiUDRC then
				button1 = gameplay.tooltips.ButtonRAnalogStick
				button2 = gameplay.tooltips.ButtonNone
			elseif controller == input.controller.ControllerSubTypeWiiURemoteClassic then
				button1 = gameplay.tooltips.ButtonRAnalogStick
				button2 = gameplay.tooltips.ButtonNone
			elseif controller == input.controller.ControllerSubTypeWiiURemoteNunchuk then
				button1 = gameplay.tooltips.WiiUSensor
				button2 = gameplay.tooltips.ButtonNone
			elseif controller == input.controller.ControllerSubTypeWiiUProController then
				button1 = gameplay.tooltips.ButtonRAnalogStick
				button2 = gameplay.tooltips.ButtonNone
			elseif controller == input.controller.ControllerSubTypeWiiURemote then
				button1 = gameplay.tooltips.WiiUSensor
				button2 = gameplay.tooltips.ButtonNone
			end
		elseif ttc:getStage() == 1 then
			localeKey = "hud.tutorial_tooltips.levitate"
			if controller == input.controller.ControllerSubTypeWiiUDRC then
				button1 = gameplay.tooltips.ButtonRTrigger
				button2 = gameplay.tooltips.ButtonRAnalogStick
			elseif controller == input.controller.ControllerSubTypeWiiURemoteClassic then
				button1 = gameplay.tooltips.ButtonRTrigger
				button2 = gameplay.tooltips.ButtonRAnalogStick
			elseif controller == input.controller.ControllerSubTypeWiiURemoteNunchuk then
				button1 = gameplay.tooltips.WiiUSensor
				button2 = gameplay.tooltips.ButtonB
			elseif controller == input.controller.ControllerSubTypeWiiUProController then
				button1 = gameplay.tooltips.ButtonRTrigger
				button2 = gameplay.tooltips.ButtonRAnalogStick
			elseif controller == input.controller.ControllerSubTypeWiiURemote then
				button1 = gameplay.tooltips.WiiUSensor
				button2 = gameplay.tooltips.ButtonB
			end
		elseif ttc:getStage() == 2 then
			localeKey = "hud.tutorial_tooltips.cantlevitate"
			if controller == input.controller.ControllerSubTypeWiiUDRC then
				button1 = gameplay.tooltips.ButtonNone
				button2 = gameplay.tooltips.ButtonNone
			elseif controller == input.controller.ControllerSubTypeWiiURemoteClassic then
				button1 = gameplay.tooltips.ButtonNone
				button2 = gameplay.tooltips.ButtonNone
			elseif controller == input.controller.ControllerSubTypeWiiURemoteNunchuk then
				button1 = gameplay.tooltips.ButtonNone
				button2 = gameplay.tooltips.ButtonNone
			elseif controller == input.controller.ControllerSubTypeWiiUProController then
				button1 = gameplay.tooltips.ButtonNone
				button2 = gameplay.tooltips.ButtonNone
			elseif controller == input.controller.ControllerSubTypeWiiURemote then
				button1 = gameplay.tooltips.ButtonNone
				button2 = gameplay.tooltips.ButtonNone
			end
		else
			logger:error("trine_tooltip_state: invalid stage.")
		end
	elseif tooltipType == trinebase.gameplay.TooltipGrapplingHook then 
		if ttc:getStage() == 0 then
			localeKey = "hud.tutorial_tooltips.grappling_hook"
			if controller == input.controller.ControllerSubTypeWiiUDRC then
				button1 = gameplay.tooltips.ButtonRTrigger
				button2 = gameplay.tooltips.ButtonNone
			elseif controller == input.controller.ControllerSubTypeWiiURemoteClassic then
				button1 = gameplay.tooltips.ButtonRTrigger
				button2 = gameplay.tooltips.ButtonNone
			elseif controller == input.controller.ControllerSubTypeWiiURemoteNunchuk then
				button1 = gameplay.tooltips.ButtonA
				button2 = gameplay.tooltips.ButtonNone
			elseif controller == input.controller.ControllerSubTypeWiiUProController then
				button1 = gameplay.tooltips.ButtonRTrigger
				button2 = gameplay.tooltips.ButtonNone
			elseif controller == input.controller.ControllerSubTypeWiiURemote then
				button1 = gameplay.tooltips.WiiURemote1
				button2 = gameplay.tooltips.ButtonNone
			end
		else
			localeKey = "hud.tutorial_tooltips.swing_and_release"
			if controller == input.controller.ControllerSubTypeWiiUDRC then
				button1 = gameplay.tooltips.ButtonA
				button2 = gameplay.tooltips.ButtonLAnalogStick
			elseif controller == input.controller.ControllerSubTypeWiiURemoteClassic then
				button1 = gameplay.tooltips.ButtonA
				button2 = gameplay.tooltips.ButtonLAnalogStick
			elseif controller == input.controller.ControllerSubTypeWiiURemoteNunchuk then
				button1 = gameplay.tooltips.ButtonLAnalogStick
				button2 = gameplay.tooltips.WiiURemoteButtonZ
			elseif controller == input.controller.ControllerSubTypeWiiUProController then
				button1 = gameplay.tooltips.ButtonA
				button2 = gameplay.tooltips.ButtonLAnalogStick
			elseif controller == input.controller.ControllerSubTypeWiiURemote then
				button1 = gameplay.tooltips.WiiUDPad
				button2 = gameplay.tooltips.WiiURemote2
			end
		end
	elseif tooltipType == trinebase.gameplay.TooltipDoubleJump then 
		localeKey = "hud.tutorial_tooltips.double_jump"
		if controller == input.controller.ControllerSubTypeWiiUDRC then
			button1 = gameplay.tooltips.ButtonA
		elseif controller == input.controller.ControllerSubTypeWiiURemoteClassic then
			button1 = gameplay.tooltips.ButtonA
		elseif controller == input.controller.ControllerSubTypeWiiURemoteNunchuk then
			button1 = gameplay.tooltips.WiiURemoteButtonZ
		elseif controller == input.controller.ControllerSubTypeWiiUProController then
			button1 = gameplay.tooltips.ButtonA
		elseif controller == input.controller.ControllerSubTypeWiiURemote then
			button1 = gameplay.tooltips.WiiURemote2
		end
		ttc:showTooltipWithCustomPicture(localeKey, button1, "data/gui/hud/tutorial/wall_jump.png")
		return
	elseif tooltipType == trinebase.gameplay.TooltipIceraft then			
		localeKey = "hud.tutorial_tooltips.ice_bow"
		ttc:showTooltipWithCustomPicture(localeKey, button1, "data/gui/hud/tutorial/iceraft.png")
		return
	else
		-- Generate WiiU tooltips from wiiUTooltips table
		if wiiUTooltips[tostring(tooltipType)] ~= nil then
			localeKey = wiiUTooltips[tostring(tooltipType)][1]
			if controller == input.controller.ControllerSubTypeWiiUDRC then
				button1 = wiiUTooltips[tostring(tooltipType)][2][1]
				button2 = wiiUTooltips[tostring(tooltipType)][2][2]
			elseif controller == input.controller.ControllerSubTypeWiiURemoteClassic then
				button1 = wiiUTooltips[tostring(tooltipType)][3][1]
				button2 = wiiUTooltips[tostring(tooltipType)][3][2]
			elseif controller == input.controller.ControllerSubTypeWiiURemoteNunchuk then
				button1 = wiiUTooltips[tostring(tooltipType)][4][1]
				button2 = wiiUTooltips[tostring(tooltipType)][4][2]
			elseif controller == input.controller.ControllerSubTypeWiiUProController then
				button1 = wiiUTooltips[tostring(tooltipType)][5][1]
				button2 = wiiUTooltips[tostring(tooltipType)][5][2]
			elseif controller == input.controller.ControllerSubTypeWiiURemote then
				button1 = wiiUTooltips[tostring(tooltipType)][6][1]
				button2 = wiiUTooltips[tostring(tooltipType)][6][2]
			end
		else
			logger:error("trine_tooltip_state: generateWiiUTooltips: can't find tooltipType.")
		end
	end
	
	if tooltipType == trinebase.gameplay.TooltipCustom and ttc:getCustomTooltipHideControllerPic() then
		ttc:showTooltipWithCustomPicture(localeKey, button1, "")
	else
		ttc:showTooltip(localeKey, button1, button2)
	end	
end