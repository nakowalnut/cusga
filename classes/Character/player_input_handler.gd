extends Node
class_name PlayerInputHandler

var player: Player

func _init(_player: Player):
	player = _player

func handle_input() -> void:
	if Input.is_action_just_pressed("dodge"):
		if player.can_change_state():
			player.c_state_machine.change_state(player.STATE_DODGE)
			return

	if Input.is_action_just_pressed("ultimate"):
		player.ultimate_manager._try_cast_ultimate()
		return

	if not player.can_change_state(): 
		return

	if not player.in_ultimate_mode:
		for i in range(1, player.weapon_wheel.size() + 1):
			var action_name = "weapon_" + str(i)
			if Input.is_action_just_pressed(action_name):
				player._switch_and_attack(i - 1)
				return

	if Input.is_action_just_pressed("attack"):
		if player.in_ultimate_mode:
			player.ultimate_manager._cycle_ultimate_weapon_before_attack()

		var cur_weapon_id = player.weapon_wheel[player.current_weapon_index]
		var is_charged_type = false
		var bypass_charge = player.in_ultimate_mode and cur_weapon_id == "hammer"
		if is_instance_valid(player.current_weapon_node):
			player.current_weapon_node.on_attack_pressed()
			is_charged_type = player.current_weapon_node.get("is_charge_weapon")
			if bypass_charge:
				is_charged_type = false
		
		if not is_charged_type:
			player.c_state_machine.change_state(player.STATE_ATTACK, {
				"weapon": cur_weapon_id, 
				"prev_weapon": cur_weapon_id, 
				"is_switch": false
			})
		else:
			player.weapon_visual_system.play_charge_animation()
		
	if Input.is_action_just_released("attack"):
		if player.in_ultimate_mode and player.weapon_wheel[player.current_weapon_index] == "hammer":
			return

		var cur_weapon_id = player.weapon_wheel[player.current_weapon_index]
		var is_charged_type = false
		if is_instance_valid(player.current_weapon_node):
			player.current_weapon_node.on_attack_released()
			is_charged_type = player.current_weapon_node.get("is_charge_weapon")
			
		if is_charged_type:
			if player.weapon_visual_system.current_weapon_tween and player.weapon_visual_system.current_weapon_tween.is_valid():
				player.weapon_visual_system.current_weapon_tween.kill()
			player.c_state_machine.change_state(player.STATE_ATTACK, {
				"weapon": cur_weapon_id, 
				"prev_weapon": cur_weapon_id, 
				"is_switch": false
			})
