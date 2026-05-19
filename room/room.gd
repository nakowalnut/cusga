extends Area2D
class_name BattleArea

@export var enemy_scenes: Array[PackedScene] = []   # 敌人生成池
@export var enemy_count: int = 5                    # 总敌人数
@export var max_per_type: int = 3                   # 每种怪物上限
@export var spawn_delay: float = 0.5                # 进入后延迟生成
@export var barrier_nodes: Array[StaticBody2D] = [] # 屏障碰撞体（拖入）

var has_triggered: bool = false
var remaining_enemies: int = 0
var spawn_points: Array[Node2D] = []

func _ready():
	# 获取所有子节点中属于 Marker2D 的生成点
	for child in $SpawnPoints.get_children():
		if child is Marker2D:
			spawn_points.append(child)
	# 初始关闭屏障
	set_barriers(false)
	# 连接玩家进入信号
	body_entered.connect(_on_player_entered)

func _on_player_entered(body: Node2D):
	print("进入区域，body=", body.name, " group=", body.get_groups())
	if has_triggered:
		print("已经触发过了")
		return
	if body.is_in_group("player"):
		print("玩家进入，开始准备生成敌人")
		has_triggered = true
		set_barriers(true)
		await get_tree().create_timer(spawn_delay).timeout      
		spawn_enemies()
	else:
		print("不是玩家，忽略")
func spawn_enemies():
	print("spawn_enemies 被调用")
	print("生成点数量：", spawn_points.size())
	if spawn_points.is_empty():
		push_error("BattleArea 没有设置生成点")
		return
	# 打乱生成点顺序
	var shuffled_points = spawn_points.duplicate()
	shuffled_points.shuffle()
	var actual_count = min(enemy_count, shuffled_points.size())
	remaining_enemies = actual_count
	
	var spawn_tracker = {}
	for i in range(actual_count):
		var point = shuffled_points[i]
		# 筛选可用怪物种类
		var available = []
		for scene in enemy_scenes:
			var used = spawn_tracker.get(scene, 0)
			if used < max_per_type:
				available.append(scene)
		if available.is_empty():
			break
		var chosen = available.pick_random()
		spawn_tracker[chosen] = spawn_tracker.get(chosen, 0) + 1
		
		var enemy = PoolManager.get_object(chosen)
		if enemy.has_method("reset_enemy"):
			enemy.reset_enemy()
		add_child(enemy)
		enemy.global_position = point.global_position
		
		# 连接死亡信号
		if enemy.has_signal("died"):
			if not enemy.died.is_connected(_on_enemy_died):
				enemy.died.connect(_on_enemy_died.bind(enemy))

func _on_enemy_died(enemy: Node):
	remaining_enemies -= 1
	if enemy.has_signal("died"):
		enemy.died.disconnect(_on_enemy_died)
	if remaining_enemies <= 0:
		on_area_cleared()

func on_area_cleared():
	print("战斗区域已清空，解除屏障")
	set_barriers(false)
	# 可选：生成宝箱、掉落等
	# 也可以发射信号让外部处理

func set_barriers(enable: bool):
	for barrier in barrier_nodes:
		if barrier:
			barrier.set_deferred("disabled", not enable)   # enable=true 时启用屏障（disabled=false）
