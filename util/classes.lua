--[[
	Class System
	
	This is a very simple class system. It exists primarily to support proper object serialization and deserialization for scriptblocks2 values in the future.
	
	class.instances
		Maps instances to their class names.
	class.classes
		Maps class names to class defs.

	sb2.registerClass(name, def)
		Registers and returns a new class for you to expose in any way you want. Should only be run at load time. 'def' should not be a pre-existing table, as it is modified during registration.
	sb2.serialize(object)
		Serializes a value. Supports both raw Lua values and class instances.
	
	class.name
		Returns the canonical name of this class.
	class:rawNew()
		Creates a new instance of this class and returns it *without* initializing it.
		Class code will likely expect all initial fields to be set!
	class:new(...)
		Creates a new instance of the class, calls instance:initialize(...) and returns it.
	
	object:getClass()
		Returns the object's class, or nil if it is a plain Lua value.
	
	object:isSerializable()
		Called to determine if this object can be serialized.
	object:shouldNotSerialize(k)
		Called to determine if a field with a specific key should not be serialized.
]]

local classDefinitions = {}
local instanceClassNames = {}

local function rawNew(self)
	local instance = {}
	instanceClassNames[instance] = self.name
	setmetatable(instance, self)
	return instance
end
local function new(self, ...)
	local instance = self:rawNew()
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
	def.rawNew = rawNew
	def.new = new
	def.getClass = getClass
	
	return def
end
function sb2.classNamed(name)
	return classDefinitions[name]
end
function sb2.getClassName(v)
	return instanceClassNames[v]
end

--[[
record = {
	declarations = {}, -- "t[1] = {}", etc.
	definitions = {}, -- "t[1][3] = t[2]", etc. list of code segments to concatenate
	indices = {}, -- map from values to their array indices
	nextIndex = 1, -- next unused index
]]
function sb2.serialize(obj, record)
	if type(obj) == "string" then return string.format("%q", obj) end
	if type(obj) == "number" or type(obj) == "boolean" or type(obj) == "nil" then return tostring(obj) end
	
	local initialCall = not record
	if not record then record = {declarations = {}, definitions = {}, indices = {}, nextIndex = 1} end
	
	if type(obj) == "table" then
		if record.indices[obj] then return string.format("t[%s]", record.indices[obj]) end
		
		local className = sb2.getClassName(obj)
		local creator = className and string.format("sb2.classNamed(%q):rawNew()", className) or "{}"
		
		local myIndex = record.nextIndex
		local indexer = string.format("t[%s]", record.nextIndex)
		table.insert(record.declarations, string.format("%s = %s;\n", indexer, creator))
		record.indices[obj] = myIndex
		record.nextIndex = record.nextIndex + 1
		
		if className then
			if not obj.isSerializable or not obj:isSerializable() then return "nil" end
			for k, v in pairs(obj) do
				if not obj.shouldNotSerialize or obj:shouldNotSerialize(k) then
					table.insert(record.definitions, string.format("%s[%s] = %s;\n", indexer, sb2.serialize(k, record), sb2.serialize(v, record)))
				end
			end
		else
			for k, v in pairs(obj) do
				table.insert(record.definitions, string.format("%s[%s] = %s;\n", indexer, sb2.serialize(k, record), sb2.serialize(v, record)))
			end
		end
		
		if initialCall then
			return string.format("local t = {};%s%sreturn t[%s]", table.concat(record.declarations), table.concat(record.definitions), myIndex)
		else
			return indexer
		end
	end
	
	return "nil"
end