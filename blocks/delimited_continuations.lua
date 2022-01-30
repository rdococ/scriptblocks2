sb2.colors.delimitedContinuations = "#cafcab"

--[[
PromptFrame

This is a custom frame type that represents a continuation prompt. It is created by the 'Call With Continuation Prompt' block, and used by 'Call With Delimited Continuation' to capture a continuation up to this frame.
]]

sb2.PromptFrame = sb2.registerClass("promptFrame")

function sb2.PromptFrame:initialize(tag)
	self.tag = tag
	
	self.parent = nil
	self.arg = nil
end

function sb2.PromptFrame:copy()
	local newFrame = self:getClass():new()
	newFrame.parent = self.parent and self.parent:copy()
end
function sb2.PromptFrame:step(process)
	return process:report(self.arg)
end
function sb2.PromptFrame:receiveArg(arg)
	self.arg = arg
end

function sb2.PromptFrame:getParent()
	return self.parent
end
function sb2.PromptFrame:setParent(parent)
	self.parent = parent
end

function sb2.PromptFrame:getPromptTag()
	return self.tag
end


--[[
DelimitedContinuation

A delimited continuation is much like a continuation. A continuation represents a point in the execution of a process; when a continuation is invoked, execution carries on from that point without ever returning.

However, a delimited continuation represents a *slice* of process execution. A delimited continuation, when called, will transfer execution to the beginning of this slice. When the end of the slice is reached, execution *returns* to the invoker of the delimited continuation.

This makes delimited continuations a lot more powerful than regular continuations, and very different. Invoking a delimited continuation is less like a GOTO and more like a function call - in fact, a delimited continuation can be treated exactly like a closure value, and can be called with the 'Call/Run Closure' blocks.
]]

sb2.DelimitedContinuation = sb2.registerClass("delimitedContinuation")

function sb2.DelimitedContinuation:initialize(frame, tag)
	self.frame = frame
	self.tag = tag
end

function sb2.DelimitedContinuation:doCall(process, context, arg)
	local frame = self.frame and self.frame:copy()
	if not frame then return process:receiveArg(arg) end
	
	-- Push a delimiter frame here.
	process:push(sb2.PromptFrame:new(self.tag))
	
	process:rewind(frame)
	return frame:receiveArg(arg)
end

function sb2.DelimitedContinuation:recordString(record)
	return "<delimited continuation>"
end

minetest.register_alias("scriptblocks2:prompt", "scriptblocks2:call_with_continuation_delimiter")
minetest.register_alias("scriptblocks2:call_with_continuation_prompt", "scriptblocks2:call_with_continuation_delimiter")
sb2.registerScriptblock("scriptblocks2:call_with_continuation_delimiter", {
	sb2_label = "Call With Continuation Delimiter",
	
	sb2_explanation = {
		shortExplanation = "Calls the given closure. Delimited continuations created within the closure with the same tag value end here.",
		inputSlots = {
			{"Right", "The closure to call."},
			{"Front", "The tag required for the call/DC block to use this delimiter."},
		},
		additionalPoints = {
			"This block defines the end of the continuations created by 'Call With Delimited Continuation' blocks with the same tag.",
			"You should use the simpler coroutine mechanism instead. This block will be removed in the future.",
		}
	},
	
	sb2_color = sb2.colors.delimitedContinuations,
	sb2_icon  = "sb2_icon_call_with_continuation.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_deprecated = true,
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated("closure") then
			frame:selectArg("closure")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		if not frame:isArgEvaluated("tag") then
			frame:selectArg("tag")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context))
		end
		
		local closure = frame:getArg("closure")
		if type(closure) ~= "table" or not closure.doCall then return process:report(nil) end
		
		frame:selectArg("value")
		
		-- Replace this frame with a delimiter, and call the closure.
		process:pop()
		process:push(sb2.PromptFrame:new(frame:getArg("tag")))
		
		return closure:doCall(process, context, nil)
	end
})

minetest.register_alias("scriptblocks2:control", "scriptblocks2:call_with_delimited_continuation")
sb2.registerScriptblock("scriptblocks2:call_with_delimited_continuation", {
	sb2_label = "Call With Delimited Continuation",
	
	sb2_explanation = {
		shortExplanation = "Calls a closure, passing this block's continuation up until the end of the innermost 'Call With Continuation Delimiter' block with the same tag.",
		inputSlots = {
			{"Right", "The closure to call."},
			{"Front", "The tag for the delimiter block to delimit the continuation at."},
		},
		additionalPoints = {
			"This delimited continuation value can be called like a closure.",
			"It runs the program from this block up until the end of the innermost delimiter block with the same tag value.",
			"You should use the simpler coroutine mechanism instead. This block will be removed in the future.",
		}
	},
	
	sb2_color = sb2.colors.delimitedContinuations,
	sb2_icon  = "sb2_icon_invoke_continuation.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_deprecated = true,
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated("closure") then
			frame:selectArg("closure")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		if not frame:isArgEvaluated("tag") then
			frame:selectArg("tag")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context))
		end
		
		local closure = frame:getArg("closure")
		if type(closure) ~= "table" or not closure.doCall then return process:report(nil) end
		
		local tag = frame:getArg("tag")
		
		-- Remove this frame so we aren't in the captured slice.
		process:pop()
		-- Unwind the stack until we find the continuation delimiter.
		local slice = process:unwind(function (f) return f.getPromptTag and f:getPromptTag() == tag end)
		
		if process:getFrame() then
			-- Process:unwind does not capture the delimiter frame itself. It's our job to decide what to do with it.
			-- We're about to call the 'shift0' closure. Within it, the 'reset0' should no longer be active.
			process:pop()
		end
		return closure:doCall(process, context, sb2.DelimitedContinuation:new(slice, tag))
	end
})