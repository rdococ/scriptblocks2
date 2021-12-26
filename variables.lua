sb2.colors.variables = "#f89110"

sb2.registerScriptblock("scriptblocks2:declare_variable", {
	sb2_label = "Declare Variable",
	
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