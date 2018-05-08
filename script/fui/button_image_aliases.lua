module(..., package.seeall)
debug.ReloadScripts.allowReload(..., false)

local thisModule = _M
declareReload(thisModule, [[buttonImageAliases]])

-- used to fetch menu (pad)button images
-- this gives out the platform and configuration specific button image resource for a button of given type
-- currently supported buttons: 
--
-- "accept"  (having the meaning of enter / confirm / advance / ok ...) 
-- "cancel"  (having the meaning of cancel / back / return / ...) 
-- "decrease"  (having the meanning of decreasing a value, where the value (basically an adjustable bar) is left to right directional)
-- "increase"  (having the meanning of increasing a value, where the value (basically an adjustable bar) is left to right directional)
-- "move_left"  (having the meaning of navigating left with d-pad left / arrow left / and maybe even analog stick left? / ...) 
-- "move_right" (having the meaning of navigating left with d-pad right / arrow right / and maybe even analog stick right? / ...) 
-- "arrow_left"  (having the meaning of specifically d-pad (arrow on pc) left - but NOT analog stick) 
-- "arrow_right" (having the meaning of specifically d-pad (arrow on pc) right - but NOT analog stick) 
-- "decrease_and_increase"  decrease and increase buttons both in one
-- "move_left_and_right"  move_left and move_right buttons both in one
-- "arrow_left_and_right"  arrow_left and arrow_right buttons both in one
-- "rename"  the button that works as rename  (most likely X on xbox360, square on ps3, blue bullet/X for pc)
-- "sort"  the button that works as sort  (most likely Y on xbox360, triangle on ps3, blue bullet/X for pc)
-- "select_profile"  the button that works as profile select  (most likely X on xbox360, square on ps3, blue bullet/X for pc)
-- "delete"  the button that works as delete  (most likely Y on xbox360, triangle on ps3, yellow bullet/Y for pc)
-- "settings"  the button that works as settings  (most likely Y on xbox360, triangle on ps3, yellow bullet/Y for pc)
-- "next" the button moves focus of something to the next possible one (most likely R1 on ps3 and RB on xbox)
-- "previous" the button moves focus of something to the previous possible one (most likely L1 on ps3 and LB on xbox)
-- "reset" the button that works as reset (most likely X on xbox360, square on ps3, blue bullet/X for pc)
-- "info"  the button that works as delete  (most likely Y on xbox360, triangle on ps3, yellow bullet/Y for pc)
-- "refresh"  the button that works as refresh  (most likely X on xbox360, square on ps3, blue bullet/X for pc)
-- "start"  having the meaning of start (most likely Start on PS3, Start on XBOX360, Enter/Space on PC?) 
-- "purchase"  (having the meaning of purchase (most likely X on xbox360, square on ps3, blue bullet/X for pc)

-- NOTE: you are NOT supposed to use the following normally (instead, use the most appropriate of "accept", "cancel", "settings", etc. instead)
-- if you are specifically referring to a specific hard-coded physical button, rather than a button/shortcut with some specific function (such as 
-- navigating forward or backward in some menu), then you may use these (which is RARELY true).
-- When you are using these, namely "button1" or "button2", in almost any menu, you have most likely screwed up!
-- NOTICE: In absolutely no circumstance are you allowed to use "button1" and "button2" to navigate in menus!!!

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! YOU ARE NOT SUPPOSED TO USE THESE UNLESS YOU KNOW WHAT YOU ARE DOING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! YOU ARE NOT SUPPOSED TO USE THESE UNLESS YOU KNOW WHAT YOU ARE DOING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! YOU ARE NOT SUPPOSED TO USE THESE UNLESS YOU KNOW WHAT YOU ARE DOING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 

-- "button1"  (having the meaning of one of the following specifically: A on xbox360, X on ps3, green bullet/A for pc)
-- "button2"  (having the meaning of one of the following specifically: B on xbox360, O on ps3, red bullet/B for pc)
-- "button3"  (having the meaning of one of the following specifically: X on xbox360, square on ps3, blue bullet/X for pc)
-- "button4"  (having the meaning of one of the following specifically: Y on xbox360, triangle on ps3, yellow bullet/Y for pc)

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! YOU ARE NOT SUPPOSED TO USE THESE UNLESS YOU KNOW WHAT YOU ARE DOING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! YOU ARE NOT SUPPOSED TO USE THESE UNLESS YOU KNOW WHAT YOU ARE DOING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! YOU ARE NOT SUPPOSED TO USE THESE UNLESS YOU KNOW WHAT YOU ARE DOING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

-- "shoulder_l1" (L1 on PS3, LB on XBOX360)
-- "shoulder_r1" (R1 on PS3, RB on XBOX360)
--
-- Note, nothing guarantees that all of these actually have images - or that they have binds!

-- Don't assume anything about these values. these aliases exist only to reduce unnecessary memory usage of images in case the buttons
-- on specific platform actually happend to be the same. Don't assume that they are the same for all future platforms, etc!
buttonImageAliases = 
{
	Common = 
	{
		-- stuff...
		-- Note: Must invert based on accept/cancel buttons here
		accept = FB_PS3_INVERT_ACCEPT_CANCEL and "button2" or "button1",
		cancel = FB_PS3_INVERT_ACCEPT_CANCEL and "button1" or "button2",
		decrease = "arrow_left",
		increase = "arrow_right",
		move_left = "arrow_left",
		move_right = "arrow_right",
		
		decrease_and_increase = "arrow_left_and_right",
		move_left_and_right = "arrow_left_and_right",
		rename = "button3",
		sort = "button4",
		settings = "button4",
		-- Upgrade menu
		info = "button4",
		choose = FB_PS3_INVERT_ACCEPT_CANCEL and "button2" or "button1",
		resetSkill = FB_PS3_INVERT_ACCEPT_CANCEL and "button2" or "button1",
		purchaseSkill = FB_PS3_INVERT_ACCEPT_CANCEL and "button2" or "button1",
		purchase = "button3",
		-- stuff...
		refresh = "button3",
		purchase = "button3",
		previous = "shoulder_l1",
		next = "shoulder_r1",
		start = "start",
		select = "select",
		accept_online = FB_PS3_INVERT_ACCEPT_CANCEL and "button2_online" or "button1_online",
		accept_offline = FB_PS3_INVERT_ACCEPT_CANCEL and "button2_offline" or "button1_offline",
		accept_unknown = FB_PS3_INVERT_ACCEPT_CANCEL and "button2_unknown" or "button1_unknown",
		
		menu_left = "arrow_left",
		menu_right = "arrow_right",
		menu_accept = FB_PS3_INVERT_ACCEPT_CANCEL and "button2" or "button1",
		menu_close = FB_PS3_INVERT_ACCEPT_CANCEL and "button1" or "button2",
		menu_back = FB_PS3_INVERT_ACCEPT_CANCEL and "button1" or "button2",

		previousHint = "button3",
		nextHint = "button1"
	}
	,	
	FB_PS3 = 
	{
		delete = "button4",
		reset = "button3",
		select_profile = "button3"
	}
	,
	FB_XBOX360 = 
	{
		delete = "button4",
		reset = "button3",
		select_profile = "button3"
	}
	,
	FB_WINDOWS = 
	{
		delete = "button4",
		reset = "button3",
		select_profile = "select"
	}
	,
	FB_OSX = 
	{
		delete = "button4",
		reset = "button3",
		select_profile = "button3"
	}
	,
	FB_LINUX = 
	{
		delete = "button4",
		reset = "button3",
		select_profile = "select"
	}
	,
	FB_WIIU = 
	{
		delete = "select",
		reset = "select",
		resetSkill = "start",
		select_profile = "start"
	}
	,	
	FB_PS4 = 
	{
		delete = "button4",
		reset = "button3",
		select_profile = "button3",
		select = "button3",
		button10 = "touchPadButton"
	}
}

function getPlatformSubFolder()
	assert_string(FB_PLATFORM_SUBDIRECTORY)

	-- hack for  WiiU
	if platformModule:isPlatformPS4() then
		return "ps4"
	end

	-- hack for  WiiU
	if platformModule:isPlatformWiiU() then
		return "wiiu"
	end
	
	-- hack for mac/linux
	if (platformModule:isPlatformTypePC()) then
		return "windows"
	end

	return FB_PLATFORM_SUBDIRECTORY
end

function getPlatformButtonPath()
	return "data/gui/menu/common/buttons/" .. getPlatformSubFolder()
end

function getPlatformButtonAliasMappingTable()
	local resultTable = {}
	if buttonImageAliases["Common"] ~= nil then
		for key, value in pairs(buttonImageAliases["Common"]) do
			resultTable[key] = value;
		end
	end
	if buttonImageAliases[FB_PLATFORM] ~= nil then
		for key, value in pairs(buttonImageAliases[FB_PLATFORM]) do
			resultTable[key] = value;
		end
	end
	return resultTable;
end






-----------------------------------------------------------
-- Button image initialization
-----------------------------------------------------------


-- Initialize the tooltips module stuff from here
function initButtonImages()
	registerControllers()
end

function registerControllers()
	if not buttonBindImageModule then
		logger:error("gui.initTooltips.registerControllers - buttonBindImageModule is NIL. Cannot initialize button images.")
		return
	end

	if platformModule:isPlatformTypePC() then
		registerPCControllers()
		registerPS4Controllers()
		registerSteamControllers()
	end
	if platformModule:isPlatformPS4() then
		registerPS4Controllers()
	end
	if platformModule:isPlatformWiiU() then
		registerWiiUControllers()
	end
end

function registerPCControllers()
	local controllerType = input.controller.ControllerSubTypeKeyboardAndMouse
	buttonBindImageModule:registerController(controllerType, "data/gui/hud/tutorial/keyboard/keyboard_controller.png")
	
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "MouseButtonLeft", "data/gui/hud/tutorial/mouse/mb_left.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "MouseButtonRight", "data/gui/hud/tutorial/mouse/mb_right.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "MouseWheel", "data/gui/hud/tutorial/mouse/mb_middle.png")
	-- buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "MouseWheelUp", "data/gui/hud/tutorial/mouse/mb_middle.png")
	-- buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "MouseWheelDown", "data/gui/hud/tutorial/mouse/mb_middle.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "MouseButtonLeftWithMouseButtonRight", "data/gui/hud/tutorial/mouse/mb_left_and_right.png")
	
	-- Greyscale
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "MouseButtonLeft", "data/gui/hud/tutorial/mouse/mb_left_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "MouseButtonRight", "data/gui/hud/tutorial/mouse/mb_right_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "MouseWheel", "data/gui/hud/tutorial/mouse/mb_middle_grey.png")
	-- buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "MouseWheelUp", "data/gui/hud/tutorial/mouse/mb_middle_grey.png")
	-- buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "MouseWheelDown", "data/gui/hud/tutorial/mouse/mb_middle_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "MouseButtonLeftWithMouseButtonRight", "data/gui/hud/tutorial/mouse/mb_left_and_right_grey.png")

	registerGamepadController()
