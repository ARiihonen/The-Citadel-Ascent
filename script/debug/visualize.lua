local moduleName = "debug.Visualize"
module(moduleName, package.seeall)
debug.ReloadScripts.allowReload(moduleName)

------------------------------------------------------------------------------------------------------------------------------------------------
-- Property visualization helper functions

function addDebugComponentByComponent(component, propertiesToBeVisualized, existingPropertyComp)
	local inst = common.CommonUtils.getFinalOwnerInstance(component);
	
	local propertyComp = nil;	
	if existingPropertyComp == nil then
		propertyComp = inst:findComponent(rendering.PropertyVisualizerComponent);
	else
		propertyComp = existingPropertyComp;	
	end
	
	if propertyComp ~= nil then
		-- If not visible, force it
		if not propertyComp:getVisible() then
			propertyComp:setVisible(true)
		end
		propertyComp:addVisualizedComponent(component);
		
		-- Visualize only selected properties
		if propertiesToBeVisualized ~= nil then
			for key, propertyName in pairs(propertiesToBeVisualized) do
				propertyComp:addVisualizedComponentProperty(component, propertyName);
			end
		end		
	else
		--[[
		local function addPropertyVisualizerComponent(obj, params)
			-- HACK: Call itself because component creation is delayed
			-- NOTE: This may result Instance having multiple PropertyVisualizerComponents
			addDebugComponentByComponent(params.pComponent, params.pPropertiesToBeVisualized, nil);
		end
		local params = { pComponent = component, pPropertiesToBeVisualized = propertiesToBeVisualized };
		common.CommonUtils.getSceneInstanceManager():createNewComponent(rendering.PropertyVisualizerComponent.getTypeUH(), inst, addPropertyVisualizerComponent, params)
		]]--
		logger:error("visualize:addDebugComponentByComponent - No PropertyVisualizerComponent found.");
	end
end

function addDebugComponentByComponentType(obj, componentType, propertiesToBeVisualized)
	local inst = common.CommonUtils.getFinalOwnerInstance(obj);
	local component = inst:findComponent(componentType);
	if component ~= nil then
		addDebugComponentByComponent(component, propertiesToBeVisualized, nil);
	end	
end

function removeDebugComponentByComponent(component)
	local inst = common.CommonUtils.getFinalOwnerInstance(component);
	local propertyComp = inst:findComponent(rendering.PropertyVisualizerComponent);
	if propertyComp ~= nil then
		propertyComp:removeVisualizedComponent(component);
	end
end

function removeDebugComponentByComponentType(obj, componentType)
	local inst = common.CommonUtils.getFinalOwnerInstance(obj);
	local component = inst:findComponent(componentType);
	if component ~= nil then
		removeDebugComponentByComponent(component);
	end
end

function addDebugStateComponentByName(obj, stateName, propertiesToBeVisualized)
	local inst = common.CommonUtils.getFinalOwnerInstance(obj);
	local characterComponent = inst:findComponent(gameplay.CharacterComponent);
	if characterComponent then
		if stateName ~= nil then
			-- Can be nil, just ignore
			local stateComponent = characterComponent:findStateComponentByCollection(stateName);
			if stateComponent then
				addDebugComponentByComponent(stateComponent, propertiesToBeVisualized, nil);
			end
		end
	else
		-- HACK: Just get the first state component (TODO: Should support them all...)
		local stateComponent = inst:findComponent(gameplay.ScriptedStateComponent);
		if stateComponent then
			addDebugComponentByComponent(stateComponent, propertiesToBeVisualized, nil);
		end
	end
end

function removeDebugStateComponentByName(obj, stateName)
	local inst = common.CommonUtils.getFinalOwnerInstance(obj);
	local characterComponent = inst:findComponent(gameplay.CharacterComponent);
	if characterComponent ~= nil then
		if stateName ~= nil then
			-- Can be nil, just ignore
			local stateComponent = characterComponent:findStateComponentByCollection(stateName);
			if stateComponent then
				removeDebugComponentByComponent(stateComponent);
			end
		end
	else
		-- HACK: Just get the first state component (TODO: Should support them all...)
		local stateComponent = inst:findComponent(gameplay.ScriptedStateComponent);
		if stateComponent then
			removeDebugComponentByComponent(stateComponent);
		end
	end
