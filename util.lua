-- Thanks to Aaron Suen <warr1024@gmail.com> for this snippet!

local alldirs = {
	e = {x = 1, y = 0, z = 0},
	w = {x = -1, y = 0, z = 0},
	u = {x = 0, y = 1, z = 0},
	d = {x = 0, y = -1, z = 0},
	n = {x = 0, y = 0, z = 1},
	s = {x = 0, y = 0, z = -1}
}

local facedirs = {
	{"u", "w"},
	{"u", "n"},
	{"u", "e"},
	{"n", "u"},
	{"n", "w"},
	{"n", "d"},
	{"n", "e"},
	{"s", "d"},
	{"s", "w"},
	{"s", "u"},
	{"s", "e"},
	{"e", "s"},
	{"e", "u"},
	{"e", "n"},
	{"e", "d"},
	{"w", "s"},
	{"w", "d"},
	{"w", "n"},
	{"w", "u"},
	{"d", "s"},
	{"d", "e"},
	{"d", "n"},
	{"d", "w"},
	[0] = {"u", "s"}
}

local function cross(a, b)
	return {
		x = a.y * b.z - a.z * b.y,
		y = a.z * b.x - a.x * b.z,
		z = a.x * b.y - a.y * b.x
	}
end

for k, t in pairs(facedirs) do
	t.id = k
	t.top = alldirs[t[1]]
	t.front = alldirs[t[2]]
	t[2] = nil
	t[1] = nil
	t.left = cross(t.top, t.front)
	t.right = vector.multiply(t.left, -1)
	t.bottom = vector.multiply(t.top, -1)
	t.back = vector.multiply(t.front, -1)
end

-- End snippet

function sb2.facedirToDirs(facedir)
	return facedirs[facedir]
end

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