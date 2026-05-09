extends WeaponBase
class_name DaggerWeapon

@export var displacement_speed: float = 600.0
@export var combo_timeout: float = 3.0
@export var delay_time: float = 0.1
@export var hold_time_required: float = 0.17 # 长按触发所需时间
@export var hammer_synergy_damage_multiplier: float = 2.5
@export var hammer_synergy_knockback: float = 800.0
var combo_timer: Timer
var hold_timer: Timer
var pending_stab_target: Node = null
var dash_pending: bool = false
var dash_executed_this_hold: bool = false
var hammer_synergy_expire_at: float = 0.0

func _init() -> void:
	weapon_name = "短剑"
	damage = 8.0
	attack_range = 30.0
	attack_speed_multiplier = 1.6 # 提高攻速
	color = Color.BLUE
	max_combo = 5
	attack_wind_up = 0.03
	attack_active = 0.08
	attack_recovery = 0.09
	attack_cooldown = 0.05
	is_charge_weapon = true

func _ready() -> void:
	combo_timer = Timer.new()
	combo_timer.one_shot = true
	combo_timer.timeout.connect(_on_combo_timeout)
	add_child(combo_timer)
	
	hold_timer = Timer.new()
	hold_timer.one_shot = true
	hold_timer.timeout.connect(_on_hold_timeout)
	add_child(hold_timer)

func on_attack_pressed() -> void:
	dash_executed_this_hold = false
	dash_pending = false
	var mouse_pos = weapon_owner.get_global_mouse_position()
	var target_enemy = _find_enemy_near_mouse(mouse_pos)
	if target_enemy:
		_register_stab_target(target_enemy)
	else:
		_reset_pending_stab()

func on_attack_released() -> void:
	if not hold_timer.is_stopped():
		hold_timer.stop()
		print("短剑：长按中断")

func attack(target_pos: Vector2) -> void:
	if not is_instance_valid(weapon_owner): return

	# 长按闪现已结算，松开触发的 Attack 不再重复结算伤害。
	if dash_pending or dash_executed_this_hold:
		dash_executed_this_hold = false
		return

	var target_enemy = _find_enemy_near_mouse(target_pos)
	if target_enemy:
		on_hit(target_enemy)
	else:
		print("短剑：目标处无敌人，原地攻击")

func _find_enemy_near_mouse(mouse_pos: Vector2) -> Node:
	# 短剑位移：检测鼠标位置是否有敌人
	var space_state = weapon_owner.get_world_2d().direct_space_state
	var params = PhysicsShapeQueryParameters2D.new()
	 
	var shape = CircleShape2D.new()
	shape.radius = 10.0#调受击判定半径大小
	
	params.shape = shape
	params.transform = Transform2D(0,mouse_pos)

	#params.collision_mask = 4 # Enemy Layer
	params.collide_with_areas = false
	params.collide_with_bodies = true
	
	var results = space_state.intersect_shape(params)
	var target_enemy: Node = null
	for res in results:
		if res.collider and (res.collider is Enemy):
			target_enemy = res.collider
			break
		elif res.collider and (res.collider.get_parent() is Enemy):
			target_enemy = res.collider.get_parent()
			break

	return target_enemy

func _register_stab_target(enemy: Node) -> void:
	if not is_instance_valid(enemy) or enemy.is_dead:
		return

	if pending_stab_target != enemy:
		pending_stab_target = enemy

	if hold_timer.is_stopped():
		print("短剑：锁定敌人，开始长按判定...")
		hold_timer.start(hold_time_required)

func _on_hold_timeout() -> void:
	if is_instance_valid(pending_stab_target) and not pending_stab_target.is_dead:
		print("短剑：长按触发，准备位移突刺...")
		dash_pending = true
		_perform_dash(pending_stab_target)
		_reset_pending_stab()

func _perform_dash(enemy: Node) -> void:
	# 延迟1秒
	await get_tree().create_timer(delay_time).timeout
	
	# 延迟过后，逻辑上获取该敌人当前的最新坐标（实时更新效果）
	if not is_instance_valid(weapon_owner) or not is_instance_valid(enemy) or enemy.is_dead:
		return

	if is_instance_valid(weapon_owner) and is_instance_valid(enemy) and not enemy.is_dead:
		var pre_dash_pos = weapon_owner.global_position
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
		# 瞬移后自动触发一次攻击判定；锤子连携窗口内升级为击飞突刺
		if _is_hammer_synergy_active():
			_apply_hammer_synergy_stab(enemy, pre_dash_pos)
		else:
			on_hit(enemy)
		dash_executed_this_hold = true
	dash_pending = false

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

func grant_hammer_synergy(duration: float = 10.0) -> void:
	hammer_synergy_expire_at = _get_now_seconds() + duration
	print("短剑：获得锤子连携强化，持续", duration, "秒")

func _is_hammer_synergy_active() -> bool:
	return _get_now_seconds() < hammer_synergy_expire_at

func _get_now_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0

func _apply_hammer_synergy_stab(target: Node, from_pos: Vector2) -> void:
	if not is_instance_valid(target) or target.get("is_dead"):
		return

	var synergy_damage = damage * hammer_synergy_damage_multiplier
	if target.has_method("take_damage"):
		target.take_damage(synergy_damage)

	var dir_to_enemy = (target.global_position - from_pos).normalized()
	if dir_to_enemy == Vector2.ZERO:
		dir_to_enemy = (target.global_position - weapon_owner.global_position).normalized()
	if dir_to_enemy == Vector2.ZERO:
		dir_to_enemy = Vector2.RIGHT

	if target.has_method("apply_knockback"):
		target.apply_knockback(dir_to_enemy * hammer_synergy_knockback)
	elif "velocity" in target:
		target.velocity = target.velocity + dir_to_enemy * hammer_synergy_knockback
		if target.has_method("move_and_slide"):
			target.move_and_slide()

	add_combo(1)
	combo_timer.start(combo_timeout)
	print("短剑：连携突刺触发，造成击飞")


func update_weapon_visual(visual_system: Node) -> void:
	visual_system.weapon_sprite.scale = Vector2(0.5, 1.125)
