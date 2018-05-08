module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

local thisModule = _M

declareManualReload(thisModule, [[letterSpecifications]])

-- available letters

letterSpecifications = 
{
	--{ missionId = "witch_castle1", name = "letter", textLocale = "05_witch_castle1_17_letter_rosabel_dear_izzie_put", iconPosX = 0, iconPosY = 0, iconFile = "" }
	--, { missionId = "witch_castle2", name = "letter", textLocale = "06_witch_castle2_07_letter_isabel_thank_you_for", iconPosX = 0, iconPosY = 0, iconFile = "" }
	--, { missionId = "spooky_forest", name = "letter", textLocale = "07_spooky_forest_18_letter_rosabel_dear_izzie_happy", iconPosX = 0, iconPosY = 0, iconFile = "" }
	--, { missionId = "mushroom_cave", name = "letter", textLocale = "08a_mushroom_cave_11_letter_isabel_dear_rosie_im", iconPosX = 0, iconPosY = 0, iconFile = "" }
--	, { missionId = "seasurface_ruins", name = "letter", textLocale = "10_seasurface_ruins_21a_amadeus_letter_combined", iconPosX = 0, iconPosY = 0, iconFile = "" }
	--, { missionId = "seasurface_ruins", name = "letter", textLocale = "10_seasurface_ruins_21b_pontius_letter_combined", iconPosX = 0, iconPosY = 0, iconFile = "" }
--	, { missionId = "seasurface_ruins", name = "letter", textLocale = "10_seasurface_ruins_21c_zoya_letter_combined", iconPosX = 0, iconPosY = 0, iconFile = "" }
	--, { missionId = "seasurface_ruins", name = "letter2", textLocale = "10_seasurface_ruins_47_letter_rosabel_dear_isabel_happy", iconPosX = 0, iconPosY = 0, iconFile = "" }
	--, { missionId = "sewers", name = "letter", textLocale = "11_sewers_20_letter_isabel_dear_rosie_happy", iconPosX = 0, iconPosY = 0, iconFile = "" }
	--, { missionId = "ice_castle", name = "letter", textLocale = "12_ice_castle_30_letter_rosabel_dear_isabel_it", iconPosX = 0, iconPosY = 0, iconFile = "" }
}


-- mysteriously solves the letter id number from given mission id and the treasure chest entity name
-- notice, that the treasure chest name here is not necessarily a full entity name, but just a portion of it
-- you'll need to give the right portion here. (currently always "letter" as only one letter per mission)
-- NOTE: letter name here is not the treasure chest entity name! see getLetterIdByMissionIdAndTreasureChestEntityName()
function getLetterIdByMissionIdAndLetterName(missionId, letterName)
	assert_string(missionId)
	assert_string(letterName)	
	
	for i = 1,#letterSpecifications do
		if (letterSpecifications[i].missionId == missionId and letterSpecifications[i].name == letterName) then
			return i - 1
		end
	end
	
	-- no such letter listed
	return -1
end


-- get the letter id based on mission id and treasure chest entity name
function getLetterIdByMissionIdAndTreasureChestEntityName(missionId, treasureChestEntityName)
	local letterName = getLetterName(treasureChestEntityName)
	return getLetterIdByMissionIdAndLetterName(missionId, letterName)
end


-- note, does not return the full locale, just a postfix to be added to "locales.sub" ro something like that. 
-- (thus, works for audio event name as well, with a "Play_" prefix.)
function getLetterTextLocale(idNum)
	assert_number(idNum)
	
	return letterSpecifications[idNum + 1].textLocale
end


function getLetterIconFilename(idNum)
	assert_number(idNum)
	
	return letterSpecifications[idNum + 1].iconFile
end


-- TODO: improved support
-- only one letter per map supported. if multiple ones are to be supported, a more complex logic would be required
-- in simplest terms, could be looking for the word "letter" in the entity name, then assuming it is possibly followed by a number - and treat that as the letter name
function getLetterName(treasureChestEntityName)
	assert_string(treasureChestEntityName)	
	if (string.find(treasureChestEntityName, "letter2", 1, true)) then
		return "letter2"
	else
		return "letter"
	end
end
