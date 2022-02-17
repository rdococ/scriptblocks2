local modStorage = (...).modStorage

sb2.colors.procedures = "#f070a0"

--[[
Procedure

Instances of this class are references to named, user-defined procedures. An extension could allow access to Procedure values from user scripts for introspective purposes, or object-orientation (imagine constructing a procedure name from a dictionary's "class" entry and a method name).

Constructors:
	fromName(name)
		Returns the Procedure instance for the given procedure name. If the procedure doesn't exist, this will return nil!
	new(name, pos, owner, public)
		Creates and returns an entirely new Procedure.
		If the name already exists, this replaces that existing procedure. Procedure references will now point to the new procedure.

Methods:
	getPos()
		Returns the position where this procedure is defined.
	getOwner()
		Returns the player that created this procedure.
	isPublic()
		Returns true if anyone can use this procedure, not just its owner.
	update(pos, owner, public)
		Updates this procedure's definition according to the given fields.
	delete()
		Deletes this procedure.
	isDefined()
		Returns true if this procedure still exists (hasn't been deleted.)
	isAccessibleTo(user)
		Returns true if this procedure can be used by the given user.
	do2ArgCall(process, context, arg1, arg2)
		Pushes a frame that will run the procedure onto the process's call stack.
]]

sb2.Procedure = sb2.registerClass("procedure")

local procObjectList = {}
local procDataList = minetest.deserialize(modStorage:get_string("procedures")) or {}

function sb2.Procedure:isSerializable() return true end

function sb2.Procedure:fromName(name)
	if not procDataList[name] then return end
	if procObjectList[name] then return procObjectList[name] end
	
	local inst = self:rawNew()
	
	inst.name = name
	procObjectList[name] = inst
	
	return inst
end
function sb2.Procedure:new(name, pos, owner, public)
	procDataList[name] = {pos = pos, owner = owner, public = public}
	if procObjectList[name] then return procObjectList[name] end
	
	local inst = self:rawNew()
	
	inst.name = name
	procObjectList[name] = inst
	
	return inst
end
function sb2.Procedure:getPos()
	return procDataList[self.name].pos
end
function sb2.Procedure:getOwner()
	return procDataList[self.name].owner
end
function sb2.Procedure:isPublic()
	return procDataList[self.name].public
end
function sb2.Procedure:update(pos, owner, public)
	if not self.name then return end
	
	procDataList[self.name] = procDataList[self.name] or {}
	procDataList[self.name].pos = pos
	procDataList[self.name].owner = owner
	procDataList[self.name].public = public
end
function sb2.Procedure:delete()
	procDataList[self.name] = nil
end
function sb2.Procedure:isDefined()
	return not not procDataList[self.name]
end
function sb2.Procedure:isAccessibleTo(user)
	if not self.name then return false end
	return self:getOwner() == user or self:isPublic()
end

function sb2.Procedure:do2ArgCall(process, context, arg1, arg2)
	if not self:isDefined() then return process:receiveArg(nil) end
	
	local pos = self:getPos()
	local frame = sb2.Frame:new(pos, context)
	
	frame:setArg("call", self)
	frame:setArg(1, arg1)
	frame:setArg(2, arg2)
	
	return process:push(frame)
end

function sb2.Procedure:recordString(record)
	return string.format("<procedure %q>", self.name)
end
function sb2.Procedure:__eq(other)
	return self.name == other.name
end

local function generateDefProcFormspec(pos, proc)
	local meta = minetest.get_meta(pos)
	
	local public = true
	if proc then public = proc:isPublic() end
	
	meta:set_string("formspec", [[
		formspec_version[4]
		size[10,7.5]
		field[2.5,1;5,1;procedure;Name;${procedure}]
		field[2.5,2.5;5,1;parameter1;Right Parameter;${parameter1}]
		field[2.5,4;5,1;parameter2;Front/Left Parameter;${parameter2}]
		checkbox[2.5,5.5;public;Allow other players to run;]] .. (public and "true" or "false") .. [[]
		button_exit[3.5,6;3,1;proceed;Proceed]
	]])
end

local function onRunProcConstruct(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", [[
		field[procedure;Procedure;${procedure}]
	]])
	meta:set_string("infotext", "No procedure name set")
