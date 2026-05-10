extends Node2D
class_name WeaponBase

@export var weapon_name: String = "未命名武器"
@export var damage: float = 10.0
@export var crit_rate: float = 0.05 # 暴击率
@export var crit_damage_multiplier: float = 2.0 # 暴击伤害倍率
var attack_range: float = 50.0
@export var attack_speed_multiplier: float = 1.0
@export var movement_speed_multiplier: float = 1.0
@export var color: Color = Color.WHITE
@export var max_combo: int = 5
@export_group("Attack Timing")
@export var attack_wind_up: float = 0.05
@export var attack_active: float = 0.12
@export var attack_recovery: float = 0.18
@export var attack_cooldown: float = 0.08
@export var is_charge_weapon: bool = false # 是否需要蓄力

@export_group("Audio")
@export var attack_sfx: AudioStream # 单个武器的攻击音效
var sfx_player: AudioStreamPlayer2D

var current_combo: int = 0
var is_synergy_ready: bool = false
var is_combo_active: bool = false
@export var weapon_owner: CharacterBase

func _ready() -> void:
	# 动态创建音频播放器节点并挂载到武器下
	sfx_player = AudioStreamPlayer2D.new()
	add_child(sfx_player)

# 添加一个新方法专门用来播放该武器被分配的音效
func play_attack_sound() -> void:
	if attack_sfx and is_instance_valid(sfx_player):
		sfx_player.pitch_scale = randf_range(0.9, 1.1) 
		sfx_player.stream = attack_sfx
		sfx_player.play()

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
func deal_damage(target: Node, override_damage: float = -1.0) -> void:
	if not is_instance_valid(target):
		return
	if target.has_method("take_damage") and not target.get("is_dead"):
		var applied_damage = damage
		if override_damage >= 0.0:
			applied_damage = override_damage
			
		# 计算暴击
		var is_crit = false
		if randf() < crit_rate:
			applied_damage *= crit_damage_multiplier
			is_crit = true

		# 如果该武器的拥有者是玩家，并且目标不是玩家，则打印伤害调试信息
		if is_instance_valid(weapon_owner) and weapon_owner is Player and not (target is Player):
			var prev_hp = target.get("current_health")
			target.take_damage(applied_damage)
			var after_hp = target.get("current_health")
			var crit_str = " [暴击!]" if is_crit else ""
			print("玩家伤害:", weapon_owner.name, "->", target.name, " 伤害:", applied_damage, crit_str, " HP:", prev_hp, "->", after_hp)
		else:
			# 默认造成伤害
			target.take_damage(applied_damage)

		if is_instance_valid(weapon_owner) and weapon_owner is Player and weapon_owner.has_method("spawn_ultimate_followup_arrow"):
			weapon_owner.spawn_ultimate_followup_arrow(target)

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
func on_switch_out(name: String) -> bool:
	var triggered := false
	if is_synergy_ready:
		triggered = execute_synergy(name)
	reset_combo()
	return triggered

# 执行连携技的具体逻辑，由子类实现
func execute_synergy(name) -> bool:
	if weapon_owner.debug_mode:
		print("连携技使出(",weapon_name,"->", name, ")")
	if weapon_owner.has_node("ComboManager"):
		var manager = weapon_owner.get_node("ComboManager")
		return manager.trigger_combo(weapon_owner, self, name)
	return false

# 重置连携计数
func reset_combo() -> void:
	current_combo = 0
	is_synergy_ready = false

# 如果武器在特定状态下可以接管伤害处理（如霸体），返回 true 并执行自定义逻辑
func handle_take_damage(amount: float) -> bool:
	return false

# 如果武器在特定状态下可以接管击退处理，返回 true 并执行自定义逻辑
func handle_apply_knockback(force: Vector2) -> bool:
	return false
	
