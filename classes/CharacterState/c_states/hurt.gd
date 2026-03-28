extends State
class_name HurtState

@export var hurt_timer:Timer

func _ready() -> void:
	if not hurt_timer:
		hurt_timer = Timer.new()
		hurt_timer.one_shot = true
		hurt_timer.wait_time = 0.2 # 默认无敌或受击硬直时间
		add_child(hurt_timer)
		
func enter(msg: Dictionary = {}) -> void:
	if character.hp >= 0:
		if character.debug_mode:
			print("Entering Hurt State")
		if character.anim is AnimatedSprite2D and "sprite_frames" in character.anim:
			if character.anim.sprite_frames.has_animation("hurt") or character.anim.animation != "hurt":
				character.anim.play("hurt")
		elif character.anim is AnimationPlayer:
			if character.anim.has_animation("hurt"):
				character.anim.play("hurt")
				
		if character.get("animation_player") and character.animation_player.has_animation("hurt"):
			character.animation_player.play("hurt")
		if character.material:
			character.material.set("shader_parameter/get_hit", true)
		hurt_timer.start()
		if !hurt_timer.timeout.is_connected(on_timeout):
			hurt_timer.timeout.connect(on_timeout)
	else:
		if character.has_method("is_player") or character is Player:
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
