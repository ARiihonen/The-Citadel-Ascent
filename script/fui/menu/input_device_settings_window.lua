
menuWindow:clearMenu()

do
	menuWindow:setTitle("menu.mainmenu.controlsettings.headerControlSettings")
	menuWindow:setMenuGrid("SettingsMenuGridWidget");
	
	-- Mouse & Gamepad Sensitivity
	if (platformModule:isPlatformTypePC()) then
		menuWindow:createSlider("MouseSensitivitySlider", "menu.mainmenu.controlsettings.sliderMouseSensitivity", "MenuSlider", 0.5, 2)
	end
	menuWindow:createSlider("GamepadSensitivitySlider", "menu.mainmenu.controlsettings.sliderGamepadSensitivity", "MenuSlider", 0.5, 3)
	
	---- Controller Vibration
	--menuWindow:createRadioButton("VibrationEnabled", "menu.mainmenu.controlsettings.buttonControllerVibration", "TrineRadioButtonWidget", { "menu.mainmenu.controlsettings.valueOn", "menu.mainmenu.controlsettings.valueOff" })
	
	---- Input Lag Reduction
	--if (platformModule:isPlatformTypePC()) then
	--	menuWindow:createRadioButton("InputLagReductionEnabled", "menu.mainmenu.controlsettings.buttonInputLagReduction", "TrineRadioButtonWidget", { "menu.mainmenu.controlsettings.valueOn", "menu.mainmenu.controlsettings.valueOff" })
	--end
	
	menuWindow:createRadioButton("InvertCameraY", "menu.mainmenu.controlsettings.buttonInvertCameraY", "TrineRadioButtonWidget", { "menu.mainmenu.controlsettings.valueOn", "menu.mainmenu.controlsettings.valueOff" })
end

-- data/script/fui/menu/input_device_settings_window.lua
