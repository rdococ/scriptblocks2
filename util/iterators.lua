--[[
Recursive Iterator

An object that iterates a table recursively. Does not use standard Lua iteration mechanism because this iterator is designed to be able to run across multiple Minetest ticks.

Methods:
	hasNext()
		Returns true if there are more objects left to iterate through.
	next()
		Returns the next object to iterate through and advances the iterator.
]]

sb2.RecursiveIterator = sb2.registerClass("recursiveiterator")

function sb2.RecursiveIterator:initialize(object)
	self.traced = setmetatable({[self] = true}, {__mode = "k"})
	self.traceQueue = {}
	self.returnQueue = {object}
	
	self.currentObject = object
	self.currentKey = nil
end

function sb2.RecursiveIterator:hasNext()
	return #self.returnQueue > 0
end

function sb2.RecursiveIterator:next()
	if not self.currentObject then
		if #self.traceQueue == 0 then
			local value = self.returnQueue[1]
			table.remove(self.returnQueue, 1)
			return value
		end
		
		self.currentObject, self.currentKey = self.traceQueue[1], nil
		table.remove(self.traceQueue, 1)
	end
	
	local k, v = next(self.currentObject, self.currentKey)
	self.currentKey = k
	
	if k == nil then
		self.currentObject = nil
	else
		if not self.traced[k] then
			if type(k) == "table" then
				self.traced[k] = true
				table.insert(self.traceQueue, k)
			end
			
			table.insert(self.returnQueue, k)
		end
		if not self.traced[v] then
			if type(v) == "table" then
				self.traced[v] = true
				table.insert(self.traceQueue, v)
			end
			
			table.insert(self.returnQueue, v)
		end
	end
	
	local value = self.returnQueue[1]
	table.remove(self.returnQueue, 1)
	return value
end