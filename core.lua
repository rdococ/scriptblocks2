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

A process is a running instance of a scriptblocks2 program. Processes store their current evaluation frame, an event queue for processing outside events (a mechanism which is still a work in progress), and whether they are yielding/halted.

Constructor:
	new(frame, manual)
		frame
			The evaluation frame to start on. The process' 'starter' is automatically set to the owner of this frame.
		manual
			Whether this process was started manually using the runner tool or similar. This may send useful debugging information to the starter player in the future.

Methods:
	getStarter()
		Gets the player that 'started' this process (i.e. the owner of the initial block of the entire process, not just the current procedure).
	getHead()
		Gets the 'head' of this process (the position of the block that this process started on).
	
	push(frame)
		Pushes the given frame onto the stack; i.e. the new frame is evaluated, and once finished, control returns to the current frame. Think of this like a function call.
	replace(frame)
		Replaces the topmost frame with a new one; i.e. the new frame replaces the current frame completely. This is equivalent to a tail-recursive call.
	report(value)
		Pops the current frame, returning control to the previous frame, and a reported value along with it. This is like returning from a function call.
	
	queueEvent(event)
		Queues an event in the process's event queue. Currently, events are unused, and the language model for passing events to processes is yet to be worked out.
	handleEvent(criteria(event))
		Finds, pops and returns the first event that satisfies the given criterium function.
	
	step()
		Performs one execution step.
	
	halt(reason)
		Halts this process. Halting reason can be anything truthy, but generally one of the following:
			"TooManyProcesses"
				This process was halted at the start because the player has already reached maxProcesses.
			"OutOfMemory"
				This process was halted because it exceeded maxMemory.
			"StoppedManually"
				This process was stopped by external forces, such as a player using a Scriptblock Stopper.
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
	
	log(message, ...)
		Logs a debug message to the player only if debugging is enabled.
		Automatic formatting is applied using string.format. If one of the values is something like "{prettyprint = true, value = ...}", sb2.prettyPrint is called on it before formatting, but only if debugging is enabled.

Static methods:
	stopAllProcessesFor(starter)
		Stops all processes attributed to the given username. Returns the number of processes stopped.
	stopProcessesFor(starter, head)
		Stops all processes attributed to the given username that began at the given location. Returns the number of processes stopped.

Node properties:
	sb2_action(pos, node, process, frame, context)
		When a scriptblock is evaluated, the process calls this function from the node definition to decide what to do. The function can call any of the methods presented in this file on existing processes, frames or contexts and/or create new frames and contexts. The function may be evaluated multiple times if control returns to the current frame; this is how scriptblocks can can evaluate multiple arguments, perform calculations and report the result.
]]

sb2.Process = sb2.registerClass("process")

sb2.Process.processList = {}
sb2.Process.starterInfo = {}

function sb2.Process:stopAllProcessesFor(starter)
	local n = 0
	for process, _ in pairs(sb2.shallowCopy(sb2.Process.starterInfo[starter].processes)) do
		process:halt("StoppedManually")
		n = n + 1
	end
	return n
end

function sb2.Process:stopProcessesFor(starter, head)
	local n = 0
	for process, _ in pairs(sb2.shallowCopy(sb2.Process.starterInfo[starter].processes)) do
		if vector.equals(process:getHead(), head) then
			process:halt("StoppedManually")
			n = n + 1
		end
	end
	return n
end

function sb2.Process:initialize(frame, head, starter, debugging)
	self.head = head
	self.starter = starter
	
	self.debugging = debugging or false
	
	if self.starter then
		local starterInfo = sb2.Process.starterInfo[self.starter]
		local processCount = starterInfo.processCount
		
		starterInfo.processes[self] = true
		starterInfo.processCount = processCount + 1
		
		if processCount >= maxProcesses then
			sb2.log("action", "%s could not start another process at %s", self.starter or "(unknown)", minetest.pos_to_string(frame:getPos()))
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
	
	self:log("Started.")
	sb2.log("action", "Process started by %s at %s", self.starter or "(unknown)", minetest.pos_to_string(frame:getPos()))
	
	table.insert(sb2.Process.processList, self)
end
function sb2.Process:getStarter()
	return self.starter
