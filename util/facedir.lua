--[[
Copyright (C)2018-2021 by Aaron Suen <warr1024@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject
to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

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

function sb2.facedirToDirs(facedir)
	return facedirs[facedir]
end