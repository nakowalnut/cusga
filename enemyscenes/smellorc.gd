extends Enemy

var throw_tween: Tween

func reset_enemy():
	if throw_tween: throw_tween.kill()
	super.reset_enemy()

func pre_attack(_msg):
	if not is_instance_valid(GameManager.player): return
	
	var target_pos = GameManager.player.global_position
	var dir = global_position.direction_to(target_pos)
	
	throw_tween = create_tween()
	# 1. 后仰蓄力
	throw_tween.tween_property(self, "global_position", global_position - dir * 15, 0.4)
	# 2. 投掷瞬间
	throw_tween.tween_callback(func():
		if character_weapon:
			character_weapon.attack(target_pos)
	)
	# 3. 前倾后座力
	throw_tween.tween_property(self, "global_position", global_position + dir * 5, 0.1)
	throw_tween.tween_property(self, "global_position", global_position, 0.2)
	throw_tween.tween_callback(attack_callback)

func attack_callback():
	if c_state_machine: c_state_machine.change_state("Idle")