end

function addDebugComponent(obj, componentType, enabled, propertiesToBeVisualized)	
	if enabled then
		addDebugComponentByComponentType(obj, componentType, propertiesToBeVisualized);
	else
		removeDebugComponentByComponentType(obj, componentType);
	end
end

function addDebugStateComponent(obj, stateName, enabled, propertiesToBeVisualized)	
	if enabled then
		addDebugStateComponentByName(obj, stateName, propertiesToBeVisualized);
	else
		removeDebugStateComponentByName(obj, stateName);
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------
-- Visualization helper functions, vol 1.

function visitAllTreeNodes(treeNode, visitor)
	visitChildInstances(treeNode, visitor)
	visitChildComponents(treeNode, visitor)
	visitor(treeNode)
end

function visitChildComponents(treeNode, visitor)
	for i = 0, treeNode:getNumComponents() - 1 do
		visitAllTreeNodes(treeNode:getComponent(i), visitor)
	end
end

function visitChildInstances(treeNode, visitor)
	for i = 0, treeNode:getNumChildren() - 1 do
		visitAllTreeNodes(treeNode:getChild(i), visitor)
	end
end

function visitAllInstancesUnderInstanceRoot(visitor)
	visitAllTreeNodes(instanceManager:getTopmostInstanceRoot(), visitor)
end

function addVisualizerIfComponentFound(visualizerTypeUH, componentType)
	local instanceManager = gameScene:getSceneInstanceManager();
	visitAllInstancesUnderInstanceRoot(
		function(instance)		
		  -- Note, this checks for implementing _class_, not the dynamically inherited _type_.
		  -- As such, you may get results that do not really exactly match the give type (but they happen to use the same implementing class).
			-- (This is probably close enough for dev purposes though.)
			if instance:countComponentsOfClass(componentType.getStaticObjectClass()) == 1 then		
				local visualizerType = typeManager:getTypeByUH(visualizerTypeUH)
				if instance:findComponent(rendering.DebugVisualizerComponent) == nil then
					instanceManager:createNewComponent(visualizerTypeUH, instance, function() end, nil)
				end
			end
		end
	)
end

function visualizeAll(componentType)
	local visualizerTypeUH = typeManager:findDebugVisualizerType(componentType.getStaticClassId())
	if visualizerTypeUH == UH_NONE then
		logger:error("No visualizer found for given type")
		return
	end	
	addVisualizerIfComponentFound(visualizerTypeUH, componentType)
end

------------------------------------------------------------------------------------------------------------------------------------------------
-- Visualization helper functions, vol 2.

