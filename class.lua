--[[
	Class System
	
	This is a very simple class system. It exists primarily to support proper object serialization and deserialization for scriptblocks2 values in the future.
	
	class.instances
		Maps instances to their class names.
	class.classes
		Maps class names to class defs.

	sb2.registerClass(name, def)
		Registers and returns a new class for you to expose in any way you want. Should only be run at load time. 'def' should not be a pre-existing table, as it is modified during registration.
	
	TODO: class.serialize(object)
		Serializes an object or plain Lua value.
	TODO: class.deserialize(object)
		Deserializes an object or plain Lua value.
		If it is an object, this includes reregistering it as an instance of the class it was originally from and reinstantiating its metatable.
		Should only be run when all mods are loaded, so that objects from mods loaded after this one can still be serialized and deserialized properly.
	
	<class>.name
		Returns the canonical name of this class.
	<class>:new(...)
		Creates a new instance of the class, calls :initialize(...) and returns it.
	
	<object>:getClass()
		Returns the object's class, or nil if it is a plain Lua value.
]]

local classDefinitions = {}
local instanceClassNames = {}

local function new(self, ...)
	local instance = {}
	
	instanceClassNames[instance] = self.name
	
	setmetatable(instance, self)
	if instance.initialize then
		instance:initialize(...)
	end
	
	return instance
end
local function getClass(self)
	return instanceClassNames[self] and classDefinitions[instanceClassNames[self]]
end

function sb2.registerClass(name, def)
	def = def or {}
	
	classDefinitions[name] = def
	
	def.__index = def
	def.name = name
	def.new = new
	def.getClass = getClass
	
	return def
end