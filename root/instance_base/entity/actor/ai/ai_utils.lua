local moduleName = "gameplay.ai.AiUtils"
module(moduleName, package.seeall)
debug.ReloadScripts.allowReload(moduleName)
-------------------------------------------------------------------------------------------------
--
-- Some cfg
--

-- Animation Param names
local cfg_AnimationParamNameDistance = "distance"
local cfg_AnimationParamNameAngle = "angle"
local cfg_AnimationParamNameSpeed = "speed"
local cfg_AnimationParamNameHelperAngle = "helper_angle"
local cfg_AnimationParamNameHammerAngle = "hammer_angle"

-- Animation Context names
local cfg_AnimationContextNameSpawn = "spawn"
local cfg_AnimationContextNameRight = "right"
local cfg_AnimationContextNameLeft = "left"
local cfg_AnimationContextNameType1 = "type1"
local cfg_AnimationContextNameType2 = "type2"
local cfg_AnimationContextNameType3 = "type3"
local cfg_AnimationContextNameType4 = "type4"
local cfg_AnimationContextNameStand = "stand";
local cfg_AnimationContextNameWalk = "walk";
local cfg_AnimationContextNameFall = "fall";
local cfg_AnimationContextNameFast = "fast";
local cfg_AnimationContextNameAttack = "attack";
local cfg_AnimationContextNameAttack1 = "attack1";
local cfg_AnimationContextNameAttack1End = "attack1_end";
local cfg_AnimationContextNameAttack2 = "attack2";
local cfg_AnimationContextNameAttack2End = "attack2_end";
local cfg_AnimationContextNameAttackFast = "attack_fast";
local cfg_AnimationContextNameAttackGoblin = "attack_goblin";
local cfg_AnimationContextNameAttackSpit = "spit";
local cfg_AnimationContextNameSpotted = "spotted";
local cfg_AnimationContextNameIdle = "idle";
local cfg_AnimationContextNameBackground1 = "background1";
local cfg_AnimationContextNameShoot = "shoot";
local cfg_AnimationContextNameStagger = "stagger";
local cfg_AnimationContextNameImpact = "impact";
local cfg_AnimationContextNameArrow = "arrow";
local cfg_AnimationContextNameBack = "back";
local cfg_AnimationContextNameDown = "down";
local cfg_AnimationContextNameUp = "up";
local cfg_AnimationContextNameDie = "die";
local cfg_AnimationContextNameBlocked = "blocked";
local cfg_AnimationContextNameBlock = "block";
local cfg_AnimationContextNameBlocks = "blocks";
local cfg_AnimationContextNameBlockedAttack = "blocked_attack";
local cfg_AnimationContextNameGroup = "group";
local cfg_AnimationContextNamePrepare = "prepare";
local cfg_AnimationContextNameInterested = "interested";
local cfg_AnimationContextNameLevitated = "levitated";
local cfg_AnimationContextNameLevitatedFall = "levitatedfall";
local cfg_AnimationContextNameLevitatedLand = "levitatedland";
local cfg_AnimationContextNameAttackRight = "attack_right";
local cfg_AnimationContextNameAttackLeft = "attack_left";
local cfg_AnimationContextNameStumped = "stumped";
local cfg_AnimationContextNameBurn = "burn";
local cfg_AnimationContextNameAngry = "angry";
local cfg_AnimationContextNameSquashed = "squashed";
local cfg_AnimationContextNameLedgeAttack = "ledge_attack";
local cfg_AnimationContextNameLedgeAttackExecute = "ledge_attack_execute";
local cfg_AnimationContextNameLedgeClimbAttack = "ledge_climb_attack";
local cfg_AnimationContextNameLedgeDown = "ledge_down";
local cfg_AnimationContextNameMoveForward = "move_forward";
local cfg_AnimationContextNameMoveBackward = "move_backward";
local cfg_AnimationContextNameTargetVanished = "target_vanished";
local cfg_AnimationContextNameFrozen = "frozen";
local cfg_AnimationContextNameStaggerHammer = "stagger_hammer";
local cfg_AnimationContextNameChew = "chew";
local cfg_AnimationContextNameMoveTo = "moveto"
local cfg_AnimationContextNameMoveFrom = "movefrom"
local cfg_AnimationContextNameSweep = "sweep"

local cfg_AnimationContextNameCover = "cover";
local cfg_AnimationContextNameGrab = "grab";
local cfg_AnimationContextNameEatPlayer = "eat_player";
local cfg_AnimationContextNameGrabFailed = "grab_failed";

local cfg_AnimationContextNameWeapon1 = "weapon1";
local cfg_AnimationContextNameWeapon2 = "weapon2";
local cfg_AnimationContextNameWeapon3 = "weapon3";
local cfg_AnimationContextNameActive = "active";
local cfg_AnimationContextNameInActive = "inactive";
local cfg_AnimationContextNameMoveLeft = "move_left";
local cfg_AnimationContextNameMoveRight = "move_right";
local cfg_AnimationContextNameStomp = "stomp";
local cfg_AnimationContextNameStompMoving = "stomp_moving";
local cfg_AnimationContextNameShootDown = "shoot_down";
local cfg_AnimationContextNameReload = "reload";
local cfg_AnimationContextNameSpin = "spin";
local cfg_AnimationContextNameSpinReverse = "spin_reverse";
local cfg_AnimationContextNameStop = "stop";
local cfg_AnimationContextNameStationary = "stationary";
local cfg_AnimationContextNameStationaryEnd = "stationary_end";
local cfg_AnimationContextNameFull = "full";
local cfg_AnimationContextNameEmpty = "empty";
local cfg_AnimationContextNameRefill = "refill";
local cfg_AnimationContextNameTurret = "turret";

local cfg_AnimationContextNameIntro = "intro";
local cfg_AnimationContextNameIntroWait = "intro_wait";
local cfg_AnimationContextNameIntroCloudyIsles = "intro_cloudy_isles";
local cfg_AnimationContextNameIntroCloudyIslesWait = "intro_cloudy_isles_wait";

-------------------------------------------------------------------------------------------------
--
-- Wrapped error / debug messages (IMPL)
--

function logErrorImpl(msg)
	if msg == nil then
		logger:error("ai_utils:logErrorImpl - Nil message given.");
		return;
	end	
	logger:error(msg);
end

function logWarningImpl(msg)
	if msg == nil then
		logger:error("ai_utils:logWarningImpl - Nil message given.");
		return;
	end
	logger:warning(msg);
end

function logInfoImpl(msg)
	if msg == nil then
		logger:error("ai_utils:logInfoImpl - Nil message given.");
		return;
	end
	logger:info(msg);
end

-------------------------------------------------------------------------------------------------
--
-- Error handling
--

function getGUID(obj)	
	return obj:getGuid()
end

function getGUIDStr(obj)
	return tostring(getGUID(obj));
end

function getFinalOwnerGUID(obj)
	if obj == nil then
		logErrorImpl("ai_utils:getFinalOwnerGUID - Nil param given.");
	end

	local finalOwnerInstance = common.CommonUtils.getFinalOwnerInstance(obj);
	if finalOwnerInstance == nil then
		logErrorImpl("ai_utils:getFinalOwnerGUID - No final owner instance found.");
	end
	
	return finalOwnerInstance:getGuid()
end

function getFinalOwnerGUIDStr(obj)
	return tostring(getFinalOwnerGUID(obj));
end

function getType(obj)
	if obj == nil then
		logErrorImpl("ai_utils:getType - Nil param given.");
	end
	
	local type = common.CommonUtils.getTypeManager():getTypeByUH(obj:getType());
	return type;
end

function getTypeName(obj)

	if obj == nil then
		logErrorImpl("ai_utils:getTypeName - Nil param given.");
	end

	local type = getType(obj);
	if type == nil then
		logErrorImpl("ai_utils:getTypeName - No type found.");
	end
	
	return type:getName();
end

function getFinalOwnerType(obj)
	if obj == nil then
		logErrorImpl("ai_utils:getFinalOwnerType - Nil param given.");
	end

	local finalOwnerInstance = common.CommonUtils.getFinalOwnerInstance(obj);
	if finalOwnerInstance == nil then
		logErrorImpl("ai_utils:getFinalOwnerType - No final owner instance found.");
	end
	
	local type = common.CommonUtils.getTypeManager():getTypeByUH(finalOwnerInstance:getType());	
	return type;
end

function getFinalOwnerTypeName(obj)

	if obj == nil then
		logErrorImpl("ai_utils:getFinalOwnerTypeName - Nil param given.");
	end

	local type = getFinalOwnerType(obj);
	if type == nil then
		logErrorImpl("ai_utils:getFinalOwnerTypeName - No type found.");
	end
	
	return type:getName();
end

function getErrorStringForAIInstance(obj)	
	local str = " ( AIType: " .. getFinalOwnerTypeName(obj) .. " , AIInstance: " .. getFinalOwnerGUIDStr(obj) .. " ) ";
	return str;
end
	
-------------------------------------------------------------------------------------------------
--
-- VC3 stuff
--

function getDotWith(a, b)
	return (a.x * b.x) + (a.y * b.y) + (a.z * b.z);
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

function logAIError(obj, msg)
	if obj == nil then
		if msg == nil then
			logErrorImpl("ai_utils:logAIError - Nil obj and msg given.");
		else
			logErrorImpl("ai_utils:logAIError - Nil obj given. Message was: " .. msg);		
		end
		return;
	end
	
	if msg == nil then
		logErrorImpl("ai_utils:logAIError - Nil message given" .. " " .. getErrorStringForAIInstance(obj) .. ".");
		return;
	end
	
	logErrorImpl(msg .. " " .. getErrorStringForAIInstance(obj) .. ".");
end

function logAIWarning(obj, msg)
	if obj == nil then
		if msg == nil then
			logErrorImpl("ai_utils:logAIWarning - Nil obj and msg given.");
		else
			logErrorImpl("ai_utils:logAIWarning - Nil obj given. Message was: " .. msg);		
		end
		return;
	end

	if msg == nil then
		logErrorImpl("ai_utils:logAIWarning - Nil message given" .. " " .. getErrorStringForAIInstance(obj) .. ".");
		return;
	end
	
	logWarningImpl(msg .. " " .. getErrorStringForAIInstance(obj) .. ".");
end

function logAIInfo(obj, msg)
	if obj == nil then
		if msg == nil then
			logErrorImpl("ai_utils:logAIInfo - Nil obj and msg given.");
		else
			logErrorImpl("ai_utils:logAIInfo - Nil obj given. Message was: " .. msg);		
		end
		return;
	end

	if msg == nil then
		logErrorImpl("ai_utils:logAIInfo - Nil message given" .. " " .. getErrorStringForAIInstance(obj) .. ".");
		return;
	end
	
	logInfoImpl(msg .. " " .. getErrorStringForAIInstance(obj) .. ".");
end

function debugPrintPosition(obj, pos)
	if obj == nil then
		logErrorImpl("ai_utils:debugPrintPosition - Nil obj given.");
		return;
	end
	
	if pos == nil then
		logErrorImpl("ai_utils:debugPrintPosition - Nil pos given" .. " " .. getErrorStringForAIInstance(obj) .. ".");
		return;
	end
	
	logInfoImpl("DEBUG, ai_utils - X: " .. tostring(pos.x) .. " Y: " .. tostring(pos.y) .. " Z: " .. tostring(pos.z) " " .. getErrorStringForAIInstance(obj) .. ".");
end

-------------------------------------------------------------------------------------------------
--
-- Get components
--

function getFinalOwnerUnifiedHandle(obj)
	if obj:isInherited(engine.base.ComponentBase.getStaticObjectClass()) and obj.getFinalOwner then
		return obj:getFinalOwner():getUnifiedHandle();
	else
		return obj:getUnifiedHandle();
	end
end

function getFinalOwnerUnifiedHandleByUnifiedHandle(uh)
	local obj = common.CommonUtils.getSceneInstanceByUH(uh);
	if obj ~= nil then
		return getFinalOwnerUnifiedHandle(obj);
	end
	return UH_NONE;
end

function findAllComponentsFromObject(obj, class)
	if obj ~= nil then
		local inst = nil;		
		if obj:isInherited(engine.base.ComponentBase.getStaticObjectClass()) and obj.getFinalOwner then
			inst = obj:getFinalOwner();
		else
			inst = obj;
		end
		
		if inst then
			local componentsIterator = inst:findAllComponents(class);
			if componentsIterator ~= nil then
				return componentsIterator;
			else
				-- Not an error
				return nil;
			end
		else
			logAIError(obj, "ai_utils:findAllComponentsFromObject - Instance is nil.");
			return nil;
		end
	else
		logAIError(obj, "ai_utils:findAllComponentsFromObject - Nil param given.");
		return nil;
	end
	
	return nil;
end

function findAllComponentsFromComponent(comp, class)
	if comp ~= nil then		
		local componentsIterator = comp:findAllComponents(class);
		if componentsIterator ~= nil then
			return componentsIterator;
		else
			-- Not an error
			return nil;
		end
	else
		logAIError(obj, "ai_utils:findAllComponentsFromComponent - Nil param given.");
		return nil;
	end
	logAIError(obj, "ai_utils:findAllComponentsFromComponent - Something went wrong.");
	return nil;
end

function findComponentFromObjectByClass(obj, class)
	if obj ~= nil then
		local inst = nil;		
		if obj:isInherited(engine.base.ComponentBase.getStaticObjectClass()) and obj.getFinalOwner then
			inst = obj:getFinalOwner();
		else
			inst = obj;
		end
		
		if inst ~= nil then
			local comp = inst:findComponentByClass(class);
			if comp ~= nil then
				return comp;
			else
				-- Not an error
				return nil;
			end
		else
			logAIError(obj, "ai_utils:findComponentFromObjectByClassId - Instance is nil.");
			return nil;
		end
	else
		logAIError(obj, "ai_utils:findComponentFromObjectByClassId - Nil param given.");
		return nil;
	end
	logAIError(obj, "ai_utils:findComponentFromObjectByClassId - Something went wrong.");
	return nil;
end

function findSubComponentFromComponentByClass(comp, class)
	if comp ~= nil then		
		local subComp = comp:findComponentByClass(class);
		if subComp ~= nil then
			return subComp;
		else
			return nil;
		end
	else
		logAIError(obj, "ai_utils:findSubComponentFromComponentByClassId - Nil param given.");
		return nil;
	end
	logAIError(obj, "ai_utils:findSubComponentFromComponentByClassId - Something went wrong.");
	return nil;
end

function findStateComponentByNameFromCharacterComponent(obj, stateCollectionName)
	if obj ~= nil then
		local characterComponent = nil;		
		if not obj:isInherited(trinebase.gameplay.TrineCharacterComponent.getStaticObjectClass()) and obj.getOwner then
			characterComponent = obj:getOwner();
		else
			characterComponent = obj;
		end		
		
		if characterComponent then
			local comp = characterComponent:findStateComponentByCollection(stateCollectionName);
			if comp then
				return comp;
			else
				logAIError(obj, "ai_utils:findStateComponentByNameFromCharacterComponent - No " .. stateCollectionName .. " found.");
				return nil;
			end
		else
			logAIError(obj, "ai_utils:findStateComponentByNameFromCharacterComponent - CharacterComponent is missing.");
			return nil;
		end
	else
		logAIError(obj, "ai_utils:findStateComponentByNameFromCharacterComponent - Nil param given.");
		return nil;
	end
	logAIError(obj, "ai_utils:findStateComponentByNameFromCharacterComponent - Something went wrong.");
	return nil;
end

function getHealthComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.damage.HealthComponent.getStaticObjectClass());
end

function getRagdollPhysicsComponent(obj)
	return findComponentFromObjectByClass(obj, physics.RagdollPhysicsComponent.getStaticObjectClass());
end

function getAiStateComponent(obj)
	--return findStateComponentByNameFromCharacterComponent(obj, "AiState");
	local trineCharacterComponent = getTrineCharacterComponent(obj);
	if trineCharacterComponent == nil then
		logAIError(obj, "ai_utils:getAiStateComponent - TrineCharacterComponent is missing.");
		return nil;	
	end
	return trineCharacterComponent:getAIStateComponent();
end

function getMoveStateComponent(obj)
	--return findStateComponentByNameFromCharacterComponent(obj, "MoveState");
	local trineCharacterComponent = getTrineCharacterComponent(obj);
	if trineCharacterComponent == nil then
		logAIError(obj, "ai_utils:getMoveStateComponent - TrineCharacterComponent is missing.");
		return nil;	
	end
	
	return trineCharacterComponent:getMoveStateComponent();
end

function getPhysicsComponent(obj)
	if obj.getFinalOwner then
		return obj:getFinalOwner():getPhysicsComponent();
	else
		return obj:getPhysicsComponent();
	end
end

function getTransformComponent(obj)
	return common.CommonUtils.getFinalOwnerInstance(obj):getTransformComponent();
end


function getTargetComponent(obj)
	if(obj.getFinalOwner) then obj = obj:getFinalOwner(); end
	if(obj.getTargetComponent) then
		return obj:getTargetComponent();
	else
		return findComponentFromObjectByClass(obj, gameplay.TargetComponent.getStaticObjectClass());
	end
end

function getSphereAreaComponent(obj)
	return findComponentFromObjectByClass(obj, area.SphereAreaComponent.getStaticObjectClass());
end

function getEnemyDoEffectComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.effect.EnemyDoEffectComponent.getStaticObjectClass());
end

function getLanternComponent(obj)
	return findComponentFromObjectByClass(obj, trinebase.gameplay.TrineLanternComponent.getStaticObjectClass());
end

function getAICharacterComponent(obj)
	if obj == nil then
		-- Cannot print AI error because obj is nil
		--logAIError(obj, "ai_utils:getAICharacterComponent - Param obj is NIL.");
		logErrorImpl("ai_utils:getAICharacterComponent - Param obj is NIL.");
		return nil;
	end

	if obj.getFinalOwner then
		obj = obj:getFinalOwner();
	end
	
	local cc = obj:getControllerComponent();
	if not cc then
		return nil
	end
	
	return cc:dynamicCast(trinebase.gameplay.ai.TrineAICharacterComponent.getStaticObjectClass());
end

function getTrineCharacterComponent(obj)
	if obj == nil then
		-- Cannot print AI error because obj is nil
		--logAIError(obj, "ai_utils:getAICharacterComponent - Param obj is NIL.");
		logErrorImpl("ai_utils:getAICharacterComponent - Param obj is NIL.");
		return nil;
	end

	if obj.getFinalOwner then
		obj = obj:getFinalOwner();
	end
	
	local cc = obj:getControllerComponent();
	if not cc then
		return nil
	end
	
	return cc:dynamicCast(trinebase.gameplay.TrineCharacterComponent.getStaticObjectClass());
end

function getCharacterComponent(obj)
	if obj == nil then
		logErrorImpl("ai_utils:getCharacterComponent - Param obj is NIL.");
		return nil;
	end

	if obj.getFinalOwner then
		obj = obj:getFinalOwner();
	end
	
	local cc = obj:getControllerComponent();
	if not cc then
		return nil
	end
	
	return cc:dynamicCast(gameplay.CharacterComponent.getStaticObjectClass());
end

function getAnimationComponent(obj)
	if obj.getFinalOwner then
		obj = obj:getFinalOwner();
	end
	return obj:getAnimationComponent();
end

function getCharacterPhysicsComponent(obj)
	if obj.getFinalOwner then
		obj = obj:getFinalOwner();
	end
	return obj:getPhysicsComponent()
end

function getRootMotionComponent(obj)
	if obj.getFinalOwner then
		obj = obj:getFinalOwner();
	end
	
	local pc = obj:getPhysicsComponent();
	if pc ~= nil and pc.getRootMotionJointComponent then
		return pc:getRootMotionJointComponent();
	else
		return nil;
	end
end

function getPlatformerCharacterComponent(obj)
	if obj.getFinalOwner then
		obj = obj:getFinalOwner();
	end
	
	local cc = obj:getControllerComponent();
	if not cc then
		return nil
	end
	
	return cc:dynamicCast(platformer.gameplay.PlatformerCharacterComponent.getStaticObjectClass());
end

function getHittableComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.hit.HittableComponent.getStaticObjectClass());
end

function getAudioComponent(obj)
	return findComponentFromObjectByClass(obj,audio.AudioComponent.getStaticObjectClass());
end

function getAttachEffectComponent(obj)
	return findComponentFromObjectByClass(obj,gameplay.effect.AttachEffectComponent.getStaticObjectClass());
end

function getWeaponComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.weapon.WeaponComponent.getStaticObjectClass());
end

function getWeaponMeleeComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.weapon.MeleeWeaponComponent.getStaticObjectClass());
end

function getAllWeaponMeleeComponents(obj)
	return findAllComponentsFromObject(obj, gameplay.weapon.MeleeWeaponComponent);
end

function getAllWeaponMeleeComponentsFromComponent(obj)
	return findAllComponentsFromComponent(obj, gameplay.weapon.MeleeWeaponComponent);
end

function getWeaponMultiAnimatedWeaponComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.weapon.MultiAnimatedWeaponComponent.getStaticObjectClass());
end

function getAllWeaponAnimatedComponentsFromComponent(obj)
	return findAllComponentsFromComponent(obj, gameplay.weapon.AnimatedWeaponComponent);
end

function getWeaponMultiMeleeComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.weapon.MultiMeleeWeaponComponent.getStaticObjectClass());
end

function getAllWeaponRangedComponentsFromComponent(obj)
	return findAllComponentsFromComponent(obj, gameplay.weapon.RangedWeaponComponent);
end

function getAllWeaponSimpleRangedComponentsFromComponent(obj)
	return findAllComponentsFromComponent(obj, gameplay.weapon.SimpleRangedWeaponComponent);
end

function getWeaponMultiRangedComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.weapon.MultiRangedWeaponComponent.getStaticObjectClass());
end

function getWeaponSwingMeleeComponent(obj)
	return findComponentFromObjectByClass(obj, trinebase.gameplay.weapon.TrineSwingMeleeWeaponComponent.getStaticObjectClass());
end

function getWeaponStabMeleeComponent(obj)
	return findComponentFromObjectByClass(obj, trinebase.gameplay.weapon.TrineStabMeleeWeaponComponent.getStaticObjectClass());
end

function getAttachToHelperComponent(obj)
	return findComponentFromObjectByClass(obj, engine.component.AbstractAttachToHelperComponent.getStaticObjectClass());
end

function getCarnivorousPlantComponent(obj)
	return findComponentFromObjectByClass(obj, trinebase.gameplay.TrineCarnivorousPlantComponent.getStaticObjectClass());
end

function getControllerComponent(obj)
	if(obj.getFinalOwner) then obj = obj:getFinalOwner(); end
	return obj:getControllerComponent();
end

function getModelComponent(obj)
	if(obj.getFinalOwner) then obj = obj:getFinalOwner(); end
	return obj:getModelComponent();
end

function getFluidDamageComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.damage.FluidDamageComponent.getStaticObjectClass());
end

function getExplosiveWeaponComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.weapon.ExplosiveWeaponComponent.getStaticObjectClass());
end

function getExplosiveComponent(obj)
	return findComponentFromObjectByClass(obj, trinebase.gameplay.elements.TrineExplosiveComponent.getStaticObjectClass());
end

function getAllAttachAreaToModelComponents(obj)
	return findAllComponentsFromObject(obj, gameplay.AttachAreaToModelComponent);
end

function getAllExplosiveWeaponComponents(obj)
	-- Loop returning value like this:
	--
	--local iter = getAllExplosiveWeaponComponents(obj);
	--local component = iter:next()
	--while component do
	--	-- Do something...
	--
	--	component = iter:next()
	--end
	return findAllComponentsFromObject(obj, gameplay.weapon.ExplosiveWeaponComponent);
end

function getShieldComponent(obj)
	return findComponentFromObjectByClass(obj, trinebase.gameplay.wear.WearShieldComponent.getStaticObjectClass());
end

function getRangedWeaponComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.weapon.RangedWeaponComponent.getStaticObjectClass());
end

function getTrineFireSweepComponent(obj)
	return findComponentFromObjectByClass(obj, trinebase.gameplay.weapon.TrineFireSweepComponent.getStaticObjectClass());
end

function getTrineFireFlowComponent(obj)
	return findComponentFromObjectByClass(obj, trinebase.gameplay.elements.TrineFireFlowComponent.getStaticObjectClass());
end

function getAttachEffectComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.effect.AttachEffectComponent.getStaticObjectClass());
end

function getAISquashedComponent(obj)
	return findComponentFromObjectByClass(obj, trinebase.gameplay.ai.TrineAISquashedComponent.getStaticObjectClass());
end

function getFootstepsEffectComponent(obj)
	return findComponentFromObjectByClass(obj, trinebase.gameplay.effect.FootstepsEffectComponent.getStaticObjectClass());
end

function getRopeComponent(obj)
	return findComponentFromObjectByClass(obj, trinebase.gameplay.skills.RopeComponent.getStaticObjectClass());
end

function getTimerComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.TimerComponent.getStaticObjectClass());
end

function getTargetComponentTargetToAnimationParamsComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.TargetComponentTargetToAnimationParamsComponent.getStaticObjectClass());
end

function getFloatAndReferenceSelectComponent(obj)
	return findComponentFromObjectByClass(obj, propertyanimation.proputil.FloatAndReferenceSelectComponent.getStaticObjectClass());
end

function getFrozeMeComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.FrozeMeComponent.getStaticObjectClass());
end

function getTrineFrozeMeComponent(obj)
	return findComponentFromObjectByClass(obj, trinebase.gameplay.skills.TrineFrozeMeComponent.getStaticObjectClass());
end

function getTargetPositionToAnimationParamsComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.TargetPositionToAnimationParamsComponent.getStaticObjectClass());
end

function getAttachHitPointsComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.hit.AttachHitPointsComponent.getStaticObjectClass());
end

function getAIFlyingMovementHelperComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.AIFlyingMovementHelperComponent.getStaticObjectClass());
end

function getAIFlyingMovementHelperPointComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.AIFlyingMovementHelperPointComponent.getStaticObjectClass());
end

function getTrineBiteComponent(obj)
	return findComponentFromObjectByClass(obj, trinebase.gameplay.weapon.TrineBiteComponent.getStaticObjectClass());
end

function getTrineStuckInMouthComponent(obj)
	return findComponentFromObjectByClass(obj, trinebase.gameplay.TrineStuckInMouthComponent.getStaticObjectClass());
end

function getAllAnimateModelBoneComponents(obj)
	return findAllComponentsFromObject(obj, gameplay.AnimateModelBoneComponent);
end

function getTrineSpikesComponent(obj)
	return findComponentFromObjectByClass(obj, trinebase.gameplay.elements.TrineSpikesComponent.getStaticObjectClass());
