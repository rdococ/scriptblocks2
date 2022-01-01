sb2 = {}

local MP = minetest.get_modpath(minetest.get_current_modname())

local privateSB2 = {}
privateSB2.modStorage = minetest.get_mod_storage()
privateSB2.insecureEnvironment = minetest.request_insecure_environment()

if not privateSB2.insecureEnvironment then
	error("Scriptblocks 2 needs to access the insecure environment, solely for newproxy()")
end

dofile(MP .. "/util.lua")
dofile(MP .. "/class.lua")

loadfile(MP .. "/tracking.lua")(privateSB2)

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

dofile(MP .. "/fun.lua")

if mesecon then
	dofile(MP .. "/mesecons.lua")
end
if digilines then
	dofile(MP .. "/digilines.lua")
end