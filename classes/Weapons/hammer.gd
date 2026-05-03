extends WeaponBase
class_name HammerWeapon

@export var max_charge_multiplier: float = 3.0
@export var dagger_synergy_blink_radius: float = 150.0
@export var dagger_synergy_blink_offset: float = 40.0
@export var dagger_synergy_hold_time_required: float = 0.35
@export var dagger_synergy_knockback: float = 900.0
var is_charging: bool = false
var charge_start_time: float = 0.0
var current_multiplier: float = 1.0
var dagger_synergy_expire_at: float = 0.0
var bow_synergy_expire_at: float = 0.0
var bow_synergy_active_for_next_attack: bool = false
@export var explosive_damage_multiplier: float = 3.0
@export var explosive_knockback: float = 800.0
@export var explosive_radius: float = 100.0
const ArrowScene = preload("res://Scenes/Prefab/arrow_projectile.tscn")
var pending_blink_target: Node = null
var blink_knockback_target: Node = null

func _init() -> void:
	weapon_name = "锤子"
	damage = 25.0
	attack_range = 50.0 # 稍微大一点
	attack_speed_multiplier = 0.5 
	color = Color.BLACK
	max_combo = 3
	attack_wind_up = 0.12
	attack_active = 0.18
	attack_recovery = 0.30
	attack_cooldown = 0.16
	is_charge_weapon = true

func attack(target_pos: Vector2) -> void:
	if is_instance_valid(weapon_owner) and weapon_owner.get("in_ultimate_mode"):
		current_multiplier = max_charge_multiplier

	# 由 player.gd release 后切入 Attack 状态触发
	if _is_bow_synergy_active():
		bow_synergy_active_for_next_attack = false
		_fire_explosive_arrow(target_pos)
		# 即使发射了箭，锤子本身的近战攻击是否触发取决于需求，
		# 这里逻辑仿照弓箭，触发了爆炸箭就不走原来的逻辑
		return

	# 单体攻击逻辑：找范围内最近的一个
	var nearby = get_nearby_enemies(attack_range)
	if nearby.is_empty(): return
	
	nearby.sort_custom(func(a, b): 
		return weapon_owner.global_position.distance_squared_to(a.global_position) < weapon_owner.global_position.distance_squared_to(b.global_position)
	)
	
	var target = nearby[0]
	if target.has_method("take_damage"):
		deal_damage(target, damage * current_multiplier)
		add_combo(1)

	if is_instance_valid(blink_knockback_target) and not blink_knockback_target.get("is_dead"):
		_apply_synergy_knockback(blink_knockback_target)
		blink_knockback_target = null

func on_attack_pressed() -> void:
	if is_instance_valid(weapon_owner) and weapon_owner is Player and weapon_owner.get("in_ultimate_mode"):
		is_charging = false
		current_multiplier = max_charge_multiplier
		pending_blink_target = null
		print("锤子：大招模式，直接满倍率")
		return

	is_charging = true
	charge_start_time = Time.get_ticks_msec() / 1000.0
	current_multiplier = 1.0
	pending_blink_target = null
	if _is_dagger_synergy_active() and is_instance_valid(weapon_owner):
		pending_blink_target = _find_enemy_near_mouse(weapon_owner.get_global_mouse_position())
	print("锤子：开始蓄力...")

func on_attack_released() -> void:
	if not is_charging: return
	
	var charge_duration = (Time.get_ticks_msec() / 1000.0) - charge_start_time
	current_multiplier = clamp(charge_duration * 1.5, 1.0, max_charge_multiplier)
	if _is_dagger_synergy_active() and charge_duration >= dagger_synergy_hold_time_required:
		var target = pending_blink_target
		if not is_instance_valid(target) or target.get("is_dead"):
			target = _find_enemy_near_mouse(weapon_owner.get_global_mouse_position())
		_try_synergy_blink_target(target)
	pending_blink_target = null
	is_charging = false
	
	print("锤子：蓄力完毕，倍率决定为: ", current_multiplier)

