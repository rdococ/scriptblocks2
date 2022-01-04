sb2.colors.mesecons = "#ffff00"
sb2.colors.mesecons_on = "#ffff80"

sb2.registerScriptblock("scriptblocks2:receive_mesecon_signal", {
	sb2_label = "When I Receive Mesecon Signal",
	
	sb2_explanation = {
		shortExplanation = "Starts a script after receiving a mesecon signal.",
		inputSlots = {
			{"Front", "What to do when a signal is received."},
		},
	},
	
	sb2_color = sb2.colors.mesecons,
	sb2_icon  = "sb2_icon_receive.png",
	sb2_slotted_faces = {"front"},
	
	sb2_action = sb2.simple_action {
		continuation = "front",
		action = function (pos, node, process, frame, context) end
	},
	
	after_place_node = function (pos, placer, itemstack, pointed_thing)
		if not placer then return end
		if not placer:is_player() then return end
		
		local name = placer:get_player_name()
		local meta = minetest.get_meta(pos)
		
		meta:set_string("owner", name)
		meta:set_string("infotext", "Owner: " .. name)
	end,
	
	mesecons = {
		effector = {
			action_on = function (pos, node)
				local context = sb2.Context:new(pos, minetest.get_meta(pos):get_string("owner"))
				sb2.Process:new(sb2.Frame:new(pos, context))
			end,
			rules = mesecon.rules.alldirs,
		},
	},
})