module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

local thisModule = _M

declareReload(thisModule, [[originalSubtitleLocale]])
declareReload(thisModule, [[originalAudioLocale]])

function audioDone(subtitleName)
	if fuiSubtitleComponent then
		fuiSubtitleComponent:clearSubtitle(subtitleName)
	end
	cinematic.CinematicUtil.skippingGUICinematic = false
end

originalSubtitleLocale = nil
originalAudioLocale = nil

function allLanguagesDone(subtitleName)
	audioDone(subtitleName)
	
	if (originalSubtitleLocale) then
		localeModule:setSubtitleLanguage(originalSubtitleLocale)
		localeModule:setGuiLanguage(originalSubtitleLocale)
		originalSubtitleLocale = nil
	end
	if (originalAudioLocale) then
		local wwiseAudioId = nil
		local enWwiseAudioId = nil
		localeModule:setAudioLanguage(originalAudioLocale)
		for k,v in pairs(misc.LocaleSettings.languages) do
			if (v.id == originalAudioLocale) then
				wwiseAudioId = v.audioName
			end
			if (v.id == "en") then
				enWwiseAudioId = v.audioName
			end
		end

		local okForAudio = false
		for i = 1,#misc.LocaleSettings.audioLanguages do
			if (misc.LocaleSettings.audioLanguages[i] == originalAudioLocale) then okForAudio = true end
		end

		if (wwiseAudioId and okForAudio) then
			audioModule:setAudioLanguage(wwiseAudioId)
			localeModule:setAudioLanguage(originalAudioLocale)
		else
			logger:error("Failed to restore original audio language.")
			audioModule:setAudioLanguage(enWwiseAudioId)
			localeModule:setAudioLanguage("en")
		end
		originalAudioLocale = nil
	end	
end

-- internal implementation function
function playAudioForSubtitleImpl(subtitleName, completedCallbackString)
	assert_string(subtitleName)
	assert_string(completedCallbackString)
	
	local subStart = string.sub(subtitleName, 1, 8)
	if (subStart ~= "locales.") then
		logger:warning("Locale key \""..subtitleName.."\" does not appear to be a subtitle locale (does not start with the string \"locales.\"). Skipping.")
		return
	end

	local subStart2 = string.sub(subtitleName, 1, 11)
	local localeWithoutSub = string.sub(subtitleName, 9)
	if (subStart2 == "locales.sub") then
		localeWithoutSub = string.sub(subtitleName, 12)
	end
	
	local speechEvent = "Play_"..localeWithoutSub 
	local failsafeDuration = 500 -- intentionally small to allow noticing these cases such.
	
	cinematic.CinematicUtil.skippingGUICinematic = false
	cinematic.CinematicUtil.playSpeech(speechEvent, subtitleName, failsafeDuration, 500, completedCallbackString)
	
	if fuiSubtitleComponent then
		if (subtitlesLocale:doesKeyExist(subtitleName)) then		
			-- this infoline would affect the automatic line wrapping...
			--local infoLine = "\n(subtitle: " .. localeModule:getSubtitleLanguage() .. ", audio: " .. localeModule:getAudioLanguage() .. ")"
			local infoLine = ""
			fuiSubtitleComponent:showSubtitle(fontname, subtitlesLocale:getValue(subtitleName)..infoLine, subtitleName)
		else
			fuiSubtitleComponent:showSubtitle(fontname, "(Missing subtitle locale key \""..subtitleName.."\".)", subtitleName)
		end
	else
		logger:error("locale_authoring.lua - Couldn't find fuiSubtitleComponent.")
	end
end

-- step-by-step all language play internal functions
function playAudioForSubtitleAllStep(languageId, subtitleName)
	assert_string(languageId)
	assert_string(subtitleName)

	localeModule:setGuiLanguage(languageId)
	localeModule:setSubtitleLanguage(languageId)
	
	-- use the audio language if available, if not, use english audio instead, with the specific language subtitling.
	local wwiseAudioId = nil
	local enWwiseAudioId = nil
	for k,v in pairs(misc.LocaleSettings.languages) do
		if (v.id == languageId) then
			wwiseAudioId = v.audioName
		end
		if (v.id == "en") then
			enWwiseAudioId = v.audioName
		end
	end
	local okForAudio = false
	for i = 1,#misc.LocaleSettings.audioLanguages do
		if (misc.LocaleSettings.audioLanguages[i] == languageId) then okForAudio = true end
	end

	if (wwiseAudioId and okForAudio) then
		audioModule:setAudioLanguage(wwiseAudioId)
		localeModule:setAudioLanguage(languageId)
	else
		audioModule:setAudioLanguage(enWwiseAudioId)
		localeModule:setAudioLanguage("en")
	end
	
	local nextLangId = nil
	if (languageId == "en") then	
		nextLangId = "de"
	elseif (languageId == "de") then
		nextLangId = "fr"
	elseif (languageId == "fr") then
		nextLangId = "it"
	elseif (languageId == "it") then
		nextLangId = "es"
	elseif (languageId == "es") then
		nextLangId = "fi"
	end
	if (nextLangId) then
		playAudioForSubtitleImpl(subtitleName, "editor.LocaleAuthoring.playAudioForSubtitleAllStep(\""..nextLangId.."\", \""..subtitleName.."\")")	
	else
		playAudioForSubtitleImpl(subtitleName, "editor.LocaleAuthoring.allLanguagesDone(\""..subtitleName.."\")")	
	end
end

-- play in current language
function playAudioForSubtitle(subtitleName)
	if (state:isEditorState()) then
		logger:error("Cannot play subtitle/audio while in editor mode, start the game first")
		return
	end

	-- skip any previous stuff
	skip()
	
	playAudioForSubtitleImpl(subtitleName, "editor.LocaleAuthoring.audioDone(\"" .. subtitleName .. "\")")	
end

-- play in all languages
function playAudioForSubtitleInAllLanguages(subtitleName)		
	if (state:isEditorState()) then
		logger:error("Cannot play subtitle/audio while in editor mode, start the game first.")
		return
	end
	
	-- skip any previous stuff
	skip()
	
	originalSubtitleLocale = localeModule:getSubtitleLanguage()
	originalAudioLocale = localeModule:getAudioLanguage()
	
	playAudioForSubtitleAllStep("en", subtitleName)
end

function changeLanguage(languageId)
	localeModule:setSubtitleLanguage(languageId)
	localeModule:setGuiLanguage(languageId)
	local wwiseAudioId = nil
	local enWwiseAudioId = nil
	for k,v in pairs(misc.LocaleSettings.languages) do
		if (v.id == languageId) then
			wwiseAudioId = v.audioName
		end
		if (v.id == "en") then
			enWwiseAudioId = v.audioName
		end
	end

	local okForAudio = false
	for i = 1,#misc.LocaleSettings.audioLanguages do
		if (misc.LocaleSettings.audioLanguages[i] == languageId) then okForAudio = true end
	end

	if (wwiseAudioId and okForAudio) then
		audioModule:setAudioLanguage(wwiseAudioId)
		localeModule:setAudioLanguage(languageId)
	else	
		audioModule:setAudioLanguage(enWwiseAudioId)
		localeModule:setAudioLanguage("en")
	end
end

function skip()
	cinematic.CinematicUtil.skipCinematicGUISpeech()
end
