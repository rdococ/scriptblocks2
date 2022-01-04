sb2.colors.fun = "#ff80ff"

sb2.registerScriptblock("scriptblocks2:get_call_stack_length", {
	sb2_label = "Get Call Stack Length",
	
	sb2_explanation = {
		shortExplanation = "Reports the current length of the call stack.",
	},
	
	sb2_color = sb2.colors.fun,
	sb2_icon  = "sb2_icon_count.png",
	sb2_slotted_faces = {},
	
	sb2_action = sb2.simple_action {
		arguments = {},
		action = function (pos, node, process, frame, context)
			local count = 0
			local f = frame
			
			while f do
				f = f:getParent()
				count = count + 1
			end
			
			return count
		end
	}
})

sb2.registerScriptblock("scriptblocks2:get_memory_usage", {
	sb2_label = "Get Process Memory Usage",
	
	sb2_explanation = {
		shortExplanation = "Reports an estimate of the memory used by the process, in bytes.",
	},
	
	sb2_color = sb2.colors.fun,
	sb2_icon  = "sb2_icon_list.png",
	sb2_slotted_faces = {},
	
	sb2_action = sb2.simple_action {
		arguments = {},
		action = function (pos, node, process, frame, context)
			return process.memoryUsage
		end
	}
})

sb2.registerScriptblock("scriptblocks2:get_context_owner", {
	sb2_label = "Get Context Owner",
	
	sb2_explanation = {
		shortExplanation = "Reports the player that owns the current script.",
	},
	
	sb2_color = sb2.colors.fun,
	sb2_icon  = "sb2_icon_if.png",
	sb2_slotted_faces = {},
	
	sb2_action = sb2.simple_action {
		arguments = {},
		action = function (pos, node, process, frame, context)
			return context:getOwner()
		end
	}
})