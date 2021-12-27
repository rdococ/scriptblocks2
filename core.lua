--[[
	Scriptblocks2 Core
	
	This is the core of the mod. It defines the API for manipulating processes and stack frames used by scriptblocks,
	and is also responsible for stepping through each process on each globalstep.
]]


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
		Performs one execution step. If this method returns "halt", the process is done and dead. If it returns "yield", it is waiting for something else to happen and thus requires no more execution steps until the next Minetest tick.
]]

sb2.Process = class.register("process")
sb2.Process.runningProcesses = {}

function sb2.Process:initialize(frame)
	self.frame = frame
	self.eventQueue = {}
	
	sb2.log("action", "Process started at %s", minetest.pos_to_string(frame.pos))
	
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
		sb2.log("action", "Process at %s reported %s", minetest.pos_to_string(self.frame.pos), tostring(value))
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
	local oldFrame = self.frame
	if not oldFrame then return "halt" end
	
	local pos = oldFrame.pos
	
	local node = minetest.get_node(pos)
	local nodename = node.name
	
	if nodename == "ignore" then
		if not minetest.forceload_block(pos, true) then return "yield" end
		
		node = minetest.get_node(pos)
		nodename = node.name
		
		if nodename == "ignore" then return "yield" end
	end
	
	local def = minetest.registered_nodes[nodename]
	
	local action
	if def and def.sb2_action then
		action = def.sb2_action(pos, node, self, oldFrame, oldFrame:getContext())
	else
		action = self:report(nil)
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
	
	return action
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

sb2.Frame = class.register("frame")

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

sb2.Context = class.register("context")

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


minetest.register_globalstep(function ()
	local processes = sb2.Process.runningProcesses
	local numProcesses = #processes
	
	for i, process in pairs(processes) do
		for _ = 1, math.max(1000 / numProcesses, 1) do
			local action = process:step()
			if action == "halt" then
				processes[i] = nil
				break
			elseif action == "yield" then
				break
			end
		end
	end
end)