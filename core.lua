--[[
	Scriptblocks2 Core
	
	This is the core of the mod. It defines the API for manipulating processes and stack frames used by scriptblocks,
	and is also responsible for stepping through each process on each globalstep.
]]

local settings = minetest.settings
local maxSteps = settings:get("scriptblocks2_max_steps") or 10000
local maxMemory = settings:get("scriptblocks2_max_memory") or 100000
local maxProcesses = settings:get("scriptblocks2_max_processes") or 500

--[[
Process

A process is a running instance of a scriptblocks2 program. Processes store their current evaluation frame and an event queue for processing outside events (a mechanism which is still a work in progress).

Methods:
	push(frame)
		Pushes the given frame onto the stack; i.e. the new frame is evaluated, and once finished, control returns to the current frame. Think of this like a function call.
	replace(frame)
		Replaces the topmost frame with a new one; i.e. the new frame replaces the current frame completely. This is equivalent to a tail-recursive call.
	report(value)
		Pops the current frame, returning control to the previous frame, and a reported value along with it. This is like returning from a function call.
	
	queueEvent(event)
		Queues an event in the process's event queue. Currently, events are unused, and the language model for passing events to processes is yet to be worked out.
	handleEvent(criteria)
		Finds, pops and returns the first event that satisfies the given criteria.
	
	step()
		Performs one execution step.
	
	halt(reason)
		Halts this process. The process is still in runningProcesses until the end of the next Minetest tick, and calling step() does nothing. Halting reason can be anything truthy, but generally one of the following:
			"TooManyProcesses"
				This process was halted at the start because the player has already reached maxProcesses.
			"OutOfMemory"
				This process was halted because it exceeded maxMemory.
			true
				This process ended normally without any issues.
	yield()
		Causes the current process to yield until the start of the next tick. Processes are normally stepped up to maxSteps times per Minetest tick. A process can yield to signal that it is waiting for some external change that can only occur on the next tick, allowing stepping to end early.
	
	isHalted()
		Returns true if the process has halted, false otherwise.
	isYielding()
		Returns true if the process is yielding until the start of the next tick.
	
	getHaltingReason()
		Returns the reason this process has halted, or nil if it hasn't.

Node properties:
	sb2_action(pos, node, process, context, frame)
		When a scriptblock is evaluated, the process calls this function from the node definition to decide what to do. The function can call any of the methods presented in this file on existing processes, frames or contexts and/or create new frames and contexts. The function may be evaluated multiple times if control returns to the current frame; this is how scriptblocks can can evaluate multiple arguments, perform calculations and report the result.
]]

sb2.Process = sb2.registerClass("process")

sb2.Process.runningProcesses = {}
sb2.Process.processCounts = {}

function sb2.Process:initialize(frame)
	self.starter = frame:getContext():getOwner()
	if self.starter then
		local processCounts = sb2.Process.processCounts
		local processCount = processCounts[self.starter] or 0
		
		processCounts[self.starter] = processCount + 1
		
		if processCount >= maxProcesses then
			sb2.log("warning", "Process could not be started by %s (too many processes) at %s", self.starter or "(unknown)", minetest.pos_to_string(frame:getPos()))
			self:halt("TooManyProcesses")
			return
		end
	end
	
	self.frame = frame
	self.eventQueue = {}
	
	self.memoryScanner = sb2.RecursiveIterator:new(self)
	
	self.memoryUsage = 0
	self.newMemoryUsage = 0
	
	self.yielding = false
	self.halted = false
	
	sb2.log("action", "Process started by %s at %s", self.starter or "(unknown)", minetest.pos_to_string(frame:getPos()))
	
	table.insert(sb2.Process.runningProcesses, self)
end
function sb2.Process:push(frame)
	frame:setParent(self.frame)
	self.frame = frame
end
function sb2.Process:replace(frame)
	frame:setParent(self.frame:getParent())
	self.frame = frame
end
function sb2.Process:report(value)
	local parent = self.frame:getParent()
	if parent then
		parent:receiveArg(value)
	else
		sb2.log("action", "Process at %s reported %s", minetest.pos_to_string(self.frame:getPos()), tostring(value))
	end
	self.frame = parent
end
function sb2.Process:queueEvent(event)
	table.insert(self.eventQueue, event)
end
function sb2.Process:handleEvent(criteria)
	for i, event in ipairs(self.eventQueue) do
		if criteria(event) then
			table.remove(self.eventQueue, i)
			return event
		end
	end
end
function sb2.Process:step()
	if self.halted then return end
	self.yielding = false
	
	local oldFrame = self.frame
	if not oldFrame then return self:halt() end
	
	local pos = oldFrame.pos
	
	local node = minetest.get_node(pos)
	local nodename = node.name
	
	if nodename == "ignore" then
		if not minetest.forceload_block(pos, true) then return self:yield() end
		
		node = minetest.get_node(pos)
		nodename = node.name
		
		if nodename == "ignore" then return self:yield() end
	end
	
	local def = minetest.registered_nodes[nodename]
	if def and def.sb2_action then
		def.sb2_action(pos, node, self, oldFrame, oldFrame:getContext())
	else
		self:report(nil)
	end
	
	for i = 1, #self.eventQueue do
		table.remove(self.eventQueue, 1)
	end
	
	if not self.frame or not vector.equals(pos, self.frame:getPos()) then
		minetest.forceload_free_block(pos, true)
		if self.frame then
			minetest.forceload_block(self.frame:getPos(), true)
		end
	end
	
	local getSize = sb2.getSize
	
	if not self.halted then
		local i = 1
		if self.memoryScanner:hasNext() then
			local object = self.memoryScanner:next()
			local size = getSize(object)
			
			self.newMemoryUsage = self.newMemoryUsage + size
			
			i = i + 1
		end
		if not self.memoryScanner:hasNext() then
			self.memoryUsage = self.newMemoryUsage
			
			self.memoryScanner = sb2.RecursiveIterator:new(self)
			self.newMemoryUsage = 0
			
			if self.memoryUsage > maxMemory then
				if self.frame then
					sb2.log("warning", "Process started by %s ran out of memory at %s", self.starter or "(unknown)", minetest.pos_to_string(self.frame:getPos()))
				else
					sb2.log("warning", "Process started by %s ran out of memory somewhere", self.starter or "(unknown)")
				end
				
				return self:halt("OutOfMemory")
			end
		end
	end
