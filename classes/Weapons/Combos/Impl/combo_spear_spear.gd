extends ComboBase

func execute(player: CharacterBase, current_weapon: WeaponBase, next_weapon_name: String) -> void:
	print("【连携技触发】矛 ⇄ 矛：以自身为中心的范围刺击，附带减速与减攻速！")

	var damage := current_weapon.damage * 0.6
	var radius := 130.0
	var debuff_duration := 3.0

	var enemies = get_nearby_enemies(player, radius)
	if enemies.is_empty():
		print("矛 ⇄ 矛 未命中任何敌人。")
		finish_combo()
		return

	var affected_targets: Array = []
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.get("is_dead"):
			continue

		deal_damage_to(enemy, damage)
		print("矛击命中：", enemy.name, "，造成伤害：", damage)

		var original_speed = enemy.speed if "speed" in enemy else 0.0
		var original_attack_cd = enemy.attack_cooldown_time if "attack_cooldown_time" in enemy else 0.0
		affected_targets.append({
			"target": enemy,
			"speed": original_speed,
			"attack_cooldown_time": original_attack_cd
		})

		if "speed" in enemy:
			enemy.speed = original_speed * 0.7
		if "attack_cooldown_time" in enemy:
			enemy.attack_cooldown_time = original_attack_cd * 1.3

		if enemy.has_method("apply_stun"):
			# 这里不使用眩晕，只用一次短促表现让命中更有反馈
			enemy.modulate = Color(0.7, 0.9, 1.0)
			create_tween().tween_property(enemy, "modulate", Color.WHITE, 0.15)

	var cast_tween = create_tween()
	cast_tween.tween_property(player, "scale", Vector2(1.08, 1.08), 0.08)
	cast_tween.tween_property(player, "scale", Vector2(1.0, 1.0), 0.12)

	await get_tree().create_timer(debuff_duration).timeout

	for item in affected_targets:
		var target: Node = item["target"]
		if not is_instance_valid(target) or target.get("is_dead"):
			continue
		if "speed" in target:
			target.speed = item["speed"]
		if "attack_cooldown_time" in target:
			target.attack_cooldown_time = item["attack_cooldown_time"]

	finish_combo()
