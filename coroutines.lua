sb2.colors.coroutines = "#fce762"

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
	return self.closure:doCall(process, self.context, self.arg)
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
	self.coroutine:hasFinished()
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
	self.finished = false
end
function sb2.Coroutine:copy()
	if self.process[1] and not self.process[1]:isHalted() then return end
	
	local copy = self:getClass():new(self.frame and self.frame:copy())
	copy.finished = self.finished
	
	return copy
end

function sb2.Coroutine:doResume(process, arg)
	if self.process[1] and not self.process[1]:isHalted() or self.finished then return process:receiveArg(nil) end
	
	self.process[1] = process
	
	process:push(sb2.CoroutineDelimiterFrame:new(self))
	
	process:pushAll(self.frame)
	return process:receiveArg(arg)
end
function sb2.Coroutine:doCall(process, context, arg)
	return self:doResume(process, arg)
end

function sb2.Coroutine:doYield(process, value)
	if process ~= self.process[1] then return end
	
	self.frame = process:unwind(function (f) return f.getDelimiteeCoroutine and f:getDelimiteeCoroutine() == self end)
	self.process[1] = nil
	
	return process:report(value)
end
function sb2.Coroutine:getState()
	if self.process[1] and not self.process[1]:isHalted() then
		return "running"
	elseif not self.finished then
		return "paused"
	else
		return "finished"
	end
end

function sb2.Coroutine:hasFinished()
	self.frame = nil
	self.process[1] = nil
	self.finished = true
end

function sb2.Coroutine:recordString(record)
	return "<coroutine>"
end


sb2.registerScriptblock("scriptblocks2:create_new_coroutine", {
	sb2_label = "Create New Coroutine",
	
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
	sb2_icon  = "sb2_icon_program_point.png",
	sb2_slotted_faces = {"right"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated("closure") then
			frame:selectArg("closure")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		
		local closure = frame:getArg("closure")
		if type(closure) ~= "table" or not closure.doCall then return process:report(nil) end
		
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
		
		if type(coro) ~= "table" or not coro.doYield then
			local value = frame:getArg("arg")
			
			if value ~= nil then
				process:log("Yielded: %s", sb2.toString(value))
			end
			
			process:yield()
			return process:report(nil)
		end
		
		process:pop()
		return coro:doYield(process, frame:getArg("arg"))
	end
})

sb2.registerScriptblock("scriptblocks2:get_coroutine_state", {
	sb2_label = "Get Coroutine State",
	
	sb2_explanation = {
		shortExplanation = "Reports 'running', 'paused' or 'finished' depending on the state of the given coroutine.",
		inputSlots = {
			{"Right", "The coroutine to check."},
		},
		additionalPoints = {
			"Dead coroutines will report nil if they are resumed again.",
		},
	},
	
	sb2_color = sb2.colors.coroutines,
	sb2_icon  = "sb2_icon_get_coroutine_state.png",
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

sb2.registerScriptblock("scriptblocks2:clone_coroutine", {
	sb2_label = "Clone Coroutine",
	
	sb2_explanation = {
		shortExplanation = "Reports a clone of the given coroutine.",
		inputSlots = {
			{"Right", "The coroutine to clone."},
		},
		additionalPoints = {
			"Any variables, lists, etc. are shared between the original and the clone - this may result in very strange effects!",
			"Running coroutines cannot currently be cloned.",
		},
	},
	
	sb2_color = sb2.colors.coroutines,
	sb2_icon  = "sb2_icon_clone.png",
	sb2_slotted_faces = {"right"},
	
	sb2_action = sb2.simple_action {
		arguments = {"right"},
		action = function (pos, node, process, frame, context, coro)
			if type(coro) ~= "table" or not coro.copy then return end
			return coro:copy()
		end
	}
})