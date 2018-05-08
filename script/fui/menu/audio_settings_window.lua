
menuWindow:clearMenu()

do
	menuWindow:setTitle("menu.mainmenu.audiovolumemenu.headerAudioVolume")
	menuWindow:setMenuGrid("SettingsMenuGridWidget");

	-- Volume sliders
	menuWindow:createSlider("MasterSlider",  "menu.mainmenu.audiovolumemenu.sliderMaster", "MenuSlider", 0, 100)
	menuWindow:createSlider("SoundFxSlider", "menu.mainmenu.audiovolumemenu.sliderSoundFx", "MenuSlider", 0, 100)
	menuWindow:createSlider("SpeechSlider",  "menu.mainmenu.audiovolumemenu.sliderSpeech", "MenuSlider", 0, 100)
	menuWindow:createSlider("MusicSlider",   "menu.mainmenu.audiovolumemenu.sliderMusic", "MenuSlider", 0, 100)
	
	-- Spacer
	menuWindow:createLabel("", "", "MenuTextLabelWidget")
	
	-- Headphone Mode
	menuWindow:createRadioButton("HeadphoneModeEnabled", "menu.mainmenu.audiovolumemenu.buttonHeadphonePanningMode", "TrineRadioButtonWidget", { "menu.mainmenu.audiovolumemenu.valueOn", "menu.mainmenu.audiovolumemenu.valueOff" })
end

-- data/script/fui/menu/audio_settings_window.lua
