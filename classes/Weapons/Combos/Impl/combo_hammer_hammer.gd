extends ComboBase

func execute(player: CharacterBase, current_weapon: WeaponBase, next_weapon_name: String) -> void:
	print("【连携技触发】锤子 ⇄ 锤子：蓄力然后造成大圈伤害！")
	
	var charge_dmg = current_weapon.damage * 4.0
	var range_val = 250.0
	
	# 蓄力期间改变颜色
	player.modulate = Color(1, 0, 0)
	var charge_tween = create_tween()
	charge_tween.tween_property(player, "scale", Vector2(1.5, 1.5), 1.0)
	
	await charge_tween.finished
	
	# 爆发
	var burst_tween = create_tween()
	burst_tween.tween_property(player, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BOUNCE)
	player.modulate = Color.WHITE
	
	var enemies = get_nearby_enemies(player, range_val)
	for e in enemies:
		deal_damage_to(e, charge_dmg)
		
	# 爆炸后硬直
	await get_tree().create_timer(0.2).timeout
	finish_combo()
