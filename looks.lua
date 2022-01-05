sb2.colors.looks = "#b76cff"

sb2.registerScriptblock("scriptblocks2:say", {
	sb2_label = "Say",
	
	sb2_explanation = {
		shortExplanation = "Says something in the chat to the starter of the process.",
		inputSlots = {
			{"Right", "The message to say."},
			{"Front", "What to do next."},
		},
		additionalPoints = {
			"If someone else calls your procedure, they can see the message!",
		},
	},
	
	sb2_color = sb2.colors.looks,
	sb2_icon = "sb2_icon_say.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right"},
		continuation = "front",
		
		action = function (pos, node, process, frame, context, message)
			message = sb2.toString(message)
			
			local starter = process:getStarter()
			if starter then
				minetest.chat_send_player(starter, "[Process] Said: " .. message)
			end
		end
	}
})