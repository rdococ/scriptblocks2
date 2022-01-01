local env = (...).insecureEnvironment
local newproxy = env.newproxy

function sb2.getPrimitiveSize(p)
	if type(p) == "string" then return p:len() end
	if p == nil then return 0 end
	return 1
end

sb2.FootprintTracker = sb2.registerClass("FootprintTracker")

function sb2.FootprintTracker:initialize()
	self.memoryFootprint = 0
	self.objectProxies = setmetatable({}, {__mode = "k"})
end
-- Called by trackee
function sb2.FootprintTracker:footprintChanged(difference)
	self.memoryFootprint = self.memoryFootprint + difference
end
-- Called by object
function sb2.FootprintTracker:getMemoryFootprint()
	return self.memoryFootprint
end
function sb2.FootprintTracker:trackFootprint(trackee)
	if self.objectProxies[trackee] then return end
	
	local proxy = newproxy(true)
	getmetatable(proxy).__gc = function ()
		self.memoryFootprint = self.memoryFootprint - trackee:getSize()
		sb2.log("none", "Trackee was garbage collected %s", sb2.prettyPrint(trackee))
	end
	
	self.objectProxies[trackee] = proxy
	
	self.memoryFootprint = self.memoryFootprint + trackee:getSize()
	
	-- sb2.log("none", "Tracking footprint %s", sb2.prettyPrint(trackee))
	
	trackee:trackerAssigned(self)
end
function sb2.FootprintTracker:recordString(record)
	return "<FootprintTracker>"
end


sb2.FootprintTrackee = sb2.registerClass("FootprintTrackee")

function sb2.FootprintTrackee:initialize()
	self.assignedTrackers = setmetatable({}, {__mode = "k"})
	self.size = 1
end
-- Called by tracker
function sb2.FootprintTrackee:trackerAssigned(tracker)
	self.assignedTrackers[tracker] = true
end
function sb2.FootprintTrackee:getSize()
	return self.size
end
-- Called by object
function sb2.FootprintTrackee:valueChanged(a, b)
	local difference = sb2.getPrimitiveSize(b) - sb2.getPrimitiveSize(a)
	
	self.size = self.size + difference
	
	-- sb2.log("none", "Value changed: %s -> %s", sb2.prettyPrint(a), sb2.prettyPrint(b))
	
	if type(b) == "table" and b.getTrackee then
		local bTrackee = b:getTrackee()
		for tracker, _ in pairs(self.assignedTrackers) do
			tracker:footprintChanged(difference)
			tracker:trackFootprint(bTrackee)
		end
	else
		for tracker, _ in pairs(self.assignedTrackers) do
			tracker:footprintChanged(difference)
		end
	end
end
function sb2.FootprintTrackee:recordString(record)
	return "<FootprintTrackee>"
end