end

function getTrineWyvernAttackTypeInfoComponent(obj)
	return findComponentFromObjectByClass(obj, trinebase.gameplay.ai.TrineWyvernAttackTypeInfoComponent.getStaticObjectClass());
end

function getContactEffectCreatorComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.effect.ContactEffectCreatorComponent.getStaticObjectClass());
end
-------------------------------------------------------------------------------------------------
--
-- Flying AI
--

function hasFlyingTargetAreas(obj, aiFlyingMovementHelperComponent)
	local fmc = aiFlyingMovementHelperComponent;
	if fmc == nil then
		fmc = getAIFlyingMovementHelperComponent(obj);
	end
	
	return fmc:hasInstances();
end

function hasFlyingTargetAreaFlyingPoints(obj, aiFlyingMovementHelperComponent)
	local fmc = aiFlyingMovementHelperComponent;
	if fmc == nil then
		fmc = getAIFlyingMovementHelperComponent(obj);
	end
	
	return fmc:hasHelperEntities();
end

function getClosestFlyingAreaUHToSelf(obj, aiFlyingMovementHelperComponent)
	local fmc = aiFlyingMovementHelperComponent;
	if fmc == nil then
		fmc = getAIFlyingMovementHelperComponent(obj);
	end
	
	if not hasFlyingTargetAreas(obj, fmc) then
		logAIError(obj, "ai_utils:getClosestFlyingAreaUHToSelf - AIFlyingMovementHelperComponent doesn't have any instances.");
		return UH_NONE;
	end
	
	return fmc:getClosestInstanceToSelf();
end

function getClosestFlyingAreaUHToUH(obj, uh, aiFlyingMovementHelperComponent)
	local fmc = aiFlyingMovementHelperComponent;
	if fmc == nil then
		fmc = getAIFlyingMovementHelperComponent(obj);
	end
	
	if not hasFlyingTargetAreas(obj, fmc) then
		logAIError(obj, "ai_utils:getClosestFlyingAreaUHToUH - AIFlyingMovementHelperComponent doesn't have any instances.");
		return UH_NONE;
	end
	
	return fmc:getClosestInstanceToUH(uh);
end

function isInstanceUHInsideOfFlyingAreaUH(targetUH, flyingAreaUH)
	if flyingAreaUH == UH_NONE then
		logAIError(obj, "ai_utils:isInstanceUHInsideOfFlyingAreaUH - flyingAreaUH is UH_NONE.");
		return false;
	end

	local flyingAreaUHInstance = common.CommonUtils.getSceneInstanceByUH(flyingAreaUH);
	if flyingAreaUHInstance == nil then
		logAIError(obj, "ai_utils:isInstanceUHInsideOfFlyingAreaUH - flying area instance doesn't exist.");
		return false;
	end
	
	local fmc = getAIFlyingMovementHelperComponent(flyingAreaUHInstance);
		
	return fmc:isInstanceInsideOfArea(targetUH);
end

