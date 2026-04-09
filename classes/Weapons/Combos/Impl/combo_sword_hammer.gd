extends ComboBase

func execute(player: CharacterBase, current_weapon: WeaponBase, next_weapon_name: String) -> void:
	print("【连携技触发】长剑 ⇄ 锤子：重砸地面范围伤害，附加自身攻击力5秒！")
	
	var base_dmg = current_weapon.damage * 1.5
	var smash_radius = 150.0
	
	# 重砸特效缩放
	var tween = create_tween()
	tween.tween_property(player, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(player, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BOUNCE)
	
	await tween.finished # 等待起跳并重重落地后再判定伤害！
	
	var enemies = get_nearby_enemies(player, smash_radius)
	if enemies.is_empty():
		print("砸地未命中任何敌人。")
	for e in enemies:
		deal_damage_to(e, base_dmg)
		print("锤击命中：", e.name, "，造成伤害：", base_dmg)
		# 微弱击退
		if e.has_method("apply_knockback"):
			var dir = (e.global_position - player.global_position).normalized()
			e.apply_knockback(dir * 200.0)
		elif e is CharacterBody2D or e is RigidBody2D:
			var dir = (e.global_position - player.global_position).normalized()
			if e.get("velocity") != null:
				e.velocity += dir * 200.0
	
	# 附加攻击力 (需要在player增加buff机制，这里简单粗暴叠加)
	if is_instance_valid(player.get("current_weapon_node")):
		var original_dmg = player.current_weapon_node.get("damage")
		player.current_weapon_node.set("damage", original_dmg * 1.5)
		
		# 恢复计时器
		await get_tree().create_timer(5.0).timeout
		if is_instance_valid(player.get("current_weapon_node")):
			player.current_weapon_node.set("damage", original_dmg)
			print("攻击力buff消失：", player.current_weapon_node.damage)
		
	finish_combo()
