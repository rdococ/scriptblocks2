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

sb2.registerScriptblock("scriptblocks2:is_process_running", {
	sb2_label = "Is Process Running",
	
	sb2_explanation = {
		shortExplanation = "Reports true if a process is running.",
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
			if type(processToCheck) ~= "table" or not processToCheck.isHalted then return end
			return not processToCheck:isHalted()
		end
	},
})

sb2.registerScriptblock("scriptblocks2:stop_process", {
	sb2_label = "Stop Process",
	
	sb2_explanation = {
		shortExplanation = "Stops a running process.",
		inputSlots = {
			{"Right", "The process to stop."},
			{"Front", "What to do next."},
		},
	},
	
	sb2_color = sb2.colors.processes,
	sb2_icon  = "sb2_icon_stop.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right"},
		continuation = "front",
		action = function (pos, node, process, frame, context, processToStop)
			if type(processToStop) ~= "table" or not processToStop.halt then return end
			processToStop:halt("StoppedByOtherProcess")
		end
	},
})