end

function registerGamepadController()
	local controllerType = input.controller.ControllerSubTypeXBoxPad

	-- Bubble buttons
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyXIButtonA", "data/gui/hud/tutorial/xbox360/360_button_a.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyXIButtonB", "data/gui/hud/tutorial/xbox360/360_button_b.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyXIButtonX", "data/gui/hud/tutorial/xbox360/360_button_x.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyXIButtonY", "data/gui/hud/tutorial/xbox360/360_button_y.png")
	
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyXIAxisTriggerL", "data/gui/hud/tutorial/xbox360/360_button_lt.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyXIAxisTriggerR", "data/gui/hud/tutorial/xbox360/360_button_rt.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyXIButtonShoulderL", "data/gui/hud/tutorial/xbox360/360_button_lb.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyXIButtonShoulderR", "data/gui/hud/tutorial/xbox360/360_button_rb.png")
	
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyXIAxisLX", "data/gui/hud/tutorial/xbox360/360_joy_l_left_right.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyXIAxisLY", "data/gui/hud/tutorial/xbox360/360_joy_l_up_down.png")
	
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyXIAxisRX", "data/gui/hud/tutorial/xbox360/360_joy_r_left_right.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyXIAxisRY", "data/gui/hud/tutorial/xbox360/360_joy_r_up_down.png")
	
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyXISpecialThumbstickL", "data/gui/hud/tutorial/xbox360/360_joy_l_4way.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyXISpecialThumbstickR", "data/gui/hud/tutorial/xbox360/360_joy_r_4way.png")
	
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyXIButtonThumbL", "data/gui/hud/tutorial/xbox360/360_joy_l_push.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyXIButtonThumbR", "data/gui/hud/tutorial/xbox360/360_joy_r_push.png")
	
	-- Greyscale
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyXIButtonA", "data/gui/hud/tutorial/xbox360/360_button_a_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyXIButtonB", "data/gui/hud/tutorial/xbox360/360_button_b_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyXIButtonX", "data/gui/hud/tutorial/xbox360/360_button_x_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyXIButtonY", "data/gui/hud/tutorial/xbox360/360_button_y_grey.png")
	
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyXIAxisTriggerL", "data/gui/hud/tutorial/xbox360/360_button_lt_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyXIAxisTriggerR", "data/gui/hud/tutorial/xbox360/360_button_rt_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyXIButtonShoulderL", "data/gui/hud/tutorial/xbox360/360_button_lb_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyXIButtonShoulderR", "data/gui/hud/tutorial/xbox360/360_button_rb_grey.png")
	
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyXIAxisLX", "data/gui/hud/tutorial/xbox360/360_joy_l_left_right_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyXIAxisLY", "data/gui/hud/tutorial/xbox360/360_joy_l_up_down_grey.png")
	
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyXIAxisRX", "data/gui/hud/tutorial/xbox360/360_joy_r_left_right_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyXIAxisRY", "data/gui/hud/tutorial/xbox360/360_joy_r_up_down_grey.png")
	
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyXISpecialThumbstickL", "data/gui/hud/tutorial/xbox360/360_joy_l_4way_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyXISpecialThumbstickR", "data/gui/hud/tutorial/xbox360/360_joy_r_4way_grey.png")
	
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyXIButtonThumbL", "data/gui/hud/tutorial/xbox360/360_joy_l_push_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyXIButtonThumbR", "data/gui/hud/tutorial/xbox360/360_joy_r_push_grey.png")
end

