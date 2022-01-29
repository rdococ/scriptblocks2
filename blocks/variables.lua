sb2.colors.variables = "#f89110"

function sb2.Context:declareVar(varname, value)
	self.attributes["variables:" .. varname] = {value = value}
end
function sb2.Context:getVar(varname)
	return self.attributes["variables:" .. varname]
end

sb2.registerScriptblock("scriptblocks2:declare_variable", {
	sb2_label = "Declare Variable",
	
	sb2_explanation = {
		shortExplanation = "Creates a new variable, holding a temporary value you can use in the next part of the script.",
		inputValues = {
			{"Variable", "The name of the new variable."},
		},
		inputSlots = {
			{"Right", "The initial value of the variable."},
			{"Front", "What to do next."},
		},
	},
	
	sb2_color = sb2.colors.variables,
	sb2_icon = "sb2_icon_declare_var.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_input_name = "varname",
	sb2_input_label = "Variable",
	sb2_input_default = "",
	
	sb2_action = sb2.simple_action {
		arguments = {"right"},
		continuation = "front",
		
		action = function (pos, node, process, frame, context, value)
			local varname = minetest.get_meta(pos):get_string("varname")
			context:declareVar(varname, value)
		end
	}
})

sb2.registerScriptblock("scriptblocks2:set_variable", {
	sb2_label = "Set Variable",
	
	sb2_explanation = {
		shortExplanation = "Sets the value of an existing variable.",
		inputValues = {
			{"Variable", "The name of the variable to set."},
		},
		inputSlots = {
			{"Right", "The new value of the variable."},
			{"Front", "What to do next."},
		},
		additionalPoints = {
			"Make sure the variable has been declared first!",
		},
	},
	
	sb2_color = sb2.colors.variables,
	sb2_icon = "sb2_icon_set_var.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_input_name = "varname",
	sb2_input_label = "Variable",
	sb2_input_default = "",
	
	sb2_action = sb2.simple_action {
		arguments = {"right"},
		continuation = "front",
		
		action = function (pos, node, process, frame, context, value)
			local varname = minetest.get_meta(pos):get_string("varname")
			local var = context:getVar(varname)
			if var then
				var.value = value
			end
		end
	}
})

sb2.registerScriptblock("scriptblocks2:get_variable", {
	sb2_label = "Get Variable",
	
	sb2_explanation = {
		shortExplanation = "Reports the value of an existing variable.",
		inputValues = {
			{"Variable", "The name of the variable to get."},
		},
		additionalPoints = {
			"Make sure the variable has been declared first!",
		},
	},
	
	sb2_color = sb2.colors.variables,
	sb2_icon = "sb2_icon_ellipsis.png",
	
	sb2_input_name = "varname",
	sb2_input_label = "Variable",
	sb2_input_default = "",
	
	sb2_action = sb2.simple_action {
		arguments = {},
		action = function (pos, node, process, frame, context)
			local varname = minetest.get_meta(pos):get_string("varname")
			local var = context:getVar(varname)
			return var and var.value or nil
		end
	}
})