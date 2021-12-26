sb2.colors.looks = "#b76cff"

sb2.registerScriptblock("scriptblocks2:say", {
	sb2_label = "Say",
	
	sb2_color = sb2.colors.looks,
	sb2_icon = "sb2_icon_say.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right"},
		continuation = "front",
		
		action = function (pos, node, process, frame, context, message)
			message = sb2.toString(message)
			
			local owner = context:getOwner()
			if owner then
				minetest.chat_send_player(owner, "[Process] " .. message)
			end
		end
	}
})