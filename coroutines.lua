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
			"A coroutine is a special kind of closure that can be paused and resumed.",
			"A coroutine can pause itself with 'Call/Run Out Of Coroutine', reporting back to its caller.",
			"The caller can resume the coroutine, which will then continue from where it left off.",
			"The coroutine starts out paused, so make sure to 'Call/Run Into Coroutine' to start it up.",
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

sb2.registerScriptblock("scriptblocks2:call_into_coroutine", {
	sb2_label = "Call Into Coroutine",
	
	sb2_explanation = {
		shortExplanation = "Resumes a coroutine and reports its next yielded value.",
		inputSlots = {
			{"Front", "The coroutine to resume."},
			{"Right", "The value to pass to the coroutine."},
		},
	},
	
	sb2_color = sb2.colors.coroutines,
	sb2_icon  = "sb2_icon_invoke_continuation.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated("coroutine") then
			frame:selectArg("coroutine")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context))
		end
		if not frame:isArgEvaluated(1) then
			frame:selectArg(1)
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		
		local coro = frame:getArg("coroutine")
		if type(coro) ~= "table" or not coro.doCall then return process:report(nil) end
		
		process:pop()
		return coro:doCall(process, context, frame:getArg(1))
	end,
})
sb2.registerScriptblock("scriptblocks2:run_into_coroutine", {
	sb2_label = "Run Into Coroutine",
	
	sb2_explanation = {
		shortExplanation = "Resumes a coroutine, and continues after the coroutine yields.",
		inputSlots = {
			{"Left", "The coroutine to resume."},
			{"Right", "The value to pass to the coroutine."},
			{"Front", "What to do next."},
		},
	},
	
	sb2_color = sb2.colors.coroutines,
	sb2_icon  = "sb2_icon_run_coroutine.png",
	sb2_slotted_faces = {"left", "right", "front"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated("coroutine") then
			frame:selectArg("coroutine")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.left), context))
		end
		if not frame:isArgEvaluated(1) then
			frame:selectArg(1)
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		if not frame:isArgEvaluated("value") then
			frame:selectArg("value")
			
			local coro = frame:getArg("coroutine")
			if type(coro) ~= "table" or not coro.doCall then process:pop(); return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context)) end
			
			return coro:doCall(process, context, frame:getArg(1))
		end
		
		process:pop()
		return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context))
	end,
})

sb2.registerScriptblock("scriptblocks2:call_out_of_coroutine", {
	sb2_label = "Call Out Of Coroutine",
	
	sb2_explanation = {
		shortExplanation = "Pauses the current coroutine, optionally reporting a value back to the caller.",
		inputSlots = {
			{"Right", "The value to report back to the caller."},
		},
		additionalPoints = {
			"When the coroutine is resumed again, it will continue from this point.",
			"This block will report the value passed back to the coroutine when resumed.",
		},
	},
	
	sb2_color = sb2.colors.coroutines,
	sb2_icon  = "sb2_icon_yield_from_coroutine.png",
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
sb2.registerScriptblock("scriptblocks2:run_out_of_coroutine", {
	sb2_label = "Run Out Of Coroutine",
	
	sb2_explanation = {
		shortExplanation = "Pauses the current coroutine, optionally reporting a value back to the caller.",
		inputSlots = {
			{"Right", "The value to report back to the caller."},
			{"Front", "What to do when this coroutine is resumed."},
		},
		additionalPoints = {
			"When the coroutine is resumed again, it will continue from this point.",
			"This block will continue the script when the coroutine is resumed, without reporting any value.",
		},
	},
	
	sb2_color = sb2.colors.coroutines,
	sb2_icon  = "sb2_icon_yield_from_coroutine_then_continue.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated("arg") then
			frame:selectArg("arg")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		if not frame:isArgEvaluated("value") then
			local delimiter = process:find(function (f) return f.getDelimiteeCoroutine end)
			local coro = delimiter and delimiter:getDelimiteeCoroutine()
			
			if type(coro) ~= "table" or not coro.doYield then
				local value = frame:getArg("arg")
				
				if value ~= nil then
					process:log("Yielded: %s", sb2.toString(value))
				end
				
				process:yield()
				process:pop()
				return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context))
			end
			
			frame:selectArg("value")
			
			return coro:doYield(process, frame:getArg("arg"))
		end
		
		process:pop()
		process:push(sb2.Frame:new(vector.add(pos, dirs.front), context))
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
			"This block can be used to implement multi-shot continuations!",
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