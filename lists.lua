sb2.colors.lists = "#ce421e"

sb2.List = sb2.registerClass("list")

function sb2.List:initialize()
	self.items = {}
end
function sb2.List:getLength()
	return #self.items
end
function sb2.List:getItem(index)
	return self.items[index]
end
function sb2.List:setItem(index, value)
	self.items[index] = value
end
function sb2.List:insertItem(index, value)
	table.insert(self.items, index, value)
end
function sb2.List:removeItem(index)
	table.remove(self.items, index)
end
function sb2.List:appendItem(value)
	table.insert(self.items, value)
end
function sb2.List:asListIndex(index, extendedRange)
	index = sb2.toNumber(index)
	if index < 0.5 then return end
	if index >= self:getLength() + (extendedRange and 1.5 or 0.5) then return end
	return math.ceil(index - 0.5)
end
function sb2.List:recordString(record)
	record[self] = true
	
	local elements = {}
	
	for k, v in ipairs(self.items) do
		elements[k] = sb2.prettyPrint(v, record)
	end
	
	return string.format("[%s]", table.concat(elements, ", "))
end
function sb2.List:recordLuaValue(record)
	local tbl = {}
	record[self] = tbl
	
	for k, v in ipairs(self.items) do
		tbl[k] = sb2.toLuaValue(v, record)
	end
	
	return tbl
end

sb2.registerScriptblock("scriptblocks2:create_empty_list", {
	sb2_label = "Create Empty List",
	
	sb2_color = sb2.colors.lists,
	sb2_icon = "sb2_icon_list.png",
	
	sb2_action = sb2.simple_action {
		arguments = {},
		action = function (pos, node, process, frame, context)
			return sb2.List:new()
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
		action = function (pos, node, process, frame, context, item)
			local varname = minetest.get_meta(pos):get_string("varname")
			local var = context:getVar(varname)
			
			local list = var and var.value
			
			if type(list) ~= "table" then return end
			if not list.appendItem then return end
			
			list:appendItem(item)
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
		action = function (pos, node, process, frame, context, index)
			local varname = minetest.get_meta(pos):get_string("varname")
			local var = context:getVar(varname)
			
			local list = var and var.value
			
			if type(list) ~= "table" then return end
			if not list.removeItem then return end
			if not list.asListIndex then return end
			
			local index = list:asListIndex(index)
			if not index then return end
			
			list:removeItem(index)
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
		action = function (pos, node, process, frame, context, index, value)
			local varname = minetest.get_meta(pos):get_string("varname")
			local var = context:getVar(varname)
			
			local list = var and var.value
			
			if type(list) ~= "table" then return end
			if not list.insertItem then return end
			if not list.asListIndex then return end
			
			local index = list:asListIndex(index, true)
			if not index then return end
			
			list:insertItem(index, value)
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
		action = function (pos, node, process, frame, context, index, value)
			local varname = minetest.get_meta(pos):get_string("varname")
			local var = context:getVar(varname)
			
			local list = var and var.value
			
			if type(list) ~= "table" then return end
			if not list.insertItem then return end
			if not list.asListIndex then return end
			
			local index = list:asListIndex(index)
			if not index then return end
			
			list:setItem(index, value)
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
		action = function (pos, node, process, frame, context, index)
			local varname = minetest.get_meta(pos):get_string("varname")
			local var = context:getVar(varname)
			
			local list = var and var.value
			
			if type(list) ~= "table" then return end
			if not list.getItem then return end
			if not list.asListIndex then return end
			
			local index = list:asListIndex(index)
			if not index then return end
			
			return list:getItem(index)
		end
	}
})

sb2.registerScriptblock("scriptblocks2:get_list_length", {
	sb2_label = "Get List Length",
	
	sb2_color = sb2.colors.lists,
	sb2_icon = "sb2_icon_count.png",
	
	sb2_input_name = "varname",
	sb2_input_label = "Variable",
	sb2_input_default = "",
	
	sb2_action = sb2.simple_action {
		action = function (pos, node, process, frame, context)
			local varname = minetest.get_meta(pos):get_string("varname")
			local var = context:getVar(varname)
			
			local list = var and var.value
			
			if type(list) ~= "table" then return end
			if not list.getLength then return end
			
			return list:getLength()
		end
	}
})