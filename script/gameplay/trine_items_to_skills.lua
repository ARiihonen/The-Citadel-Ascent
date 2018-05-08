
function trinebase.gameplay.item.TrineItemsToSkillsComponent:addSkillComponent(type, setProps)
	if(not self:getFinalOwner():findComponentByExactType(type))
	then
		function initComponent(comp, params)
		  if params.setProperties then
			params.setProperties(comp)
		  end
		end
		sceneInstanceManager:createNewComponentInstantly(type, self:getFinalOwner(), initComponent, { setProperties = setProps } )
	end
end

function trinebase.gameplay.item.TrineItemsToSkillsComponent:removeSkillComponent(type)
	local comp = self:getFinalOwner():findComponent(type)
	if comp then
		sceneInstanceManager:deleteInstanceInstantly(comp:getUnifiedHandle())
	end
end

function trinebase.gameplay.item.TrineItemsToSkillsComponent:initConjuring(comp, ic)
	comp:setCanConjureBox(not ic:hasItem("item_ball"))
	comp:setCanConjureBall(ic:hasItem("item_ball"))
	comp:setCanConjurePlank(ic:hasItem("Plank"))
--	comp:setCanConjureGlass(ic:hasItem("GlassObjects"))
	comp:setCanConjureSpikes(ic:hasItem("item_spiked_object"))
	
	local trapAISkillAllowed = true;
	
	if trapAISkillAllowed then
		comp:setCanTrapAI(ic:hasItem("TrapAI"));
	end
	
	local skillLevel = ic:getItemAmount("ConjuredObjectsAmount")
	if skillLevel > 0 then
		if skillLevel == 1 then
			comp:setMaxSimultaneousObjects(2)
		elseif skillLevel == 2 then
			comp:setMaxSimultaneousObjects(3)
		elseif skillLevel >= 3 then
			comp:setMaxSimultaneousObjects(4)
		end
	else
		comp:setMaxSimultaneousObjects(1)
	end
	--TODO: Should update ConjuredObjectUHArray, if max simultaneus objects amount get lower and then need to delete some old conjured objects
end

function trinebase.gameplay.item.TrineItemsToSkillsComponent:initFloating(comp, ic)
	comp:setCanLevitateObjects(true)
	comp:setObjectKeepKinetic(ic:hasItem("KeepKinetic"))
	comp:setCanLevitateActors(ic:hasItem("MonsterLevitation"))
	comp:setCanMagnetize(ic:hasItem("Magnetization"))
end

function trinebase.gameplay.item.TrineItemsToSkillsComponent:initVanish(comp, ic)
	comp:setSpawnScarecrow(ic:hasItem("StealthDisguise"))
end


function trinebase.gameplay.item.TrineItemsToSkillsComponent:addSkills()
	-- nop
end

function trinebase.gameplay.item.TrineItemsToSkillsComponent:removeSkills()
	-- Remove skill tooltips
	local skillTooltipComp = self:getFinalOwner():findComponent(trinebase.gameplay.skills.CharacterSkillTooltipComponent)
	if skillTooltipComp then
		skillTooltipComp:clearAllSkillTooltip()
	end	
end

function trinebase.gameplay.item.TrineItemsToSkillsComponent:updateSkills()
	self:removeSkills()
	self:addSkills()
end

--function trinebase.gameplay.item.TrineItemsToSkillsComponent:addItemModifiers()
	
--end

function trinebase.gameplay.item.TrineItemsToSkillsComponent:itemsUpdatedOnInventoryChange()
	-- For items that must come in effect even if character is not selected.
	-- Eg. Inactive characters can be healed by checkpoints and potions. Therefore it's important to 
	-- increase the maximum health as soon as the character gets the item (not when the character is
	-- switched to for the first time after receiving it)
end