function registerPS4Controllers()
	local controllerType = input.controller.ControllerSubTypePS4Pad

	-- Bubble buttons
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyPS4ButtonCross", "data/gui/hud/tutorial/ps4/ps4_button_cross.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyPS4ButtonCircle", "data/gui/hud/tutorial/ps4/ps4_button_circle.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyPS4ButtonSquare", "data/gui/hud/tutorial/ps4/ps4_button_square.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyPS4ButtonTriangle", "data/gui/hud/tutorial/ps4/ps4_button_triangle.png")
	
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyPS4ButtonTriggerL", "data/gui/hud/tutorial/ps4/ps4_button_l2.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyPS4ButtonTriggerR", "data/gui/hud/tutorial/ps4/ps4_button_r2.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyPS4ButtonShoulderL", "data/gui/hud/tutorial/ps4/ps4_button_l1.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyPS4ButtonShoulderR", "data/gui/hud/tutorial/ps4/ps4_button_r1.png")
	
	-- There is no high resolution version of these images.
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyPS4ButtonTouchpadClick", "data/gui/menu/common/buttons/ps4/touchpad_click.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyPS4ButtonShare", "data/gui/menu/common/buttons/ps4/select_enabled.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyPS4ButtonOptions", "data/gui/menu/common/buttons/ps4/start_enabled.png")
	
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyPS4AxisLX", "data/gui/hud/tutorial/ps4/ps4_joy_l_left_right.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyPS4AxisLY", "data/gui/hud/tutorial/ps4/ps4_joy_l_up_down.png")
	
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyPS4AxisRX", "data/gui/hud/tutorial/ps4/ps4_joy_r_left_right.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyPS4AxisRY", "data/gui/hud/tutorial/ps4/ps4_joy_r_up_down.png")
	
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyPS4SpecialThumbstickL", "data/gui/hud/tutorial/ps4/ps4_joy_l_4way.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyPS4SpecialThumbstickR", "data/gui/hud/tutorial/ps4/ps4_joy_r_4way.png")
	
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyPS4ButtonThumbL", "data/gui/hud/tutorial/ps4/ps4_joy_l_push.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoyPS4ButtonThumbR", "data/gui/hud/tutorial/ps4/ps4_joy_r_push.png")
	
	-- Greyscale
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyPS4ButtonCross", "data/gui/hud/tutorial/ps4/ps4_button_cross_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyPS4ButtonCircle", "data/gui/hud/tutorial/ps4/ps4_button_circle_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyPS4ButtonSquare", "data/gui/hud/tutorial/ps4/ps4_button_square_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyPS4ButtonTriangle", "data/gui/hud/tutorial/ps4/ps4_button_triangle_grey.png")
	
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyPS4ButtonTriggerL", "data/gui/hud/tutorial/ps4/ps4_button_l2_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyPS4ButtonTriggerR", "data/gui/hud/tutorial/ps4/ps4_button_r2_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyPS4ButtonShoulderL", "data/gui/hud/tutorial/ps4/ps4_button_l1_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyPS4ButtonShoulderR", "data/gui/hud/tutorial/ps4/ps4_button_r1_grey.png")
	
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyPS4AxisLX", "data/gui/hud/tutorial/ps4/ps4_joy_l_left_right_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyPS4AxisLY", "data/gui/hud/tutorial/ps4/ps4_joy_l_up_down_grey.png")
	
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyPS4AxisRX", "data/gui/hud/tutorial/ps4/ps4_joy_r_left_right_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyPS4AxisRY", "data/gui/hud/tutorial/ps4/ps4_joy_r_up_down_grey.png")
	
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyPS4SpecialThumbstickL", "data/gui/hud/tutorial/ps4/ps4_joy_l_4way_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyPS4SpecialThumbstickR", "data/gui/hud/tutorial/ps4/ps4_joy_r_4way_grey.png")
	
	
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyPS4ButtonThumbL", "data/gui/hud/tutorial/ps4/ps4_joy_l_push_grey.png")
	buttonBindImageModule:registerBubbleButtonGreyscaleImageLUA(controllerType, "JoyPS4ButtonThumbR", "data/gui/hud/tutorial/ps4/ps4_joy_r_push_grey.png")
