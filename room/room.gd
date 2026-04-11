extends Node2D

# 设定怪物场景
@export var enemy_scenes: Array[PackedScene] = []
# 设定怪物数量
@export var enemy_count: int 
# 限制每种怪物生成数量
@export var max_per_type: int
# 防止反复刷怪
var has_triggered: bool = false

func _ready() -> void:
	pass
func _on_spawn_trigger_body_entered(body: Node2D) -> void:
	#检查玩家信号
	if not has_triggered and body.is_in_group("player"):
		call_deferred("spawn_enemies")
		# 标记为已触发
		has_triggered = true 

func spawn_enemies():
	# 1. 获取所有生成点并打乱
	var spawn_points = get_tree().get_nodes_in_group("enemy_spawn_point")
	spawn_points.shuffle()
	
	var spawn_tracker = {}
	var actual_count = min(enemy_count, spawn_points.size())
	
	for i in range(actual_count):
		# 2. 筛选出目前还没达到上限的怪物种类
		var available_monsters = []
		for scene in enemy_scenes:
			if not spawn_tracker.has(scene) or spawn_tracker[scene] < max_per_type:
				available_monsters.append(scene)
		
		# 3. 如果没怪可选了，跳出循环
		if available_monsters.is_empty():
			break
			
		# 4. 随机选一个点和一种怪
		var point = spawn_points[i]
		var chosen_scene = available_monsters.pick_random()
		
		# 5. 更新字典计数
		if not spawn_tracker.has(chosen_scene):
			spawn_tracker[chosen_scene] = 1
		else:
			spawn_tracker[chosen_scene] += 1
			
		# --- 6. 【核心改动】改用对象池获取 ---
		var enemy = PoolManager.get_object(chosen_scene)
		
		# 重点：如果是从池子里取出来的旧怪，需要重置它的血量、状态和 AI
		if enemy.has_method("reset_enemy"):
			enemy.reset_enemy()
		
		# 将怪物添加进场景（如果它已经在父节点下，对象池内部逻辑会处理 remove_child）
		add_child(enemy)
		enemy.global_position = point.global_position
