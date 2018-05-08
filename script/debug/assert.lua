module(..., package.seeall)

-- better not allow reload, cos the whole ReloadScripts thing might actually require this.
-- (well it does not, but AutoReloadable does)
-- debug.ReloadScripts.allowReload(...)


-- NOTE: always use the global aliases at the end of this file instead of using these with the module name!

lua_assert_breaks = true

function nop() end

function dump_assert_call_frame()
	local level = 0
	if _G.debug and _G.debug.getinfo then
		local ret = "Lua stack at assert: "
		local lv = 1
		while true do
			local oneMore = false
			local info = _G.debug.getinfo(lv)
			if info then 
				if info.what == "C" then
					if (info.name ~= nil) then
						ret = ret .. "[C] in function "..string.format("'%s'",info.name) .. " --- "
					else
						ret = ret .. "[C] in function (unknown)".. "\r\n"
					end
				else
					local line = ""
					if (info.name ~= nil) then
						line = string.format("%s:%d - in function '%s'", info.short_src, info.currentline, info.name) .. " --- "
						oneMore = true
					else
						line = string.format("%s:%d in function (anonymous)", info.short_src, info.currentline) .. " --- "
						oneMore = true
					end
					if not(string.find(line, "debug/assert.lua")) then
						ret = ret .. line
					else
						-- skip the assert itself, go up by one frame
						oneMore = true
					end
				end
			end
			if (not(oneMore)) then
				break
			else
				oneMore = false
				lv = lv + 1
			end
		end
		logger:info(ret)
	else
		logger:info("No lua debug available, thus cannot dump assert stack.")
	end
	
	if (lua_assert_breaks) then
		assert(false)
	end	
end

function assert_nil(obj)
	if (obj ~= nil) then
		logger:error("Nil object expected.")
		dump_assert_call_frame()
	end
end

function assert_string(obj)
	if (type(obj) ~= "string") then
		logger:error("String type expected.")
		dump_assert_call_frame()
	end
end

function assert_string_or_nil(obj)
	if (obj == nil) then
		return
	end
	assert_string(obj)
end

function assert_number(obj)
	if (type(obj) ~= "number") then
		logger:error("Number type expected.")
		dump_assert_call_frame()
	end
end

function assert_number_or_nil(obj)
	if (obj == nil) then
		return
	end
	assert_number(obj)
end

function assert_integer(obj)
	if (type(obj) ~= "number") then
		logger:error("Integer type expected.")
		dump_assert_call_frame()
		return
	end
	if (math.floor(obj) ~= obj) then
		logger:error("Integer type expected (but a floating point number was encountered).")
		dump_assert_call_frame()
		return
	end
end

function assert_integer_or_nil(obj)
	if (obj == nil) then
		return
	end
	assert_integer(obj)
end

function assert_boolean(obj)
	if (type(obj) ~= "boolean") then
		logger:error("Boolean type expected.")
		dump_assert_call_frame()
	end
end

function assert_boolean_or_nil(obj)
	if (obj == nil) then
		return
	end
	assert_boolean(obj)
end

function assert_table(obj)
	if (type(obj) ~= "table") then
		logger:error("Table type expected.")
		dump_assert_call_frame()
	end
end

function assert_table_or_nil(obj)
	if (obj == nil) then
		return
	end
	assert_table(obj)
end

function assert_function(obj)
	if (type(obj) ~= "function") then
		logger:error("Function type expected.")
		dump_assert_call_frame()
	end
end

function assert_function_or_nil(obj)
	if (obj == nil) then
		return
	end
	assert_function(obj)
end

function assert_luamodule(obj)
	if (type(obj) ~= "table") then
		logger:error("Module type expected.")
		dump_assert_call_frame()
		return
	end
	if (obj._M == nil or obj._NAME == nil or obj._PACKAGE == nil) then
		logger:error("Module type expected.")
		dump_assert_call_frame()
	end
end