func on_hit(target: Node) -> void:
	# 锤子的物理碰撞盒备用伤害
	if not target.get("is_dead"):
		if target.has_method("take_damage"):
			deal_damage(target, damage * current_multiplier)

func update_weapon_visual(visual_system: Node) -> void:
	visual_system.weapon_sprite.scale = Vector2(0.9, 1.0)
	_build_hammer_head(self.color, visual_system)

func _build_hammer_head(base_color: Color, visual_system: Node) -> void:
	if not visual_system.weapon_sprite:
		return
	visual_system._clear_custom_weapon_shapes()
	_add_hammer_square(Vector2(18.0, -8.0), 11.0, base_color.lightened(0.15), "Top", visual_system)
	_add_hammer_square(Vector2(24.0, -2.0), 13.0, base_color, "Middle", visual_system)
	_add_hammer_square(Vector2(18.0, 7.0), 10.0, base_color.darkened(0.2), "Bottom", visual_system)

func _add_hammer_square(center: Vector2, size: float, fill_color: Color, suffix: String, visual_system: Node) -> void:
	var half := size * 0.5
	var block := Polygon2D.new()
	block.name = "CustomShape_Hammer_" + suffix
	block.polygon = PackedVector2Array([
		Vector2(-half, -half),
		Vector2(half, -half),
		Vector2(half, half),
		Vector2(-half, half)
	])
	block.position = center
	block.color = fill_color
	visual_system.weapon_sprite.add_child(block)


func handle_take_damage(amount: float) -> bool:
	if is_charging:
		var w_owner = weapon_owner
		if w_owner.is_dead:
			return true
		
		# 直接修改从 character_base 继承的 current_health 和 hp 属性
		w_owner.hp -= amount
		w_owner.hp = clamp(w_owner.hp, 0.0, w_owner.max_health)
		w_owner.emit_signal("damaged", amount)
		w_owner.emit_signal("health_changed", w_owner.hp, w_owner.max_health)
		
		if amount > 0.0:
			w_owner.emit_signal("hurt")
		
		# 即使处于霸体，也播放受击闪烁
		if w_owner.get("material"):
			var mat = w_owner.material
			mat.set("shader_parameter/get_hit", true)
			var flash_timer = w_owner.get_tree().create_timer(0.2)
			flash_timer.timeout.connect(func(): if mat: mat.set("shader_parameter/get_hit", false))
			
		if w_owner.hp <= 0:
			w_owner.die()
		
		return true
	return false

func handle_apply_knockback(_force: Vector2) -> bool:
	if is_charging:
		return true
	return false

func grant_dagger_synergy(duration: float = 10.0) -> void:
	dagger_synergy_expire_at = _get_now_seconds() + duration
	print("锤子：获得短剑连携位移强化，持续", duration, "秒")

func grant_bow_synergy(duration: float = 10.0) -> void:
	bow_synergy_expire_at = _get_now_seconds() + duration
	bow_synergy_active_for_next_attack = true
	print("锤子：获得弓箭连携爆炸强化，持续", duration, "秒")

func _is_bow_synergy_active() -> bool:
	return bow_synergy_active_for_next_attack and _get_now_seconds() < bow_synergy_expire_at

func _is_dagger_synergy_active() -> bool:
	return _get_now_seconds() < dagger_synergy_expire_at

func _get_now_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0

