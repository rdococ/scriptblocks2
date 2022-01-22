sb2.colors.coroutines = "#cafcab"

sb2.CoroutineStartFrame = sb2.registerClass("CoroutineStartFrame")

function sb2.CoroutineStartFrame:initialize(context, closure)
	self.closure = closure
	self.context = context
	
	self.parent = nil
	
	self.arg = nil
end

function sb2.CoroutineStartFrame:copy()
	local newFrame = self:getClass():new()
	newFrame.closure = self.closure
	newFrame.parent = self.parent and self.parent:copy()
end
function sb2.CoroutineStartFrame:step(process)
	process:pop()
	return self.closure:callClosure(process, self.context, self.arg)
end
function sb2.CoroutineStartFrame:receiveArg(arg)
	self.arg = arg
end

function sb2.CoroutineStartFrame:getParent()
	return self.parent
end
function sb2.CoroutineStartFrame:setParent(parent)
	self.parent = parent
end

function sb2.CoroutineStartFrame:getContext()
	return self.context
end


sb2.CoroutineDelimiterFrame = sb2.registerClass("coroutineDelimiterFrame")

function sb2.CoroutineDelimiterFrame:initialize(coro)
	self.coroutine = coro
	
	self.parent = nil
	self.arg = nil
end

function sb2.CoroutineDelimiterFrame:copy()
	local newFrame = self:getClass():new()
	newFrame.coroutine = self.coroutine
	newFrame.parent = self.parent and self.parent:copy()
end
function sb2.CoroutineDelimiterFrame:step(process)
	self.coroutine:hasDied()
	return process:report(self.arg)
end
function sb2.CoroutineDelimiterFrame:receiveArg(arg)
	self.arg = arg
end

function sb2.CoroutineDelimiterFrame:getParent()
	return self.parent
end
function sb2.CoroutineDelimiterFrame:setParent(parent)
	self.parent = parent
end

function sb2.CoroutineDelimiterFrame:getDelimiteeCoroutine()
	return self.coroutine
end


sb2.Coroutine = sb2.registerClass("Coroutine")

function sb2.Coroutine:initialize(frame)
	self.frame = frame
	self.process = setmetatable({}, {__mode = "k"})
	self.dead = false
end
function sb2.Coroutine:copy()
	if self.process[1] and not self.process[1]:isHalted() then return end
	
	local copy = self:getClass():new(self.frame and self.frame:copy())
	copy.dead = self.dead
end

function sb2.Coroutine:resume(process, arg)
	if self.process[1] and not self.process[1]:isHalted() or self.dead then return process:receiveArg(nil) end
	
	self.process[1] = process
	
	process:push(sb2.CoroutineDelimiterFrame:new(self))
	
	process:pushAll(self.frame)
	return process:receiveArg(arg)
end
function sb2.Coroutine:callClosure(process, context, arg)
	return self:resume(process, arg)
end

function sb2.Coroutine:yield(process, value)
	if process ~= self.process[1] then return end
	
	self.frame = process:unwind(function (f) return f.getDelimiteeCoroutine and f:getDelimiteeCoroutine() == self end)
	self.process[1] = nil
	
	return process:report(value)
end
function sb2.Coroutine:getState()
	if self.process[1] and not self.process[1]:isHalted() then
		return "running"
	elseif not self.dead then
		return "suspended"
	else
		return "dead"
	end
end

function sb2.Coroutine:hasDied()
	self.frame = nil
	self.process[1] = nil
	self.dead = true
end

function sb2.Coroutine:recordString(record)
	return "<coroutine>"
end


sb2.registerScriptblock("scriptblocks2:create_coroutine", {
	sb2_label = "Create Coroutine",
	
	sb2_explanation = {
		shortExplanation = "Creates and reports a new coroutine.",
		inputSlots = {
			{"Right", "The closure for the coroutine to run."},
		},
		additionalPoints = {
			"A coroutine is a special kind of closure that can pause itself and be resumed.",
			"This coroutine will not start running immediately. Call it like a regular closure to resume it."
		},
	},
	
	sb2_color = sb2.colors.coroutines,
	sb2_icon  = "sb2_icon_flag.png",
	sb2_slotted_faces = {"right"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated("closure") then
			frame:selectArg("closure")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		
		local closure = frame:getArg("closure")
		if type(closure) ~= "table" or not closure.callClosure then return process:report(nil) end
		
		local coro = sb2.Coroutine:new(sb2.CoroutineStartFrame:new(context, closure))
		return process:report(coro)
	end
})

sb2.registerScriptblock("scriptblocks2:yield_from_coroutine", {
	sb2_label = "Yield From Coroutine",
	
	sb2_explanation = {
		shortExplanation = "Pauses the current coroutine, passing a value back to the caller.",
		inputSlots = {
			{"Right", "The value to report back to the caller."},
		},
		additionalPoints = {
			"When the coroutine is called again, it will continue from this point.",
			"The value passed to that call will be reported by this block.",
		},
	},
	
	sb2_color = sb2.colors.coroutines,
	sb2_icon  = "sb2_icon_pause.png",
	sb2_slotted_faces = {"right"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated("arg") then
			frame:selectArg("arg")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		
		local delimiter = process:find(function (f) return f.getDelimiteeCoroutine end)
		local coro = delimiter and delimiter:getDelimiteeCoroutine()
		
		if type(coro) ~= "table" or not coro.yield then return process:report(nil) end
		
		process:pop()
		return coro:yield(process, frame:getArg("arg"))
	end
})

sb2.registerScriptblock("scriptblocks2:get_coroutine_state", {
	sb2_label = "Get Coroutine State",
	
	sb2_explanation = {
		shortExplanation = "Reports 'running', 'suspended' or 'dead' depending on the state of the given coroutine.",
		inputSlots = {
			{"Right", "The coroutine to check."},
		},
		additionalPoints = {
			"Dead coroutines will report nil if they are resumed again.",
		},
	},
	
	sb2_color = sb2.colors.coroutines,
	sb2_icon  = "sb2_icon_is_process_running.png",
	sb2_slotted_faces = {"right"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated("coroutine") then
			frame:selectArg("coroutine")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		
		local coro = frame:getArg("coroutine")
		if type(coro) ~= "table" or not coro.getState then return process:report(nil) end
		
		return process:report(coro:getState())
	end
})