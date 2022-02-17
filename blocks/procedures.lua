sb2.colors.procedures = "#f070a0"

sb2.procedureData = {}

local modStorage = (...).modStorage
sb2.procedureData.list = minetest.deserialize(modStorage:get_string("procedures")) or {}

function sb2.procedureData.update(name, pos, owner, public)
	sb2.procedureData.list[name] = {pos = pos, owner = owner, public = public}
end
function sb2.procedureData.exists(name)
	return not not sb2.procedureData.list[name]
end
function sb2.procedureData.getPos(name)
	return sb2.procedureData.list[name] and sb2.procedureData.list[name].pos
end
function sb2.procedureData.getOwner(name)
	return sb2.procedureData.list[name] and sb2.procedureData.list[name].owner
end
function sb2.procedureData.getPublic(name)
	return sb2.procedureData.list[name] and sb2.procedureData.list[name].public
end
function sb2.procedureData.delete(name)
	sb2.procedureData.list[name] = nil
end
function sb2.procedureData.canAccess(procedure, user)
	local procedureDef = sb2.procedureData.list[procedure]
	if not procedureDef then return false end
	
	return user == procedureDef.owner or procedureDef.public
end

local function generateDefProcFormspec(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", [[
		formspec_version[4]
		size[10,7.5]
		field[2.5,1;5,1;procedure;Name;${procedure}]
		field[2.5,2.5;5,1;parameter1;Right Parameter;${parameter1}]
		field[2.5,4;5,1;parameter2;Front/Left Parameter;${parameter2}]
		checkbox[2.5,5.5;public;Allow other players to run;]] .. meta:get_string("public") .. [[]
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
		meta:set_string("public", "true")
		
		generateDefProcFormspec(pos)
	end,
	
	on_receive_fields = function (pos, formname, fields, sender)
		local senderName = sender:get_player_name()
		if minetest.is_protected(pos, senderName) then minetest.record_protection_violation(pos, senderName); return end
		
		local meta = minetest.get_meta(pos)

		local procedure = meta:get_string("procedure")
		local owner = meta:get_string("owner")
		local public = meta:get_string("public") == "true"
		
		if fields.parameter1 then
			meta:set_string("parameter1", fields.parameter1)
		end
		if fields.parameter2 then
			meta:set_string("parameter2", fields.parameter2)
		end
		if fields.procedure then
			-- Make sure new name follows proper naming rules
			local oldName, newName = procedure, fields.procedure
			if newName:sub(1, owner:len() + 1) ~= owner .. ":" then
				newName = owner .. ":" .. newName
			end
			
			if newName ~= oldName then
				if sb2.procedureData.exists(newName) then
					minetest.chat_send_player(senderName, "That procedure name already exists!")
				else
					-- Remove the old definition
					sb2.procedureData.delete(oldName)
					
					-- Update metadata and variable
					meta:set_string("procedure", newName)
					procedure = newName
				end
			end
		end
		if fields.public then
			meta:set_string("public", fields.public)
			public = fields.public == "true"
			
			-- Updating publicity requires updating formspec
			generateDefProcFormspec(pos)
		end
		
		-- At the end of the day, if the procedure has been named, update its data
		if procedure == "" then return end
		sb2.procedureData.update(procedure, pos, owner, public)
		
		meta:set_string("infotext", string.format("Owner: %s\nProcedure name: %q\nParameters: %q, %q\n%s", owner, procedure, meta:get_string("parameter1"), meta:get_string("parameter2"), public and "Public" or "Private"))
	end,
	
	on_destruct = function (pos)
		local procedure = minetest.get_meta(pos):get_string("procedure")
		if procedure ~= "" then
			sb2.procedureData.list[procedure] = nil
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
		
		local meta = minetest.get_meta(pos)
		local procedure = meta:get_string("procedure")
		
		local canAccess = sb2.procedureData.canAccess(procedure, context:getOwner())
		if not canAccess then process:pop(); return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context)) end
		
		local procPos = sb2.procedureData.getPos(procedure)
		
		if not frame:isArgEvaluated(1) then
			frame:selectArg(1)
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		if not frame:isArgEvaluated(2) then
			frame:selectArg(2)
			return process:push(sb2.Frame:new(vector.add(pos, dirs.left), context))
		end
		if not frame:isArgEvaluated("value") then
			frame:selectArg("value")
			
			local procFrame = sb2.Frame:new(procPos, context)
			
			procFrame:setArg("call", true)
			procFrame:setArg(1, frame:getArg(1))
			procFrame:setArg(2, frame:getArg(2))
			
			return process:push(procFrame)
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
		
		local meta = minetest.get_meta(pos)
		local procedure = meta:get_string("procedure")
		
		local canAccess = sb2.procedureData.canAccess(procedure, context:getOwner())
		if not canAccess then return process:report(nil) end
		
		local procPos = sb2.procedureData.getPos(procedure)
		
		if not frame:isArgEvaluated(1) then
			frame:selectArg(1)
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		if not frame:isArgEvaluated(2) then
			frame:selectArg(2)
			return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context))
		end
		
		local procFrame = sb2.Frame:new(procPos, context)
		
		procFrame:setArg("call", true)
		procFrame:setArg(1, frame:getArg(1))
		procFrame:setArg(2, frame:getArg(2))
		
		process:pop()
		return process:push(procFrame)
	end,
})

local t = 0
minetest.register_globalstep(function (dt)
	t = t + dt
	
	if t > 60 then
		modStorage:set_string("procedures", minetest.serialize(sb2.procedureData.list))
		t = 0
	end
end)

minetest.register_on_shutdown(function ()
	modStorage:set_string("procedures", minetest.serialize(sb2.procedureData.list))
end)