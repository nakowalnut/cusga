extends ComboBase

func execute(player: CharacterBase, current_weapon: WeaponBase, next_weapon_name: String) -> void:
	print("【连携技触发】锤子 ⇄ 矛：砸地眩晕+地刺全中！")
	
	var base_dmg = current_weapon.damage * 0.8
	var range_val = 300.0
	
	# 第一击：砸地造成眩晕！(动画用颜色变红缩放代替)
	var smash_tween = create_tween()
	smash_tween.tween_property(player, "scale", Vector2(1.3, 1.3), 0.1)
	smash_tween.tween_property(player, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BOUNCE)
	
	await smash_tween.finished
	
	var stun_enemies = get_nearby_enemies(player, range_val)
	for e in stun_enemies:
		deal_damage_to(e, current_weapon.damage * 0.5)
		if e.has_method("stun"): e.stun(1.5)
		elif e.has_method("change_state"): e.change_state(e.STATE_STUN)
	
	# 后续：地下多根矛进行多段穿刺
	print("地刺爆发！")
	for i in range(3):
		await get_tree().create_timer(0.3).timeout
		var spike_enemies = get_nearby_enemies(player, range_val)
		for e in spike_enemies:
			deal_damage_to(e, base_dmg)
			# 视觉效果
			e.modulate = Color(0.9, 0.4, 0.4)
			create_tween().tween_property(e, "modulate", Color.WHITE, 0.2)
	
	finish_combo()
