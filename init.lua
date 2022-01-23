sb2 = {}

local MP = minetest.get_modpath(minetest.get_current_modname())

local privateSB2 = {}
privateSB2.modStorage = minetest.get_mod_storage()

local settings = minetest.settings
local enableExperiments = settings:get_bool("scriptblocks2_enable_experiments")

dofile(MP .. "/util.lua")
dofile(MP .. "/facedir.lua")
dofile(MP .. "/class.lua")
dofile(MP .. "/iterators.lua")

dofile(MP .. "/core.lua")
dofile(MP .. "/base.lua")

dofile(MP .. "/special.lua")
dofile(MP .. "/control.lua")
dofile(MP .. "/looks.lua")
dofile(MP .. "/operators.lua")
dofile(MP .. "/variables.lua")
dofile(MP .. "/lists.lua")
dofile(MP .. "/dictionaries.lua")
loadfile(MP .. "/procedures.lua")(privateSB2)
loadfile(MP .. "/closures.lua")(privateSB2)
dofile(MP .. "/coroutines.lua")

if enableExperiments then
	dofile(MP .. "/continuations.lua")
	dofile(MP .. "/delimited_continuations.lua")
	dofile(MP .. "/processes.lua")
	dofile(MP .. "/fun.lua")
end

if mesecon then
	dofile(MP .. "/mesecons.lua")
end
if digilines then
	dofile(MP .. "/digilines.lua")
end