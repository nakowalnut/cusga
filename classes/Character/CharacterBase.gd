extends CharacterBody2D
class_name CharacterBase

## 状态名常量
const STATE_HURT = "Hurt"
const STATE_DIED = "Died"
const STATE_IDLE = "Idle"
const STATE_ATTACK = "Attack"
const STATE_WALK = "Walk"

## 基础属性
@export var character_weapon: WeaponBase
@export_group("基础属性")
@export var max_health: float = 100.0
@export var speed: float = 300
@export var debug_mode: bool = false
@onready var current_health: float = max_health
@export var attack_timer: Timer
@export var attack_cooldown_time: float = 1.0
@export var sight_range: Array[int] = [50, 500]## 感知范围，【临近值，最远值】
var toward: int = 1# 面向方向 (Walk/Hurt 等状态依赖)
@onready var anim: Node ##存储动画
var hp: float:
	get: return current_health
	set(value): current_health = value
	
## 状态定义
var is_dead: bool = false
var is_invulnerable: bool = false
@export var invulnerability_duration: float = 0.2
var is_attacking: bool = false
## 状态机节点
@export_group("角色状态")
@export var c_state_machine: StateMachine

## 信号
signal health_changed(new_health: float, max_health: float)
signal damaged(amount: float)
signal hurt
signal died

func _ready() -> void:
	if attack_timer:
		attack_timer.one_shot = true

## 伤害处理
func take_damage(amount: float):
	if is_dead or is_invulnerable:
		return
	
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	
	emit_signal("damaged", amount)
	emit_signal("health_changed", current_health, max_health)
	
	if amount > 0:
		emit_signal("hurt")
	
	if current_health <= 0:
		die()
	else:
		if c_state_machine and c_state_machine.states.has(STATE_HURT):
			c_state_machine.change_state(STATE_HURT)
		_trigger_invulnerability()

## 触发无敌帧
func _trigger_invulnerability():
	is_invulnerable = true
	get_tree().create_timer(invulnerability_duration).timeout.connect(
		func(): is_invulnerable = false
	)

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
	pre_attack(msg)
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

func get_attack_duration() -> float:
	return 0.3 # 保持与原 attack.gd 相同的默认锁定时间基线