function enableVisualizerForAllComponentsByClassIdRecursively(owner, comp, componentTypeClassId, visualizerTypeUH, enabled)
	
	local instanceManager = gameScene:getSceneInstanceManager();
	
	if instanceManager == nil then
		logger:error("visualize:enableVisualizerForAllComponentsByClassIdRecursively - InstanceManager param is nil.");
		return;
	end
	
	if owner == nil then
		logger:error("visualize:enableVisualizerForAllComponentsByClassIdRecursively - Owner param is nil.");
		return;
	end
	
	if comp == nil then
		logger:error("visualize:enableVisualizerForAllComponentsByClassIdRecursively - Component param is nil.");
		return;
	end
	
	local visualizerType = typeManager:getTypeByUH(visualizerTypeUH);
	if visualizerType == nil then
		logger:error("visualize:enableVisualizerForAllComponentsByClassIdRecursively - No such visualizer type found with given UH.");
		return;
	end
	
	if comp:isInheritedByClassId(componentTypeClassId) then
		local existingComponent = nil;
		
		-- Check existing status by looping owners components
		local iter = ComponentVectorIterator(owner:getComponents());
		if not iter:hasInitFailed() then
			local childComp = iter:next()
			while not (childComp == nil) do
				local childCompType = typeManager:getTypeByUH(childComp:getType());
				if childCompType ~= nil then
					if childCompType:doesInheritType(visualizerType) then
					
						-- NOTE: New design, don't delete, just show or hide
						childComp:setVisible(enabled);
						existingComponent = childComp;
						break;
						--[[
						if enabled then					
							existingComponent = childComp;
							break;
						else
							-- Exist and should be deleted
							instanceManager:deleteInstance(childComp:getUnifiedHandle());
						end
						]]--
					end
				end				
				childComp = iter:next();
			end
		else
			logger:error("visualize:enableVisualizerForAllComponentsByClassIdRecursively - Component iterator init failed, cannot loop trough child components.");
		end
		
		if existingComponent == nil then
			if enabled then
				-- Doesn't exist and should be added
				function componentCreate(obj, params)
					-- nop
				end	
				instanceManager:createNewComponent(visualizerTypeUH, owner, componentCreate, nil);
			end
		end
	end
	
	-- Also for child components
	local iter = ComponentVectorIterator(comp:getComponents());
	if not iter:hasInitFailed() then
		local childComp = iter:next()
		while not (childComp == nil) do
			enableVisualizerForAllComponentsByClassIdRecursively(comp, childComp, componentTypeClassId, visualizerTypeUH, enabled)
			childComp = iter:next();
		end
	else
		logger:error("visualize:enableVisualizerForAllComponentsByClassIdRecursively - Component iterator init failed, cannot loop trough child components.");
	end
end


function enableVisualizerForAllInstancesByClassIdAndVisualizerTypeUH(componentTypeClassId, visualizerTypeUH, enabled, instanceTypeNameFilterString)

	if(enabled == nil) then
		logger:error("visualize:enableVisualizerForAllInstancesByClassIdAndVisualizerTypeUH - You are supposed to give the enabled parameter as boolean (true or false).");
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
	
		if allow and obj.getComponents then			
			local iter = ComponentVectorIterator(obj:getComponents());
			if not iter:hasInitFailed() then
				local childComp = iter:next()
				while not (childComp == nil) do
					enableVisualizerForAllComponentsByClassIdRecursively(obj, childComp, componentTypeClassId, visualizerTypeUH, enabled);
					childComp = iter:next();
				end
			else
				logger:error("visualize:enableVisualizerForAllInstancesByClassId - Component iterator init failed, cannot loop trough child components.");
			end
		end		
		obj = resultIterator:next();		
	end
end

function enableVisualizerForAllInstancesByClassId(componentTypeClassId, enabled, instanceTypeNameFilterString)
	local visualizerTypeUH = typeManager:findDebugVisualizerType(componentTypeClassId);
	if visualizerTypeUH == UH_NONE then
		logger:error("visualize:enableVisualizerForAllInstancesByClassId - No visualizer found for given type");
		return;
	end
	enableVisualizerForAllInstancesByClassIdAndVisualizerTypeUH(componentTypeClassId, visualizerTypeUH, enabled, instanceTypeNameFilterString);
end

------------------------------------------------------------------------------------------------------------------------------------------------
-- NetSync visualizations

function visualizeNetSyncs()
	local visualizerTypeUH = sync.NetSyncVisualizerComponent.getTypeUH()
	local componentType = engine.component.AbstractNetSyncComponent
	local instanceManager = gameScene:getSceneInstanceManager();
	visitAllInstancesUnderInstanceRoot(
		function(instance)		
		  -- Note, this checks for implementing _class_, not the dynamically inherited _type_.
		  -- As such, you may get results that do not really exactly match the give type (but they happen to use the same implementing class).
			-- (This is probably close enough for dev purposes though.)
			if instance:countComponentsOfClass(componentType.getStaticObjectClass()) == 1 then		
				local visualizerType = typeManager:getTypeByUH(visualizerTypeUH)
				if instance:findComponent(sync.NetSyncVisualizerComponent) == nil then
					instanceManager:createNewComponent(visualizerTypeUH, instance, function() end, nil)
				end
			end
		end
	)
