
-- this may not be required globally, or the reload won't work (nor should it be usable in global context anyway)
--require "mission.MissionChangeUtil"

campaigns = nil;
missions = nil;

campaigns = {
	{ "original" }
}

-- mission entries:
--  { campaign, id, { playableMission, multiplayerAllowed, characterChangeDisabled, showOnlySelectedCharacterGUI, upgradeMenuDisabled, experienceRequirement, stageRequirement, preferredStartingCharacter (optional), tutorialMission (optional) } }

missions = {
	 { "original", 				"mainmenu",									{true, true, true, true, true, 0, ""} }
	,{ "original", 				"anna_02_tutorial_lily",									{true, true, true, true, true, 0, ""} }
	,{ "original", 				"anna_03_tutorial_shadwen",									{true, true, true, true, true, 0, ""} }
	,{ "original", 				"anna_04_tutorial_lily_and_shadwen",						{true, true, true, true, true, 0, ""} }
	,{ "original", 				"kim_01_castle_wall_cliff_guard_house",						{true, true, true, true, true, 0, ""} }
	,{ "original", 				"anna_01_castle_wall_city_walls",							{true, true, true, true, true, 0, ""} }
	,{ "original", 				"sami_02_prisons_prisons",									{true, true, true, true, true, 0, ""} }
	,{ "original", 				"esa_01_prisons_guard_house",								{true, true, true, true, true, 0, ""} }
	,{ "original", 				"ville_02_poor_district_poor_housing",						{true, true, true, true, true, 0, ""} }
	,{ "original", 				"sami_01_poor_district_poor_courtyard",						{true, true, true, true, true, 0, ""} }
	,{ "original", 				"mikko_02_poor_district_poor_square",						{true, true, true, true, true, 0, ""} }
	,{ "original", 				"kim_03_merchants_square_and_docks_port",					{true, true, true, true, true, 0, ""} }
	,{ "original", 				"kim_02_merchants_square_and_docks_market_place",			{true, true, true, true, true, 0, ""} }
	,{ "original", 				"sami_03_noble_district",									{true, true, true, true, true, 0, ""} }
	,{ "original", 				"esa_03_castle_courtyard_main_gate",						{true, true, true, true, true, 0, ""} }
	,{ "original", 				"ville_03_inside_the_castle",								{true, true, true, true, true, 0, ""} }

	,{ "original", 				"ville_03_inside_the_castle_reversed",						{true, true, true, true, true, 0, ""} }
	,{ "original", 				"esa_03_castle_courtyard_main_gate_reversed",				{true, true, true, true, true, 0, ""} }
	,{ "original", 				"sami_03_noble_district_reversed",							{true, true, true, true, true, 0, ""} }
	,{ "original", 				"kim_02_merchants_square_and_docks_market_place_reversed",	{true, true, true, true, true, 0, ""} }
	,{ "original", 				"kim_03_merchants_square_and_docks_port_reversed",			{true, true, true, true, true, 0, ""} }
	,{ "original", 				"mikko_02_poor_district_poor_square_reversed",				{true, true, true, true, true, 0, ""} }
	,{ "original", 				"sami_01_poor_district_poor_courtyard_reversed",			{true, true, true, true, true, 0, ""} }
	,{ "original", 				"ville_02_poor_district_poor_housing_reversed",				{true, true, true, true, true, 0, ""} }
	,{ "original", 				"esa_01_prisons_guard_house_reversed",						{true, true, true, true, true, 0, ""} }
	,{ "original", 				"sami_02_prisons_prisons_reversed",							{true, true, true, true, true, 0, ""} }
	,{ "original", 				"anna_01_castle_wall_city_walls_reversed",					{true, true, true, true, true, 0, ""} }
	,{ "original", 				"kim_01_castle_wall_cliff_guard_house_reversed",			{true, true, true, true, true, 0, ""} }
	,{ "original", 				"anna_04_tutorial_lily_and_shadwen_reversed",				{true, true, true, true, true, 0, ""} }	
	,{ "original", 				"anna_03_tutorial_shadwen_reversed",						{true, true, true, true, true, 0, ""} }
}
	
-- Clear campaigns
missionModule:clearCampaigns();

-- Make campaigns
for k,v in ipairs(campaigns) do
	missionModule:addNewCampaign(v[1])
end

-- Add main menu mission always first
missionModule:setAllowMainMenuInCampaign(true); -- Main menu level acts as normal level/mission
--missionModule:addMainMenuMission(); -- Main menu level acts as separate main menu level and not a mission

-- Then, add rest of missions
for k,v in ipairs(missions) do
	missionModule:addNewMission(v[1], v[2], v[3]);
end

if missionModule and missionModule.setDefaultStartupMissionID then
	--missionModule:setDefaultStartupMissionID("kim_01_castle_wall_cliff_guard_house");
end
