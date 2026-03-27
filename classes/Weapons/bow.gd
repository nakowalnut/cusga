extends WeaponBase
class_name BowWeapon

const ArrowScene = preload("res://Scenes/Prefab/arrow_projectile.tscn")

func _init() -> void:
	weapon_name = "弓"
	damage = 5.0
	attack_range = 300.0
	attack_speed_multiplier = 0.8
	color = Color.GREEN
	max_combo = 8

func attack(target_pos: Vector2) -> void:
	# 弓攻击时不能移动在 State 里面处理（Velocity 归零）
	# 发射抛射物
	if ArrowScene:
		var arrow = ArrowScene.instantiate()
		arrow.global_position = weapon_owner.global_position
		arrow.direction = (target_pos - weapon_owner.global_position).normalized()
		arrow.damage = damage
		# 传入 bow 自身以便子弹命中时增加 combo
		arrow.weapon_owner = self 
		get_tree().current_scene.add_child(arrow)
	else:
		print("未找到箭矢场景 res://classes/Weapons/arrow_projectile.tscn")

func on_hit(target: Node) -> void:
	# 弓的普通挥打不计入，只有箭矢命中会计入，这里可以通过 arrow 调用
	if not target.is_dead:
		deal_damage(target)
		add_combo(1)
