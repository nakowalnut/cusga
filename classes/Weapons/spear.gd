extends WeaponBase
class_name SpearWeapon

@export var stun_chance: float = 0.35
@export var stun_duration: float = 1.0

func _init() -> void:
	weapon_name = "矛"
	damage = 6.0 # 少量伤害忽略具体数值
	attack_range = 100.0 # 矛比较长
	attack_speed_multiplier = 1.2
	color = Color.RED
	max_combo = 3
	attack_wind_up = 0.08
	attack_active = 0.16
	attack_recovery = 0.21
	attack_cooldown = 0.10

func attack(_target_pos: Vector2) -> void:
	# 矛：对范围内所有敌人造成少量伤害
	var nearby = get_nearby_enemies(attack_range)
	for enemy in nearby:
		on_hit(enemy)

func on_hit(target: Node) -> void:
	if not target.get("is_dead"):
		deal_damage(target)
		add_combo(1)
		# 概率眩晕敌人
		var final_stun_chance = stun_chance
		if is_instance_valid(weapon_owner) and weapon_owner is Player and weapon_owner.get("in_ultimate_mode"):
			final_stun_chance = 1.0

		if randf() <= final_stun_chance:
			if target.has_method("apply_stun"):
				target.apply_stun(stun_duration)
				# 眩晕敌人增加 combo (需求: 累计眩晕敌人3人次)
				add_combo(1)
				print("长矛眩晕了敌人！当前眩晕计数已刷新")

func play_attack_visual(visual_system: Node, total_duration: float) -> void:
	if visual_system.animation_player.is_playing() and visual_system.animation_player.current_animation.begins_with("Attack"):
		visual_system.animation_player.stop()

	if visual_system.current_weapon_tween and visual_system.current_weapon_tween.is_valid():
		visual_system.current_weapon_tween.kill()
		
	var base_pos = Vector2(22, -5)
	visual_system.weapon_sprite.position = base_pos
	visual_system.weapon_sprite.rotation = 0.0
	
	var target_pos = base_pos + Vector2(60, 0)
	var poke_time = max(total_duration * 0.35, 0.04)
	var back_time = max(total_duration * 0.65, 0.06)
	
	visual_system.current_weapon_tween = visual_system._create_tween()
	visual_system.current_weapon_tween.tween_property(visual_system.weapon_sprite, "position", target_pos, poke_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	visual_system.current_weapon_tween.tween_property(visual_system.weapon_sprite, "position", base_pos, back_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func update_weapon_visual(visual_system: Node) -> void:
	visual_system.weapon_sprite.scale = Vector2(1.6, 0.55)
	visual_system.weapon_sprite.rotation = 0.0


