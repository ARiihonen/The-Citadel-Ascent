
menuWindow:clearMenu()

do
	menuWindow:setTitle("menu.mainmenu.networksettingsmenu.headerNetworkSettings")

	-- Network Bandwith
	-- TODO: dropdown menu
	menuWindow:createRadioButton("VibrationEnabled", "menu.mainmenu.networksettingsmenu.buttonNetworkBandwith", "TrineRadioButtonWidget", { "menu.mainmenu.networksettingsmenu.valueNetworkKbit512" })
	-- Auto Adjust Network Rate
	menuWindow:createRadioButton("AutoAdjust", "menu.mainmenu.networksettingsmenu.buttonAutoAdjustRate", "TrineRadioButtonWidget", { "menu.mainmenu.networksettingsmenu.valueAutoAdjustRateOn", "menu.mainmenu.networksettingsmenu.valueAutoAdjustRateOff" })
	
	-- Reset to default button
	menuWindow:createButton("ResetToDefault",    "menu.mainmenu.networksettingsmenu.buttonReset", "ImageButtonWidget", "")
end

-- data/script/fui/menu/network_settings_window.lua
