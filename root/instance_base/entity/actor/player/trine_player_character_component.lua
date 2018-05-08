
trinebase.gameplay.character.TrinePlayerCharacterComponent.addProperty(engine.base.TypeFloat, "GroundWalkVelocity", 5.8, "", "");
trinebase.gameplay.character.TrinePlayerCharacterComponent.addProperty(engine.base.TypeFloat, "GroundWalkAcceleration", 37.0, "", "");
trinebase.gameplay.character.TrinePlayerCharacterComponent.addProperty(engine.base.TypeFloat, "BackwardMovementFactor", 0.6, "", "");
trinebase.gameplay.character.TrinePlayerCharacterComponent.addProperty(engine.base.TypeFloat, "CarryingMovementFactor", 0.6, "", "");
trinebase.gameplay.character.TrinePlayerCharacterComponent.addProperty(engine.base.TypeFloat, "ShieldGrabMovementSpeed", 1.8, "", "");

-- Touchscreen and state machine communication variables.
trinebase.gameplay.character.TrinePlayerCharacterComponent.addProperty(engine.base.TypeBool, "TouchscreenUse", false, "", "This is true, if use button was pushed down via the touchscreen.");

trinebase.gameplay.character.TrinePlayerCharacterComponent.addProperty(engine.base.TypeBool, "ABTestHack", false, "", "");

function trinebase.gameplay.character.TrinePlayerCharacterComponent:started()
end

function trinebase.gameplay.character.TrinePlayerCharacterComponent:stopped()
end
