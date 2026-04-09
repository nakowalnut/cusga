extends CharacterBase
class_name Player

@export var ULTIMATE_MAX_POINTS: int = 3 # 测试大招次数，平时是10
const ULTIMATE_ARROW_SCENE = preload("res://Scenes/Prefab/arrow_projectile.tscn")
const ULTIMATE_ARROW_DAMAGE: float = 4.0

## ---- 常量定义 ----
@onready var animation_player = $AnimationPlayer

## 检查是否处于无法切换状态的硬直中
func can_change_state() -> bool:
	# 1. 检查是否正在播放攻击动画 
	if animation_player.is_playing():
		var anim_name = animation_player.current_animation
		if anim_name.begins_with("attack"):
			return false
	
	# 2. 检查基础状态机当前是否处于 受击 或 死亡 状态
	if c_state_machine.is_in_state(STATE_HURT) or c_state_machine.is_in_state(STATE_DIED):
		return false
		
	return true

# 武器库 (实体的 Node 节点)
var all_weapons: Dictionary = {}

# 当前武器轮 (玩家可自定义顺序)
var weapon_wheel: Array[String] = ["sword", "spear", "dagger", "bow", "hammer"]
var current_weapon_index: int = 0

var current_weapon_node: WeaponBase = null
var ultimate_points: int = 0
var in_ultimate_mode: bool = false
var ultimate_weapon_cycle: Array[String] = ["sword", "dagger", "spear", "hammer"]
var ultimate_cycle_index: int = -1

# 演示用节点引用
@onready var weapon_holder = $WeaponHolder
@onready var weapon_sprite = $WeaponHolder/CurrentWeapon 
@onready var weapon_hitbox = $WeaponHolder/CurrentWeapon/HitBox
@onready var attack_collider = $AttackHitBox/AttackCollider

func _ready() -> void:
	anim = $AnimationPlayer
	GameManager.player = self
	
	# 初始化连携管理器
	var combo_manager = ComboManagerClass.new()
	combo_manager.name = "ComboManager"
	add_child(combo_manager)
	
	_init_weapons()
	# 初始更新一次视觉
	_update_weapon_visual()
	# 连接武器自己的攻击判定信号
	weapon_hitbox.area_entered.connect(_on_weapon_hitbox_area_entered)
	weapon_hitbox.body_entered.connect(_on_weapon_hitbox_body_entered)
	weapon_hitbox.monitoring = false

func take_damage(amount: float) -> void:
	if is_instance_valid(current_weapon_node) and current_weapon_node.has_method("handle_take_damage"):
		if current_weapon_node.handle_take_damage(amount):
			return
	super.take_damage(amount)

func apply_knockback(force: Vector2) -> void:
	if is_instance_valid(current_weapon_node) and current_weapon_node.has_method("handle_apply_knockback"):
		if current_weapon_node.handle_apply_knockback(force):
			return
	super.apply_knockback(force)

func _init_weapons() -> void:
	# 实例化所有武器，并放入节点树成为子节点，这样就可以使用 Timer 或者 process 逻辑
	all_weapons["sword"] = SwordWeapon.new()
	all_weapons["spear"] = SpearWeapon.new()
	all_weapons["dagger"] = DaggerWeapon.new()
	all_weapons["bow"] = BowWeapon.new()
	all_weapons["hammer"] = HammerWeapon.new()
	
	for key in all_weapons:
		var wp = all_weapons[key]
		wp.weapon_owner = self
		weapon_holder.add_child(wp)

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

func _rotate_weapon_to_mouse() -> void:
	if weapon_holder:
		var mouse_pos = get_global_mouse_position()
		weapon_holder.look_at(mouse_pos)


func _on_weapon_hitbox_area_entered(area: Area2D) -> void:
	if area is FieldOfView2D:
		return
	if weapon_hitbox.monitoring and area.get_parent() is Enemy:
		if is_instance_valid(current_weapon_node):
			current_weapon_node.on_hit(area.get_parent())
			if in_ultimate_mode:
				apply_ultimate_arrow_rain(area.get_parent())
		print("攻击到了(Area)！", area.get_parent().name)

