--[[
Base

This is the base of scriptblocks2. It defines various helper functions for creating vanilla-looking and vanilla-acting scriptblocks, and provides conversion functions between Lua and SB2 values (e.g. lists and dictionaries).

Fields:
	colors
		A table of colors for each category of scriptblock.

Functions:
	makeTiles(color, icon, slots)
		Takes a color, an icon, and an optional list of faces ("top", "right", "front", etc.). It produces a set of tiles with the icon slapped on top of the base texture, and slot images overlayed on the selected faces.
	registerScriptblock(name, def)
		Registers a 'vanilla' scriptblock node.
		Any node can be modified to act like a scriptblock, but this is the best way to do it. It ensures that all scriptblocks look and act alike.
		
		registerScriptblock only:
			sb2_label
				A human-readable name for the scriptblock. Suffixed with "Scriptblock" to create the item description.
			sb2_explanation
				A table representing an explanation of what the scriptblock does. The explanation is formatted, and used to generate tooltips if the Extended Tooltips mod is installed.
				{
					shortExplanation = ...,
					inputValues = {
						{value, explanation}, ...
					}
					inputSlots = {
						{slottedFace, explanation}, ...
					},
					additionalPoints = ...
				}
			
			sb2_color
				The color of the scriptblock.
			sb2_icon
				The icon to be displayed on the top face of the scriptblock.
			sb2_slotted_faces
				A list of faces to be overlayed with slots.
			
			sb2_input_name, sb2_input_label, sb2_input_default
				The name of the metadata field used to store the input; the human-readable label for the input; and the input's default value. Automatically creates a formspec allowing users to enter a value for the input, and displays the input value in infotext.
				Scriptblocks with multiple input values or complex validation can still do it manually.
			
			sb2_deprecated
				If true, this block will be given a red outline and hidden from the creative inventory. Continuations are slated for removal, so they have sb2_deprecated set to true.
			sb2_add_groups
				If true, groups such as oddly_breakable_by_hand (and not_in_creative_inventory for deprecated blocks) will be added even if a custom group table has been provided.
		
		Can be used by any registered node:
			sb2_action(pos, node, process, frame, context)
				The function called when this node is evaluated.
		
	toString(value, (record))/toNumber(value, (default))
		Functions to convert values to strings or numbers. Guaranteed never to return nil. Use these instead of tostring and tonumber to follow the typing conventions of the language.
		'record' is a table of converted values used to prevent recursion.
		'default' is what value to use if none is provided.
	toSB2Value(value, (record))/toLuaValue(value, (record))
		Functions to convert values from SB2 values to Lua values and vice versa. toSB2Value creates dictionaries and thus depends on dictionaries.lua - digilines.lua needs to convert Lua values to SB2 values, and so also depends on dictionaries.lua. It may be a good idea to move it to a separate file.
	prettyPrint(value, (record))
		Equivalent to toString, but wraps actual strings in quotation marks.
	
	simple_action(def)
		Returns a simple sb2_action function that behaves according to specific norms. All simple actions evaluate their arguments before calculating the final result, and either discarding it to evaluate a continuation (a la command blocks) or reporting it (a la reporters).
		
		arguments
			A list of faces that represent the arguments to be evaluated. The order of faces determines the order the arguments are evaluated, and the order they are given in the action function.
		continuation
			An optional face, and a sort of pseudo-argument. If absent, the scriptblock acts like a reporter - it will report the value of action(...) to the previous frame. Otherwise, it acts as a command block, evaluating the next block in the sequence.
		action(pos, node, process, frame, context, ...)
			Receives the standard arguments you get from sb2_action, plus the results of evaluated arguments. The scriptblock either reports the return value of this function, or discards it and replaces the current frame with a frame to evaluate the continuation.
]]

sb2.colors = {}

