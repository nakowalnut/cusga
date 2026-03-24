extends State
class_name HurtState

@export var hurt_timer:Timer

func enter(msg: Dictionary = {}) -> void:
	if character.hp >= 0:
		if character.debug_mode:
			print("Entering Hurt State")
		if character.anim.sprite_frames.has_animation("hurt") or character.anim.animation != "hurt":
			character.anim.play("hurt")
		if character.animation_player.has_animation("hurt"):
			character.animation_player.play("hurt")
		if character.material:
			character.material.set("shader_parameter/get_hit", true)
		hurt_timer.start()
		if !hurt_timer.timeout.is_connected(on_timeout):
			hurt_timer.timeout.connect(on_timeout)
	else:
		if character.type == 0:
			GameManager.player_die()
		hurt_timer.stop()
		state_machine.change_state("Died")


func exit() -> void:
	if character.debug_mode:
		print("Exiting Hurt State")

func process(delta: float) -> void:
	character.velocity.x = - character.toward

func get_state_name() -> String:
	return "Hurt"

func on_timeout():
	if character.material:
		character.material.set("shader_parameter/get_hit", false)
	if character.hp > 0:
		state_machine.change_state("Idle")