end
local function onRunProcReceiveFields(pos, formname, fields, sender)
	local senderName = sender:get_player_name()
	if minetest.is_protected(pos, senderName) then minetest.record_protection_violation(pos, senderName); return end
	
	local meta = minetest.get_meta(pos)
	
	if fields.procedure then
		local newProcName = fields.procedure
		if not newProcName:match(".+%:.*") then
			newProcName = senderName .. ":" .. newProcName
		end
		
		meta:set_string("procedure", newProcName)
		meta:set_string("infotext", string.format("Procedure: %q", newProcName))
	end
end

sb2.registerScriptblock("scriptblocks2:define_procedure", {
	sb2_label = "Define Procedure",
	
	sb2_explanation = {
		shortExplanation = "Defines a custom procedure.",
		inputValues = {
			{"Name", "The name of this procedure."},
			{"Right Parameter", "The name of the variable to store the right argument in."},
			{"Front/Left Parameter", "The name of the variable to store the front/left argument in."},
			{"Public", "Whether this procedure can be called by other players' scripts."},
		},
		inputSlots = {
			{"Front", "What to do when this procedure is called."},
		},
	},
	
	sb2_color = sb2.colors.procedures,
	sb2_icon  = "sb2_icon_define_procedure.png",
	sb2_slotted_faces = {"front"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		process:pop()
		
		if frame:getArg("call") then
			local meta = minetest.get_meta(pos)
			
			local procContext = context:copy()
			
			procContext:setHead(pos)
			procContext:setOwner(meta:get_string("owner"))
			
			procContext:declareVar(meta:get_string("parameter1"), frame:getArg(1))
			procContext:declareVar(meta:get_string("parameter2"), frame:getArg(2))
			
			return process:push(sb2.Frame:new(vector.add(pos, dirs.front), procContext))
		else
			return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context))
		end
	end,
	
	after_place_node = function (pos, placer, itemstack, pointed_thing)
		if not placer then return end
		if not placer:is_player() then return end
		
		local owner = placer:get_player_name()
		local meta = minetest.get_meta(pos)
		
		meta:set_string("owner", owner)
		meta:set_string("infotext", "Owner: " .. owner .. "\nNo procedure name set")
		
		generateDefProcFormspec(pos)
	end,
	
	on_receive_fields = function (pos, formname, fields, sender)
		local senderName = sender:get_player_name()
		if minetest.is_protected(pos, senderName) then minetest.record_protection_violation(pos, senderName); return end
		
		local meta = minetest.get_meta(pos)

		local procedureName = meta:get_string("procedure")
		local procedure = sb2.Procedure:fromName(procedureName)
		
		local owner = meta:get_string("owner")
		local public = procedure and procedure:isPublic()
		if public == nil then public = true end
		
		if fields.parameter1 then
			meta:set_string("parameter1", fields.parameter1)
		end
		if fields.parameter2 then
			meta:set_string("parameter2", fields.parameter2)
		end
		if fields.procedure then
			-- Make sure new name follows proper naming rules
			local oldName, newName = procedureName, fields.procedure
			if newName:sub(1, owner:len() + 1) ~= owner .. ":" then
				newName = owner .. ":" .. newName
			end
			
			if newName ~= oldName then
				local newProcedure = sb2.Procedure:fromName(newName)
				if newProcedure then
					minetest.chat_send_player(senderName, "That procedure already exists!")
				else
					-- Delete the old procedure if it existed
					if procedure then
						procedure:delete()
					end
					
					-- Update metadata
					meta:set_string("procedure", newName)
					
					-- Update variables
					procedureName = newName
					procedure = sb2.Procedure:new(procedureName, pos, owner, public)
					
					sb2.log("action", "%s names a procedure %s at %s", owner, procedureName, minetest.pos_to_string(pos))
				end
			end
		end
		if fields.public then
			public = fields.public == "true"
		end
		
		-- At the end of the day, if the procedure exists, update its data
		if not procedure then return end
		procedure:update(pos, owner, public)
		generateDefProcFormspec(pos, procedure)
		
		meta:set_string("infotext", string.format("Owner: %s\nProcedure name: %q\nParameters: %q, %q\n%s", owner, procedureName, meta:get_string("parameter1"), meta:get_string("parameter2"), public and "Public" or "Private"))
	end,
	
	on_destruct = function (pos)
		local procedureName = minetest.get_meta(pos):get_string("procedure")
		local procedure = sb2.Procedure:fromName(procedureName)
		if procedure then
			procedure:delete()
		end
	end,
})

