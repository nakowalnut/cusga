extends ComboBase

func execute(player: CharacterBase, current_weapon: WeaponBase, next_weapon_name: String) -> void:
	print("【连携技触发】长剑 ⇄ 短剑：5连斩+最后一击击退！")
	
	var base_dmg = current_weapon.damage * 0.8
	var search_range = 200.0
	
	var enemies = get_nearby_enemies(player, search_range)
	if enemies.size() == 0:
		print("周围无敌人，短剑空翻")
		finish_combo()
		return
	
	# 选最近的一个敌人
	var target = enemies[0]
	for e in enemies:
		if player.global_position.distance_squared_to(e.global_position) < player.global_position.distance_squared_to(target.global_position):
			target = e

	# 步骤: 原地5连斩（移除快速突进）
	for i in range(5):
		if not is_instance_valid(target) or target.get("is_dead"):
			break
			
		var is_last = (i == 4)
		var dmg = base_dmg * (2.0 if is_last else 1.0)
		deal_damage_to(target, dmg)
		
		# 简易攻击特效(玩家闪烁)
		var color_tween = create_tween()
		player.modulate = Color(1.5, 1.5, 2.0)
		color_tween.tween_property(player, "modulate", Color.WHITE, 0.1)
		
		# 最后一击带击退
		if is_last:
				var dir = (target.global_position - player.global_position).normalized()
				var kb_str = 600.0
				if target.has_method("apply_knockback"):
					target.apply_knockback(dir * kb_str)
				elif "velocity" in target:
					target.velocity = target.velocity + dir * kb_str
		
		await get_tree().create_timer(0.1).timeout
		
	finish_combo()
