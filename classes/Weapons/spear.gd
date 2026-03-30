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
	attack_duration = 0.45

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
		if randf() <= stun_chance:
			if target.has_method("apply_stun"):
				target.apply_stun(stun_duration)
				# 眩晕敌人增加 combo (需求: 累计眩晕敌人3人次)
				add_combo(1)
				print("长矛眩晕了敌人！当前眩晕计数已刷新")