end

------------------------------------------------------------------------------------------------------------------------------------------------
-- Area visualizations

function visualizeAreas(enabled)
	--visualizeAll(engine.component.AbstractAreaComponent);
	enableVisualizerForAllInstancesByClassId(engine.component.AbstractAreaComponent.getStaticClassId(), enabled, nil);
end

------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper visualizations

function visualizeHelpers(enabled)
	editor.Util.setAbstractModelComponentBoolPropertyForHelperEntityInstances("VisibleInGame", enabled);
end

------------------------------------------------------------------------------------------------------------------------------------------------
-- Poperty animation system visualizations

function visualizePropertyConnections(enabled)
	enableVisualizerForAllInstancesByClassId(propertyanimation.PropertyConnectionComponent.getStaticClassId(), enabled, nil);
end

------------------------------------------------------------------------------------------------------------------------------------------------
-- Generic visualizations

function visualizeTargetComponents(enabled)
	enableVisualizerForAllInstancesByClassId(gameplay.TargetComponent.getStaticClassId(), enabled, nil);
end

function visualizeNavigationComponents(enabled)
	enableVisualizerForAllInstancesByClassId(gameplay.ai.AINavigationComponent.getStaticClassId(), enabled, nil);
end

------------------------------------------------------------------------------------------------------------------------------------------------
-- AI visualizations

function visualizeAIPathHelpers(enabled)
	enableVisualizerForAllInstancesByClassId(platformer.ai.PlatformerAIPathHelperComponent.getStaticClassId(), enabled, nil);
	enableVisualizerForAllInstancesByClassId(platformer.ai.PlatformerAIPathHelperForceDirComponent.getStaticClassId(), enabled, nil);
	enableVisualizerForAllInstancesByClassId(platformer.ai.PlatformerAIPathHelperShooterHelperComponent.getStaticClassId(), enabled, nil);
	enableVisualizerForAllInstancesByClassId(pathfind.NavigationOfflinkComponent.getStaticClassId(), enabled, nil);
	visualizeHelpers(enabled)
end

function visualizeAIPathHelperAreas(enabled)
	enableVisualizerForAllInstancesByClassId(engine.component.AbstractAreaComponent.getStaticClassId(), enabled, "AIPathHelperEntity");
	enableVisualizerForAllInstancesByClassId(engine.component.AbstractAreaComponent.getStaticClassId(), enabled, "NavigationOfflinkHelperEntity");
end

function visualizeAIAreas(enabled)
	-- NOTE: This enables visualization for players etc. as well
	local rootTypeName = "ActorEntity";
	enableVisualizerForAllInstancesByClassId(engine.component.AbstractAreaComponent.getStaticClassId(), enabled, rootTypeName);
end

function visualizeAINetSyncs(enabled)
	-- NOTE: This enables visualization for players etc. as well
	local rootTypeName = "ActorEntity";
	enableVisualizerForAllInstancesByClassIdAndVisualizerTypeUH(sync.SceneNetSyncComponent.getStaticClassId(), sync.NetSyncVisualizerComponent.getTypeUH(), enabled, rootTypeName);
end

function visualizeAllNetSyncs(enabled)
	enableVisualizerForAllInstancesByClassIdAndVisualizerTypeUH(sync.SceneNetSyncComponent.getStaticClassId(), sync.NetSyncVisualizerComponent.getTypeUH(), enabled);
end

function visualizeAIProperties(enabled)
	-- NOTE: This enables visualization for players etc. as well
	local rootTypeName = "ActorEntity";
	gameplay.ai.AiUtilsDebug.enablePropertyVisualizerForAllInstances(enabled, rootTypeName);
	
	-- Spawner objects
	--gameplay.ai.AiUtilsDebug.enablePropertyVisualizerForAllInstances(enabled, "SpawnerHelperEntity");
end
