extends WeaponBase
class_name SwordWeapon

@export var synergy_damage: float = 20.0
@export var max_targets: int = 3

func _init() -> void:
	weapon_name = "长剑"
	damage = 10.0
	attack_range = 60.0
	attack_speed_multiplier = 1.0
	color = Color.WHITE
	max_combo = 5
	attack_duration = 0.35 # 稍微长一点的挥砍时间

func attack(_target_pos: Vector2) -> void:
	# 长剑泛用：对附近 1-3 名敌人造成伤害
	# 虽然 HitBox 也会触发，但我们在这里显式处理多目标逻辑
	var nearby = get_nearby_enemies(attack_range)
	if nearby.is_empty(): return
	
	# 按距离排序
	nearby.sort_custom(func(a, b): 
		return weapon_owner.global_position.distance_squared_to(a.global_position) < weapon_owner.global_position.distance_squared_to(b.global_position)
	)
	
	# 只对前 N 个目标触发 hit
	for i in range(min(nearby.size(), max_targets)):
		on_hit(nearby[i])

func on_hit(target: Node) -> void:
	if not target.get("is_dead"):
		deal_damage(target)
		add_combo(1)
