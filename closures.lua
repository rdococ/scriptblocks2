sb2.colors.closures = "#c1c1c1"

local modStorage = (...).modStorage
sb2.closureList = minetest.deserialize(modStorage:get_string("closures")) or minetest.deserialize(modStorage:get_string("functions")) or {}

sb2.Closure = sb2.registerClass("closure")

function sb2.Closure:initialize(id, context)
	self.id = id
	self.context = context:copy()
end

function sb2.Closure:getPos()
	return sb2.closureList[self.id] and sb2.closureList[self.id].pos
end
function sb2.Closure:getContext()
	return self.context
end

function sb2.Closure:callClosure(process, arg)
	local pos = self:getPos()
	if not pos then return process:getFrame():receiveArg(nil) end
	
	local frame = sb2.Frame:new(pos, process:getFrame():getContext())
	
	frame:setArg("call", self)
	frame:setArg(1, arg)
	
	return process:push(frame)
end
function sb2.Closure:tailCallClosure(process, arg)
	local pos = self:getPos()
	if not pos then return process:report(nil) end
	
	local frame = sb2.Frame:new(pos, process:getFrame():getContext())
	
	frame:setArg("call", self)
	frame:setArg(1, arg)
	
	return process:replace(frame)
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
		local id
		
		local itemMeta = itemstack:get_meta()
		local itemId = itemMeta:get_string("id")
		if itemId ~= "" then
			id = itemId
			
			if sb2.closureList[id] then
				if placerName then
					minetest.chat_send_player(placerName, "This closure has already been placed. Creating a new closure.")
				end
				
				sb2.log("warning", "Attempted to place closure %s at %s, but it already exists at %s. Generating a new ID.", id, minetest.pos_to_string(pos), minetest.pos_to_string(sb2.closureList[id].pos))
			end
			
			local parameter = itemMeta:get_string("parameter")
			meta:set_string("parameter", parameter)
			
			itemstack:set_count(0)
		end
		
		local attempts = 0
		while (not id or sb2.closureList[id]) and attempts <= 10000 do
			id = sb2.generateUUID()
			attempts = attempts + 1
		end
		
		if attempts > 10000 and sb.closures[id] then
			if placerName then
				minetest.chat_send_player(placerName, "Failed to initialize closure.")
				meta:set_string("owner", placerName)
			end
			
			sb2.log("error", "Failed to initialize closure at %s", minetest.pos_to_string(pos))
			meta:set_string("infotext", "Failed to initialize")
			
			return
		end
		
		sb2.log("action", "Closure %s created at %s", id, minetest.pos_to_string(pos))
		meta:set_string("id", id)
		
		if placerName then
			meta:set_string("owner", placerName)
		end
		
		meta:set_string("infotext", string.format("Owner: %s\nParameter: %q", placerName or "(unknown)", meta:get_string("parameter")))
		
		sb2.closureList[id] = {pos = pos}
	end,
	on_destruct = function (pos)
		local id = minetest.get_meta(pos):get_string("id")
		if id ~= "" then
			sb2.log("action", "Closure %s destroyed at %s", id, minetest.pos_to_string(pos))
			sb2.closureList[id] = nil
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
		
		local funcDef = sb2.closureList[id]
		if not funcDef then
			funcDef = {pos = pos}
			sb2.closureList[id] = funcDef
		end
		
		if not funcDef.pos or not vector.equals(pos, funcDef.pos) then
			funcDef.pos = pos
			
			sb2.log("action", "Updated closure %s position at %s", id, minetest.pos_to_string(pos))
			minetest.chat_send_player(senderName, "Updated closure position.")
		end
		
		meta:set_string("infotext", string.format("Owner: %s\nParameter: %q", meta:get_string("owner"), meta:get_string("parameter")))
	end,
	
	preserve_metadata = function (pos, oldNode, oldMeta, drops)
		local drop = drops[1]
		local itemMeta = drop:get_meta()
		
		local id = oldMeta.id or ""
		local parameter = oldMeta.parameter or ""
		
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
			
			return process:replace(sb2.Frame:new(vector.add(pos, dirs.right), funcContext))
		else
			local id = meta:get_string("id")
			local closure = sb2.Closure:new(id, context)
			
			if not closure:getPos() or not vector.equals(closure:getPos(), pos) then
				sb2.closureList[id] = sb2.closureList[id] or {}
				sb2.closureList[id].pos = pos
			end
			
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
		if type(closure) ~= "table" or not closure.tailCallClosure then return process:report(nil) end
		
		return closure:tailCallClosure(process, frame:getArg(1))
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
			if type(closure) ~= "table" or not closure.callClosure then return process:replace(sb2.Frame:new(vector.add(pos, dirs.front), context)) end
			
			return closure:callClosure(process, frame:getArg(1))
		end
		
		return process:replace(sb2.Frame:new(vector.add(pos, dirs.front), context))
	end,
})

local t = 0
minetest.register_globalstep(function (dt)
	t = t + dt
	
	if t > 60 then
		modStorage:set_string("closures", minetest.serialize(sb2.closureList))
		t = 0
	end
end)

minetest.register_on_shutdown(function ()
	modStorage:set_string("functions", "")
	modStorage:set_string("closures", minetest.serialize(sb2.closureList))
end)