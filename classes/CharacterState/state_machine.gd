extends Node
class_name StateMachine

# 状态机信号
signal state_changed(previous_state: State, new_state: State)

@export var character:CharacterBase

# 当前状态
var current_state: State = null
# 状态历史（用于返回之前的状态）
var state_history: Array[State] = []
# 状态字典
var states: Dictionary = {}

# 初始化
func _ready() -> void:
	await get_parent().ready
	
	# 自动查找子节点的状态
	for child in get_children():
		if child is State:
			states[child.get_state_name()] = child
			child.state_machine = self
			child.character = self.character
	
	# 设置初始状态
	if states.size() > 0:
		var initial_state = states.values()[0]
		change_state(initial_state.get_state_name())


func _process(delta: float) -> void:
	if current_state:
		current_state.process(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_process(delta)

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

# 切换状态
func change_state(state_name: String, msg: Dictionary = {}) -> void:
	if not state_name in states:
		push_error("State not found: %s" % state_name)
		return
	
	var new_state = states[state_name]
	
	if current_state == new_state:
		return
	
	# 退出当前状态
	if current_state:
		current_state.exit()
		state_history.append(current_state)
	
	# 切换状态
	var previous_state = current_state
	current_state = new_state
	
	# 进入新状态
	current_state.enter(msg)
	
	# 发出信号
	state_changed.emit(previous_state, current_state)
	
	if character.debug_mode:
		print(character, "\n---State changed: %s -> %s" % [
			previous_state.get_state_name() if previous_state else "None",
			current_state.get_state_name()
		])

# 返回之前的状态
func revert_to_previous_state(msg: Dictionary = {}) -> bool:
	if state_history.size() == 0:
		return false
	
	var previous_state = state_history.pop_back()
	change_state(previous_state.get_state_name(), msg)
	return true

# 检查当前状态
func is_in_state(state_name: String) -> bool:
	return current_state and current_state.get_state_name() == state_name

# 获取当前状态名称
func get_current_state_name() -> String:
	return current_state.get_state_name() if current_state else ""
