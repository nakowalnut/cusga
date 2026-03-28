extends Enemy

func pre_attack(msg):
	# 使用直线距离判断是否满足攻击范围
	if is_instance_valid(GameManager.player) and global_position.distance_to(GameManager.player.global_position) <= sight_range[0]:
		var start_pos = global_position
		var target_pos = GameManager.player.global_position
		var old_layer := collision_layer
		var old_mask := collision_mask
		# 冲刺期间关闭本体碰撞，避免将玩家硬顶飞
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		
		var tween = create_tween()
		# 1. 本体快速扑向玩家的全局位置
		tween.tween_property(self, "global_position", target_pos, 0.1)
		
		# 1.5 到达玩家位置时，触发一次攻击判定！
		tween.tween_callback(func():
			if is_instance_valid(character_weapon) and character_weapon.has_method("attack"):
				character_weapon.attack(global_position)
		)
		
		# 2. 然后马上弹回起始位置（利用 Tween 的自动排队特性连续播放）
		tween.tween_property(self, "global_position", start_pos, 0.15)
		# 2.5 还原碰撞层和掩码
		tween.tween_callback(func():
			set_deferred("collision_layer", old_layer)
			set_deferred("collision_mask", old_mask)
		)
		
		# 3. 冲击-返回 这套动作全结束后再呼叫回调
		tween.tween_callback(attack_callback)

func attack_callback():
	if c_state_machine and c_state_machine.get_current_state_name() == "Attack":
		c_state_machine.change_state("Idle")
