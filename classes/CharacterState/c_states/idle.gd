extends State
class_name IdleState

func enter(msg: Dictionary = {}) -> void:
	pass
	#if character.anim.sprite_frames.has_animation("fall_to_ground") or character.anim.animation != "fall_to_ground":
		#character.anim.play("idle")

func exit() -> void:
	pass

func process(delta: float) -> void:
	character.process_idle(delta)
				
func get_state_name() -> String:
	return CharacterBase.STATE_IDLE
	
