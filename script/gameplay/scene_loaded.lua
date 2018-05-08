
if not state:isEditorState() then
	local currentMission = common.CommonUtils.getCurrentMissionID();
	local sceneLoadType = -1;

	if string.len(currentMission) > 0 then
		local inMainMenu = common.CommonUtils.isCurrentMissionMainMenuMission();
		
		-- Various menus behave differently
		if inMainMenu then
			sceneLoadType = 2;
		else
			sceneLoadType = 1;
		end
	else
		-- Empty mission or for some reason mission id isn't updated yet (client is joining to host's game or something)		
		if state:isOffline() then
			sceneLoadType = 0;
		else
			sceneLoadType = 1;		
		end
	end

	if sceneLoadType == 0 then
		-- Do nothing
		--logger:info("SceneLoaded - SceneLoadTrigger disabled.");
	elseif sceneLoadType == 1 then
		-- Normal (instant)
		--logger:info("SceneLoaded - SceneLoadTrigger normal.");
		common.CommonUtils.doSceneLoaded();	
	elseif sceneLoadType == 2 then
		-- Delayed
		--logger:info("SceneLoaded - SceneLoadTrigger delayed.");
		common.CommonUtils.startSceneLoadedDelayed(100);		
	else
		logger:error("SceneLoaded - Invalid sceneLoadType.");
	end
end