function solveClassNameFor(classObj)
	local className = "(unknown_classname)" 

	if (classObj.getClassId == nil) then
		return className
	end
	if (classObj.getTypeUH == nil) then
		return className
	end
	
	local classId = nil
	if (classObj.getStaticClassId ~= nil) then
		classId = classObj.getStaticClassId()
	else
		classId = classObj:getClassId()
	end
	
	if (_G.typeManager) then
		if (_G.typeManager.getTypeByUH) then
			if (_G.typeManager:getStaticDefaultType(classId) == nil) then
				-- hack... handle this specifically
				if (classId == engine.base.treebase.AbstractEditableObjectTreeNode.getStaticClassId()) then
					className = "AbstractEditableObjectTreeNode" 
				else
					className = "(a_class_with_no_type)" 
				end
				return className
			end			
			local typeObj = _G.typeManager:getTypeByUH(classObj.getTypeUH())			
			if (typeObj) then			
				className = _G.typeManager:getTypeByUH(classObj.getTypeUH()):getName()
				
				--logger:error("debug spam: " .. tostring(_G.typeManager:getTypeByUH(classObj.getTypeUH())))
				
				if (_G.typeManager:findTypeByName(className) == nil) then
					logger:error("Engine type sanity check failed. Resolved a name for a type, which cannot be used to find any type.");
				elseif (_G.typeManager:findTypeByName(className).getUnifiedHandle == nil) then
					logger:error("Engine type sanity check failed. Resolved a name for a type, which cannot be used to find a type with unified handle getter.");
				elseif (_G.typeManager:findTypeByName(className):getUnifiedHandle() ~= classObj.getTypeUH()) then
					logger:error("Engine type sanity check failed. Resolved a name for a type, but the type resolved with that name is not the original type.");
				end
			else
				className = "(unknown_classname, " .. tostring(className) .. ", " .. tostring(classObj.getTypeUH()) .. ")"
			end
		else
			className = "(unknown_classname, " .. tostring(className) .. ")"
		end
	else
		className = "(unknown_classname, " .. tostring(className) .. ")"
	end
	return className
end

-- usage example, is exactly InstanceRoot (not inherited)
-- assert_exact_class(var, engine.base.InstanceRoot)
function assert_exact_class(obj, classObj)
	if (type(classObj) == "string") then
		logger:error("Given class is a string, when an actual class object is expected (i.e. engine.base.InstanceBase).");
		dump_assert_call_frame()
		return
	end
	if (type(classObj) ~= "userdata") then
		logger:error("Given class is not a valid class object (make sure such namespace and class exists).");
		dump_assert_call_frame()
		return
	end
	if (classObj.getStaticClassId == nil) then
		logger:error("Given class is not a valid class object (make sure such namespace and class exists).");
		dump_assert_call_frame()
		return
	end
	
	local className = solveClassNameFor(classObj)

	if (obj == nil) then
		logger:error("Object type of class \"" .. className .. "\" expected, but nil encountered.")
		dump_assert_call_frame()
	end	
	if (type(obj) ~= "userdata") then
		logger:error("Object type of class \"" .. className .. "\" expected, but \"".. type(obj) .."\" type encountered.")
		dump_assert_call_frame()
	end	
	if (obj:getClassId() ~= classObj.getStaticClassId()) then
		local wrongClassName = solveClassNameFor(obj)
		logger:error("Object type of class \"" .. className .. "\" expected, but \"".. wrongClassName.. "\" class encountered.")
		dump_assert_call_frame()
	end	

end

function assert_exact_class_or_nil(obj, className)
	if (obj == nil) then
		return
	end
	assert_exact_class(obj, className)
end

-- usage example, inherits from InstanceBase: 
-- assert_class(var, engine.base.InstanceBase)
function assert_class(obj, classObj)
	if (type(classObj) == "string") then
		logger:error("Given class is a string, when an actual class object is expected (i.e. engine.base.InstanceBase).");
		dump_assert_call_frame()
		return
	end
	if (type(classObj) ~= "userdata") then
		logger:error("Given class is not a valid class object (make sure such namespace and class exists).");
		dump_assert_call_frame()
		return
	end
	if (classObj.getStaticClassId == nil) then
		logger:error("Given class is not a valid class object (make sure such namespace and class exists).");
		dump_assert_call_frame()
		return
	end
	
	local className = solveClassNameFor(classObj)

	if (obj == nil) then
		logger:error("Object type of class \"" .. className .. "\" expected, but nil encountered.")
		dump_assert_call_frame()
	end	
	if (type(obj) ~= "userdata") then
		logger:error("Object type of class \"" .. className .. "\" expected, but \"".. type(obj) .."\" type encountered.")
		dump_assert_call_frame()
	end	
	if (not(obj:isInherited(classObj.getStaticObjectClass()))) then
		local wrongClassName = solveClassNameFor(obj)
		logger:error("Object type of class \"" .. className .. "\" expected, but \"".. wrongClassName.. "\" class encountered.")
		--logger:info("The object was: " .. tostring(obj))
		dump_assert_call_frame()
	end	
end

-- usage example: assert_class(var, engine.base.InstanceBase)
function assert_class_or_nil(obj, classObj)
	if (obj == nil) then
		return
	end
	assert_class(obj, className)
end


