extends Node2D
class_name WeaponBase

@export var weapon_name: String = "未命名武器"
@export var damage: float = 10.0
@export var attack_range: float = 50.0
@export var attack_speed_multiplier: float = 1.0
@export var color: Color = Color.WHITE
@export var max_combo: int = 5
@export var attack_duration: float = 0.3 # 统一攻击硬直时长
@export var is_charge_weapon: bool = false # 是否需要蓄力
@export_flags_2d_physics var nearby_enemy_mask: int = 4 # 默认敌人层

var current_combo: int = 0
var is_synergy_ready: bool = false
@export var weapon_owner: CharacterBase

func _ready() -> void:
	pass

# 当玩家发起攻击时调用
func attack(target_pos: Vector2) -> void:
	pass

# 统一输入钩子：玩家按下攻击键时
func on_attack_pressed() -> void:
	pass

# 统一输入钩子：玩家松开攻击键时
func on_attack_released() -> void:
	pass

# 获取附近敌人的辅助函数
func get_nearby_enemies(radius: float) -> Array:
	var space_state = weapon_owner.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	query.shape = shape
	query.transform = Transform2D(0, weapon_owner.global_position)
	query.collision_mask = nearby_enemy_mask
	query.collide_with_areas = true
	var results = space_state.intersect_shape(query)
	var enemies = []
	for r in results:
		var col = r.collider
		if col is Enemy:
			enemies.append(col)
		elif col.get_parent() is Enemy:
			enemies.append(col.get_parent())
	return enemies

# 统一致死判定接口：由子类 on_hit 调用，实现“触碰即死”语义
#func kill_target_if_enemy(target: Node) -> void:
	#if not is_instance_valid(target): return
	#if target.has_method("die") and not target.get("is_dead"):
		## 如果是 CharacterBase 或继承者，直接触发死亡逻辑
		#target.die()

# 统一数值伤害接口
func deal_damage(target: Node) -> void:
	if not is_instance_valid(target): return
	if target.has_method("take_damage") and not target.get("is_dead"):
		target.take_damage(damage)

# 每次攻击检测到命中敌人时调用
func on_hit(target: Node) -> void:
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
func on_switch_out(name: String) -> void:
	if is_synergy_ready:
		execute_synergy(name)
	reset_combo()

# 执行连携技的具体逻辑，由子类实现
func execute_synergy(name) -> void:
	if weapon_owner.debug_mode:
		print("连携技使出(",weapon_name,"->", name, ")")

# 重置连携计数
func reset_combo() -> void:
	current_combo = 0
	is_synergy_ready = false
	