end
function sb2.Process:getHead()
	return self.head
end
function sb2.Process:isDebugging()
	return self.debugging
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
		self:log("Reported: %s", {prettyprint = true, value = value})
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
	
	local frame = self.frame
	if not frame then return self:halt() end
	
	local pos = frame.pos
	local node = frame:requestNode()
	
	if node == nil then return self:yield() end
	if node == false then
		self:log("Failed to load block at %s", minetest.pos_to_string(pos))
	end
	
	local nodename = node and node.name or "ignore"
	
	local def = minetest.registered_nodes[nodename]
	if def and def.sb2_action then
		def.sb2_action(pos, node, self, frame, frame:getContext())
	else
		self:report(nil)
	end
	frame = self.frame
	
	for i = 1, #self.eventQueue do
		table.remove(self.eventQueue, 1)
	end
	
	if not self.halted then
		local i = 1
		if self.memoryScanner:hasNext() then
			local object = self.memoryScanner:next()
			local size = sb2.getSize(object)
			
			self.newMemoryUsage = self.newMemoryUsage + size
			
			i = i + 1
		end
		if not self.memoryScanner:hasNext() then
			self.memoryUsage = self.newMemoryUsage
			
			self.memoryScanner = sb2.RecursiveIterator:new(self)
			self.newMemoryUsage = 0
			
			if self.memoryUsage > maxMemory then
				return self:halt("OutOfMemory")
			end
		end
	end
end
function sb2.Process:halt(reason)
	self.halted = reason or true
	
	if self.starter then
		local starterInfo = sb2.Process.starterInfo[self.starter]
		starterInfo.processCount = starterInfo.processCount - 1
		starterInfo.processes[self] = nil
	end
	
	if self.halted == "TooManyProcesses" then
		self:log("You have too many processes!")
	elseif self.halted == "OutOfMemory" then
		self:log("Ran out of memory.")
	elseif self.halted == "StoppedManually" then
		self:log("Stopped manually.")
	elseif self.halted == true then
		self:log("Finished normally.")
	else
		self:log("Halted somehow.")
	end
	
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
function sb2.Process:log(message, ...)
	if self.debugging then
		local values = {...}
		for i, v in ipairs(values) do
			if type(v) == "table" and v.prettyprint then
				values[i] = sb2.prettyPrint(v.value)
			end
		end
		
		minetest.chat_send_player(self.starter, string.format("[Process] " .. message, unpack(values)))
	end
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
	
	requestNode()
		Attempts to emerge the node at this frame's position.
		Return values:
			nil
				The emerge request is pending.
			{name = ..., ...}
				The emerge request was successful, here's the node's data.
			false
				The emerge request failed.
]]

sb2.Frame = sb2.registerClass("frame")

function sb2.Frame:initialize(pos, context)
	self.pos = pos
	self.context = context
	self.parent = nil
	
	self.arguments = {}
	self.argsEvaluated = {}
	self.selectedArg = nil
	
	self.requestedEmerge = false
	self.emergeFailed = false
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
function sb2.Frame:requestNode()
	local pos = self.pos
	local node = minetest.get_node(pos)
	
	if node.name == "ignore" then
		if not self.requestedEmerge then
			minetest.emerge_area(pos, pos, function (blockPos, action)
				if action == minetest.EMERGE_CANCELLED or action == minetest.EMERGE_ERRORED then
					self.emergeFailed = true
					sb2.log("warning", "Failed to emerge scriptblock at %s", minetest.pos_to_string(pos))
				end
			end)
			self.requestedEmerge = true
			sb2.log("info", "Requested to emerge scriptblock at %s", minetest.pos_to_string(pos))
			return nil
		elseif self.emergeFailed then
			return false
		else
			return nil
		end
	else
		return node
	end
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


minetest.register_on_joinplayer(function (player)
	local name = player:get_player_name()
	sb2.Process.starterInfo[name] = {
		processes = {},
		processCount = 0
	}
end)
minetest.register_on_leaveplayer(function (player)
	local name = player:get_player_name()
	
	sb2.Process:stopAllProcessesFor(name)
	sb2.Process.starterInfo[name] = nil
end)

local i = 1
minetest.register_globalstep(function ()
	local processes = sb2.Process.processList
	
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