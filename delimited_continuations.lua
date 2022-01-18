sb2.colors.delimitedContinuations = "#cafcab"

--[[
DelimiterFrame

This is a type of frame that represents a continuation delimiter.
]]

sb2.DelimiterFrame = sb2.registerClass("delimiterFrame")

function sb2.DelimiterFrame:initialize(context)
	self.context = context
	self.parent = nil
	
	self.arg = nil
end

function sb2.DelimiterFrame:copy()
	local newFrame = self:getClass():new(self.context)
	newFrame.parent = self.parent and self.parent:copy()
end
function sb2.DelimiterFrame:step(process)
	return process:report(self.arg)
end
function sb2.DelimiterFrame:receiveArg(arg)
	self.arg = arg
end

function sb2.DelimiterFrame:getContext()
	return self.context
end

function sb2.DelimiterFrame:getParent()
	return self.parent
end
function sb2.DelimiterFrame:setParent(parent)
	self.parent = parent
end

function sb2.DelimiterFrame:isDelimiter()
	return true
end


--[[
DelimitedContinuation

A delimited continuation is much like a continuation. A continuation represents a point in the execution of a process; when a continuation is invoked, execution carries on from that point without ever returning.

However, a delimited continuation represents a *slice* of process execution. A delimited continuation, when called, will transfer execution to the beginning of this slice. When the end of the slice is reached, execution *returns* to the invoker of the delimited continuation.

This makes delimited continuations a lot more powerful than regular continuations, and very different. Invoking a delimited continuation is less like a GOTO and more like a function call - in fact, a delimited continuation can be treated exactly like a closure value, and can be called with the 'Call/Run Closure' blocks.
]]

sb2.DelimitedContinuation = sb2.registerClass("delimitedContinuation")

function sb2.DelimitedContinuation:initialize(frame)
	self.frame = frame and frame:copy()
end

function sb2.DelimitedContinuation:callClosure(process, context, arg)
	local frame = self.frame and self.frame:copy()
	if not frame then return process:continue(process:getFrame(), arg) end
	
	-- Push a delimiter frame here.
	process:push(sb2.DelimiterFrame:new(context))
	
	frame:receiveArg(arg)
	process:pushAll(frame)
end
function sb2.DelimitedContinuation:tailCallClosure(process, context, arg)
	local frame = self.frame and self.frame:copy()
	if not frame then return process:report(arg) end
	
	-- Replace this frame with a marker.
	process:replace(sb2.DelimiterFrame:new(context))
	
	frame:receiveArg(arg)
	process:pushAll(frame)
end

function sb2.DelimitedContinuation:recordString(record)
	return "<delimited continuation>"
end

minetest.register_alias("scriptblocks2:prompt", "scriptblocks2:call_with_continuation_prompt")
sb2.registerScriptblock("scriptblocks2:call_with_continuation_prompt", {
	sb2_label = "Call With Continuation Prompt",
	
	sb2_explanation = {
		shortExplanation = "Calls the given closure. Delimited continuations created within the closure end here.",
		inputSlots = {
			{"Right", "The closure to call."},
		},
		additionalPoints = {
			"This block defines the end of the continuation the 'Call With Delimited Continuation' block creates.",
			"For advanced users: These blocks should behave like the reset/shift operators!",
		}
	},
	
	sb2_color = sb2.colors.delimitedContinuations,
	sb2_icon  = "sb2_icon_call_with_continuation.png",
	sb2_slotted_faces = {"right"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated("closure") then
			frame:selectArg("closure")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		
		local closure = frame:getArg("closure")
		if type(closure) ~= "table" or not closure.callClosure then return process:report(nil) end
		
		frame:selectArg("value")
		
		-- Replace this frame with a delimiter, and call the closure.
		process:replace(sb2.DelimiterFrame:new(context))
		return closure:callClosure(process, context, nil)
	end
})

minetest.register_alias("scriptblocks2:control", "scriptblocks2:call_with_delimited_continuation")
sb2.registerScriptblock("scriptblocks2:call_with_delimited_continuation", {
	sb2_label = "Call With Delimited Continuation",
	
	sb2_explanation = {
		shortExplanation = "Calls a closure, passing this block's continuation up until the end of the innermost 'Delimit Continuation' block to it.",
		inputSlots = {
			{"Right", "The closure to call."},
		},
		additionalPoints = {
			"This delimited continuation value can be called like a closure.",
			"It runs the program from this block up until the end of the innermost 'Call With Continuation Prompt' block.",
			"For advanced users: These blocks should behave like the reset/shift operators!",
		}
	},
	
	sb2_color = sb2.colors.delimitedContinuations,
	sb2_icon  = "sb2_icon_invoke_continuation.png",
	sb2_slotted_faces = {"right"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated("closure") then
			frame:selectArg("closure")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		
		local closure = frame:getArg("closure")
		if type(closure) ~= "table" or not closure.callClosure then return process:report(nil) end
		
		-- Unwind the stack until we find the continuation delimiter.
		-- The captured slice includes this frame. Remove it, it's unnecessary.
		local slice = process:unwind(function (frame) return frame.isDelimiter and frame:isDelimiter() end):getParent()
		
		if process:getFrame() then
			-- Process:unwind does not capture the delimiter frame itself. It's our job to decide what to do with it.
			-- We're about to call the 'shift' closure. Within it, the 'reset' should no longer be active.
			return closure:tailCallClosure(process, context, sb2.DelimitedContinuation:new(slice))
		end
		return closure:callClosure(process, context, sb2.DelimitedContinuation:new(slice))
	end
})