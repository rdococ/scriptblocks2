sb2.colors.control = "#f9e944"

sb2.registerScriptblock("scriptblocks2:if", {
	sb2_label = "If",
	
	sb2_color = sb2.colors.control,
	sb2_icon = "sb2_icon_if.png",
	sb2_slotted_faces = {"right", "front", "left"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not frame:isArgEvaluated("condition") then
			frame:selectArg("condition")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		
		if frame:getArg("condition") then
			return process:replace(sb2.Frame:new(vector.add(pos, dirs.front), context))
		else
			return process:replace(sb2.Frame:new(vector.add(pos, dirs.left), context))
		end
	end
})

sb2.registerScriptblock("scriptblocks2:wait", {
	sb2_label = "Wait",
	
	sb2_color = sb2.colors.control,
	sb2_icon = "sb2_icon_wait.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = function (pos, node, process, frame, context)
		local dirs = sb2.facedirToDirs(node.param2)
		local t = minetest.get_server_uptime()
		
		if not frame:isArgEvaluated("duration") then
			frame:setArg("start", t)
			frame:selectArg("duration")
			return process:push(sb2.Frame:new(vector.add(pos, dirs.right), context))
		end
		
		if t - frame:getArg("start") >= sb2.toNumber(frame:getArg("duration")) then
			return process:replace(sb2.Frame:new(vector.add(pos, dirs.front), context))
		else
			return process:yield()
		end
	end
})