extends CharacterBase
class_name Player



@onready var anim = $AnimatedSprite2D
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
var is_attacking: bool = false
var current_weapon_node: WeaponBase = null

# 演示用节点引用
@onready var weapon_holder = $WeaponHolder
@onready var weapon_sprite = $WeaponHolder/CurrentWeapon 
@onready var weapon_hitbox = $WeaponHolder/CurrentWeapon/HitBox
@onready var attack_collider = $AttackHitBox/AttackCollider

func _ready() -> void:
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
		wp.player = self
		weapon_holder.add_child(wp)

func _physics_process(_delta: float) -> void:
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
		var cur_weapon = weapon_wheel[current_weapon_index]
		c_state_machine.change_state("Attack", {
			"weapon": cur_weapon, 
			"prev_weapon": cur_weapon, 
			"is_switch": false
		})
		print("普通攻击")


# 处理切换武器并攻击
func _switch_and_attack(new_index: int) -> void:
	if new_index < 0 or new_index >= weapon_wheel.size(): return
	var prev_weapon = weapon_wheel[current_weapon_index]
	
	# 如果切换武器，先让旧武器结算连携技并重置累积次数
	if current_weapon_index != new_index and is_instance_valid(current_weapon_node):
		current_weapon_node.on_switch_out()
		
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
	
	# 通过调制颜色 (Self Modulate) 来模拟武器切换
	if weapon_sprite:
		weapon_sprite.self_modulate = weapon.color
	
	# 同步攻击判定范围的掩码和层，确保能检测到敌人 (Layer 3/Collision Mask 4)
	if weapon_hitbox:
		weapon_hitbox.collision_mask = 4 
		weapon_hitbox.collision_layer = 0 # 攻击判定不需要被别人撞，只需要去撞别人
	
	# 如果有攻击判定，可以在这里调整碰撞盒大小模拟不同武器长度
	# attack_collider.shape.extents = Vector2(weapon.attack_range, 10)


# 自定义武器轮接口 (供Tab菜单调用)
func update_weapon_sequence(new_sequence: Array[String]) -> void:
	weapon_wheel = new_sequence
	current_weapon_index = 0


func set_weapon_hitbox_active(active: bool) -> void:
	if weapon_hitbox:
		weapon_hitbox.monitoring = active
