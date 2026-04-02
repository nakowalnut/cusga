extends ComboBase

func execute(player: CharacterBase, current_weapon: WeaponBase, next_weapon_name: String) -> void:
	print("【连携技触发】短剑 ⇄ 弓：突刺一段并在路径下箭雨！")
	
	var dash_dist = 150.0
	var total_dur = 0.3
	
	var mouse_pos = player.get_global_mouse_position()
	var forward_dir = (mouse_pos - player.global_position).normalized()
	var start_pos = player.global_position
	var target_pos = start_pos + forward_dir * dash_dist
	
	var tween = create_tween()
	tween.tween_property(player, "global_position", target_pos, total_dur).set_trans(Tween.TRANS_QUAD)
	
	# 每0.1秒掉落箭矢：获取起步与终点之间的范围
	var drops = 5
	var step_vec = (target_pos - start_pos) / drops
	var arrow_dmg = current_weapon.damage * 0.8
	
	for i in range(drops):
		var drop_pos = start_pos + step_vec * i
		
		# 模拟在降落点制造一个小范围伤害
		player.global_position = drop_pos
		var enemies = get_nearby_enemies(player, 40.0)
		for e in enemies:
			deal_damage_to(e, arrow_dmg)
			
		await get_tree().create_timer(max(total_dur/drops, 0.05)).timeout
		
	# 回归终点
	player.global_position = target_pos
	finish_combo()