func _on_weapon_hitbox_body_entered(body: Node2D) -> void:
	if weapon_hitbox.monitoring and body is Enemy:
		if is_instance_valid(current_weapon_node):
			current_weapon_node.on_hit(body)
			if in_ultimate_mode:
				apply_ultimate_arrow_rain(body)
		print("攻击到了(Body)！", body.name)

func _handle_input() -> void:
	if Input.is_action_just_pressed("ultimate"):
		_try_cast_ultimate()
		return

	# 检查切换前置条件：必须没有正在攻击，且没在受击/死亡中
	if not can_change_state(): 
		return

	# 处理数字键切换武器并触发攻击
	if not in_ultimate_mode:
		for i in range(1, weapon_wheel.size() + 1):
			var action_name = "weapon_" + str(i)
			if Input.is_action_just_pressed(action_name):
				_switch_and_attack(i - 1)
				return

	# 平A (鼠标点击)
	if Input.is_action_just_pressed("attack"):
		if in_ultimate_mode:
			_cycle_ultimate_weapon_before_attack()

		var cur_weapon_id = weapon_wheel[current_weapon_index]
		var is_charged_type = false
		var bypass_charge = in_ultimate_mode and cur_weapon_id == "hammer"
		if is_instance_valid(current_weapon_node):
			current_weapon_node.on_attack_pressed()
			is_charged_type = current_weapon_node.get("is_charge_weapon")
			if bypass_charge:
				is_charged_type = false
		
		# 如果不是蓄力武器，直接发起攻击状态
		if not is_charged_type:
			c_state_machine.change_state(STATE_ATTACK, {
				"weapon": cur_weapon_id, 
				"prev_weapon": cur_weapon_id, 
				"is_switch": false
			})
			print("攻击按下")
		else:
			print("蓄力武器，开始举起...")
			_play_charge_animation()
		
	if Input.is_action_just_released("attack"):
		if in_ultimate_mode and weapon_wheel[current_weapon_index] == "hammer":
			return

		var cur_weapon_id = weapon_wheel[current_weapon_index]
		var is_charged_type = false
		if is_instance_valid(current_weapon_node):
			current_weapon_node.on_attack_released()
			is_charged_type = current_weapon_node.get("is_charge_weapon")
			
		# 对于蓄力武器，松开时才真正触发攻击挥舞
		if is_charged_type:
			if current_weapon_tween and current_weapon_tween.is_valid():
				current_weapon_tween.kill() # 停掉蓄力的动画
			c_state_machine.change_state(STATE_ATTACK, {
				"weapon": cur_weapon_id, 
				"prev_weapon": cur_weapon_id, 
				"is_switch": false
			})
			print("蓄力释放，执行攻击")


# 处理切换武器；只有连携技真的触发时才进入攻击态
func _switch_and_attack(new_index: int) -> void:
	if in_ultimate_mode:
		return

	if new_index < 0 or new_index >= weapon_wheel.size(): return
	var prev_weapon = weapon_wheel[current_weapon_index]
	var new_weapon_id = weapon_wheel[new_index]

	# 无论是否切换同样武器，只要发起按键都结算旧武器状态
	var combo_triggered := false
	if is_instance_valid(current_weapon_node):
		combo_triggered = current_weapon_node.on_switch_out(new_weapon_id)
		
	current_weapon_index = new_index
	var new_weapon = weapon_wheel[current_weapon_index]
	
	_update_weapon_visual()
	
	if combo_triggered:
		# 只有连携技命中时才把切枪视为一次攻击
		c_state_machine.change_state(STATE_ATTACK, {
			"weapon": new_weapon, 
			"prev_weapon": prev_weapon, 
			"is_switch": true
		})
		print("切换攻击，从 ", prev_weapon, " 切换到 ", new_weapon)

# 核心演示逻辑：更换棍子颜色
func _update_weapon_visual() -> void:
	if weapon_wheel.size() == 0: return
	
	var current_weapon_id = weapon_wheel[current_weapon_index]
	var weapon = all_weapons[current_weapon_id]
	current_weapon_node = weapon
	_clear_custom_weapon_shapes()
	
	# 重置被Tween影响的位置和旋转，防止切枪时由于动画残留导致表现错乱
	if weapon_sprite:
		weapon_sprite.position = Vector2(22, -5)
		weapon_sprite.rotation = -1.16588
	
	# 通过调制颜色 (Self Modulate) 来模拟武器切换
	if weapon_sprite:
		weapon_sprite.self_modulate = weapon.color
		_apply_weapon_transforms(current_weapon_id, weapon.color)

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
			# 锤子：杆保持中等长度，头部由多个方块拼接
			weapon_sprite.scale = Vector2(0.9, 1.0)
			_build_hammer_head(weapon_color)
		_:
			pass
	
	# 如果有攻击判定，可以在这里调整碰撞盒大小模拟不同武器长度
	# attack_collider.shape.extents = Vector2(weapon.attack_range, 10)