function sb2.simple_action(def)
	return function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if def.arguments then
			for i, face in ipairs(def.arguments) do
				if not frame:isArgEvaluated(i) then
					frame:selectArg(i)
					return process:push(sb2.Frame:new(vector.add(pos, type(face) == "string" and dirs[face] or face), context))
				end
			end
		end
		
		if def.continuation then
			local cont = def.continuation
			
			def.action(pos, node, process, frame, context, unpack(frame:getArguments()))
			
			process:pop()
			return process:push(sb2.Frame:new(vector.add(pos, type(cont) == "string" and dirs[cont] or cont), context))
		end
		
		return process:report(def.action(pos, node, process, frame, context, unpack(frame:getArguments())))
	end
end

local faceIndexes = {top = 1, bottom = 2, right = 3, left = 4, back = 5, front = 6}
function sb2.makeTiles(color, icons, slots, deprecated)
	if type(icons) == "string" then
		icons = {icons, "blank.png", "blank.png", "blank.png", "blank.png", "blank.png"}
	end
	
	local tiles = {}
	for _, icon in ipairs(icons) do
		table.insert(tiles, "sb2_base.png^[multiply:" .. color .. "^" .. (deprecated and "sb2_deprecated_highlight.png" or "sb2_highlight.png") .. "^(" .. icon .. "^[opacity:45)")
	end
	
	if slots then
		for _, face in ipairs(slots) do
			tiles[faceIndexes[face]] = tiles[faceIndexes[face]] .. "^sb2_slot.png"
		end
	end
	
	return tiles
end

function sb2.toString(value, record)
	if type(value) ~= "table" or not value.recordString then return tostring(value) end
	if record and record[value] then return "..." end
	return value:recordString(record or {}) or ""
end
function sb2.toNumber(value, default)
	if default == nil then default = 0 end
	if type(value) ~= "table" or not value.toNumber then return tonumber(value) or default end
	return value:toNumber() or default
end
function sb2.toLuaValue(value, record)
	if type(value) ~= "table" or not sb2.getClassName(value) then return value end
	if not value.recordLuaValue then return end
	if record and record[value] then return record[value] end
	return value:recordLuaValue(record or {})
end
function sb2.toSB2Value(value, record)
	if type(value) ~= "table" then return value end
	if record and record[value] then return record[value] end
	
	local isList = true
	for k, v in pairs(value) do
		if type(k) ~= "number" or k ~= math.floor(k) then
			isList = false
			break
		end
	end
	
	record = record or {}
	
	local object
	if isList then
		object = sb2.List:new()
		record[value] = object
		
		for k, v in ipairs(value) do
			object:appendItem(sb2.toSB2Value(v, record))
		end
	else
		object = sb2.Dictionary:new()
		record[value] = object
		
		for k, v in pairs(value) do
			object:setEntry(sb2.toSB2Value(k, record), sb2.toSB2Value(v, record))
		end
	end
	
	return object
end
function sb2.prettyPrint(value, ...)
	if type(value) == "string" then return string.format("%q", value) end
	return sb2.toString(value, ...)
end

local function inputOnConstruct(pos)
	local def = minetest.registered_nodes[minetest.get_node(pos).name]
	
	local inputName = minetest.formspec_escape(def.sb2_input_name)
	local inputLabel = minetest.formspec_escape(def.sb2_input_label)
	
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", "field[" .. inputName .. ";" .. inputLabel .. ";${" .. inputName .. "}]")
	meta:set_string(def.sb2_input_name, def.sb2_input_default)
	meta:set_string("infotext", def.sb2_input_label .. ": " .. string.format("%q", def.sb2_input_default))
end
local function inputOnReceiveFields(pos, formname, fields, sender)
	local senderName = sender:get_player_name()
	if minetest.is_protected(pos, senderName) then minetest.record_protection_violation(pos, senderName); return end
	
	local def = minetest.registered_nodes[minetest.get_node(pos).name]
	
	if not fields[def.sb2_input_name] then return end
	
	local meta = minetest.get_meta(pos)
	local oldInput = meta:get_string(def.sb2_input_name)
	local newInput = fields[def.sb2_input_name]
	
	meta:set_string(def.sb2_input_name, newInput)
	meta:set_string("infotext", def.sb2_input_label .. ": " .. string.format("%q", newInput))
