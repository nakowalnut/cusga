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
	var hitbox = $"../HitBox"
	hitbox.global_position = target_pos

	# 使用直接空间查询，避免 Area2D 在同一物理帧内重叠列表未刷新的问题
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = hitbox.get_node("CollisionShape2D").shape
	params.transform = Transform2D(hitbox.global_rotation, target_pos)
	params.collide_with_bodies = true
	params.collide_with_areas = false
	params.collision_mask = hitbox.collision_mask
	params.exclude = [hitbox.get_rid()]
	if is_instance_valid(weapon_owner):
		params.exclude.append(weapon_owner.get_rid())

	var results = get_world_2d().direct_space_state.intersect_shape(params)

	# --- 调试打印开始 ---
	print("--- 史莱姆攻击调试 ---")
	print("攻击位置: ", target_pos)
	print("HitBox 掩码(Mask): ", hitbox.collision_mask)
	print("检测到的物体数量: ", results.size())

	for result in results:
		var body: Node = result.get("collider")
		if body == null:
			continue
		print("检测到物体: ", body.name, " | 类名: ", body.get_class(), " | 是否为Player: ", body is Player)
		if body is CharacterBody2D:
			print("  物体层(Layer): ", body.collision_layer)
	# --- 调试打印结束 ---

	for result in results:
		var i: Node = result.get("collider")
		if i == null:
			continue
		if i is Player:
			on_hit(i)
			
func on_hit(target: Node) -> void:
	if not target.is_dead:
		deal_damage(target)
		

func _init_weapons() -> void:
	pass
