module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

require "debug.Assert"
require "cinematic.CinematicUtil"

-- start mission list
require "cinematic.LoadingMainMenu";
require "cinematic.LoadingAnna02TutorialLily";
require "cinematic.LoadingAnna03TutorialShadwen";
require "cinematic.LoadingAnna04TutorialLilyAndShadwen";
require "cinematic.LoadingKim01CastleWallCliffGuardHouse";
require "cinematic.LoadingAnna01CastleWallCityWalls";
require "cinematic.LoadingSami02PrisonsPrisons";
require "cinematic.LoadingEsa01PrisonsGuardHouse";
require "cinematic.LoadingVille02PoorDistrictPoorHousing";
require "cinematic.LoadingSami01PoorDistrictPoorCourtyard";
require "cinematic.LoadingMikko02PoorDistrictPoorSquare";
require "cinematic.LoadingKim03MerchantsSquareAndDocksPort";
require "cinematic.LoadingKim02MerchantsSquareAndDocksMarketPlace";
require "cinematic.LoadingSami03NobleDistrict";
require "cinematic.LoadingEsa03CastleCourtyardMainGate";
require "cinematic.LoadingVille03InsideTheCastle";
-- end of mission list

traumatizingMissionNumber = -1

function getMissionUpperId(missionId)
	assert_string(missionId)
	local upperMissionId = string.upper(missionId:sub(1,1)) .. missionId:sub(2);
	
	local umid = common.CommonUtils.getMissionUpperCaseIDName(missionId);
	if string.len(umid) == 0 then
		umid = upperMissionId;
	end

	return umid;
end


function getLoadingCinematicModule(missionId)
	assert_string(missionId)
	local upperMissionId = getMissionUpperId(missionId)
	assert_string(upperMissionId)

	local loadingCinematicModule = cinematic["Loading"..upperMissionId]
	
	if (loadingCinematicModule) then
		assert_luamodule(loadingCinematicModule)		
		return loadingCinematicModule
	else
		return nil
	end
end


function startLoadingMusic(missionId)
	assert_string(missionId)
	
	local loadingCinematicModule = getLoadingCinematicModule(missionId)
	if loadingCinematicModule and loadingCinematicModule.startMusic then
		loadingCinematicModule.startMusic()
	else
		-- default music if none is specified
		cinematic.CinematicUtil.playLoadingScreenMusic(nil);
	end
end


function setLilysTraumaMissionNumber(missionNumber)
	traumatizingMissionNumber = missionNumber
end


function startLoadingCinematic(missionId)
	assert_string(missionId)
	local loadingCinematicModule = getLoadingCinematicModule(missionId)
	
	if (loadingCinematicModule) then
		loadingCinematicModule.start(traumatizingMissionNumber)
	else
		if not common.CommonUtils.isMainMenuMission(missionId) then
			logger:warning("No loading cinematic found for mission \""..missionId.."\".");
		end
		cinematic.CinematicUtil.loadingCinematicDone()
	end
end

