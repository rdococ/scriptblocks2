sb2.colors.dictionaries = "#40e5c1"

sb2.Dictionary = sb2.registerClass("dictionary")

function sb2.Dictionary:initialize()
	self.entries = {}
end
function sb2.Dictionary:getEntry(index)
	return self.entries[index]
end
function sb2.Dictionary:setEntry(index, value)
	self.entries[index] = value
end
function sb2.Dictionary:recordString(record)
	record[self] = true
	
	local elements = {}
	
	for k, v in pairs(self.entries) do
		table.insert(elements, string.format("%s: %s", sb2.prettyPrint(k, record), sb2.prettyPrint(v, record)))
	end
	
	return string.format("{%s}", table.concat(elements, ", "))
end
function sb2.Dictionary:recordLuaValue(record)
	local tbl = {}
	record[self] = tbl
	
	for k, v in pairs(self.entries) do
		tbl[sb2.toLuaValue(k, record)] = sb2.toLuaValue(v, record)
	end
	
	return tbl
end

sb2.registerScriptblock("scriptblocks2:create_empty_dictionary", {
	sb2_label = "Create Empty Dictionary",
	
	sb2_explanation = {
		shortExplanation = "Creates and reports an empty dictionary.",
		additionalPoints = {
			"A dictionary is like a list, but the indexes can be anything.",
		},
	},
	
	sb2_color = sb2.colors.dictionaries,
	sb2_icon = "sb2_icon_dictionary.png",
	
	sb2_action = sb2.simple_action {
		arguments = {},
		action = function (pos, node, process, frame, context)
			return sb2.Dictionary:new()
		end
	}
})

sb2.registerScriptblock("scriptblocks2:set_dictionary_entry", {
	sb2_label = "Set Dictionary Entry",
	
	sb2_explanation = {
		shortExplanation = "Sets an entry in a dictionary to a new value.",
		inputValues = {
			{"Variable", "The dictionary to set the entry in."},
		},
		inputSlots = {
			{"Left", "The key to store the entry in."},
			{"Right", "The new value of the entry."},
			{"Front", "What to do next."},
		},
	},
	
	sb2_color = sb2.colors.dictionaries,
	sb2_icon = "sb2_icon_set_list_item.png",
	sb2_slotted_faces = {"right", "left", "front"},
	
	sb2_input_name = "varname",
	sb2_input_label = "Variable",
	sb2_input_default = "",
	
	sb2_action = sb2.simple_action {
		arguments = {"left", "right"},
		continuation = "front",
		action = function (pos, node, process, frame, context, index, value)
			local varname = minetest.get_meta(pos):get_string("varname")
			local var = context:getVar(varname)
			
			local dict = var and var.value
			
			if not dict then return end
			if not dict.setEntry then return end
			
			if index == nil then return end
			
			dict:setEntry(index, value)
		end
	}
})
sb2.registerScriptblock("scriptblocks2:get_dictionary_entry", {
	sb2_label = "Get Dictionary Entry",
	
	sb2_explanation = {
		shortExplanation = "Reports the value of an entry in the dictionary.",
		inputValues = {
			{"Variable", "The dictionary to get the entry from."},
		},
		inputSlots = {
			{"Right", "The key of the entry you want to retrieve."},
		},
	},
	
	sb2_color = sb2.colors.dictionaries,
	sb2_icon = "sb2_icon_index.png",
	sb2_slotted_faces = {"right"},
	
	sb2_input_name = "varname",
	sb2_input_label = "Variable",
	sb2_input_default = "",
	
	sb2_action = sb2.simple_action {
		arguments = {"right"},
		action = function (pos, node, process, frame, context, index)
			local varname = minetest.get_meta(pos):get_string("varname")
			local var = context:getVar(varname)
			
			local dict = var and var.value
			
			if not dict then return end
			if not dict.getEntry then return end
			
			if index == nil then return end
			
			return dict:getEntry(index)
		end
	}
})