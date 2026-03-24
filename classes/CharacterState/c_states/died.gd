extends State
class_name DiedState

func enter(msg: Dictionary = {}) -> void:
	character.velocity.x = 0
	character.anim.play("died")
	print("dead")
	
func get_state_name() -> String:
	return "Died"
	
func process(delta: float) -> void:
	if character.anim.animation != "died":
		character.anim.play("died")
