extends Node2D
class_name WeaponBase

@export var weapon_name: String = "未命名武器"
@export var damage: float = 10.0
var attack_range: float = 50.0
@export var attack_speed_multiplier: float = 1.0
@export var color: Color = Color.WHITE
@export var max_combo: int = 5
@export var attack_duration: float = 0.3 # 统一攻击硬直时长
@export var is_charge_weapon: bool = false # 是否需要蓄力

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


# 统一数值伤害接口
func deal_damage(target: Node) -> void:
	if not is_instance_valid(target):
		return
	if target.has_method("take_damage") and not target.get("is_dead"):
		# 如果该武器的拥有者是玩家，并且目标不是玩家，则打印伤害调试信息
		if is_instance_valid(weapon_owner) and weapon_owner is Player and not (target is Player):
			var prev_hp = target.get("current_health")
			target.take_damage(damage)
			var after_hp = target.get("current_health")
			print("玩家伤害:", weapon_owner.name, "->", target.name, " 伤害:", damage, " HP:", prev_hp, "->", after_hp)
			return

		# 默认造成伤害
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
	if weapon_owner.has_node("ComboManager"):
		var manager = weapon_owner.get_node("ComboManager")
		manager.trigger_combo(weapon_owner, self, name)

# 重置连携计数
func reset_combo() -> void:
	current_combo = 0
	is_synergy_ready = false
	
