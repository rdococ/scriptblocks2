sb2.colors.continuations = "#fce762"

sb2.Continuation = sb2.registerClass("continuation")

function sb2.Continuation:initialize(frame)
	local frame = frame:copy()
	frame:selectArg("invoke")
	
	self.frame = frame
end
function sb2.Continuation:getFrame()
	return self.frame
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
		
		if frame:isArgEvaluated("invoke") then
			return process:report(frame:getArg("invoke"))
		end
		if not frame:isArgEvaluated("closure") then
			frame:selectArg("closure")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		
		local closure = frame:getArg("closure")
		if type(closure) ~= "table" or not closure.getPos then return process:report(nil) end
		
		local funcPos = closure:getPos()
		if not funcPos then return process:report(nil) end
		
		local funcFrame = sb2.Frame:new(funcPos, context)
		
		funcFrame:setArg("call", closure)
		funcFrame:setArg(1, sb2.Continuation:new(frame))
		
		return process:replace(funcFrame)
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
		if not frame:isArgEvaluated("value") then
			frame:selectArg("value")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		
		local continuation = frame:getArg("continuation")
		if type(continuation) ~= "table" then return process:halt() end
		if not continuation.getFrame then return process:halt() end
		
		local contFrame = continuation:getFrame():copy()
		contFrame:receiveArg(frame:getArg("value"))
		
		return process:setFrame(contFrame)
	end
})