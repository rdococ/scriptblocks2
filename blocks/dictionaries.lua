sb2.colors.dictionaries = "#40e5c1"

--[[
Dictionary

A dictionary is much like a Lua table - it maps non-nil values to other non-nil values.

Methods:
	getSize()
		Returns the number of entries in the dictionary.
	
	getItem(key)
		Gets the entry with the specified key.
	setItem(key, value)
		Sets the entry with the specified key to the specified value.
		If the entry didn't exist, it is created. If the value is nil, the entry is removed.

If you are looking to extend scriptblocks2, you can register classes with definitions for these methods. The corresponding scriptblocks check for the presence of these methods and will call them if it can find them.
]]

sb2.Dictionary = sb2.registerClass("dictionary")

function sb2.Dictionary:initialize()
	self.entries = {}
	self.size = 0
end

function sb2.Dictionary:isSerializable() return true end

function sb2.Dictionary:getItem(key)
	return self.entries[key]
end
function sb2.Dictionary:setItem(key, value)
	if key == nil then return end
	
	if self.entries[key] ~= nil then self.size = self.size - 1 end
	if value ~= nil then self.size = self.size + 1 end
	
	self.entries[key] = value
end
function sb2.Dictionary:getSize()
	return self.size
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
			
			if type(dict) ~= "table" then return end
			if not dict.setItem then return end
			
			dict:setItem(index, value)
		end
	}
})
sb2.registerScriptblock("scriptblocks2:get_dictionary_entry", {
	sb2_label = "Get Dictionary Entry",
	
	sb2_explanation = {
		shortExplanation = "Reports the value of an entry in a dictionary.",
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
			
			if type(dict) ~= "table" then return end
			if not dict.getItem then return end
			
			return dict:getItem(index)
		end
	}
})
sb2.registerScriptblock("scriptblocks2:get_dictionary_size", {
	sb2_label = "Get Dictionary Size",
	
	sb2_explanation = {
		shortExplanation = "Reports the number of entries in a dictionary.",
		inputValues = {
			{"Variable", "The dictionary to get the size of."},
		},
	},
	
	sb2_color = sb2.colors.dictionaries,
	sb2_icon = "sb2_icon_count.png",
	sb2_slotted_faces = {},
	
	sb2_input_name = "varname",
	sb2_input_label = "Variable",
	sb2_input_default = "",
	
	sb2_action = sb2.simple_action {
		arguments = {},
		action = function (pos, node, process, frame, context)
			local varname = minetest.get_meta(pos):get_string("varname")
			local var = context:getVar(varname)
			
			local dict = var and var.value
			
			if type(dict) ~= "table" then return end
			if not dict.getSize then return end
			
			return dict:getSize()
		end
	}
})