end

function registerSteamControllers()
	local controllerType = input.controller.ControllerSubTypeSteamController

	-- Bubble buttons
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamButtonA", "data/gui/hud/tutorial/steam/steam_button_a.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamButtonB", "data/gui/hud/tutorial/steam/steam_button_b.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamButtonX", "data/gui/hud/tutorial/steam/steam_button_x.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamButtonY", "data/gui/hud/tutorial/steam/steam_button_y.png")
	
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamTouchpadLPadUp", "data/gui/hud/tutorial/steam/steam_button_dpad_up.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamTouchpadLPadDown", "data/gui/hud/tutorial/steam/steam_button_dpad_down.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamTouchpadLPadLeft", "data/gui/hud/tutorial/steam/steam_button_dpad_left.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamTouchpadLPadRight", "data/gui/hud/tutorial/steam/steam_button_dpad_right.png")
	
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamButtonBack", "data/gui/hud/tutorial/steam/steam_button_back.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamButtonStart", "data/gui/hud/tutorial/steam/steam_button_start.png")
	
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamButtonBackL", "data/gui/hud/tutorial/steam/steam_button_back_left.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamButtonBackR", "data/gui/hud/tutorial/steam/steam_button_back_right.png")
	
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamAxisTriggerL", "data/gui/hud/tutorial/steam/steam_button_trigger_left.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamAxisTriggerR", "data/gui/hud/tutorial/steam/steam_button_trigger_right.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamButtonBumberL", "data/gui/hud/tutorial/steam/steam_button_bumber_left.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamButtonBumberR", "data/gui/hud/tutorial/steam/steam_button_bumber_right.png")
	
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamAxisThumbX", "data/gui/hud/tutorial/steam/steam_joy_l_left_right.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamAxisThumbY", "data/gui/hud/tutorial/steam/steam_joy_l_up_down.png")
	
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamAxisRX", "data/gui/hud/tutorial/steam/steam_joy_r_left_right.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamAxisRY", "data/gui/hud/tutorial/steam/steam_joy_r_up_down.png")
	
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamSpecialRightPad", "data/gui/hud/tutorial/steam/steam_joy_r_4way.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamSpecialThumbstick", "data/gui/hud/tutorial/steam/steam_joy_l_4way.png")
	
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamButtonThumbstickPress", "data/gui/hud/tutorial/steam/steam_joy_l_push.png")
	buttonBindImageModule:registerBubbleButtonImageLUA(controllerType, "JoySteamButtonPadClickR", "data/gui/hud/tutorial/steam/steam_joy_r_push.png")
