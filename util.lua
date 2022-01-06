function sb2.shallowCopy(tbl)
	local newTbl = {}
	for k, v in pairs(tbl) do
		newTbl[k] = v
	end
	return newTbl
end

function sb2.generateUUID()
	return ("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"):gsub("x", function () local num = math.random(1, 16); return ("0123456789abcdef"):sub(num, num) end)
end

function sb2.getSize(v)
	local t = type(v)
	
	-- A table reference is 8 bytes
	if t == "table" then return 8 end
	-- A number is 8 bytes
	if t == "number" then return 8 end
	-- A string is 1 byte per character
	if t == "string" then return v:len() + 25 end
	-- A boolean is 1 byte
	if t == "boolean" then return 1 end
	-- Nil, let's just say it's 1 byte
	if t == "nil" then return 1 end
	
	-- Unsupported type, return 8 by default
	return 8
end

function sb2.log(level, message, ...)
	minetest.log(level, string.format("[Scriptblocks 2] " .. message, ...))
end