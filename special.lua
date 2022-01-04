sb2.colors.constants = "#ffffff"
sb2.colors.special   = "#888888"

sb2.registerScriptblock("scriptblocks2:string_constant", {
	sb2_label = "String Constant",
	
	sb2_explanation = {
		shortExplanation = "Reports a string, which is a piece of text.",
		inputValues = {
			{"Value", "The text to report."}
		}
	},
	
	sb2_color = sb2.colors.constants,
	sb2_icon = "sb2_icon_string_constant.png",
	
	sb2_input_name = "value",
	sb2_input_label = "Value",
	sb2_input_default = "",
	
	sb2_action = sb2.simple_action {
		action = function (pos, node, process, frame, context)
			return minetest.get_meta(pos):get_string("value")
		end
	}
})

sb2.registerScriptblock("scriptblocks2:number_constant", {
	sb2_label = "Number Constant",
	
	sb2_explanation = {
		shortExplanation = "Reports a number.",
		inputValues = {
			{"Value", "The number to report."}
		}
	},
	
	sb2_color = sb2.colors.constants,
	sb2_icon = "sb2_icon_number_constant.png",
	
	sb2_input_name = "value",
	sb2_input_label = "Value",
	sb2_input_default = "",
	
	sb2_action = sb2.simple_action {
		action = function (pos, node, process, frame, context)
			return sb2.toNumber(minetest.get_meta(pos):get_string("value"))
		end
	}
})

sb2.registerScriptblock("scriptblocks2:identity", {
	sb2_label = "Identity",
	
	sb2_explanation = {
		shortExplanation = "Runs the next scriptblock.",
		inputSlots = {
			{"Right", "The scriptblock to run."}
		},
		additionalPoints = {
			"This can be used to merge different paths or form loops!",
		}
	},
	
	sb2_color = sb2.colors.special,
	sb2_icon = "sb2_icon_identity.png",
	sb2_slotted_faces = {"right"},
	
	sb2_action = sb2.simple_action {
		continuation = "right",
		action = function (pos, node, process, frame, context) end
	}
})