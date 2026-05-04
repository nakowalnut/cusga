extends CharacterBase
class_name Player
@export var prev_weapon_ani: AnimatedSprite2D
@export var new_weapon_ani: AnimatedSprite2D
#@export var ULTIMATE_MAX_POINTS: int = 3 # 测试大招次数，平时是10
#@export var ULTIMATE_DURATION: float = 150.0 # 大招持续时间，可在Inspector里调整
@export var animationsprite2d_node: AnimatedSprite2D
@export_group("Stats")
@export var weapon_manager: WeaponManager
@export var ultimate_system: UltimateSystem

#const ULTIMATE_ARROW_SCENE = preload("res://Scenes/Prefab/arrow_projectile.tscn")
#const ULTIMATE_ARROW_DAMAGE: float = 4.0

## ---- 常量定义 ----
@onready var animation_player = $AnimationPlayer

## 检查是否处于无法切换状态的硬直中
func can_change_state() -> bool:
	# 1. 检查是否处于攻击流程中
	if attack_controller and attack_controller.is_busy():
			return false
	
	# 2. 检查基础状态机当前是否处于 受击 或 死亡 状态
	if c_state_machine.is_in_state(STATE_HURT) or c_state_machine.is_in_state(STATE_DIED):
		return false
		
	return true



# 演示用节点引用
@onready var weapon_holder = $WeaponHolder
@onready var weapon_sprite = $WeaponHolder/CurrentWeapon 
@onready var weapon_hitbox = $WeaponHolder/CurrentWeapon/HitBox
@onready var attack_collider = $AttackHitBox/AttackCollider
@onready var modifier_system: ModifierSystem = get_node_or_null("ModifierSystem")
@onready var equipment_manager: EquipmentManager = get_node_or_null("EquipmentManager")

@export_group("Equipment")
@export var default_equip_head: String = ""
@export var default_equip_body: String = ""
@export var default_equip_foot: String = ""

func _ready() -> void:
	anim = $AnimationPlayer
	GameManager.player = self
	super._ready()
	_init_combat_systems()
	
	# 初始化连携管理器
	var combo_manager = ComboManagerClass.new()
	combo_manager.name = "ComboManager"
	add_child(combo_manager)
	
	if weapon_manager:
		# 必须先绑定信号，再初始化武器（init_weapons 内部会 emit weapon_switched）
		weapon_manager.weapon_switched.connect(func(w_id): _update_weapon_visual())
		weapon_manager.init_weapons()

	# 连接武器自己的攻击判定信号
	weapon_hitbox.area_entered.connect(_on_weapon_hitbox_area_entered)
	weapon_hitbox.body_entered.connect(_on_weapon_hitbox_body_entered)
	weapon_hitbox.monitoring = false
	if attack_controller:
		if not attack_controller.active_started.is_connected(_on_attack_active_started_player):
			attack_controller.active_started.connect(_on_attack_active_started_player)
		if not attack_controller.recovery_started.is_connected(_on_attack_recovery_started_player):
			attack_controller.recovery_started.connect(_on_attack_recovery_started_player)
		if not attack_controller.attack_ended.is_connected(_on_attack_ended_player):
			attack_controller.attack_ended.connect(_on_attack_ended_player)

func _init_combat_systems() -> void:
	if not is_instance_valid(modifier_system):
		modifier_system = ModifierSystem.new()
		modifier_system.name = "ModifierSystem"
		add_child(modifier_system)

	if not is_instance_valid(equipment_manager):
		equipment_manager = EquipmentManager.new()
		equipment_manager.name = "EquipmentManager"
		add_child(equipment_manager)

	equipment_manager.modifier_system = modifier_system

	modifier_system.set_base_stats({
		"max_hp": max_health,
		"speed": speed,
		"damage_reduction": damage_reduction_ratio
	})

	if not EventBus.on_stat_changed.is_connected(_on_modifier_stat_changed):
		EventBus.on_stat_changed.connect(_on_modifier_stat_changed)

	if default_equip_head != "":
		equipment_manager.equip_item("head", default_equip_head)
	if default_equip_body != "":
		equipment_manager.equip_item("body", default_equip_body)
	if default_equip_foot != "":
		equipment_manager.equip_item("foot", default_equip_foot)

	_sync_stats_from_modifier()

