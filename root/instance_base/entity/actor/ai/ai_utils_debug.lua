local moduleName = "gameplay.ai.AiUtilsDebug"
module(moduleName, package.seeall)
debug.ReloadScripts.allowReload(moduleName)

-------------------------------------------------------------------------------------------------
--
-- Wrapped error / debug messages (IMPL)
--

function logErrorImpl(msg)
	if msg == nil then
		logger:error("ai_utils_debug:logErrorImpl - Nil message given.");
		return;
	end
	logger:error(msg);
end

function logWarningImpl(msg)
	if msg == nil then
		logger:error("ai_utils_debug:logWarningImpl - Nil message given.");
		return;
	end
	logger:warning(msg);
end

function logInfoImpl(msg)
	if msg == nil then
		logger:error("ai_utils_debug:logInfoImpl - Nil message given.");
		return;
	end
	logger:info(msg);
end

-------------------------------------------------------------------------------------------------
--
-- Wrapped error / debug messages
--

function logError(msg)
	logErrorImpl(msg);
end

function logWarning(msg)
	logWarningImpl(msg);
end

function logInfo(msg)
	logInfoImpl(msg);
end

-------------------------------------------------------------------------------------------------
--
-- Visualize ai properties
--

function enableVisualizerComponentByClass(obj, enabled, class)
	if obj ~= nil then
		local inst = nil;		
		if obj:isInherited(engine.base.ComponentBase.getStaticObjectClass()) and obj.getFinalOwner then
			inst = obj:getFinalOwner();
		else
			inst = obj;
		end
		
		if inst ~= nil then
			local visualizerComponent = inst:findComponentByClass(class);
			if visualizerComponent ~= nil then
				visualizerComponent:setVisible(enabled);
				visualizerComponent:setSelected(enabled);
			end
		end
	end
end

function enablePropertyVisualizerForAllInstances(enabled, instanceTypeNameFilterString)

	if(enabled == nil) then
		logError("ai_utils_debug:enablePropertyVisualizerForAllInstances - You are supposed to give the enabled parameter as boolean (true or false).");
	end		

	local resultIterator = filteringModule:filterTreeBranchUsingMultiLevelFilter(instanceManager:getTopmostInstanceRoot(), "0,data/filter/native/nativefilter_composite_allowall_allowall.fbfilt", editor.Editor.InfiniteDepth, false)
	local obj = resultIterator:next();
	while (not(obj == nil)) do
	
		local allow = true;
		if instanceTypeNameFilterString ~= nil and string.len(instanceTypeNameFilterString) > 0 then
			allow = false;
			local type = typeManager:getTypeByUH( obj:getType() );
			if type then
				if type:doesInheritTypeByName(instanceTypeNameFilterString) then
					allow = true;
				end
			end
		end
	
		if allow then			
			visualizeAiProperties(obj, enabled);
		end		
		obj = resultIterator:next();		
	end
end

function visualizeAiProperties(obj, enabled)
	--enableDebugComponentForTransformComponent(obj, enabled);
	enableDebugComponentForCharacterComponent(obj, enabled);
	enableDebugComponentForStateComponents(obj, enabled);
	enableDebugComponentForAnimationComponent(obj, enabled);
	enableDebugComponentForRootMotionJointComponent(obj, enabled);
	enableDebugComponentForTargetComponent(obj, enabled);
	enableDebugComponentForHealthComponent(obj, enabled);	
	
	-- Visualize parabolic auto aim
	enableVisualizerComponentByClass(obj, enabled, gameplay.visualization.RangedWeaponVisualizerComponent.getStaticObjectClass());	
end

function enableDebugComponentForStateComponents(obj, enabled)
	local properties = {
		"StateCollection"
		, "CurrentState"
		, "NumStateChanges"
	}
	-- For Characters
	debug.Visualize.addDebugStateComponent(obj, "MoveState", enabled, properties);
	debug.Visualize.addDebugStateComponent(obj, "AiState", enabled, properties);
	debug.Visualize.addDebugStateComponent(obj, "BowState", enabled, properties);
	
	-- New Generic AI state
	debug.Visualize.addDebugStateComponent(obj, "AIPathfindState", enabled, properties);
	
	-- For AI spawners and points
	debug.Visualize.addDebugStateComponent(obj, nil, enabled, properties);
