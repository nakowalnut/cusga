extends ComboBase

const ArrowScene = preload("res://Scenes/Prefab/arrow_projectile.tscn")

func execute(player: CharacterBase, current_weapon: WeaponBase, next_weapon_name: String) -> void:
	print("【连携技触发】长剑 ⇄ 弓：扇形剑雨，5秒内持续朝鼠标方向倾泻！")

	if not is_instance_valid(player) or not is_instance_valid(current_weapon):
		finish_combo()
		return

	var duration := 5.0
	var shots_per_wave := 7
	var fire_interval := 0.18
	var wave_spread := PI / 3.0
	var projectile_speed := 900.0
	var projectile_damage := current_weapon.damage * 0.55
	var elapsed := 0.0

	while elapsed < duration:
		if not is_instance_valid(player) or player.get("is_dead"):
			break

		var mouse_pos := player.get_global_mouse_position()
		var forward_dir := (mouse_pos - player.global_position).normalized()
		var start_angle := forward_dir.angle() - wave_spread * 0.5

		for i in range(shots_per_wave):
			if not ArrowScene:
				break

			var ratio := 0.0 if shots_per_wave <= 1 else float(i) / float(shots_per_wave - 1)
			var angle := start_angle + wave_spread * ratio
			var direction := Vector2.RIGHT.rotated(angle)
			var arrow = ArrowScene.instantiate()
			arrow.global_position = player.global_position + direction * 18.0
			arrow.direction = direction
			arrow.speed = projectile_speed
			arrow.damage = projectile_damage
			arrow.direct_damage = projectile_damage
			arrow.trigger_weapon_on_hit = false
			arrow.weapon_owner = current_weapon
			get_tree().current_scene.add_child(arrow)

		var tween = create_tween()
		player.modulate = Color(0.9, 1.0, 0.7)
		tween.tween_property(player, "modulate", Color.WHITE, 0.08)

		await get_tree().create_timer(fire_interval).timeout
		elapsed += fire_interval

	finish_combo()
