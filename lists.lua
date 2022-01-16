sb2.colors.lists = "#ce421e"

--[[
List

A list is a contiguous list of non-nil values.

Methods:
	getSize()
		Returns the number of items in the list.
	
	getItem(index)
		Returns the item at this index in the list.
	setItem(index, value)
		Sets an item at this index in the list to a new value.
		This value should never be nil. When the 'set item' scriptblock receives a nil value, it calls removeItem instead.
	insertItem(index, value)
		Inserts an item at this index in the list.
		The value should never be nil. 'insert item' will do nothing if it receives a nil value.
	removeItem(index)
		Removes an item at this index in the list.
	appendItem(value)
		Appends an item to the list.
		The value should not be nil.
	
	asListIndex(index, extendedRange)
		Converts the value to a valid list index, or nil if there is no sensible way to do so. You don't need to call this, the other methods do so automatically.

If you are looking to extend scriptblocks2, you can register classes with definitions for these methods. The corresponding scriptblocks check for the presence of these methods and will call them if it can find them.
]]

sb2.List = sb2.registerClass("list")

function sb2.List:initialize()
	self.items = {}
end

function sb2.List:getSize()
	return #self.items
end
function sb2.List:getItem(index)
	index = self:asListIndex(index, false)
	if not index then return end
	
	return self.items[index]
end
function sb2.List:setItem(index, value)
	if value == nil then return self:removeItem(index) end
	
	index = self:asListIndex(index, false)
	if not index then return end
	
	self.items[index] = value
end
function sb2.List:insertItem(index, value)
	if value == nil then return end
	
	index = self:asListIndex(index, true)
	if not index then return end
	
	table.insert(self.items, index, value)
end
function sb2.List:removeItem(index)
	index = self:asListIndex(index, false)
	if not index then return end
	
	table.remove(self.items, index)
end
function sb2.List:appendItem(value)
	if value == nil then return end
	
	table.insert(self.items, value)
end
function sb2.List:asListIndex(index, extendedRange)
	index = sb2.toNumber(index)
	if index < 0.5 then return end
	if index >= #self.items + (extendedRange and 1.5 or 0.5) then return end
	return math.floor(index + 0.5)
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
	
	sb2_explanation = {
		shortExplanation = "Creates and reports an empty list.",
		additionalPoints = {
			"A list is a value that holds an ordered sequence of other values.",
		},
	},
	
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
	
	sb2_explanation = {
		shortExplanation = "Appends an item to the end of a list.",
		inputValues = {
			{"Variable", "The list to append the item to."},
		},
		inputSlots = {
			{"Right", "The value of the item to append."},
			{"Front", "What to do next."},
		},
		additionalPoints = {
			"Nil values cannot be appended.",
		},
	},
	
	sb2_color = sb2.colors.lists,
	sb2_icon = "sb2_icon_add.png",
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
			
			local list = var and var.value
			
			if type(list) ~= "table" then return end
			if not list.appendItem then return end
			
			list:appendItem(value)
		end
	}
})
sb2.registerScriptblock("scriptblocks2:remove_from_list", {
	sb2_label = "Remove From List",
	
	sb2_explanation = {
		shortExplanation = "Removes an item from a list.",
		inputValues = {
			{"Variable", "The list to remove the item from."},
		},
		inputSlots = {
			{"Right", "The index of the item to remove."},
			{"Front", "What to do next."},
		},
	},
	
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
			
			list:removeItem(index)
		end
	}
})
sb2.registerScriptblock("scriptblocks2:insert_into_list", {
	sb2_label = "Insert Into List",
	
	sb2_explanation = {
		shortExplanation = "Insert an item into the middle of a list.",
		inputValues = {
			{"Variable", "The list to insert the item into."},
		},
		inputSlots = {
			{"Left", "The index to insert the item into."},
			{"Right", "The value of the item to insert."},
			{"Front", "What to do next."},
		},
		additionalPoints = {
			"Nil values cannot be inserted.",
		},
	},
	
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
			
			list:insertItem(index, value)
		end
	}
})

sb2.registerScriptblock("scriptblocks2:set_list_item", {
	sb2_label = "Set List Item",
	
	sb2_explanation = {
		shortExplanation = "Sets the value of a list item to a new value.",
		inputValues = {
			{"Variable", "The list to set a list item in."},
		},
		inputSlots = {
			{"Left", "The index of the list item to set."},
			{"Right", "The new value of the item."},
			{"Front", "What to do next."},
		},
		additionalPoints = {
			"Setting an item to nil removes it from the list.",
		},
	},
	
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
			if not list.setItem then return end
			
			list:setItem(index, value)
		end
	}
})
sb2.registerScriptblock("scriptblocks2:get_list_item", {
	sb2_label = "Get List Item",
	
	sb2_explanation = {
		shortExplanation = "Reports the value of a list item.",
		inputValues = {
			{"Variable", "The list of the item to report."},
		},
		inputSlots = {
			{"Right", "The index of the item to report in the list."},
		},
	},
	
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
			
			return list:getItem(index)
		end
	}
})

sb2.registerScriptblock("scriptblocks2:get_list_length", {
	sb2_label = "Get List Length",
	
	sb2_explanation = {
		shortExplanation = "Reports the number of items in a list.",
		inputValues = {
			{"Variable", "The list to report the length of."},
		},
	},
	
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
			if not list.getSize then return end
			
			return list:getSize()
		end
	}
})