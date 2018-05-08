module(..., package.seeall)
debug.ReloadScripts.allowReload(...)

-- Change the animation context (of the animation component) in given instance 
function changeAnimationContext(instance, animationContextName, contextEnabled)
	local animComp = instance:findComponentByClassName("AnimationComponent")
	if (animComp) then
		animComp:setContext(animationContextName, contextEnabled)
	else
		logger:error("No AnimationComponent was found in the given instance.")
	end
end

-- Unfortunately current implementation screws up .fbt files if they contain quotes, thus, had to wrap this
function changeAnimationContextToGrow()
  changeAnimationContext(_G.ownerInstance, "small", false)
  changeAnimationContext(_G.ownerInstance, "grow", true)
end
