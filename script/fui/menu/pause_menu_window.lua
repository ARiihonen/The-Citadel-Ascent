
menuWindow:clearMenu()

do
	menuWindow:setMenuGrid("PauseMenuGrid");
	menuWindow:setTitle("")
	menuWindow:createButton("Resume",           "menu.pausemenu.buttonResume",                        "CenteredImageButtonWidget", "Close")
	--menuWindow:createButton("Restart",          "menu.pausemenu.buttonRestart",                       "CenteredImageButtonWidget", "")
	menuWindow:createButton("Chapter",          "menu.pausemenu.buttonChooseLevelShort",              "CenteredImageButtonWidget", "")
	menuWindow:createButton("MainMenu",         "menu.pausemenu.buttonMainMenu",                      "CenteredImageButtonWidget", "")
	menuWindow:createButton("Settings",         "menu.mainmenu.helpandoptionsmenu.buttonSettings",    "CenteredImageButtonWidget", "ShadwenSettingsMenuWidget")
	menuWindow:createButton("Difficulty",       "menu.mainmenu.difficultymenu.headerDifficulty",      "CenteredImageButtonWidget", "DifficultyMenuWidget")
	--menuWindow:createButton("Credits",          "menu.mainmenu.helpandoptionsmenu.buttonCredits",     "CenteredImageButtonWidget", "CreditsMenuWidget")
	
	if not platformModule:isPlatformPS4() then
		menuWindow:createButton("ExitGame",         "menu.pausemenu.buttonExit",                          "CenteredImageButtonWidget", "")
	end
end

-- data/script/fui/menu/pause_menu_window.lua
