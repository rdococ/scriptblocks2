sb2.colors.operators = "#10e81e"
sb2.colors.strings = "#c3e51b"
sb2.colors.booleans = "#04d349"

sb2.registerScriptblock("scriptblocks2:add", {
	sb2_label = "Add",
	
	sb2_explanation = {
		shortExplanation = "Reports the result of adding two numbers.",
		inputSlots = {
			{"Right", "The first number to add."},
			{"Front", "The second number to add."},
		},
	},
	
	sb2_color = sb2.colors.operators,
	sb2_icon = "sb2_icon_add.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right", "front"},
		action = function (pos, node, process, frame, context, a, b)
			return sb2.toNumber(a, 0) + sb2.toNumber(b, 0)
		end
	}
})
sb2.registerScriptblock("scriptblocks2:subtract", {
	sb2_label = "Subtract",
	
	sb2_explanation = {
		shortExplanation = "Reports the result of subtracting one number from another.",
		inputSlots = {
			{"Right", "The number to subtract from."},
			{"Front", "The number to subtract."},
		},
	},
	
	sb2_color = sb2.colors.operators,
	sb2_icon = "sb2_icon_subtract.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right", "front"},
		action = function (pos, node, process, frame, context, a, b)
			return sb2.toNumber(a, 0) - sb2.toNumber(b, 0)
		end
	}
})
sb2.registerScriptblock("scriptblocks2:multiply", {
	sb2_label = "Multiply",
	
	sb2_explanation = {
		shortExplanation = "Reports the result of multiplying two numbers.",
		inputSlots = {
			{"Right", "The first number to multiply."},
			{"Front", "The second number to multiply."},
		},
	},
	
	sb2_color = sb2.colors.operators,
	sb2_icon = "sb2_icon_multiply.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right", "front"},
		action = function (pos, node, process, frame, context, a, b)
			return sb2.toNumber(a, 1) * sb2.toNumber(b, 1)
		end
	}
})
sb2.registerScriptblock("scriptblocks2:divide", {
	sb2_label = "Divide",
	
	sb2_explanation = {
		shortExplanation = "Reports the result of dividing one number by another.",
		inputSlots = {
			{"Right", "The number to divide."},
			{"Front", "The number to divide by."},
		},
	},
	
	sb2_color = sb2.colors.operators,
	sb2_icon = "sb2_icon_divide.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right", "front"},
		action = function (pos, node, process, frame, context, a, b)
			return sb2.toNumber(a, 1) / sb2.toNumber(b, 1)
		end
	}
})
sb2.registerScriptblock("scriptblocks2:modulo", {
	sb2_label = "Modulo",
	
	sb2_explanation = {
		shortExplanation = "Reports the remainder after dividing one number by another.",
		inputSlots = {
			{"Right", "The number to divide."},
			{"Front", "The number to divide by."},
		},
		additionalPoints = {
			"The remainder is always positive regardless of the signs of the two numbers.",
		},
	},
	
	sb2_color = sb2.colors.operators,
	sb2_icon = "sb2_icon_modulo.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right", "front"},
		action = function (pos, node, process, frame, context, a, b)
			return sb2.toNumber(a, 1) % math.abs(sb2.toNumber(b, 1))
		end
	}
})
sb2.registerScriptblock("scriptblocks2:raise_to_power", {
	sb2_label = "Raise to Power",
	
	sb2_explanation = {
		shortExplanation = "Reports the result of raising one number to the power of another.",
		inputSlots = {
			{"Right", "The base."},
			{"Front", "The exponent."},
		},
	},
	
	sb2_color = sb2.colors.operators,
	sb2_icon = "sb2_icon_raise_to_power.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right", "front"},
		action = function (pos, node, process, frame, context, a, b)
			return sb2.toNumber(a, 0) ^ sb2.toNumber(b, 1)
		end
	}
})

sb2.registerScriptblock("scriptblocks2:less_than", {
	sb2_label = "Less Than",
	
	sb2_explanation = {
		shortExplanation = "Reports true if the first number is less than the second number.",
		inputSlots = {
			{"Right", "The first number."},
			{"Front", "The second number."},
		},
	},
	
	sb2_color = sb2.colors.operators,
	sb2_icon = "sb2_icon_less_than.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right", "front"},
		action = function (pos, node, process, frame, context, a, b)
			return sb2.toNumber(a, -math.huge) < sb2.toNumber(b, -math.huge)
		end
	}
})
sb2.registerScriptblock("scriptblocks2:equals", {
	sb2_label = "Equals",
	
	sb2_explanation = {
		shortExplanation = "Reports true if the two values are equal.",
		inputSlots = {
			{"Right", "The first value."},
			{"Front", "The second value."},
		},
	},
	
	sb2_color = sb2.colors.operators,
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
	
	sb2_explanation = {
		shortExplanation = "Reports true if the first number is greater than the second number.",
		inputSlots = {
			{"Right", "The first number."},
			{"Front", "The second number."},
		},
	},
	
	sb2_color = sb2.colors.operators,
	sb2_icon = "sb2_icon_greater_than.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right", "front"},
		action = function (pos, node, process, frame, context, a, b)
			return sb2.toNumber(a, -math.huge) > sb2.toNumber(b, -math.huge)
		end
	}
})

sb2.registerScriptblock("scriptblocks2:join", {
	sb2_label = "Join",
	
	sb2_explanation = {
		shortExplanation = "Joins two pieces of text together.",
		inputSlots = {
			{"Right", "The first string to join."},
			{"Front", "The second string to join."},
		},
	},
	
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
	sb2_label = "Get String Letter",
	
	sb2_explanation = {
		shortExplanation = "Reports the letter at a certain index in a piece of text.",
		inputSlots = {
			{"Right", "The index of the letter to get in the string."},
			{"Front", "The string to get the letter from."},
		},
	},
	
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
	
	sb2_explanation = {
		shortExplanation = "Reports the number of letters in a piece of text.",
		inputSlots = {
			{"Right", "The string to get the length of."},
		},
	},
	
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
	
	sb2_explanation = {
		shortExplanation = "Reports true if the input is false, and false if the input is true.",
		inputSlots = {
			{"Right", "The condition to invert."},
		},
	},
	
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
	
	sb2_explanation = {
		shortExplanation = "Reports a true value only if both inputs are true.",
		inputSlots = {
			{"Right", "The first condition to check."},
			{"Front", "The second condition to check."},
		},
		additionalPoints = {
			"The second condition is not checked if the first condition is false.",
			"If both values are true, the second value is reported.",
		},
	},
	
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
	
	sb2_explanation = {
		shortExplanation = "Reports a true value only if either input is true.",
		inputSlots = {
			{"Right", "The first condition to check."},
			{"Front", "The second condition to check."},
		},
		additionalPoints = {
			"The second condition is not checked if the first condition is true.",
			"If both values are true, the first value is reported.",
		},
	},
	
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