-- Area group and mask bit naming
--
-- AreaGroup names must start with "AreaGroup". That is used to detect default values used by type 
-- manager.

area.AreaGroup.rename(
	{
		AreaGroupNotSpecified = 0,
		AreaGroupLights = 1,
		AreaGroupGameplay = 2,
		AreaGroupActivation = 3,
		AreaGroupLocalCamera = 4
	}
)

-- Add some default masks
--
-- Note: Bits are generally speaking handled by name, not by mask position. Changing the names of 
-- bits or groups (since in types, bits are named "group name: bit name") means the values of 
-- renamed bits are set to 0.
--
-- I'm not actually totally sure how this works with instances that have modified masks, but it 
-- probably asserts when setting renamed values for the first time, loses renamed bit values but 
-- works ok from there on.
-- 
-- Changing the masks causes all component types inherit from and including AbstractAreaComponent 
-- to be saved again. Hopefully it also forces resave of instances with modified masks.
--
-- Also note: If area mask bits broke, try deleting types.bin and restarting twice.

area.AreaModule.beginSetGlobalMaskBits()

	area.AreaModule.addGlobalMaskBit(area.AreaGroupNotSpecified, "default")

	area.AreaModule.addGlobalMaskBit(area.AreaGroupLights, "default")

	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "default")
	
	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "usableItem")
	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "pressurePlate")
	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "distractionObject")
	
	-- These should be enough for most of the cases (own bit for PointAreaComponent and for BoxAreaComponent, actors have both of them, this prevents multiple area enter/exit signals)
	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "ActorPlayerPoint")
	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "ActorPlayerBox")
	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "ActorAiPoint")
	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "ActorAiBox")
	
	-- Intended for gameplay area elements that are "quite rare" (a few of these here and there in the map, and usually do not overlap)
	-- To be used by, for example, pipe flow areas, unique gameplay scripting area stuff, etc. 
	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "RareGameplayElement")	
	
	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "DynamicObject")	

	area.AreaModule.addGlobalMaskBit(area.AreaGroupActivation, "ParticlesActivation")
	area.AreaModule.addGlobalMaskBit(area.AreaGroupActivation, "PhysicsActivation")
	area.AreaModule.addGlobalMaskBit(area.AreaGroupActivation, "GameplayActivation")
	area.AreaModule.addGlobalMaskBit(area.AreaGroupActivation, "CameraPositionActivation")

	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "SwimPoint")
	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "OxygenPoint")
	
	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "ActorPlayerShadwen")
	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "AreaFlow")

	area.AreaModule.addGlobalMaskBit(area.AreaGroupLocalCamera, "LocalCameraPoint")
	
	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "RagdollObject")
	
	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "Lantern")

	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "Magnetism")

	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "Sunray")

	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "Projectile")
	
	-- area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "Electricity")
	
	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "Wind")
	
	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "WindReceiver")

	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "Rope")
	
	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "ExperienceTracker")

	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "GameplaySound")
	
	area.AreaModule.addGlobalMaskBit(area.AreaGroupGameplay, "InventoryArea")
	
area.AreaModule.endSetGlobalMaskBits()