end

function registerWiiUControllers()
	registerDRC()
	registerRemote()
	registerRemoteAndNunchuck()
	registerClassic()
	registerProController()	
end

function registerDRC()
	local controllerType = input.controller.ControllerSubTypeWiiUDRC
	buttonBindImageModule:registerController(controllerType, "data/gui/hud/tutorial/wiiu/drcphysical/controller.png")
	-- Thumbsticks
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUDRCButtonThumbL", "data/gui/hud/tutorial/wiiu/drcphysical/joy_left.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUDRCButtonThumbR", "data/gui/hud/tutorial/wiiu/drcphysical/joy_right.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUDRCAxisLX", "data/gui/hud/tutorial/wiiu/drcphysical/joy_left.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUDRCAxisLY", "data/gui/hud/tutorial/wiiu/drcphysical/joy_left.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUDRCAxisRX", "data/gui/hud/tutorial/wiiu/drcphysical/joy_right.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUDRCAxisRY", "data/gui/hud/tutorial/wiiu/drcphysical/joy_right.png")
	-- dpad
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUDRCButtonPadUp", "data/gui/hud/tutorial/wiiu/drcphysical/dpad.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUDRCButtonPadDown", "data/gui/hud/tutorial/wiiu/drcphysical/dpad_down.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUDRCButtonPadLeft", "data/gui/hud/tutorial/wiiu/drcphysical/dpad.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUDRCButtonPadRight", "data/gui/hud/tutorial/wiiu/drcphysical/dpad_right.png")
	-- A, B, X, Y
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUDRCButtonA", "data/gui/hud/tutorial/wiiu/drcphysical/butt_a.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUDRCButtonB", "data/gui/hud/tutorial/wiiu/drcphysical/butt_b.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUDRCButtonX", "data/gui/hud/tutorial/wiiu/drcphysical/butt_x.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUDRCButtonY", "data/gui/hud/tutorial/wiiu/drcphysical/butt_y.png")
	-- start and select
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUDRCButtonPlus", "data/gui/hud/tutorial/wiiu/drcphysical/butt_start.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUDRCButtonMinus", "data/gui/hud/tutorial/wiiu/drcphysical/butt_select.png")
	-- Triggers and bumpers
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUDRCButtonTriggerL", "data/gui/hud/tutorial/wiiu/drcphysical/shoulder_lback.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUDRCButtonTriggerR", "data/gui/hud/tutorial/wiiu/drcphysical/shoulder_rback.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUDRCButtonShoulderL", "data/gui/hud/tutorial/wiiu/drcphysical/shoulder_ltop.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUDRCButtonShoulderR", "data/gui/hud/tutorial/wiiu/drcphysical/shoulder_rtop.png")
end

