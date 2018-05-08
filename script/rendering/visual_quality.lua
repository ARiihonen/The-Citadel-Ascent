module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

function setDefaultVisualQuality()
	-- TODO: Better heuristics for determining optimal visual quality. LOL!
	
	if platformModule:isPlatformWindows() then
		renderingModule:setVisualQualityPreset(rendering.RenderingModule.VisualQualityPresetHigh)
	else
		renderingModule:setVisualQualityPreset(rendering.RenderingModule.VisualQualityPresetMedium)
	end
end

function setVisualQuality(quality)

	if quality == rendering.RenderingModule.VisualQualityPresetCustom then
		-- nop
	elseif quality == rendering.RenderingModule.VisualQualityPresetVeryLow then
	
		particleModule:setMinParticleEffectQuality(0)
		particleModule:setMaxParticleEffectQuality(0)
		renderingModule:setAnisotropy(1)
		renderingModule:setDistortionEnabled(false)
		renderingModule:setShowGlow(false)
		renderingModule:setEnableSway(false)
		renderingModule:setUseHalfResolutionTextures(true)
		renderingModule:setColorTextureMipLevelDrop(3)
		renderingModule:setNormalTextureMipLevelDrop(3)
		renderingModule:setSpecularTextureMipLevelDrop(3)
		renderingModule:setShaderQuality(0)
		renderingModule:setResolutionReduction(2)
		renderingModule:setAmbientOcclusionEnabled(false)
		renderingModule:setSpriteQuality(0)
		
	elseif quality == rendering.RenderingModule.VisualQualityPresetLow then
	
		particleModule:setMinParticleEffectQuality(25)
		particleModule:setMaxParticleEffectQuality(25)
		renderingModule:setAnisotropy(2)
		renderingModule:setDistortionEnabled(false)
		renderingModule:setShowGlow(true)
		renderingModule:setEnableSway(true)
		renderingModule:setUseHalfResolutionTextures(true)
		renderingModule:setColorTextureMipLevelDrop(1)
		renderingModule:setNormalTextureMipLevelDrop(2)
		renderingModule:setSpecularTextureMipLevelDrop(2)
		renderingModule:setShaderQuality(1)
		renderingModule:setResolutionReduction(1)
		renderingModule:setAmbientOcclusionEnabled(false)
		renderingModule:setSpriteQuality(1)
		
	elseif quality == rendering.RenderingModule.VisualQualityPresetMedium then
	
		particleModule:setMinParticleEffectQuality(50)
		particleModule:setMaxParticleEffectQuality(50)
		renderingModule:setAnisotropy(4)
		renderingModule:setDistortionEnabled(true)
		renderingModule:setShowGlow(true)
		renderingModule:setEnableSway(true)
		renderingModule:setUseHalfResolutionTextures(true)
		renderingModule:setColorTextureMipLevelDrop(1)
		renderingModule:setNormalTextureMipLevelDrop(1)
		renderingModule:setSpecularTextureMipLevelDrop(1)
		renderingModule:setShaderQuality(2)
		renderingModule:setResolutionReduction(0)
		renderingModule:setAmbientOcclusionEnabled(false)
		renderingModule:setSpriteQuality(2)
		
	elseif quality == rendering.RenderingModule.VisualQualityPresetHigh then
	
		particleModule:setMinParticleEffectQuality(75)
		particleModule:setMaxParticleEffectQuality(75)
		renderingModule:setAnisotropy(8)
		renderingModule:setDistortionEnabled(true)
		renderingModule:setShowGlow(true)
		renderingModule:setEnableSway(true)
		renderingModule:setUseHalfResolutionTextures(false)
		renderingModule:setColorTextureMipLevelDrop(0)
		renderingModule:setNormalTextureMipLevelDrop(0)
		renderingModule:setSpecularTextureMipLevelDrop(0)
		renderingModule:setShaderQuality(3)
		renderingModule:setResolutionReduction(0)
		renderingModule:setAmbientOcclusionEnabled(true)
		renderingModule:setSpriteQuality(3)
		
	elseif quality == rendering.RenderingModule.VisualQualityPresetVeryHigh then
	
		particleModule:setMinParticleEffectQuality(100)
		particleModule:setMaxParticleEffectQuality(100)
		renderingModule:setAnisotropy(16)
		renderingModule:setDistortionEnabled(true)
		renderingModule:setShowGlow(true)
		renderingModule:setEnableSway(true)
		renderingModule:setUseHalfResolutionTextures(false)
		renderingModule:setColorTextureMipLevelDrop(0)
		renderingModule:setNormalTextureMipLevelDrop(0)
		renderingModule:setSpecularTextureMipLevelDrop(0)
		renderingModule:setShaderQuality(4)
		renderingModule:setResolutionReduction(0)
		renderingModule:setAmbientOcclusionEnabled(true)
		renderingModule:setSpriteQuality(4)
		
	else
		logger:error("Unhandled quality option: ".. tostring(quality))
	end
end