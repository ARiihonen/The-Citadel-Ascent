
menuWindow:clearMenu()

do
	menuWindow:setTitle("")
	menuWindow:setMenuGrid("VisualSettingsMenuGridWidget");
	
	local onOffOptions =
	{
		"menu.mainmenu.visualsettingsmenu.valueOn",
		"menu.mainmenu.visualsettingsmenu.valueOff"
	}
	
	if platformModule:isPlatformTypePC() then
		-- FPS Cap
		menuWindow:createRadioButton("EnableFPSCap", "menu.mainmenu.visualsettingsmenu.buttonFPSCapEnabled", "TrineRadioButtonWidget", onOffOptions)
		menuWindow:createInput("FPSCap",             "menu.mainmenu.visualsettingsmenu.inputFPSCap",         "MenuTextInputWidget")
	end
	
	local stereoOptions = 
	{
		"menu.mainmenu.visualsettingsmenu.valueStereo3dModeDisabled",
		"menu.mainmenu.visualsettingsmenu.valueStereo3dModeNvidia3dVision",
		"menu.mainmenu.visualsettingsmenu.valueStereo3dModeAmdHd3d",
		"menu.mainmenu.visualsettingsmenu.valueStereo3dModeSideBySide",
		"menu.mainmenu.visualsettingsmenu.valueStereo3dModeSideBySideSwapped",
		"menu.mainmenu.visualsettingsmenu.valueStereo3dModeTopBottom",
		"menu.mainmenu.visualsettingsmenu.valueStereo3dModeTopBottomSwapped",
		"menu.mainmenu.visualsettingsmenu.valueStereo3dModeSideBySideNoStretch",
		"menu.mainmenu.visualsettingsmenu.valueStereo3dModeSideBySideNoStretchSwapped",
		"menu.mainmenu.visualsettingsmenu.valueStereo3dModeTopBottomNoStretch",
		"menu.mainmenu.visualsettingsmenu.valueStereo3dModeTopBottomNoStretchSwapped",
		"menu.mainmenu.visualsettingsmenu.valueStereo3dModeLineInterlaced",
		"menu.mainmenu.visualsettingsmenu.valueStereo3dModeLineInterlacedSwapped",
		"menu.mainmenu.visualsettingsmenu.valueStereo3dModeDlpCheckerboard",
		"menu.mainmenu.visualsettingsmenu.valueStereo3dModeDlpCheckerboardSwapped"
	}
	
	-- Stereo settings
	if platformModule:isPlatformPS4() then
		--menuWindow:createDropDownMenu("Stereo3dMode", "menu.mainmenu.visualsettingsmenu.buttonStereo3dMode", "SettingsMenuDropDownWidget", stereoOptions)
		--menuWindow:createLabel("Stereo3DSettings",   "menu.mainmenu.visualsettingsmenu.subheaderStereo3D", "MenuTextLabelWidget")
		--menuWindow:createSlider("SeparationSlider",  "menu.mainmenu.visualsettingsmenu.sliderSeparation",  "MenuSlider", 0, 1)
		--menuWindow:createSlider("ConvergenceSlider", "menu.mainmenu.visualsettingsmenu.sliderConvergence", "MenuSlider", 0, 10)
		--menuWindow:createSlider("UIDepthSlider",     "menu.mainmenu.visualsettingsmenu.sliderUIDepth",     "MenuSlider", 0, 1)
	else
		menuWindow:createDropDownMenu("Stereo3dMode", "menu.mainmenu.visualsettingsmenu.buttonStereo3dMode", "StereoModeSettingsMenuDropDownWidget", stereoOptions)
		menuWindow:createLabel("Stereo3DSettings",   "menu.mainmenu.visualsettingsmenu.subheaderStereo3D", "MenuTextLabelWidget")
		menuWindow:createSlider("SeparationSlider",  "menu.mainmenu.visualsettingsmenu.sliderSeparation",  "MenuSlider", 0, 0.1)
		menuWindow:createSlider("ConvergenceSlider", "menu.mainmenu.visualsettingsmenu.sliderConvergence", "MenuSlider", 0, 10)
		menuWindow:createSlider("UIDepthSlider",     "menu.mainmenu.visualsettingsmenu.sliderUIDepth",     "MenuSlider", 0, 1)
	end
end

-- data/script/fui/menu/advanced_visual_settings_window.lua