end
function sb2.Process:halt(reason)
	self.halted = reason or true
	sb2.Process.processCounts[self.starter] = sb2.Process.processCounts[self.starter] - 1
	
	sb2.log("action", "Process by %s halted because %s", self.starter or "(unknown)", tostring(self.halted))
end
function sb2.Process:yield()
	self.yielding = true
end
function sb2.Process:isHalted()
	return self.halted and true or false
end
function sb2.Process:isYielding()
	return self.yielding
end
function sb2.Process:getHaltingReason()
	return self.halted or nil
end


--[[
Frame

A frame is a single unit of evaluation in a scriptblocks2 program. A frame stores the position of the node it is evaluating, the context of variables it is doing so in, and the parent frame which it will eventually report back to. It also stores a set of arguments, temporary storage where scriptblocks can store values for later evaluation steps, or receive values reported from elsewhere.

Methods:
	getPos()
		Returns the position of the node this frame is evaluating.
	getContext()
		Returns the context of this evaluation frame. This consists of variables, the top block that began the current procedure, and the player blamed for building the current procedure.
	
	getParent()
		Returns the frame that this frame will eventually report back to.
	setParent(parent)
		Sets this frame's parent, causing it to report back to that frame when done.
	
	getArguments()
		Returns a table consisting of this frame's evaluated arguments.
	isArgEvaluated(arg)
		Returns true if this argument has been evaluated, even if the result was nil.
	getArg(arg)
		Gets the value of this argument.
	setArg(arg, value)
		Manually sets the value of this argument for temporary storage by the scriptblock. Also marks the argument as evaluated.
	selectArg(arg)
		Selects the given argument as the "report destination" for the next frame that this frame pushes onto the process.
	receiveArg(value)
		Receives a value, storing it in the selected argument and marking it as evaluated.
]]

sb2.Frame = sb2.registerClass("frame")

function sb2.Frame:initialize(pos, context)
	self.pos = pos
	self.context = context
	self.parent = nil
	
	self.arguments = {}
	self.argsEvaluated = {}
	self.selectedArg = nil
end
function sb2.Frame:getPos()
	return self.pos
end
function sb2.Frame:getContext()
	return self.context
end
function sb2.Frame:getParent()
	return self.parent
end
function sb2.Frame:setParent(parent)
	self.parent = parent
end
function sb2.Frame:getArguments()
	return self.arguments
end
function sb2.Frame:isArgEvaluated(arg)
	return self.argsEvaluated[arg] or false
end
function sb2.Frame:getArg(arg)
	return self.arguments[arg]
end
function sb2.Frame:setArg(arg, value)
	self.arguments[arg] = value
	self.argsEvaluated[arg] = true
end
function sb2.Frame:selectArg(arg)
	self.selectedArg = arg
end
function sb2.Frame:receiveArg(value)
	self.arguments[self.selectedArg] = value
	self.argsEvaluated[self.selectedArg] = true
end


--[[
Context

A context is a lexical context within a scriptblocks2 program. Contexts store variables, the head of the current procedure and the player that owns it. Multiple evaluation frames may share the same context, or have separate contexts but share variable objects.

Methods:
	copy()
		Copies the context, creating a new context which shares the same variables and head, but not owner. New variables declared in the original context do not transfer over to the copy, but if an existing variable is mutated, that change will be visible.
	declareVar(varname, value)
		Creates a new variable named varname in this context and sets its value.
	getVar(varname)
		Gets the variable object referred to by varname in this context. Use .value to set or get its value.
	getOwner()
		Gets the player blamed for building the scriptblocks running in this context.
	setOwner(owner)
		Sets the owner blamed for building these scriptblocks.
	getHead()
		Gets the initial position of the current context.
]]

sb2.Context = sb2.registerClass("context")

function sb2.Context:initialize(head, owner)
	self.variables = {}
	self.head = head
	self.owner = owner
end
function sb2.Context:copy()
	local copy = self:getClass():new(self.head)
	copy.variables = sb2.shallowCopy(self.variables)
	return copy
end
function sb2.Context:declareVar(varname, value)
	self.variables[varname] = {value = value}
end
function sb2.Context:getVar(varname)
	return self.variables[varname]
end
function sb2.Context:getOwner()
	return self.owner
end
function sb2.Context:setOwner(owner)
	self.owner = owner
end
function sb2.Context:getHead()
	return self.head
end


local i = 1
minetest.register_globalstep(function ()
	local processes = sb2.Process.runningProcesses
	
	while i <= math.min(#processes, maxSteps) do
		local process = processes[i]
		for _ = 1, math.max(math.floor(maxSteps / #processes), 1) do
			process:step()
			if process:isHalted() then
				table.remove(processes, i)
				i = i - 1
				break
			elseif process:isYielding() then
				break
			end
		end
		
		i = i + 1
	end
	if i > #processes then i = 1 end
end)