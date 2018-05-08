
menuWindow:clearMenu()

do
	menuWindow:setMenuGrid("DifficultySettingsMenuGridWidget");
	menuWindow:setTitle("menu.mainmenu.difficultymenu.headerDifficulty")
	
	local onOffOptions =
	{
		"menu.mainmenu.difficultymenu.valueOn",
		"menu.mainmenu.difficultymenu.valueOff"
	}
	
	menuWindow:createRadioButton("VisionCones",     "menu.mainmenu.difficultymenu.descriptionEasy",        "TrineRadioButtonWidget", onOffOptions)
	menuWindow:createRadioButton("OutlinesEnabled", "menu.mainmenu.difficultymenu.descriptionEasy2",       "TrineRadioButtonWidget", onOffOptions)
	menuWindow:createRadioButton("LilyFollows",     "menu.mainmenu.difficultymenu.descriptionLilyFollows", "TrineRadioButtonWidget", onOffOptions)
end

-- data/script/fui/menu/difficulty_menu.lua