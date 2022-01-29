--[[
	Scriptblocks2 Core
	
	This is the core of the mod. It defines the API for manipulating processes and stack frames used by scriptblocks,
	and is also responsible for stepping through each process on each globalstep.
]]

local settings = minetest.settings
local maxSteps = tonumber(settings:get("scriptblocks2_max_steps")) or 10000
local maxMemory = tonumber(settings:get("scriptblocks2_max_memory")) or 100000
local maxProcesses = tonumber(settings:get("scriptblocks2_max_processes")) or 500

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
	isDebugging()
		Returns true if debug information should be logged to the starter of the process.
	
	getFrame()
		Returns the process's current evaluation frame.
	
	push(frame)
		Pushes the given frame onto the stack; i.e. the new frame is evaluated, and once finished, control returns to the current frame. Think of this like a function call.
	pop()
		Pops the current frame without providing a value. May be used for tail calls, or replacing a frame with a different type of frame before evaluating something on top of it.
	
	receiveArg(value)
		Reports an evaluated value to the current evaluation frame, usually after it has requested to evaluate something.
	
	report(value)
		Pops the current frame and provides a value to the previous frame. This is like returning from a function call.
		This is equivalent to pop(); receiveArg(value), but it is very commonly used.
	
	find(criteria)
		Finds the nearest call stack frame that fits the specified criteria.
	unwind(criteria)
		Unwinds the call stack until a frame fits the specified criteria, returning the resulting captured slice. The unwound slice *excludes* the marked frame. This is like throwing an exception, and the return value is similar to a delimited continuation.
		The unwound(slice) method is called on each frame (where it is present) in the order of unwinding (from the top frame downwards). This is used by coroutines to force themselves to yield when some other mechanism transfers control away from them. The 'slice' in these method calls is a partial slice that stops short of the current frame - however, it will be mutated into the full captured slice, so frames looking to save these partial slices should copy them first.
		If criteria is not present, then the whole call stack will be unwound. This is done when a process is halted so all running coroutines (and other things) have a chance to pause themselves.
	rewind(frame)
		Rewinds the captured slice back onto the call stack. The rewound(process) method is called on each frame (where it is present) in the reverse order of rewinding (so from frame downwards). If a frame returns 'true', the slice will 'crash' and be cut off there - this is used by coroutines to prevent rewinding into an already running coroutine.
		If the frame is not present, it is interpreted as an empty slice and nothing is done.
	
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
			"StoppedByOtherProcess"
				This process was stopped by another process.
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

sb2.Process.shouldNotScan = function (x) return x.isProcess and x:isProcess() and not x:isHalted() end

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
		
		if processCount >= maxProcesses then
			sb2.log("action", "%s could not start another process at %s", self.starter or "(unknown)", minetest.pos_to_string(frame:getPos()))
			return self:halt("TooManyProcesses")
		end
		
		starterInfo.processes[self] = true
		starterInfo.processCount = processCount + 1
	end
	
	self.frame = frame
	
	self.memoryScanner = sb2.RecursiveIterator:new(self, self:getClass().shouldNotScan)
	
	self.memoryUsage = 0
	self.newMemoryUsage = 0
	
	self.yielding = false
	self.halted = false
	
	self:log("Started.")
	sb2.log("action", "Process started by %s at %s", self.starter or "(unknown)", minetest.pos_to_string(frame:getPos()))
	
	table.insert(sb2.Process.processList, self)
end

function sb2.Process:isProcess()
	return true
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

function sb2.Process:getFrame()
	return self.frame
end

function sb2.Process:push(frame)
	frame:setParent(self.frame)
	self.frame = frame
end
function sb2.Process:pop()
	self.frame = self.frame:getParent()
end

function sb2.Process:receiveArg(value)
	if self.frame then
		return self.frame:receiveArg(value)
	else
		self:log("Reported: %s", {prettyprint = true, value = value})
		if self.frame and self.frame.getPos then
			sb2.log("action", "Process at %s reported %s", minetest.pos_to_string(self.frame:getPos()), tostring(value))
		else
			sb2.log("action", "Process at unknown location reported %s", tostring(value))
		end
	end
end
function sb2.Process:report(value)
	self:pop()
	return self:receiveArg(value)
end

function sb2.Process:find(criteria)
	local markedFrame = self.frame
	
	while markedFrame and not criteria(markedFrame) do
		markedFrame = markedFrame:getParent()
	end
	
	return markedFrame
end