func _sync_stats_from_modifier() -> void:
	if not is_instance_valid(modifier_system):
		return
	max_health = modifier_system.get_stat("max_hp")
	speed = modifier_system.get_stat("speed")
	damage_reduction_ratio = clamp(modifier_system.get_stat("damage_reduction"), 0.0, 0.95)
	current_health = clamp(current_health, 0.0, max_health)

func _on_modifier_stat_changed(stat_name: String, new_value: float) -> void:
	match stat_name:
		"max_hp":
			max_health = new_value
			current_health = clamp(current_health, 0.0, max_health)
		"speed":
			speed = new_value
		"damage_reduction":
			damage_reduction_ratio = clamp(new_value, 0.0, 0.95)
		_:
			pass

func take_damage(amount: float) -> void:
	# 实装伤害减免比率：实际伤害 = 原始伤害 * (1.0 - 减免比率)
	var dr := damage_reduction_ratio
	if is_instance_valid(modifier_system):
		dr = clamp(modifier_system.get_stat("damage_reduction"), 0.0, 0.95)
	var final_damage = amount * (1.0 - dr)
	
	if is_instance_valid(weapon_manager.current_weapon_node) and weapon_manager.current_weapon_node.has_method("handle_take_damage"):
		if weapon_manager.current_weapon_node.handle_take_damage(final_damage):
			return
	super.take_damage(final_damage)
	EventBus.on_damage_taken.emit(final_damage, self)

func apply_knockback(force: Vector2) -> void:
	if is_instance_valid(weapon_manager.current_weapon_node) and weapon_manager.current_weapon_node.has_method("handle_apply_knockback"):
		if weapon_manager.current_weapon_node.handle_apply_knockback(force):
			return
	super.apply_knockback(force)

