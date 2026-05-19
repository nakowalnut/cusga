extends State
class_name JumpState

func enter(msg: Dictionary = {}) -> void:
	if character.debug_mode:
		print("Entering Jump State")
	if msg.get("is_fall") == true:
		pass
	else:
		character.velocity.y = -character.jump_force
		character.anim.play("jump")

func physics_process(delta: float) -> void:
	# 检查是否落地
	if character.is_on_floor() and character.hp > 0:
		character.anim.play("fall_to_ground")
		state_machine.change_state(CharacterBase.STATE_IDLE)
		
	if character.velocity.y >= 100:
		character.anim.play("fall")

	if Input.get_axis("move_left", "move_right") != 0:
		character.toward = int(Input.get_axis("move_left", "move_right"))
		# 更新移动逻辑
		if character.run:
			character.velocity.x = character.toward * character.speed * 3
		else:
			character.velocity.x = character.toward * character.speed
		
	if Input.is_action_just_pressed("pounce"):
		state_machine.change_state("Pounce")

func get_state_name() -> String:
	return "Jump"
