sb2 = {}

local MP = minetest.get_modpath(minetest.get_current_modname())

dofile(MP .. "/util.lua")
dofile(MP .. "/core.lua")
dofile(MP .. "/base.lua")

dofile(MP .. "/special.lua")
dofile(MP .. "/control.lua")
dofile(MP .. "/looks.lua")
dofile(MP .. "/operators.lua")
dofile(MP .. "/variables.lua")

dofile(MP .. "/lists.lua")
dofile(MP .. "/dictionaries.lua")
dofile(MP .. "/procedures.lua")
dofile(MP .. "/closures.lua")

if mesecon then
	dofile(MP .. "/mesecons.lua")
end
if digilines then
	dofile(MP .. "/digilines.lua")
end