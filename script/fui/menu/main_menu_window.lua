
menuWindow:clearMenu()

do
	menuWindow:setMenuGrid("MainMenuGrid");
	
	menuWindow:createButton("ContinueGame",  "menu.mainmenu.main.continueButton",                             "MainMenuImageButtonWidget", "")
	--menuWindow:createButton("StartGame",     "menu.mainmenu.singleplayerstartdifficultymenu.buttonStartGame", "MainMenuImageButtonWidget", "")
	menuWindow:createButton("Chapter",       "menu.pausemenu.buttonChooseLevelShort",                         "MainMenuImageButtonWidget", "")
	menuWindow:createButton("Settings",      "menu.mainmenu.helpandoptionsmenu.buttonSettings",               "MainMenuImageButtonWidget", "ShadwenSettingsMenuWidget")
	menuWindow:createButton("Difficulty",    "menu.mainmenu.difficultymenu.headerDifficulty",                 "MainMenuImageButtonWidget", "DifficultyMenuWidget")
	menuWindow:createButton("SaveSlot",      "menu.mainmenu.helpandoptionsmenu.buttonProfileSettings",        "MainMenuImageButtonWidget", "SaveSlotMenuWindow")
	
	if platformModule:isPlatformTypePC() then -- and not platformModule:getSteamEnabled() then
		menuWindow:createButton("Achievements",  "menu.mainmenu.mainmenu.buttonAchievements",                 "MainMenuImageButtonWidget", "AchievementMenuWindow")
	end
	
	menuWindow:createButton("Credits",       "menu.mainmenu.helpandoptionsmenu.buttonCredits",                "MainMenuImageButtonWidget", "CreditsMenuWidget")
	
	if platformModule:isPlatformTypePC() then
		menuWindow:createButton("ExitGame",      "menu.mainmenu.main.quitButton",                                 "MainMenuImageButtonWidget", "")
	end
end

-- data/script/fui/menu/main_menu_window.lua