func _fire_explosive_arrow(target_pos: Vector2) -> void:
	if not is_instance_valid(weapon_owner): return
	
	print("锤子：释放爆炸箭！目标点：", target_pos)
	var start_pos = weapon_owner.global_position
	
	if ArrowScene:
		var arrow = ArrowScene.instantiate()
		arrow.global_position = start_pos
		arrow.direction = (target_pos - start_pos).normalized()
		
		# 将箭矢移动交由 Tween 控制
		arrow.set_physics_process(false)
		arrow.set_deferred("monitoring", false)
		arrow.set_deferred("monitorable", false)
		
		arrow.rotation = arrow.direction.angle()
		arrow.modulate = Color(1.0, 0.4, 0.0)
		arrow.scale = Vector2(1.5, 1.5)
		
		get_tree().current_scene.add_child(arrow)
		
		var dist = start_pos.distance_to(target_pos)
		var flight_time = dist / 600.0
		if flight_time < 0.1:
			flight_time = 0.1
			
		var tween = arrow.create_tween()
		tween.tween_property(arrow, "global_position", target_pos, flight_time)
		
		tween.finished.connect(func():
			if is_instance_valid(arrow):
				_explode_at(target_pos)
				arrow.queue_free()
		)
	else:
		_explode_at(target_pos)

func _explode_at(point: Vector2) -> void:
	if not is_instance_valid(weapon_owner): return
	
	print("锤子：爆炸箭在落点爆炸！爆炸半径：", explosive_radius)
	var space_state = weapon_owner.get_world_2d().direct_space_state
	var params = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = explosive_radius
	params.shape = shape
	params.transform = Transform2D(0, point)
	params.collide_with_areas = false
	params.collide_with_bodies = true
	
	var results = space_state.intersect_shape(params)
	var hit_targets = []
	for res in results:
		var collider = res.collider
		if collider and not collider.has_method("take_damage") and collider.get_parent():
			collider = collider.get_parent()
			
		if collider and collider.has_method("take_damage") and not collider.get("is_dead"):
			if not hit_targets.has(collider):
				if collider != weapon_owner:
					hit_targets.append(collider)
	
	for target in hit_targets:
		var synergy_damage = damage * explosive_damage_multiplier
		deal_damage(target, synergy_damage)
		
		var dir_to_enemy = (target.global_position - point).normalized()
		if dir_to_enemy == Vector2.ZERO:
			dir_to_enemy = Vector2.RIGHT
			
		if target.has_method("apply_knockback"):
			target.apply_knockback(dir_to_enemy * explosive_knockback)
		elif "velocity" in target:
			target.velocity = target.velocity + dir_to_enemy * explosive_knockback
			if target.has_method("move_and_slide"):
				target.move_and_slide()
				
	add_combo(1)

func _try_synergy_blink(mouse_pos: Vector2) -> void:
	var target = _find_enemy_near_mouse(mouse_pos)
	_try_synergy_blink_target(target)

func _try_synergy_blink_target(target: Node) -> void:
	if not is_instance_valid(target) or target.get("is_dead"):
		return

	var dir = (weapon_owner.global_position - target.global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.LEFT

	weapon_owner.global_position = target.global_position + dir * dagger_synergy_blink_offset
	blink_knockback_target = target
	print("锤子：连携位移触发，闪现到目标身边")

func _apply_synergy_knockback(target: Node) -> void:
	var dir = (target.global_position - weapon_owner.global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT

	if target.has_method("apply_knockback"):
		target.apply_knockback(dir * dagger_synergy_knockback)
	elif "velocity" in target:
		target.velocity = target.velocity + dir * dagger_synergy_knockback
		if target.has_method("move_and_slide"):
			target.move_and_slide()
	print("锤子：连携击飞生效")

func _find_enemy_near_mouse(mouse_pos: Vector2) -> Node:
	var space_state = weapon_owner.get_world_2d().direct_space_state
	var params = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = dagger_synergy_blink_radius
	params.shape = shape
	params.transform = Transform2D(0, mouse_pos)
	params.collide_with_areas = false
	params.collide_with_bodies = true

	var results = space_state.intersect_shape(params)
	for res in results:
		if res.collider and (res.collider is Enemy):
			return res.collider
		elif res.collider and (res.collider.get_parent() is Enemy):
			return res.collider.get_parent()
	return null
