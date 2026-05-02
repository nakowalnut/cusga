extends State
class_name DiedState

func enter(msg: Dictionary = {}) -> void:
	character.velocity = Vector2.ZERO
	character.set_deferred("collision_layer", 0)
	character.set_deferred("collision_mask", 0)
	if character.anim is AnimationPlayer and character.anim.has_animation("died"):
		character.anim.play("died")
	#elif character.anim is AnimatedSprite2D:
		#character.anim.play("died")
	print("dead")
	get_tree().create_timer(1).timeout.connect(func():character.queue_free())
	
func get_state_name() -> String:
	return CharacterBase.STATE_DIED
	
func process(delta: float) -> void:
	if character.anim is AnimationPlayer:
		if character.anim.current_animation != "died" and character.anim.has_animation("died"):
			character.anim.play("died")
	#elif character.anim is AnimatedSprite2D:
		#if character.anim.animation != "died":
			#character.anim.play("died")
	
