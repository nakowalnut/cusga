extends WeaponBase
class_name HammerWeapon

var m_damage: float = 30.0

func _init() -> void:
	weapon_name = "锤子"
	damage = 25.0
	attack_range = 40.0
	attack_speed_multiplier = 0.5 # 慢速
	color = Color.BLACK
	max_combo = 3

func attack(target_pos: Vector2) -> void:
	# 锤子只要“攻击”就会叠加连携技条件，不需要命中
	add_combo(1)

func on_hit(enemy: Node) -> void:
	if not enemy.is_dead:
		# 单体攻击，造成大量伤害
		enemy.take_damage(m_damage)

func execute_synergy() -> void:
	print("执行锤子连携技！")
	# 连携技具体效果
