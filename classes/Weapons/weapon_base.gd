extends Node2D
class_name WeaponBase

@export var weapon_name: String = "未命名武器"
@export var damage: float = 10.0
@export var attack_range: float = 50.0
@export var attack_speed_multiplier: float = 1.0
@export var color: Color = Color.WHITE
@export var max_combo: int = 5

var current_combo: int = 0
var is_synergy_ready: bool = false
var player: Player

func _ready() -> void:
	pass

# 当玩家发起攻击时调用
func attack(target_pos: Vector2) -> void:
	pass

# 每次攻击检测到命中敌人时调用
func on_hit(enemy: Node) -> void:
	pass

# 更新连携技进度
func add_combo(amount: int = 1) -> void:
	if is_synergy_ready:
		return
	current_combo += amount
	if current_combo >= max_combo:
		is_synergy_ready = true
		print(weapon_name + " 连携技已就绪！")

# 切换武器时调用，判断是否触发连携技
func on_switch_out() -> void:
	if is_synergy_ready:
		execute_synergy()
	reset_combo()

# 执行连携技的具体逻辑，由子类实现
func execute_synergy() -> void:
	pass

# 重置连携计数
func reset_combo() -> void:
	current_combo = 0
	is_synergy_ready = false

# 获取附近敌人的辅助函数
func get_nearby_enemies(radius: float) -> Array:
	if not is_instance_valid(player): return []
	var enemies = []
	var space_state = player.get_world_2d().direct_space_state
	var shape = CircleShape2D.new()
	shape.radius = radius
	
	var params = PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = player.global_transform
	params.collision_mask = 4 # 假设敌人是在 Layer 3 (掩码为 4)
	
	var results = space_state.intersect_shape(params)
	for res in results:
		var col = res.collider
		if col.has_method("take_damage") and not col.is_dead:
			enemies.append(col)
	return enemies
