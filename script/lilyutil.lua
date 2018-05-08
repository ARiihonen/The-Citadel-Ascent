module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

function stopLily()
	function recurseInstances(inst)
		if not inst then
			logger:error("Calling recurseInstances with NIL instance in cheat.makeChildUndetectable")
			return
		end
		
		local gcucc = inst:findComponent(game.gameplay.character.GameCharacterUnderCommandComponent);
		if gcucc then
			gcucc:setNavigationStateBeforeDisabling(gcucc:getNavigationState())
			gcucc:setNavigationState(game.gameplay.character.GameCharacterUnderCommandComponent.navigationStateDisabled)
		end
		
		for i = 0, inst:getNumChildren()-1 do
			recurseInstances(inst:getChild(i))
		end
	end
	
	recurseInstances(gameScene:getSceneInstanceManager():getTopmostInstanceRoot())
end

function restartLily()
	function recurseInstances(inst)
		if not inst then
			logger:error("Calling recurseInstances with NIL instance in cheat.makeChildUndetectable")
			return
		end
		
		local gcucc = inst:findComponent(game.gameplay.character.GameCharacterUnderCommandComponent);
		if gcucc then
			gcucc:setNavigationState(gcucc:getNavigationStateBeforeDisabling())
		end
		
		for i = 0, inst:getNumChildren()-1 do
			recurseInstances(inst:getChild(i))
		end
	end
	
	recurseInstances(gameScene:getSceneInstanceManager():getTopmostInstanceRoot())
end