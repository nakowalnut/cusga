extends ComboBase

func execute(player: CharacterBase, current_weapon: WeaponBase, next_weapon_name: String) -> void:
	print("【连携技触发】弓 ⇄ 矛：追踪箭眩晕+降防！")
	
	var base_dmg = current_weapon.damage * 0.8
	var search_range = 800.0
	
	# 寻找鼠标附近最近的敌人作为猎物
	var mouse_pos = player.get_global_mouse_position()
	var enemies = get_nearby_enemies(player, search_range)
	if enemies.size() == 0:
		print("追踪失败，无敌人。")
		finish_combo()
		return
		
	var target = enemies[0]
	for e in enemies:
		if e.global_position.distance_squared_to(mouse_pos) < target.global_position.distance_squared_to(mouse_pos):
			target = e
			
	# “发射”追踪箭
	var arrow_tween = create_tween()
	player.modulate = Color(0.2, 0.2, 1.0)
	arrow_tween.tween_property(player, "modulate", Color.WHITE, 0.4).set_trans(Tween.TRANS_QUAD)
	
	# 延时“命中”
	await get_tree().create_timer(0.4).timeout
	
	if not is_instance_valid(target) or target.get("is_dead"):
		finish_combo()
		return
		
	# 打击
	deal_damage_to(target, base_dmg)
	print("追踪箭命中：", target.name)
	
	# 施加眩晕
	if target.has_method("stun"):
		target.stun(2.0)
	elif target.has_method("change_state"):
		target.change_state(target.STATE_STUN)
	
	# 降低防御Buff处理 (假定在Enemy上有该接口或者属性，这里仅做属性修改与延迟恢复)
	var original_def = 1.0
	if "defense" in target:
		original_def = target.defense
		target.defense *= 0.5 # 减防一半
		print("敌人被降防，剩余：", target.defense)
		
		# 不能立即结束由于涉及到延时的状态恢复
		await get_tree().create_timer(5.0).timeout
		if is_instance_valid(target) and not target.get("is_dead"):
			target.defense = original_def
			print("敌人防弹恢复：", target.defense)
			
	finish_combo()
