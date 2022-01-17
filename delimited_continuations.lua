sb2.colors.delimitedContinuations = "#cafcab"

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
function sb2.DelimitedContinuation:callClosure(process, arg)
	local frame = self.frame and self.frame:copy()
	if not frame then return process:continue(process:getFrame(), nil) end
	
	frame:receiveArg(arg)
	process:pushAll(frame)
end
function sb2.DelimitedContinuation:tailCallClosure(process, arg)
	local frame = self.frame and self.frame:copy()
	if not frame then return process:report(nil) end
	
	frame:receiveArg(arg)
	process:replaceAll(frame)
end
function sb2.DelimitedContinuation:recordString(record)
	return "<delimited continuation>"
end

sb2.registerScriptblock("scriptblocks2:prompt", {
	sb2_label = "Delimit Continuation",
	
	sb2_explanation = {
		shortExplanation = "Calls the given closure. Delimited continuations created within the closure end here.",
		inputSlots = {
			{"Right", "The closure to call."},
		},
		additionalPoints = {
			"This is meant to be used with the 'Call with Delimited Continuation' block!",
			"This block defines the 'end' of the continuation that block creates.",
			"For advanced users: These blocks should behave like the prompt/control operators!",
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
		if not frame:isArgEvaluated("value") then
			local closure = frame:getArg("closure")
			if type(closure) ~= "table" or not closure.tailCallClosure then return process:report(nil) end
			
			frame:selectArg("value")
			frame:setMarker("delimited_continuations:delimiter")
			
			return closure:callClosure(process, delimiter)
		end
		
		return process:report(frame:getArg("value"))
	end
})

sb2.registerScriptblock("scriptblocks2:control", {
	sb2_label = "Call With Delimited Continuation",
	
	sb2_explanation = {
		shortExplanation = "Calls a closure, passing this block's continuation up until the end of the innermost 'Delimit Continuation' block to it.",
		inputSlots = {
			{"Right", "The closure to call."},
		},
		additionalPoints = {
			"This block is meant to be used with the 'Delimit Continuation' block.",
			"This block does the following:",
			"1. It skips part of the program, up until the end of the 'Delimit' block.",
			"2. Then, it takes the part of the program it skipped, and turns it into a special closure.",
			"3. When called, the special closure finishes the part of the program that was skipped.",
			"4. This special closure is then passed to this block's closure, which reports directly back to the end of the 'Delimit' block.",
			"For advanced users: These blocks should behave like the prompt/control operators!",
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
		if type(closure) ~= "table" or not closure.tailCallClosure then return process:report(nil) end
		
		-- Unwind the stack until we find the continuation delimiter.
		-- The captured slice includes this frame. Remove it, it's unnecessary.
		local slice = process:unwind(function (m) return m == "delimited_continuations:delimiter" end):getParent()
		
		frame = process:getFrame()
		if frame then
			-- Reset frame present, do a tail call.
			return closure:tailCallClosure(process, sb2.DelimitedContinuation:new(slice))
		else
			-- Reset frame not found! Do a regular call.
			return closure:callClosure(process, sb2.DelimitedContinuation:new(slice))
		end
	end
})