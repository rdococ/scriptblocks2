sb2.colors.digilines = "#8080ff"

sb2.registerScriptblock("scriptblocks2:receive_digiline_message", {
	sb2_label = "When I Receive Digiline Message",
	
	sb2_color = sb2.colors.digilines,
	sb2_icon  = "sb2_icon_receive.png",
	sb2_slotted_faces = {"front"},
	
	sb2_input_name = "channel",
	sb2_input_label = "Channel",
	sb2_input_default = "",
	
	sb2_action = sb2.simple_action {
		continuation = "front",
		action = function (pos, node, process, frame) end
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
				
				if channel == setchan then
					local frame = sb2.createFrame(pos, nil, meta:get_string("owner"))
					sb2.declareVar(frame, "message", sb2.toSB2Value(message))
					
					sb2.createProcess(frame)
				end
			end
		}
	},
})
sb2.registerScriptblock("scriptblocks2:send_digiline_message", {
	sb2_label = "Send Digiline Message",
	
	sb2_color = sb2.colors.digilines,
	sb2_icon  = "sb2_icon_send.png",
	sb2_slotted_faces = {"front", "right", "left"},
	
	sb2_action = sb2.simple_action {
		arguments = {"left", "right"},
		continuation = "front",
		action = function (pos, node, process, frame, channel, message)
			digilines.receptor_send(sb2.getHead(frame), digilines.rules.default, channel, sb2.toLuaValue(message))
		end
	},
})