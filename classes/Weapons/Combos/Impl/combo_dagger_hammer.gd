extends ComboBase

func execute(player: CharacterBase, current_weapon: WeaponBase, next_weapon_name: String) -> void:
	print("【连携技触发】短剑 ⇄ 锤子：获得特殊状态，10秒内鼠标长按攻击对准敌人可闪现并击飞！")
	
	var buff_duration := 10.0
	var charge_time_required := 0.35
	var current_charge := 0.0
	var elapsed := 0.0
	var combo_fired := false

	var original_modulate = player.modulate
	player.modulate = Color(1.5, 0.8, 1.2) # 视觉提示：身上带点光圈或变色

	# 由于是在 _ready 的子节点运行，可以用 await 维持循环帧
	while elapsed < buff_duration:
		if not is_instance_valid(player) or player.get("is_dead"):
			break

		if Input.is_action_pressed("attack"):
			current_charge += 0.05
			if current_charge >= charge_time_required:
				combo_fired = _perform_blink_attack(player, current_weapon)
				if combo_fired:
					break
		else:
			current_charge = 0.0

		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05

	if is_instance_valid(player):
		player.modulate = original_modulate

	finish_combo()

func _perform_blink_attack(player: CharacterBase, current_weapon: WeaponBase) -> bool:
	var mouse_pos = player.get_global_mouse_position()
	var enemies = get_nearby_enemies(player, 1500.0)
	var target: Node = null
	var min_dist_sq = 150.0 * 150.0 # 必须在鼠标周围150像素内圈定目标

	for e in enemies:
		var dist_sq = e.global_position.distance_squared_to(mouse_pos)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			target = e

	if not target:
		return false

	var start_pos = player.global_position
	var target_pos = target.global_position
	var dir_to_enemy = (target_pos - start_pos).normalized()
	if dir_to_enemy == Vector2.ZERO:
		dir_to_enemy = Vector2.RIGHT

	# 闪现到敌人身前40距离
	player.global_position = target_pos - dir_to_enemy * 40.0

	# 伤害与击飞
	var base_dmg = current_weapon.damage * 2.5
	deal_damage_to(target, base_dmg)

	var kb_str = 800.0
	if target.has_method("apply_knockback"):
		target.apply_knockback(dir_to_enemy * kb_str)
	elif "velocity" in target:
		target.velocity = target.velocity + dir_to_enemy * kb_str
		if target.has_method("move_and_slide"):
			target.move_and_slide()

	# 闪现完毕后的震荡特效
	var tween = create_tween()
	player.modulate = Color(2.0, 1.5, 0.5)
	tween.tween_property(player, "modulate", Color.WHITE, 0.3)
	
	var scale_tween = create_tween()
	scale_tween.tween_property(player, "scale", Vector2(1.2, 1.2), 0.1)
	scale_tween.tween_property(player, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BOUNCE)

	print("【短剑 ⇄ 锤子】成功长按闪现并击飞敌人！")
	return true
