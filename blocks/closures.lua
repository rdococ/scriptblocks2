local modStorage = (...).modStorage

sb2.colors.closures = "#c1c1c1"

--[[
ClosureBody

Instances of this class are references to named, user-defined closure bodies. An extension could allow users to construct Closure instances manually by combining ClosureBody instances with user-created Context instances - something equivalent to Lua's "setfenv".

Constructors:
	fromName(name)
		Returns the ClosureBody instance for the given closure body name. If the closure doesn't exist, this will return nil!
	new(pos)
		Creates and returns an entirely new ClosureBody with a randomly generated name.
	newNamed(name, pos)
		Creates and returns a new ClosureBody with a pre-existing name.
		If the name already exists, this replaces the existing ClosureBody. ClosureBody references and Closure instances point to the new ClosureBody.

Methods:
	getName()
		Returns the name of this ClosureBody.
	getPos()
		Returns the position where this closure body is defined.
	update(pos)
		Updates this closure body's definition according to the given fields.
	delete()
		Deletes this closure body.
	isDefined()
		Returns true if this closure body still exists (hasn't been deleted).
]]

sb2.ClosureBody = sb2.registerClass("closureBody")

local bodyObjectList = {}
local bodyDataList = minetest.deserialize(modStorage:get_string("closures")) or {}

function sb2.ClosureBody:isSerializable() return true end

function sb2.ClosureBody:fromName(name)
	if not bodyDataList[name] then return end
	if bodyObjectList[name] then return bodyObjectList[name] end
	
	local inst = self:rawNew()
	
	inst.name = name
	bodyObjectList[name] = inst
	
	return inst
end
function sb2.ClosureBody:new(pos)
	local name
	
	local attempts = 0
	while (not name or bodyDataList[name]) and attempts <= 100000 do
		name = sb2.generateUUID()
		attempts = attempts + 1
	end
	
	return self:newNamed(name, pos)
end
function sb2.ClosureBody:newNamed(name, pos)
	bodyDataList[name] = {pos = pos}
	if bodyObjectList[name] then return bodyObjectList[name] end
	
	local inst = self:rawNew()
	
	inst.name = name
	bodyObjectList[name] = inst
	
	return inst
end
function sb2.ClosureBody:getName()
	return self.name
end
function sb2.ClosureBody:getPos()
	return bodyDataList[self.name].pos
end
function sb2.ClosureBody:update(pos)
	bodyDataList[self.name] = bodyDataList[self.name] or {}
	bodyDataList[self.name].pos = pos
end
function sb2.ClosureBody:delete()
	bodyDataList[self.name] = nil
end
function sb2.ClosureBody:isDefined()
	return not not bodyDataList[self.name]
end

function sb2.ClosureBody:recordString(record)
	return string.format("<closure body %s>", self.name)
end
function sb2.ClosureBody:__eq(other)
	return self.name == other.name
end

--[[
Closure

A closure is a value that represents an anonymous procedure along with an environment. Closures store their context, containing the variables they can access, and their ID, representing the definition of the anonymous procedure.

Constructor:
	new(body, context)
		Creates a new closure with the given closure body and context.

Methods:
	getContext()
		Returns the context, consisting of variables from this closure's lexical scope.
	
	doCall(process, context, arg)
		Performs a closure call. This generally pushes a new frame to the process's stack to evaluate the closure's body.

If you are looking to extend scriptblocks2, you can register classes with their own doCall methods and the 'run'/'call' blocks will automatically detect the presence of the method and run it when they encounter your custom data type.
]]

sb2.Closure = sb2.registerClass("closure")

function sb2.Closure:isSerializable() return true end

function sb2.Closure:initialize(body, context)
	self.body = body
	self.context = context:copy()
end
function sb2.Closure:getContext()
	return self.context
end

function sb2.Closure:doCall(process, context, arg)
	if not self.body:isDefined() then return process:receiveArg(nil) end
	local pos = self.body:getPos()
	
	local frame = sb2.Frame:new(pos, context)
	
	frame:setArg("call", self)
	frame:setArg(1, arg)
	
	return process:push(frame)
end

function sb2.Closure:recordString(record)
	return "<closure>"
end
function sb2.Closure:recordLuaValue(record)
	return
end

sb2.registerScriptblock("scriptblocks2:create_closure", {
	sb2_label = "Create Closure",
	
	sb2_explanation = {
		shortExplanation = "Creates and reports a closure, an anonymous procedure that can be stored like a value.",
		inputValues = {
			{"Parameter", "The name of the variable to store the argument in."},
		},
		inputSlots = {
			{"Right", "The scriptblocks to run when this closure is called."}
		},
		additionalPoints = {
			"Closures can access and modify variables from where they were created."
		}
	},
	
	sb2_color = sb2.colors.closures,
	sb2_icon  = "sb2_icon_define_procedure.png",
	sb2_slotted_faces = {"right"},
	
	sb2_input_name = "parameter",
	sb2_input_label = "Parameter",
	sb2_input_default = "",
	
	after_place_node = function (pos, placer, itemstack, pointed_thing)
		local placerName = placer and placer:get_player_name()
		
		local meta = minetest.get_meta(pos)
		local body
		
		local itemMeta = itemstack:get_meta()
		local itemId = itemMeta:get_string("id")
		if itemId ~= "" then
			local existingBody = sb2.ClosureBody:fromName(itemId)
			if existingBody then
				if placerName then
					minetest.chat_send_player(placerName, "This closure has already been placed. Creating a new closure.")
				end
				
				sb2.log("warning", "Attempted to place closure %s at %s, but it already exists at %s. Generating a new name.", itemId, minetest.pos_to_string(pos), minetest.pos_to_string(existingBody:getPos()))
			else
				body = sb2.ClosureBody:newNamed(itemId, pos)
			end
			
			local parameter = itemMeta:get_string("parameter")
			meta:set_string("parameter", parameter)
			
			itemstack:set_count(0)
		end
		
		body = body or sb2.ClosureBody:new(pos)
		local id = body:getName()
		
		sb2.log("action", "Closure %s created at %s", id, minetest.pos_to_string(pos))
		meta:set_string("id", id)
		
		if placerName then
			meta:set_string("owner", placerName)
		end
		
		meta:set_string("infotext", string.format("Owner: %s\nParameter: %q", placerName or "(unknown)", meta:get_string("parameter")))
	end,
	on_destruct = function (pos)
		local id = minetest.get_meta(pos):get_string("id")
		if id ~= "" then
			sb2.log("action", "Closure %s destroyed at %s", id, minetest.pos_to_string(pos))
			
			local body = sb2.ClosureBody:fromName(id)
			if body then
				body:delete()
			end
		end
	end,
	
	on_receive_fields = function (pos, formname, fields, sender)
		local senderName = sender:get_player_name()
		if minetest.is_protected(pos, senderName) then return end
		
		local node = minetest.get_node(pos)
		local dirs = sb2.facedirToDirs(node.param2)
		
		local meta = minetest.get_meta(pos)
		local id = meta:get_string("id")
		
		if id == "" then return end
		
		meta:set_string("infotext", string.format("Owner: %s\nParameter: %q", meta:get_string("owner"), meta:get_string("parameter")))
	end,
	
	preserve_metadata = function (pos, oldNode, oldMeta, drops)
		local drop = drops[1]
		local itemMeta = drop:get_meta()
		
		local id = oldMeta.id or ""
		local parameter = oldMeta.parameter or ""
		
		if id == "" then return end
		
		itemMeta:set_string("id", id)
		itemMeta:set_string("parameter", parameter)
		itemMeta:set_string("description", string.format("Create Closure Scriptblock %s(%s)", id:sub(1, 8), parameter))
	end,
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		local meta = minetest.get_meta(pos)
		
		local closure = frame:getArg("call")
		if closure then
			local meta = minetest.get_meta(pos)
			
			local funcContext = closure:getContext():copy()
			funcContext:setOwner(meta:get_string("owner"))
			funcContext:declareVar(meta:get_string("parameter"), frame:getArg(1))
			
			process:pop()
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), funcContext))
		else
			local id = meta:get_string("id")
			if id == "" then return process:report(nil) end
			
			body = sb2.ClosureBody:fromName(id)
			
			if not body then body = sb2.ClosureBody:newNamed(id, pos) end
			body:update(pos)
			
			local closure = sb2.Closure:new(body, context)
			return process:report(closure)
		end
	end,
})

