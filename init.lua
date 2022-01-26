sb2 = {}

local MP = minetest.get_modpath(minetest.get_current_modname())

local privateSB2 = {}
privateSB2.modStorage = minetest.get_mod_storage()

local settings = minetest.settings
local enableExperiments = settings:get_bool("scriptblocks2_enable_experiments")

-- Utilities
-- These are files to provide helper functions and classes, as well as a simple class mechanism.
dofile(MP .. "/util/util.lua")
dofile(MP .. "/util/facedir.lua")
dofile(MP .. "/util/classes.lua")
dofile(MP .. "/util/iterators.lua")

-- Core
-- This is the core of Scriptblocks 2. It defines Process, Frame and Context, their behaviour, and manages the running of processes.
dofile(MP .. "/core.lua")

-- Base
-- This is the base of Scriptblocks 2. It defines the look and feel of scriptblocks and manages type conversions.
-- The base currently depends on /blocks/lists.lua and /blocks/dictionaries.lua to convert Lua values to SB2 values.
dofile(MP .. "/base.lua")

-- Blocks
-- These files implement the blocks available in Scriptblocks 2. They are organized into distinct 'categories'.
dofile(MP .. "/blocks/special.lua")
dofile(MP .. "/blocks/control.lua")
dofile(MP .. "/blocks/io.lua")
dofile(MP .. "/blocks/operators.lua")
dofile(MP .. "/blocks/variables.lua")
dofile(MP .. "/blocks/lists.lua")
dofile(MP .. "/blocks/dictionaries.lua")
loadfile(MP .. "/blocks/procedures.lua")(privateSB2)
loadfile(MP .. "/blocks/closures.lua")(privateSB2)
dofile(MP .. "/blocks/coroutines.lua")
if enableExperiments then
	dofile(MP .. "/blocks/continuations.lua")
	dofile(MP .. "/blocks/delimited_continuations.lua")
	dofile(MP .. "/blocks/processes.lua")
	dofile(MP .. "/blocks/fun.lua")
end
if mesecon then
	dofile(MP .. "/blocks/mesecons.lua")
end
if digilines then
	dofile(MP .. "/blocks/digilines.lua")
end