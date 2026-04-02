extends ComboBase

func execute(player: CharacterBase, current_weapon: WeaponBase, next_weapon_name: String) -> void:
	print("【连携技触发】弓 ⇄ 弓：5秒内持续朝鼠标方向自动射击！")

	if not is_instance_valid(player) or not is_instance_valid(current_weapon):
		finish_combo()
		return

	var duration := 5.0
	var fire_interval := 0.15
	var elapsed := 0.0

	# 每一发都重新读取鼠标位置，确保玩家移动鼠标时方向会实时变化
	while elapsed < duration:
		if not is_instance_valid(player) or player.get("is_dead"):
			break

		var mouse_pos := player.get_global_mouse_position()
		current_weapon.attack(mouse_pos)

		var color_tween = create_tween()
		player.modulate = Color(0.8, 1.0, 0.8)
		color_tween.tween_property(player, "modulate", Color.WHITE, 0.08)

		await get_tree().create_timer(fire_interval).timeout
		elapsed += fire_interval

	finish_combo()
