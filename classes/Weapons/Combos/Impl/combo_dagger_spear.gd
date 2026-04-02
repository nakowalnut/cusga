extends ComboBase

func execute(player: CharacterBase, current_weapon: WeaponBase, next_weapon_name: String) -> void:
	print("【连携技触发】短剑 ⇄ 矛：闪现最近敌人+强控！")
	
	var search_range = 500.0
	var base_dmg = current_weapon.damage * 1.5
	var stun_duration = 2.0
	
	var enemies = get_nearby_enemies(player, search_range)
	if enemies.size() == 0:
		print("周围无敌人，短剑矛释放失败！")
		finish_combo()
		return
		
	# 找最近的敌人
	var target = enemies[0]
	for e in enemies:
		if player.global_position.distance_squared_to(e.global_position) < player.global_position.distance_squared_to(target.global_position):
			target = e
			
	# 计算其背后面向的方向或稍微靠近身前一点的位置
	var dir_to_enemy = (target.global_position - player.global_position).normalized()
	var flash_pos = target.global_position - dir_to_enemy * 40.0
	
	# 瞬间位移过去
	player.global_position = flash_pos
	
	# 强控并造成伤害
	deal_damage_to(target, base_dmg)
	if target.has_method("stun"):
		target.stun(stun_duration)
	elif target.has_method("change_state"):
		target.change_state(target.STATE_STUN) # 尝试触发眩晕
		
	# 一点粒子/残留特效
	var tween = create_tween()
	player.modulate = Color.YELLOW
	tween.tween_property(player, "modulate", Color.WHITE, 0.4)
	
	await tween.finished
	finish_combo()
