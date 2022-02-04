sb2.colors.processes = "#fced8a"

sb2.registerScriptblock("scriptblocks2:create_new_process", {
	sb2_label = "Create New Process",
	
	sb2_explanation = {
		shortExplanation = "Creates and reports a new process.",
		inputSlots = {
			{"Right", "What to do in the new process."},
		},
		additionalPoints = {
			"The new process runs alongside this one.",
		},
	},
	
	sb2_color = sb2.colors.processes,
	sb2_icon  = "sb2_icon_flag.png",
	sb2_slotted_faces = {"right"},
	
	sb2_action = sb2.simple_action {
		action = function (pos, node, process, frame, context)
			local dirs = sb2.facedirToDirs(node.param2)
			return sb2.Process:new(sb2.Frame:new(vector.add(pos, dirs.right), frame:getContext()), process:getHead(), process:getStarter(), process:isDebugging())
		end
	},
})

sb2.registerScriptblock("scriptblocks2:wait_for_process", {
	sb2_label = "Wait For Process",
	
	sb2_explanation = {
		shortExplanation = "Waits for a process to finish.",
		inputSlots = {
			{"Right", "The process to wait for."},
			{"Front", "What to do after waiting."},
		},
	},
	
	sb2_color = sb2.colors.processes,
	sb2_icon  = "sb2_icon_wait.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		local t = minetest.get_server_uptime()
		
		if not frame:isArgEvaluated("process") then
			frame:selectArg("process")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		
		local processToCheck = frame:getArg("process")
		if type(processToCheck) ~= "table" or not processToCheck.isHalted then
			process:pop()
			return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context))
		end
		
		if processToCheck:isHalted() then
			process:pop()
			return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context))
		else
			return process:yield()
		end
	end
})

sb2.registerScriptblock("scriptblocks2:get_process_state", {
	sb2_label = "Get Process State",
	
	sb2_explanation = {
		shortExplanation = "Reports 'running' or 'finished' depending on the state of the given process.",
		inputSlots = {
			{"Right", "The process to check."},
		},
	},
	
	sb2_color = sb2.colors.processes,
	sb2_icon  = "sb2_icon_is_process_running.png",
	sb2_slotted_faces = {"right"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right"},
		action = function (pos, node, process, frame, context, processToCheck)
			if type(processToCheck) ~= "table" or not processToCheck.getState then return end
			return processToCheck:getState()
		end
	},
})

sb2.registerScriptblock("scriptblocks2:get_process_value", {
	sb2_label = "Get Process Value",
	
	sb2_explanation = {
		shortExplanation = "Reports the value reported by a process.",
		inputSlots = {
			{"Right", "The process to get the reported value of."},
		},
	},
	
	sb2_color = sb2.colors.processes,
	sb2_icon  = "sb2_icon_receive.png",
	sb2_slotted_faces = {"right"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right"},
		action = function (pos, node, process, frame, context, processToCheck)
			if type(processToCheck) ~= "table" or not processToCheck.getReportedValue then return end
			return processToCheck:getReportedValue()
		end
	},
})