extends State
class_name DiedState

func enter(msg: Dictionary = {}) -> void:
	character.velocity.x = 0
	character.anim.play("died")
	print("dead")
	get_tree().create_timer(1).timeout.connect(func():character.queue_free())
	
func get_state_name() -> String:
	return "Died"
	
func process(delta: float) -> void:
	if character.anim.current_animation != "died":
		character.anim.play("died")
	
