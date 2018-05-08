require "rendering.VisualQuality"

rendering.ColorEffectGroup.rename(
{
	ColorEffectGroupSceneLights = 0,
	ColorEffectGroupHitEffect = 1
});

local r = renderingModule
local setParams = r.setColorEffectGroupParams

setParams(r, rendering.ColorEffectGroupSceneLights, { priority = 0, isAdjustExposure = 1 })
setParams(r, rendering.ColorEffectGroupHitEffect, { priority = 1, isAdjustExposure = 0 })