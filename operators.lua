sb2.colors.numbers = "#10e81e"
sb2.colors.strings = "#c3e51b"
sb2.colors.booleans = "#04d349"

sb2.registerScriptblock("scriptblocks2:add", {
	sb2_label = "Add",
	
	sb2_color = sb2.colors.numbers,
	sb2_icon = "sb2_icon_add.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right", "front"},
		action = function (pos, node, process, frame, context, a, b)
			return sb2.toNumber(a) + sb2.toNumber(b)
		end
	}
})
sb2.registerScriptblock("scriptblocks2:subtract", {
	sb2_label = "Subtract",
	
	sb2_color = sb2.colors.numbers,
	sb2_icon = "sb2_icon_subtract.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right", "front"},
		action = function (pos, node, process, frame, context, a, b)
			return sb2.toNumber(a) - sb2.toNumber(b)
		end
	}
})
sb2.registerScriptblock("scriptblocks2:multiply", {
	sb2_label = "Multiply",
	
	sb2_color = sb2.colors.numbers,
	sb2_icon = "sb2_icon_multiply.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right", "front"},
		action = function (pos, node, process, frame, context, a, b)
			return sb2.toNumber(a) * sb2.toNumber(b)
		end
	}
})
sb2.registerScriptblock("scriptblocks2:divide", {
	sb2_label = "Divide",
	
	sb2_color = sb2.colors.numbers,
	sb2_icon = "sb2_icon_divide.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right", "front"},
		action = function (pos, node, process, frame, context, a, b)
			return sb2.toNumber(a) / sb2.toNumber(b)
		end
	}
})

sb2.registerScriptblock("scriptblocks2:less_than", {
	sb2_label = "Less Than",
	
	sb2_color = sb2.colors.numbers,
	sb2_icon = "sb2_icon_less_than.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right", "front"},
		action = function (pos, node, process, frame, context, a, b)
			return sb2.toNumber(a) < sb2.toNumber(b)
		end
	}
})
sb2.registerScriptblock("scriptblocks2:equals", {
	sb2_label = "Equals",
	
	sb2_color = sb2.colors.numbers,
	sb2_icon = "sb2_icon_equals.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right", "front"},
		action = function (pos, node, process, frame, context, a, b)
			return a == b
		end
	}
})
sb2.registerScriptblock("scriptblocks2:greater_than", {
	sb2_label = "Greater Than",
	
	sb2_color = sb2.colors.numbers,
	sb2_icon = "sb2_icon_greater_than.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right", "front"},
		action = function (pos, node, process, frame, context, a, b)
			return sb2.toNumber(a) > sb2.toNumber(b)
		end
	}
})

sb2.registerScriptblock("scriptblocks2:join", {
	sb2_label = "Join",
	
	sb2_color = sb2.colors.strings,
	sb2_icon = "sb2_icon_join.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right", "front"},
		action = function (pos, node, process, frame, context, a, b)
			return sb2.toString(a) .. sb2.toString(b)
		end
	}
})
sb2.registerScriptblock("scriptblocks2:get_letter", {
	sb2_label = "Get Letter",
	
	sb2_color = sb2.colors.strings,
	sb2_icon = "sb2_icon_index.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right", "front"},
		action = function (pos, node, process, frame, context, ind, str)
			str = sb2.toString(str)
			ind = sb2.toNumber(ind)
			if ind < 1 or ind > str:len() then
				return ""
			end
			
			return str:sub(ind, ind)
		end
	}
})
sb2.registerScriptblock("scriptblocks2:get_string_length", {
	sb2_label = "Get String Length",
	
	sb2_color = sb2.colors.strings,
	sb2_icon = "sb2_icon_count.png",
	sb2_slotted_faces = {"right"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right"},
		action = function (pos, node, process, frame, context, str)
			return sb2.toString(str):len()
		end
	}
})

sb2.registerScriptblock("scriptblocks2:not", {
	sb2_label = "Not",
	
	sb2_color = sb2.colors.booleans,
	sb2_icon = "sb2_icon_not.png",
	sb2_slotted_faces = {"right"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right"},
		action = function (pos, node, process, frame, context, a)
			return not a
		end
	}
})
sb2.registerScriptblock("scriptblocks2:and", {
	sb2_label = "And",
	
	sb2_color = sb2.colors.booleans,
	sb2_icon = "sb2_icon_and.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated(1) then
			frame:selectArg(1)
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		if not frame:isArgEvaluated(2) then
			if not frame:getArg(1) then return process:report(frame:getArg(1)) end
			
			frame:selectArg(2)
			return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context))
		end
		
		return process:report(frame:getArg(2))
	end,
})
sb2.registerScriptblock("scriptblocks2:or", {
	sb2_label = "Or",
	
	sb2_color = sb2.colors.booleans,
	sb2_icon = "sb2_icon_or.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated(1) then
			frame:selectArg(1)
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		if not frame:isArgEvaluated(2) then
			if frame:getArg(1) then return process:report(frame:getArg(1)) end
			
			frame:selectArg(2)
			return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context))
		end
		
		return process:report(frame:getArg(2))
	end,
})