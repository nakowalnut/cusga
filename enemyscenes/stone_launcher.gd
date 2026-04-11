extends WeaponBase

@export var projectile_scene: PackedScene # 绑定 stone.tscn

func attack(target_pos: Vector2) -> void:
	if not projectile_scene: return
	
	# 从对象池获取石头
	var stone = PoolManager.get_object(projectile_scene)
	if not stone.get_parent():
		get_tree().current_scene.add_child(stone)
	
	stone.global_position = global_position
	var shoot_dir = (target_pos - global_position).normalized()
	
	# 属性传递
	if "damage" in stone: stone.damage = damage
	stone.weapon_owner = self # 关键：让石头知道它属于这个发射器
	
	if stone.has_method("launch"):
		stone.launch(global_position, shoot_dir, self)

func on_hit(target: Node):
	add_combo(1) # 命中时增加连携计数