function registerRemote()
	registerRemoteImpl(input.controller.ControllerSubTypeWiiURemote)
	registerRemoteImpl(input.controller.ControllerSubTypeWiiURemoteMotionPlus)
end

function registerRemoteImpl(controllerType)
	buttonBindImageModule:registerController(controllerType, "data/gui/hud/tutorial/wiiu/remotetilted/controller.png")
	-- dpad
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadUp", "data/gui/hud/tutorial/wiiu/remotetilted/dpad_up.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadDown", "data/gui/hud/tutorial/wiiu/remotetilted/dpad_down.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadLeft", "data/gui/hud/tutorial/wiiu/remotetilted/dpad_left.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadRight", "data/gui/hud/tutorial/wiiu/remotetilted/dpad_right.png")
	-- A, B, 1, 2
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonA", "data/gui/hud/tutorial/wiiu/remotetilted/butt_a.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonB", "data/gui/hud/tutorial/wiiu/remotetilted/butt_b.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonOne", "data/gui/hud/tutorial/wiiu/remotetilted/butt_1.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonTwo", "data/gui/hud/tutorial/wiiu/remotetilted/butt_2.png")
	-- +, -
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPlus", "data/gui/hud/tutorial/wiiu/remotetilted/butt_start.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonMinus", "data/gui/hud/tutorial/wiiu/remotetilted/butt_select.png")	
end