function sb2.Process:unwind(criteria)
	local topFrame, markedFrame, afterFrame = self.frame, self.frame
	local data = {}
	
	while markedFrame and (not criteria or not criteria(markedFrame)) do
		if markedFrame and markedFrame.unwound then
			local partialSlice
			if afterFrame then
				partialSlice = topFrame
				afterFrame:setParent(nil)
			end
			
			markedFrame:unwound(partialSlice, data)
			
			if afterFrame then
				afterFrame:setParent(markedFrame)
			end
		end
		
		afterFrame = markedFrame
		markedFrame = markedFrame:getParent()
	end
	
	if markedFrame then
		self.frame = markedFrame
		if afterFrame then afterFrame:setParent(nil) end
	else
		self.frame = nil
	end
	
	return markedFrame ~= topFrame and topFrame or nil, data
end
function sb2.Process:rewind(frame)
	if frame == nil then return end
	
	local ancestor, newFrame = frame, frame
	
	while true do
		if ancestor and ancestor.rewound then
			local crash = ancestor:rewound(self)
			if crash then
				-- Crash - e.g. a coroutine is already running and thus cannot be resumed into
				-- 'Cap' the rewind at this frame's parent, as it cannot be entered
				newFrame = ancestor:getParent()
			end
		end
		
		local newAncestor = ancestor:getParent()
		if newAncestor then
			ancestor = newAncestor
		else break end
	end
	
	ancestor:setParent(self.frame)
	self.frame = newFrame
end

function sb2.Process:step()
	if self.halted then return end
	self.yielding = false
	
	local frame = self.frame
	if not frame then return self:halt() end
	
	frame:step(self)
	frame = self.frame
	
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
			
			self.memoryScanner = sb2.RecursiveIterator:new(self, self:getClass().shouldNotScan)
			self.newMemoryUsage = 0
		end
		if math.max(self.memoryUsage, self.newMemoryUsage) > maxMemory then
			return self:halt("OutOfMemory")
		end
	end
end

function sb2.Process:halt(reason)
	if self.halted then return end
	self.halted = reason or true
	
	-- Unwind the call stack. This gives a chance for e.g. coroutines to pause themselves.
	self:unwind()
	
	if self.starter then
		local starterInfo = sb2.Process.starterInfo[self.starter]
		
		if starterInfo.processes[self] then
			starterInfo.processCount = starterInfo.processCount - 1
			starterInfo.processes[self] = nil
		end
	end
	
	if self.halted == "TooManyProcesses" then
		self:log("You have too many processes!")
	elseif self.halted == "OutOfMemory" then
		self:log("Ran out of memory.")
	elseif self.halted == "StoppedManually" then
		self:log("Stopped manually.")
	elseif self.halted == "StoppedByOtherProcess" then
		self:log("Stopped by other process.")
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
	return self.halted
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

function sb2.Process:recordString(record)
	return "<process>"
end


--[[
Frame

A frame is a single unit of evaluation in a scriptblocks2 program. A frame stores the position of the node it is evaluating, the context of variables it is doing so in, and the parent frame which it will eventually report back to. It also stores a set of arguments, temporary storage where scriptblocks can store values for later evaluation steps or receive values reported from elsewhere.

Extensions may define their own types of frame to implement custom behaviours. When interacting with frames outside the current frame, scriptblocks can only be sure that the basic methods exist.

Basic interface:
	These are methods that must be implemented by all types of frame.
	
	copy()
		Copies this frame recursively. The resulting frame can be restored with process:continue(), acting as a continuation.
	
	getParent()
		Returns the frame that this frame will eventually report back to.
	setParent(parent)
		Sets this frame's parent, causing it to report back to that frame when done.
	
	receiveArg(value)
		Receives a value. The default frame type stores it in the selected argument and marks it as evaluated.
	
	step(process)
		Runs an execution step. The default frame type attempts to load the node at its position, and runs its sb2_action property to decide what to do.
	
	unwound(slice, data)
	rewound(process)
		These two methods are called when your frame is unwound or rewound respectively. Coroutines use this to yield when a continuation jumps out of them, and to make sure they aren't already running when a continuation jumps into them.
		'data' is a table passed to every frame along the way. Coroutines use this to coordinate - if a continuation jumps out of two coroutines, the inner coroutine will set data.coroutineFrame. The outer coroutine will be able to see it, and only save the stack up to the start of the inner coroutine. This ensures that coroutines don't save frames belonging to other coroutines, which causes odd behaviour.
		These two methods are optional - the default frame type doesn't implement them.

Frame interface:
	These are methods that this type of frame implements for scriptblocks to use. Other types of frame don't have to implement these.
	
	getPos()
		Returns the position of the node this frame is evaluating.
	
	getContext()
		Returns the context of this evaluation frame. This consists of variables, the top block that began the current procedure, and the player blamed for building the current procedure.
	
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
	
	requestNode()
		Attempts to emerge the node at this frame's position. Internal.
]]

