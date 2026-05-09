extends WeaponBase
class_name BowWeapon

const ArrowScene = preload("res://Scenes/Prefab/arrow_projectile.tscn")

var hammer_synergy_expire_at: float = 0.0
var hammer_synergy_active_for_next_attack: bool = false
@export var explosive_damage_multiplier: float = 3.0
@export var explosive_knockback: float = 800.0
@export var explosive_radius: float = 100.0

func _init() -> void:
	weapon_name = "弓"
	damage = 5.0
	attack_range = 300.0
	attack_speed_multiplier = 0.8
	movement_speed_multiplier = 0.5
	color = Color.GREEN
	max_combo = 8
	attack_wind_up = 0.14
	attack_active = 0.06
	attack_recovery = 0.16
	attack_cooldown = 0.12

func attack(target_pos: Vector2) -> void:
	if _is_hammer_synergy_active():
		hammer_synergy_active_for_next_attack = false
		_fire_explosive_arrow(target_pos)
		return

	# 弓攻击时降低移速在 Player 里面处理
	# 发射抛射物
	if ArrowScene:
		var arrow = ArrowScene.instantiate()
		arrow.global_position = weapon_owner.global_position
		arrow.direction = (target_pos - weapon_owner.global_position).normalized()
		arrow.damage = damage
		# 传入 bow 自身以便子弹命中时增加 combo
		arrow.weapon_owner = self 
		arrow.trigger_weapon_on_hit = not is_combo_active
		get_tree().current_scene.add_child(arrow)
	else:
		print("未找到箭矢场景 res://classes/Weapons/arrow_projectile.tscn")

func on_hit(target: Node) -> void:
	# 弓的普通挥打不计入，只有箭矢命中会计入，这里可以通过 arrow 调用
	if not target.is_dead:
		deal_damage(target)
		add_combo(1)

func grant_hammer_synergy(duration: float = 10.0) -> void:
	hammer_synergy_expire_at = _get_now_seconds() + duration
	hammer_synergy_active_for_next_attack = true
	print("弓：获得锤子连携强化，下一次攻击变为爆炸箭，持续", duration, "秒")

func _is_hammer_synergy_active() -> bool:
	return hammer_synergy_active_for_next_attack and _get_now_seconds() < hammer_synergy_expire_at

func _get_now_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0

func _fire_explosive_arrow(target_pos: Vector2) -> void:
	if not is_instance_valid(weapon_owner): return
	
	print("弓：发射爆炸箭！目标点：", target_pos)
	var start_pos = weapon_owner.global_position
	
	if ArrowScene:
		var arrow = ArrowScene.instantiate()
		arrow.global_position = start_pos
		arrow.direction = (target_pos - start_pos).normalized()
		
		# 将箭矢移动交由 Tween 控制，不使用自身的 physics_process 导致飞行过头
		arrow.set_physics_process(false)
		# 关闭碰撞，防止还没到达鼠标落点就被怪物挡下并触发自身逻辑
		arrow.set_deferred("monitoring", false)
		arrow.set_deferred("monitorable", false)
		
		arrow.rotation = arrow.direction.angle()
		arrow.modulate = Color(1.0, 0.4, 0.0) # 橙红色外观
		arrow.scale = Vector2(1.5, 1.5)
		
		get_tree().current_scene.add_child(arrow)
		
		var dist = start_pos.distance_to(target_pos)
		var flight_time = dist / 600.0 # 600 为通常的箭矢速度
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
	
	print("弓：爆炸箭在落点爆炸！爆炸半径：", explosive_radius)
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
		# 兼容 hit_box -> parent
		if collider and not collider.has_method("take_damage") and collider.get_parent():
			collider = collider.get_parent()
			
		if collider and collider.has_method("take_damage") and not collider.get("is_dead"):
			if not hit_targets.has(collider):
				# 防误伤武器持有者自身
				if collider != weapon_owner:
					hit_targets.append(collider)
	
	for target in hit_targets:
		var synergy_damage = damage * explosive_damage_multiplier
		target.take_damage(synergy_damage)
		
		# 强制以爆炸点即 point 为圆心向外击飞
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


func update_weapon_visual(visual_system: Node) -> void:
	visual_system.weapon_sprite.scale = Vector2(1.0, 1.125)
