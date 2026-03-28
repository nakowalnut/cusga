extends WeaponBase
class_name SpearWeapon

@export var stun_chance: float = 0.3
@export var stun_duration: float = 1.5

func _init() -> void:
	weapon_name = "矛"
	damage = 5.0 # 少量伤害
	attack_range = 80.0
	attack_speed_multiplier = 1.2
	color = Color.RED
	max_combo = 3

func attack(target_pos: Vector2) -> void:
	pass

func on_hit(target: Node) -> void:
	if not target.is_dead:
		deal_damage(target)
		add_combo(1)
		# 概率眩晕敌人
		if randf() <= stun_chance:
			if target.has_method("apply_stun"):
				target.apply_stun(stun_duration)
				# 眩晕敌人增加 combo (需求: 累计眩晕敌人3人次)
				add_combo(1)
				print("长矛眩晕了敌人！当前眩晕次数:", current_combo)
