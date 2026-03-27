extends WeaponBase
class_name Slimer

@export var synergy_damage: float = 20.0
@onready var weapon_holder: Node2D = $WeaponHolder


func _init() -> void:
	weapon_name = "史莱姆肚"
	damage = 10.0
	attack_range = 60.0
	attack_speed_multiplier = 1.0
	color = Color.WHITE
	max_combo = 0

func attack(target_pos: Vector2) -> void:
	$"../HitBox".global_position = target_pos
	for i in $"../HitBox".get_overlapping_areas():
		if i is Player:
			on_hit(i)
			
func on_hit(target: Node) -> void:
	if not target.is_dead:
		deal_damage(target)
		

func _init_weapons() -> void:
	pass
