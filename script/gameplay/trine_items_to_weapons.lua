
function trinebase.gameplay.weapon.TrineItemsToWeaponsComponent:addWeaponComponent(type, setProps)
	--[[local c = self:getFinalOwner():findComponentByExactType(type)
	if(c) then
		if(setProps) then
			setProps(self, c)
		end
		return
	end
	--]]
	function initWeapon(comp, params)
		if params.setProperties then
			params.setProperties(self, comp)
		end
	end
	sceneInstanceManager:createNewComponentInstantly(type, self:getFinalOwner(), initWeapon, { setProperties = setProps } )
end

function trinebase.gameplay.weapon.TrineItemsToWeaponsComponent:removeWeaponComponent(type)
	-- HACK: Somewhat solves fast weapon change => multiple weapons bug
	local iter = self:getFinalOwner():findAllComponents(type)
	local comp = iter:next()
	while comp do
		if comp:getClassId() == type.getStaticClassId() then
			sceneInstanceManager:deleteInstanceInstantly(comp:getUnifiedHandle())
			-- Must re-initialize iterator (or crash)
			iter = self:getFinalOwner():findAllComponents(type)
		end
		comp = iter:next()
	end
end

function trinebase.gameplay.weapon.TrineItemsToWeaponsComponent:removeWeaponComponentDelayed(type)
	local iter = self:getFinalOwner():findAllComponents(type)
	local comp = iter:next()
	while comp do
		if comp:getClassId() == type.getStaticClassId() then
			sceneInstanceManager:deleteInstanceWithoutSync(comp:getUnifiedHandle())
		end
		comp = iter:next()
	end
end

function initNormalBow(self, comp)
	local ic = self:getFinalOwner():findComponent(gameplay.item.InventoryComponent)
	if ic:hasItem("item_multiple_arrows") then
		comp:setRepeatAmount(3)
		comp:setRepeatDelay(15)
		comp:setRepeatDamageMultiplier(0.33)
		comp:setSymmetricSpreadAngle(0.6)
	else
		comp:setRepeatAmount(1)
		comp:setRepeatDelay(15)
		comp:setRepeatDamageMultiplier(1)
		comp:setSymmetricSpreadAngle(0.3)
	end
end

function initNormalSword(self, comp)
	local owner = self:getFinalOwner()
	
	if owner == nil then
		logger:error("getFinalOwner failed")
		return
	end
end

function initIceBow(self, comp, typeUHs)
	local ic = self:getFinalOwner():findComponent(gameplay.item.InventoryComponent)
	if ic and ic:getItemAmount("IceBow") >= 2 then
		comp:setRepeatAmount(2)
		comp:setRepeatDelay(15)
		comp:setSymmetricSpreadAngle(0.4)
	else
		comp:setRepeatAmount(1)
		comp:setRepeatDelay(15)
		comp:setSymmetricSpreadAngle(0.01)
	end
end

function initFireBow(self, comp, typeUHs)
	comp:setRepeatAmount(1)
	comp:setRepeatDelay(15)
	comp:setSymmetricSpreadAngle(0.01)
end

function initShield(self, comp)
	-- nop
end

function giveShield(self, typeUHs)
	local ic = self:getFinalOwner():findComponent(gameplay.item.InventoryComponent)
	if ic then
		if ic:hasItem("FrostShield") then
			self:addWeaponComponent(typeUHs["Trine3DWarriorWearFrostShieldComponent"], initShield)
			return
		end
	end
	self:addWeaponComponent(typeUHs["Trine3DWarriorWearShieldComponent"], initShield)
end

function trinebase.gameplay.weapon.TrineItemsToWeaponsComponent:addWeapon(weaponName)
	-- nop
end

function trinebase.gameplay.weapon.TrineItemsToWeaponsComponent:removeWeapon(weaponName)
--[[
	if weaponName == "NormalBow" or weaponName == "FireBow" then
		self:removeWeaponComponent(trinebase.gameplay.skills.ThiefLowGravityArrowComponent)
		self:removeWeaponComponent(trinebase.gameplay.Trine3DBowComponent)
	elseif weaponName == "Sword" then
		self:removeWeaponComponent(trinebase.gameplay.Trine3DWearShieldComponent)
		self:removeWeaponComponent(trinebase.gameplay.weapon.TrineSwingMeleeWeaponComponent)
	elseif weaponName == "Hammer" then
		self:removeWeaponComponent(trinebase.gameplay.weapon.TrineRechargeableMeleeWeaponComponent)
	end
--]]
end

function trinebase.gameplay.weapon.TrineItemsToWeaponsComponent:removeWeaponDelayed(weaponName)
--[[
	if weaponName == "NormalBow" or weaponName == "FireBow" then
		self:removeWeaponComponentDelayed(trinebase.gameplay.skills.ThiefLowGravityArrowComponent)
		self:removeWeaponComponentDelayed(game.gameplay.GameTrine3DBowComponent)
	elseif weaponName == "Sword" then
		self:removeWeaponComponentDelayed(trinebase.gameplay.Trine3DWearShieldComponent)
		self:removeWeaponComponentDelayed(trinebase.gameplay.weapon.TrineSwingMeleeWeaponComponent)
	elseif weaponName == "Hammer" then
		self:removeWeaponComponentDelayed(trinebase.gameplay.weapon.TrineRechargeableMeleeWeaponComponent)
	end
--]]
end

function trinebase.gameplay.weapon.TrineItemsToWeaponsComponent:updateWeapon(weaponName)
	self:removeWeapon(weaponName)
	local ic = self:getFinalOwner():findComponent(gameplay.item.InventoryComponent)
	if ic and ic:hasItem(weaponName) then
		self:addWeapon(weaponName)
	else
		local wsc = self:getFinalOwner():findComponent(trinebase.gameplay.weapon.TrineWeaponSelectionComponent)
		if wsc then
			wsc:requestNextWeapon()
		end
	end
end
