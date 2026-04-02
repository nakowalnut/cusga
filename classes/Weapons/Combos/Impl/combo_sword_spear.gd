extends ComboBase

func execute(player: CharacterBase, current_weapon: WeaponBase, next_weapon_name: String) -> void:
	print("【连携技触发】长剑 ⇄ 矛：冲锋穿透路径眩晕+终点横斩！")
	
	var charge_dist = 200.0
	var mouse_pos = player.get_global_mouse_position()
	var charge_dir = (mouse_pos - player.global_position).normalized()
	var target_pos = player.global_position + charge_dir * charge_dist
	
	# 步骤1: 冲锋
	var tween = create_tween()
	tween.tween_property(player, "global_position", target_pos, 0.4).set_trans(Tween.TRANS_BACK)
	
	var struck = {}
	
	# 在这段冲锋期间，我们检测周围极近距离的物体作为“穿刺”
	for i in range(4):
		var enemies = get_nearby_enemies(player, 60.0)
		for e in enemies:
			if not struck.has(str(e.get_instance_id())):
				deal_damage_to(e, current_weapon.damage)
				# 假装眩晕：如果有特殊方法
				if e.has_method("stun"):
					e.stun(1.5)
				elif e.has_method("change_state"):
					e.change_state(e.STATE_STUN) # 假设存在打断的强控
				struck[str(e.get_instance_id())] = true
				
		await get_tree().create_timer(0.1).timeout
	
	# 终结一击: 长剑横斩范围大
	print("终点横斩！")
	var end_enemies = get_nearby_enemies(player, 120.0)
	for e in end_enemies:
		deal_damage_to(e, current_weapon.damage * 1.5)
		
	# 横斩特效(简单旋转)
	player.rotation += PI * 2.0
	await get_tree().create_timer(0.1).timeout
	player.rotation = 0.0
	
	finish_combo()
