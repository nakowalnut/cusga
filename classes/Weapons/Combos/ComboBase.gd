extends Node
class_name ComboBase

# 统一入口
func execute(player: CharacterBase, current_weapon: WeaponBase, next_weapon_name: String) -> void:
	# 子类重写此方法
	pass

# 辅助方法：获取范围内的敌人
func get_nearby_enemies(player: CharacterBase, radius: float) -> Array:
	if not player or not is_instance_valid(player): return []
	var space_state = player.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	query.shape = shape
	query.transform = Transform2D(0, player.global_position)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var results = space_state.intersect_shape(query)
	var enemies = []
	for r in results:
		var col = r.collider
		if col is Enemy:
			enemies.append(col)
		elif col.get_parent() is Enemy:
			enemies.append(col.get_parent())
	return enemies

# 辅助方法：简易单体伤害
func deal_damage_to(target: Node, damage: float) -> void:
	if is_instance_valid(target) and target.has_method("take_damage") and not target.get("is_dead"):
		target.take_damage(damage)

# 辅助方法：连携完成清理自身
func finish_combo() -> void:
	queue_free()
