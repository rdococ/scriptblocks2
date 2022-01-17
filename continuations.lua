sb2.colors.continuations = "#fce762"

--[[
Continuation

A continuation is a value that represents a point in the execution of a scriptblocks2 process. In many ways, it is a sort of first-class GOTO label - invoking the continuation will 'jump' to another location without any guarantee of control returning.

Constructor:
	new(frame)
		Creates a new continuation for the given frame. When the continuation is invoked, a copy of this frame will receive the argument passed to the continuation. The frame is copied during initialization, so the original can continue execution without altering the behaviour of the continuation.

Methods:
	invokeContinuation(process, arg)
		Invokes this continuation. This replaces the entire call stack with a copy of the continuation's frame.

If you are looking to extend scriptblocks2, you can register classes with their own invokeContinuation method. The 'invoke continuation' block will automatically detect the presence of the method and run it when it encounters your custom data type.
invokeContinuation should not report back to the frame that called it.
]]

sb2.Continuation = sb2.registerClass("continuation")

function sb2.Continuation:initialize(frame)
	local frame = frame and frame:copy()
	self.frame = frame
end
function sb2.Continuation:invokeContinuation(process, arg)
	local frame = self.frame
	frame = frame and frame:copy()
	
	if frame then
		frame:receiveArg(arg)
	end
	
	return process:continue(frame, arg)
end
function sb2.Continuation:recordString(record)
	return "<continuation>"
end

sb2.registerScriptblock("scriptblocks2:call_with_continuation", {
	sb2_label = "Call With Continuation",
	
	sb2_explanation = {
		shortExplanation = "Calls a closure, passing this block's continuation to it.",
		inputSlots = {
			{"Right", "The closure to call."},
		},
		additionalPoints = {
			"This block calls a closure, passing a special 'continuation' value to it.",
			"When this 'continuation' is invoked, the program jumps back to this point."
		}
	},
	
	sb2_color = sb2.colors.continuations,
	sb2_icon  = "sb2_icon_call_with_continuation.png",
	sb2_slotted_faces = {"right"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated("closure") then
			frame:selectArg("closure")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		
		local closure = frame:getArg("closure")
		if type(closure) ~= "table" or not closure.tailCallClosure then return process:report(nil) end
		
		return closure:tailCallClosure(process, sb2.Continuation:new(frame:getParent()))
	end
})

sb2.registerScriptblock("scriptblocks2:invoke_continuation", {
	sb2_label = "Invoke Continuation",
	
	sb2_explanation = {
		shortExplanation = "Jumps to the point in the program specified by the continuation.",
		inputSlots = {
			{"Front", "The continuation to invoke."},
			{"Right", "The value to invoke the continuation with."}
		},
	},
	
	sb2_color = sb2.colors.continuations,
	sb2_icon  = "sb2_icon_invoke_continuation.png",
	sb2_slotted_faces = {"front", "right"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated("continuation") then
			frame:selectArg("continuation")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.front), context))
		end
		if not frame:isArgEvaluated(1) then
			frame:selectArg(1)
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		
		local continuation = frame:getArg("continuation")
		if type(continuation) ~= "table" or not continuation.invokeContinuation then return process:halt() end
		
		return continuation:invokeContinuation(process, frame:getArg(1))
	end
})