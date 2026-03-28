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
		spawn_enemies()
		# 标记为已触发
		has_triggered = true 

func spawn_enemies():
	# 获取所有标记为生成点的节点
	var spawn_points = get_tree().get_nodes_in_group("enemy_spawn_point")
	#  将点位顺序随机打乱
	spawn_points.shuffle()
	# 生成字典
	var spawn_tracker = {}
	#  确定生成数量
	var actual_count = min(enemy_count, spawn_points.size())
	
	for i in range(actual_count):
		# 2. 筛选出目前还没达到上限的怪物种类
		var available_monsters = []
		for scene in enemy_scenes:
			# 如果这种怪还没生成过，或者生成数量小于上限
			if not spawn_tracker.has(scene) or spawn_tracker[scene] < max_per_type:
				available_monsters.append(scene)
		
		# 3. 到达s上限，停止生成
		if available_monsters.is_empty():
			break
			
		# 4. 从可选的列表里随机选一个
		var point = spawn_points[i]
		var chosen_scene = available_monsters.pick_random()
		
		# 5. 更新字典里的计数
		if not spawn_tracker.has(chosen_scene):
			spawn_tracker[chosen_scene] = 1
		else:
			spawn_tracker[chosen_scene] += 1
			
		# 6. 实例化并放置
		var enemy = chosen_scene.instantiate()
		enemy.global_position = point.global_position
		add_child(enemy)