function getRandomFlyingPointUHFromFlyingAreaInstance(obj, flyingAreaInstanceUH, fromLeft)
	if flyingAreaInstanceUH == UH_NONE then		
		logAIError(obj, "ai_utils:getRandomFlyingPointUHFromFlyingAreaInstance - flyingAreaInstanceUH is UH_NONE.");
		return UH_NONE;
	end
	
	local flyingAreaInstance = common.CommonUtils.getSceneInstanceByUH(flyingAreaInstanceUH);
	if flyingAreaInstance == nil then
		logAIError(obj, "ai_utils:getRandomFlyingPointUHFromFlyingAreaInstance - flyingAreaInstance doesn't exist.");
		return UH_NONE;
	end
	
	local fmc = getAIFlyingMovementHelperComponent(flyingAreaInstance);
	
	if not hasFlyingTargetAreaFlyingPoints(flyingAreaInstance, fmc) then
		logAIError(obj, "ai_utils:getRandomFlyingPointUHFromFlyingAreaInstance - flyingAreaInstance doesn't have any flying points (on EITHER side).");
		return UH_NONE;
	end
		
	local flyingAreaInstancePos = getOwnPosition(flyingAreaInstance);
	local flyingPointUHList = fmc:getHelperEntities();
	local flyingPointUHListSize = flyingPointUHList:getSize();
	local foundFlyingPoints = { }
	local foundFlyingPointsCount = 0;
	
	-- Init the array (and one extra slot to mark the end
	for i = 1, flyingPointUHListSize + 1 do
		foundFlyingPoints[i] = UH_NONE;
	end
	
	if fromLeft then
		-- Get all points from left
		for i = 0, flyingPointUHList:getSize() - 1 do
			local flyingPointUH = flyingPointUHList:get(i);		
			if flyingPointUH ~= UH_NONE then	
				local flyingPointInstance = common.CommonUtils.getSceneInstanceByUH(flyingPointUH);
				if flyingPointInstance ~= nil then
				
					local flyingPointInstancePos = getInstancePosition(flyingPointInstance);
					if flyingPointInstancePos.x <= flyingAreaInstancePos.x then
						foundFlyingPointsCount = foundFlyingPointsCount + 1;
						foundFlyingPoints[foundFlyingPointsCount] = flyingPointUH;
					end
				end
			end
		end
	else
		-- Get all points from right
		for i = 0, flyingPointUHList:getSize() - 1 do
			local flyingPointUH = flyingPointUHList:get(i);
			if flyingPointUH ~= UH_NONE then
				local flyingPointInstance = common.CommonUtils.getSceneInstanceByUH(flyingPointUH);
				if flyingPointInstance ~= nil then
					local fmhpc = getAIFlyingMovementHelperPointComponent(flyingPointInstance);
					if fmhpc ~= nil and fmhpc:getEnabled() then
						local flyingPointInstancePos = getInstancePosition(flyingPointInstance);
						if flyingPointInstancePos.x >= flyingAreaInstancePos.x then
							foundFlyingPointsCount = foundFlyingPointsCount + 1;
							foundFlyingPoints[foundFlyingPointsCount] = flyingPointUH;
						end
					end
				end
			end
		end
	end
	
	if foundFlyingPointsCount == 0 then
		-- This function shouldn't be used directly so no errors, handle errors where you call this function
		--logAIError(obj, "ai_utils:getRandomFlyingPointUHFromFlyingAreaInstance - Couldn't find any flying points.");
		return UH_NONE;
	end
	
	-- Get random found pos
	local randomIndex = getRandomInt(obj, 1, foundFlyingPointsCount);
		
	for i = 1, foundFlyingPointsCount do	
		if foundFlyingPoints[i] ~= UH_NONE then
			if i >= randomIndex then
				return foundFlyingPoints[i];
			end
		end
	end
	
	-- This function shouldn't be used directly so no errors, handle errors where you call this function
	--local errorMsg = "right";
	--if fromLeft then
	--	errorMsg = "left";
	--end
	--logAIError(obj, "ai_utils:getRandomFlyingPointUHFromFlyingAreaInstance - flyingAreaInstance doesn't have flying points on " .. errorMsg .. ".");
	
	return UH_NONE;
end

function getRandomFlyingPointUHFromFlyingAreaUH(obj, flyingAreaUH, fromLeft, ifNotFoundLookOtherDirection)
	local fmc = aiFlyingMovementHelperComponent;
	if fmc == nil then
		fmc = getAIFlyingMovementHelperComponent(obj);
	end
	
	if flyingAreaUH == UH_NONE then
		logAIError(obj, "ai_utils:getRandomFlyingPointUHFromFlyingAreaUH - flyingAreaUH is UH_NONE.");
		return UH_NONE;
	end
	
	local randomFlyingPointUH = getRandomFlyingPointUHFromFlyingAreaInstance(obj, flyingAreaUH, fromLeft);
	if randomFlyingPointUH == UH_NONE then
		if ifNotFoundLookOtherDirection then
			local lookOtherDirection = not fromLeft;
			randomFlyingPointUH = getRandomFlyingPointUHFromFlyingAreaInstance(obj, flyingAreaUH, lookOtherDirection);
			return randomFlyingPointUH;
		else
			return UH_NONE;
		end
	end
		
	local randomFlyingPointInstance = common.CommonUtils.getSceneInstanceByUH(randomFlyingPointUH);
	if randomFlyingPointInstance == nil then
		logAIError(obj, "ai_utils:getRandomFlyingPointUHFromFlyingAreaUH - flyingpoint instance doesn't exist.");
		return UH_NONE;
	end
	
	-- Finally return the uh
	return randomFlyingPointUH;
end

function getRandomFlyingPointPosFromFlyingAreaUH(obj, flyingAreaUH, fromLeft, ifNotFoundLookOtherDirection)
	local fmc = aiFlyingMovementHelperComponent;
	if fmc == nil then
		fmc = getAIFlyingMovementHelperComponent(obj);
	end
	
	if flyingAreaUH == UH_NONE then
		logAIError(obj, "ai_utils:getRandomFlyingPointPosFromFlyingAreaUH - flyingAreaUH is UH_NONE. Returning AI pos.");
		return getOwnPosition(obj);
	end
	
	local randomFlyingPointUH = getRandomFlyingPointUHFromFlyingAreaInstance(obj, flyingAreaUH, fromLeft);
	if randomFlyingPointUH == UH_NONE then
		if ifNotFoundLookOtherDirection then
			local lookOtherDirection = not fromLeft;
			randomFlyingPointUH = getRandomFlyingPointUHFromFlyingAreaInstance(obj, flyingAreaUH, lookOtherDirection);
			if randomFlyingPointUH == UH_NONE then
				logAIError(obj, "ai_utils:getRandomFlyingPointPosFromFlyingAreaUH - flyingAreaInstance doesn't have flying points on EITHER side. This is clearly a MAJOR error. Returning AI pos.");
				return getOwnPosition(obj);
			end
		else
			local errorMsg = "right";
			if fromLeft then
				errorMsg = "left";
			end
			logAIError(obj, "ai_utils:getRandomFlyingPointPosFromFlyingAreaUH - flyingAreaInstance doesn't have flying points on " .. errorMsg .. " side. Returning AI pos.");
			return getOwnPosition(obj);
		end
	end
		
	local randomFlyingPointInstance = common.CommonUtils.getSceneInstanceByUH(randomFlyingPointUH);
	if randomFlyingPointInstance == nil then
		logAIError(obj, "ai_utils:getRandomFlyingPointPosFromFlyingAreaUH - flyingpoint instance doesn't exist. Returning AI pos.");
		return getOwnPosition(obj);
	end
	
	-- Finally return the found pos
	return getInstancePosition(randomFlyingPointInstance);
end

function getBackgroundPointUHFromFlyingPointInstance(obj)
	local fmhpc = getAIFlyingMovementHelperPointComponent(obj);
	if fmhpc == nil then
		logAIError(obj, "ai_utils:getBackgroundPointUHFromFlyingPointInstance - Flying point is missing AIFlyingMovementHelperPointComponent.");
		return UH_NONE;
	end
	
	local uhList = fmhpc:getToHelperEntities();
	local uhListSize = uhList:getSize();
	
	if uhListSize <= 0 then
		logAIError(obj, "ai_utils:getBackgroundPointUHFromFlyingPointInstance - Flying point's AIFlyingMovementHelperPointComponent doesn't have any background points.");
		return UH_NONE;	
	end
	
	if uhListSize > 1 then
		logAIError(obj, "ai_utils:getBackgroundPointUHFromFlyingPointInstance - TODO: Supports only 1 backround flying point. Returning the first found background point.");
	end
	
	-- TODO: Should check if the backgroundFlyingPointUH is enabled (AIFlyingMovementHelperPointComponent:getEnabled())
	local backgroundFlyingPointUH = uhList:get(0);
	if backgroundFlyingPointUH == UH_NONE then
		logAIError(obj, "ai_utils:getBackgroundPointUHFromFlyingPointInstance - backgroundFlyingPointUH is UH_NONE.");
	end
	
	return backgroundFlyingPointUH;	
end

function getRandomBackgroundPointPosFromFlyingAreaUH(obj, flyingAreaUH, fromLeft, ifNotFoundLookOtherDirection)
	local fmc = aiFlyingMovementHelperComponent;
	if fmc == nil then
		fmc = getAIFlyingMovementHelperComponent(obj);
	end
	
	if flyingAreaUH == UH_NONE then
		logAIError(obj, "ai_utils:getRandomBackgroundPointPosFromFlyingAreaUH - flyingAreaUH is UH_NONE. Returning AI pos.");
		return getOwnPosition(obj);
	end
	
	local randomFlyingPointUH = getRandomFlyingPointUHFromFlyingAreaInstance(obj, flyingAreaUH, fromLeft);
	if randomFlyingPointUH == UH_NONE then
		if ifNotFoundLookOtherDirection then
			local lookOtherDirection = not fromLeft;
			randomFlyingPointUH = getRandomFlyingPointUHFromFlyingAreaInstance(obj, flyingAreaUH, lookOtherDirection);
			if randomFlyingPointUH == UH_NONE then
				logAIError(obj, "ai_utils:getRandomBackgroundPointPosFromFlyingAreaUH - flyingAreaInstance doesn't have flying points on EITHER side. This is clearly a MAJOR error. Returning AI pos.");
				return getOwnPosition(obj);
			end
		else
			local errorMsg = "right";
			if fromLeft then
				errorMsg = "left";
			end
			logAIError(obj, "ai_utils:getRandomBackgroundPointPosFromFlyingAreaUH - flyingAreaInstance doesn't have flying points on " .. errorMsg .. " side. Returning AI pos.");
			return getOwnPosition(obj);
		end
	end
		
	local randomFlyingPointInstance = common.CommonUtils.getSceneInstanceByUH(randomFlyingPointUH);
	if randomFlyingPointInstance == nil then
		logAIError(obj, "ai_utils:getRandomBackgroundPointPosFromFlyingAreaUH - flyingpoint instance doesn't exist. Returning AI pos.");
		return getOwnPosition(obj);
	end
	
	local backgroundPointUH = getBackgroundPointUHFromFlyingPointInstance(randomFlyingPointInstance);
	if backgroundPointUH == UH_NONE then
		logAIError(obj, "ai_utils:getRandomBackgroundPointPosFromFlyingAreaUH - backgroundPointUH is UH_NONE. Returning AI pos.");
		return getOwnPosition(obj);
	end
	
	local backgroundPointInstance = common.CommonUtils.getSceneInstanceByUH(backgroundPointUH);
	if backgroundPointInstance == nil then
		logAIError(obj, "ai_utils:getRandomBackgroundPointPosFromFlyingAreaUH - backgroundPoint instance doesn't exist. Returning AI pos.");
		return getOwnPosition(obj);
	end	
	
	-- Finally return the found pos
	return getInstancePosition(backgroundPointInstance);
end

function isFlyingPointUHOnLeft(flyingPointUH, flyingAreaUH)
	if flyingPointUH == nil or flyingPointUH == UH_NONE then
		logAIError(obj, "ai_utils:isFlyingPointUHOnLeft - flyingPointUH is nil or UH_NONE.");
		return false;
	end
	
	if flyingAreaUH == nil or flyingAreaUH == UH_NONE then
		logAIError(obj, "ai_utils:isFlyingPointUHOnLeft - flyingPointUH is nil or UH_NONE.");
		return false;
	end
	
	local flyingPointInstance = common.CommonUtils.getSceneInstanceByUH(flyingPointUH);
	if flyingPointInstance == nil then
		logAIError(obj, "ai_utils:isFlyingPointUHOnLeft - flyingPointUH instance doesn't exist.");
		return false;
	end
	
	local flyingAreaInstance = common.CommonUtils.getSceneInstanceByUH(flyingAreaUH);
	if flyingAreaInstance == nil then
		logAIError(obj, "ai_utils:isFlyingPointUHOnLeft - flyingAreaUH instance doesn't exist.");
		return false;
	end
	
	local flyingPointPos = getInstancePosition(flyingPointInstance);
	local flyingAreaPos = getInstancePosition(flyingAreaInstance);
	
	return flyingPointPos.x < flyingAreaPos.x;	
end

-------------------------------------------------------------------------------------------------
--
-- Animation
--

function isAnimationContextSet(obj, name, animationComponent)
	local ac = animationComponent;
	if ac == nil then
		ac = getAnimationComponent(obj);
	end
	
	if ac:hasContext(name) then
		return ac:isContextSet(name);
	end
	return false;
end

function setAnimationContextEnabled(obj, name, enabled, animationComponent)
	local ac = animationComponent;
	if animationComponent == nil then
		ac = getAnimationComponent(obj);
	end	
	ac:setContext(name, enabled);
end

function setAnimationContextEnabledForAnimComponent(obj, name, enabled, animationComponent)
	if animationComponent == nil then
		logAIError(obj, "ai_utils:setAnimationContextEnabledForAnimComponent - Given specific animationComponent is nil.");
		return;
	end
	
	if animationComponent:hasContext(name) then
		animationComponent:setContext(name, enabled);
	end
end

function enableAnimationContextOnce(obj, name)	
	getAnimationComponent(obj):enableContextOnce(name);
end

function enableDefaultAnimationContext(obj)
	local ac = getAnimationComponent(obj);
	local defaultContext = ac:getDefaultContext();	
	if string.len(defaultContext) > 0 then
		if ac:hasContext(defaultContext) then
			ac:setContext(defaultContext, true);
		end
	end
end

function disableDefaultAnimationContext(obj)
	local ac = getAnimationComponent(obj);
	local defaultContext = ac:getDefaultContext();	
	if string.len(defaultContext) > 0 then
		if ac:hasContext(defaultContext) then
			ac:setContext(defaultContext, false);
		end
	end
end

function setAnimationContextEnabledIfHasContext(obj, name, enabled, animationComponent)	
	local ac = animationComponent;
	if ac == nil then
		ac = getAnimationComponent(obj);
	end
	
	if ac:hasContext(name) then
		ac:setContext(name, enabled);
	end
end

function enableAnimationContextOnceIfHasContext(obj, name, animationComponent)
	local ac = animationComponent;
	if ac == nil then
		ac = getAnimationComponent(obj);
	end
	
	if ac:hasContext(name) then
		ac:enableContextOnce(name);
	end
end

function clearTypeAnimationContexts(obj)	
	local ac = getAnimationComponent(obj);
	
	if ac:hasContext(cfg_AnimationContextNameType1) then
		ac:setContext(cfg_AnimationContextNameType1, false);
	end
	
	if ac:hasContext(cfg_AnimationContextNameType2) then
		ac:setContext(cfg_AnimationContextNameType2, false);
	end
	
	if ac:hasContext(cfg_AnimationContextNameType3) then
		ac:setContext(cfg_AnimationContextNameType3, false);
	end
	
	if ac:hasContext(cfg_AnimationContextNameType4) then
		ac:setContext(cfg_AnimationContextNameType4, false);
	end
end

function clearHitAnimationContexts(obj)
	local ac = getAnimationComponent(obj);
	
	if ac:hasContext(cfg_AnimationContextNameBack) then
		ac:setContext(cfg_AnimationContextNameBack, false);
	end
	
	if ac:hasContext(cfg_AnimationContextNameImpact) then
		ac:setContext(cfg_AnimationContextNameImpact, false);
	end
	
	if ac:hasContext(cfg_AnimationContextNameArrow) then
		ac:setContext(cfg_AnimationContextNameArrow, false);
	end
	
	if ac:hasContext(cfg_AnimationContextNameDown) then
		ac:setContext(cfg_AnimationContextNameDown, false);
	end
	
	if ac:hasContext(cfg_AnimationContextNameStagger) then
		ac:setContext(cfg_AnimationContextNameStagger, false);
	end
	
	if ac:hasContext(cfg_AnimationContextNameStaggerHammer) then
		ac:setContext(cfg_AnimationContextNameStaggerHammer, false);
	end
end

function isStaggering(obj)
	return isAnimationContextSet(obj, getAnimationContextNameStagger());
end

function isBlocking(obj)
	return isAnimationContextSet(obj, getAnimationContextNameBlocks());
end

function getAnimationParamNameDistance()
	return cfg_AnimationParamNameDistance;
end

function getAnimationParamNameAngle()
	return cfg_AnimationParamNameAngle;
end

function getAnimationParamNameSpeed()
	return cfg_AnimationParamNameSpeed;
end

function getAnimationParamNameHelperAngle()
	return cfg_AnimationParamNameHelperAngle;
end

function getAnimationParamNameHammerAngle()
	return cfg_AnimationParamNameHammerAngle;
end

function getAnimationContextNameSpawn()
	return cfg_AnimationContextNameSpawn;
end

function getAnimationContextNameRight()
	return cfg_AnimationContextNameRight;
end

function getAnimationContextNameLeft()
	return cfg_AnimationContextNameLeft;
end

function getAnimationContextNameType1()
	return cfg_AnimationContextNameType1;
end

function getAnimationContextNameType2()
	return cfg_AnimationContextNameType2;
end

function getAnimationContextNameType3()
	return cfg_AnimationContextNameType3;
end

function getAnimationContextNameType4()
	return cfg_AnimationContextNameType4;
end

function getAnimationContextNameStand()
	return cfg_AnimationContextNameStand;
end

function getAnimationContextNameWalk()
	return cfg_AnimationContextNameWalk;
end

function getAnimationContextNameFall()
	return cfg_AnimationContextNameFall;
end

function getAnimationContextNameFast()
	return cfg_AnimationContextNameFast;
end

function getAnimationContextNameAttack()
	return cfg_AnimationContextNameAttack;
end

function getAnimationContextNameAttack1()
	return cfg_AnimationContextNameAttack1;
end

function getAnimationContextNameAttack1End()
	return cfg_AnimationContextNameAttack1End;
end

function getAnimationContextNameAttack2()
	return cfg_AnimationContextNameAttack2;
end

function getAnimationContextNameAttack2End()
	return cfg_AnimationContextNameAttack2End;
end

function getAnimationContextNameAttackFast()
	return cfg_AnimationContextNameAttackFast;
end

function getAnimationContextNameAttackGoblin()
	return cfg_AnimationContextNameAttackGoblin;
end

function getAnimationContextNameAttackSpit()
	return cfg_AnimationContextNameAttackSpit;
end

function getAnimationContextNameSpotted()
	return cfg_AnimationContextNameSpotted;
end

function getAnimationContextNameIdle()
	return cfg_AnimationContextNameIdle;
end

function getAnimationContextNameBackground1()
	return cfg_AnimationContextNameBackground1;
end

function getAnimationContextNameShoot()
	return cfg_AnimationContextNameShoot;
end

function getAnimationContextNameStagger()
	return cfg_AnimationContextNameStagger;
end

function getAnimationContextNameImpact()
	return cfg_AnimationContextNameImpact;
end

function getAnimationContextNameArrow()
	return cfg_AnimationContextNameArrow;
end

function getAnimationContextNameBack()
	return cfg_AnimationContextNameBack;
end

function getAnimationContextNameDown()
	return cfg_AnimationContextNameDown;
end

function getAnimationContextNameUp()
	return cfg_AnimationContextNameUp;
end

function getAnimationContextNameDie()
	return cfg_AnimationContextNameDie;
end

function getAnimationContextNameBlocked()
	return cfg_AnimationContextNameBlocked;
end

function getAnimationContextNameBlock()
	return cfg_AnimationContextNameBlock;
end

function getAnimationContextNameBlocks()
	return cfg_AnimationContextNameBlocks;
end

function getAnimationContextNameBlockedAttack()
	return cfg_AnimationContextNameBlockedAttack;
end

function getAnimationContextNameGroup()
	return cfg_AnimationContextNameGroup;
end

function getAnimationContextNamePrepare()
	return cfg_AnimationContextNamePrepare;
end

function getAnimationContextNameInterested()
	return cfg_AnimationContextNameInterested;
end

function getAnimationContextNameLevitated()
	return cfg_AnimationContextNameLevitated;
end

function getAnimationContextNameLevitatedFall()
	return cfg_AnimationContextNameLevitatedFall;
end

function getAnimationContextNameLevitatedLand()
	return cfg_AnimationContextNameLevitatedLand;
end

function getAnimationContextNameAttackRight()
	return cfg_AnimationContextNameAttackRight;
end

function getAnimationContextNameAttackLeft()
	return cfg_AnimationContextNameAttackLeft;
end

function getAnimationContextNameStumped()
	return cfg_AnimationContextNameStumped;
end

function getAnimationContextNameBurn()
	return cfg_AnimationContextNameBurn;
end

function getAnimationContextNameAngry()
	return cfg_AnimationContextNameAngry;
end

function getAnimationContextNameSquashed()
	return cfg_AnimationContextNameSquashed;
end

function getAnimationContextNameLedgeAttack()
	return cfg_AnimationContextNameLedgeAttack;
end

function getAnimationContextNameLedgeAttackExecute()
	return cfg_AnimationContextNameLedgeAttackExecute;
end

function getAnimationContextNameLedgeClimbAttack()
	return cfg_AnimationContextNameLedgeClimbAttack;
end

function getAnimationContextNameLedgeDown()
	return cfg_AnimationContextNameLedgeDown;
end

function getAnimationContextNameMoveForward()
	return cfg_AnimationContextNameMoveForward;
end

function getAnimationContextNameMoveBackward()
	return cfg_AnimationContextNameMoveBackward;
end

function getAnimationContextNameTargetVanished()
	return cfg_AnimationContextNameTargetVanished;
end

function getAnimationContextNameFrozen()
	return cfg_AnimationContextNameFrozen;
end

function getAnimationContextNameStaggerHammer()
	return cfg_AnimationContextNameStaggerHammer;
end

function getAnimationContextNameChew()
	return cfg_AnimationContextNameChew;
end

function getAnimationContextNameMoveTo()
	return cfg_AnimationContextNameMoveTo;
end

function getAnimationContextNameMoveFrom()
	return cfg_AnimationContextNameMoveFrom;
end

function getAnimationContextNameSweep()
	return cfg_AnimationContextNameSweep;
end

function getAnimationContextNameCover()
	return cfg_AnimationContextNameCover;
end

function getAnimationContextNameGrab()
	return cfg_AnimationContextNameGrab;
end

function getAnimationContextNameEatPlayer()
	return cfg_AnimationContextNameEatPlayer;
end

function getAnimationContextNameGrabFailed()
	return cfg_AnimationContextNameGrabFailed;
end

function getAnimationContextNameWeapon1()
	return cfg_AnimationContextNameWeapon1;
end

function getAnimationContextNameWeapon2()
	return cfg_AnimationContextNameWeapon2;
end

function getAnimationContextNameWeapon3()
	return cfg_AnimationContextNameWeapon3;
end

function getAnimationContextNameActive()
	return cfg_AnimationContextNameActive;
end

function getAnimationContextNameInActive()
	return cfg_AnimationContextNameInActive;
end

function getAnimationContextNameMoveLeft()
	return cfg_AnimationContextNameMoveLeft;
end

function getAnimationContextNameMoveRight()
	return cfg_AnimationContextNameMoveRight;
end

function getAnimationContextNameStomp()
	return cfg_AnimationContextNameStomp;
end

function getAnimationContextNameStompMoving()
	return cfg_AnimationContextNameStompMoving;
end

function getAnimationContextNameShootDown()
	return cfg_AnimationContextNameShootDown;
end

function getAnimationContextNameReload()
	return cfg_AnimationContextNameReload;
end

function getAnimationContextNameSpin()
	return cfg_AnimationContextNameSpin;
end

function getAnimationContextNameSpinReverse()
	return cfg_AnimationContextNameSpinReverse;
end

function getAnimationContextNameStop()
	return cfg_AnimationContextNameStop;
end

function getAnimationContextNameStationary()
	return cfg_AnimationContextNameStationary;
end

function getAnimationContextNameStationaryEnd()
	return cfg_AnimationContextNameStationaryEnd;
end

function getAnimationContextNameFull()
	return cfg_AnimationContextNameFull;
end

function getAnimationContextNameEmpty()
	return cfg_AnimationContextNameEmpty;
end

function getAnimationContextNameRefill()
	return cfg_AnimationContextNameRefill;
end

function getAnimationContextNameTurret()
	return cfg_AnimationContextNameTurret;
end

function getAnimationContextNameIntro()
	return cfg_AnimationContextNameIntro;
end

function getAnimationContextNameIntroWait()
	return cfg_AnimationContextNameIntroWait;
end

function getAnimationContextNameIntroCloudyIsles()
	return cfg_AnimationContextNameIntroCloudyIsles;
end

function getAnimationContextNameIntroCloudyIslesWait()
	return cfg_AnimationContextNameIntroCloudyIslesWait;
end

-------------------------------------------------------------------------------------------------
--
-- Moving
--

function isDirectionToLeft(obj, platformerCharacterComponent)
	local pc = platformerCharacterComponent;
	if pc == nil then
		pc = getPlatformerCharacterComponent(obj);
	end
	
	return pc:isDirectionToLeft();
end

function isDirectionToRight(obj, platformerCharacterComponent)
	local pc = platformerCharacterComponent;
	if pc == nil then
		pc = getPlatformerCharacterComponent(obj);
	end
	
	return pc:isDirectionToRight();
end

function switchAiPathHelperUHs(obj)
	-- HACK: Switch AI helper UHs
	local aiCC = gameplay.ai.AiUtils.getAICharacterComponent(obj);
	if aiCC ~= nil then
		local aiHelperUH = aiCC:getAiHelperUH();
		local aiPathHelperInvalidUH = aiCC:getAiHelperInvalidUH();
		
		local aiHelperComponent = nil;
		local aiPathHelperInvalidComponent = nil;
		
		if aiHelperUH ~= UH_NONE then
			aiHelperComponent = getAiPathHelperComponentByInstanceUH(aiHelperUH);
		end
		
		if aiPathHelperInvalidUH ~= UH_NONE then
			aiPathHelperInvalidComponent = getAiPathHelperComponentByInstanceUH(aiPathHelperInvalidUH);
		end
		
		-- Use invalid as normal helper?
		if aiPathHelperInvalidComponent ~= nil then
			if aiPathHelperInvalidComponent:getSidewaysDirection() == aiCC:getSidewaysDirection() then
				aiCC:setAiHelperUH(aiPathHelperInvalidUH);
			end
		end
		
		-- Use normal as invalid helper?
		if aiHelperComponent ~= nil then
			if aiHelperComponent:getSidewaysDirection() ~= aiCC:getSidewaysDirection() then
				aiCC:setAiHelperInvalidUH(aiHelperUH);
			end
		end
	end		
end

function setDirectionToLeft(obj)
	if obj:getNetSyncer():hasLocalMaster() then
		local pc = getPlatformerCharacterComponent(obj);
		if not isDirectionToLeft(obj, pc) then
			pc:setDirectionToLeft();
			
			-- HACK: Switch AI helper UHs
			switchAiPathHelperUHs(obj);				
		end
	end
end

function setDirectionToRight(obj)
	if obj:getNetSyncer():hasLocalMaster() then
		local pc = getPlatformerCharacterComponent(obj);
		if not isDirectionToRight(obj, pc) then
			pc:setDirectionToRight();
			
			-- HACK: Switch AI helper UHs
			switchAiPathHelperUHs(obj);
		end
	end
end	

function isMoveState(obj, stateName)
	local comp = getMoveStateComponent(obj);
	if comp then
		if comp:getCurrentState() == stateName then
			return true;
		end
	else
		logAIError(obj, "ai_utils:isMoveState - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
	return false;
end

function moveStateSpawn(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		comp:changeState("Spawn");
	else
		logAIError(obj, "ai_utils:moveStateSpawn - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
end

function moveStatePathHelperAction(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		comp:changeState("PathHelperAction");
	else
		logAIError(obj, "ai_utils:moveStatePathHelperAction - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
end

function isMoveStatePathHelperAction(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		if comp:getCurrentState() == "PathHelperAction" then
			return true;
		end
	else
		logAIError(obj, "ai_utils:isMoveStatePathHelperAction - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
	return false;
end

function moveStateCustom(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		comp:changeState("Custom");
	else
		logAIError(obj, "ai_utils:moveStateCustom - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
end

function moveStateCustomNoError(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		comp:changeState("Custom");
	end
end

function moveStateWaitingForTarget(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		comp:changeState("WaitingForTarget");
	else
		logAIError(obj, "ai_utils:moveStateWaitingForTarget - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
end

function moveStateStop(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		if comp:getCurrentState() ~= "Stand" then
			comp:changeState("Stand");
		end
	else
		logAIError(obj, "ai_utils:moveStateStop - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
end

function moveStateStopDown(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		if comp:getCurrentState() ~= "StandDown" then
			comp:changeState("StandDown");
		end
	else
		logAIError(obj, "ai_utils:moveStateStopDown - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
end

function moveStateStagger(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		if comp:getCurrentState() ~= "Stagger" then
			comp:changeState("Stagger");
		end
	else
		logAIError(obj, "ai_utils:moveStateStagger - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
end

function moveStateStaggerRight(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		if comp:getCurrentState() ~= "StaggerRight" then
			comp:changeState("StaggerRight");
		end
	else
		logAIError(obj, "ai_utils:moveStateStaggerRight - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
end

function moveStateDestroyed(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		if comp:getCurrentState() ~= "Destroyed" then
			comp:changeState("Destroyed");
		end
	else
		logAIError(obj, "ai_utils:moveStateDestroyed - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
end

function moveStateStopUp(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		if comp:getCurrentState() ~= "StandUp" then
			comp:changeState("StandUp");
		end
	else
		logAIError(obj, "ai_utils:moveStateStopUp - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
end

function moveStateIdle(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		comp:changeState("Stand");
	else
		logAIError(obj, "ai_utils:moveStateIdle - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
end

function moveStateStopNoError(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		comp:changeState("Stand");
	end
end

function moveStateIdleNoError(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		comp:changeState("Idle");
	end
end

function moveStateMoveLeft(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		if comp:getCurrentState() ~= "MoveLeft" then
			comp:changeState("MoveLeft");
		end
	else
		logAIError(obj, "ai_utils:moveStateMoveLeft - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
end

function moveStateMoveLeftUp(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		if comp:getCurrentState() ~= "MoveLeftUp" then
			comp:changeState("MoveLeftUp");
		end
	else
		logAIError(obj, "ai_utils:moveStateMoveLeftUp - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
end

function moveStateMoveRight(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		if comp:getCurrentState() ~= "MoveRight" then
			comp:changeState("MoveRight");
		end
	else
		logAIError(obj, "ai_utils:moveStateMoveRight - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
end

function moveStateMoveRightUp(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		if comp:getCurrentState() ~= "MoveRightUp" then
			comp:changeState("MoveRightUp");
		end
	else
		logAIError(obj, "ai_utils:moveStateMoveRightUp - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
end

function moveStateStomp(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		comp:changeState("Stomp");
	else
		logAIError(obj, "ai_utils:moveStateStomp - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
end

function moveStateStompMoving(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		comp:changeState("StompMoving");
	else
		logAIError(obj, "ai_utils:moveStateStomp - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
end

function isMoveStateStop(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		if comp:getCurrentState() == "Stand" then
			return true;
		end
	else
		logAIError(obj, "ai_utils:isMoveStateStop - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
	return false;
end

function moveStateWalk(obj)
	local comp = getMoveStateComponent(obj);
	-- Only master is allowed to change the AI direction
	if comp then
		if comp:getNetSyncer():hasLocalMaster() then
			comp:changeState("Walk");
		end
	else
		logAIError(obj, "ai_utils:moveStateWalk - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
end

function moveStateRight(obj)
	local comp = getMoveStateComponent(obj);
	-- Only master is allowed to change the AI direction
	if comp then
		if comp:getNetSyncer():hasLocalMaster() then
			comp:changeState("WalkRight");
		end
	else
		logAIError(obj, "ai_utils:moveStateRight - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
end

function moveStateLeft(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		-- Only master is allowed to change the AI direction
		if comp:getNetSyncer():hasLocalMaster() then
			comp:changeState("WalkLeft");
		end
	else
		logAIError(obj, "ai_utils:moveStateLeft - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
end

function isMoveStateRight(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		if comp:getCurrentState() == "WalkRight" then
			return true;
		end
	else
		logAIError(obj, "ai_utils:isMoveStateRight - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
	return false;
end

function isMoveStateLeft(obj)
	local comp = getMoveStateComponent(obj);
	if comp then
		if comp:getCurrentState() == "WalkLeft" then
			return true;
		end
	else
		logAIError(obj, "ai_utils:isMoveStateLeft - MoveStateComponent is missing. Either AI doesn't have the component or it shouldn't even support moving?");
	end
	return false;
end

function moveStateSetDirectionToOtherDirection(obj)
	if not isDirectionToRight(obj) then
		setDirectionToRight(obj);
	else
		setDirectionToLeft(obj);
	end
end

function moveStateSetDirectionTowardsTarget(obj)
	if hasTarget(obj) then
		if(isTargetOnLeft(obj)) then
			if isDirectionToRight(obj) then
				setDirectionToLeft(obj);
			end
			return true;
		else
			if not isDirectionToRight(obj) then
				setDirectionToRight(obj);
			end
			return true;
		end
	else
		logAIError(obj, "ai_utils:moveStateSetDirectionTowardsTarget - Cannot set direction towards target, no target specified.");
	end
	return false;
end

function moveStateToOtherDirection(obj)
	if isMoveStateLeft(obj) or not isDirectionToRight(obj) then
		moveStateRight(obj);
	elseif isMoveStateRight(obj) or isDirectionToRight(obj) then
		moveStateLeft(obj);
	end
end

function moveStateToSameDirection(obj)
	if isMoveStateLeft(obj) or not isDirectionToRight(obj) then
		moveStateLeft(obj);
	elseif isMoveStateRight(obj) or isDirectionToRight(obj) then
		moveStateRight(obj);
	end
end

function setMovingTowardsTarget(obj, targetComponent, ignoreMinDistanceToTarget)
	local tc = targetComponent;
	
	if tc == nil then	
		tc = getTargetComponent(obj);
	end
	
	if hasTarget(obj, tc) then
		local moveTowardsTarget = true;
		
		-- If target is too close, don't walk towards the target, just turn towards the target!
		if ignoreMinDistanceToTarget then
			-- Just ignore
		else
			local minDistToTarget = getInstanceType(obj):getMinDistanceToTarget();
			if minDistToTarget > 0 then
				if isTargetOnSamePlatform(obj, tc, 2) then
					local targetDistSq = getTargetHeightFlattenedDistanceSq(obj, tc);
					if targetDistSq <= (minDistToTarget * minDistToTarget) then
						moveTowardsTarget = false;
					end
				end
			end		
		end

		if(isTargetOnLeft(obj, tc)) then		
			if moveTowardsTarget then
				moveStateLeft(obj);
			else
				moveStateStop(obj);
				setDirectionToLeft(obj);
			end
			return true;
		else
			if moveTowardsTarget then
				moveStateRight(obj);
			else
				moveStateStop(obj);
				setDirectionToRight(obj);
			end
			return true;
		end
	else
		-- Not an error
		--logAIError(obj, "ai_utils:setMovingTowardsTarget - Cannot move towards target, no target specified.");
	end
	return false;
end

function setMovingOppositeToTarget(obj)
	if hasTarget(obj) then
		if(isTargetOnLeft(obj)) then
			moveStateRight(obj);
			return true;
		else
			moveStateLeft(obj);
			return true;
		end
	else
		logAIError(obj, "ai_utils:setMovingOppositeToTarget - Cannot move towards target, no target specified.");
	end
	return false;
end

-------------------------------------------------------------------------------------------------
--
-- HealthComponent
--

function setImmortal(obj)
	local hc = getHealthComponent(obj);
	if not hc:getImmortal() then
		hc:setImmortal(true);
	end
end

function setMortal(obj)
	local hc = getHealthComponent(obj);
	if hc:getImmortal() then
		hc:setImmortal(false);
	end
end

-------------------------------------------------------------------------------------------------
--
-- Misc
--

function isState(comp, stateName)
	if comp:getCurrentState() == stateName then
		return true;
	end
	return false;
end

function isAIActive(obj)
	return getAICharacterComponent(obj):getAiActive();
end

function setAIActive(obj)
	local aiCharacterComponent = getAICharacterComponent(obj);
	if not aiCharacterComponent:getAiActive() then
		aiCharacterComponent:setAiActive(true);
	end
end

function isAIEnabled(obj)
	return getAICharacterComponent(obj):getAiEnabled();
end

function enableAI(obj)
	logAIError(obj, "ai_utils:enableAI - Not supported. Engine handles this property.");
	
	--[[
	if not hasLocalMaster(obj) then
		return;
	end
	
	local comp = getAICharacterComponent(obj);
	if not comp:getAiEnabled() then
		comp:setAiEnabled(true);
	end
	]]--
end

function disableAI(obj)
	logAIError(obj, "ai_utils:disableAI - Not supported. Engine handles this property.");
	
	--[[
	if not hasLocalMaster(obj) then
		return;
	end

	local comp = getAICharacterComponent(obj);
	if comp:getAiEnabled() then
		comp:setAiEnabled(false);
	end
	]]--
end

function setAIDestroyed(obj, val)
	local comp = getAICharacterComponent(obj);
	if comp then
		comp:setAiDestroyed(val);
	end
end

function playAudioEvent(obj, event)
	local audioComponent = getAudioComponent(obj);
	
	if audioComponent then
		audioComponent:postEventLua(event)
	else
		logError("ai_utils.lua:playAudioEvent - no audio component found")
	end
end

-------------------------------------------------------------------------------------------------
--
-- Physics
--

function isOnGround(obj)
	local pc = getCharacterPhysicsComponent(obj);
	if pc == nil then
		return false;
	end
	return pc:isOnGround();
end

function getGroundUH(obj)
	local pc = getCharacterPhysicsComponent(obj);
	if pc == nil then
		return UH_NONE;
	end
	return pc:getGroundUH();
end

function getLastCeilingContactDynamicUH(obj)
	return getCharacterPhysicsComponent(obj):getLastCeilingContactDynamicUH();
end

function getLastCeilingContactStaticUH(obj)
	return getCharacterPhysicsComponent(obj):getLastCeilingContactStaticUH();
end

function getLastLeftContactDynamicUH(obj)
	return getCharacterPhysicsComponent(obj):getLastLeftContactDynamicUH();
end

function getLastLeftContactStaticUH(obj)
	return getCharacterPhysicsComponent(obj):getLastLeftContactStaticUH();
end

function getLastRightContactDynamicUH(obj)
	return getCharacterPhysicsComponent(obj):getLastRightContactDynamicUH();
end

function getLastRightContactStaticUH(obj)
	return getCharacterPhysicsComponent(obj):getLastRightContactStaticUH();
end

function removeUnnecessaryComponentsOnDestroyed(obj)
	if not obj:getNetSyncer():hasLocalMaster() then
		return false;
	end
	
	local finalOwner = common.CommonUtils.getFinalOwnerInstance(obj);
	if finalOwner == nil then
		logAIError(obj, "ai_utils:removeUnnecessaryComponentsOnDestroyed - Final owner is nil.");
		return false;
	end
	
	-- Disable collision
	local modelComponent = getModelComponent(obj);
	if modelComponent ~= nil then
		modelComponent:setCollisionEnabled(false);
	end
	
	local fluidDamageComponent = getFluidDamageComponent(obj);
	if fluidDamageComponent ~= nil then
		common.CommonUtils.getSceneInstanceManager():deleteInstance(fluidDamageComponent:getUnifiedHandle()); -- Cannot delete instantly (may cause crash because if the FluidDamageComponent is the killer, it tries to delete itself)
	end
	
	local physicsContactDamageToSelfComponent = getPhysicsContactDamageToSelfComponent(obj);
	if physicsContactDamageToSelfComponent ~= nil then
		common.CommonUtils.getSceneInstanceManager():deleteInstance(physicsContactDamageToSelfComponent:getUnifiedHandle()); -- Cannot delete instantly (may cause crash because if the PhysicsContactDamageToSelfComponent is the killer, it tries to delete itself)
	end
	
	local aiSquashedComponent = getAISquashedComponent(obj);
	if aiSquashedComponent ~= nil then
		common.CommonUtils.getSceneInstanceManager():deleteInstance(aiSquashedComponent:getUnifiedHandle()); -- Cannot delete instantly (may cause crash because if the AISquashedComponent is the killer, it tries to delete itself)
	end
	
	local footstepsEffectComponent = getFootstepsEffectComponent(obj);
	if footstepsEffectComponent ~= nil then
		common.CommonUtils.getSceneInstanceManager():deleteInstance(footstepsEffectComponent:getUnifiedHandle()); 
	end
	
	return true;
end

function hasRagdoll(obj)	
	local aiCharacterComponent = getAICharacterComponent(obj);
	if aiCharacterComponent == nil then
		logAIError(obj, "ai_utils:hasRagdoll - AICharacterComponent is nil.");
		return false;
	end
	
	local ragdollTypeUH = aiCharacterComponent:getRagdollTypeUH();
	if ragdollTypeUH == UH_NONE then
		return false;
	end
	
	return true;
end

function createRagdoll(obj)
	if not obj:getNetSyncer():hasLocalMaster() then
		return false;
	end

	local finalOwner = common.CommonUtils.getFinalOwnerInstance(obj);
	if finalOwner == nil then
		logAIError(obj, "ai_utils:createRagdoll - Final owner is nil.");
		return false;
	end
	
	local aiCharacterComponent = getAICharacterComponent(obj);
	if aiCharacterComponent == nil then
		logAIError(obj, "ai_utils:createRagdoll - AICharacterComponent is nil.");
		return false;
	end
	
	local ragdollTypeUH = aiCharacterComponent:getRagdollTypeUH();
	if ragdollTypeUH == UH_NONE then
		logAIWarning(obj, "ai_utils:createRagdoll - Ragdoll type UH is missing from the  AICharacterComponent.");
		return false;
	end
	
	local ragdollType = common.CommonUtils.getTypeManager():getTypeByUH(ragdollTypeUH);
	if ragdollType == nil then
		logAIError(obj, "ai_utils:createRagdoll - No such radgoll type found with given UH.");
		return false;
	end
	
	local physicsComponent = getPhysicsComponent(obj);
	if physicsComponent ~= nil then
		if(physicsComponent:getType() == ragdollType:getUnifiedHandle()) then
			logAIError(obj, "ai_utils:createRagdoll - Trying to create ragdoll when already has one.");
			return false;
		end
	end
	
	local attachToHelperComponent = getAttachToHelperComponent(obj);
	if attachToHelperComponent ~= nil then
		common.CommonUtils.getSceneInstanceManager():deleteInstanceInstantly(attachToHelperComponent:getUnifiedHandle()); -- Could be removed delayed
	end
	
	local rootMotionComponent = getRootMotionComponent(obj);
	if rootMotionComponent ~= nil then
		common.CommonUtils.getSceneInstanceManager():deleteInstanceInstantly(rootMotionComponent:getUnifiedHandle()); -- Could be removed delayed
	end
	
	local velocity = VC3(0,0,0);
	if physicsComponent ~= nil then
		velocity = physicsComponent:getLinearVelocity();
		
		 -- NOTE: Instant delete may cause crashes? PhysicsComponent and RagdollPhysicsComponent cannot exist at the same time but they need to be deleted and added in same frame (that dying is smooth)
		common.CommonUtils.getSceneInstanceManager():deleteInstanceInstantly(physicsComponent:getUnifiedHandle());
	end

	function initRagdollComponent(comp, velocity)
	  comp:setLinearVelocity(velocity);
	  comp:updateBoneVelocitiesFromAnimation();
	end
	common.CommonUtils.getSceneInstanceManager():createNewComponentInstantly(ragdollType:getUnifiedHandle(), finalOwner, initRagdollComponent, velocity);

	local ragdollBuoyancyTypeUH = aiCharacterComponent:getRagdollBuoyancyTypeUH();
	if ragdollBuoyancyTypeUH == UH_NONE then
		logAIWarning(obj, "ai_utils:createRagdoll - Ragdoll buoyancy type UH is missing from the  AICharacterComponent.");
		return false;
	end
	
	local ragdollBuoyancyType = common.CommonUtils.getTypeManager():getTypeByUH(ragdollBuoyancyTypeUH);
	if ragdollBuoyancyType == nil then
		logAIError(obj, "ai_utils:createRagdoll - No such radgoll buoyancy type found with given UH.");
		return false;
	end

	common.CommonUtils.getSceneInstanceManager():createNewComponentInstantly(ragdollBuoyancyType:getUnifiedHandle(), finalOwner, function() end, nil);

	local ragdollEffectsTypeUH = aiCharacterComponent:getRagdollEffectsTypeUH()
	if ragdollEffectsTypeUH ~= UH_NONE then
		local ragdollEffectsType = common.CommonUtils.getTypeManager():getTypeByUH(ragdollEffectsTypeUH)
		if ragdollEffectsType == nil then
			logAIError(obj, "ai_utils:createRagdoll - No such radgoll effects type found with given UH.")
			return false
		end
		common.CommonUtils.getSceneInstanceManager():createNewComponentInstantly(ragdollEffectsType:getUnifiedHandle(), finalOwner, function() end, nil);
	end

    -- Hax to get Mobile Goblin Archer ragdoll to show //CH
	getModelComponent(obj):setVisibleInGame(true);
	
	return true;
end

-------------------------------------------------------------------------------------------------
--
-- Events
--

function enablePhysicsEventsDynamic(obj, val)
	local comp = getAICharacterComponent(obj);
	if comp then
		if comp:getEventPhysicsContactDynamicAbove() ~= val then
			comp:setEventPhysicsContactDynamicAbove(val);
		end
		if comp:getEventPhysicsContactDynamicLeft() ~= val then
			comp:setEventPhysicsContactDynamicLeft(val);
		end
		if comp:getEventPhysicsContactDynamicRight() ~= val then
			comp:setEventPhysicsContactDynamicRight(val);
		end
	end
end

function enablePhysicsEventsStatic(obj, val)
	local comp = getAICharacterComponent(obj);
	if comp then
		if comp:getEventPhysicsContactStaticAbove() ~= val then
			comp:setEventPhysicsContactStaticAbove(val);
		end
		if comp:getEventPhysicsContactStaticLeft() ~= val then
			comp:setEventPhysicsContactStaticLeft(val);
		end
		if comp:getEventPhysicsContactStaticRight() ~= val then
			comp:setEventPhysicsContactStaticRight(val);
		end
	end
end

function enablePhysicsEventsLanding(obj, val)
	local comp = getAICharacterComponent(obj);
	if comp then
		if comp:getEventLand() ~= val then
			comp:setEventLand(val);
		end
		if comp:getEventPredictLanding() ~= val then
			comp:setEventPredictLanding(val);
		end
	end
end

function enablePhysicsEventFall(obj, val)
	local comp = getAICharacterComponent(obj);
	if comp then
		if comp:getEventFall() ~= val then
			comp:setEventFall(val);
		end
	end
end

function enablePhysicsEvents(obj, val)
	enablePhysicsEventsDynamic(obj, val);
	enablePhysicsEventsStatic(obj, val);
	enablePhysicsEventsLanding(obj, val);
end

-------------------------------------------------------------------------------------------------
--
-- Targeting
--

function setClosestPlayerAsTarget(obj, useMinVisionRange, maxDistance, targetComponent)
	local playerFound = false
	local closestPlayerDistSq = 999999999999
	local playerUH = UH_NONE
	
	local tc = targetComponent;	
	if tc == nil then	
		tc = getTargetComponent(obj);
	end
	
	local sce = common.CommonUtils.getScene()
	
	if not sce then
		logAIError(obj, "ai_utils:setClosestPlayerAsTarget - Scene is nil")
		return false;
	end
	
	-- Add players
	local characterManager = common.CommonUtils.getCharacterSelectionManager()
	local playerCharacters = { }
	if characterManager then
		playerCharacters = {
			characterManager:getCharacterInstanceForPlayer(0), 
			characterManager:getCharacterInstanceForPlayer(1), 
			characterManager:getCharacterInstanceForPlayer(2)
		}
	end
	
	local myPos = getOwnPosition(obj);
	
	-- Get closest player
	for key, playerInstance in pairs(playerCharacters) do
		if playerInstance ~= nil then
		
			local ignore = false;
			local cc = playerInstance:getControllerComponent()
			if(cc and cc.getInvisibilityComponent) then
				local invisibilityComponent = cc:getInvisibilityComponent();
				if invisibilityComponent ~= nil then
					if invisibilityComponent:getEnabled() then -- Don't allow players which are invisible
						ignore = true;
					end
				end
			end
			
			if not ignore then
				local tfc = playerInstance:getTransformComponent();
				if tfc ~= nil then			
					local playerPos = tfc:getPosition();
					local myPosFixed = VC3(myPos.x, playerPos.y, myPos.z);
					local dir = playerPos - myPosFixed;
					local distSq = dir:getSquareLength();
					
					if distSq < closestPlayerDistSq then
						closestPlayerDistSq = distSq;
						playerUH = playerInstance:getUnifiedHandle();
					end
				end
			end
		end
	end
	
	if playerUH == UH_NONE then	
		--logAIWarning(obj, "ai_utils:setClosestPlayerAsTarget - Didn't find any player instances.");
		return false;
	end
	
	-- Is player near enough?
	-- Use Max vision area here, TrineTargetComponent::trineCharacterSpawn uses it also
	local visionRange = 1.0;
	
	
	if maxDistance ~= nil then
		visionRange = maxDistance;
	else
		-- By default, use VisionMaxRange
		if useMinVisionRange ~= nil and useMinVisionRange then
			visionRange = getVisionMinRange(obj, tc);
		else
			visionRange = getVisionMaxRange(obj, tc);
		end
	end
	
	local maxDistSq = visionRange * visionRange;

	if closestPlayerDistSq < maxDistSq and tc:getTarget() ~= playerUH then	
		if setTarget(obj, playerUH, tc) then
			return true;
		end
	end
	
	return false;
end

function isClosestPlayerOnleft(obj)
	local playerFound = false
	local closestPlayerDistSq = 999999999999
	local closestPlayerPos = VC3(0,0,0);
	local playerUH = UH_NONE
		
	local sce = common.CommonUtils.getScene()
	
	if not sce then
		logAIError(obj, "ai_utils:isClosestPlayerOnleft - Scene is nil")
	
		-- By default, true
		return true;
	end
	
	-- Add players
	local characterManager = common.CommonUtils.getCharacterSelectionManager()
	local playerCharacters = { }
	if characterManager then
		playerCharacters = {
			characterManager:getCharacterInstanceForPlayer(0), 
			characterManager:getCharacterInstanceForPlayer(1), 
			characterManager:getCharacterInstanceForPlayer(2)
		}
	end
	
	local myPos = getOwnPosition(obj);
	
	-- Get closest player
	for key, playerInstance in pairs(playerCharacters) do
		if playerInstance ~= nil then
			local tfc = playerInstance:getTransformComponent();
			if tfc ~= nil then			
				local playerPos = tfc:getPosition();
				local myPosFixed = VC3(myPos.x, playerPos.y, myPos.z);
				local dir = playerPos - myPosFixed;
				local distSq = dir:getSquareLength();
				
				if distSq < closestPlayerDistSq then
					closestPlayerDistSq = distSq;
					closestPlayerPos = playerPos;
					playerUH = playerInstance:getUnifiedHandle();
				end
			end
		end
	end
	
	if playerUH == UH_NONE then		
		-- By default, true
		return true;
	end

	if closestPlayerPos.x < myPos.x then
		return true;
	else
		return false;
	end
	
	-- By default, true
	return true;
end

function getWizardWhichLevitatesMe(obj)
	local playerFound = false;
	local playerUH = UH_NONE;
	
	local sce = common.CommonUtils.getScene();
	
	if not sce then
		logAIError(obj, "ai_utils:getWizardWhichLevitatesMe - Scene is nil");
		return UH_NONE;
	end
	
	-- Add players
	local characterManager = common.CommonUtils.getCharacterSelectionManager();
	local playerCharacters = { }
	if characterManager then
		playerCharacters = {
			characterManager:getCharacterInstanceForPlayer(0), 
			characterManager:getCharacterInstanceForPlayer(1), 
			characterManager:getCharacterInstanceForPlayer(2)
		}
	end
	
	for key, playerInstance in pairs(playerCharacters) do
		if playerInstance ~= nil then
			local fjc = playerInstance:findComponent(trinebase.physics.WizardFloatingJointComponent);
			if fjc ~= nil then
				local target = fjc:getTarget();
				if target ~= UH_NONE and fjc:getEnabled() and fjc:getActive() then
					local levitatedFinalOwnerUH = getFinalOwnerUnifiedHandleByUnifiedHandle(target);
					local aiFinalOwnerUH = getFinalOwnerUnifiedHandle(obj);
					if levitatedFinalOwnerUH == aiFinalOwnerUH then
						return playerInstance:getUnifiedHandle();
					end
				end
			end		
		end
	end
	return UH_NONE;
end

function isMyTargetThiefWhichHasVanishedEnabled(obj)
	local playerFound = false
	local playerUH = UH_NONE;
	
	local target = getTarget(obj);
	if target == UH_NONE then
		logAIError(obj, "ai_utils:getWizardWhichLevitatesMe - AI doesn't have target. Cannot determine anything.");
		return false;
	end
	
	local sce = common.CommonUtils.getScene();
	
	if not sce then
		logAIError(obj, "ai_utils:isMyTargetThiefWhichHasVanishedEnabled - Scene is nil");
		return false;
	end
	
	-- Add players
	local characterManager = common.CommonUtils.getCharacterSelectionManager();
	local playerCharacters = { }
	if characterManager then
		playerCharacters = {
			characterManager:getCharacterInstanceForPlayer(0), 
			characterManager:getCharacterInstanceForPlayer(1), 
			characterManager:getCharacterInstanceForPlayer(2)
		}
	end

	for key, playerInstance in pairs(playerCharacters) do
		if playerInstance ~= nil then
			local cc = playerInstance:getControllerComponent()
			if(cc and cc.getInvisibilityComponent) then
				local invisibilityComponent = cc:getInvisibilityComponent(); -- NOTE: Only Thief should have this
				if invisibilityComponent ~= nil then
					if invisibilityComponent:getEnabled() then
						if target == playerInstance:getUnifiedHandle() then
							return true;
						end
					end
				end
			end
		end
	end
	return false;
end

function enableTargetSetting(obj)
	getTargetComponent(obj):setTargetSettingEnabled(true);
end

function disableTargetSetting(obj)
	getTargetComponent(obj):setTargetSettingEnabled(false);
end

function setTarget(obj, target, targetComponent)
	local tc = targetComponent;
	
	if tc == nil then	
		tc = getTargetComponent(obj);
	end
	
	--[[
	if obj == nil then
		logAIError(obj, "ai_utils:setTarget - Param obj is nil.");
		return false;
	end
	
	if target == nil then
		logAIError(obj, "ai_utils:setTarget - Param target is nil.");
		return false;
	end
	
	if tc == nil then
		logAIError(obj, "ai_utils:setTarget - TargetComponent is missing.");
		return false;
	end
	]]--
	
	if(tc:getTarget() ~= target) then
		tc:setTarget(target);
	end
	
	if hasTarget(obj, tc) then
		return true;
	end
	
	return false;
end

function getTarget(obj)
	return getTargetComponent(obj):getTarget();
end

function clearTarget(obj)
	getTargetComponent(obj):clearTarget();
end

function setCustomTargetPosEnabled(obj, enabled)
	getTargetComponent(obj):setCustomTargetPosEnabled(enabled);
end

function getCustomTargetPosEnabled(obj)
	return getTargetComponent(obj):getCustomTargetPosEnabled();
end

function setCustomTargetPos(obj, customTargetPos)
	getTargetComponent(obj):setCustomTargetPos(customTargetPos);
end

function getCustomTargetPos(obj)
	return getTargetComponent(obj):getCustomTargetPos();
end

function clearPossibleInvalidTarget(obj)
	local tc = getTargetComponent(obj);	
	if tc:getTarget() ~= UH_NONE then
		if not tc:hasValidTarget() then
			tc:clearTarget();
		end
	end
end

function hasTarget(obj, targetComponent)
	local tc = targetComponent;
	
	if tc == nil then	
		tc = getTargetComponent(obj);
	end
		
	if tc then
		if tc:hasTarget() then
			return tc:hasValidTarget();
		else
			return false;
		end
	else
		logAIError(obj, "ai_utils:hasTarget - TargetComponent is missing.");
		return false;
	end
	
	logAIError(obj, "ai_utils:hasTarget - Something wen't wrong.");
	return false;
end

function hasValidTarget(obj, targetComponent)
	local tc = targetComponent;
	
	if tc == nil then	
		tc = getTargetComponent(obj);
	end
		
	return tc:hasValidTarget();
end

function hasLineOfSightToTarget(obj, targetComponent)
	local tc = targetComponent;
	
	if tc == nil then	
		tc = getTargetComponent(obj);
	end

	return tc:hasLineOfSightToTarget();
end

function isTargetOnLeft(obj, targetComponent)
	local tc = targetComponent;
	
	if tc == nil then	
		tc = getTargetComponent(obj);
	end

	return tc:isTargetOnLeft();
end

function isTargetOnLookDirection(obj, targetComponent)
	local tc = targetComponent;
	
	if tc == nil then	
		tc = getTargetComponent(obj);
	end

	if isDirectionToRight(obj) then
		return not tc:isTargetOnLeft();
	else
		return tc:isTargetOnLeft();	
	end
end

function getVisionMinRange(obj, targetComponent)
	local tc = targetComponent;
	
	if tc == nil then	
		tc = getTargetComponent(obj);
	end

	return tc:getVisionMinRange();
end

function getVisionMaxRange(obj, targetComponent)
	local tc = targetComponent;
	
	if tc == nil then	
		tc = getTargetComponent(obj);
	end

	return tc:getVisionMaxRange();
end

function getTargetPos(obj, targetComponent)
	local tc = targetComponent;
	
	if tc == nil then	
		tc = getTargetComponent(obj);
	end
	
	if tc:getTarget() == UH_NONE then
		logAIError(obj, "AiUtils.getTargetPos - No valid target.");
	end

	-- Returns position with offset
	return tc:getTargetPos();
end

function getTargetPosActual(obj, targetComponent)
	local tc = targetComponent;
	
	if tc == nil then	
		tc = getTargetComponent(obj);
	end

	-- Return actual instance position
	return tc:getTargetPosActual();
end

function isValidPossibleTargetUH(obj, uh, targetComponent)
	local tc = targetComponent;
	
	if tc == nil then	
		tc = getTargetComponent(obj);
	end

	return tc:isValidPossibleTargetUH(uh);
end

function getClosestSpottedTarget(obj, targetComponent)
	local tc = targetComponent;
	
	if tc == nil then	
		tc = getTargetComponent(obj);
	end

	return tc:getClosestSpottedTarget();
end

function getTargetDistanceSq(obj, targetComponent)
	local tc = targetComponent;
	
	if tc == nil then	
		tc = getTargetComponent(obj);
	end

	if not hasTarget(obj, tc) then
		logAIError(obj, "ai_utils:getTargetDistanceSq - No target specified.");
		return 0.0;
	end
	return tc:getTargetDistanceSq();
end

function getTargetDistanceSqAdjustedByVelocity(obj, velocityWeight)
	if not hasTarget(obj) then
		logAIError(obj, "ai_utils:getTargetDistanceSqAdjustedByVelocity - No target specified.");
		return 0.0;
	end
	return getTargetComponent(obj):getTargetDistanceSqAdjustedByVelocity(velocityWeight);
end

function getTargetHeightFlattenedDistanceSq(obj, targetComponent)
	local tc = targetComponent;
	
	if tc == nil then	
		tc = getTargetComponent(obj);
	end
	
	if not hasTarget(obj, tc) then
		logAIError(obj, "ai_utils:getTargetHeightFlattenedDistanceSq - No target specified.");
		return 0.0;
	end
	return tc:getTargetHeightFlattenedDistanceSq();
end

function getTargetHeightFlattenedDistanceSqAdjustedByVelocity(obj, velocityWeight, targetComponent)
	local tc = targetComponent;
	
	if tc == nil then	
		tc = getTargetComponent(obj);
	end
	if not hasTarget(obj, tc) then
		logAIError(obj, "ai_utils:getTargetHeightFlattenedDistanceSqAdjustedByVelocity - No target specified.");
		return 0.0;
	end
	return tc:getTargetHeightFlattenedDistanceSqAdjustedByVelocity(velocityWeight);
end

function setClosestSpottedTargetAsTarget(obj, targetComponent)
	local tc = targetComponent;
	
	if tc == nil then	
		tc = getTargetComponent(obj);
	end
	
	if tc == nil then
		logAIError(obj, "ai_utils:setClosestSpottedTargetAsTarget - TargetComponent missing.");
		return false;
	end
	
	local closestSpottedTarget = tc:getClosestSpottedTarget();
	
	if closestSpottedTarget ~= UH_NONE then
		if tc:getTarget() ~= closestSpottedTarget then
			if setTarget(obj, closestSpottedTarget, tc) then
				return true;
			end
		end
	end
	
	return false;
end

function setHighestSpottedTargetAsTarget(obj, maxDistance)
	local targetComponent = getTargetComponent(obj);
	local highestSpottedTarget = targetComponent:getHighestSpottedTargetIncludeCurrentTargetWithinMaxDistance(maxDistance);
	
	if highestSpottedTarget ~= UH_NONE then
		if targetComponent:getTarget() ~= highestSpottedTarget then
			if setTarget(obj, highestSpottedTarget, targetComponent) then
				return true;
			end
		end
	end
	
	return hasTarget(obj);
end

function setClosestSpottedTargetAsTargetIfDiffersFromCurrentTarget(obj)
	local targetComponent = getTargetComponent(obj);
	local closestSpottedTarget = targetComponent:getClosestSpottedTarget();
	
	if closestSpottedTarget ~= UH_NONE then
		local target = targetComponent:getTarget();
		if target ~= closestSpottedTarget then
			if setTarget(obj, closestSpottedTarget, targetComponent) then
				return true;
			end
		end
	end
	
	return hasTarget(obj);
end

function setClosestSpottedTargetAsTargetIfNoTargetExist(obj)
	if hasTarget(obj) then
		return false;
	end
	return setClosestSpottedTargetAsTarget(obj);
end

function setLastShooterAsTarget(obj)
	local shooterUH = getLastShooterHitInstanceUH(obj);
	if shooterUH ~= UH_NONE then
		local tc = getTargetComponent(obj);		
		if setTarget(obj, shooterUH, tc) then
			return true;
		end	
	else
		logAIError(obj, "ai_utils:setLastShooterAsTarget - Last shooter uh is NONE.");
	end
	return false;
end

function setLastShooterAsTargetIfCloserThanCurrentTarget(obj)
	local shooterUH = getLastShooterHitInstanceUH(obj);
	if shooterUH ~= UH_NONE then		
		local lastShooterInstance = common.CommonUtils.getSceneInstanceByUH(shooterUH);
		if lastShooterInstance ~= nil then -- Shooter might be nil e.g. if it was an explosion
			if hasTarget(obj) then
				-- Has target, compare target and shooter positions
				local lastShooterPos = getInstancePosition(lastShooterInstance);
				local targetPos = getTargetPosActual(obj);
				local ownPos = getOwnPosition(obj);

				local dirToTarget = targetPos - ownPos;
				local sqDistToTarget = dirToTarget:getSquareLength();
				local dirToLastShooter = lastShooterPos - ownPos;
				local sqDistToLastShooter = dirToTarget:getSquareLength();
				
				-- Use shooter as target if it was closer than old target
				if sqDistToLastShooter < sqDistToTarget then		
					local tc = getTargetComponent(obj);
					if isValidPossibleTargetUH(obj, shooterUH, tc) then
						if setTarget(obj, shooterUH, tc) then
							return true;
						end	
					end
				end
			else
				-- No target, use the shooter target
				local tc = getTargetComponent(obj);	
				if isValidPossibleTargetUH(obj, shooterUH, tc) then
					if setTarget(obj, shooterUH, tc) then
						return true;
					end
				end
			end
		end
		return true;
	else
		logAIError(obj, "ai_utils:setLastShooterAsTargetIfCloserThanCurrentTarget - Last shooter uh is NONE.");
	end
	return false;
end

function isTargetOnSamePlatform(obj, targetComponent, customLimit)	
	local diff = getTargetAbsolutePositionDiffOnAxisZ(obj, targetComponent);
	
	local limit = customLimit;
	if limit == nil then
		limit = 4;
	end
	-- HACK NOTE: This is very very very HACKY
	if diff <= limit then
		return true;
	else
		return false;
	end
end

function isTargetOnSamePlatformOrHigher(obj)
	if not hasTarget(obj) then
		logAIError(obj, "ai_utils:isTargetOnSamePlatformOrHigher - No target specified.");
		return false;
	end
	
	local targetPos = getTargetPosActual(obj);
	local ownPos = getOwnPosition(obj);
	
	return targetPos.z >= (ownPos.z - 1.0);
end

function getTargetInstance(obj, targetComponent)
	local tc = targetComponent;
	
	if tc == nil then	
		tc = getTargetComponent(obj);
	end
	
	if hasTarget(obj, tc) then
		local targetUH = tc:getTarget();
		if targetUH ~= UH_NONE then
			return common.CommonUtils.getSceneInstanceByUH(targetUH);
		end
	end
	return nil;
end

function getPlayerCharacterComponent(obj)
	if(obj.getControllerComponent) then obj = obj:getFinalOwner(); end
	local cc = obj:getControllerComponent()
	if(not cc) then return nil end
	return cc:dynamicCast(trinebase.gameplay.character.TrinePlayerCharacterComponent.getStaticObjectClass());
end

function getPlayerStateComponentByName(obj, stateCollectionName)
	return findStateComponentByNameFromCharacterComponent(obj, stateCollectionName);
end

function getTargetStateComponentByName(stateCollectionName)	
	local targetInstance = getTargetInstance(obj);
	if targetInstance ~= nil then
		local playerCharacterComponent = getPlayerCharacterComponent(targetInstance);
		if playerCharacterComponent ~= nil then
			return getPlayerStateComponentByName(playerCharacterComponent, stateCollectionName);		
		end
	end
	return nil;
end

function isTargetBlockingWithShield(obj)
	if not hasTarget(obj) then
		logAIError(obj, "ai_utils:isTargetBlockingWithShield - No target specified.");
		return false;
	end
		
	local stateComponent = getTargetStateComponentByName("ShieldState");
	if stateComponent ~= nil then
		if stateComponent:getCurrentState() == "Blocking" then
			return true;
		end
	end	
	return false;
end

function isTargetAimingWithBow(obj)
	if not hasTarget(obj) then
		logAIError(obj, "ai_utils:isTargetAimingWithBow - No target specified.");
		return false;
	end
	
	local stateComponent = getTargetStateComponentByName("BowState");
	if stateComponent ~= nil then
		if stateComponent:getCurrentState() == "Loading" or stateComponent:getCurrentState() == "Aiming" or stateComponent:getCurrentState() == "Shoot" then
			return true;
		end
	end	
	return false;
end

function isUnifiedHandleInsideVisionMaxArea(obj, uh)
	return getTargetComponent(obj):isUnifiedHandleInsideVisionMaxArea(uh);
end

function isUnifiedHandleInsideVisionMinArea(obj, uh)
	return getTargetComponent(obj):isUnifiedHandleInsideVisionMinArea(uh);
end

-------------------------------------------------------------------------------------------------
--
-- Hit stuff
--
function getLastHitPoint(obj)
	return getHittableComponent(obj):getLastHitPoint();
end

function getLastShooterHitInstanceUH(obj)
	return getHittableComponent(obj):getLastShooterHitInstance();
end

function getLastShooterHitTypeUH(obj)
	return getHittableComponent(obj):getLastShooterHitType();
end

function getLastWeaponHitTypeUH(obj)
	return getHittableComponent(obj):getLastWeaponHitType();
end

function getLastWeaponHitInstanceUH(obj)
	return getHittableComponent(obj):getLastWeaponHitInstance();
end

function getLastWeaponInstanceHitStateNumber(obj)
	return getHittableComponent(obj):getLastWeaponInstanceHitStateNumber();
end

function getLastShooterHitInstance(obj)
	local last = getLastShooterHitInstanceUH(obj);
	if last ~= UH_NONE then
		return common.CommonUtils.getSceneInstanceByUH(last);
	end
	return nil;
end

function getLastShooterHitType(obj)
	local last = getLastShooterHitTypeUH(obj);
	if last ~= UH_NONE then
		return common.CommonUtils.getTypeManager():getTypeByUH(last);
	end
	return nil;
end

function getLastWeaponHitType(obj)
	local last = getLastWeaponHitTypeUH(obj);
	if last == UH_NONE then	
		return nil;	
	end
	return common.CommonUtils.getTypeManager():getTypeByUH(last);
end

function getWeaponComponentsLastProjectileHitUH(obj, weaponComponent)
	local wc = weaponComponent;
	if wc == nil then
		wc = getWeaponComponent(obj);
	end
	
	if wc == nil then
		logAIError(obj, "ai_utils:getWeaponComponentsLastProjectileHitUH - Cannot find WeaponComponent.");
		return UH_NONE;
	end
	return wc:getLastProjectileHitUH();
end

function getWeaponComponentsLastProjectileHitPoint(obj, weaponComponent)
	local wc = weaponComponent;
	if wc == nil then
		wc = getWeaponComponent(obj);
	end
	
	if wc == nil then
		logAIError(obj, "ai_utils:getWeaponComponentsLastProjectileHitPoint - Cannot find WeaponComponent.");
		return VC3(0,0,0);
	end
	return wc:getLastProjectileHitPoint();
end

function getWeaponComponentsLastProjectileHitMaterialTypeUH(obj, weaponComponent)
	local wc = weaponComponent;
	if wc == nil then
		wc = getWeaponComponent(obj);
	end
	
	if wc == nil then
		logAIError(obj, "ai_utils:getWeaponComponentsLastProjectileHitMaterialTypeUH - Cannot find WeaponComponent.");
		return UH_NONE;
	end
	return wc:getLastProjectileHitMaterialTypeUH();
end

function getWeaponComponentsLastProjectileTrackHitUH(obj, weaponComponent)
	local wc = weaponComponent;
	if wc == nil then
		wc = getWeaponComponent(obj);
	end
	
	if wc == nil then
		logAIError(obj, "ai_utils:getWeaponComponentsLastProjectileTrackHitUH - Cannot find WeaponComponent.");
		return UH_NONE;
	end
	return wc:getLastProjectileTrackHitUH();
end

function getWeaponComponentsLastProjectileTrackHitPoint(obj, weaponComponent)
	local wc = weaponComponent;
	if wc == nil then
		wc = getWeaponComponent(obj);
	end
	
	if wc == nil then
		logAIError(obj, "ai_utils:getWeaponComponentsLastProjectileTrackHitPoint - Cannot find WeaponComponent.");
		return VC3(0,0,0);
	end
	return wc:getLastProjectileTrackHitPoint();
end

function getWeaponComponentsLastProjectileTrackHitMaterialTypeUH(obj, weaponComponent)
	local wc = weaponComponent;
	if wc == nil then
		wc = getWeaponComponent(obj);
	end
	
	if wc == nil then
		logAIError(obj, "ai_utils:getWeaponComponentsLastProjectileTrackHitMaterialTypeUH - Cannot find WeaponComponent.");
		return UH_NONE;
	end
	return wc:getLastProjectileTrackHitMaterialTypeUH();
end

function getLastWeaponHitTypeUHFromAttachHitPoint(obj, index)
	local attachHitPointsComponent = getAttachHitPointsComponent(obj);
	if attachHitPointsComponent == nil then
		logAIError(obj, "ai_utils:getLastWeaponHitTypeUHFromAttachHitPoint - AttachHitPointsComponent is missing.");
		return UH_NONE;
	end
	
	local hitPointInstanceUH = attachHitPointsComponent:getHitPointInstancesByIndex(index);
	if hitPointInstanceUH == UH_NONE then
		logAIError(obj, "ai_utils:getLastWeaponHitTypeUHFromAttachHitPoint - AttachHitPointsComponent index is UH_NONE with index: " .. tostring(index) .. ".");
		return UH_NONE;
	end
	
	local hitPointInstance = common.CommonUtils.getSceneInstanceByUH(hitPointInstanceUH);
	if hitPointInstance == nil then
		logAIError(obj, "ai_utils:getLastWeaponHitTypeUHFromAttachHitPoint - AttachHitPointsComponent's  hit point instance doesn't exist with index: " .. tostring(index) .. ".");
		return UH_NONE;
	end
	
	return getHittableComponent(hitPointInstance):getLastWeaponHitType();
end

function getLastWeaponHitTypeFromAttachHitPoint(obj, index)
	local last = getLastWeaponHitTypeUHFromAttachHitPoint(obj, index);
	if last == UH_NONE then	
		return nil;	
	end
	return common.CommonUtils.getTypeManager():getTypeByUH(last);
end

-------------------------------------------------------------------------------------------------
--
-- Reward spawning
--

function spawnItemTypeImpl(object, params)
	if object ~= nil then
		-- Randomize spawn pos & rot a bit
		local tfc = object:getTransformComponent()
		if tfc then
			-- NOTE: mathh.random() with no arguments generates a real number between 0 and 1. 
			
			local spawnPos = params.itemPosition + VC3(math.random() - 1.0, 0.0, math.random() + 1.5)
			tfc:setPosition(spawnPos)
			
			-- NOTE: No rotation please (doesn't look good at all)
			--local spawnRot = QUAT(0.0, math.random() * 3.14, 0.0)
			--tfc:setRotation(spawnRot)
		end
		
		-- Give also some impulse to the physics
		local physics = object:findComponent(physics.PhysicsComponent)
		if physics then
			local spawnForce = VC3(getRandomFloat(params.spawner, 0.25, 1.0) - 1.0, 0.0, getRandomFloat(params.spawner, 0.5, 1.0) + 1.0)
			physics:addForce(spawnForce, engine.component.AbstractPhysicsComponent.ForceModeVelocityChange)
		end
	end
end

function spawnItemType(obj, typeName, spawnPos)
	if not hasLocalMaster(obj) then
		return;
	end
	
	-- spawnPos is reference, save it
	local pos = VC3(spawnPos.x, spawnPos.y, spawnPos.z);
	
	common.CommonUtils.getSceneInstanceManager():createNewInstance(typeManager:findTypeByName(typeName):getUnifiedHandle(), spawnItemTypeImpl, {spawner = obj, itemPosition = pos});
end

function spawnItemTypeHealthSmall(obj, spawnPos)
	spawnItemType(obj, "SmallHealthPickableItem", spawnPos);
end

function spawnItemTypeHealthLarge(obj, spawnPos)
	spawnItemType(obj, "LargeHealthPickableItem", spawnPos);
end

function spawnItemTypeHealthEnemy(obj, spawnPos)
	spawnItemType(obj, "EnemyHealthPickableItem", spawnPos);
end

function spawnItemTypeManaEnemy(obj, spawnPos)
	spawnItemType(obj, "SmallManaPickableItem", spawnPos);
end

function spawnItemTypeManaSmall(obj, spawnPos)
	spawnItemType(obj, "SmallManaPickableItem", spawnPos);
end

function spawnItemTypeManaLarge(obj, spawnPos)
	spawnItemType(obj, "LargeManaPickableItem", spawnPos);
end

-- These would mess persistent experience counting
-- function spawnItemTypeExp(obj, spawnPos)
-- 	spawnItemType(obj, "SolidExpPickableItem", spawnPos);
-- end
-- 
-- function spawnItemTypeExpEnemy(obj, spawnPos)
-- 	spawnItemType(obj, "EnemyExpPickableItem", spawnPos);
-- end
-- 
-- function spawnItemTypeExpFloating(obj, spawnPos)
-- 	spawnItemType(obj, "FloatingExpPickableItem", spawnPos);
-- end

local difficultySpawnRate =
{
	["gameplay.difficulty.DifficultyLevelEasy"] = 3,
	["gameplay.difficulty.DifficultyLevelMedium"] = 5,
	["gameplay.difficulty.DifficultyLevelHard"] = 7
}

function spawnHealthReward(obj, spawnPos)
	if not hasLocalMaster(obj) then
		return;
	end
	local difMan = gameState:getDifficultyManager()
	if difMan then
		local difLevel = difMan:getCurrentDifficultyLevel()
		if difLevel then
			if math.random(1, difficultySpawnRate[tostring(difLevel)]) == 1 then
				spawnItemTypeHealthEnemy(obj, spawnPos);
			end
		end
	end
end

local difficultySpawnRateForMana =
{
	["gameplay.difficulty.DifficultyLevelEasy"] = 3,
	["gameplay.difficulty.DifficultyLevelMedium"] = 5,
	["gameplay.difficulty.DifficultyLevelHard"] = 7
}

function spawnManaReward(obj, spawnPos)
	if not hasLocalMaster(obj) then
		return;
	end
	local difMan = gameState:getDifficultyManager()
	if difMan then 
		local difLevel = difMan:getCurrentDifficultyLevel()
		if difLevel then
			if math.random(1, difficultySpawnRateForMana[tostring(difLevel)]) == 1 then
				spawnItemTypeManaEnemy(obj, spawnPos);
				spawnItemTypeManaEnemy(obj, spawnPos);
				spawnItemTypeManaEnemy(obj, spawnPos);
			end
		end
	end
end

function spawnAITypeExp(obj, spawnPos)
	if not hasLocalMaster(obj) then
		return;
	end
	
	local finalOwner = obj:getFinalOwner()
	local aicc = getAICharacterComponent(obj);
	if not aicc then
		logAIError(obj, "AiUtils:spawnAITypeExp - Could not find ExperienceSpawner.");
		return
	end
	
	local expAmount = aicc:getExperienceAmountToSpawnOnDeath()
	if expAmount == 0 then
		return
	end
	
	local expSpawnerUH = aicc:getExperienceSpawner()
	local expSpawner = expSpawnerUH ~= UH_NONE and sceneInstanceManager:getInstanceByUH(expSpawnerUH) or nil
	if not expSpawner then
		logAIError(obj, "AiUtils:spawnAITypeExp - Could not find ExperienceSpawner.");
		return
	end
	if not expSpawner.spawnExperience then
		expSpawner = expSpawner:findComponent(trinebase.gameplay.TrineExperienceSpawnerComponent)
		if not expSpawner or not expSpawner.spawnExperience then
		logAIError(obj, "AiUtils:spawnAITypeExp - Invalid experience spawner. No spawnExperience method.")
		end
	end
	local expType = typeManager:findTypeByName("EnemyExpPickableItem")
	if not expType then
		logAIError(obj, "AiUtils:spawnAITypeExp - Could not find experience type to spawn.");
		return
	end
	
	expSpawner:spawnExperience(finalOwner:getUnifiedHandle(), expType:getUnifiedHandle(), expAmount, VC3(spawnPos.x, 0, spawnPos.z))
end

function spawnReward(obj)
	local myPos = getOwnPosition(obj);

	spawnHealthReward(obj, myPos);
	--spawnManaReward(obj, myPos);
	spawnAITypeExp(obj, myPos);
end

-------------------------------------------------------------------------------------------------

--
-- Path helper with root motion
--

function enableRootMotionForAllAxixes(obj)
	local rmc = getRootMotionComponent(obj);
	enableRootMotionX(obj, rmc);
	enableRootMotionY(obj, rmc);
	enableRootMotionZ(obj, rmc);
end

function disableRootMotionForAllAxixes(obj)
	local rmc = getRootMotionComponent(obj);
	disableRootMotionX(obj, rmc);
	disableRootMotionY(obj, rmc);
	disableRootMotionZ(obj, rmc);
end

function enableRootMotion(obj)
	local rmc = getRootMotionComponent(obj);
	-- We don't want to modify root motion on X axis, it's used for moving
	--enableRootMotionX(obj, rmc);
	enableRootMotionY(obj, rmc);
	-- We don't want to modify root motion on Z axis, it's used for moving
	--enableRootMotionZ(obj, rmc);
end

function disableRootMotion(obj)
	local rmc = getRootMotionComponent(obj);
	-- We don't want to modify root motion on X axis, it's used for moving
	--disableRootMotionX(obj, rmc);
	disableRootMotionY(obj, rmc);
	-- We don't want to modify root motion on Z axis, it's used for moving
	--disableRootMotionZ(obj, rmc);
end

function enableRootMotionX(obj)
	local comp = getRootMotionComponent(obj);
	if comp == nil then
		return;
	end
	if not comp:getAxisXEnabled() then
		comp:setAxisXEnabled(true);
	end
end

function disableRootMotionX(obj)
	local comp = getRootMotionComponent(obj);
	if comp == nil then
		return;
	end
	if comp:getAxisXEnabled() then
		comp:setAxisXEnabled(false);
	end
end

function enableRootMotionY(obj, rootMotionComponent)
	local comp = rootMotionComponent;
	if comp == nil then
		comp = getRootMotionComponent(obj);
	end
	
	if comp == nil then
		return;
	end
	
	if not comp:getAxisYEnabled() then
		comp:setAxisYEnabled(true);
	end
end

function disableRootMotionY(obj)
	local comp = getRootMotionComponent(obj);
	if comp == nil then
		return;
	end
	if comp:getAxisYEnabled() then
		comp:setAxisYEnabled(false);
	end
end

function enableRootMotionZ(obj)
	local comp = getRootMotionComponent(obj);
	if comp == nil then
		return;
	end
	if not comp:getAxisZEnabled() then
		comp:setAxisZEnabled(true);
	end
end

function disableRootMotionZ(obj)
	local comp = getRootMotionComponent(obj);
	if comp == nil then
		return;
	end
	if comp:getAxisZEnabled() then
		comp:setAxisZEnabled(false);
	end
end

function getAIPathelperInstance(obj)	
	local inst = obj:getFinalOwner();
	if inst == nil then
		logAIError(obj, "ai_utils:getAIPathelperInstance - Instance is nil.");
		return nil;
	end
	
	local aiCC = getAICharacterComponent(obj);
	if aiCC == nil then
		logAIError(obj, "ai_utils:getAIPathelperInstance - AICharacter component is missing.");
		return nil;
	end	
	local aiPathHelperUH = aiCC:getAiHelperUH();	
	if aiPathHelperUH ~= UH_NONE then
		return common.CommonUtils.getSceneInstanceByUH(aiPathHelperUH);
	end	
	return nil;
end

function getAIPathelperUH(obj, aiCharacterComponent)
	local aiCC = aiCharacterComponent;
	
	if aiCC == nil then
		aiCC = getAICharacterComponent(obj);
		if aiCC == nil then
			logAIError(obj, "ai_utils:getAIPathelperUH - AICharacter component is missing.");
			return UH_NONE;
		end
	end
	
	return aiCC:getAiHelperUH();
end

function getAiHelperUHInUse(obj, aiCharacterComponent)
	local aiCC = aiCharacterComponent;
	
	if aiCC == nil then
		aiCC = getAICharacterComponent(obj);
		if aiCC == nil then
			logAIError(obj, "ai_utils:getAiHelperUHInUse - AICharacter component is missing.");
			return UH_NONE;
		end
	end
	
	return aiCC:getAiHelperUHInUse();
end

function getAIHelperInvalidUH(obj, aiCharacterComponent)
	local aiCC = aiCharacterComponent;
	
	if aiCC == nil then
		aiCC = getAICharacterComponent(obj);
		if aiCC == nil then
			logAIError(obj, "ai_utils:getAIHelperInvalidUH - AICharacter component is missing.");
			return UH_NONE;
		end
	end
	
	return aiCC:getAiHelperInvalidUH();
end

function isAIPathHelperUsable(obj, uh, ignoreDirection, doActiveEnabledUsableCheck)	
	if uh == UH_NONE then
		logAIError(obj, "ai_utils:isAIPathHelperUsable - Invalid unified handle.");
		return false;
	end
	
	local aiCC = getAICharacterComponent(obj);
	if aiCC == nil then
		logAIError(obj, "ai_utils:isAIPathHelperUsable - AICharacter component is missing.");
		return false;
	end
	
	local aiPathHelperComp = getAiPathHelperComponentByInstanceUH(uh);
	if aiPathHelperComp == nil then
		logAIError(obj, "ai_utils:isAIPathHelperUsable - No AIPathHelperComponent found with given instance uh.");
		return false;
	end
	
	-- Don't use disabled helpers
	if not aiPathHelperComp:getEnabled() then
		return false;
	end
	
	-- NOTE: THIS BREAKS ALL (it doesn't care about height limits)
	-- TODO: should use: aiPathHelperComp:isHelperActiveEnabledUsableByThisInstanceUH(uh)) (so doActiveEnabledUsableCheck should be probably always TRUE for all helpers)
	-- By enabling doActiveEnabledUsableCheck it might break some stuff, so lets not do that (at least for now) -Jari 2011-07-18
	-- Don't use inactive helpers
	--if not aiPathHelperComp:getActive() then
	--	return false;
	--end
	
	-- Don't use helper if AI group status or helper group status differs
	if aiPathHelperComp:getAIPathHelperGroupType() == platformer.ai.AIPathHelperGroupTypeGroup then
		if not aiCC:getInGroup() then
			return false;
		end
	end
		
	-- NOTE: Allow always custom helpers also
	--if isAIPathHelperComponentCustom(aiPathHelperComp) then
	--	return false;
	--end
	
	-- Make sure that AI path helper and AI rotation is the same
	if not ignoreDirection then
		if not aiPathHelperComp:getIgnoreSidewayDirection() then		
	        local pathHelperSidewayDirection = aiPathHelperComp:getSidewaysDirection();
	        local aiSidewayDirection = aiCC:getSidewaysDirection();	
	
			if pathHelperSidewayDirection ~= aiSidewayDirection then
				return false;
			end
		end
	end
	
	if doActiveEnabledUsableCheck then
		local aiUH = getFinalOwnerUnifiedHandle(obj);
		if aiUH ~= UH_NONE then
			if not aiPathHelperComp:isHelperActiveEnabledUsableByThisInstanceUH(aiUH) then
				return false;
			end
		end
	end
	
	return true;
end

function hasAIPathHelperInvalid(obj, aiCharacterComponent)
	local aiCC = aiCharacterComponent;
	
	if aiCC == nil then
		aiCC = getAICharacterComponent(obj);
		if aiCC == nil then
			logAIError(obj, "ai_utils:hasAIPathHelperInvalid - AICharacter component is missing.");
			return false;
		end
	end
	
	return aiCC:getAiHelperInvalidUH() ~= UH_NONE;
end

function doesAIPathHelperDirectionMatchToAI(obj, aiCharacterComponent)
	local aiCC = aiCharacterComponent;
	
	if aiCC == nil then
		aiCC = getAICharacterComponent(obj);
		if aiCC == nil then
			logAIError(obj, "ai_utils:doesAIPathHelperDirectionMatchToAI - AICharacter component is missing.");
			return false;
		end
	end
	
	local aiPathHelperUH = getAIPathelperUH(obj, aiCC);
	if aiPathHelperUH == UH_NONE then
		logAIError(obj, "ai_utils:doesAIPathHelperDirectionMatchToAI - AIPathelperUH is UH_NONE.");
		return false;
	end
	
	local aiPathHelperComp = getAiPathHelperComponentByInstanceUH(aiPathHelperUH);
	if aiPathHelperComp == nil then
		logAIError(obj, "ai_utils:doesAIPathHelperDirectionMatchToAI - No AIPathHelperComponent found with given instance uh.");
		return false;
	end
	return aiPathHelperComp:getSidewaysDirection() == aiCC:getSidewaysDirection();
end

function doesInvalidAIPathHelperDirectionMatchToAI(obj, aiCharacterComponent)
	local aiCC = aiCharacterComponent;
	
	if aiCC == nil then
		aiCC = getAICharacterComponent(obj);
		if aiCC == nil then
			logAIError(obj, "ai_utils:doesInvalidAIPathHelperDirectionMatchToAI - AICharacter component is missing.");
			return false;
		end
	end
	
	local aiPathHelperUH = getAIHelperInvalidUH(obj, aiCC);
	if aiPathHelperUH == UH_NONE then
		logAIError(obj, "ai_utils:doesInvalidAIPathHelperDirectionMatchToAI - AiHelperInvalidUH is UH_NONE.");
		return false;
	end
	
	local aiPathHelperComp = getAiPathHelperComponentByInstanceUH(aiPathHelperUH);
	if aiPathHelperComp == nil then
		logAIError(obj, "ai_utils:doesInvalidAIPathHelperDirectionMatchToAI - No AIPathHelperComponent found with given instance uh.");
		return false;
	end
	return aiPathHelperComp:getSidewaysDirection() == aiCC:getSidewaysDirection();
end

function hasAIPathelper(obj, aiCharacterComponent, ignoreDirection)
	local aiCC = aiCharacterComponent;	
	if aiCC == nil then
		aiCC = getAICharacterComponent(obj);
	end
	
	local aiPathHelperUH = aiCC:getAiHelperUH();
	if aiPathHelperUH == UH_NONE then
		return false;
	end
	
	return isAIPathHelperUsable(obj, aiPathHelperUH, ignoreDirection);
end

function getDistanceSqToAIPathelper(obj)
	local aiPathelperInstance = getAIPathelperInstance(obj);
	if aiPathelperInstance == nil then
		logAIError(obj, "ai_utils:getDistanceToAIPathelper - AIPathelperInstance is nil.");
		return 9999.0;
	end
	
	local aiPathHelperPos = getInstancePosition(aiPathelperInstance);
	local ownPos = getOwnPosition(obj);
	local dir = aiPathHelperPos - ownPos;
	return dir:getSquareLength();
end

function getDistanceSqToAIPathelperByUH(obj, uh)
	if uh == UH_NONE then
		logAIError(obj, "ai_utils:getDistanceSqToAIPathelperByUH - uh is UH_NONE.");
		return 9999.0;
	end	
	
	local aiPathelperInstance = common.CommonUtils.getSceneInstanceByUH(uh);
	if aiPathelperInstance == nil then
		logAIError(obj, "ai_utils:getDistanceSqToAIPathelperByUH - AIPathelperInstance is nil.");
		return 9999.0;
	end
	
	local aiPathHelperPos = getInstancePosition(aiPathelperInstance);
	local ownPos = getOwnPosition(obj);
	local dir = aiPathHelperPos - ownPos;
	return dir:getSquareLength();
end

function doesAIPathHelperAllowParametrizedJump(uh)
	if uh == UH_NONE then
		logErrorImpl("ai_utils:doesAIPathHelperAllowParametrizedJump - Invalid unified handle.");
		return false;
	end
	
	local aiPathHelperComp = getAiPathHelperComponentByInstanceUH(uh);
	if aiPathHelperComp == nil then
		logErrorImpl("ai_utils:doesAIPathHelperAllowParametrizedJump - No AIPathHelperComponent found with given instance uh.");
		return false;
	end
	
	return aiPathHelperComp:getParametrizedJumpAllowed();
end

function isAIPathHelperComponentCustom(component)
	if component == nil then
		logErrorImpl("ai_utils:isAIPathHelperComponentCustom - Nil component param given.");
		return false;
	end
	
	if component:getAIPathHelperType() == platformer.ai.AIPathHelperTypeCustom then
		return true;
	end
	
	return false;
end

function isAIPathHelperCustom(uh)
	if uh == UH_NONE then
		logErrorImpl("ai_utils:isAIPathHelperCustom - Invalid unified handle.");
		return false;
	end
	
	local aiPathHelperComp = getAiPathHelperComponentByInstanceUH(uh);
	if aiPathHelperComp == nil then
		logErrorImpl("ai_utils:isAIPathHelperCustom - No AIPathHelperComponent found with given instance uh.");
		return false;
	end
	
	return isAIPathHelperComponentCustom(aiPathHelperComp);
end

function isAIPathHelperComponentStop(component)
	if component == nil then
		logErrorImpl("ai_utils:isAIPathHelperComponentStop - Nil component param given.");
		return false;
	end
	
	if component:getAIPathHelperType() == platformer.ai.AIPathHelperTypeStop then
		return true;
	end
	
	return false;
end

function isAIPathHelperStop(uh)
	if uh == UH_NONE then
		logErrorImpl("ai_utils:isAIPathHelperStop - Invalid unified handle.");
		return false;
	end
	
	local aiPathHelperComp = getAiPathHelperComponentByInstanceUH(uh);
	if aiPathHelperComp == nil then
		logErrorImpl("ai_utils:isAIPathHelperStop - No AIPathHelperComponent found with given instance uh.");
		return false;
	end
	
	return isAIPathHelperComponentStop(aiPathHelperComp);
end

function isAIPathHelperGroup(uh)
	if uh == UH_NONE then
		logErrorImpl("ai_utils:isAIPathHelperGroup - Invalid unified handle.");
		return false;
	end
	
	local aiPathHelperComp = getAiPathHelperComponentByInstanceUH(uh);
	if aiPathHelperComp == nil then
		logErrorImpl("ai_utils:isAIPathHelperGroup - No AIPathHelperComponent found with given instance uh.");
		return false;
	end
	
	if aiPathHelperComp:getAIPathHelperGroupType() == platformer.ai.AIPathHelperGroupTypeGroup then
		return true;
	end
	
	return false;
end

function doesAIPathHelperHaveAnimParamSecondary(uh)
	if uh == UH_NONE then
		logErrorImpl("ai_utils:doesAIPathHelperHaveAnimParamSecondary - Invalid unified handle.");
		return false;
	end
	
	local aiPathHelperComp = getAiPathHelperComponentByInstanceUH(uh);
	if aiPathHelperComp == nil then
		logErrorImpl("ai_utils:doesAIPathHelperHaveAnimParamSecondary - No AIPathHelperComponent found with given instance uh.");
		return false;
	end
	
	return string.len(aiPathHelperComp:getAnimParamSecondary()) > 0;
end

function enableAiPathHelperChainedImpl(obj, enabled, aICharacterComponent)
	local inst = obj:getFinalOwner();
	if inst == nil then
		logAIError(obj, "ai_utils:enableAiPathHelperChainedImpl - Instance is nil.");
		return;
	end
	
	local aiCC = aICharacterComponent;
	if aiCC == nil then
		aiCC = getAICharacterComponent(obj);
	end
	
	if aiCC:getAiHelperAllowChained() ~= enabled then
		aiCC:setAiHelperAllowChained(enabled);
	end
end

function enableAiPathHelperChained(obj, aICharacterComponent)	
	enableAiPathHelperChainedImpl(obj, true, aICharacterComponent);
end

function disableAiPathHelperChained(obj, aICharacterComponent)	
	enableAiPathHelperChainedImpl(obj, false, aICharacterComponent);
end

function getAiPathHelperComponentByInstanceUH(uh)

	if uh == UH_NONE then
		logErrorImpl("ai_utils:getAiPathHelperComponentByInstanceUH - Invalid unified handle.");
		return nil;
	end
	
	local aiPathHelperInst = common.CommonUtils.getSceneInstanceByUH(uh);
	if aiPathHelperInst == nil then
		logErrorImpl("ai_utils:getAiPathHelperComponentByInstanceUH - No such instance found.");
		return nil;
	end
		
	local aiPathHelperComp = findComponentFromObjectByClass(aiPathHelperInst, trinebase.gameplay.ai.TrineAIPathHelperComponent.getStaticObjectClass());
	if aiPathHelperComp == nil then
	    aiPathHelperComp = findComponentFromObjectByClass(aiPathHelperInst, trinebase.gameplay.ai.TrineAIPathHelperJumpHelperComponent.getStaticObjectClass());
	    
		-- Not an error, if TrineAIPathHelperComponent doesn't exist, it's probably not even a AiPathHelperEntity
		--logErrorImpl("ai_utils:getAiPathHelperComponentByInstanceUH - Cannot find TrineAIPathHelperComponent from AiPathHelper instance.");
	end	
	return aiPathHelperComp;	
end

function clearPathHelper(obj, possiblePathHelperUH)
	if obj == nil then
		logErrorImpl("ai_utils:clearPathHelper - Param obj is NIL.");
		return false;
	end
	
	local inst = obj:getFinalOwner();
	if inst == nil then
		logAIError(obj, "ai_utils:clearPathHelper - Instance is nil.");
		return false;
	end

	local aiCC = getAICharacterComponent(obj);
	if aiCC == nil then
		logAIError(obj, "ai_utils:clearPathHelper - AICharacterComponent is missing.");
		return false;
	end
		
	-- Use the param UH
	if possiblePathHelperUH ~= nil and possiblePathHelperUH ~= UH_NONE then
		local aiPathHelperComp = getAiPathHelperComponentByInstanceUH(possiblePathHelperUH);
		if aiPathHelperComp ~= nil then
			if aiPathHelperComp:getOccupiedByUH() == inst:getUnifiedHandle() then
				aiPathHelperComp:setOccupiedByUH(UH_NONE);
			end
		end
	end
	
	local aiPathHelperUH = aiCC:getAiHelperUH();
	if aiPathHelperUH ~= UH_NONE then
		aiCC:setAiHelperUH(UH_NONE);
		local aiPathHelperComp = getAiPathHelperComponentByInstanceUH(aiPathHelperUH);
		if aiPathHelperComp ~= nil then
			if aiPathHelperComp:getOccupiedByUH() == inst:getUnifiedHandle() then
				aiPathHelperComp:setOccupiedByUH(UH_NONE);
			end
		end
	else
		-- NOTE: This happens with the spider all the time
		--logAIError(obj, "ai_utils:clearPathHelper - AICharacterComponent doesn't have path helper on memory, cannot clear.");
	end
end

function disableRootMotionAndClearVariables(obj)	
	if obj == nil then
		logErrorImpl("ai_utils:disableRootMotionAndClearVariables - Param obj is NIL.");
		return false;
	end
	
	local inst = obj:getFinalOwner();
	if inst == nil then
		logAIError(obj, "ai_utils:disableRootMotionAndClearVariables - Instance is nil.");
		return false;
	end
	
	local aiCC = getAICharacterComponent(obj);
	if aiCC == nil then
		logAIError(obj, "ai_utils:disableRootMotionAndClearVariables - AICharacter component is missing.");
		return false;
	end	
	
	-- Clear all
	disableRootMotion(obj);
	
	-- NOTE: No need to call this, we handle this differently in this function
	--clearPathHelper(obj)
	
	local waitingAiHelperUH = aiCC:getWaitingAiHelperUH();
	if waitingAiHelperUH ~= UH_NONE then
		aiCC:setWaitingAiHelperUH(UH_NONE);
		local aiPathHelperComp = getAiPathHelperComponentByInstanceUH(waitingAiHelperUH);
		if aiPathHelperComp ~= nil then
			aiPathHelperComp:removeUhFromListOfWaitersUHArray(inst:getUnifiedHandle());
			if aiPathHelperComp:getOccupiedByUH() == inst:getUnifiedHandle() then
				aiPathHelperComp:setOccupiedByUH(UH_NONE);
			end
		end
	end
	
	aiCC:setAiHelperStartTime(0);
	resetJumpOverRootMotionPosition(obj);
	
	return true;
end

function enableAIPathHelperUsageImpl(obj, useAnimParamSecondary, enableAnimContext)
	if obj == nil then
		logErrorImpl("ai_utils:enableAIPathHelperUsageImpl - Param obj is NIL.");
		return false;
	end
	
	local inst = obj:getFinalOwner();
	if inst == nil then
		logAIError(obj, "ai_utils:enableAIPathHelperUsageImpl - Instance is nil.");
		return false;
	end
	
	local aiCC = getAICharacterComponent(obj);
	if aiCC == nil then
		logAIError(obj, "ai_utils:enableAIPathHelperUsageImpl - AICharacterComponent is missing.");
		return false;
	end	
	
	local lastPathHelperUH = aiCC:getAiHelperUHInUse();
	if lastPathHelperUH ~= UH_NONE then		
		-- Just ignore and disable? :D
		if not disableAIPathHelperUsageCustom(obj, lastPathHelperUH, aiCC) then
			logAIError(obj, "ai_utils:enableAIPathHelperUsageImpl - AI was trying to use helper even it had the old one in memory. Well, tried to disable the old one but that failed too. NEED TO FIX THIS.");
			return false;			
		end
		--logAIError(obj, "ai_utils:enableAIPathHelperUsageImpl - AI is still using the last AI path helper and it's not disabled, this may result to invalid animation contexts and path helper reserving. This should never happen.");
		--return false;
	end
	
	local aiPathHelperUH = aiCC:getAiHelperUH();
	if aiPathHelperUH == UH_NONE then
		logAIError(obj, "ai_utils:enableAIPathHelperUsageImpl - AiPathHelperUh is invalid, this should never happen.");
		return false;
	end
	
	local aiPathHelperComp = getAiPathHelperComponentByInstanceUH(aiPathHelperUH);
	if aiPathHelperComp == nil then
		aiCC:setAiHelperUH(UH_NONE);
		logAIError(obj, "ai_utils:enableAIPathHelperUsageImpl - AiPathHelperComponent is nil, this should never happen.");
		return false;
	end
		
	local aiPathHelperTransFComp = aiPathHelperComp:getFinalOwner():getTransformComponent();
	if aiPathHelperTransFComp == nil then
		logAIError(obj, "ai_utils:enableAIPathHelperUsageImpl - AiPathHelper instance doesn't have TransformComponent.");
		return false;
	end
		
	local animC = getAnimationComponent(obj);
	if animC == nil then
		logAIError(obj, "ai_utils:enableAIPathHelperUsageImpl - AnimationComponent is missing.");
		return false;
	end
	
	-- Allow chained ai path helper actions by default
	enableAiPathHelperChained(obj, aiCC);

	-- NOTE: This is some very old code, shouldn't never clear the force dir! Done automatically by engine
	-- Clear forced dir
	--clearAIPathHelperForceDirection(obj);

	if enableAnimContext and aiPathHelperComp:getAnimParamsEnabled() then	
		local aiPathHelperAnimParam = "";	
		if useAnimParamSecondary then
			aiPathHelperAnimParam = aiPathHelperComp:getAnimParamSecondary();
		else	    
			aiPathHelperAnimParam = aiPathHelperComp:getAnimParam();
		end
		
		if string.len(aiPathHelperAnimParam) == 0 then
			if useAnimParamSecondary then
				logAIError(obj, "ai_utils:enableAIPathHelperUsageImpl - AiPathHelper animation param (AnimParamSecondary) is emtpy. HelperComponentInstanceType: " .. getTypeName(aiPathHelperComp) .. " , HelperComponentInstance: " .. getGUIDStr(aiPathHelperComp) .. "..");
			else
				logAIError(obj, "ai_utils:enableAIPathHelperUsageImpl - AiPathHelper animation param (AnimParam) is emtpy. HelperComponentInstanceType: " .. getTypeName(aiPathHelperComp) .. " , HelperComponentInstance: " .. getGUIDStr(aiPathHelperComp) .. "..");
			end
			return false;
		end	

		if animC:hasContext(aiPathHelperAnimParam) then
			local customAiPathHelper = isAIPathHelperComponentCustom(aiPathHelperComp);
			
			-- Custom path helpers cannot be scaled (e.g. Swamp Goblin's predator helper, uses same anim param!)
			if not customAiPathHelper then
				local aiPathHelperScaleFactor = aiPathHelperComp:getScaleFactor();
				if aiPathHelperScaleFactor > 0.0 then
					local scaleX = math.abs(aiPathHelperComp:getAIPathHelperScale().x);
					if scaleX ~= 1.0 then
						animC:setParameterForNextAnimation(getAnimationParamNameDistance(), scaleX * aiPathHelperScaleFactor);
					else
						animC:setParameterForNextAnimation(getAnimationParamNameDistance(), aiPathHelperScaleFactor);		
					end
				else
					animC:setParameterForNextAnimation(getAnimationParamNameDistance(), 0.0);		
				end
			end
			
			-- Enable anim context from helper
			animC:setContext(aiPathHelperAnimParam, true);
			
			local angle = aiPathHelperComp:getAIPathHelperAngleFromDefault().y * (180.0 / 3.14);
			if angle > 180.0 then
				angle = angle - 360;
			end
			animC:setParameterForNextAnimation(getAnimationParamNameHelperAngle(), angle);
		else
			-- not an warning anymore!
			--logAIWarning(obj, "ai_utils:enableAIPathHelperUsageImpl - No such animation context: \"" .. aiPathHelperAnimParam .. "\".");
			--return false;
		end
	end
	
	--
	-- NOTE: ALWAYS set root motion pos
	--
	-- Just to be sure (spawning might use this)
	animC:resetMoveAbsoluteRootMotionPositionEvent();	

	-- NOTE / HACK: This seems pretty dangerous, JumpOverRootMotionPosition needs to be always reseted after dynamic object climb!!!
	-- Set absolute root motion pos	
	-- Try first to see if we have a dynamic object jump helper
	local absoluteRootMotionPos = getJumpOverRootMotionPosition(obj);	
	if not absoluteRootMotionPos or absoluteRootMotionPos == VC3(0,0,0) then
		absoluteRootMotionPos = aiPathHelperTransFComp:getPosition();
	end
	animC:setAbsoluteRootMotionPositionForNextAnimation(absoluteRootMotionPos);
	animC:sendAbsoluteRootMotionPositionToAll(absoluteRootMotionPos);
	
	-- Set start time
	local curTime = common.CommonUtils.getScene():getTime():getMilliseconds();
	aiCC:setAiHelperStartTime(curTime);
	
	-- Just to be sure, remove itself from waiting list
	local waitingAiHelperUH = aiCC:getWaitingAiHelperUH();
	if waitingAiHelperUH ~= UH_NONE then
		aiCC:setWaitingAiHelperUH(UH_NONE);
		local waitingAiHelperComp = getAiPathHelperComponentByInstanceUH(waitingAiHelperUH);
		if waitingAiHelperComp ~= nil then
			waitingAiHelperComp:removeUhFromListOfWaitersUHArray(inst:getUnifiedHandle());
		end
	end
	
	-- Reserve ai path helper
	aiPathHelperComp:setOccupiedByUH(inst:getUnifiedHandle());
	
	local disabledAftersUsageMsec = aiPathHelperComp:getDisableTimeAfterUsedMsec();
	if disabledAftersUsageMsec > 0 then
		local disableUntil = curTime + disabledAftersUsageMsec;
		aiPathHelperComp:setDisableTime(disableUntil);
	end
	
	-- Inform helper that it has been used
	aiPathHelperComp:pathHelperUsageSuccess();
	
	-- Save the helper UH
	aiCC:setAiHelperUHInUse(aiPathHelperUH);
	
	
	-- Need to always forget the helper which we are about to use!
	aiCC:setAiHelperUH(UH_NONE);

	return true;
end

function enableAIPathHelperUsage(obj, useAnimParamSecondary, enableAnimContext)
	if obj == nil then
		logErrorImpl("ai_utils:enableAIPathHelperUsage - Param obj is NIL.");
		return false;
	end
	
	local success = enableAIPathHelperUsageImpl(obj, useAnimParamSecondary, enableAnimContext);
	if success then
		return true;
	end

	-- Annoying duplicate error (not an actual error)
	--logAIError(obj, "ai_utils:enableAIPathHelperUsage - AIPathHelper usage failed, clearing variables. This shouldn't happen.");
	
	-- NOTE: Hmm, this shoulnd't be needed
	--disableRootMotionAndClearVariables(obj);
	
	
	return false;
end

function disableAIPathHelperUsageImplForReal(obj, disableAnimContext, customAIPathHelperUH, aiCharacterComponent)
	if obj == nil then
		logErrorImpl("ai_utils:disableAIPathHelperUsageImplForReal - Param obj is NIL.");
		return false;
	end
	
	local aiCC = aiCharacterComponent;
	
	if aiCC == nil then
		aiCC = getAICharacterComponent(obj);
	end

	if aiCC == nil then
		logAIError(obj, "ai_utils:disableAIPathHelperUsageImplForReal - AICharacterComponent is missing.");
		return false;
	end
	
	local aiPathHelperUH = UH_NONE;
	if customAIPathHelperUH ~= nil then
		if customAIPathHelperUH == UH_NONE then
			logAIError(obj, "ai_utils:disableAIPathHelperUsageImplForReal - Param: CustomAIPathHelperUH is UH_NONE. Cannot do anything.");
			return false;		
		end
		aiPathHelperUH = customAIPathHelperUH;
	else
		aiPathHelperUH = aiCC:getAiHelperUHInUse();
		if aiPathHelperUH == UH_NONE then
			logAIError(obj, "ai_utils:disableAIPathHelperUsageImplForReal - AICharacterComponent's aiPathHelperUH is UH_NONE. Cannot do anything.");
			return false;
		end
	end
	
	if aiPathHelperUH == UH_NONE then
		logAIError(obj, "ai_utils:disableAIPathHelperUsageImplForReal - CustomAIPathHelperUH or AICharacterComponent's aiPathHelperUH is UH_NONE. Cannot do anything.");
		return false;
	end
	
	local aiPathHelperComp = getAiPathHelperComponentByInstanceUH(aiPathHelperUH);
	if aiPathHelperComp == nil then	
		-- Check from occupied
		aiPathHelperUH = aiCC:getWaitingAiHelperUH();
		if aiPathHelperUH == UH_NONE then
			logAIError(obj, "ai_utils:disableAIPathHelperUsageImplForReal - aiPathHelperUH is UH_NONE.");
			return false;
		else
			aiPathHelperComp = getAiPathHelperComponentByInstanceUH(aiPathHelperUH);
			if aiPathHelperComp == nil then
				logAIError(obj, "ai_utils:disableAIPathHelperUsageImplForReal - AiPathHelperComponent is nil.");
				return false;
			end
		end
	end
	
	local animC = getAnimationComponent(obj);
	if animC == nil then
		logAIError(obj, "ai_utils:disableAIPathHelperUsageImplForReal - AnimationComponent is missing.");
		return false;
	end
	
	local isDestroyed = aiCC:getAiDestroyed();
	if not isDestroyed then
		if animC == nil then
			logAIError(obj, "ai_utils:disableAIPathHelperUsageImplForReal - AnimationComponent is missing.");
			return false;
		end
				
		-- Reset
		animC:setParameter(getAnimationParamNameDistance(), 0.0);
		
		-- Disable anim context
		if disableAnimContext then		
			local aiPathHelperAnimParam = aiPathHelperComp:getAnimParam();
			local aiPathHelperAnimParamSecondary = aiPathHelperComp:getAnimParamSecondary();

			-- Always disable both parameters!				
			if string.len(aiPathHelperAnimParamSecondary) > 0 then
				animC:setContext(aiPathHelperAnimParamSecondary, false);
			end
			
			if string.len(aiPathHelperAnimParam) > 0 then
				animC:setContext(aiPathHelperAnimParam, false);
			end
		end
	end

	-- Release ai path helper
	if isDestroyed then
		aiPathHelperComp:setOccupiedByUH(UH_NONE);
	else
		--local delay = getRandomInt(obj, 500, 1000);
		local delay = 0; -- No delay (allow usage always)
		aiPathHelperComp:setOccupiedByUHDelayed(UH_NONE, delay);
	end

	-- Reset variables
	resetJumpOverRootMotionPosition(obj);
	aiCC:setAiHelperStartTime(0);
	
	-- NOTE: Old code, shouldn't do this?
	---- Prevent same helper to be used again
	--local currentPathHelperUH = aiCC:getAiHelperUH();
	--if currentPathHelperUH ~= UH_NONE and currentPathHelperUH == aiPathHelperUH then
	--	aiCC:setAiHelperUH(UH_NONE);
	--end	

	-- All cleared, reset the AI path helper
	if customAIPathHelperUH ~= nil and customAIPathHelperUH ~= UH_NONE then
		-- If custom path helper disable uh was used, don't reset the AiHelperUHInUse if it's not the same as the custom uh
		if aiCC:getAiHelperUHInUse() == customAIPathHelperUH then
			aiCC:setAiHelperUHInUse(UH_NONE);
		end
	else
		-- Normal behaviour
		aiCC:setAiHelperUHInUse(UH_NONE);
	end
	
	-- Just to be sure, disable root motion
	disableRootMotion(obj);
	
	-- And just to be super sure, set the new root motion pos to the position where the AI is now (where AI stopped the path helper action)
	--animC:setAbsoluteRootMotionPositionForNextAnimation(getOwnPosition(obj));
	--animC:setAbsoluteRootMotionPositionForNextAnimation(getRootMotionBonePosition(obj, animC));
	
	return true;
end

function disableAIPathHelperUsageImpl(obj, disableAnimContext, customAIPathHelperUH, aiCC)
	if obj == nil then
		logErrorImpl("ai_utils:disableAIPathHelperUsageImpl - Param obj is NIL.");
		return false;
	end
	
	local success = disableAIPathHelperUsageImplForReal(obj, disableAnimContext, customAIPathHelperUH, aiCC);
	if success then
		return true;
	end
	disableRootMotionAndClearVariables(obj);
	return false;
end

function disableAIPathHelperUsage(obj, aiCC)
	if obj == nil then
		logErrorImpl("ai_utils:disableAIPathHelperUsage - Param obj is NIL.");
		return false;
	end
	
	return disableAIPathHelperUsageImpl(obj, true, nil, aiCC);
end

function disableAIPathHelperUsageCustom(obj, customAIPathHelperUH, aiCC)
	if obj == nil then
		logErrorImpl("ai_utils:disableAIPathHelperUsageCustom - Param obj is NIL.");
		return false;
	end
	
	return disableAIPathHelperUsageImpl(obj, true, customAIPathHelperUH, aiCC);
end

function addAiToAiPathHelperWaitingList(obj)
	local inst = obj:getFinalOwner();
	if inst == nil then
		return false;
	end
	
	local aiCC = getAICharacterComponent(obj);
	if aiCC == nil then
		return false;
	end
	
	local waitingAiHelperUH = aiCC:getWaitingAiHelperUH();
	if waitingAiHelperUH == UH_NONE then
		logAIError(obj, "ai_utils:addAiToAiPathHelperWaitingList - waitingAiHelperUH is invalid, this should never happen.");
		return false;
	end
	
	local aiPathHelperComp = getAiPathHelperComponentByInstanceUH(waitingAiHelperUH);
	if aiPathHelperComp == nil then
		return false;
	end	
	aiPathHelperComp:addUhToListOfWaitersUHArray(inst:getUnifiedHandle());
end

function allowAiPathHelperActionDisable(obj, customTimeLimit)
	local aiCC = getAICharacterComponent(obj);
	if aiCC == nil then
		return true;
	end
	
	local timeLimit = customTimeLimit;
	if timeLimit == nil then
		timeLimit = 750;
	end

	local curTime = common.CommonUtils.getScene():getTime():getMilliseconds();
	local startTime = aiCC:getAiHelperStartTime();
	local timeDiff = curTime - startTime;
	if timeDiff >= timeLimit then
		return true;
	end	
	
	return false;
end

function clearWaitingAIPathhelperUH(obj, aiCharacterComponent)
	local aiCC = aiCharacterComponent;	
	if aiCC == nil then	
		aiCC = getAICharacterComponent(obj);
	end
	
	local inst = obj:getFinalOwner();
	if inst == nil then
		logAIError(obj, "ai_utils:clearWaitingAIPathhelperUH - Instance is nil.");
		return false;
	end
	
	local waitingAiHelperUH = aiCC:getWaitingAiHelperUH();
	if waitingAiHelperUH ~= UH_NONE then
		aiCC:setWaitingAiHelperUH(UH_NONE);
		local aiPathHelperComp = getAiPathHelperComponentByInstanceUH(waitingAiHelperUH);
		if aiPathHelperComp ~= nil then
			aiPathHelperComp:removeUhFromListOfWaitersUHArray(inst:getUnifiedHandle());
			if aiPathHelperComp:getOccupiedByUH() == inst:getUnifiedHandle() then
				aiPathHelperComp:setOccupiedByUH(UH_NONE);
			end
		end
	end
end

-------------------------------------------------------------------------------------------------
--
-- Common force dir component stuff
--

function getAiPathHelperForceDirComponentByInstanceUH(uh)
	if uh == UH_NONE then
		logErrorImpl("ai_utils:getAiPathHelperForceDirComponentByInstanceUH - Invalid unified handle.");
		return nil;
	end

	local aiPathHelperInst = common.CommonUtils.getSceneInstanceByUH(uh);
	if aiPathHelperInst == nil then
		logErrorImpl("ai_utils:getAiPathHelperForceDirComponentByInstanceUH - No such instance found.");
		return nil;
	end

	local aiPathHelperComp = findComponentFromObjectByClass(aiPathHelperInst, trinebase.gameplay.ai.TrineAIPathHelperForceDirComponent.getStaticObjectClass());
	if aiPathHelperComp == nil then
		-- Not an error, if TrineAIPathHelperForceDirComponent doesn't exist, it's probably not even a AiPathHelperEntity
		--logErrorImpl("ai_utils:getAiPathHelperForceDirComponentByInstanceUH - Cannot find TrineAIPathHelperForceDirComponent from AiPathHelper instance.");
	end	
	return aiPathHelperComp;	
end

-------------------------------------------------------------------------------------------------
--
-- Ai path helper stop
--

function doesAIPathHelperStopDirectionMatchByUH(obj, aiPathHelperUH)
	if aiPathHelperUH == UH_NONE then
		logAIError(obj, "ai_utils:doesAIPathHelperStopDirectionMatchByUH - AICharacterComponent doesn't have stop helper UH.");
		return false;
	end
	
	local aiPathHelperComp = getAiPathHelperForceDirComponentByInstanceUH(aiPathHelperUH);
	if aiPathHelperComp ~= nil then
		local forceDir = aiPathHelperComp:getAiPathHelperForceDir();
		if forceDir == platformer.ai.PlatformerAIPathHelperForceDirComponent.AiPathHelperForceDirLeft and not isDirectionToRight(obj) then
			return true;
		elseif forceDir == platformer.ai.PlatformerAIPathHelperForceDirComponent.AiPathHelperForceDirRight and isDirectionToRight(obj) then
			return true;
		end	
	end
	return false;
end

function doesAIPathHelperStopDirectionMatch(obj, aiCharacterComponent)
	local aiCC = aiCharacterComponent;	
	if aiCC == nil then	
		aiCC = getAICharacterComponent(obj);
	end

	local aiPathHelperUH = aiCC:getAiHelperStopHelperUH();
	if aiPathHelperUH == UH_NONE then
		logAIError(obj, "ai_utils:doesAIPathHelperStopDirectionMatch - AICharacterComponent doesn't have stop helper UH.");
		return false;
	end	
	return doesAIPathHelperStopDirectionMatchByUH(obj, aiPathHelperUH);
end

function isStopHelperUsable(obj, uh)	
	if uh == UH_NONE then
		logAIError(obj, "ai_utils:isStopHelperUsable - Invalid unified handle.");
		return false;
	end
	
	local aiCC = getAICharacterComponent(obj);
	if aiCC == nil then
		logAIError(obj, "ai_utils:isStopHelperUsable - AICharacter component is missing.");
		return false;
	end
	
	local aiPathHelperComp = getAiPathHelperForceDirComponentByInstanceUH(uh);
	if aiPathHelperComp == nil then
		logAIError(obj, "ai_utils:isStopHelperUsable - No AiPathHelperForceDirComponent found with given instance uh.");
		return false;
	end
	
	if not doesAIPathHelperStopDirectionMatchByUH(obj, uh) then
		return false;
	end
	
	-- Don't use disabled or inactive helpers
	if not aiPathHelperComp:getEnabled() or not aiPathHelperComp:getActive() then
		return false;
	end	
	
	local aiPathHelperPos = getInstancePosition(aiPathHelperComp);
	local ownPos = getOwnPosition(obj);
	local dir = aiPathHelperPos - ownPos;
	if dir:getSquareLength() > (5 * 5) then
		return false;
	end
	
	return true;
end

function isUsingAIPathHelperStop(obj, aiCharacterComponent)
	local aiCC = aiCharacterComponent;	
	if aiCC == nil then	
		aiCC = getAICharacterComponent(obj);
	end

	local aiPathHelperUH = aiCC:getAiHelperStopHelperUH();
	if aiPathHelperUH == UH_NONE then
		return false;
	end
	
	if not doesAIPathHelperStopDirectionMatch(obj, aiCC) then
		return false;
	end
	
	if not isStopHelperUsable(obj, aiPathHelperUH) then
		return false;
	end

	return true;
end

-------------------------------------------------------------------------------------------------
--
-- Ai path helper force dir
--

function setMovingToCorrectDirectionUsingForceDirectionHelper(obj)
	if isUsingAIPathHelperForceDirection(obj) then
		if doesAIPathHelperForceDirectionMatch(obj) then
			moveStateToSameDirection(obj);
		else
			moveStateToOtherDirection(obj);
		end
	end
end

function isUsingAIPathHelperForceDirection(obj, aiCharacterComponent)
	local aiCC = aiCharacterComponent;	
	if aiCC == nil then	
		aiCC = getAICharacterComponent(obj);
	end

	local aiPathHelperUH = aiCC:getAiHelperForceDirUH();
	if aiPathHelperUH ~= UH_NONE then
		return true;
	end

	return false;
end

function doesAIPathHelperForceDirectionMatch(obj)

	local aiCC = getAICharacterComponent(obj);
	if aiCC == nil then
		logAIError(obj, "ai_utils:isUsingAIPathHelperForceDirection - AICharacterComponent is missing.");
		return false;
	end

	local aiPathHelperUH = aiCC:getAiHelperForceDirUH();
	if aiPathHelperUH == UH_NONE then
		logAIError(obj, "ai_utils:doesAIPathHelperForceDirectionMatch - AICharacterComponent doesn't have fore helper UH.");
		return false;
	end
	
	local aiPathHelperComp = getAiPathHelperForceDirComponentByInstanceUH(aiPathHelperUH);
	if aiPathHelperComp ~= nil then
		local forceDir = aiPathHelperComp:getAiPathHelperForceDir();
		if forceDir == platformer.ai.PlatformerAIPathHelperForceDirComponent.AiPathHelperForceDirLeft and not isDirectionToRight(obj) then
			return true;
		elseif forceDir == platformer.ai.PlatformerAIPathHelperForceDirComponent.AiPathHelperForceDirRight and isDirectionToRight(obj) then
			return true;
		end	
	end
	return false;
end

function clearAIPathHelperForceDirection(obj)
	-- NOTE: This is some very old code, shouldn't never clear the force dir! Done automatically by engine
	--[[
	local aiCC = getAICharacterComponent(obj);
	if aiCC == nil then
		logAIError(obj, "ai_utils:clearAIPathHelperForceDirection - AICharacterComponent is missing.");
		return;
	end

	local forceDirUH = aiCC:getAiHelperForceDirUH();
	if forceDirUH ~= UH_NONE then
		aiCC:setAiHelperForceDirUH(UH_NONE);
	end
	]]--
end

-------------------------------------------------------------------------------------------------
--
-- Position stuff
--

function setInstancePosition(obj, pos)
	local comp = getTransformComponent(obj);
	if comp then
		 comp:setPosition(pos);
	end
end

function getInstancePosition(obj)
	local comp = getTransformComponent(obj);
	local pos = VC3(0,0,0);
	if comp then
		 pos = comp:getPosition();
	end
	return pos;
end

function getInstanceRotation(obj)
	local comp = getTransformComponent(obj);
	local rot = QUAT();
	if comp then
		 rot = comp:getRotation();
	end
	return rot;
end

function getInstanceUHPosition(uh)
	local pos = VC3(0,0,0);
	
	local instance = common.CommonUtils.getSceneInstanceByUH(uh);
	if instance == nil then	
		logErrorImpl("ai_utils:getInstanceUHPosition - No instance found with given UH.");
		return pos;
	end	
	
	local comp = getTransformComponent(instance);	
	if comp ~= nil then
		 pos = comp:getPosition();
	end
	return pos;
end

function setOwnPosition(obj, pos)
	return setInstancePosition(obj, pos);
end

function getOwnPosition(obj)
	return getInstancePosition(obj);
end

function isPositionOnLeft(obj, pos)
	local ownPos = getOwnPosition(obj);
	if pos.x < ownPos.x then
		return true;
	end
	return false;
end

function isPositionOnRight(obj, pos)
	return not isPositionOnLeft(obj, pos);
end

function isInstanceOnLeft(obj, instance)
	return isPositionOnLeft(obj, getInstancePosition(instance));
end

function isInstanceOnRight(obj, instance)
	return not isPositionOnLeft(obj, getInstancePosition(instance));
end

function getTargetAbsolutePositionDiffOnAxisX(obj, targetComponent)
	if hasTarget(obj, targetComponent) then
		local targetPos = getTargetPosActual(obj, targetComponent);
		local ownPos = getOwnPosition(obj);
		
		local diffX = targetPos.x - ownPos.x;
		local lengthX = math.abs(diffX);
		return lengthX;
	else
		logAIError(obj, "ai_utils:getTargetAbsolutePositionDiffOnAxisX - No target specified.");
	end
	return 0.0;
end

function getTargetAbsolutePositionDiffOnAxisZ(obj, targetComponent)
	if hasTarget(obj, targetComponent) then
		local targetPos = getTargetPosActual(obj, targetComponent);
		local ownPos = getOwnPosition(obj);
				
		local diffZ = targetPos.z - ownPos.z;
		local lengthZ = math.abs(diffZ);
		return lengthZ;
	else
		logAIError(obj, "ai_utils:getTargetAbsolutePositionDiffOnAxisZ - No target specified.");
	end
	return 0.0;
end

function getDistanceSqToTarget(obj)
	if hasTarget(obj) then
		local targetPos = getTargetPosActual(obj);
		local ownPos = getOwnPosition(obj);		
		local dir = targetPos - ownPos;
		return dir:getSquareLength();	
	else
		logAIError(obj, "ai_utils:getDistanceToTarget - No target specified.");
	end
	return 0.0;
end

-------------------------------------------------------------------------------------------------
--
-- Net sync stuff
--
function hasLocalMaster(obj)
	return obj:getNetSyncer():hasLocalMaster();
end

	
-------------------------------------------------------------------------------------------------
--
-- Spawner stuff
--

function getMultiSpawnerComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.MultiSpawnerComponent.getStaticObjectClass());
end

function getMultispawnerComponentBySpawnerSpawnerUH(uh)
	if uh == nil then
		logErrorImpl("ai_utils:getMultispawnerComponentBySpawnerSpawnerUH - Param uh is nil.");
		return nil;
	end
	
	if uh == UH_NONE then
		logErrorImpl("ai_utils:getMultispawnerComponentBySpawnerSpawnerUH - Param uh is UH_NONE.");
		return nil;
	end

	local spawnerInstance = common.CommonUtils.getSceneInstanceByUH(uh);
	if spawnerInstance == nil then	
		logErrorImpl("ai_utils:getMultispawnerComponentBySpawnerSpawnerUH - No Spawner instance found wth given UH.");
		return nil;
	end	
	
	local multiSpawnerComponent = getMultiSpawnerComponent(spawnerInstance);
	if multiSpawnerComponent == nil then
		logErrorImpl("ai_utils:getMultispawnerComponentBySpawnerSpawnerUH - No MultiSpawnerComponent found from spawner instance with given spawner UH.");
		return nil;
	end
	
	return multiSpawnerComponent;
end

function getAnimationContextNameFromMultiSpawnerComponentBySpawnerUH(uh)
	return getInstanceType(getMultispawnerComponentBySpawnerSpawnerUH(uh)):getSpawnerAnimationContext();
end

function getAnimationContextSecondaryNameFromMultiSpawnerComponentBySpawnerUH(uh)
	return getInstanceType(getMultispawnerComponentBySpawnerSpawnerUH(uh)):getSpawnerAnimationContextSecondary();
end

function getSlideToGameAreaTimeMsecFromMultiSpawnerComponentBySpawnerUH(uh)
	return getInstanceType(getMultispawnerComponentBySpawnerSpawnerUH(uh)):getSlideToGameAreaTimeMsec();
end

function getLastSpawnPointUHFromMultiSpawnerComponentBySpawnerUH(uh)
	return getMultispawnerComponentBySpawnerSpawnerUH(uh):getLastSpawnPointUH();
end

function getRandomTargetPointUHFromMultiSpawnerComponentBySpawnerUH(uh)
	return getMultispawnerComponentBySpawnerSpawnerUH(uh):getRandomTargetPointUH();
end

------

function getAnimationContextNameByMultispawnerComponent(obj)
	return getInstanceType(obj):getSpawnerAnimationContext();
end

function getAnimationContextSecondaryNameByMultispawnerComponent(obj)
	return getInstanceType(obj):getSpawnerAnimationContextSecondary();
end

function getSlideToGameAreaTimeMsecByMultispawnerComponent(obj)
	return getInstanceType(obj):getSlideToGameAreaTimeMsec();
end

function getLastSpawnPointUHByMultispawnerComponent(obj)
	return obj:getLastSpawnPointUH();
end

function getRandomTargetPointUHByMultispawnerComponent(obj)
	return obj:getRandomTargetPointUH();
end

-------------------------------------------------------------------------------------------------
--
-- Shield grabbing stuff
--

function getGrabShieldComponent(obj)
	return findComponentFromObjectByClass(obj, trinebase.gameplay.wear.TrineGrabShieldComponent.getStaticObjectClass());
end

-------------------------------------------------------------------------------------------------
--
-- Random generator
--

function getRandomGenerator(obj)
	local finalOwner = obj;
	if obj.getFinalOwner then
		finalOwner = obj:getFinalOwner();
	end
	local rg = findComponentFromObjectByClass(obj, gameplay.RandomNumberGeneratorComponent.getStaticObjectClass());
	if rg ~= nil then
		return rg;
	end	
	if finalOwner ~= nil then
		logAIWarning(obj, "ai_utils:getRandomGenerator - Could not find RandomGenerator.");
	end	
	return nil;
end

-- Returns random float [minValue, maxValue[ or [0, 1[
function getRandomFloat(obj, minValue, maxValue, useLUARandom)
	-- NOTE: minValue or/and maxValue can be nil

	local generator = getRandomGenerator(obj);
	local baseValue = 0;
	
	if useLUARandom then
		baseValue = math.random();
	else
		if generator ~= nil then
			baseValue = generator:getRandomFloat();
		else
			logAIWarning(obj, "ai_utils:getRandomFloat - RandomGenerator is nil, using math.random.");
			baseValue = math.random();
		end
	end
	
	if minValue ~= nil and maxValue ~= nil then
		return baseValue * (maxValue - minValue) + minValue;
	else
		return baseValue;
	end
end

-- Returns random int [minValue, maxValue]
function getRandomInt(obj, minValue, maxValue, useLUARandom)
	return math.floor(getRandomFloat(obj, minValue, maxValue + 1, useLUARandom));
end

function getRandomPositiveIntWithOffsetValue(obj, minValue, offsetValue)
	if obj == nil then
		logErrorImpl("ai_utils:getRandomIntWithOffsetValue - Nil param obj given.");
		return 0;
	end
	
	if minValue == nil then
		logErrorImpl("ai_utils:getRandomIntWithOffsetValue - Nil param minValue given.");
		return 0;
	end
	
	if offsetValue == nil then
		logErrorImpl("ai_utils:getRandomIntWithOffsetValue - Nil param offsetValue given.");
		return 0;
	end
	
	-- Min value zero, cannot do anything, return zero
	if minValue <= 0 then
		return 0;
	end
	
	-- Add offset into equation ?
	if offsetValue > 0 then
		local minV = minValue;
		local maxV = minValue + offsetValue;
		local randomValue = getRandomInt(obj, minV, maxV, false);
		return randomValue;
	end
	
	-- Just return the min value
	return minValue;
end

function triggerRandomEventByPercentagePossibility(obj, percentage)
	if percentage == nil then
		logAIError(obj, "ai_utils:triggerRandomEventByPercentagePossibility - percentage param is nil.");
		return false;	
	end
	
	if percentage < 0 or percentage > 100 then
		logAIError(obj, "ai_utils:triggerRandomEventByPercentagePossibility - Invalid percentage param value, needs to be between 0 - 100.");
		return false;	
	end
	
	-- Never happens
	if percentage == 0 then
		return false;
	end
	
	-- Always happens
	if percentage == 100 then
		return true;
	end

	local randomValue = getRandomInt(obj, 0, 100);
	if randomValue <= percentage then
		return true;
	end
	
	-- Nothing happens
	return false;
end

-------------------------------------------------------------------------------------------------
--
-- Area damage stuff
--

function getContactDamageComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.damage.ContactDamageComponent.getStaticObjectClass());
end

function getAttachAreaToModelComponent(obj)
	return findComponentFromObjectByClass(obj, trinebase.gameplay.TrineAttachAreaToModelComponent.getStaticObjectClass());
end

function getPhysicsContactDamageToSelfComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.damage.PhysicsContactDamageToSelfComponent.getStaticObjectClass());
end

function getAreaContactDamageSubComponent(obj)
	return findSubComponentFromComponentByClass(obj, gameplay.damage.AreaContactDamageComponent.getStaticObjectClass());
end

function getRagdollPhysicsComponentSubComponent(obj)
	return findSubComponentFromComponentByClass(obj, physics.RagdollPhysicsComponent.getStaticObjectClass());
end

function getAreaComponentSubComponent(obj)
	return findSubComponentFromComponentByClass(obj, engine.component.AbstractAreaComponent.getStaticObjectClass());
end

function setAttachedAreaDamageStatus(obj, propActive, areaContactDamageComponent)
	local attachAreaToModel = nil;
	local areaContactDamage = areaContactDamageComponent;
	
	if areaContactDamage == nil then
		attachAreaToModel = getAttachAreaToModelComponent(obj);
		if attachAreaToModel ~= nil then
			areaContactDamage = getAreaContactDamageSubComponent(attachAreaToModel);
		end
	end

	if areaContactDamage ~= nil and areaContactDamage:getActive() ~= propActive then
		areaContactDamage:setActive(propActive);
	end
end

function setAttachedAreaHelperBoneName(obj, name, attachAreaToModelComponent)
	local attachAreaToModel = attachAreaToModelComponent;	
	if attachAreaToModel == nil then
		attachAreaToModel = getAttachAreaToModelComponent(obj);
	end

	if attachAreaToModel ~= nil and attachAreaToModel:getHelperBoneName() ~= name then
		attachAreaToModel:setHelperBoneName(name);
	end
end

function setAttachedAreaHelperBoneNameAndActiveStatus(obj, name, propActive)
	local attachAreaToModel = getAttachAreaToModelComponent(obj);
	
	if attachAreaToModel ~= nil then
		local areaContactDamage = getAreaContactDamageSubComponent(attachAreaToModel);
		if areaContactDamage ~= nil then	
			setAttachedAreaDamageStatus(obj, propActive, areaContactDamage);
			setAttachedAreaHelperBoneName(obj, name, attachAreaToModel);
		end
	end
end

function setAttachedAreaDamageStatusByAttachAreaToModelComponent(attachAreaToModelComponent, propActive)
	if attachAreaToModelComponent == nil then
		logErrorImpl("ai_utils:setAttachedAreaDamageStatusByAttachAreaToModelComponent - Nil param attachAreaToModelComponent given.");
		return;
	end
	
	if propActive == nil then
		logErrorImpl("ai_utils:setAttachedAreaDamageStatusByAttachAreaToModelComponent - Nil param propActive given.");
		return;
	end
	
	if attachAreaToModelComponent ~= nil then
		local areaContactDamage = getAreaContactDamageSubComponent(attachAreaToModelComponent);

		if areaContactDamage ~= nil then
			areaContactDamage:setActive(propActive);
		end
	end
end

-------------------------------------------------------------------------------------------------
--
-- Tracking stuff
--

function getTrackObjectsComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.TrackObjectsComponent.getStaticObjectClass());
end

function getTrackObjectsComponentActiveInstanceAmount(obj)
	return getTrackObjectsComponent(obj):getActiveInstanceAmount();	
end

function getTrackObjectsComponentActiveInstanceAmountFromTarget(obj)
	local targetInstance = getTargetInstance(obj);
	if targetInstance ~= nil then		
		return getTrackObjectsComponentActiveInstanceAmount(targetInstance);
	end
	return 0;	
end

function areTrackedObjectsInLookDirection(obj, aiCharacterComponent)
	local aiCC = aiCharacterComponent;	
	if aiCC == nil then	
		aiCC = getAICharacterComponent(obj);
	end
	return aiCC:areTrackedObjectsInDirection(true, true);
end

-- Enable if you need this
--function areTrackedObjectsInBackDirection(obj)
--	return getAICharacterComponent(obj):areTrackedObjectsInDirection(false, true);
--end

-------------------------------------------------------------------------------------------------
--
-- Object breaking
--

function getBreakableComponent(obj)
	return findComponentFromObjectByClass(obj, gameplay.damage.BreakableComponent.getStaticObjectClass());
end


function isBreakableObject(uh, ignoreAiCanBreakObject)
	if uh == UH_NONE then
		return false;
	end
	
	-- TODO: This should be a common util which checks is the object breakable with given weapon
	-- Should also notice if the object is immortal
	
	-- Break only wizard objects?
	--[[
	local scene = common.CommonUtils.getScene();
	if scene ~= nil then
		local upgradeManager = common.CommonUtils.getTrineUpgradeManager();
		if upgradeManager ~= nil then
			local isConjuredObject = upgradeManager:isUHConjuredObject(scene:getUnifiedHandle(), uh);
			if isConjuredObject then
				return true;
			end
		end
	end
	]]--
	
	local instance = common.CommonUtils.getSceneInstanceByUH(uh);
	
	if instance ~= nil then	
		-- Allow breaking only if object has healthComponent and breakableComponent
		local healthComponent = getHealthComponent(instance);
		local breakableComponent = getBreakableComponent(instance);
		
		local instanceType = getType(instance);
			
		if healthComponent == nil then	
			--[[
			-- HACK: If healthComponent is missing (e.g. object just got destroyed or something?), try to search the answer from type
			local hackThingyFoundTheComponent = false;
			local typeM = common.CommonUtils.getTypeManager();
			if instanceType ~= nil and typeM ~= nil then
				local compType = typeM:getStaticDefaultType(gameplay.damage.HealthComponent.getStaticClassId());
				if compType ~= nil then
					local foundType = instanceType:findComponentType(compType:getUnifiedHandle());
					if foundType ~= nil then
						hackThingyFoundTheComponent = true;
					end
				end				
			end
			
			if not hackThingyFoundTheComponent then
				return false;
			end
			--]]
			return false;
		end
		
		-- If frozen, allow breaking
		-- NOTE: Design didn't like this, commenting it out
		--if isFrozen(instance) then
		--	return true;
		--end
		
		if breakableComponent == nil then
			--[[
			-- HACK: If breakableComponent is missing (e.g. object just got destroyed or something?), try to search the answer from type
			-- NOTE: This overrides instances property value
			local typeM = common.CommonUtils.getTypeManager();
			if instanceType ~= nil and typeM ~= nil then
				local compType = typeM:getStaticDefaultType(gameplay.damage.BreakableComponent.getStaticClassId());
				if compType ~= nil then
					local foundType = instanceType:findComponentType(compType:getUnifiedHandle());
					if foundType ~= nil then
						local prop = foundType:getInstanceProperty("AiCanBreakObject");
						if prop == true then
							return true;
						end
					end
				end				
			end
			]]--
			return false;
		end
		
		if ignoreAiCanBreakObject then
			return true;
		end
		
		
		-- Allow breaking only if it's allowed to be broken by AI in BreakableComponent
		if breakableComponent:getAiCanBreakObject() then
			return true;
		end
	end
	
	return false;
end

function isCharacterObject(uh)
	if uh == UH_NONE then
		return false;
	end
	
	local instance = common.CommonUtils.getSceneInstanceByUH(uh);
	
	if instance ~= nil then	
		local controllerComponent = getControllerComponent(instance);
		if controllerComponent ~= nil then
			return true;
		end
	end
	
	return false;
end

function isCharacterObjectByInstance(instance)
	if instance == nil then
		return false;
	end
	
	local controllerComponent = getControllerComponent(instance);
	if controllerComponent ~= nil then
		return true;
	end
	return false;
end

function isPlayerCharacterObject(uh)
	if uh == UH_NONE then
		return false;
	end
	
	local instance = common.CommonUtils.getSceneInstanceByUH(uh);
	
	if instance ~= nil then	
		local controllerComponent = getControllerComponent(instance);
		if controllerComponent ~= nil then
			if controllerComponent:isControlledByPlayer() then
				return true;
			end
		end
	end
	
	return false;
end

function isAICharacterObject(uh)
	if uh == UH_NONE then
		return false;
	end
	
	local instance = common.CommonUtils.getSceneInstanceByUH(uh);
	
	if instance ~= nil then	
		local controllerComponent = getControllerComponent(instance);
		if controllerComponent ~= nil then
			if controllerComponent:isControlledByAI() then
				return true;
			end
		end
	end
	
	return false;
end

function shouldBreakObjectOnLeft(obj)
	if isDirectionToLeft(obj) then
		return isBreakableObject(getLastLeftContactDynamicUH(obj));
	end
	return false;
end

function shouldBreakObjectOnRight(obj)
	if isDirectionToRight(obj) then
		return isBreakableObject(getLastRightContactDynamicUH(obj));
	end
	return false;
end

-------------------------------------------------------------------------------------------------
--
-- Weapon stuff
--

function disableWeaponDamages(obj)
	local iter = getAllWeaponMeleeComponents(obj);
	if iter ~= nil then
		local weaponComponent = iter:next();
		while weaponComponent ~= nil do
			if weaponComponent.enableDamage then
				weaponComponent:enableDamage(false);
			end
			
			weaponComponent = iter:next()
		end
	end
	
	local weaponMultiMeleeComponent = getWeaponMultiMeleeComponent(obj);
	if weaponMultiMeleeComponent ~= nil then
		local iter = getAllWeaponMeleeComponentsFromComponent(weaponMultiMeleeComponent);
		local weaponComponent = iter:next();
		while weaponComponent ~= nil do
			
			if weaponComponent.enableDamage then
				weaponComponent:enableDamage(false);
			end
			
			weaponComponent = iter:next()
		end
	end
end

function enableWeaponContextsImpl(obj, enabled)
	local shieldComponent = getShieldComponent(obj);
	if shieldComponent ~= nil then
		if enabled then
			shieldComponent:enableShieldContext();
		else
			shieldComponent:disableShieldContext();		
		end
	end
	
	local iter = getAllWeaponMeleeComponents(obj);
	if iter ~= nil then
		local weaponComponent = iter:next();
		while weaponComponent ~= nil do
			if enabled then
				weaponComponent:enableWeaponContext();
			else
				weaponComponent:disableWeaponContext();	
			end
			weaponComponent = iter:next()
		end
	end
	
	local weaponMultiMeleeComponent = getWeaponMultiMeleeComponent(obj);
	if weaponMultiMeleeComponent ~= nil then
		local iter = getAllWeaponMeleeComponentsFromComponent(weaponMultiMeleeComponent);
		local weaponComponent = iter:next();
		while weaponComponent ~= nil do
			if enabled then
				weaponComponent:enableWeaponContext();
			else
				weaponComponent:disableWeaponContext();	
			end
			weaponComponent = iter:next()
		end
	end
end

function enableWeaponContexts(obj)
	enableWeaponContextsImpl(obj, true);
end

function disableWeaponContexts(obj)
	enableWeaponContextsImpl(obj, false);
end

function enableMultiWeaponAttachedEffects(obj, enabled)
	local weaponMultiMeleeComponent = getWeaponMultiMeleeComponent(obj);
	if weaponMultiMeleeComponent ~= nil then
		local iter = getAllWeaponMeleeComponentsFromComponent(weaponMultiMeleeComponent);
		local weaponComponent = iter:next();
		while weaponComponent ~= nil do
			local weaponInstance = getWeaponInstanceFromWeaponComponent(weaponComponent);
			if weaponInstance ~= nil then
				local attachEffectComponent = getAttachEffectComponent(weaponInstance);
				if attachEffectComponent ~= nil then
					attachEffectComponent:setEnabled(enabled);
				end
			end
			weaponComponent = iter:next()
		end
	end
end

-------------------------------------------------------------------------------------------------
--
-- Group stuff
--

function isAIInGroup(obj, aiCharacterComponent)
	local aiCC = aiCharacterComponent;	
	if aiCC == nil then	
		aiCC = getAICharacterComponent(obj);
	end
	return aiCC:getInGroup();
end

function setAIInGroup(obj, val, aiCharacterComponent)
	local acc = aiCharacterComponent;
	if acc == nil then
		acc = getAICharacterComponent(obj);
	end
	
	if acc:getInGroup() ~= val then
		acc:setInGroup(val);
	end
end

function setAIIgnoreThisAIFromGroups(obj, val, aiCharacterComponent)
	local acc = aiCharacterComponent;
	if acc == nil then
		acc = getAICharacterComponent(obj);
	end	
	
	if acc:getIgnoreThisAIFromGroups() ~= val then
		acc:setIgnoreThisAIFromGroups(val);
	end
end

function updateAIGroupStatus(obj, aiCharacterComponent)
	local acc = aiCharacterComponent;
	if acc == nil then
		acc = getAICharacterComponent(obj);
	end	
	acc:updateAIGroupStatus();
end

-------------------------------------------------------------------------------------------------
--
-- Shooter helper (Archer goblins)
--

function getShooterHelperCollectorComponent(obj)
	return findComponentFromObjectByClass(obj, platformer.gameplay.PlatformerShooterAreaTriggerCollectorComponent.getStaticObjectClass());
end

function clearShooterHelper(obj)
	return getShooterHelperCollectorComponent(obj):clearShooterHelper();
end

function getNewShooterHelper(obj)
    local shcc = getShooterHelperCollectorComponent(obj)
    if shcc then 
        
        local uhOld = shcc:getCurrentShooterHelper()  
        local targetPos = VC3(0,0,0)
        if gameplay.ai.AiUtils.hasTarget(obj) then
            local customPos = gameplay.ai.AiUtils.getCustomTargetPosEnabled(obj)
            gameplay.ai.AiUtils.setCustomTargetPosEnabled(obj, false)
            if gameplay.ai.AiUtils.hasTarget(obj) then          
                targetPos = gameplay.ai.AiUtils.getTargetPos(obj, getTargetComponent(obj))
            end
            gameplay.ai.AiUtils.setCustomTargetPosEnabled(obj, customPos)    
        end
        
        local uh = shcc:setNewShooterHelper(targetPos)
        
        --if uh == uhOld then -- the same shooter helper, continue doing what we were doing
        --    return false
        --end
        
        if uh ~= UH_NONE then
            local sh = getShooterHelperComponentByInstanceUH(uh)
            if sh then
                local tfc = sh:getFinalOwner():getTransformComponent();
                if tfc then                    
                    gameplay.ai.AiUtils.setCustomTargetPosEnabled(obj, true)	
                    gameplay.ai.AiUtils.setCustomTargetPos(obj, tfc:getPosition())                
                    return true
                 end
            end
        end
    end    
    return false
end

function setNoShooterHelper(obj)
    local shcc = getShooterHelperCollectorComponent(obj)
    if shcc then    
        local uh = shcc:setCurrentShooterHelper(UH_NONE)
    end
end

function isValidCurrentShooterHelper(obj)
    local shcc = getShooterHelperCollectorComponent(obj)
    if shcc then
        return shcc:isValidCurrentShooterHelper()  
    else
        return false;
    end  
end

function hasShooterHelper(obj)
    local shcc = getShooterHelperCollectorComponent(obj)
    if shcc then
        return shcc:hasShooterHelper()  
    else
        return false;
    end  
end

function getShooterHelperComponentByInstanceUH(uh)

	if uh == UH_NONE then
		logErrorImpl("ai_utils:getShooterHelperComponentByInstanceUH - Invalid unified handle.");
		return nil;
	end
	
	local helperInst = common.CommonUtils.getSceneInstanceByUH(uh);
	if helperInst == nil then
		logErrorImpl("ai_utils:getShooterHelperComponentByInstanceUH - No such instance found.");
		return nil;
	end
		
	local helperComp = findComponentFromObjectByClass(helperInst, platformer.ai.PlatformerAIPathHelperShooterHelperComponent.getStaticObjectClass());
	return helperComp;	
end

function setMovingTowardsShooterHelper(obj)
    local shcc = getShooterHelperCollectorComponent(obj)
    if shcc and hasShooterHelper(obj) then
        local sh = shcc:getCurrentShooterHelper()
        local targetComponent = getTargetComponent(obj)
		if setTarget(obj, sh, targetComponent) then            
            if(isTargetOnLeft(obj)) then
                moveStateLeft(obj)
                return true;
            else
                moveStateRight(obj)
                return true
            end
        end
    end
	return false;
end

function getShootHelperPosition(obj)
    local shcc = getShooterHelperCollectorComponent(obj)
    if shcc and hasShooterHelper(obj) then
        local shUH = shcc:getCurrentShooterHelper()
        local sh = getShooterHelperComponentByInstanceUH(shUH)
        return sh:getTargetPosition()
    end  

    return VC3(0, 0 , 0)  
end

function getShooterHelperTargetRadius(obj)
    local shUH = getCurrentShooterHelper(obj)
    if shUH ~= UH_NONE then
        local sh = getShooterHelperComponentByInstanceUH(shUH)
        return sh:getRunTargetRadius()
    end   

    return 0 
end

function getCurrentShooterHelper(obj)
    local shcc = getShooterHelperCollectorComponent(obj)
    if shcc and hasShooterHelper(obj) then
        local shUH = shcc:getCurrentShooterHelper()
        return shUH
    end   

    return UH_NONE 
end
function isInAShooterHelperArea(obj)
    local shcc = getShooterHelperCollectorComponent(obj)
    if shcc then
        local shUH = shcc:getInShooterHelper()
        return shUH
    end
    
    return false
end
-------------------------------------------------------------------------------------------------
--
-- JumpHelper (for climbing dynamic objects)
--

function getJumpHelperComponent(obj)
    return findComponentFromObjectByClass(obj, trinebase.gameplay.ai.TrineAIPathHelperJumpHelperComponent.getStaticObjectClass());
end

function isJumpActionOnProcess(obj)
    local jumpHelper = getJumpHelperComponent(obj);    
    if jumpHelper ~= nil then
        local currentObjectUH = jumpHelper:getCurrentObjectUH();
        if currentObjectUH ~= UH_NONE then
			return true;
		end
    end
	
	return false;
end

function resetJumpOverRootMotionPosition(obj)
    local jumpHelper = getJumpHelperComponent(obj);    
    if jumpHelper ~= nil then
        jumpHelper:setJumpOverRootMotionPos(VC3(0,0,0));
    end
end

function getJumpOverRootMotionPosition(obj)
    local jumpHelper = getJumpHelperComponent(obj);    
    if jumpHelper ~= nil then
        return jumpHelper:getJumpOverRootMotionPos();
    end    
    return nil;
end

-------------------------------------------------------------------------------------------------
--
-- Effect spawning
--

function isFrozen(obj)
	local frozeMeComponent = getFrozeMeComponent(obj);
	if frozeMeComponent ~= nil then
		return frozeMeComponent:isFrozen()
	end
	return false;
end

--[[
function spawnEnemyEffectChangeWeapon(obj)
	local doEffectComponent = getEnemyDoEffectComponent(obj);
	if doEffectComponent == nil then
		return false;
	end	
	doEffectComponent:spawnWithEffectEntityUH(doEffectComponent:getEffectEntityForChangeWeapon());
	return true;
end

function spawnEnemyEffectJump(obj)
	local doEffectComponent = getEnemyDoEffectComponent(obj);
	if doEffectComponent == nil then
		return false;
	end	
	doEffectComponent:spawnWithEffectEntityUH(doEffectComponent:getEffectEntityForJump());
	return true;
end

function spawnEnemyEffectLand(obj)
	local doEffectComponent = getEnemyDoEffectComponent(obj);
	if doEffectComponent == nil then
		return false;
	end	
	doEffectComponent:spawnWithEffectEntityUH(doEffectComponent:getEffectEntityForLand());
	return true;
end
]]--

function spawnEnemyEffectSquashing(obj)
	local doEffectComponent = getEnemyDoEffectComponent(obj);
	if doEffectComponent == nil then
		return false;
	end	
	doEffectComponent:spawnWithEffectEntityUH(doEffectComponent:getEffectEntityForSquashing());
	return true;
end

function spawnEnemyEffectDeath(obj, pos)
	if isFrozen(obj) then
		return false;
	end
	local doEffectComponent = getEnemyDoEffectComponent(obj);
	if doEffectComponent == nil then
		return false;
	end	
	
	if pos == nil then
		local healthComponent = gameplay.ai.AiUtils.getHealthComponent(obj)
		if healthComponent then
			doEffectComponent:spawnUsingHitInfoFromHealthComponent(doEffectComponent:getEffectEntityForDeath(), healthComponent)
		else
			doEffectComponent:spawnWithEffectEntityUH(doEffectComponent:getEffectEntityForDeath());
		end
	else
		doEffectComponent:spawnWithEffectEntityUHInPosition(doEffectComponent:getEffectEntityForDeath(), pos);
	end

	return true;
end

--[[
function spawnEnemyEffectDrowning(obj)
	local doEffectComponent = getEnemyDoEffectComponent(obj);
	if doEffectComponent == nil then
		return false;
	end	
	doEffectComponent:spawnWithEffectEntityUH(doEffectComponent:getEffectEntityForDrowning());
	return true;
end
]]--

function spawnEnemyEffectNormalHit(obj, pos, rot)
	if isFrozen(obj) then
		return false;
	end
	local doEffectComponent = getEnemyDoEffectComponent(obj);
	if doEffectComponent == nil then
		return false;
	end
	
	if pos == nil and rot == nil then
		doEffectComponent:spawnWithEffectEntityUH(doEffectComponent:getEffectEntityForNormalHit());
	elseif rot == nil then
		doEffectComponent:spawnWithEffectEntityUHInPosition(doEffectComponent:getEffectEntityForNormalHit(), pos);
	else
		doEffectComponent:spawnWithEffectEntityUHInPositionAndRotation(doEffectComponent:getEffectEntityForNormalHit(), pos, rot);
	end
	return true;
end

--[[
function spawnEnemyEffectHighfallNoDamage(obj)
	local doEffectComponent = getEnemyDoEffectComponent(obj);
	if doEffectComponent == nil then
		return false;
	end	
	doEffectComponent:spawnWithEffectEntityUH(doEffectComponent:getEffectEntityForHighfallNoDamage());
	return true;
end
]]--

function spawnEnemyEffectIdle(obj)
	local doEffectComponent = getEnemyDoEffectComponent(obj);
	if doEffectComponent == nil then
		return false;
	end	
	
	doEffectComponent:spawnWithEffectEntityUH(doEffectComponent:getEffectEntityForIdle());
	return true;
end

function spawnEnemyEffectSpot(obj)
	local doEffectComponent = getEnemyDoEffectComponent(obj);
	if doEffectComponent == nil then
		return false;
	end	
	doEffectComponent:spawnWithEffectEntityUH(doEffectComponent:getEffectEntityForSpot());
	return true;
end

function spawnEnemyEffectTaunt(obj)
	local doEffectComponent = getEnemyDoEffectComponent(obj);
	if doEffectComponent == nil then
		return false;
	end	
	doEffectComponent:spawnWithEffectEntityUH(doEffectComponent:getEffectEntityForTaunt());
	return true;
end

function spawnEnemyEffectRushTowardsPlayer(obj)
	local doEffectComponent = getEnemyDoEffectComponent(obj);
	if doEffectComponent == nil then
		return false;
	end	
	doEffectComponent:spawnWithEffectEntityUH(doEffectComponent:getEffectEntityForRushTowardsPlayer());
	return true;
end

function spawnEnemyEffectLevitated(obj)
	local doEffectComponent = getEnemyDoEffectComponent(obj);
	if doEffectComponent == nil then
		return false;
	end	
	doEffectComponent:spawnWithEffectEntityUH(doEffectComponent:getEffectEntityForLevitated());
	return true;
end

function spawnEnemyEffectFallDown(obj)
	local doEffectComponent = getEnemyDoEffectComponent(obj);
	if doEffectComponent == nil then
		return false;
	end	
	doEffectComponent:spawnWithEffectEntityUH(doEffectComponent:getEffectEntityForFallDown());
	return true;
end

function spawnEnemyEffectSpawnJumpFromBackground(obj)
	local doEffectComponent = getEnemyDoEffectComponent(obj);
	if doEffectComponent == nil then
		return false;
	end	
	doEffectComponent:spawnWithEffectEntityUH(doEffectComponent:getEffectEntityForJumpFromBackground());
	return true;
end

function spawnEnemyEffectCloseCombat(obj)
	local doEffectComponent = getEnemyDoEffectComponent(obj);
	if doEffectComponent == nil then
		return false;
	end	
	doEffectComponent:spawnWithEffectEntityUH(doEffectComponent:getEffectEntityForCloseCombat());
	return true;
end

function spawnEnemyEffectRangedCombat(obj)
	local doEffectComponent = getEnemyDoEffectComponent(obj);
	if doEffectComponent == nil then
		return false;
	end	
	doEffectComponent:spawnWithEffectEntityUH(doEffectComponent:getEffectEntityForRangedCombat());
	return true;
end

--[[
function spawnEnemyEffectRetreat(obj)
	local doEffectComponent = getEnemyDoEffectComponent(obj);
	if doEffectComponent == nil then
		return false;
	end	
	doEffectComponent:spawnWithEffectEntityUH(doEffectComponent:getEffectEntityForRetreat());
	return true;
end

function spawnEnemyEffectScared(obj)
	local doEffectComponent = getEnemyDoEffectComponent(obj);
	if doEffectComponent == nil then
		return false;
	end	
	doEffectComponent:spawnWithEffectEntityUH(doEffectComponent:getEffectEntityForScared());
	return true;
end
]]--

function spawnEnemyEffectMeleeWeaponSwing(obj)
	local audioComponent = getAudioComponent(obj);
	
	if audioComponent == nil then
		return false;
	end
	
	local weaponMeleeComponent = getWeaponMeleeComponent(obj);
	if weaponMeleeComponent ~= nil then
		audioComponent:postEventLua(weaponMeleeComponent:getAudioEventWeaponSwing());
		return true;
	end
	
	local weaponMeleeComponent = getWeaponMeleeComponent(obj);
	if weaponMeleeComponent ~= nil then
		audioComponent:postEventLua(weaponMeleeComponent:getAudioEventWeaponSwing());
		return true;
	end	

	local weaponMultiMeleeComponent = getWeaponMultiMeleeComponent(obj);
	if weaponMultiMeleeComponent ~= nil then
		local iter = getAllWeaponMeleeComponentsFromComponent(weaponMultiMeleeComponent);
		local weaponComponent = iter:next();
		while weaponComponent ~= nil do
			-- Do only for first weapon
			audioComponent:postEventLua(weaponComponent:getAudioEventWeaponSwing());
			--weaponComponent = iter:next()
			return true;			
		end
	end
	
	return false;
end

function isFrozen(obj)
	local trineFrozeMeComponent = getTrineFrozeMeComponent(obj);
	return trineFrozeMeComponent and trineFrozeMeComponent:isFrozen();
end

function startLevitationStartAudio(obj)
	local healthComponent = gameplay.ai.AiUtils.getHealthComponent(obj)
	if healthComponent and healthComponent:isAlive() then
		local floatingInfo = obj:getFinalOwner():findComponent(trinebase.gameplay.skills.FloatingInfoComponent)
		if floatingInfo and floatingInfo:getIsBeingFloated() then
			if not isFrozen(obj) then
				local audioComponent = obj:getFinalOwner():findComponent(audio.AudioComponent)
				if audioComponent then
					local enemyDoEffectComponent = obj:getFinalOwner():findComponent(gameplay.effect.EnemyDoEffectComponent)
					if enemyDoEffectComponent then
						audioComponent:postEventLua(enemyDoEffectComponent:getAudioEventLevitateStart())
					end
				end
			end
		end
	end	
end

function stopLevitationStartAudio(obj)
	local audioComponent = obj:getFinalOwner():findComponent(audio.AudioComponent)
	if audioComponent then
		local enemyDoEffectComponent = obj:getFinalOwner():findComponent(gameplay.effect.EnemyDoEffectComponent)
		if enemyDoEffectComponent then
			audioComponent:postEventLua(enemyDoEffectComponent:getAudioEventLevitateStop())
		end
	end	
end

-------------------------------------------------------------------------------------------------
--
-- Event validation
--

function validateEventsForWalkingWithHelpersAI(obj)
	if (FB_BUILD == "FB_FINAL_RELEASE") then
		return;
	end

	--
	-- Make sure that some events exists on all states
	--
	
	-- NOTE: This is very hacky and idiot way of checking invalid states
	-- TODO: Should implement util in to ScriptedStateComponent which takes ignore state list as a param and returns list of states which are missing the given state call.
	--       Now just loops trough all states (except common states) and returns the first missing state :) I'm lazy...
	
	local str = "";
	
	str = obj:getFirstMissingStateCallStateName("EventOnDamage");
	if string.len(str) > 0 then
		logAIError(obj, "ai_utils:validateEventsForWalkingWithHelpersAI - \"EventOnDamage\" event is missing from state: \"" .. str .. "\" for AI type \"" .. getFinalOwnerTypeName(obj) .. "\".");
	end
	
	str = obj:getFirstMissingStateCallStateName("EventAnimStaggerFinished");
	if string.len(str) > 0 then
		logAIError(obj, "ai_utils:validateEventsForWalkingWithHelpersAI - \"EventAnimStaggerFinished\" event is missing from state: \"" .. str .. "\" for AI type \"" .. getFinalOwnerTypeName(obj) .. "\".");
	end
	
	str = obj:getFirstMissingStateCallStateName("EventLevitateStart");
	if string.len(str) > 0 then
		logAIError(obj, "ai_utils:validateEventsForWalkingWithHelpersAI - \"EventLevitateStart\" event is missing from state: \"" .. str .. "\" for AI type \"" .. getFinalOwnerTypeName(obj) .. "\".");
	end
	
	str = obj:getFirstMissingStateCallStateName("EventSquashStart");
	if string.len(str) > 0 then
		logAIError(obj, "ai_utils:validateEventsForWalkingWithHelpersAI - \"EventSquashStart\" event is missing from state: \"" .. str .. "\" for AI type \"" .. getFinalOwnerTypeName(obj) .. "\".");
	end	
end

function validateEventsForFlyingEnemyAI(obj)
	if (FB_BUILD == "FB_FINAL_RELEASE") then
		return;
	end

	--
	-- Make sure that some events exists on all states
	--
	
	-- NOTE: This is very hacky and idiot way of checking invalid states
	-- TODO: Should implement util in to ScriptedStateComponent which takes ignore state list as a param and returns list of states which are missing the given state call.
	--       Now just loops trough all states (except common states) and returns the first missing state :) I'm lazy...
	
	local str = "";
	
	str = obj:getFirstMissingStateCallStateName("EventOnDamage");
	if string.len(str) > 0 then
		logAIError(obj, "ai_utils:validateEventsForFlyingEnemyAI - \"EventOnDamage\" event is missing from state: \"" .. str .. "\" for AI type \"" .. getFinalOwnerTypeName(obj) .. "\".");
	end
	
	str = obj:getFirstMissingStateCallStateName("EventAnimStaggerFinished");
	if string.len(str) > 0 then
		logAIError(obj, "ai_utils:validateEventsForFlyingEnemyAI - \"EventAnimStaggerFinished\" event is missing from state: \"" .. str .. "\" for AI type \"" .. getFinalOwnerTypeName(obj) .. "\".");
	end
end

-------------------------------------------------------------------------------------------------

function getWeaponInstanceFromWeaponComponent(obj)
	local uh = obj:getWeaponInstance()
	if uh == UH_NONE then
		logAIError(obj, "ai_utils:getWeaponInstanceFromWeaponComponent - WeaponInstance UH is NONE.");
		return nil;
	end
	local weaponInstance = common.CommonUtils.getSceneInstanceByUH(uh);
	if weaponInstance == nil then
		-- Not an error (instance might be already deleted, handle the error in the caller function)
		--logAIError(obj, "ai_utils:getWeaponInstanceFromWeaponComponent - WeaponInstance is nil.");
		return nil;
	end
	return weaponInstance;
end

-------------------------------------------------------------------------------------------------
--
-- Animation stuff
--
function getRootMotionBonePosition(obj, animationComponent)
	local animC = animationComponent;
	if animC == nil then
		animC = getAnimationComponent(obj);
	end
	
	return animC:getRootMotionBonePosition();
end

-------------------------------------------------------------------------------------------------

function setCustomGravity(obj, value)
    local physC = findComponentFromObjectByClass(obj, platformer.physics.PlatformerCharacterPhysicsComponent.getStaticObjectClass());
    if physC then
        physC:setCustomGravity(value)
    end
end

-------------------------------------------------------------------------------------------------
--
-- Shield stuff
--

function getShieldLastWeaponHitTypeUH(obj, shieldComponent)
	local sc = shieldComponent;
	if sc == nil then
		sc = getShieldComponent(obj);
	end
	
	return sc:getLastWeaponHitType();
end

function getShieldLastWeaponHitType(obj, shieldComponent)
	local weaponHitTypeUH = getShieldLastWeaponHitTypeUH(obj, shieldComponent)
	if weaponHitTypeUH == UH_NONE then
		-- Not an error
		--logAIError(obj, "ai_utils:getShieldLastWeaponHitType - ShieldLastWeaponHitTypeUH is UH_NONE.");
		return nil;
	end
	
	return common.CommonUtils.getTypeManager():getTypeByUH(weaponHitTypeUH);
end

-------------------------------------------------------------------------------------------------
--
-- AIPathHelper feature stuff (these components gives more functionality to the AIPathHelpers)
--

function getPlatformerAIPathHelperFeatureTrackObjectsComponent(obj)
	return findComponentFromObjectByClass(obj, platformer.ai.PlatformerAIPathHelperFeatureTrackObjectsComponent.getStaticObjectClass());
end

function getPlatformerAIPathHelperFeatureTrackObjectsComponentByAIPathHelperUH(uh)
	if uh == UH_NONE then
		logErrorImpl("ai_utils:getPlatformerAIPathHelperFeatureTrackObjectsComponentByAIPathHelperUH - UH_NONE given.");
		return nil;
	end

	local obj = common.CommonUtils.getSceneInstanceByUH(uh);
	if obj == nil then
		return nil;
	end
	
	return getPlatformerAIPathHelperFeatureTrackObjectsComponent(obj);
end

-------------------------------------------------------------------------------------------------

function isTargetOnRope(obj, targetComponent)
	local tc = targetComponent;
	
	if tc == nil then	
		tc = getTargetComponent(obj);
	end
	
	if hasTarget(obj, tc) then
		local targetInstance = getTargetInstance(obj, tc);
		if targetInstance ~= nil then
			local rc = getRopeComponent(targetInstance);
			if rc ~= nil then
				return rc:getOnRope();
			end
		else
			-- Just ignore
			--logAIError(obj, "ai_utils:isTargetOnRope - No target instance found with given UH.");		
		end
	else
		logAIError(obj, "ai_utils:isTargetOnRope - No target specified.");
	end
	
	return false;
end

-------------------------------------------------------------------------------------------------
--
-- Random DLC stuff
--

function setCustomProjectileStartPosition(obj, shootComponent, shootOffsetX, shootOffsetZ)
	if shootComponent == nil then
		logAIError(obj, "ai_utils:setCustomProjectileStartPosition - shootComponent is nil.");
		return;
	end
	
	if shootOffsetX == nil then
		logAIError(obj, "ai_utils:setCustomProjectileStartPosition - shootOffsetX is nil.");
		return;
	end
	
	if shootOffsetZ == nil then
		logAIError(obj, "ai_utils:setCustomProjectileStartPosition - shootOffsetZ is nil.");
		return;
	end
	
	if not shootComponent:getCustomProjectileStartPositionEnabled() then
		shootComponent:setCustomProjectileStartPositionEnabled(true);
	end
			
	if not isDirectionToRight(obj) then
		shootOffsetX = shootOffsetX * -1;
	end
	
	local offset = VC3(shootOffsetX, 0, shootOffsetZ);	
	local customShootPos = getRootMotionBonePosition(obj) + offset;
	shootComponent:setCustomProjectileStartPosition(customShootPos);
end

-------------------------------------------------------------------------------------------------
--
-- DLC Boss
--

function setAnimationSpeedFactorForAllAttachedWeapons(obj, speedFactor)
	local weaponMultiComponent = getWeaponMultiAnimatedWeaponComponent(obj);
	if weaponMultiComponent ~= nil then
		local iter = getAllWeaponAnimatedComponentsFromComponent(weaponMultiComponent);
		local weaponComponent = iter:next();
		while weaponComponent ~= nil do
			local weaponInstanceUH = weaponComponent:getWeaponInstanceUH();
			if weaponInstanceUH ~= UH_NONE then
				local weaponInstance = common.CommonUtils.getSceneInstanceByUH(weaponInstanceUH);
				if weaponInstance ~= nil then
					local animationComponent = getAnimationComponent(weaponInstance);
					if animationComponent ~= nil and animationComponent:getSpeedFactor() ~= speedFactor then
						animationComponent:setSpeedFactor(speedFactor);
					end
				end
			end
			weaponComponent = iter:next();
		end
	end
end

function setClosestSpottedTargetAsTargetForAllAttachedWeapons(obj)	
	local weaponMultiComponent = getWeaponMultiAnimatedWeaponComponent(obj);
	if weaponMultiComponent ~= nil then
		local iter = getAllWeaponAnimatedComponentsFromComponent(weaponMultiComponent);
		local weaponComponent = iter:next();
		while weaponComponent ~= nil do
			local weaponInstanceUH = weaponComponent:getWeaponInstanceUH();
			if weaponInstanceUH ~= UH_NONE then
				local weaponInstance = common.CommonUtils.getSceneInstanceByUH(weaponInstanceUH);
				if weaponInstance ~= nil then
					local targetComponent = getTargetComponent(weaponInstance);
					if targetComponent ~= nil then
						setClosestSpottedTargetAsTarget(weaponInstance, targetComponent);
					end
				end
			end			
			weaponComponent = iter:next();
		end
	end
end

function setTargetForAllAttachedWeapons(obj, target)
	local weaponMultiComponent = getWeaponMultiAnimatedWeaponComponent(obj);
	if weaponMultiComponent ~= nil then
		local iter = getAllWeaponAnimatedComponentsFromComponent(weaponMultiComponent);
		local weaponComponent = iter:next();
		while weaponComponent ~= nil do
			local weaponInstanceUH = weaponComponent:getWeaponInstanceUH();
			if weaponInstanceUH ~= UH_NONE then
				local weaponInstance = common.CommonUtils.getSceneInstanceByUH(weaponInstanceUH);
				if weaponInstance ~= nil then
					local targetComponent = getTargetComponent(weaponInstance);
					if targetComponent ~= nil then
						--local success = setTarget(weaponInstance, target, targetComponent);
						targetComponent:setTarget(target);
					end
				end
			end			
			weaponComponent = iter:next();
		end
	end
end

function getAttachedWeaponInstanceUH(obj, index)
	local i = 0;
	local weaponMultiComponent = getWeaponMultiAnimatedWeaponComponent(obj);
	if weaponMultiComponent ~= nil then
		local iter = getAllWeaponAnimatedComponentsFromComponent(weaponMultiComponent);
		local weaponComponent = iter:next();
		while weaponComponent ~= nil do
			if i == index then
				return weaponComponent:getWeaponInstanceUH();
			end
			
			i = i + 1;
			
			weaponComponent = iter:next();
		end
	end
	
	return UH_NONE;
end

function getAttachedWeaponInstance(obj, index)
	local weaponInstanceUH = getAttachedWeaponInstanceUH(obj, index);
	if weaponInstanceUH == UH_NONE then
		return nil;
	end
	
	return common.CommonUtils.getSceneInstanceByUH(weaponInstanceUH);
end

function getAttachedWeaponAnimationComponent(obj, index)
	local weaponInstance = getAttachedWeaponInstance(obj, index);
	if weaponInstance ~= nil then
		return getAnimationComponent(weaponInstance);
	end
end

function getAttachedWeaponTargetPositionToAnimationParamsComponent(obj, index)
	local weaponInstance = getAttachedWeaponInstance(obj, index);
	if weaponInstance ~= nil then
		return getTargetPositionToAnimationParamsComponent(weaponInstance);
	end
end

function getAttachedWeaponHittableComponent(obj, index)
	local weaponInstance = getAttachedWeaponInstance(obj, index);
	if weaponInstance ~= nil then
		return getHittableComponent(weaponInstance);
	end
end

function getAttachedWeaponModelComponent(obj, index)
	local weaponInstance = getAttachedWeaponInstance(obj, index);
	if weaponInstance ~= nil then
		return getModelComponent(weaponInstance);
	end
end

function getAttachedWeaponTargetComponent(obj, index)
	local weaponInstance = getAttachedWeaponInstance(obj, index);
	if weaponInstance ~= nil then
		return getTargetComponent(weaponInstance);
	end
end

function getAttachedWeaponShootComponent(obj, index)
	local weaponInstance = getAttachedWeaponInstance(obj, index);
	if weaponInstance ~= nil then
		return getRangedWeaponComponent(weaponInstance);
	end
end

function getAttachedWeaponFireSweepComponent(obj, index)
	local weaponInstance = getAttachedWeaponInstance(obj, index);
	if weaponInstance ~= nil then
		return getTrineFireSweepComponent(weaponInstance);
	end
end

function getAttachedWeaponAudioComponent(obj, index)
	local weaponInstance = getAttachedWeaponInstance(obj, index);
	if weaponInstance ~= nil then
		return getAudioComponent(weaponInstance);
	end
end

function getAttachedWeaponAttachEffectComponent(obj, index)
	local weaponInstance = getAttachedWeaponInstance(obj, index);
	if weaponInstance ~= nil then
		return getAttachEffectComponent(weaponInstance);
	end
end

function getAttachedWeaponPhysicsComponent(obj, index)
	local weaponInstance = getAttachedWeaponInstance(obj, index);
	if weaponInstance ~= nil then
		return getPhysicsComponent(weaponInstance);
	end
end

function setAttachedWeaponImmortal(obj, index, immortal)
	local weaponInstance = getAttachedWeaponInstance(obj, index);
	if weaponInstance ~= nil then
		local healthComponent = getHealthComponent(weaponInstance);
		if healthComponent ~= nil then
			if healthComponent:getImmortal() ~= immortal then
				healthComponent:setImmortal(immortal);
			end
		end
	end
end

function getAttachedWeaponSubAttachedWeaponInstance(obj, attachedWeapon, attachedWeaponSub)
	local weaponInstace = gameplay.ai.AiUtils.getAttachedWeaponInstance(obj, attachedWeapon);
	if weaponInstace == nil then
		logAIError(obj, "AiUtils:getAttachedWeaponSubAttachedWeaponInstance - No weapon instance found with given index: " .. tostring(attachedWeapon));
		return nil;
	end
	
	local weaponSubInstace = gameplay.ai.AiUtils.getAttachedWeaponInstance(weaponInstace, attachedWeaponSub);
	if weaponSubInstace == nil then
		logAIError(obj, "AiUtils:getAttachedWeaponSubAttachedWeaponInstance - No weapon sub instance found with given index: " .. tostring(attachedWeaponSub));
		return nil;
	end
	
	return weaponSubInstace;
end

function getAttachedWeaponSubAttachedWeaponAnimationComponent(obj, attachedWeapon, attachedWeaponSub)
	local weaponSubInstace = getAttachedWeaponSubAttachedWeaponInstance(obj, attachedWeapon, attachedWeaponSub);
	if weaponSubInstace ~= nil then
		return getAnimationComponent(weaponSubInstace);
	end	
	return nil;
end

function getAttachedWeaponSubAttachedWeaponHittableComponent(obj, attachedWeapon, attachedWeaponSub)
	local weaponSubInstace = getAttachedWeaponSubAttachedWeaponInstance(obj, attachedWeapon, attachedWeaponSub);
	if weaponSubInstace ~= nil then
		return getHittableComponent(weaponSubInstace);
	end	
	return nil;
end

function getAttachedWeaponTrineSpikesComponent(obj, index)
	local weaponInstance = getAttachedWeaponInstance(obj, index);
	if weaponInstance ~= nil then
		return getTrineSpikesComponent(weaponInstance);
	end
end

-------------------------------------------------------------------------------------------------

function isRunningEnabled(obj, aiCharacterComponent)
	local aiCC = aiCharacterComponent;
	
	if aiCC == nil then
		aiCC = getAICharacterComponent(obj);
	end
	
	return aiCC:getRunningEnabled();
end

-------------------------------------------------------------------------------------------------

function setVisibilityEnabled(obj, onlyForSpawnedAIs, doBaseModel, baseModelEnabled, doWeaponModelEnabled, weaponModelEnabled)
	if onlyForSpawnedAIs then
		local aiCC = getAICharacterComponent(obj);
		local aiSpawnerUH = aiCC:getAiSpawnerUH();
		if aiSpawnerUH == UH_NONE then
			-- If AI is placed into level directly from editor, don't do this visibility hack. Only for spawned AIs
			return;
		end
	end
	
	if doBaseModel then
		local modelComponent = getModelComponent(obj);
		if modelComponent ~= nil then
			if modelComponent:getVisibleInGame() ~= baseModelEnabled then
				modelComponent:setVisibleInGame(baseModelEnabled);
			end
			if modelComponent:getVisibilityEnabled() ~= baseModelEnabled then
				modelComponent:setVisibilityEnabled(baseModelEnabled);
			end
		else
			logAIError(obj, "AiUtils:setVisibilityEnabled - ModelComponent missing.");
		end
	end
	
	if doWeaponModelEnabled then
		local weaponMeleeComponent = getWeaponMeleeComponent(obj);
		if weaponMeleeComponent ~= nil then
			-- NOTE: If this is called right after AI instance is created, weapon instance might not yet exist
			local weaponInstanceUH = weaponMeleeComponent:getWeaponInstanceUH();
			if weaponInstanceUH ~= UH_NONE then
				local weaponInstance = sceneInstanceManager:getInstanceByUH(weaponInstanceUH);
				if weaponInstance ~= nil then
					local weaponInstanceModelComponent = getModelComponent(weaponInstance);
					if weaponInstanceModelComponent ~= nil then
						if weaponInstanceModelComponent:getVisibleInGame() ~= weaponModelEnabled then
							weaponInstanceModelComponent:setVisibleInGame(weaponModelEnabled);
						end						
						if weaponInstanceModelComponent:getVisibilityEnabled() ~= weaponModelEnabled then
							weaponInstanceModelComponent:setVisibilityEnabled(weaponModelEnabled);
						end
					else
						logAIError(obj, "AiUtils:setVisibilityEnabled - WeaponInstance ModelComponent missing.");
					end
				end
			end
		else
			-- NOTE: Not an error, not all AIs have WeaponMeleeComponent
			-- but for now this is only used for mummies, so spam the error
			logAIError(obj, "AiUtils:setVisibilityEnabled - WeaponMeleeComponent missing.");
		end
	end
end


function setPhysicsCollisionGroup(obj, onlyForSpawnedAIs, collisionGroup)
	if onlyForSpawnedAIs then
		local aiCC = getAICharacterComponent(obj);
		local aiSpawnerUH = aiCC:getAiSpawnerUH();
		if aiSpawnerUH == UH_NONE then
			-- If AI is placed into level directly from editor, don't do this visibility hack. Only for spawned AIs
			return;
		end
	end
	
	local physicsComponent = gameplay.ai.AiUtils.getPhysicsComponent(obj);
	if physicsComponent ~= nil then
		if physicsComponent:getCollisionGroup() ~= collisionGroup then
			physicsComponent:setCollisionGroup(collisionGroup);
		end
	else
		logAIError(obj, "AiUtils:setPhysicsCollisionGroup - PhysicsComponent missing.");
	end
end

-------------------------------------------------------------------------------------------------

function getBonePosition(obj, boneName)
	local modelComponent = getModelComponent(obj);
	if modelComponent == nil then
		logAIError(obj, "AiUtils:getBonePosition - ModelComponent missing.");
		return VC3(0,0,0);
	end

	return modelComponent:getBonePosition(boneName);
end

-------------------------------------------------------------------------------------------------

function disablePushEachOthers(obj)
	local component = obj:getFinalOwner():findComponent(gameplay.PushEachOthersAwayWhenOnTopComponent)
	if component then
		component:setTemporaryIgnorePushFromOthers(true)
	end
end

function enablePushEachOthers(obj)
	local component = obj:getFinalOwner():findComponent(gameplay.PushEachOthersAwayWhenOnTopComponent)
	if component then
		component:setTemporaryIgnorePushFromOthers(false)
	end
end

-------------------------------------------------------------------------------------------------

function setAnimationOverrideFactorToAllAnimateModelBoneComponents(obj, value)
	local iter = getAllAnimateModelBoneComponents(obj);
	if iter ~= nil then
		local comp = iter:next();
		while comp ~= nil do
			if comp:getAnimationOverrideFactor() ~= value then
				comp:setAnimationOverrideFactor(value);
			end
			
			comp = iter:next()
		end
	end
end

-------------------------------------------------------------------------------------------------
-- Pathfinding AI stuff

function getTrineAINavigationComponent(obj) -- NOTE: Badly named, should be getAINavigationComponent
	return findComponentFromObjectByClass(obj, gameplay.ai.AINavigationComponent.getStaticObjectClass());
end





-------------------------------------------------------------------------------------------------




