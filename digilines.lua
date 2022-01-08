sb2.colors.digilines = "#8080ff"

sb2.registerScriptblock("scriptblocks2:receive_digiline_message", {
	sb2_label = "When I Receive Digiline Message",
	
	sb2_explanation = {
		shortExplanation = "Starts a script after receiving a digiline message.",
		inputValues = {
			{"Channel", "The channel to listen out for."},
		},
		inputSlots = {
			{"Front", "What to do when a message is received."},
		},
		additionalPoints = {
			"The content of the message is available in a variable called 'message'.",
		},
	},
	
	sb2_color = sb2.colors.digilines,
	sb2_icon  = "sb2_icon_receive.png",
	sb2_slotted_faces = {"front"},
	
	sb2_input_name = "channel",
	sb2_input_label = "Channel",
	sb2_input_default = "",
	
	sb2_action = sb2.simple_action {
		continuation = "front",
		action = function (pos, node, process, frame, context) end
	},
	
	after_place_node = function (pos, placer, itemstack, pointed_thing)
		if not placer then return end
		if not placer:is_player() then return end
		
		local name = placer:get_player_name()
		local meta = minetest.get_meta(pos)
		
		meta:set_string("owner", name)
		meta:set_string("infotext", "Owner: " .. name .. "\nNo channel set")
	end,
	
	on_receive_fields = function (pos, node)
		local meta = minetest.get_meta(pos)
		
		local owner = meta:get_string("owner")
		local setchan = meta:get_string("channel")
		
		meta:set_string("infotext", "Owner: " .. owner .. "\nChannel: " .. string.format("%q", setchan))
	end,
	
	digilines = {
		receptor = {},
		effector = {
			action = function (pos, node, channel, message)
				local meta = minetest.get_meta(pos)
				local setchan = meta:get_string("channel")
				
				sb2.Process:queueEventAt(pos, {type = "digiline", channel = channel, message = message})
				
				if channel == setchan then
					local context = sb2.Context:new(pos, meta:get_string("owner"))
					context:declareVar("message", sb2.toSB2Value(message))
					
					sb2.Process:new(sb2.Frame:new(pos, context))
				end
			end
		}
	},
})
sb2.registerScriptblock("scriptblocks2:send_digiline_message", {
	sb2_label = "Send Digiline Message",
	
	sb2_explanation = {
		shortExplanation = "Sends a digiline message from the starting block.",
		inputSlots = {
			{"Left", "The channel to send the message on."},
			{"Right", "The message to send."},
			{"Front", "What to do next."},
		},
		additionalPoints = {
			"You can only send a digiline message from processes you started!",
			"This only works in a 'When I Receive Digiline Message' process!"
		},
	},
	
	sb2_color = sb2.colors.digilines,
	sb2_icon  = "sb2_icon_send.png",
	sb2_slotted_faces = {"right", "left", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"left", "right"},
		continuation = "front",
		action = function (pos, node, process, frame, context, channel, message)
			if process:getStarter() ~= context:getOwner() then return end
			digilines.receptor_send(process:getHead(), digilines.rules.default, channel, sb2.toLuaValue(message))
		end
	},
})
sb2.registerScriptblock("scriptblocks2:wait_for_digiline_message", {
	sb2_label = "Wait For Digiline Message",
	
	sb2_explanation = {
		shortExplanation = "Waits until a digiline message is received on the given channel, and reports it.",
		inputSlots = {
			{"Right", "The channel to receive the message from."},
		},
		additionalPoints = {
			"You can only receive digiline messages from processes you started!",
			"This only works in a 'When I Receive Digiline Message' process!"
		},
	},
	
	sb2_color = sb2.colors.digilines,
	sb2_icon  = "sb2_icon_wait.png",
	sb2_slotted_faces = {"right"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if process:getStarter() ~= context:getOwner() then return process:report(nil) end
		
		if not frame:isArgEvaluated("channel") then
			frame:selectArg("channel")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		
		local channel = frame:getArg("channel")
		local event = process:handleEvent(function (event)
			return event.type == "digiline" and event.channel == channel
		end)
		
		if event then return process:report(sb2.toSB2Value(event.message)) else return process:yield() end
	end
})