sb2.registerScriptblock("scriptblocks2:run_procedure", {
	sb2_label = "Run Procedure",
	
	sb2_explanation = {
		shortExplanation = "Runs a custom procedure before continuing.",
		inputValues = {
			{"Procedure", "The name of the procedure to run."},
		},
		inputSlots = {
			{"Right", "The first value to pass to the procedure."},
			{"Left", "The second value to pass to the procedure."},
			{"Front", "What to do next."},
		},
	},
	
	sb2_color = sb2.colors.procedures,
	sb2_icon  = "sb2_icon_run_procedure.png",
	sb2_slotted_faces = {"right", "left", "front"},
	
	on_construct = onRunProcConstruct,
	on_receive_fields = onRunProcReceiveFields,
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated(1) then
			frame:selectArg(1)
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		if not frame:isArgEvaluated(2) then
			frame:selectArg(2)
			return process:push(sb2.Frame:new(vector.add(pos, dirs.left), context))
		end
		
		local meta = minetest.get_meta(pos)
		local procedure = sb2.Procedure:fromName(meta:get_string("procedure"))
		
		local accessible = procedure and procedure:isAccessibleTo(context:getOwner())
		if not accessible then process:pop(); return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context)) end
		
		if not frame:isArgEvaluated("value") then
			frame:selectArg("value")
			return procedure:do2ArgCall(process, context, frame:getArg(1), frame:getArg(2))
		end
		
		process:pop()
		return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context))
	end,
})
sb2.registerScriptblock("scriptblocks2:call_procedure", {
	sb2_label = "Call Procedure",
	
	sb2_explanation = {
		shortExplanation = "Calls a custom procedure and reports its value.",
		inputValues = {
			{"Procedure", "The name of the procedure to call."},
		},
		inputSlots = {
			{"Right", "The first value to pass to the procedure."},
			{"Front", "The second value to pass to the procedure."},
		},
	},
	
	sb2_color = sb2.colors.procedures,
	sb2_icon  = "sb2_icon_call_procedure.png",
	sb2_slotted_faces = {"right", "front"},
	
	on_construct = onRunProcConstruct,
	on_receive_fields = onRunProcReceiveFields,
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated(1) then
			frame:selectArg(1)
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		if not frame:isArgEvaluated(2) then
			frame:selectArg(2)
			return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context))
		end
		
		local meta = minetest.get_meta(pos)
		local procedure = sb2.Procedure:fromName(meta:get_string("procedure"))
		
		local accessible = procedure and procedure:isAccessibleTo(context:getOwner())
		if not accessible then return process:report(nil) end
		
		process:pop()
		return procedure:do2ArgCall(process, context, frame:getArg(1), frame:getArg(2))
	end,
})

local t = 0
minetest.register_globalstep(function (dt)
	t = t + dt
	
	if t > 60 then
		modStorage:set_string("procedures", minetest.serialize(procDataList))
		t = 0
	end
end)

minetest.register_on_shutdown(function ()
	modStorage:set_string("procedures", minetest.serialize(procDataList))
end)