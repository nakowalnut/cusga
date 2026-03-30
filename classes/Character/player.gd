extends CharacterBase
class_name Player

@onready var animation_player = $AnimationPlayer

## 检查是否处于无法切换状态的硬直中
func can_change_state() -> bool:
	# 1. 检查是否正在播放攻击动画 
	if animation_player.is_playing():
		var anim_name = animation_player.current_animation
		if anim_name.begins_with("attack"):
			return false
	
	# 2. 检查基础状态机当前是否处于 受击 或 死亡 状态
	if c_state_machine.is_in_state("Hurt") or c_state_machine.is_in_state("Died"):
		return false
		
	return true

# 武器库 (实体的 Node 节点)
var all_weapons: Dictionary = {}

# 当前武器轮 (玩家可自定义顺序)
var weapon_wheel: Array[String] = ["sword", "spear", "dagger", "bow", "hammer"]
var current_weapon_index: int = 0

var current_weapon_node: WeaponBase = null

# 演示用节点引用
@onready var weapon_holder = $WeaponHolder
@onready var weapon_sprite = $WeaponHolder/CurrentWeapon 
@onready var weapon_hitbox = $WeaponHolder/CurrentWeapon/HitBox
@onready var attack_collider = $AttackHitBox/AttackCollider

func _ready() -> void:
	anim = $AnimationPlayer
	GameManager.player = self
	_init_weapons()
	# 初始更新一次视觉
	_update_weapon_visual()
	# 连接武器自己的攻击判定信号
	weapon_hitbox.area_entered.connect(_on_weapon_hitbox_area_entered)
	weapon_hitbox.body_entered.connect(_on_weapon_hitbox_body_entered)
	weapon_hitbox.monitoring = false

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
	if weapon_hitbox.monitoring and area.get_parent() is Enemy:
		if is_instance_valid(current_weapon_node):
			current_weapon_node.on_hit(area.get_parent())
		print("攻击到了(Area)！", area.get_parent().name)

func _on_weapon_hitbox_body_entered(body: Node2D) -> void:
	if weapon_hitbox.monitoring and body is Enemy:
		if is_instance_valid(current_weapon_node):
			current_weapon_node.on_hit(body)
		print("攻击到了(Body)！", body.name)

func _handle_input() -> void:
	# 检查切换前置条件：必须没有正在攻击，且没在受击/死亡中
	if not can_change_state(): 
		return

	# 处理数字键切换武器并触发攻击
	for i in range(1, weapon_wheel.size() + 1):
		var action_name = "weapon_" + str(i)
		if Input.is_action_just_pressed(action_name):
			_switch_and_attack(i - 1)
			return

	# 平A (鼠标点击)
	if Input.is_action_just_pressed("attack"):
		var cur_weapon_id = weapon_wheel[current_weapon_index]
		var is_charged_type = false
		if is_instance_valid(current_weapon_node):
			current_weapon_node.on_attack_pressed()
			is_charged_type = current_weapon_node.get("is_charge_weapon")
		
		# 如果不是蓄力武器，直接发起攻击状态
		if not is_charged_type:
			c_state_machine.change_state("Attack", {
				"weapon": cur_weapon_id, 
				"prev_weapon": cur_weapon_id, 
				"is_switch": false
			})
			print("攻击按下")
		else:
			print("蓄力武器，开始举起...")
			_play_charge_animation()
		
	if Input.is_action_just_released("attack"):
		var cur_weapon_id = weapon_wheel[current_weapon_index]
		var is_charged_type = false
		if is_instance_valid(current_weapon_node):
			current_weapon_node.on_attack_released()
			is_charged_type = current_weapon_node.get("is_charge_weapon")
			
		# 对于蓄力武器，松开时才真正触发攻击挥舞
		if is_charged_type:
			if current_weapon_tween and current_weapon_tween.is_valid():
				current_weapon_tween.kill() # 停掉蓄力的动画
			c_state_machine.change_state("Attack", {
				"weapon": cur_weapon_id, 
				"prev_weapon": cur_weapon_id, 
				"is_switch": false
			})
			print("蓄力释放，执行攻击")


# 处理切换武器并攻击
func _switch_and_attack(new_index: int) -> void:
	if new_index < 0 or new_index >= weapon_wheel.size(): return
	var prev_weapon = weapon_wheel[current_weapon_index]

	# 如果切换武器，先让旧武器结算连携技并重置累积次数
	if current_weapon_index != new_index and is_instance_valid(current_weapon_node):
		current_weapon_node.on_switch_out(weapon_wheel[new_index])
		
	current_weapon_index = new_index
	var new_weapon = weapon_wheel[current_weapon_index]
	
	_update_weapon_visual()
	
	# 切枪算作攻击，进入Attack状态并传递连携信息
	c_state_machine.change_state("Attack", {
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
		# 视觉与物理同步变化：CurrentWeapon 是 HitBox 的父节点，缩放会同时影响碰撞判定
		weapon_sprite.scale = Vector2(1.0, 1.125)
		match current_weapon_id:
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
				_build_hammer_head(weapon.color)
			_:
				pass
	
	# 同步攻击判定范围的掩码和层，确保能检测到敌人 (Layer 3/Collision Mask 4)
	if weapon_hitbox:
		# 强制重新获取实时层级 (如果需要动态更新，可以在此处根据具体敌人场景调整掩码)
		# 默认敌人层为 4 (1 << 2)
		weapon_hitbox.collision_mask = 4 
		weapon_hitbox.collision_layer = 0 # 攻击判定不需要被别人撞，只需要去撞别人
	
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
		if current_weapon_id == "spear":
			_spear_poke_animation()
		else:
			animation_player.play("Attack1") 
	else:
		print("使用武器普通攻击: ", weapon.weapon_name)
		if current_weapon_id == "spear":
			_spear_poke_animation()
		else:
			animation_player.play("Attack1") 
	
	# 调用武器子类的特定攻击逻辑（位移、射箭等）
	var mouse_pos = get_global_mouse_position()
	weapon.attack(mouse_pos)
	
	_update_weapon_visual()
	set_weapon_hitbox_active(true)

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
	var is_bow = current_weapon_node != null and current_weapon_node.weapon_name == "弓"
		
	if is_bow:
		# 弓箭攻击时必定无法移动
		character.velocity = Vector2.ZERO
	else:
		# 其它武器支持普通移动（或者根据你的游戏设定修改）
		if Input.get_axis("move_left", "move_right") != 0:
			character.toward = int(Input.get_axis("move_left", "move_right"))
			character.velocity.x = character.toward * character.speed
			character.anim.play("walk")
		elif Input.get_axis("up", "down") != 0:
			character.velocity.y = int(Input.get_axis("up", "down")) * character.speed
		else:
			if character.hp > 0:
				character.velocity = Vector2.ZERO
