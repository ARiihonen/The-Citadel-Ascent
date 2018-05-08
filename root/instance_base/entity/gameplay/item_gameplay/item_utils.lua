local moduleName = "gameplay.item.ItemUtils"
module(moduleName, package.seeall)
debug.ReloadScripts.allowReload(moduleName)

function getPickerInstance(self)
	if(not self)
	then
		logger:error("ItemUtils:getPickerInstance - self is null");
		return nil;
	end

	if(not self:getFinalOwner())
	then
		logger:error("ItemUtils:getPickerInstance - bad self parameter, expecting component");
		return nil;
	end
	
	local iPC = self:getFinalOwner():findComponent(gameplay.item.ItemPickableComponent);
	if iPC then
		local lastTriggeredByUH = iPC:getLastTriggeredByUH();
		if not(lastTriggeredByUH == UH_NONE) then
			local triggeredByInst = sceneInstanceManager:getInstanceByUH(lastTriggeredByUH);
			if triggeredByInst then
				return triggeredByInst
			else
				logger:error("ItemUtils:getPickerInstance - Invalid lastTriggeredBy instance.");
			end
		else
			return nil 
			--logger:error("ItemUtils:getPickerInstance - Invalid lastTriggeredByUH.");
		end
	else
		logger:error("ItemUtils:getPickerInstance - ItemPickableComponent is missing.");
	end
	return nil
end