function assert_object(obj)
	-- well this just wont work...
	-- assert_class(obj, engine.base.treebase.AbstractEditableObjectTreeNode)
	
	-- gotta try something like this
	if (obj == nil) then
		logger:error("Tree node object expected, but nil encountered.")
		dump_assert_call_frame()
	end
	if (type(obj) ~= "userdata") then
		logger:error("Tree node object expected, but \"".. type(obj) .."\" type encountered.")
		dump_assert_call_frame()
	end	
	if (obj ~= nil and obj.getClassId ~= nil) then
		-- ok, assume that it is a valid object
	else
		logger:error("Tree node object expected, but some other userdata encountered.")
		dump_assert_call_frame()
	end	
end

function assert_object_or_nil(obj)
	-- well this just wont work...
	-- assert_class_or_nil(obj, engine.base.treebase.AbstractEditableObjectTreeNode)
	
	if (obj == nil) then
		return
	end
	assert_object(obj)
end

function assert_instance(obj)
	-- HACK: there are some problems with the C++ class hierarchy vs type hierarcy inconsistencies, thus...
	--if (obj.getClassId and obj:isInherited(engine.base.ComponentBase.getStaticObjectClass())) then
	--	logger:warning("Attempt to use assert_instance on a component, this check will fail due to class hierarchy vs type tree incosistency. If you want to allow components with this check, consider using assert_object or assert_component instead, otherwise try assert_entity.")
	--end

	-- FIXME: this seems to be broken
	--assert_class(obj, engine.base.InstanceBase)
end

function assert_instance_or_nil(obj)
	-- FIXME: this seems to be broken
	--assert_class_or_nil(obj, engine.base.InstanceBase)
end

function assert_entity(obj)
	-- FIXME: this seems to be broken
	--assert_class(obj, engine.instance.Entity)
end

function assert_entity_or_nil(obj)
	-- FIXME: this seems to be broken
	--assert_class_or_nil(obj, engine.instance.Entity)
end

function assert_component(obj)
	-- FIXME: this seems to be broken
	--assert_class(obj, engine.base.ComponentBase)
end

function assert_component_or_nil(obj)
	-- FIXME: this seems to be broken
	--assert_class_or_nil(obj, engine.base.ComponentBase)
end

function assert_type(obj)
	assert_class(obj, engine.base.typebase.TypeBase)
end

function assert_type_or_nil(obj)
	assert_class_or_nil(obj, engine.base.typebase.TypeBase)
end

function assert_widget(obj)
	if (obj == nil) then
		logger:error("Widget type expected (but got nil).")
		dump_assert_call_frame()
		return
	end
	-- note, assuming that existence of unwrap indicates that it is a widget
	-- (cannot check just class, as this might be a lua table wrapped widget too)
	if (not(obj.unwrap)) then
		logger:error("Widget type expected.")
		dump_assert_call_frame()
		return
	end
end

function assert_widget_or_nil(obj)
	if (obj == nil) then
		return
	end
	assert_widget(obj)
end

function assert_window(obj)
	if (obj == nil) then
		logger:error("Window descriptor table expected (but got nil).")
		dump_assert_call_frame()
		return
	end
	-- all window descriptor tables are expected to have a "windowDescriptor" with a true value.
	if (not(obj.windowDescriptor)) then
		logger:error("Window descriptor table expected.")
		dump_assert_call_frame()
		return
	end
end

function assert_window_or_nil(obj)
	if (obj == nil) then
		return
	end
	assert_window(obj)
end

function assert_uh(obj)
	if (obj == nil) then
		logger:error("UH expected (but got nil).")
		dump_assert_call_frame()
		return
	end
	if (type(obj) ~= "userdata") then
		logger:error("UH expected.")
		dump_assert_call_frame()
		return	
	end
	if (getScriptClassName(obj) ~= "UH") then
		logger:error("UH expected.")
		dump_assert_call_frame()
		return
	end
end

function assert_uh_or_nil(obj)
	if (obj == nil) then
		return
	end
	assert_uh(obj)
end

function assert_vc3(obj)
	if (obj == nil) then
		logger:error("VC3 expected (but got nil).")
		dump_assert_call_frame()
		return
	end
	if (type(obj) ~= "userdata") then
		logger:error("VC3 expected.")
		dump_assert_call_frame()
		return
	end
	if (getScriptClassName(obj) ~= "VC3") then
		logger:error("VC3 expected.")
		dump_assert_call_frame()
		return
	end
end

function assert_vc3_or_nil(obj)
	if (obj == nil) then
		return
	end
	assert_vc3(obj)
end

function assert_vc2(obj)
	if (obj == nil) then
		logger:error("VC2 expected (but got nil).")
		dump_assert_call_frame()
		return
	end
	if (type(obj) ~= "userdata") then
		logger:error("VC2 expected.")
		dump_assert_call_frame()
		return
	end
	if (getScriptClassName(obj) ~= "VC2") then
		logger:error("VC2 expected.")
		dump_assert_call_frame()
		return
	end
end