func _physics_process(_delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	move_and_slide()
	
	# 让武器支架指向鼠标
	_rotate_weapon_to_mouse()
	
	# 输入处理
	_handle_input()

#func _rotate_weapon_to_mouse() -> void:
	#if weapon_holder:
		#var mouse_pos = get_global_mouse_position()
		#weapon_holder.look_at(mouse_pos)


func _on_weapon_hitbox_area_entered(area: Area2D) -> void:
	if area is FieldOfView2D:
		return
	if weapon_hitbox.monitoring and area.get_parent() is Enemy:
		if is_instance_valid(weapon_manager.current_weapon_node):
			weapon_manager.current_weapon_node.on_hit(area.get_parent())
			if ultimate_system.in_ultimate_mode:
				ultimate_system.apply_ultimate_arrow_rain(area.get_parent())
		print("攻击到了(Area)！", area.get_parent().name)

func _on_weapon_hitbox_body_entered(body: Node2D) -> void:
	if weapon_hitbox.monitoring and body is Enemy:
		if is_instance_valid(weapon_manager.current_weapon_node):
			weapon_manager.current_weapon_node.on_hit(body)
			if ultimate_system.in_ultimate_mode:
				ultimate_system.apply_ultimate_arrow_rain(body)
		print("攻击到了(Body)！", body.name)

func _handle_input() -> void:
	if Input.is_action_just_pressed("dodge"):
		if can_change_state():
			c_state_machine.change_state(STATE_DODGE)
			return

	if Input.is_action_just_pressed("ultimate"):
		if ultimate_system:
			ultimate_system.try_cast_ultimate()
		return

	if not can_change_state(): return

	##从UltimateSystem获取状态
	var is_ult = ultimate_system and ultimate_system.in_ultimate_mode
	

	if not is_ult and weapon_manager:
		for i in range(1, weapon_manager.weapon_wheel.size() + 1):
			if Input.is_action_just_pressed("weapon_" + str(i)):
				var result = weapon_manager.switch_and_combo(i-1)
				if result.combo_triggered:
					c_state_machine.change_state(STATE_ATTACK, {
						"weapon": result.new_weapon,
						"prev_weapon": result.prev_weapon,
						"is_switch": true
					})
				return

	if Input.is_action_just_pressed("attack"):
		if is_ult and ultimate_system:
			# 大招中：先循环武器
			ultimate_system.cycle_weapon()

		var cur_id = weapon_manager.get_current_weapon_id() if weapon_manager else ""
		var is_charged := false
		var bypass_charge := is_ult and cur_id == "hammer"

		if weapon_manager:
			weapon_manager.on_attack_pressed()
			is_charged = weapon_manager.is_charge_weapon()
			if bypass_charge:
				is_charged = false

		if not is_charged:
			c_state_machine.change_state(STATE_ATTACK, {
				"weapon": cur_id,
				"prev_weapon": cur_id,
				"is_switch": false
			})
		else:
			_play_charge_animation()

	if Input.is_action_just_released("attack"):
		if weapon_manager:
			weapon_manager.on_attack_released()
			if weapon_manager.is_charge_weapon():
				var cur_id = weapon_manager.get_current_weapon_id()
				c_state_machine.change_state(STATE_ATTACK, {
					"weapon": cur_id,
					"prev_weapon": cur_id,
					"is_switch": false
				})


# 核心演示逻辑
func _update_weapon_visual() -> void:
	if weapon_manager.weapon_wheel.size() == 0: return
	
	var current_weapon_id = weapon_manager.weapon_wheel[weapon_manager.current_weapon_index]
	var weapon = weapon_manager.all_weapons[current_weapon_id]
	weapon_manager.current_weapon_node = weapon
	var hammer = weapon_manager.all_weapons.get("hammer")
	if is_instance_valid(hammer) and hammer.has_method("_clear_custom_weapon_shapes"):
		hammer._clear_custom_weapon_shapes()
	
	# 重置被Tween影响的位置和旋转，防止切枪时由于动画残留导致表现错乱
	if weapon_sprite:
		weapon_sprite.position = Vector2(22, -5)
		weapon_sprite.rotation = -1.16588
	

		
	prev_weapon_ani.animation = animationsprite2d_node.animation
	new_weapon_ani.animation = current_weapon_id
	prev_weapon_ani.visible = true
	new_weapon_ani.visible = true
	animation_player.play("switchweapon")
	prev_weapon_ani.frame = 0
	new_weapon_ani.frame = 0
	# switchweapon 动画轨道的连续更新会锁死子节点帧，动画结束后手动恢复播放
	_ensure_parent_plays_after_switch(current_weapon_id)
	
	# 武器切换（视觉）设置
	if current_weapon_id in ["sword", "bow", "hammer", "spear", "dagger"]:
		animationsprite2d_node.animation = current_weapon_id
	
func _apply_weapon_transforms(weapon_id: String, weapon_color: Color) -> void:
	# 视觉与物理同步变化：CurrentWeapon 是 HitBox 的父节点，缩放会同时影响碰撞判定
	weapon_sprite.scale = Vector2(1.0, 1.125)
	
	match weapon_id:
		"dagger":
			# 短剑：更短
			weapon_sprite.scale = Vector2(0.5, 1.125)
		"spear":
			# 矛：更细、更长
			weapon_sprite.scale = Vector2(1.6, 0.55)
			# 矛头方向与鼠标一致：本地旋转归零，由 weapon_holder.look_at 接管朝向
			weapon_sprite.rotation = 0.0
		"hammer":
			weapon_sprite.scale = Vector2(0.9, 1.0)
			var hammer = weapon_manager.all_weapons.get("hammer")
			if is_instance_valid(hammer) and hammer.has_method("build_hammer_head"):
				hammer.build_hammer_head(weapon_color)
	
	# 如果有攻击判定，可以在这里调整碰撞盒大小模拟不同武器长度
	# attack_collider.shape.extents = Vector2(weapon.attack_range, 10)

func set_weapon_hitbox_active(active: bool) -> void:
	if weapon_hitbox:
		weapon_hitbox.monitoring = active
##预攻击
func pre_attack(msg):
	var current_weapon_id = msg.get("weapon", weapon_manager.weapon_wheel[weapon_manager.current_weapon_index])
	var prev_weapon_id = msg.get("prev_weapon", current_weapon_id)
	var is_switch = msg.get("is_switch", false)
	
	var weapon = weapon_manager.all_weapons[current_weapon_id]
	
	if is_switch:
		print("执行连携攻击: ", prev_weapon_id, " -> ", current_weapon_id)
		_play_attack_visual(current_weapon_id)
	else:
		print("使用武器普通攻击: ", weapon.weapon_name)
		_play_attack_visual(current_weapon_id)
	
	await get_tree().create_timer(0.5).timeout

	if is_switch:
		_update_weapon_visual()

func _play_attack_visual(weapon_id: String) -> void:
	_apply_attack_animation_speed()

	# 在当前的子节点上播放正确的武器动画

	if weapon_id in ["sword", "bow", "hammer" , "spear", "dagger"]:
		animationsprite2d_node.animation = weapon_id
		animationsprite2d_node.play(weapon_id)
	animation_player.play("Attack1")

func _ensure_parent_plays_after_switch(weapon_id: String) -> void:
	if not animation_player.is_playing() or animation_player.current_animation != "switchweapon":
		_finish_switch_to_parent(weapon_id)
		return
	# 断开之前的连接，防止重复绑定
	if animation_player.animation_finished.is_connected(_on_switchweapon_finished):
		animation_player.animation_finished.disconnect(_on_switchweapon_finished)
	animation_player.animation_finished.connect(_on_switchweapon_finished.bind(weapon_id), CONNECT_ONE_SHOT)

func _on_switchweapon_finished(anim_name: String, weapon_id: String) -> void:
	if anim_name == "switchweapon":
		_finish_switch_to_parent(weapon_id)

func _finish_switch_to_parent(weapon_id: String) -> void:
	prev_weapon_ani.visible = false
	new_weapon_ani.visible = false
	animationsprite2d_node.self_modulate = Color(1, 1, 1, 1)
	if weapon_id in ["sword", "bow", "hammer", "spear", "dagger"]:
		animationsprite2d_node.animation = weapon_id
		animationsprite2d_node.play(weapon_id)

var current_weapon_tween: Tween

func _play_charge_animation() -> void:
	if animation_player.is_playing() and animation_player.current_animation.begins_with("Attack"):
		animation_player.stop()
	
	if current_weapon_tween and current_weapon_tween.is_valid():
		current_weapon_tween.kill()
		
	current_weapon_tween = create_tween()
	# 蓄力时将武器向后方高高举起 (旋转角度后仰，并稍微收回)
	var final_rotation = weapon_sprite.rotation - deg_to_rad(45.0)
	var final_position = weapon_sprite.position + Vector2(-10, -10)
	
	current_weapon_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	current_weapon_tween.tween_property(weapon_sprite, "rotation", final_rotation, 0.4)
	current_weapon_tween.parallel().tween_property(weapon_sprite, "position", final_position, 0.4)

func _spear_poke_animation(total_duration: float) -> void:
	# 停止动画播放器，以免与代码Tween冲突
	if animation_player.is_playing() and animation_player.current_animation.begins_with("Attack"):
		animation_player.stop()

	if current_weapon_tween and current_weapon_tween.is_valid():
		current_weapon_tween.kill()
		
	var base_pos = Vector2(22, -5)
	weapon_sprite.position = base_pos
	# 矛的默认角度由 weapon_holder.look_at 驱动，这里保持本地零旋转
	weapon_sprite.rotation = 0.0
	
	# 向本地 X 轴直接延伸进行“戳”的动作
	# 父节点 weapon_holder 已经 look_at 指向了鼠标，因此增加 X 轴位置即为向前突刺
	var target_pos = base_pos + Vector2(60, 0)
	var poke_time = max(total_duration * 0.35, 0.04)
	var back_time = max(total_duration * 0.65, 0.06)
	
	current_weapon_tween = create_tween()
	# 快速突刺
	current_weapon_tween.tween_property(weapon_sprite, "position", target_pos, poke_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# 慢速收回
	current_weapon_tween.tween_property(weapon_sprite, "position", base_pos, back_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func player_attack():
	var character = self
	var current_weapon_node = character.weapon_manager.current_weapon_node
	var move_speed_multiplier: float = 1.0
	var base_move_speed: float = float(character.speed)
	if is_instance_valid(modifier_system):
		base_move_speed = modifier_system.get_stat("speed")
	if is_instance_valid(current_weapon_node):
		move_speed_multiplier = float(current_weapon_node.get("movement_speed_multiplier") if current_weapon_node.get("movement_speed_multiplier") != null else 1.0)
		
	# 攻击时保持可移动，但根据当前武器调整移速
	if Input.get_axis("move_left", "move_right") != 0:
		character.toward = int(Input.get_axis("move_left", "move_right"))
		character.velocity.x = character.toward * base_move_speed * move_speed_multiplier
		character.anim.play("walk")
	elif Input.get_axis("up", "down") != 0:
		character.velocity.y = int(Input.get_axis("up", "down")) * base_move_speed * move_speed_multiplier
	else:
		if character.hp > 0:
			character.velocity = Vector2.ZERO

## 重写基类方法 ds
func begin_attack(msg: Dictionary) -> bool:
	if weapon_manager.weapon_wheel.size() == 0:
		if c_state_machine:
			c_state_machine.change_state(STATE_IDLE)
		return false
	if attack_controller and not attack_controller.can_start_attack():
		return false
	if attack_controller and is_instance_valid(weapon_manager.current_weapon_node):
		attack_controller.configure_from_weapon(weapon_manager.current_weapon_node)
	is_attacking = true
	pre_attack(msg)
	if attack_controller:
		return attack_controller.start_attack()
	return true

func process_movement(delta: float) -> void:
	var current_speed := speed
	if is_instance_valid(modifier_system):
		current_speed = modifier_system.get_stat("speed")
	if Input.get_axis("move_left", "move_right") != 0:
		toward = int(Input.get_axis("move_left", "move_right"))
		velocity.x = toward * current_speed
		if anim and anim.has_animation("walk"): anim.play("walk")
	if Input.get_axis("up", "down") != 0:
		velocity.y = int(Input.get_axis("up", "down")) * current_speed
		
	if Input.get_axis("move_left", "move_right") == 0 and Input.get_axis("up", "down") == 0:
		if hp > 0 and c_state_machine:
			c_state_machine.change_state(STATE_IDLE)

func process_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	# 检查是否应该切换到移动状态
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or Input.is_action_pressed("up") or Input.is_action_pressed("down"):
		if c_state_machine:
			c_state_machine.change_state(STATE_WALK)

func on_death_state_entered() -> void:
	GameManager.player_die()

func end_attack() -> void:
	is_attacking = false
	if animation_player:
		animation_player.speed_scale = 1.0
	set_weapon_hitbox_active(false)

func process_attack_physics(delta: float) -> void:
	player_attack()

func _apply_attack_animation_speed() -> void:
	if not animation_player:
		return
	if not animation_player.has_animation("Attack1"):
		return
	var total_time = weapon_manager.get_attack_total_duration()
	var anim_len = animation_player.get_animation("Attack1").length
	if anim_len <= 0.0:
		animation_player.speed_scale = 1.0
		return
	var atk_speed_multiplier := 1.0
	if is_instance_valid(modifier_system):
		atk_speed_multiplier = max(modifier_system.get_stat("atk_speed"), 0.1)
	animation_player.speed_scale = (anim_len / total_time) * atk_speed_multiplier

func _on_attack_active_started_player(_duration: float) -> void:
	weapon_manager.execute_attack(get_global_mouse_position())
	set_weapon_hitbox_active(true)

func _on_attack_recovery_started_player(_duration: float) -> void:
	set_weapon_hitbox_active(false)

func _on_attack_ended_player() -> void:
	set_weapon_hitbox_active(false)

func add_ultimate_point() -> void:
	if ultimate_system:
		ultimate_system.add_point()