end

function enableDebugComponentForTransformComponent(obj, enabled)
	local properties = {
		"Position"
		, "Rotation"
	}	
	debug.Visualize.addDebugComponent(obj, engine.component.TransformComponent, enabled, properties);
end

function enableDebugComponentForCharacterComponent(obj, enabled)
	local properties = {
		"AiActive"
		, "AiEnabled"
		, "AiDestroyed"
		, "AiSpawningDone"
		, "StaggerLastTime"
	}
	debug.Visualize.addDebugComponent(obj, gameplay.ai.AICharacterComponent, enabled, properties);
end

function enableDebugComponentForAnimationComponent(obj, enabled)
	local properties = {
		"AbsoluteRootMotionPosition"
		, "AbsoluteRootMotionPositionUpdateEnabled"
		--, "CurrentStateName"
		--, "ActiveContextsList"
	}
	debug.Visualize.addDebugComponent(obj, animation.AnimationComponent, enabled, properties);
end

function enableDebugComponentForRootMotionJointComponent(obj, enabled)
	local properties = {
		"AxisXEnabled"
		, "AxisYEnabled"
		, "AxisZEnabled"
		, "LocalAnchor1"
	}
	debug.Visualize.addDebugComponent(obj, physics.RootMotionJointComponent, enabled, properties);
end

function enableDebugComponentForTargetComponent(obj, enabled)
	local properties = {
		"Target"
		, "SpottedTarget"
	}
	debug.Visualize.addDebugComponent(obj, gameplay.TargetComponent, enabled, properties);
end

function enableDebugComponentForHealthComponent(obj, enabled)
	local properties = {
		"Health"
		--, "MinHealth"
		--, "MaxHealth"
		--, "Immortal"
	}
	debug.Visualize.addDebugComponent(obj, gameplay.damage.HealthComponent, enabled, properties);
end


------------------------------------------------------------------------------------------------------------------
--
-- Simple enemies
--

function spawnGiantCrab()
	editor.Util.spawnInstanceByTypeNameNearPlayer("GiantCrab");	
end

function spawnGiantCrabWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("GiantCrab", offset);
end

------------------------------------------------------------------------------------------------------------------
--
-- Walk With Helpers enemies
--


function spawnArcherGoblin()
	editor.Util.spawnInstanceByTypeNameNearPlayer("ArcherGoblin");	
end

function spawnArcherGoblinWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("ArcherGoblin", offset);
end

function spawnArcherGoblinMobile()
	editor.Util.spawnInstanceByTypeNameNearPlayer("ArcherGoblinMobile");	
end

function spawnArcherGoblinMobileWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("ArcherGoblinMobile", offset);
end

function spawnFireArcherGoblin()
	editor.Util.spawnInstanceByTypeNameNearPlayer("FireArrowArcherGoblin");	
end

function spawnFireArcherGoblinWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("FireArrowArcherGoblin", offset);
end

function spawnFireArcherGoblinMobile()
	editor.Util.spawnInstanceByTypeNameNearPlayer("FireArcherGoblinMobile");	
end

function spawnFireArcherGoblinMobileWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("FireArcherGoblinMobile", offset);
end

function spawnBoneCrusher()
	editor.Util.spawnInstanceByTypeNameNearPlayer("BoneCrusher");	
end

function spawnBoneCrusherWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("BoneCrusher", offset);
end

function spawnCauldronMonster()
	editor.Util.spawnInstanceByTypeNameNearPlayer("CauldronMonster");	
end

function spawnCauldronMonsterWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("CauldronMonster", offset);
end

function spawnFireSwordGoblin()
	editor.Util.spawnInstanceByTypeNameNearPlayer("FireSwordGoblin");	
