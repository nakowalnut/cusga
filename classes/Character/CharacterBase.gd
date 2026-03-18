extends CharacterBody2D
class_name CharacterBase
@export var debug_mode:bool = false
## 基础属性
@export_group("基础属性")
@export var max_health: float = 100.0
@export var speed: float = 300

@onready var current_health: float = max_health

var hp: float:
	get:
		return current_health
	set(value):
		current_health = value

## 状态定义
var is_dead: bool = false
var is_invulnerable: bool = false
@export var invulnerability_duration: float = 0.2
var toward: int = 0
## 状态机节点
@export_group("附加组件")
@export var c_state_machine: StateMachine ## 状态机节点
@export var field_of_view:FieldOfView2D ## 视线节点
@onready var attack_colldown_timer:Timer = Timer.new()
@export var type: int = 0
## 信号
signal health_changed(new_health: float, max_health: float)
signal damaged(amount: float)
signal hurt
signal died

func _ready() -> void:
	if field_of_view != null:
		if debug_mode:
			field_of_view.body_entered_vision.connect(on_body_entered_vision)
			field_of_view.body_exited_vision.connect(on_body_exited_vision)
			print("初始化",self,"的视野模块")
			
func on_body_entered_vision(body:Node2D):
	print(body,"出现在",self,"的视野中")

func on_body_exited_vision(body:Node2D):
	print(body,"离开了",self,"的视野")

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
	queue_free()

## 攻击前摇
func _perform_attack():
	pass

## 获取生命百分比
func get_health_percent() -> float:
	return current_health / max_health
