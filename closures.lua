sb2.colors.closures = "#c1c1c1"

function sb2.asClosureOrNil(v)
	if type(v) ~= "table" then return end
	if v.type ~= "closure" then return end
	return v
end
function sb2.createClosure(pos, startPos, outer)
	return {type = "closure", pos = pos, frame = sb2.createFrame(startPos, outer, nil, true)}
end
function sb2.createClosureCall(closure)
	return sb2.createFrame(sb2.getPos(closure.frame), closure.frame, nil, true)
end

sb2.registerScriptblock("scriptblocks2:create_closure", {
	sb2_label = "Create Closure",
	
	sb2_color = sb2.colors.closures,
	sb2_icon  = "sb2_icon_define_procedure.png",
	sb2_slotted_faces = {"right"},
	
	sb2_input_name = "parameter",
	sb2_input_label = "Parameter",
	sb2_input_default = "",
	
	sb2_action = function (pos, node, process, frame)
		local dirs = sb2.facedirToDirs(node.param2)
		local closure = sb2.createClosure(pos, vector.add(pos, dirs.right), frame)
		
		return sb2.reportValue(process, closure)
	end,
})

sb2.registerScriptblock("scriptblocks2:call_closure", {
	sb2_label = "Call Closure",
	
	sb2_color = sb2.colors.closures,
	sb2_icon  = "sb2_icon_call_procedure.png",
	sb2_slotted_faces = {"right", "front"},
	
	sb2_action = function (pos, node, process, frame)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not sb2.isArgEvaluated(frame, "closure") then
			sb2.selectArg(frame, "closure")
			return sb2.pushFrame(process, sb2.createFrame(vector.add(pos, dirs.front), frame))
		end
		if not sb2.isArgEvaluated(frame, 1) then
			sb2.selectArg(frame, 1)
			return sb2.pushFrame(process, sb2.createFrame(vector.add(pos, dirs.right), frame))
		end
		if not sb2.isArgEvaluated(frame, "value") then
			sb2.selectArg(frame, "value")
			
			local closure = sb2.asClosureOrNil(sb2.getArg(frame, "closure"))
			if not closure then
				return sb2.reportValue(process, nil)
			end
			
			local newFrame = sb2.createClosureCall(closure)
			sb2.declareVar(newFrame, minetest.get_meta(closure.pos):get_string("parameter"), sb2.getArg(frame, 1))
			
			return sb2.pushFrame(process, newFrame)
		end
		
		return sb2.reportValue(process, sb2.getArg(frame, "value"))
	end,
})
sb2.registerScriptblock("scriptblocks2:run_closure", {
	sb2_label = "Run Closure",
	
	sb2_color = sb2.colors.closures,
	sb2_icon  = "sb2_icon_run_procedure.png",
	sb2_slotted_faces = {"right", "left", "front"},
	
	sb2_action = function (pos, node, process, frame)
		local dirs = sb2.facedirToDirs(node.param2)
		
		if not sb2.isArgEvaluated(frame, "closure") then
			sb2.selectArg(frame, "closure")
			return sb2.pushFrame(process, sb2.createFrame(vector.add(pos, dirs.left), frame))
		end
		if not sb2.isArgEvaluated(frame, 1) then
			sb2.selectArg(frame, 1)
			return sb2.pushFrame(process, sb2.createFrame(vector.add(pos, dirs.right), frame))
		end
		if not sb2.isArgEvaluated(frame, "value") then
			sb2.selectArg(frame, "value")
			
			local closure = sb2.asClosureOrNil(sb2.getArg(frame, "closure"))
			if not closure then
				return sb2.reportValue(process, nil)
			end
			
			local newFrame = sb2.createClosureCall(closure)
			sb2.declareVar(newFrame, minetest.get_meta(closure.pos):get_string("parameter"), sb2.getArg(frame, 1))
			
			return sb2.pushFrame(process, newFrame)
		end
		
		return sb2.replaceFrame(process, sb2.createFrame(vector.add(pos, dirs.front), frame))
	end,
})