sb2.Frame = sb2.registerClass("frame")

function sb2.Frame:initialize(pos, context)
	self.pos = pos
	self.context = context
	self.parent = nil
	
	self.arguments = {}
	self.argsEvaluated = {}
	self.selectedArg = nil
	
	self.marker = nil
	
	self.requestedEmerge = false
	self.emergeFailed = false
end

function sb2.Frame:copy()
	local copy = self:getClass():new(self.pos, self.context)
	copy.parent = self.parent and self.parent:copy()
	
	copy.selectedArg = self.selectedArg
	
	for arg, _ in pairs(self.argsEvaluated) do
		copy.arguments[arg] = self.arguments[arg]
		copy.argsEvaluated[arg] = true
	end
	
	copy.marker = self.marker
	
	copy.requestedEmerge = false
	copy.emergeFailed = false
	
	return copy
end
function sb2.Frame:step(process)
	local pos = self.pos
	local node = self:requestNode()
	
	if node == nil then return process:yield() end
	if node == false then
		process:log("Failed to load block at %s", minetest.pos_to_string(pos))
	end
	
	local nodename = node and node.name or "ignore"
	
	local def = minetest.registered_nodes[nodename]
	if def and def.sb2_action then
		return def.sb2_action(pos, node, process, self, self:getContext())
	else
		return process:report(nil)
	end
end
function sb2.Frame:receiveArg(value)
	self.arguments[self.selectedArg] = value
	self.argsEvaluated[self.selectedArg] = true
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

function sb2.Frame:recordString(record)
	record[self] = true
	return string.format("<frame %s -> %s", minetest.get_node(self.pos).name, sb2.toString(self.parent, record))
end


--[[
Context

A context is a lexical context within a scriptblocks2 program. Contexts store variables, the head of the current procedure and the player that owns it. Multiple evaluation frames may share the same context, or have separate contexts but share variable objects.

Methods:
	copy()
		Copies the context, creating a new context which shares the same variables and head, but not owner. New variables declared in the original context do not transfer over to the copy, but if an existing variable is mutated, that change will be visible.
	
	getOwner()
		Gets the player blamed for building the scriptblocks running in this context.
	setOwner(owner)
		Sets the owner blamed for building these scriptblocks.
	getHead()
		Gets the initial position of the context.
	setHead(head)
		Sets the initial position of the context.
	
	declareVar(varname, value)
		Declares a new variable with the given variable name.
	getVar(varname)
		Returns the variable table with that name (a table of the form {value = ...}).
	
	getAttribute(attribute)
		Gets an attribute of this context. Variables are stored in attributes named "variables:<varname>". Other attributes can be used to hold lexical information that can't be accessed by the variable blocks.
		Owner and head are stored in the attributes "builtin:owner" and "builtin:head".
	setAttribute(attribute, value)
		Sets an attribute.
]]

sb2.Context = sb2.registerClass("context")

function sb2.Context:initialize(head, owner)
	self.attributes = {}
	
	self:setHead(head)
	self:setOwner(owner)
end

function sb2.Context:copy()
	local copy = self:getClass():new()
	local record = {}
	
	for k, v in pairs(self.attributes) do
		if type(v) == "table" and sb2.getClassName(v) and v.copyForContext then
			v = v:copyForContext(record)
		end
		copy.attributes[k] = v
	end
	
	return copy
end

function sb2.Context:getOwner()
	return self.attributes["builtin:owner"]
end
function sb2.Context:setOwner(owner)
	self.attributes["builtin:owner"] = owner
end
function sb2.Context:getHead()
	return self.attributes["builtin:head"]
end
function sb2.Context:setHead(head)
	self.attributes["builtin:head"] = head
end

function sb2.Context:getAttribute(varname)
	return self.attributes[varname]
end
function sb2.Context:setAttribute(varname, value)
	self.attribute[varname] = value
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
	local processCount = #processes
	
	local step = 1
	
	local yielders = {}
	
	while processCount > 0 and step <= maxSteps do
		local process = processes[i]
		
		if not yielders[process] then
			process:step()
			if process:isHalted() then
				table.remove(processes, i)
				i = i - 1
				processCount = processCount - 1
			elseif process:isYielding() then
				yielders[process] = true
			end
		end
		
		i = i + 1
		if i > processCount then i = 1 end
		
		step = step + 1
	end
end)