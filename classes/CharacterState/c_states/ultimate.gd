extends State
class_name UltimateState

func enter(_msg: Dictionary = {}) -> void:
	if character is Player:
		character.in_ultimate_mode = true
		character.on_ultimate_started()
	state_entered.emit()

	var duration := 15.0
	if character is Player:
		duration = character.ULTIMATE_DURATION

	var timer := get_tree().create_timer(duration)
	timer.timeout.connect(_on_duration_timeout)

func exit() -> void:
	if character is Player:
		character.in_ultimate_mode = false
		character.on_ultimate_ended()
	state_exited.emit()

func _on_duration_timeout() -> void:
	if not is_instance_valid(character):
		return
	if character.c_state_machine and character.c_state_machine.is_in_state(CharacterBase.STATE_ULTIMATE):
		character.c_state_machine.change_state(CharacterBase.STATE_IDLE)

func get_state_name() -> String:
	return CharacterBase.STATE_ULTIMATE
