sb2.colors.numbers = "#10e81e"
sb2.colors.strings = "#c3e51b"
sb2.colors.booleans = "#3fba3d"

sb2.registerScriptblock("scriptblocks2:add", {
	sb2_label = "Add",
	
	sb2_color = sb2.colors.numbers,
	sb2_icon = "sb2_icon_add.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right", "front"},
		action = function (pos, node, process, frame, a, b)
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
		action = function (pos, node, process, frame, a, b)
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
		action = function (pos, node, process, frame, a, b)
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
		action = function (pos, node, process, frame, a, b)
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
		action = function (pos, node, process, frame, a, b)
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
		action = function (pos, node, process, frame, a, b)
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
		action = function (pos, node, process, frame, a, b)
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
		action = function (pos, node, process, frame, a, b)
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
		action = function (pos, node, process, frame, ind, str)
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
	sb2_icon = "sb2_icon_get_list_length.png",
	sb2_slotted_faces = {"right"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right"},
		action = function (pos, node, process, frame, str)
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
		action = function (pos, node, process, frame, a)
			return not a
		end
	}
})
sb2.registerScriptblock("scriptblocks2:and", {
	sb2_label = "And",
	
	sb2_color = sb2.colors.booleans,
	sb2_icon = "sb2_icon_and.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right", "front"},
		action = function (pos, node, process, frame, a, b)
			return a and b
		end
	}
})
sb2.registerScriptblock("scriptblocks2:or", {
	sb2_label = "Or",
	
	sb2_color = sb2.colors.booleans,
	sb2_icon = "sb2_icon_or.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right", "front"},
		action = function (pos, node, process, frame, a, b)
			return a or b
		end
	}
})