end

local defaultGroups = {oddly_breakable_by_hand = 1}
function sb2.registerScriptblock(id, def)
	def.description = def.description or def.sb2_label .. " Scriptblock"
	
	local customGroups = def.groups
	
	def.groups = customGroups or {}
	if not customGroups or def.sb2_add_groups then
		for k, v in pairs(defaultGroups) do
			def.groups[k] = def.groups[k] or v
		end
		if def.sb2_deprecated then
			def.groups.not_in_creative_inventory = 1
		end
	end
	
	def.paramtype2 = def.paramtype2 or "facedir"
	
	if def.sb2_input_name then
		local old_on_construct = def.on_construct or function () end
		def.on_construct = function (...)
			inputOnConstruct(...)
			return old_on_construct(...)
		end
		local old_on_receive_fields = def.on_receive_fields or function () end
		def.on_receive_fields = function (...)
			inputOnReceiveFields(...)
			return old_on_receive_fields(...)
		end
	end
	
	def.tiles = def.tiles or sb2.makeTiles(def.sb2_color, def.sb2_icon, def.sb2_slotted_faces, def.sb2_deprecated)
	
	if def.sb2_explanation then
		local expDef = def.sb2_explanation
		local tooltip = {}
		
		table.insert(tooltip, expDef.shortExplanation)
		
		if expDef.inputValues then
			table.insert(tooltip, "Input Values:")
			
			for i, v in ipairs(expDef.inputValues) do
				table.insert(tooltip, string.format("- %s: %s", unpack(v)))
			end
		end
		if expDef.inputSlots then
			table.insert(tooltip, "Input Slots:")
			
			for i, v in ipairs(expDef.inputSlots) do
				table.insert(tooltip, string.format("- %s: %s", unpack(v)))
			end
		end
		if expDef.additionalPoints then
			table.insert(tooltip, "Additional Points:")
			
			for i, v in ipairs(expDef.additionalPoints) do
				table.insert(tooltip, string.format("- %s", v))
			end
		end
		
		def._tt_help = table.concat(tooltip, "\n")
	end
	
	minetest.register_node(id, def)
	
	if unified_inventory then
		unified_inventory.add_category_item("scriptblocks2", id)
	end
end


minetest.register_tool("scriptblocks2:runner", {
	description = "Scriptblock Runner",
	_tt_help = "Starts a new scriptblocks process on the pointed block.",
	
	inventory_image = "sb2_runner.png",
	wield_image = "sb2_runner.png^[transformFX",
	
	on_place = function (itemstack, placer, pointed_thing)
		local name = placer:get_player_name()
		
		local pos = pointed_thing.under
		if minetest.is_protected(pos, name) then return end
		
		sb2.Process:new(sb2.Frame:new(pos, sb2.Context:new(pos, name)), pos, name, true)
	end
})

minetest.register_tool("scriptblocks2:stopper", {
	description = "Scriptblock Stopper",
	_tt_help = "Stops all your scriptblock processes that began on the pointed block.",
	
	inventory_image = "sb2_stopper.png",
	
	on_place = function (itemstack, placer, pointed_thing)
		local name = placer:get_player_name()
		local pos = pointed_thing.under
		
		local numStopped = sb2.Process:stopProcessesFor(name, pos)
		
		sb2.tellPlayer(name, "Stopped %d process%s.", numStopped, numStopped == 1 and "" or "es")
	end
})

if unified_inventory then
	unified_inventory.register_category("scriptblocks2", {
		symbol = "scriptblocks2:say",
		label = "Scriptblocks 2"
	})
	
	unified_inventory.add_category_item("scriptblocks2", "scriptblocks2:runner")
	unified_inventory.add_category_item("scriptblocks2", "scriptblocks2:stopper")
end