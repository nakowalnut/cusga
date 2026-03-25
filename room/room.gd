extends Node2D

# 在检查器里把你的怪物场景（.tscn）拖进去
@export var enemy_scenes: Array[PackedScene] = []
# 设定这个房间生多少只怪
@export var enemy_count: int = 4

func _ready() -> void:
	spawn_enemies()

func spawn_enemies():
	# 1. 获取所有标记为生成点的节点
	var spawn_points = get_tree().get_nodes_in_group("enemy_spawn_point")
	
	# 2. 将点位顺序随机打乱
	spawn_points.shuffle()
	
	# 3. 确定生成数量（不能超过现有标记点总数）
	var actual_spawn_count = min(enemy_count, spawn_points.size())
	
	# 4. 循环生成
	for i in range(actual_spawn_count):
		# 随机选一个点
		var point = spawn_points[i]
		# 随机选一种怪
		var random_enemy_scene = enemy_scenes.pick_random()
		
		# 实例化怪物
		var enemy = random_enemy_scene.instantiate()
		# 设置坐标
		enemy.global_position = point.global_position
		# 将怪物添加进场景（建议添加给当前房间节点）
		add_child(enemy)
