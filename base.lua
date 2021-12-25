--[[
	Base
	
	This is the base of scriptblocks2. It defines various helper functions for creating vanilla-looking and vanilla-acting scriptblocks, and provides conversion functions between Lua and SB2 values (e.g. lists, dictionaries and closures).
	
	colors
		A table of colors for each category of scriptblock.
	
	makeTiles
		Takes a base texture, an icon, and an optional list of faces ("top", "right", "front", etc.). It produces a set of tiles with the icon slapped on top of the base texture, and slot images overlayed on the selected faces.
	single_input_*
		The 'single_input' functions can be used to create scriptblocks that take a single input from a formspec. This is used for constant values and variable names.
	registerScriptblock
		Registers a 'vanilla' scriptblock node, using 'makeTiles' and optionally the 'single_input' mechanism.
		Any node can be modified to interact with scriptblocks, but this is the main way to do it.
		
		sb2_label: A human-readable name for the scriptblock. Suffixed with "Scriptblock" to create the item description.
		
		sb2_color: The color of the scriptblock.
		sb2_icon: The icon to be overlayed on the top face of the scriptblock.
		sb2_slotted_faces: A list of faces to be overlayed with slots.
	string/number
		Functions to convert values to strings or numbers. Guaranteed never to return nil. Use these instead of tostring and tonumber to follow the typing conventions of the language.
]]

sb2.colors = {}

function sb2.simple_action(def)
	return function (pos, node, process, frame)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if def.arguments then
			for i, face in ipairs(def.arguments) do
				if not sb2.isArgEvaluated(frame, i) then
					sb2.selectArg(frame, i)
					return sb2.pushFrame(process, sb2.createFrame(vector.add(pos, type(face) == "string" and dirs[face] or face), frame))
				end
			end
		end
		
		if def.continuation then
			local cont = def.continuation
			
			def.action(pos, node, process, frame, unpack(frame.arguments))
			
			return sb2.replaceFrame(process, sb2.createFrame(vector.add(pos, type(cont) == "string" and dirs[cont] or cont), frame))
		end
		
		return sb2.reportValue(process, def.action(pos, node, process, frame, unpack(frame.arguments)))
	end
end

local faceIndexes = {top = 1, bottom = 2, right = 3, left = 4, back = 5, front = 6}
function sb2.makeTiles(base, icons, slots)
	if type(icons) == "string" then
		icons = {icons, "blank.png", "blank.png", "blank.png", "blank.png", "blank.png"}
	end
	
	local tiles = {}
	for _, icon in ipairs(icons) do
		table.insert(tiles, "sb2_base.png^[multiply:" .. base .. "^sb2_highlight.png^(" .. icon .. "^[opacity:48)")
	end
	
	if slots then
		local slottedTexture = texture
		for _, face in ipairs(slots) do
			tiles[faceIndexes[face]] = tiles[faceIndexes[face]] .. "^sb2_slot.png"
		end
	end
	
	return tiles
end

function sb2.single_input_on_construct(pos)
	local def = minetest.registered_nodes[minetest.get_node(pos).name]
	
	local inputName = minetest.formspec_escape(def.sb2_input_name)
	local inputLabel = minetest.formspec_escape(def.sb2_input_label)
	
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", "field[" .. inputName .. ";" .. inputLabel .. ";${" .. inputName .. "}]")
	meta:set_string(def.sb2_input_name, def.sb2_input_default)
	meta:set_string("infotext", def.sb2_input_label .. ": " .. string.format("%q", def.sb2_input_default))
end
function sb2.single_input_on_receive_fields(pos, formname, fields, sender)
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

function sb2.toString(value, record)
	if type(value) ~= "table" then
		return tostring(value) or ""
	end
	
	record = record or {}
	if record[value] then return "..." end
	
	record[value] = true
	
	if value.type == "list" then
		local elements = {}
		
		for index = 1, sb2.getListLength(value) do
			table.insert(elements, sb2.prettyPrint(sb2.getListItem(value, index), record))
		end
		
		return "[" .. table.concat(elements, ", ") .. "]"
	elseif value.type == "dictionary" then
		return "<dictionary>"
	elseif value.type == "closure" then
		return "<closure>"
	end
	
	return tostring(value) or ""
end
function sb2.toNumber(value)
	return tonumber(value) or 0
end
function sb2.prettyPrint(value, record)
	if type(value) == "string" then
		return string.format("%q", value)
	end
	return sb2.toString(value, record)
end
function sb2.toSB2Value(value, record)
	if type(value) ~= "table" then return value end
	
	record = record or {}
	if record[value] then return record[value] end
	
	local entries = {}
	local dict = {type = "dictionary", entries = entries}
	
	record[value] = dict
	
	for k, v in pairs(value) do
		entries[sb2.toSB2Value(k, record)] = sb2.toSB2Value(v, record)
	end
	
	return dict
end
function sb2.toLuaValue(value, record)
	if type(value) ~= "table" then return value end
	record = record or {}
	
	if record[value] then return record[value] end
	
	if value.type == "list" then
		local newv = {}
		record[value] = newv
		
		for i, item in pairs(value.items) do
			newv[i] = item
		end
		
		return newv
	elseif value.type == "dictionary" then
		local newv = {}
		record[value] = newv
		
		for k, entry in pairs(value.entries) do
			newv[k] = entry
		end
		
		return newv
	end
end

local defaultGroups = {oddly_breakable_by_hand = 1}
function sb2.registerScriptblock(id, def)
	def.description = def.description or def.sb2_label .. " Scriptblock"
	def.groups = def.groups or defaultGroups
	
	if def.sb2_add_groups then
		for k, v in pairs(defaultGroups) do
			def.groups[k] = def.groups[k] or v
		end
	end
	
	def.paramtype2 = def.paramtype2 or "facedir"
	
	if def.sb2_input_name then
		local old_on_construct = def.on_construct or function () end
		def.on_construct = function (...)
			sb2.single_input_on_construct(...)
			return old_on_construct(...)
		end
		local old_on_receive_fields = def.on_receive_fields or function () end
		def.on_receive_fields = function (...)
			sb2.single_input_on_receive_fields(...)
			return old_on_receive_fields(...)
		end
	end
	
	def.tiles = def.tiles or sb2.makeTiles(def.sb2_color, def.sb2_icon, def.sb2_slotted_faces)
	
	if digilines then
		def.digilines = def.digilines or {}
		def.digilines.receptor = def.digilines.receptor or {}
	end
	
	minetest.register_node(id, def)
	
	if unified_inventory then
		unified_inventory.add_category_item("scriptblocks2", id)
	end
end

-- Tools
minetest.register_tool("scriptblocks2:runner", {
	description = "Scriptblock Runner",
	
	inventory_image = "sb2_runner.png",
	wield_image = "sb2_runner.png^[transformFX",
	
	on_place = function (itemstack, placer, pointed_thing)
		local name = placer:get_player_name()
		
		local pos = pointed_thing.under
		if minetest.is_protected(pos, name) then return end
		
		sb2.createProcess(sb2.createFrame(pos, nil, name))
	end
})
if unified_inventory then
	unified_inventory.add_category_item("scriptblocks2", "scriptblocks2:runner")
	unified_inventory.register_category("scriptblocks2", {
		symbol = "scriptblocks2:say",
		label = "Scriptblocks 2"
	})
end