end

function spawnFireSwordGoblinWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("FireSwordGoblin", offset);
end

function spawnSmallSpider()
	editor.Util.spawnInstanceByTypeNameNearPlayer("SmallSpider");	
end

function spawnSmallSpiderWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("SmallSpider", offset);
end

function spawnSmallSpiderStartInWeb()
	editor.Util.spawnInstanceByTypeNameNearPlayer("SmallSpiderStartInWeb");	
end

function spawnSmallSpiderStartInWebWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("SmallSpiderStartInWeb", offset);
end

function spawnSuicidepig()
	editor.Util.spawnInstanceByTypeNameNearPlayer("SuicidePig");	
end

function spawnSuicidepigWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("Suicidepig", offset);
end

function spawnSwampGoblin()
	editor.Util.spawnInstanceByTypeNameNearPlayer("SwampGoblin");
end

function spawnSwampGoblinWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("SwampGoblin", offset);
end

function spawnWarriorGoblin()
	editor.Util.spawnInstanceByTypeNameNearPlayer("WarriorGoblin");	
end

function spawnWarriorGoblinWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("WarriorGoblin", offset);
end

function spawnWarriorGoblinShield()
	editor.Util.spawnInstanceByTypeNameNearPlayer("WarriorGoblinShield");	
end

function spawnWarriorGoblinShieldWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("WarriorGoblinShield", offset);
end

function spawnFishGoblin()
	editor.Util.spawnInstanceByTypeNameNearPlayer("FishGoblin");	
end

function spawnFishGoblinWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("FishGoblin", offset);
end

function spawnFishGoblinShield()
	editor.Util.spawnInstanceByTypeNameNearPlayer("FishGoblinShield");	
end

function spawnFishGoblinShieldWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("FishGoblinShield", offset);
end

--
-- DLC AI
--
function spawnRockGolem()
	editor.Util.spawnInstanceByTypeNameNearPlayer("RockGolem");
end

function spawnRockGolemWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("RockGolem", offset);
end

function spawnMummy()
	editor.Util.spawnInstanceByTypeNameNearPlayer("Mummy");
end

function spawnMummyWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("Mummy", offset);
end

function spawnGrenadierGoblin()
	editor.Util.spawnInstanceByTypeNameNearPlayer("GrenadierGoblin");
end

function spawnGrenadierGoblinWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("GrenadierGoblin", offset);
end

function spawnWyvern()
	editor.Util.spawnInstanceByTypeNameNearPlayer("Wyvern");
end

function spawnWyvernWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("Wyvern", offset);
end

function spawnTankBossBase()
	editor.Util.spawnInstanceByTypeNameNearPlayer("TankBossBase");
end

function spawnTankBossBaseWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("TankBossBase", offset);
end



--
-- Trine 3 AI (move these somewhere else)
--
function spawnThiefGoblin()
	editor.Util.spawnInstanceByTypeNameNearPlayer("ThiefGoblin");
end

function spawnThiefGoblinWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("ThiefGoblin", offset);
end

function spawnManyGoblins()
	for i=0,10 do gameplay.ai.AiUtilsDebug.spawnThiefGoblin() end
end

function spawnThiefGoblinWithRangedAttack()
	editor.Util.spawnInstanceByTypeNameNearPlayer("ThiefGoblinWithRangedAttack");
end

function spawnThiefGoblinWithRangedAttackWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("ThiefGoblinWithRangedAttack", offset);
end

function spawnLivingBook()
	editor.Util.spawnInstanceByTypeNameNearPlayer("LivingBook");
end

function spawnLivingBookWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("LivingBook", offset);
end

function spawnTreemen()
	editor.Util.spawnInstanceByTypeNameNearPlayer("Treemen");
end

function spawnTreemenWithOffset(offset)
	editor.Util.spawnInstanceByTypeNameNearPlayerWithOffset("Treemen", offset);
end


-------------------------------------------------------------------------------------------------
