sb2.colors.coroutines = "#fce762"

sb2.CoroutineStartFrame = sb2.registerClass("coroutineStartFrame")

function sb2.CoroutineStartFrame:initialize(context, closure)
	self.closure = closure
	self.context = context
	
	self.parent = nil
	
	self.arg = nil
end
function sb2.CoroutineStartFrame:copy(record)
	record = record or {}
	record[self.context] = record[self.context] or self.context:copy()
	
	local newFrame = self:getClass():new(record[self.context], self.closure)
	newFrame.parent = self.parent and self.parent:copy(record)
	
	return newFrame
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

function sb2.CoroutineStartFrame:recordString(record)
	record[self] = true
	return string.format("<coroutine start frame -> %s", sb2.toString(self.parent, record))
end


sb2.CoroutineBaseFrame = sb2.registerClass("coroutineBaseFrame")

function sb2.CoroutineBaseFrame:initialize(coro)
	self.coroutine = coro
	
	self.parent = nil
	self.arg = nil
end
function sb2.CoroutineBaseFrame:copy(record)
	local newFrame = self:getClass():new()
	newFrame.coroutine = self.coroutine
	newFrame.parent = self.parent and self.parent:copy(record)
	
	return newFrame
end

function sb2.CoroutineBaseFrame:step(process)
	self.coroutine:hasFinished()
	return process:report(self.arg)
end
function sb2.CoroutineBaseFrame:receiveArg(arg)
	self.arg = arg
end

function sb2.CoroutineBaseFrame:getParent()
	return self.parent
end
function sb2.CoroutineBaseFrame:setParent(parent)
	self.parent = parent
end

function sb2.CoroutineBaseFrame:getBaseFrameCoroutine()
	return self.coroutine
end

function sb2.CoroutineBaseFrame:unwound(slice, data)
	-- If another coroutine has already been unwound, cap our slice so we don't resume any of their frames
	self.coroutine:forceYield(data.coroutineFrame and data.coroutineFrame:getParent() or slice, data.coroutineFrame and data.coroutineFrame:getBaseFrameCoroutine() or nil)
	data.coroutineFrame = self
end
function sb2.CoroutineBaseFrame:rewound(process)
	return self.coroutine:forceResume(process)
end

function sb2.CoroutineBaseFrame:recordString(record)
	record[self] = true
	return string.format("<coroutine delimiter frame %s -> %s", sb2.toString(self.coroutine, record), sb2.toString(self.parent, record))
end


sb2.Coroutine = sb2.registerClass("coroutine")

function sb2.Coroutine:initialize(frame)
	-- Remember this coroutine's saved top frame.
	self.frame = frame
	-- Remember if this coroutine is running, and what process it's running in.
	self.process = nil
	-- Remember if this coroutine has finished.
	self.finished = false
	-- If some external force forces us to yield, remember which coroutine we were in.
	self.resumeNext = nil
end
function sb2.Coroutine:copy()
	if self.process and not self.process:isHalted() then return end
	
	local copy = self:getClass():new(self.frame and self.frame:copy())
	copy.finished = self.finished
	
	return copy
end

function sb2.Coroutine:doResume(process, arg)
	if self.process and not self.process:isHalted() or self.finished then return process:receiveArg(nil) end
	self.process = process
	
	process:push(sb2.CoroutineBaseFrame:new(self))
	process:rewind(self.frame)
	
	if self.resumeNext then
		return self.resumeNext:doResume(process, nil)
	end
	
	return process:receiveArg(arg)
end
function sb2.Coroutine:doCall(process, context, arg)
	return self:doResume(process, arg)
end

function sb2.Coroutine:doYield(process, value, data)
	if process ~= self.process then return end
	
	self.frame = data and data.coroutineFrame and data.coroutineFrame:getParent() or process:unwind(function (f) return f.getBaseFrameCoroutine and f:getBaseFrameCoroutine() == self end)
	self.process = nil
	
	return process:report(value)
end
function sb2.Coroutine:getState()
	if self.process and not self.process:isHalted() then
		return "running"
	elseif not self.finished then
		return "paused"
	else
		return "finished"
	end
end

function sb2.Coroutine:forceYield(slice, resumeNext)
	-- This coroutine has been forced to yield. Take a copy of our slice and remember to resume the coroutine we were just in if we get resumed.
	self.frame = slice and slice:copy()
	self.process = nil
	self.resumeNext = resumeNext
end
function sb2.Coroutine:forceResume(process)
	-- If this coroutine is already running, you can't rewind into it!
	if self.process then return true end
	self.process = process
end

function sb2.Coroutine:hasFinished()
	self.frame = nil
	self.process = nil
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
			"A coroutine is a special kind of closure that can exit and then be re-entered later.",
			"A coroutine can report back to its caller with 'Call/Run Out Of Coroutine', pausing itself.",
			"The caller can then run/call back into the coroutine, which will continue from where it left off.",
			"The coroutine starts out paused, so make sure to use 'Call/Run Into Coroutine' to start it up!",
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
		
		local coro = sb2.Coroutine:new(sb2.CoroutineStartFrame:new(context:copy(), closure))
		return process:report(coro)
	end
})

sb2.registerScriptblock("scriptblocks2:call_into_coroutine", {
	sb2_label = "Call Into Coroutine",
	
	sb2_explanation = {
		shortExplanation = "Calls a coroutine until it next runs/calls out, and reports the value it called out with.",
		inputSlots = {
			{"Front", "The coroutine to call."},
			{"Right", "The value to pass to the coroutine."},
		},
		additionalPoints = {
			"You cannot call into an already running coroutine!",
		}
	},
	
	sb2_color = sb2.colors.coroutines,
	sb2_icon  = "sb2_icon_call_into_coroutine.png",
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
		shortExplanation = "Runs a coroutine until it next runs/calls out.",
		inputSlots = {
			{"Left", "The coroutine to run."},
			{"Right", "The value to pass to the coroutine."},
			{"Front", "What to do afterwards."},
		},
		additionalPoints = {
			"You cannot run into an already running coroutine!",
		}
	},
	
	sb2_color = sb2.colors.coroutines,
	sb2_icon  = "sb2_icon_run_into_coroutine.png",
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
			"When the coroutine is resumed, it will continue from this point.",
			"This block will report the value passed back to the coroutine when resumed.",
		},
	},
	
	sb2_color = sb2.colors.coroutines,
	sb2_icon  = "sb2_icon_call_out_of_coroutine.png",
	sb2_slotted_faces = {"right"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated("arg") then
			frame:selectArg("arg")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		
		local delimiter = process:find(function (f) return f.getBaseFrameCoroutine end)
		local coro = delimiter and delimiter:getBaseFrameCoroutine()
		
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
			"When the coroutine is resumed, it will continue from this point.",
			"This block will continue the script when the coroutine is resumed.",
		},
	},
	
	sb2_color = sb2.colors.coroutines,
	sb2_icon  = "sb2_icon_run_out_of_coroutine.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated("arg") then
			frame:selectArg("arg")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		if not frame:isArgEvaluated("value") then
			local delimiter = process:find(function (f) return f.getBaseFrameCoroutine end)
			local coro = delimiter and delimiter:getBaseFrameCoroutine()
			
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
			"Only paused coroutines can be ran/called back into.",
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
			"Any variables, lists, etc. are shared between the original and the clone!",
			"This can be used to implement multi-shot continuations!",
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