extends CharacterBody2D
class_name CharacterBase

## 基础属性
@export_group("基础属性")
@export var max_health: float = 100.0
@export var speed: float = 300
@export var debug_mode: bool = false
@onready var current_health: float = max_health
@onready var attack_cooldown: Timer = Timer.new()
@onready var act_cooldown: Timer = Timer.new()
@export var sight_range: Array[int] = [50, 500]## 感知范围，【临近值，最远值】
var toward: int = 1# 面向方向 (Walk/Hurt 等状态依赖)

var hp: float:
	get: return current_health
	set(value): current_health = value
	
## 状态定义
var is_dead: bool = false
var is_invulnerable: bool = false
@export var invulnerability_duration: float = 0.2

## 状态机节点
@export_group("角色状态")
@export var c_state_machine: StateMachine

## 信号
signal health_changed(new_health: float, max_health: float)
signal damaged(amount: float)
signal hurt
signal died

## 伤害处理
func take_damage(amount: float):
	if is_dead or is_invulnerable:
		return
	
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	
	emit_signal("damaged", amount)
	emit_signal("health_changed", current_health, max_health)
	
	if current_health <= 0:
		die()
	else:
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
	# 可以在子类中重写此方法以实现具体的死亡动画或效果
	#queue_free()

## 获取生命百分比
func get_health_percent() -> float:
	return current_health / max_health
