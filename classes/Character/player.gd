extends CharacterBase
class_name Player
@export var prev_weapon_ani: AnimatedSprite2D
@export var new_weapon_ani: AnimatedSprite2D
@export var ULTIMATE_MAX_POINTS: int = 3 # 测试大招次数，平时是10
@export var ULTIMATE_DURATION: float = 150.0 # 大招持续时间，可在Inspector里调整
@export var animationsprite2d_node: AnimatedSprite2D
@export_group("Stats")


const ULTIMATE_ARROW_SCENE = preload("res://Scenes/Prefab/arrow_projectile.tscn")
const ULTIMATE_ARROW_DAMAGE: float = 4.0

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
@export_group("Weapon Tuning")
@export var weapon_tuning_profiles: Array[WeaponTuningProfile] = []

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

var weapon_visual_system
var input_handler: PlayerInputHandler
var ultimate_manager: UltimateSkillManager

func _ready() -> void:
	anim = $AnimationPlayer
	GameManager.player = self
	
	weapon_visual_system = PlayerWeaponVisualSystem.new(self, weapon_sprite, prev_weapon_ani, new_weapon_ani, animation_player, animationsprite2d_node)
	add_child(weapon_visual_system)
	
	input_handler = PlayerInputHandler.new(self)
	input_handler.name = "InputHandler"
	add_child(input_handler)
	
	ultimate_manager = UltimateSkillManager.new(self)
	ultimate_manager.name = "UltimateManager"
	add_child(ultimate_manager)

	super._ready()
	_init_combat_systems()
	
	# 初始化连携管理器
	var combo_manager = ComboManagerClass.new()
	combo_manager.name = "ComboManager"
	add_child(combo_manager)
	
	_init_weapons()
	# 初始更新一次视觉
	weapon_visual_system.update_weapon_visual()
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
	
	if is_instance_valid(current_weapon_node) and current_weapon_node.has_method("handle_take_damage"):
		if current_weapon_node.handle_take_damage(final_damage):
			return
	super.take_damage(final_damage)
	EventBus.on_damage_taken.emit(final_damage, self)

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
		_apply_weapon_tuning(key, wp)
		wp.weapon_owner = self
		weapon_holder.add_child(wp)

func _apply_weapon_tuning(weapon_id: String, weapon: WeaponBase) -> void:
	if not is_instance_valid(weapon):
		return
	for profile in weapon_tuning_profiles:
		if not is_instance_valid(profile):
			continue
		if profile.weapon_id == weapon_id:
			profile.apply_to(weapon)
			if debug_mode:
				print("应用武器调参: ", weapon_id)
			return

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
				ultimate_manager.apply_ultimate_arrow_rain(area.get_parent())
		print("攻击到了(Area)！", area.get_parent().name)

func _on_weapon_hitbox_body_entered(body: Node2D) -> void:
	if weapon_hitbox.monitoring and body is Enemy:
		if is_instance_valid(current_weapon_node):
			current_weapon_node.on_hit(body)
			if in_ultimate_mode:
				ultimate_manager.apply_ultimate_arrow_rain(body)
		print("攻击到了(Body)！", body.name)

func _handle_input() -> void:
	input_handler.handle_input()

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
	
	weapon_visual_system.update_weapon_visual()
	
	if combo_triggered:
		# 只有连携技命中时才把切枪视为一次攻击
		c_state_machine.change_state(STATE_ATTACK, {
			"weapon": new_weapon, 
			"prev_weapon": prev_weapon, 
			"is_switch": true
		})
		print("切换攻击，从 ", prev_weapon, " 切换到 ", new_weapon)

func set_weapon_hitbox_active(active: bool) -> void:
	if weapon_hitbox:
		weapon_hitbox.monitoring = active
##预攻击
func pre_attack(msg):
	var current_weapon_id = msg.get("weapon", weapon_wheel[current_weapon_index])
	var prev_weapon_id = msg.get("prev_weapon", current_weapon_id)
	var is_switch = msg.get("is_switch", false)
	
	var weapon = all_weapons[current_weapon_id]
	
	if is_switch:
		print("执行连携攻击: ", prev_weapon_id, " -> ", current_weapon_id)
		weapon_visual_system.play_attack_visual(current_weapon_id)
	else:
		print("使用武器普通攻击: ", weapon.weapon_name)
		weapon_visual_system.play_attack_visual(current_weapon_id)
	
	await get_tree().create_timer(0.5).timeout

	if is_switch:
		weapon_visual_system.update_weapon_visual()

func player_attack():
	var character = self
	var current_weapon_node = character.current_weapon_node
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

## ---- 状态机重构：重写基类方法 ----
func begin_attack(msg: Dictionary) -> bool:
	if weapon_wheel.size() == 0:
		if c_state_machine:
			c_state_machine.change_state(STATE_IDLE)
		return false
	if attack_controller and not attack_controller.can_start_attack():
		return false
	if attack_controller and is_instance_valid(current_weapon_node):
		attack_controller.configure_from_weapon(current_weapon_node)
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
	weapon_visual_system.reset_weapon_visual()

func process_attack_physics(delta: float) -> void:
	player_attack()

func execute_attack() -> void:
	if is_instance_valid(current_weapon_node):
		var mouse_pos = get_global_mouse_position()
		current_weapon_node.attack(mouse_pos)

func _get_current_attack_total_duration() -> float:
	if is_instance_valid(current_weapon_node):
		return max(
			current_weapon_node.attack_wind_up + current_weapon_node.attack_active + current_weapon_node.attack_recovery,
			0.01
		)
	return 0.3

func _apply_attack_animation_speed() -> void:
	if not animation_player:
		return
	if not animation_player.has_animation("Attack1"):
		return
	var total_time = _get_current_attack_total_duration()
	var anim_len = animation_player.get_animation("Attack1").length
	if anim_len <= 0.0:
		animation_player.speed_scale = 1.0
		return
	var atk_speed_multiplier := 1.0
	if is_instance_valid(modifier_system):
		atk_speed_multiplier = max(modifier_system.get_stat("atk_speed"), 0.1)
	animation_player.speed_scale = (anim_len / total_time) * atk_speed_multiplier

func _on_attack_active_started_player(_duration: float) -> void:
	set_weapon_hitbox_active(true)

func _on_attack_recovery_started_player(_duration: float) -> void:
	set_weapon_hitbox_active(false)

func _on_attack_ended_player() -> void:
	set_weapon_hitbox_active(false)

func add_ultimate_point(amount: int = 1) -> void:
	ultimate_manager.add_ultimate_point(amount)

func on_ultimate_started() -> void:
	ultimate_cycle_index = -1

func on_ultimate_ended() -> void:
	ultimate_cycle_index = -1

func _try_cast_ultimate() -> void:
	ultimate_manager._try_cast_ultimate()

func _cycle_ultimate_weapon_before_attack() -> void:
	ultimate_manager._cycle_ultimate_weapon_before_attack()

func apply_ultimate_arrow_rain(target: Node) -> void:
	ultimate_manager.apply_ultimate_arrow_rain(target)

func spawn_ultimate_followup_arrow(target: Node) -> void:
	ultimate_manager.spawn_ultimate_followup_arrow(target)
