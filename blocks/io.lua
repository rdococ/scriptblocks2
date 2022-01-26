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

-- os.time() usually only has a resolution of 1s. Get it when the server starts, then add get_server_uptime for extra "accuracy" ;)
sb2.serverStart = os.difftime(os.time(), os.time {year = 2000, month = 1, day = 1, hour = 0, min = 0, sec = 0, isdst = false})

sb2.registerScriptblock("scriptblocks2:get_seconds_since_2000", {
	sb2_label = "Get Seconds Since 2000",
	
	sb2_explanation = {
		shortExplanation = "Reports the number of seconds passed since the year 2000.",
		additionalPoints = {
			"If you save this value, you can subtract it to determine the number of seconds passed since you saved it.",
		},
	},
	
	sb2_color = sb2.colors.looks,
	sb2_icon = "sb2_icon_wait.png",
	sb2_slotted_faces = {},
	
	sb2_action = sb2.simple_action {
		action = function (pos, node, process, frame, context, message)
			return sb2.serverStart + minetest.get_server_uptime()
		end
	}
})