
menuWindow:clearMenu()

do
	menuWindow:setTitle("")
	menuWindow:setMenuGrid("VisualSettingsMenuGridWidget");
	
	-- Brightness
	menuWindow:createSlider("BrightnessSlider", "menu.mainmenu.visualsettingsmenu.sliderBrightness", "MenuSlider", 0.3, 2.5)
	if platformModule:isPlatformTypePC() then
		menuWindow:createLabel("BrightnessLabel",   "menu.mainmenu.visualsettingsmenu.infoNoBrightness", "MenuDescriptionTextLabelWidget")
	end
	
	menuWindow:createDropDownMenu("Resolution", "menu.mainmenu.visualsettingsmenu.buttonResolution", "ResolutionSettingsMenuDropDownWidget", {"1920x1080"})
	
	
	local windowedModeOptions =
	{
		"menu.mainmenu.visualsettingsmenu.buttonWindowModeWindowed",
		--"menu.mainmenu.visualsettingsmenu.buttonWindowModeBorderlessWindow",
		"menu.mainmenu.visualsettingsmenu.buttonWindowModeMaximizedWindow",
		"menu.mainmenu.visualsettingsmenu.buttonWindowModeFullscreen"
	}
	menuWindow:createDropDownMenu("WindowedMode", "menu.mainmenu.visualsettingsmenu.buttonWindowMode", "SettingsMenuDropDownWidget", windowedModeOptions)
	
	local visualSettingsOptions =
	{
		"menu.mainmenu.visualsettingsmenu.valueVisualQualityVeryHigh",
		"menu.mainmenu.visualsettingsmenu.valueVisualQualityHigh",
		"menu.mainmenu.visualsettingsmenu.valueVisualQualityMedium",
		"menu.mainmenu.visualsettingsmenu.valueVisualQualityLow",
		"menu.mainmenu.visualsettingsmenu.valueVisualQualityVeryLow"
	}
	
	menuWindow:createDropDownMenu("VisualQuality", "menu.mainmenu.visualsettingsmenu.buttonVisualQuality", "SettingsMenuDropDownWidget", visualSettingsOptions)
	
	local onOffOptions =
	{
		"menu.mainmenu.visualsettingsmenu.valueOn",
		"menu.mainmenu.visualsettingsmenu.valueOff"
	}
	
	menuWindow:createDropDownMenu("VerticalSync", "menu.mainmenu.visualsettingsmenu.buttonVerticalSync", "SettingsMenuDropDownWidget", onOffOptions)
	
	local aaOptions =
	{
		"menu.mainmenu.visualsettingsmenu.valueOff",
		"menu.mainmenu.visualsettingsmenu.valueAntiAliasingMedium",
		"menu.mainmenu.visualsettingsmenu.valueAntiAliasingHigh",
		"menu.mainmenu.visualsettingsmenu.valueAntiAliasingVeryHigh",
		"menu.mainmenu.visualsettingsmenu.valueAntiAliasingExtreme"
	}
	menuWindow:createDropDownMenu("AntiAliasing", "menu.mainmenu.visualsettingsmenu.buttonAntiAliasing", "SettingsMenuDropDownWidget", aaOptions)
	
	---- UI Visibility (aka. HUD Size)
	--menuWindow:createRadioButton("UIVisibility", "menu.mainmenu.visualsettingsmenu.buttonUiVisibility", "TrineRadioButtonWidget", { "menu.mainmenu.visualsettingsmenu.valueOff", "menu.mainmenu.visualsettingsmenu.valueSmall", "menu.mainmenu.visualsettingsmenu.valueMedium", "menu.mainmenu.visualsettingsmenu.valueLarge" })
	
	---- Tooltips
	--menuWindow:createRadioButton("EnableTooltips", "menu.mainmenu.visualsettingsmenu.buttonTooltipsEnabled", "TrineRadioButtonWidget", onOffOptions)
	
	menuWindow:createButton("AdvancedVisualSettings", "menu.mainmenu.visualsettingsmenu.buttonAdvancedVisualSettings", "TrineButtonWidget", "AdvancedVisualSettingsMenuWindow")
end

-- data/script/fui/menu/visual_settings_window.lua