function registerRemoteAndNunchuck()
	registerRemoteAndNunchuckImpl(input.controller.ControllerSubTypeWiiURemoteNunchuk)
	registerRemoteAndNunchuckImpl(input.controller.ControllerSubTypeWiiURemoteMotionPlusNunchuk)
end

function registerRemoteAndNunchuckImpl(controllerType)
	buttonBindImageModule:registerController(controllerType, "data/gui/hud/tutorial/wiiu/remotenunchuk/controller.png")
	-- dpad
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadUp", "data/gui/hud/tutorial/wiiu/remotenunchuk/mote_dpad.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadDown", "data/gui/hud/tutorial/wiiu/remotenunchuk/mote_dpad.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadLeft", "data/gui/hud/tutorial/wiiu/remotenunchuk/mote_dpad.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadRight", "data/gui/hud/tutorial/wiiu/remotenunchuk/mote_dpad.png")
	-- A, B, 1, 2
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonA", "data/gui/hud/tutorial/wiiu/remotenunchuk/mote_a.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonB", "data/gui/hud/tutorial/wiiu/remotenunchuk/mote_b.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonOne", "data/gui/hud/tutorial/wiiu/remotenunchuk/mote_1.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonTwo", "data/gui/hud/tutorial/wiiu/remotenunchuk/mote_2.png")
	-- +, -
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPlus", "data/gui/hud/tutorial/wiiu/remotenunchuk/mote_start.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonMinus", "data/gui/hud/tutorial/wiiu/remotenunchuk/mote_select.png")
	-- Nunchuck buttons
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonC", "data/gui/hud/tutorial/wiiu/remotenunchuk/nun_c.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonZ", "data/gui/hud/tutorial/wiiu/remotenunchuk/nun_z.png")
	-- Thumbstick
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteAxisNunchukX", "data/gui/hud/tutorial/wiiu/remotenunchuk/nun_joy.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteAxisNunchukY", "data/gui/hud/tutorial/wiiu/remotenunchuk/nun_joy.png")
end

function registerClassic()
	registerClassicImpl(input.controller.ControllerSubTypeWiiUClassicPad)
	registerClassicImpl(input.controller.ControllerSubTypeWiiURemoteClassic)	
	registerClassicImpl(input.controller.ControllerSubTypeWiiURemoteMotionPlusClassic)
	
	
end

