extends Enemy
class_name SmellOrc

func process_movement(_delta: float) -> void:
	if not is_instance_valid(target_player):
		super.process_movement(_delta)
		return

	var dist = global_position.distance_to(target_player.global_position)
	var dir = global_position.direction_to(target_player.global_position)

	# 远程怪物的特殊逻辑：
	if dist < 150.0:
		# 1. 玩家太近了，尝试后退（风筝）
		velocity = -dir * (speed * 0.6)
	elif dist <= sight_range[0]:
		# 2. 在射程内，停下攻击
		velocity = Vector2.ZERO
		if attack_controller and attack_controller.can_start_attack():
			c_state_machine.change_state(CharacterBase.STATE_ATTACK)
	else:
		# 3. 玩家太远，向前走
		velocity = dir * speed

func pre_attack(_msg: Dictionary = {}) -> void:
	if not is_instance_valid(target_player): return
	
	# 投掷动作：身体向后仰，然后掷出
	var dir = global_position.direction_to(target_player.global_position)
	perform_attack_movement(dir, 10.0, 0.4, true) 
	
	await get_tree().create_timer(0.4).timeout
	
	if character_weapon:
		character_weapon.attack(target_player.global_position)
