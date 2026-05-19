extends State
class_name WalkState

func enter(msg: Dictionary = {}) -> void:
	character.play_walk_animation()
	
func exit() -> void:
	character.stop_walk_animation()

func physics_process(_delta: float) -> void:
	pass
	
	character.process_movement(_delta)

	character.move_and_slide()
func get_state_name() -> String:
	return CharacterBase.STATE_WALK