function assert_vc2_or_nil(obj)
	if (obj == nil) then
		return
	end
	assert_vc2(obj)
end


if (FB_PLATFORM == nil) then
	logger:error("FB_PLATFORM lua variable is missing.")
end

-- no such FB_BUILD exist, etc.
--if (FB_BUILD == "FB_FINAL_RELEASE" or FB_PLATFORM ~= "FB_WINDOWS") then
if (FB_PLATFORM ~= "FB_WINDOWS") then
	lua_assert_in_use = false
else
	lua_assert_in_use = true
end

-- global aliases for much easier use. 
-- always use these instead of using the full package name. (for disable possibility and easier future search&replace)

if (lua_assert_in_use) then
	_G.assert_nil = _M.assert_nil
	_G.assert_string = _M.assert_string
	_G.assert_string_or_nil = _M.assert_string_or_nil
	_G.assert_number = _M.assert_number
	_G.assert_number_or_nil = _M.assert_number_or_nil
	_G.assert_integer = _M.assert_integer
	_G.assert_integer_or_nil = _M.assert_integer_or_nil
	_G.assert_boolean = _M.assert_boolean
	_G.assert_boolean_or_nil = _M.assert_boolean_or_nil
	_G.assert_table = _M.assert_table 
	_G.assert_table_or_nil = _M.assert_table_or_nil
	_G.assert_function = _M.assert_function
	_G.assert_function_or_nil = _M.assert_function_or_nil
	_G.assert_luamodule = _M.assert_luamodule
	_G.assert_exact_class = _M.assert_exact_class
	_G.assert_exact_class_or_nil = _M.assert_exact_class_or_nil
	_G.assert_class = _M.assert_class
	_G.assert_class_or_nil = _M.assert_class_or_nil
	_G.assert_treenode = _M.assert_object 
	_G.assert_treenode_or_nil = _M.assert_object_or_nil 
	_G.assert_instance = _M.assert_instance 
	_G.assert_instance_or_nil = _M.assert_instance_or_nil
	_G.assert_entity = _M.assert_entity 
	_G.assert_entity_or_nil = _M.assert_entity_or_nil
	_G.assert_component = _M.assert_component
	_G.assert_component_or_nil = _M.assert_component_or_nil
	_G.assert_type = _M.assert_type
	_G.assert_type_or_nil = _M.assert_type_or_nil
	_G.assert_widget = _M.assert_widget
	_G.assert_widget_or_nil = _M.assert_widget_or_nil
	_G.assert_window = _M.assert_window
	_G.assert_window_or_nil = _M.assert_window_or_nil
	_G.assert_uh = _M.assert_uh
	_G.assert_uh_or_nil = _M.assert_uh_or_nil
	_G.assert_vc3 = _M.assert_vc3
	_G.assert_vc3_or_nil = _M.assert_vc3_or_nil
	_G.assert_vc2 = _M.assert_vc2
	_G.assert_vc2_or_nil = _M.assert_vc2_or_nil
	
else
	_G.assert_nil = _M.nop
	_G.assert_string = _M.nop
	_G.assert_string_or_nil = _M.nop
	_G.assert_number = _M.nop
	_G.assert_number_or_nil= _M.nop
	_G.assert_integer = _M.nop
	_G.assert_integer_or_nil= _M.nop
	_G.assert_boolean = _M.nop
	_G.assert_boolean_or_nil= _M.nop
	_G.assert_table = _M.nop
	_G.assert_table_or_nil = _M.nop
	_G.assert_function = _M.nop
	_G.assert_function_or_nil = _M.nop
	_G.assert_luamodule = _M.nop
	_G.assert_exact_class = _M.nop
	_G.assert_exact_class_or_nil = _M.nop
	_G.assert_class = _M.nop
	_G.assert_class_or_nil = _M.nop
	_G.assert_treenode = _M.nop
	_G.assert_treenode_or_nil = _M.nop
	_G.assert_instance = _M.nop
	_G.assert_instance_or_nil = _M.nop
	_G.assert_entity = _M.nop
	_G.assert_entity_or_nil = _M.nop
	_G.assert_component = _M.nop
	_G.assert_component_or_nil = _M.nop
	_G.assert_type = _M.nop
	_G.assert_type_or_nil = _M.nop
	_G.assert_widget = _M.nop
	_G.assert_widget_or_nil = _M.nop
	_G.assert_window = _M.nop
	_G.assert_window_or_nil = _M.nop
	_G.assert_uh = _M.nop
	_G.assert_uh_or_nil = _M.nop
	_G.assert_vc3 = _M.nop
	_G.assert_vc3_or_nil = _M.nop
	_G.assert_vc2 = _M.nop
	_G.assert_vc2_or_nil = _M.nop
end
