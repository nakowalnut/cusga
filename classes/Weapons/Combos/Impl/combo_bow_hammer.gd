extends ComboBase

func execute(player: CharacterBase, current_weapon: WeaponBase, next_weapon_name: String) -> void:
	print("【连携技触发】弓 ⇄ 锤子：爆裂箭聚拢爆炸！")
	
	var base_dmg = current_weapon.damage * 0.5
	var boom_dmg = current_weapon.damage * 3.0
	var range_val = 300.0
	
	var start_pos = player.global_position
	var mouse_pos = player.get_global_mouse_position()
	var shoot_dir = (mouse_pos - start_pos).normalized()
	
	# 向前飞去 500 距离的“幻影箭”
	var arrow_end_pos = start_pos + shoot_dir * 500.0
	var hit_enemy = null
	
	player.modulate = Color(1.0, 0.5, 0)
	var arrow_tween = create_tween()
	arrow_tween.tween_property(player, "modulate", Color.WHITE, 0.4)
	
	# 这里简化了箭矢投射，先找直线上的敌人作为“命中”
	var enemies = get_nearby_enemies(player, 500.0)
	for e in enemies:
		var dir_to_enemy = (e.global_position - player.global_position).normalized()
		var angle = shoot_dir.angle_to(dir_to_enemy)
		if abs(angle) < 0.15:
			hit_enemy = e
			arrow_end_pos = e.global_position
			break
			
	await get_tree().create_timer(0.3).timeout # 假装箭飞
	
	# 聚拢
	var center_pos = arrow_end_pos
	var inner_enemies = get_nearby_enemies(player, range_val)
	var to_boom = []
	
	for e in inner_enemies:
		if e.global_position.distance_squared_to(center_pos) < range_val * range_val:
			to_boom.append(e)
			# 磁吸效果 (简单位移)
			if e is RigidBody2D or e is CharacterBody2D:
				var pull_dir = (center_pos - e.global_position).normalized()
				var speed = 200.0
				var tween = create_tween()
				var new_pos = e.global_position + pull_dir * speed
				tween.tween_property(e, "global_position", new_pos, 0.5)
	
	await get_tree().create_timer(0.5).timeout
	
	# 爆炸！
	for e in to_boom:
		deal_damage_to(e, boom_dmg)
		print("BOOM!")
	
	# 特效
	player.scale = Vector2(1.2, 1.2)
	var final_tween = create_tween()
	final_tween.tween_property(player, "scale", Vector2(1.0, 1.0), 0.2)
	
	await final_tween.finished
	finish_combo()
