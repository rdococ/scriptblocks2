sb2.colors.procedures = "#f070a0"

local modStorage = (...).modStorage
sb2.procedureList = minetest.deserialize(modStorage:get_string("procedures")) or {}

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
	
	on_construct = generateDefProcFormspec,
	after_place_node = function (pos, placer, itemstack, pointed_thing)
		if not placer then return end
		if not placer:is_player() then return end
		
		local owner = placer:get_player_name()
		local meta = minetest.get_meta(pos)
		
		meta:set_string("owner", owner)
		meta:set_string("infotext", "Owner: " .. owner .. "\nNo procedure name set")
	end,
	
	on_receive_fields = function (pos, formname, fields, sender)
		local senderName = sender:get_player_name()
		if minetest.is_protected(pos, senderName) then minetest.record_protection_violation(pos, senderName); return end
		
		local meta = minetest.get_meta(pos)
		
		local owner = meta:get_string("owner")
		local procedure = meta:get_string("procedure")
		local procDef = sb2.procedureList[procedure]
		
		if procedure ~= "" then
			-- If procedure is named but definition does not exist somehow (e.g. server crash), create it
			-- After this step, code assumes that procedure name == "" OR definition exists
			if not procDef then
				procDef = {pos = pos, owner = owner, public = meta:get_string("public") == "true"}
				sb2.log("warning", "Procedure %s did not have definition somehow - creating it now")
				sb2.procedureList[procedure] = procDef
			end
			
			-- If procedure is named and has moved (e.g. WorldEdit), update procedure definition
			if not vector.equals(pos, procDef.pos) then
				procDef.pos = pos
				sb2.log("action", "Updated procedure %s position at %s", procedure, minetest.pos_to_string(pos))
				minetest.chat_send_player(senderName, "Updated procedure position.")
			end
		end
		
		-- If any fields are changed, update metadata, and sometimes definition if it exists
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
			
			-- If new name already exists, just send a message to the user
			-- Otherwise, change the procedure's name and move procedure definition
			if newName ~= oldName then
				if sb2.procedureList[newName] then
					minetest.chat_send_player(senderName, "That procedure name already exists!")
				else
					-- If the procedure was already named, remove the old name's definition
					-- Otherwise, the procedure has just now been named. Create a new definition
					if oldName ~= "" then
						sb2.procedureList[oldName] = nil
					else
						procDef = {pos = pos, owner = owner, public = meta:get_string("public") == "true"}
					end
					
					-- Record definition at the new name, then update name in metadata and update variable
					sb2.procedureList[newName] = procDef
					sb2.log("action", "Renamed procedure %s to %s", oldName, newName)
					meta:set_string("procedure", newName)
					
					procedure = newName
				end
			end
		end
		if fields.public then
			meta:set_string("public", fields.public)
			
			-- If the procedure definition exists, set its publicity based on the checkbox
			if procDef then
				procDef.public = fields.public == "true"
			end
			
			generateDefProcFormspec(pos)
		end
		
		-- Step 3: Update infotext only if procedure has been named
		if procedure == "" then return end
		if procDef.owner ~= owner then
			procDef.owner = owner
		end
		
		meta:set_string("infotext", string.format("Owner: %s\nProcedure name: %q\nParameters: %q, %q\n%s", owner, procedure, meta:get_string("parameter1"), meta:get_string("parameter2"), meta:get_string("public") == "true" and "Public" or "Private"))
	end,
	
	on_destruct = function (pos)
		local procedure = minetest.get_meta(pos):get_string("procedure")
		if procedure ~= "" then
			sb2.procedureList[procedure] = nil
		end
	end,
})

local function findProcedure(procedure, user)
	local procedureDef = sb2.procedureList[procedure]
	if not procedureDef then return end
	
	if user ~= procedureDef.owner and not procedureDef.public then return end
	
	return procedureDef
end

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
		
		local procedureDef = findProcedure(procedure, context:getOwner())
		if not procedureDef then process:pop(); return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context)) end
		
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
		modStorage:set_string("procedures", minetest.serialize(sb2.procedureList))
		t = 0
	end
end)

minetest.register_on_shutdown(function ()
	modStorage:set_string("procedures", minetest.serialize(sb2.procedureList))
end)