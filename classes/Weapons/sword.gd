extends WeaponBase
class_name SwordWeapon

@export var synergy_damage: float = 20.0

func _init() -> void:
	weapon_name = "长剑"
	damage = 10.0
	attack_range = 60.0
	attack_speed_multiplier = 1.0
	color = Color.WHITE
	max_combo = 5

func attack(target_pos: Vector2) -> void:
	# 长剑的常规攻击交由 Player 的 AnimationPlayer 和 HitBox 处理
	pass

func on_hit(target: Node) -> void:
	if not target.is_dead:
		deal_damage(target)
		add_combo(1)
