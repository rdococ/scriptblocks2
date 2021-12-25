sb2.colors.lists = "#ce421e"

function sb2.asListOrNil(v)
	if type(v) ~= "table" then return end
	if v.type ~= "list" then return end
	return v
end
function sb2.createList()
	return {type = "list", items = {}}
end
function sb2.getListLength(list)
	return #list.items
end
function sb2.getListItem(list, index)
	return list.items[index]
end
function sb2.setListItem(list, index, value)
	list.items[index] = value
end
function sb2.insertListItem(list, index, value)
	table.insert(list.items, index, value)
end
function sb2.removeListItem(list, index)
	table.remove(list.items, index)
end
function sb2.appendListItem(list, value)
	table.insert(list.items, value)
end
function sb2.asListIndexOrNil(list, index)
	if index < 1 then return end
	if index > sb2.getListLength(list) then return end
	return math.ceil(index - 0.5)
end

sb2.registerScriptblock("scriptblocks2:create_empty_list", {
	sb2_label = "Create Empty List",
	
	sb2_color = sb2.colors.lists,
	sb2_icon = "sb2_icon_list.png",
	
	sb2_action = sb2.simple_action {
		arguments = {},
		action = function (pos, node, process, frame)
			return sb2.createList()
		end
	}
})

sb2.registerScriptblock("scriptblocks2:append_to_list", {
	sb2_label = "Append To List",
	
	sb2_color = sb2.colors.lists,
	sb2_icon = "sb2_icon_add.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_input_name = "varname",
	sb2_input_label = "Variable",
	sb2_input_default = "",
	
	sb2_action = sb2.simple_action {
		arguments = {"right"},
		continuation = "front",
		action = function (pos, node, process, frame, item)
			local varname = minetest.get_meta(pos):get_string("varname")
			local var = sb2.getVar(frame, varname)
			
			local list = var and sb2.asListOrNil(var.value)
			if not list then return end
			
			sb2.appendListItem(list, item)
		end
	}
})
sb2.registerScriptblock("scriptblocks2:remove_from_list", {
	sb2_label = "Remove From List",
	
	sb2_color = sb2.colors.lists,
	sb2_icon = "sb2_icon_subtract.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_input_name = "varname",
	sb2_input_label = "Variable",
	sb2_input_default = "",
	
	sb2_action = sb2.simple_action {
		arguments = {"right"},
		continuation = "front",
		action = function (pos, node, process, frame, index)
			local varname = minetest.get_meta(pos):get_string("varname")
			local var = sb2.getVar(frame, varname)
			
			local list = var and sb2.asListOrNil(var.value)
			if not list then return end
			
			local index = sb2.asListIndexOrNil(list, sb2.toNumber(index))
			if not index then return end
			
			sb2.removeListItem(list, index)
		end
	}
})
sb2.registerScriptblock("scriptblocks2:insert_into_list", {
	sb2_label = "Insert Into List",
	
	sb2_color = sb2.colors.lists,
	sb2_icon = "sb2_icon_insert_into_list.png",
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
			
			local list = var and sb2.asListOrNil(var.value)
			if not list then return end
			
			local index = sb2.asListIndexOrNil(list, sb2.toNumber(index))
			if not index then return end
			
			sb2.insertListItem(list, index, value)
		end
	}
})

sb2.registerScriptblock("scriptblocks2:set_list_item", {
	sb2_label = "Set List Item",
	
	sb2_color = sb2.colors.lists,
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
			
			local list = var and sb2.asListOrNil(var.value)
			if not list then return end
			
			local index = sb2.asListIndexOrNil(list, sb2.toNumber(index))
			if not index then return end
			
			sb2.setListItem(list, index, value)
		end
	}
})
sb2.registerScriptblock("scriptblocks2:get_list_item", {
	sb2_label = "Get List Item",
	
	sb2_color = sb2.colors.lists,
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
			
			local list = var and sb2.asListOrNil(var.value)
			if not list then return end
			
			local index = sb2.asListIndexOrNil(list, sb2.toNumber(index))
			if not index then return end
			
			return sb2.getListItem(list, index)
		end
	}
})

sb2.registerScriptblock("scriptblocks2:get_list_length", {
	sb2_label = "Get List Length",
	
	sb2_color = sb2.colors.lists,
	sb2_icon = "sb2_icon_get_list_length.png",
	
	sb2_input_name = "varname",
	sb2_input_label = "Variable",
	sb2_input_default = "",
	
	sb2_action = sb2.simple_action {
		action = function (pos, node, process, frame)
			local varname = minetest.get_meta(pos):get_string("varname")
			local var = sb2.getVar(frame, varname)
			
			local list = var and sb2.asListOrNil(var.value)
			if not list then return end
			
			return sb2.getListLength(list)
		end
	}
})