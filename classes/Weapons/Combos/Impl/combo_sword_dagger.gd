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

	# 步骤: 原地5连斩
	for i in range(5):
		if not is_instance_valid(target) or target.get("is_dead"):
			print("【连携技】第", i + 1, "刀前目标已失效或死亡，提前结束连斩")
			break
			
		var is_last = (i == 4)
		var dmg = base_dmg * (2.0 if is_last else 1.0)
		var prev_hp = target.get("current_health")
		print("【连携技】第", i + 1, "刀开始，目标HP=", prev_hp, " 伤害=", dmg, " 最后一击=", is_last)
		deal_damage_to(target, dmg)
		var after_hp = target.get("current_health")
		print("【连携技】第", i + 1, "刀结束，目标HP=", after_hp)
		
		# 简易攻击特效(玩家闪烁)
		var color_tween = create_tween()
		player.modulate = Color(1.5, 1.5, 2.0)
		color_tween.tween_property(player, "modulate", Color.WHITE, 0.1)
		
		# 最后一击带击退
		if is_last:
			var dir = (target.global_position - player.global_position).normalized()
			var kb_str = 600.0
			print("【连携技】最后一击准备击退，方向=", dir, " 力度=", kb_str)
			if target.has_method("apply_knockback"):
				target.apply_knockback(dir * kb_str)
				print("【连携技】已调用 apply_knockback")
			elif target.get("velocity") != null:
				target.velocity = target.velocity + dir * kb_str
				print("【连携技】已直接叠加 velocity")
			else:
				print("【连携技】目标没有击退接口，也没有 velocity 属性")
		
		await get_tree().create_timer(0.1).timeout
		
	finish_combo()
