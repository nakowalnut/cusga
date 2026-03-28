extends State
class_name IdleState

func enter(msg: Dictionary = {}) -> void:
	pass
	#if character.anim.sprite_frames.has_animation("fall_to_ground") or character.anim.animation != "fall_to_ground":
		#character.anim.play("idle")

func exit() -> void:
	pass

func process(delta: float) -> void:
	character.velocity.x = 0
	character.velocity.y = 0
	#match character.type:
	if character is Player:
			# 检查是否应该切换到移动状态
			if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or Input.is_action_pressed("up") or Input.is_action_pressed("down"):
				state_machine.change_state("Walk")

	else:
		if is_instance_valid(GameManager.player):
			if character.position.distance_to(GameManager.player.position) >= character.sight_range[1]:
				pass
			elif character.position.distance_to(GameManager.player.position) <= character.sight_range[0]:
				if character.attack_timer and character.attack_timer.is_stopped():
					character.attack_timer.start(character.attack_cooldown_time)
					state_machine.change_state("Attack")
			else:
				state_machine.change_state("Walk")
				#character.velocity = character.position.direction_to(GameManager.player.position)
			if character.attack_timer and character.attack_timer.is_stopped():
				pass
				#if character.target_can_attack:
					#character.attack_timer.start()
					#state_machine.change_state("Attack",{"anim" : 0})

			#if character.attack_timer and character.attack_timer.is_stopped():
				#var f = (GameManager.player.position.x - character.position.x) > 0
				#character.character_filp(f)
				
			#if character.need_move_attack:
				#character.attack_timer.start()
				#if state_machine.get_current_state_name()  == "Idle":
					#state_machine.change_state("Walk")
					#character.need_move_attack = false
				
func get_state_name() -> String:
	return "Idle"
	
