extends State
class_name DiedState

var _death_timer: SceneTreeTimer

func enter(msg: Dictionary = {}) -> void:
	character.velocity = Vector2.ZERO
	character.set_deferred("collision_layer", 0)
	character.set_deferred("collision_mask", 0)
	if character.anim is AnimationPlayer and character.anim.has_animation("died"):
		character.anim.play("died")
	print("dead")
	_death_timer = get_tree().create_timer(1)
	_death_timer.timeout.connect(_on_death_timer_timeout)


func _on_death_timer_timeout() -> void:
	if is_instance_valid(character):
		character.queue_free()
	
func get_state_name() -> String:
	return CharacterBase.STATE_DIED
	
func process(delta: float) -> void:
	if character.anim is AnimationPlayer:
		if character.anim.current_animation != "died" and character.anim.has_animation("died"):
			character.anim.play("died")
	#elif character.anim is AnimatedSprite2D:
		#if character.anim.animation != "died":
			#character.anim.play("died")
	