function registerClassicImpl(controllerType)
	buttonBindImageModule:registerController(controllerType, "data/gui/hud/tutorial/wiiu/classicpadpro/controller.png")
	-- Thumbsticks
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUPadAxisLX", "data/gui/hud/tutorial/wiiu/classicpadpro/joy_left.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUPadAxisLY", "data/gui/hud/tutorial/wiiu/classicpadpro/joy_left.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUPadAxisRX", "data/gui/hud/tutorial/wiiu/classicpadpro/joy_right.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUPadAxisRY", "data/gui/hud/tutorial/wiiu/classicpadpro/joy_right.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteAxisPadLX", "data/gui/hud/tutorial/wiiu/classicpadpro/joy_left.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteAxisPadLY", "data/gui/hud/tutorial/wiiu/classicpadpro/joy_left.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteAxisPadRX", "data/gui/hud/tutorial/wiiu/classicpadpro/joy_right.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteAxisPadRY", "data/gui/hud/tutorial/wiiu/classicpadpro/joy_right.png")
	-- dpad
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadPadUp", "data/gui/hud/tutorial/wiiu/classicpadpro/dpad.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadPadDown", "data/gui/hud/tutorial/wiiu/classicpadpro/dpad.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadPadLeft", "data/gui/hud/tutorial/wiiu/classicpadpro/dpad.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadPadRight", "data/gui/hud/tutorial/wiiu/classicpadpro/dpad.png")
	-- A, B, X, Y
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadA", "data/gui/hud/tutorial/wiiu/classicpadpro/butt_a.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadB", "data/gui/hud/tutorial/wiiu/classicpadpro/butt_b.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadX", "data/gui/hud/tutorial/wiiu/classicpadpro/butt_x.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadY", "data/gui/hud/tutorial/wiiu/classicpadpro/butt_y.png")
	-- Triggers and bumpers
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadTriggerL", "data/gui/hud/tutorial/wiiu/classicpadpro/shoulder_lback.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadTriggerR", "data/gui/hud/tutorial/wiiu/classicpadpro/shoulder_rback.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadShoulderL", "data/gui/hud/tutorial/wiiu/classicpadpro/shoulder_ltop.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadShoulderR", "data/gui/hud/tutorial/wiiu/classicpadpro/shoulder_rtop.png")
	-- +, -
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadPlus", "data/gui/hud/tutorial/wiiu/classicpadpro/butt_start.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiURemoteButtonPadMinus", "data/gui/hud/tutorial/wiiu/classicpadpro/butt_select.png")
end

function registerProController()
	local controllerType = input.controller.ControllerSubTypeWiiUProController
	buttonBindImageModule:registerController(controllerType, "data/gui/hud/tutorial/wiiu/gamepadpro/controller.png")
	-- Thumbsticks
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUProCAxisLX", "data/gui/hud/tutorial/wiiu/gamepadpro/joy_left.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUProCAxisLY", "data/gui/hud/tutorial/wiiu/gamepadpro/joy_left.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUProCButtonThumbL", "data/gui/hud/tutorial/wiiu/gamepadpro/joy_left.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUProCAxisRX", "data/gui/hud/tutorial/wiiu/gamepadpro/joy_right.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUProCAxisRY", "data/gui/hud/tutorial/wiiu/gamepadpro/joy_right.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUProCButtonThumbR", "data/gui/hud/tutorial/wiiu/gamepadpro/joy_right.png")
	-- dpad
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUProCButtonPadUp", "data/gui/hud/tutorial/wiiu/gamepadpro/dpad.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUProCButtonPadDown", "data/gui/hud/tutorial/wiiu/gamepadpro/dpad_down.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUProCButtonPadLeft", "data/gui/hud/tutorial/wiiu/gamepadpro/dpad.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUProCButtonPadRigh", "data/gui/hud/tutorial/wiiu/gamepadpro/dpad_right.png")
	-- A, B, X, Y
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUProCButtonA", "data/gui/hud/tutorial/wiiu/gamepadpro/butt_a.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUProCButtonB", "data/gui/hud/tutorial/wiiu/gamepadpro/butt_b.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUProCButtonX", "data/gui/hud/tutorial/wiiu/gamepadpro/butt_x.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUProCButtonY", "data/gui/hud/tutorial/wiiu/gamepadpro/butt_y.png")
	-- Triggers and bumpers
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUProCButtonTriggerL", "data/gui/hud/tutorial/wiiu/gamepadpro/shoulder_lback.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUProCButtonTriggerR", "data/gui/hud/tutorial/wiiu/gamepadpro/shoulder_rback.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUProCButtonShoulderL", "data/gui/hud/tutorial/wiiu/gamepadpro/shoulder_ltop.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUProCButtonShoulderR", "data/gui/hud/tutorial/wiiu/gamepadpro/shoulder_rtop.png")
	-- +, -
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUProCButtonPlus", "data/gui/hud/tutorial/wiiu/gamepadpro/butt_start.png")
	buttonBindImageModule:registerButtonImageLUA(controllerType, "JoyWiiUProCButtonMinus", "data/gui/hud/tutorial/wiiu/gamepadpro/butt_select.png")
end

