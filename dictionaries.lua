sb2.colors.dictionaries = "#40e5c1"

function sb2.asDictionaryOrNil(v)
	if type(v) ~= "table" then return end
	if v.type ~= "dictionary" then return end
	return v
end
function sb2.createDictionary()
	return {type = "dictionary", entries = {}}
end
function sb2.getDictionaryEntry(dict, index)
	return dict.entries[index]
end
function sb2.setDictionaryEntry(dict, index, value)
	dict.entries[index] = value
end

sb2.registerScriptblock("scriptblocks2:create_empty_dictionary", {
	sb2_label = "Create Empty Dictionary",
	
	sb2_color = sb2.colors.dictionaries,
	sb2_icon = "sb2_icon_dictionary.png",
	
	sb2_action = sb2.simple_action {
		arguments = {},
		action = function (pos, node, process, frame)
			return sb2.createDictionary()
		end
	}
})

sb2.registerScriptblock("scriptblocks2:set_dictionary_entry", {
	sb2_label = "Set Dictionary Entry",
	
	sb2_color = sb2.colors.dictionaries,
	sb2_icon = "sb2_icon_set_list_item.png",
	sb2_slotted_faces = {"right", "left", "front"},
	
	sb2_input_name = "varname",
	sb2_input_label = "Variable",
	sb2_input_default = "",
	
	sb2_action = sb2.simple_action {
		arguments = {"left", "right"},
		continuation = "front",
		action = function (pos, node, process, frame, index, value)
			local varname = minetest.get_meta(pos):get_string("varname")
			local var = sb2.getVar(frame, varname)
			
			local dict = var and sb2.asDictionaryOrNil(var.value)
			if not dict then return end
			
			if index == nil then return end
			
			sb2.setDictionaryEntry(dict, index, value)
		end
	}
})
sb2.registerScriptblock("scriptblocks2:get_dictionary_entry", {
	sb2_label = "Get Dictionary Entry",
	
	sb2_color = sb2.colors.dictionaries,
	sb2_icon = "sb2_icon_index.png",
	sb2_slotted_faces = {"right"},
	
	sb2_input_name = "varname",
	sb2_input_label = "Variable",
	sb2_input_default = "",
	
	sb2_action = sb2.simple_action {
		arguments = {"right"},
		action = function (pos, node, process, frame, index)
			local varname = minetest.get_meta(pos):get_string("varname")
			local var = sb2.getVar(frame, varname)
			
			local dict = var and sb2.asDictionaryOrNil(var.value)
			if not dict then return end
			
			if index == nil then return end
			
			return sb2.getDictionaryEntry(dict, index)
		end
	}
})