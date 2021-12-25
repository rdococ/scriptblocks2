--[[
	Scriptblocks2 Core
	
	This is the core of the mod. It defines the API for manipulating processes and stack frames used by scriptblocks,
	and is also responsible for stepping through each process on each globalstep.
]]

--[[
	Processes
	
	Processes are active threads running scriptblocks2 programs.
	Each process manages a spaghetti stack of frames. The top frame in each process is executed every globalstep.
	
	frame
		The current evaluation frame; what the process is going to evaluate in the next step.
	queue
		A queue of events this process has received and not yet handled.
	
	pushFrame
		Pushes a new frame to the stack to evaluate it; essentially, asking the process to evaluate something else before coming back.
	selectArg
		Allows a frame to select an argument the value should return to.
	replaceFrame
		Replaces the current frame with a new one; essentially, a tail recursive evaluation. It's used for 'command' blocks, which are really just special forms that evaluate their continuation last.
	reportValue
		Reports a value from the current frame to the parent frame's desired argument, popping it in the process.
	
	queueEvent
		Queues an event onto the given process.
	handleEvent
		Finds the first event that satisfies a given criterium, pops and returns it.
	
	Currently, at the end of each step, the event queue is cleared.
]]
sb2.runningProcesses = {}

function sb2.createProcess(frame, starter)
	local process = {}
	
	process.frame = frame
	process.queue = {}
	
	process.starter = starter
	
	table.insert(sb2.runningProcesses, process)
	return process
end
function sb2.pushFrame(process, frame)
	frame.parent = process.frame
	process.frame = frame
end
function sb2.replaceFrame(process, frame)
	frame.parent = process.frame.parent
	process.frame = frame
end
function sb2.reportValue(process, value)
	local frame = process.frame
	
	if frame.parent then
		local parent = frame.parent
		parent.arguments[parent.argument] = value
		parent.argsEvaluated[parent.argument] = true
	end
	
	process.frame = frame.parent
end
function sb2.getStarter()
	return process.starter
end
function sb2.queueEvent(process, event)
	table.insert(process.queue, event)
end
function sb2.handleEvent(process, criteria)
	for i, event in ipairs(process.queue) do
		if criteria(event) then
			table.remove(process.queue, i)
			return event
		end
	end
end
function sb2.stepProcess(process)
	local oldFrame = process.frame
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
		action = def.sb2_action(pos, node, process, oldFrame)
	else
		action = sb2.reportValue(process, nil)
	end
	
	for i = 1, #process.queue do
		table.remove(process.queue, 1)
	end
	
	if not process.frame or not vector.equals(pos, process.frame.pos) then
		minetest.forceload_free_block(pos, true)
		if process.frame then
			minetest.forceload_block(process.frame.pos, true)
		end
	end
	
	return action
end

--[[
	Frames
	
	Frames are the basic unit of execution. Each frame may have a parent to report to, has an environment of variables, and a position indicating the node currently being executed.
	
	Args are a mechanism that enables a node to schedule other nodes to run, and then do something with the reported value. Use isArgEvaluated to detect if the argument already has a value. Use selectArg to select an argument name to report the value to, and then use pushFrame to push the next frame on.
	
	getArg
		Gets the value of an argument.
	setArg
		Sets the value of an argument.
	isArgEvaluated
		Checks if the argument has been evaluated.
	selectArg
		Selects an argument for a new stack frame to report its value back to.
	
	declareVar
		Defines a variable in this frame's environment.
	getVar
		Gets the variable object - you can use .value to set or get its value.
	
	getOwner
		Gets the user that created the stack frame this procedure is in.
	getPos
		Gets the position of the node this stack frame is located in.
	getHead
		Gets the head position of the stack frame.
		i.e. The position that started this top-level procedure.
]]
function sb2.createFrame(pos, outer, owner, copyEnv)
	local frame = {}
	
	frame.parent = parent
	
	frame.pos = pos
	
	frame.arguments = {}
	frame.argsEvaluated = {}
	frame.argument = nil
	
	frame.environment = outer and (copyEnv and sb2.shallowCopy(outer.environment) or outer.environment) or {}
	frame.owner = owner or (outer and outer.owner or nil)
	
	frame.head = outer and outer.head or pos
	
	return frame
end
function sb2.getArg(frame, argname)
	return frame.arguments[argname]
end
function sb2.setArg(frame, argname, value)
	frame.arguments[argname] = value
end
function sb2.isArgEvaluated(frame, argname)
	return frame.argsEvaluated[argname]
end
function sb2.selectArg(frame, argname)
	frame.argument = argname
end
function sb2.declareVar(frame, name, value)
	frame.environment[name] = {value = value}
	return frame.environment[name]
end
function sb2.getVar(frame, name)
	return frame.environment[name]
end
function sb2.getOwner(frame)
	return frame.owner
end
function sb2.getPos(frame)
	return frame.pos
end
function sb2.getHead(frame)
	return frame.head
end

minetest.register_globalstep(function ()
	local processes = sb2.runningProcesses
	local numProcesses = #processes
	
	for i, process in pairs(processes) do
		for _ = 1, math.max(1000 / numProcesses, 1) do
			local action = sb2.stepProcess(process)
			if action == "halt" then
				processes[i] = nil
				break
			elseif action == "yield" then
				break
			end
		end
	end
end)