extends CharacterBody2D
class_name CharacterBase

## 状态名常量
const STATE_HURT = "Hurt"
const STATE_DIED = "Died"
const STATE_IDLE = "Idle"
const STATE_ATTACK = "Attack"
const STATE_WALK = "Walk"
const STATE_ULTIMATE = "Ultimate"
const STATE_DODGE = "Dodge"

## 基础属性
@export var character_weapon: WeaponBase
@export_group("基础属性")
@export var damage_reduction_ratio: float = 0.2 # 减免伤害比率
@export var max_health: float = 100.0
@export var speed: float = 300
@export var dodge_speed: float = 800.0
@export var dodge_duration: float = 0.2
@export var debug_mode: bool = false
@onready var current_health: float = max_health
@export var sight_range: Array[int] = [50, 500]## 感知范围，【临近值，最远值】
var toward: int = 1# 面向方向 (Walk/Hurt 等状态依赖)
@onready var anim: Node ##存储动画
@onready var attack_controller: AttackController = get_node_or_null("AttackController")
var hp: float:
	get: return current_health
	set(value): current_health = value
	
## 状态定义
var is_dead: bool = false
var is_attacking: bool = false
var is_invulnerable: bool = false
## 状态机节点
@export_group("角色状态")
@export var c_state_machine: StateMachine

## 信号
signal health_changed(new_health: float, max_health: float)
signal damaged(amount: float)
signal hurt
signal died

func _ready() -> void:
	if not is_instance_valid(attack_controller):
		attack_controller = AttackController.new()
		attack_controller.name = "AttackController"
		add_child(attack_controller)

	if attack_controller and not attack_controller.active_started.is_connected(_on_attack_active_started):
		attack_controller.active_started.connect(_on_attack_active_started)
	if attack_controller and not attack_controller.attack_ended.is_connected(_on_attack_ended):
		attack_controller.attack_ended.connect(_on_attack_ended)

## 伤害处理
func take_damage(amount: float):
	if is_dead or is_invulnerable:
		return
	
	var old_health = current_health
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)

	if debug_mode:
		var character_type = ""
		if self.get_class() == "Player" or self is Player:
			character_type = "玩家"
		elif self.get_class() == "Enemy" or self is Enemy:
			character_type = "敌人"
		else:
			character_type = "角色"
		
		print("[%s] 血量变化: %.2f -> %.2f (伤害: %.2f)" % [character_type, old_health, current_health, amount])
	
	emit_signal("damaged", amount)
	emit_signal("health_changed", current_health, max_health)
	
	if amount > 0:
		emit_signal("hurt")
	
	if current_health <= 0:
		die()
	else:
		if c_state_machine and c_state_machine.states.has(STATE_HURT):
			c_state_machine.change_state(STATE_HURT)

## 应用击退效果
func apply_knockback(force: Vector2) -> void:
	if is_dead:
		return
	
	# 如果处于动作强控状态（如使用了 Tween 的某些攻击），尝试打断
	if self.has_method("cancel_action_tweens"):
		self.call("cancel_action_tweens")
	
	# 设置初始击退速度，并强制进入受击物理判定
	velocity = force
	if c_state_machine and c_state_machine.states.has(STATE_HURT):
		c_state_machine.change_state(STATE_HURT)

## 死亡逻辑
func die():
	if is_dead:
		return
	is_dead = true
	emit_signal("died")
	
	if c_state_machine and c_state_machine.states.has(STATE_DIED):
		c_state_machine.change_state(STATE_DIED)
	# 可以在子类中重写此方法以实现具体的死亡动画或效果
	#queue_free()

## 获取生命百分比
func get_health_percent() -> float:
	return current_health / max_health
	
func _init_weapons() -> void:
	# 实例化所有武器，并放入节点树成为子节点，这样就可以使用 Timer 或者 process 逻辑
	pass

func begin_attack(msg: Dictionary) -> bool:
	if attack_controller and not attack_controller.can_start_attack():
		return false

	if attack_controller and is_instance_valid(character_weapon):
		attack_controller.configure_from_weapon(character_weapon)

	is_attacking = true
	pre_attack(msg)
	if attack_controller:
		return attack_controller.start_attack()
	return true

func pre_attack(msg: Dictionary):
	pass

func execute_attack() -> void:
	if is_instance_valid(character_weapon):
		character_weapon.attack(global_position)

func end_attack() -> void:
	is_attacking = false

func process_attack_physics(delta: float) -> void:
	pass

## ---- 状态机重构：角色通用接口 ----
func process_movement(delta: float) -> void:
	pass

func process_idle(delta: float) -> void:
	pass

func on_death_state_entered() -> void:
	pass

func _on_attack_active_started(_duration: float) -> void:
	execute_attack()

func _on_attack_ended() -> void:
	end_attack()
