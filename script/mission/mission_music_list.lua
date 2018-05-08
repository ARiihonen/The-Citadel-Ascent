module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

local thisModule = _M
declareManualReload(thisModule, [[music]])
declareManualReload(thisModule, [[no_music_event]])

music = {}

-- NOTE: Add "mission_" prefix to missionIDs since LUA doesn't really like variable names which starts with numbers
-- NOTE: "no_music" is a special keyword identified by menu_music_util that means that no music should play
-- and that previous music should be stopped. This is better than using "" or nil because those might mean
-- misconfigured or missing music.		
no_music_event = "no_music"
		
-- Menus
music.mission_menu = ""
music.mission_mainmenu = "Play_mainmenu_music"

-- Actual levels

music.mission_anna_02_tutorial_lily = "Play_lily_tutorial"
music.mission_anna_03_tutorial_shadwen = "Play_shadwen_tutorial"
music.mission_anna_04_tutorial_lily_and_shadwen = "Play_music_generic_1"
music.mission_kim_01_castle_wall_cliff_guard_house = "Play_music_generic_castle"
music.mission_anna_01_castle_wall_city_walls = "Play_music_generic_2"
music.mission_sami_02_prisons_prisons = "Play_music_prison"
music.mission_esa_01_prisons_guard_house = "Play_music_generic_castle"
music.mission_ville_02_poor_district_poor_housing = "Play_music_poor_district_1"
music.mission_sami_01_poor_district_poor_courtyard = "Play_music_generic_1"
music.mission_mikko_02_poor_district_poor_square = "Play_music_poor_district_1"
music.mission_kim_03_merchants_square_and_docks_port = "Play_music_docks"
music.mission_kim_02_merchants_square_and_docks_market_place = "Play_music_marketplace"
music.mission_sami_03_noble_district = "Play_music_generic_3"
music.mission_esa_03_castle_courtyard_main_gate = "Play_music_generic_2"
music.mission_ville_03_inside_the_castle = "Play_music_final_castle"
music.mission_anna_03_tutorial_shadwen_reversed = "Play_shadwen_tutorial"
music.mission_anna_04_tutorial_lily_and_shadwen_reversed = "Play_music_generic_1"
music.mission_kim_01_castle_wall_cliff_guard_house_reversed = "Play_music_generic_castle"
music.mission_anna_01_castle_wall_city_walls_reversed = "Play_music_generic_2"
music.mission_sami_02_prisons_prisons_reversed = "Play_music_prison"
music.mission_esa_01_prisons_guard_house_reversed = "Play_music_generic_castle"
music.mission_ville_02_poor_district_poor_housing_reversed = "Play_music_poor_district_1"
music.mission_sami_01_poor_district_poor_courtyard_reversed = "Play_music_generic_1"
music.mission_mikko_02_poor_district_poor_square_reversed = "Play_music_poor_district_1"
music.mission_kim_03_merchants_square_and_docks_port_reversed = "Play_music_docks"
music.mission_kim_02_merchants_square_and_docks_market_place_reversed = "Play_music_marketplace"
music.mission_sami_03_noble_district_reversed = "Play_music_generic_3"
music.mission_esa_03_castle_courtyard_main_gate_reversed = "Play_music_generic_2"
music.mission_ville_03_inside_the_castle_reversed = "Play_music_final_castle"
