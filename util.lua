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

function sb2.log(level, message, ...)
	minetest.log(level, string.format("[Scriptblocks2] " .. message, ...))
end