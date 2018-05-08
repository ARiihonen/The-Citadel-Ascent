
menuWindow:clearMenu()

do
	menuWindow:setTitle("menu.mainmenu.settingsmenu.headerSettings")

	menuWindow:createButton("Language", "menu.mainmenu.settingsmenu.buttonLanguageSettings",  "ImageButtonWidget", "LanguageSettingsMenuWindow")
	menuWindow:createButton("Visual",   "menu.mainmenu.settingsmenu.buttonVisualSettings",    "ImageButtonWidget", "VisualSettingsMenuWindow")
	menuWindow:createButton("Audio",    "menu.mainmenu.settingsmenu.buttonAudioVolume",       "ImageButtonWidget", "AudioSettingsMenuWindow")
	if FB_PLATFORM_TYPE == "FB_PC" then
		menuWindow:createButton("Controls", "menu.mainmenu.settingsmenu.buttonConfigureControls", "ImageButtonWidget", "ConfigureControlsMenuWindow")
	end
	menuWindow:createButton("Devices",  "menu.mainmenu.settingsmenu.buttonControlSettings",   "ImageButtonWidget", "InputDeviceSettingsMenuWindow")
	menuWindow:createButton("Network",  "menu.mainmenu.settingsmenu.buttonNetworkSettings",   "ImageButtonWidget", "NetworkSettingsMenuWindow")
end

-- data/script/fui/menu/settings_menu_window.lua
