extends ComboBase

func execute(player: CharacterBase, current_weapon: WeaponBase, next_weapon_name: String) -> void:
	print("【连携技触发】长剑 ⇄ 长剑：对附近1-3名敌人造成双倍伤害！")
	
	var base_dmg = current_weapon.damage * 2.0
	var range_val = 100.0 # 扩大范围
	
	# 播放特效 (暂以变色做视觉反馈)
	var tween = create_tween()
	var original_modulate = player.modulate
	tween.tween_property(player, "modulate", Color.RED, 0.1)
	tween.tween_property(player, "modulate", original_modulate, 0.2)
	
	var enemies = get_nearby_enemies(player, range_val)
	# 排序：距离由近到远
	enemies.sort_custom(func(a, b): 
		return player.global_position.distance_squared_to(a.global_position) < player.global_position.distance_squared_to(b.global_position)
	)
	
	var count = 0
	for enemy in enemies:
		if count >= 3: break
		deal_damage_to(enemy, base_dmg)
		count += 1
		
	# 延时结束
	await get_tree().create_timer(0.5).timeout
	finish_combo()
