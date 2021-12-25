sb2.colors.control = "#f9e944"

sb2.registerScriptblock("scriptblocks2:if", {
	sb2_label = "If",
	
	sb2_color = sb2.colors.control,
	sb2_icon = "sb2_icon_if.png",
	sb2_slotted_faces = {"right", "front", "left"},
	
	sb2_action = function (pos, node, process, frame)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not sb2.isArgEvaluated(frame, "condition") then
			sb2.selectArg(frame, "condition")
			return sb2.pushFrame(process, sb2.createFrame(vector.add(pos, dirs.right), frame))
		end
		
		if sb2.getArg(frame, "condition") then
			return sb2.replaceFrame(process, sb2.createFrame(vector.add(pos, dirs.front), frame))
		else
			return sb2.replaceFrame(process, sb2.createFrame(vector.add(pos, dirs.left), frame))
		end
	end
})

sb2.registerScriptblock("scriptblocks2:wait", {
	sb2_label = "Wait",
	
	sb2_color = sb2.colors.control,
	sb2_icon = "sb2_icon_wait.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = function (pos, node, process, frame)
		local dirs = sb2.facedirToDirs(node.param2)
		local t = minetest.get_server_uptime()
		
		if not sb2.isArgEvaluated(frame, "duration") then
			sb2.setArg(frame, "start", t)
			sb2.selectArg(frame, "duration")
			return sb2.pushFrame(process, sb2.createFrame(vector.add(pos, dirs.right), frame))
		end
		
		if t - sb2.getArg(frame, "start") >= sb2.toNumber(sb2.getArg(frame, "duration")) then
			return sb2.replaceFrame(process, sb2.createFrame(vector.add(pos, dirs.front), frame))
		else
			return "yield"
		end
	end
})