func _clear_custom_weapon_shapes() -> void:
	if not weapon_sprite:
		return
	for child in weapon_sprite.get_children():
		if child.name.begins_with("CustomShape_"):
			child.free()


func _build_hammer_head(base_color: Color) -> void:
	if not weapon_sprite:
		return
	# 防御性清理：避免同帧重复构建时出现残留
	_clear_custom_weapon_shapes()
	_add_hammer_square(Vector2(18.0, -8.0), 11.0, base_color.lightened(0.15), "Top")
	_add_hammer_square(Vector2(24.0, -2.0), 13.0, base_color, "Middle")
	_add_hammer_square(Vector2(18.0, 7.0), 10.0, base_color.darkened(0.2), "Bottom")


func _add_hammer_square(center: Vector2, size: float, fill_color: Color, suffix: String) -> void:
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
	weapon_sprite.add_child(block)



func set_weapon_hitbox_active(active: bool) -> void:
	if weapon_hitbox:
		weapon_hitbox.monitoring = active

func pre_attack(msg):
	var current_weapon_id = msg.get("weapon", weapon_wheel[current_weapon_index])
	var prev_weapon_id = msg.get("prev_weapon", current_weapon_id)
	var is_switch = msg.get("is_switch", false)
	
	var weapon = all_weapons[current_weapon_id]
	
	if is_switch:
		print("执行连携攻击: ", prev_weapon_id, " -> ", current_weapon_id)
		_play_attack_visual(current_weapon_id)
	else:
		print("使用武器普通攻击: ", weapon.weapon_name)
		_play_attack_visual(current_weapon_id)
	
	# 调用武器子类的特定攻击逻辑（位移、射箭等）
	var mouse_pos = get_global_mouse_position()
	weapon.attack(mouse_pos)
	
	_update_weapon_visual()
	set_weapon_hitbox_active(true)

func _play_attack_visual(weapon_id: String) -> void:
	if weapon_id == "spear":
		_spear_poke_animation()
	else:
		animation_player.play("Attack1") 

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

