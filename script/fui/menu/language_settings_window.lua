
function getMenuLanguageTable()
	local ret = {}
	for i=1,#misc.LocaleSettings.subtitleLocaleLanguages do
		local languageId = misc.LocaleSettings.subtitleLocaleLanguages[i]
		table.insert(ret, localeModule:getNativeNameForLanguageId(languageId))
	end
	return ret
end

--function getAudioLanguagesTable()
--	local ret = {}
--	for i=1,#misc.LocaleSettings.audioLanguages do
--		local languageId = misc.LocaleSettings.audioLanguages[i]
--		table.insert(ret, localeModule:getNativeNameForLanguageId(languageId))
--	end
--	return ret
--end

menuWindow:clearMenu()

do
	menuWindow:setMenuGrid("SettingsMenuGridWidgetNarrow");
	menuWindow:setTitle("menu.mainmenu.languagesettingsmenu.headerLanguageSettings")

	menuWindow:createRadioButton("SubtitlesEnabled", "menu.mainmenu.languagesettingsmenu.buttonSubtitles", "TrineRadioButtonWidget", { "menu.mainmenu.languagesettingsmenu.valueOn", "menu.mainmenu.languagesettingsmenu.valueOff" })
	
	
	menuWindow:createDropDownMenu("TextLanguage", "menu.mainmenu.languagesettingsmenu.buttonTextLanguage", "SettingsMenuDropDownWidget", getMenuLanguageTable())
	
	--menuWindow:createDropDownMenu("AudioLanguage", "menu.mainmenu.languagesettingsmenu.buttonAudioLanguage", "SettingsMenuDropDownWidget", getAudioLanguagesTable())
end

-- data/script/fui/menu/language_settings_window.lua
