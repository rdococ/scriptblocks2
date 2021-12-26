sb2.colors.procedures = "#f070a0"

local modStorage = (...).modStorage
sb2.procedures = minetest.deserialize(modStorage:get_string("procedures")) or {}

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
	
	sb2_color = sb2.colors.procedures,
	sb2_icon  = "sb2_icon_define_procedure.png",
	sb2_slotted_faces = {"front"},
	
	sb2_action = sb2.simple_action {
		continuation = "front",
		action = function (pos, node, process, frame, context) end
	},
	
	on_construct = generateDefProcFormspec,
	after_place_node = function (pos, placer, itemstack, pointed_thing)
		if not placer then return end
		if not placer:is_player() then return end
		
		local owner = placer:get_player_name()
		local meta = minetest.get_meta(pos)
		
		meta:set_string("owner", owner)
		meta:set_string("infotext", "Owner: " .. owner .. "\nNo procedure name or parameters set")
	end,
	
	on_receive_fields = function (pos, formname, fields, sender)
		local senderName = sender:get_player_name()
		if minetest.is_protected(pos, senderName) then minetest.record_protection_violation(pos, senderName); return end
		
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		
		if fields.parameter1 then
			meta:set_string("parameter1", fields.parameter1)
		end
		if fields.parameter2 then
			meta:set_string("parameter2", fields.parameter2)
		end
		if fields.procedure then
			local oldName, newName = meta:get_string("procedure"), fields.procedure
			if newName:sub(1, owner:len() + 1) ~= owner .. ":" then
				newName = owner .. ":" .. newName
			end
			
			if newName ~= oldName then
				if sb2.procedures[newName] then
					if sender and sender:is_player() then
						minetest.chat_send_player(sender:get_player_name(), "That procedure name already exists!")
					end
				else
					local procDef = sb2.procedures[oldName]
					if procDef and vector.equals(procDef.pos, pos) then
						sb2.procedures[oldName] = nil
					else
						procDef = nil
					end
					
					sb2.procedures[newName] = procDef or {pos = pos, owner = owner, public = meta:get_string("public") == "true"}
					meta:set_string("procedure", newName)
				end
			end
		end
		if fields.public then
			meta:set_string("public", fields.public)
			
			local procDef = sb2.procedures[meta:get_string("procedure")]
			if procDef and vector.equals(procDef.pos, pos) then
				procDef.public = fields.public == "true"
			end
			
			generateDefProcFormspec(pos)
		end
		
		local procedure = meta:get_string("procedure")
		local procDef = sb2.procedures[procedure]
		if not vector.equals(pos, procDef.pos) then
			procDef.pos = pos
			sb2.log("action", "Updated procedure %s position at %s", procedure, minetest.pos_to_string(pos))
			minetest.chat_send_player(senderName, "Updated procedure position.")
		end
		if procDef.owner ~= owner then
			procDef.owner = owner
		end
		
		meta:set_string("infotext", string.format("Owner: %s\nProcedure name: %q\nParameters: %q, %q\n%s", owner, procedure, meta:get_string("parameter1"), meta:get_string("parameter2"), meta:get_string("public") == "true" and "Public" or "Private"))
	end,
	
	on_destruct = function (pos)
		local oldName = minetest.get_meta(pos):get_string("procedure")
		
		if sb2.procedures[oldName] and vector.equals(sb2.procedures[oldName].pos, pos) then
			sb2.procedures[oldName] = nil
		end
	end,
})

local function findProcedure(procedure, user)
	local procedureDef = sb2.procedures[procedure]
	if not procedureDef then return end
	
	if user ~= procedureDef.owner and not procedureDef.public then return end
	
	return procedureDef
end

sb2.registerScriptblock("scriptblocks2:run_procedure", {
	sb2_label = "Run Procedure",
	
	sb2_color = sb2.colors.procedures,
	sb2_icon  = "sb2_icon_run_procedure.png",
	sb2_slotted_faces = {"right", "left", "front"},
	
	on_construct = onRunProcConstruct,
	on_receive_fields = onRunProcReceiveFields,
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		local meta = minetest.get_meta(pos)
		local procedure = meta:get_string("procedure")
		
		local procedureDef = findProcedure(procedure, context:getOwner())
		if not procedureDef then return process:replace(sb2.Frame:new(vector.add(pos, dirs.front), context)) end
		
		local procPos = procedureDef.pos
		
		if not frame:isArgEvaluated(1) then
			frame:selectArg(1)
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		if not frame:isArgEvaluated(2) then
			frame:selectArg(2)
			return process:push(sb2.Frame:new(vector.add(pos, dirs.left), context))
		end
		if not frame:isArgEvaluated("value") then
			local procNode = minetest.get_node(procPos)
			if procNode.name == "ignore" then
				if not minetest.forceload_block(procPos, true) then return "yield" end
			end
			
			local procMeta = minetest.get_meta(procPos)
			
			frame:selectArg("value")
			
			local newContext = sb2.Context:new(procPos, procMeta:get_string("owner"))
			newContext:declareVar(procMeta:get_string("parameter1"), frame:getArg(1))
			newContext:declareVar(procMeta:get_string("parameter2"), frame:getArg(2))
			
			return process:push(sb2.Frame:new(procPos, newContext))
		end
		
		return process:replace(sb2.Frame:new(vector.add(pos, dirs.front), context))
	end,
})
sb2.registerScriptblock("scriptblocks2:call_procedure", {
	sb2_label = "Call Procedure",
	
	sb2_color = sb2.colors.procedures,
	sb2_icon  = "sb2_icon_call_procedure.png",
	sb2_slotted_faces = {"right", "front"},
	
	on_construct = onRunProcConstruct,
	on_receive_fields = onRunProcReceiveFields,
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		local meta = minetest.get_meta(pos)
		local procedure = meta:get_string("procedure")
		
		local proc = findProcedure(procedure, context:getOwner())
		if not proc then return process:report(nil) end
		
		local procPos = proc.pos
		
		if not frame:isArgEvaluated(1) then
			frame:selectArg(1)
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		if not frame:isArgEvaluated(2) then
			frame:selectArg(2)
			return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context))
		end
		
		local procNode = minetest.get_node(procPos)
		if procNode.name == "ignore" then
			if not minetest.forceload_block(procPos, true) then return "yield" end
		end
		
		local procMeta = minetest.get_meta(procPos)
		
		local newContext = sb2.Context:new(procPos, procMeta:get_string("owner"))
		newContext:declareVar(procMeta:get_string("parameter1"), frame:getArg(1))
		newContext:declareVar(procMeta:get_string("parameter2"), frame:getArg(2))
		
		return process:replace(sb2.Frame:new(procPos, newContext))
	end,
})

minetest.register_on_shutdown(function ()
	modStorage:set_string("procedures", minetest.serialize(sb2.procedures))
end)