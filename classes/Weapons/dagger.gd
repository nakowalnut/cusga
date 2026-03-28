extends WeaponBase
class_name DaggerWeapon

@export var displacement_speed: float = 600.0
@export var combo_timeout: float = 3.0
@export var delay_time: float = 0.1
var combo_timer: Timer
var pending_stab_target: Node = null
var pending_stab_hits: int = 0

func _init() -> void:
	weapon_name = "短剑"
	damage = 8.0
	attack_range = 30.0
	attack_speed_multiplier = 1.5 # 攻速高
	color = Color.BLUE
	max_combo = 5

func _ready() -> void:
	combo_timer = Timer.new()
	combo_timer.one_shot = true
	combo_timer.timeout.connect(_on_combo_timeout)
	add_child(combo_timer)

func attack(target_pos: Vector2) -> void:
	if not is_instance_valid(weapon_owner): return
	
	var mouse_pos = weapon_owner.get_global_mouse_position()
	
	# 短剑位移：检测鼠标位置是否有敌人
	var space_state = weapon_owner.get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = mouse_pos
	params.collision_mask = 4 # Enemy Layer
	params.collide_with_areas = true
	params.collide_with_bodies = true
	
	var results = space_state.intersect_point(params)
	var target_enemy: Node = null
	for res in results:
		if res.collider and (res.collider is Enemy):
			target_enemy = res.collider
			break
		elif res.collider and (res.collider.get_parent() is Enemy):
			target_enemy = res.collider.get_parent()
			break
			
	if target_enemy:
		_register_stab_target(target_enemy)
	else:
		print("短剑：目标处无敌人，原地攻击")
		_reset_pending_stab()

func _register_stab_target(enemy: Node) -> void:
	if not is_instance_valid(enemy) or enemy.is_dead:
		return

	if pending_stab_target != enemy:
		pending_stab_target = enemy
		pending_stab_hits = 0

	pending_stab_hits += 1
	combo_timer.start(combo_timeout)

	if pending_stab_hits < 2:
		print("短剑：第1次命中，继续点同一个敌人触发突刺")
		return

	print("短剑：双击命中，准备位移突刺...")
	_reset_pending_stab()
	_perform_dash(enemy)

func _perform_dash(enemy: Node) -> void:
	# 延迟1秒
	await get_tree().create_timer(delay_time).timeout
	
	# 延迟过后，逻辑上获取该敌人当前的最新坐标（实时更新效果）
	if not is_instance_valid(weapon_owner) or not is_instance_valid(enemy) or enemy.is_dead:
		return

	if is_instance_valid(weapon_owner) and is_instance_valid(enemy) and not enemy.is_dead:
		# 留出一点距离，避免玩家和怪物完全重叠
		var dir = (weapon_owner.global_position - enemy.global_position).normalized()
		var offset = dir * 40.0
		if offset == Vector2.ZERO:
			offset = Vector2(40, 0)
			
		# 直接更改玩家坐标到该敌人身边
		weapon_owner.global_position = enemy.global_position + offset
		print("短剑：瞬移到敌人坐标并发起突刺！")
		add_combo(1)
		# 刷新连击时间
		combo_timer.start(combo_timeout)
		# 瞬移后自动触发一次攻击判定
		on_hit(enemy)

func on_hit(target: Node) -> void:
	if not target.is_dead:
		deal_damage(target)
		add_combo(1)
		# 刷新连击时间
		combo_timer.start(combo_timeout)

func _on_combo_timeout() -> void:
	_reset_pending_stab()
	if not is_synergy_ready:
		reset_combo()
		print("短剑连击超时，已重置")

func _reset_pending_stab() -> void:
	pending_stab_target = null
	pending_stab_hits = 0
