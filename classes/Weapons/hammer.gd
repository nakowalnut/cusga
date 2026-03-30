extends WeaponBase
class_name HammerWeapon

@export var max_charge_multiplier: float = 3.0
var is_charging: bool = false
var charge_start_time: float = 0.0
var current_multiplier: float = 1.0

func _init() -> void:
	weapon_name = "锤子"
	damage = 25.0
	attack_range = 50.0 # 稍微大一点
	attack_speed_multiplier = 0.5 
	color = Color.BLACK
	max_combo = 3
	attack_duration = 0.6 # 重型武器硬直长
	is_charge_weapon = true

func attack(_target_pos: Vector2) -> void:
	# 由 player.gd release 后切入 Attack 状态触发
	# 单体攻击逻辑：找范围内最近的一个
	var nearby = get_nearby_enemies(attack_range)
	if nearby.is_empty(): return
	
	nearby.sort_custom(func(a, b): 
		return weapon_owner.global_position.distance_squared_to(a.global_position) < weapon_owner.global_position.distance_squared_to(b.global_position)
	)
	
	var target = nearby[0]
	if target.has_method("take_damage"):
		target.take_damage(damage * current_multiplier)
		add_combo(1)

func on_attack_pressed() -> void:
	is_charging = true
	charge_start_time = Time.get_ticks_msec() / 1000.0
	current_multiplier = 1.0
	print("锤子：开始蓄力...")

func on_attack_released() -> void:
	if not is_charging: return
	
	var charge_duration = (Time.get_ticks_msec() / 1000.0) - charge_start_time
	current_multiplier = clamp(charge_duration * 1.5, 1.0, max_charge_multiplier)
	is_charging = false
	
	print("锤子：蓄力完毕，倍率决定为: ", current_multiplier)

func on_hit(target: Node) -> void:
	# 锤子的物理碰撞盒备用伤害
	if not target.get("is_dead"):
		if target.has_method("take_damage"):
			target.take_damage(damage * current_multiplier)
