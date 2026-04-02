extends ComboBase

func execute(player: CharacterBase, current_weapon: WeaponBase, next_weapon_name: String) -> void:
	print("【连携技触发】短剑 ⇄ 短剑：闪现一段距离造成路径伤害！")
	
	var base_dmg = current_weapon.damage * 1.2
	var blink_dist = 250.0
	
	var mouse_pos = player.get_global_mouse_position()
	var start_pos = player.global_position
	var blink_dir = (mouse_pos - start_pos).normalized()
	var end_pos = start_pos + blink_dir * blink_dist
	
	# 收集路径上的敌人 (用细长矩形或者多次圆判定)
	var struck = {}
	var steps = 10
	var step_vec = (end_pos - start_pos) / steps
	var current_check_pos = start_pos
	
	for i in range(steps + 1):
		# 模拟检测路径上圆形范围 30 内的敌人
		player.global_position = current_check_pos
		var enemies = get_nearby_enemies(player, 30.0)
		for e in enemies:
			if not struck.has(str(e.get_instance_id())):
				deal_damage_to(e, base_dmg)
				struck[str(e.get_instance_id())] = true
				
		current_check_pos += step_vec
		
	# 完成瞬间位移
	player.global_position = end_pos
	
	# 隐身/虚化特效
	var tween = create_tween()
	player.modulate.a = 0.2
	tween.tween_property(player, "modulate:a", 1.0, 0.3)
	
	await tween.finished
	finish_combo()