func _spear_poke_animation() -> void:
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
	
	current_weapon_tween = create_tween()
	# 快速突刺
	current_weapon_tween.tween_property(weapon_sprite, "position", target_pos, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# 慢速收回
	current_weapon_tween.tween_property(weapon_sprite, "position", base_pos, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func player_attack():
	var character = self
	var current_weapon_node = character.current_weapon_node
	var move_speed_multiplier := 1.0
	if is_instance_valid(current_weapon_node):
		move_speed_multiplier = current_weapon_node.movement_speed_multiplier
		
	# 攻击时保持可移动，但根据当前武器调整移速
	if Input.get_axis("move_left", "move_right") != 0:
		character.toward = int(Input.get_axis("move_left", "move_right"))
		character.velocity.x = character.toward * character.speed * move_speed_multiplier
		character.anim.play("walk")
	elif Input.get_axis("up", "down") != 0:
		character.velocity.y = int(Input.get_axis("up", "down")) * character.speed * move_speed_multiplier
	else:
		if character.hp > 0:
			character.velocity = Vector2.ZERO

## ---- 状态机重构：重写基类方法 ----
func begin_attack(msg: Dictionary) -> bool:
	if weapon_wheel.size() == 0:
		if c_state_machine:
			c_state_machine.change_state(STATE_IDLE)
		return false
	is_attacking = true
	pre_attack(msg)
	return true

func process_movement(delta: float) -> void:
	if Input.get_axis("move_left", "move_right") != 0:
		toward = int(Input.get_axis("move_left", "move_right"))
		velocity.x = toward * speed
		if anim and anim.has_animation("walk"): anim.play("walk")
	if Input.get_axis("up", "down") != 0:
		velocity.y = int(Input.get_axis("up", "down")) * speed
		
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
	set_weapon_hitbox_active(false)

func process_attack_physics(delta: float) -> void:
	player_attack()

func execute_attack() -> void:
	pass # Player在 pre_attack 中就触发了武器逻辑，这里留空或后续合并

func get_attack_duration() -> float:
	if is_instance_valid(current_weapon_node):
		return current_weapon_node.attack_duration
	return 0.3

func add_ultimate_point(amount: int = 1) -> void:
	if amount <= 0:
		return
	ultimate_points = min(ULTIMATE_MAX_POINTS, ultimate_points + amount)
	print("[Ultimate] 点数: ", ultimate_points, "/", ULTIMATE_MAX_POINTS)
	if ultimate_points == ULTIMATE_MAX_POINTS:
		print("[Ultimate] 大招已就绪！可以按下 ultimate 键释放！")

func on_ultimate_started() -> void:
	ultimate_cycle_index = -1

func on_ultimate_ended() -> void:
	ultimate_cycle_index = -1

func _try_cast_ultimate() -> void:
	if in_ultimate_mode:
		return
	if ultimate_points < ULTIMATE_MAX_POINTS:
		print("[Ultimate] 点数不足: ", ultimate_points, "/", ULTIMATE_MAX_POINTS)
		return
	print("[Ultimate] 大招触发！状态锁定接管：开始连续乱舞！")
	ultimate_points = 0
	in_ultimate_mode = true
	on_ultimate_started()
	
	# 这里大招是一直存在的BUFF状态（而不是切换节点），由定时器负责结束，以免跟基础的Attack状态相冲突结束
	var timer := get_tree().create_timer(15.0)
	timer.timeout.connect(func():
		in_ultimate_mode = false
		on_ultimate_ended()
		print("[Ultimate] 大招时间到，效果结束")
	)

func _cycle_ultimate_weapon_before_attack() -> void:
	if ultimate_weapon_cycle.is_empty():
		return

	ultimate_cycle_index = (ultimate_cycle_index + 1) % ultimate_weapon_cycle.size()
	var target_weapon_id = ultimate_weapon_cycle[ultimate_cycle_index]
	var idx = weapon_wheel.find(target_weapon_id)
	if idx == -1:
		weapon_wheel.append(target_weapon_id)
		idx = weapon_wheel.size() - 1

	current_weapon_index = idx
	_update_weapon_visual()

func apply_ultimate_arrow_rain(target: Node) -> void:
	if not in_ultimate_mode or not is_instance_valid(target) or target.get("is_dead"):
		return
	if target.has_meta("ultimate_rain"):
		return
	target.set_meta("ultimate_rain", true)
	print("弓箭雨降临：目标 ", target.name)
	
	var rain_timer = Timer.new()
	rain_timer.wait_time = 0.5
	rain_timer.autostart = true
	var count = [0]
	rain_timer.timeout.connect(func():
		if not is_instance_valid(target) or target.get("is_dead") or count[0] >= 10:
			if is_instance_valid(target):
				target.remove_meta("ultimate_rain")
			if is_instance_valid(rain_timer):
				rain_timer.queue_free()
			return
		count[0] += 1
		spawn_ultimate_followup_arrow(target)
	)
	target.add_child(rain_timer)

func spawn_ultimate_followup_arrow(target: Node) -> void:
	if not in_ultimate_mode:
		return
	if not is_instance_valid(target):
		return
	if target.get("is_dead"):
		return
	if not ULTIMATE_ARROW_SCENE:
		return
	if not is_instance_valid(get_tree().current_scene):
		return

	var arrow = ULTIMATE_ARROW_SCENE.instantiate()
	var random_offset_x = randf_range(-24.0, 24.0)
	var spawn_pos = target.global_position + Vector2(random_offset_x, -220.0)
	arrow.global_position = spawn_pos
	arrow.direction = (target.global_position - spawn_pos).normalized()
	arrow.speed = 900.0
	arrow.life_time = 1.2
	arrow.direct_damage = ULTIMATE_ARROW_DAMAGE
	arrow.trigger_weapon_on_hit = false

	if all_weapons.has("bow"):
		arrow.weapon_owner = all_weapons["bow"]
	else:
		arrow.weapon_owner = current_weapon_node

	get_tree().current_scene.add_child(arrow)
