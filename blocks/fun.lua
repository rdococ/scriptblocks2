sb2.colors.fun = "#ff80ff"

sb2.registerScriptblock("scriptblocks2:get_call_stack_length", {
	sb2_label = "Get Call Stack Length",
	
	sb2_explanation = {
		shortExplanation = "Reports the current length of the call stack.",
	},
	
	sb2_color = sb2.colors.fun,
	sb2_icon = "sb2_icon_count.png",
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
	sb2_icon = "sb2_icon_list.png",
	sb2_slotted_faces = {},
	
	sb2_action = sb2.simple_action {
		arguments = {},
		action = function (pos, node, process, frame, context)
			return math.max(process.memoryUsage, process.newMemoryUsage)
		end
	}
})

sb2.registerScriptblock("scriptblocks2:get_context_owner", {
	sb2_label = "Get Context Owner",
	
	sb2_explanation = {
		shortExplanation = "Reports the player that owns the current script.",
	},
	
	sb2_color = sb2.colors.fun,
	sb2_icon = "sb2_icon_question.png",
	sb2_slotted_faces = {},
	
	sb2_action = sb2.simple_action {
		arguments = {},
		action = function (pos, node, process, frame, context)
			return context:getOwner()
		end
	}
})

sb2.registerScriptblock("scriptblocks2:get_type", {
	sb2_label = "Get Type",
	
	sb2_explanation = {
		shortExplanation = "Reports whether a given value is a string, number, list, etc.",
		inputSlots = {
			{"Right", "The value to get the type of."}
		},
	},
	
	sb2_color = sb2.colors.fun,
	sb2_icon = "sb2_icon_question.png",
	sb2_slotted_faces = {"right"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right"},
		action = function (pos, node, process, frame, context, value)
			if type(value) ~= "table" then return type(value) end
			if not value.getClass then return "table" end
			
			return value:getClass().name
		end
	}
})

sb2.registerScriptblock("scriptblocks2:get_call_stack_trace", {
	sb2_label = "Get Call Stack Trace",
	
	sb2_explanation = {
		shortExplanation = "Reports a string representation of the call stack.",
	},
	
	sb2_color = sb2.colors.fun,
	sb2_icon = "sb2_icon_join.png",
	sb2_slotted_faces = {},
	
	sb2_action = sb2.simple_action {
		arguments = {},
		action = function (pos, node, process, frame, context)
			return sb2.toString(process:getFrame())
		end
	}
})