sb2.registerScriptblock("scriptblocks2:call_closure", {
	sb2_label = "Call Closure",
	
	sb2_explanation = {
		shortExplanation = "Calls a closure and reports its value.",
		inputSlots = {
			{"Front", "The closure to call."},
			{"Right", "The value to pass to the closure."},
		},
	},
	
	sb2_color = sb2.colors.closures,
	sb2_icon  = "sb2_icon_call_procedure.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated("closure") then
			frame:selectArg("closure")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context))
		end
		if not frame:isArgEvaluated(1) then
			frame:selectArg(1)
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		
		local closure = frame:getArg("closure")
		if type(closure) ~= "table" or not closure.doCall then return process:report(nil) end
		
		process:pop()
		return closure:doCall(process, context, frame:getArg(1))
	end,
})
sb2.registerScriptblock("scriptblocks2:run_closure", {
	sb2_label = "Run Closure",
	
	sb2_explanation = {
		shortExplanation = "Runs a closure before continuing.",
		inputSlots = {
			{"Left", "The closure to run."},
			{"Right", "The value to pass to the closure."},
			{"Front", "What to do next."},
		},
	},
	
	sb2_color = sb2.colors.closures,
	sb2_icon  = "sb2_icon_run_procedure.png",
	sb2_slotted_faces = {"left", "right", "front"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated("closure") then
			frame:selectArg("closure")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.left), context))
		end
		if not frame:isArgEvaluated(1) then
			frame:selectArg(1)
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		if not frame:isArgEvaluated("value") then
			frame:selectArg("value")
			
			local closure = frame:getArg("closure")
			if type(closure) ~= "table" or not closure.doCall then process:pop(); return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context)) end
			
			return closure:doCall(process, context, frame:getArg(1))
		end
		
		process:pop()
		return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context))
	end,
})

local t = 0
minetest.register_globalstep(function (dt)
	t = t + dt
	
	if t > 60 then
		modStorage:set_string("closures", minetest.serialize(bodyDataList))
		t = 0
	end
end)

minetest.register_on_shutdown(function ()
	modStorage:set_string("closures", minetest.serialize(bodyDataList))
end)