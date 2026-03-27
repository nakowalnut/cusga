extends State
class_name WalkState

func enter(msg: Dictionary = {}) -> void:
	pass
	#character.anim.play("walk")
	
func exit() -> void:
	pass

func physics_process(_delta: float) -> void:
	character.get_velocity()

	if character is Player:
		if Input.get_axis("move_left", "move_right") != 0:
			character.toward = int(Input.get_axis("move_left", "move_right"))
			# 更新移动逻辑
			#if character.run:
				#character.velocity.x = character.toward * character.speed * 3
				#character.anim.play("run")
			#else:
				#character.velocity.x = character.toward * character.speed
				#character.anim.play("walk")
			character.velocity.x = character.toward * character.speed
			character.anim.play("walk")
		if Input.get_axis("up", "down") != 0:
			character.velocity.y = int(Input.get_axis("up", "down")) * character.speed
		if Input.get_axis("move_left", "move_right") == 0 and Input.get_axis("up", "down") == 0:
			print(character.velocity)

			if character.hp > 0:
				state_machine.change_state("Idle")
			
	else:
		if character.position.distance_to(GameManager.player.position) >= character.sight_range[1]:
			state_machine.change_state("Idle")
		elif character.position.distance_to(GameManager.player.position) <= character.sight_range[0]:
			character.velocity = Vector2.ZERO
			if character.attack_timer and character.attack_timer.is_stopped(): 
				character.attack_timer.start(character.attack_cooldown_time)
				state_machine.change_state("Attack")
		else:
			character.velocity = character.position.direction_to(GameManager.player.position) * character.speed
			
		#if character.attack_timer and character.attack_timer.is_stopped():
			#if character.target_can_attack:ad
				#character.attack_timer.start()
				#state_machine.change_state("Idle")
		#if character.attack_timer and character.attack_timer.is_stopped():
				#var f = (GameManager.player.position.x - character.position.x) > 0
				#character.character_filp(f)
	character.move_and_slide()
func get_state_name() -> String:
	return "Walk"
	
