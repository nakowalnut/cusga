@abstract
extends Node
class_name State

# 状态信号
signal state_entered
signal state_exited


# 状态机引用
var state_machine: StateMachine = null
var character:CharacterBase = null

# 重写这些方法来实现状态逻辑
func enter(_msg: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func process(delta: float) -> void:
	pass

func physics_process(delta: float) -> void:
	pass

func handle_input(event: InputEvent) -> void:
	pass

func get_state_name() -> String:
	return "BaseState"
