extends State
class_name IdleState


func enter(msg: Dictionary = {}) -> void:
	if character.anim.sprite_frames.has_animation("fall_to_ground") or character.anim.animation != "fall_to_ground":
		character.anim.play("idle")

func exit() -> void:
	pass

func process(delta: float) -> void:
	character.velocity.x = 0
	match character.type:
		0:
			# 检查是否应该切换到移动状态
			if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
				state_machine.change_state("Walk")
				
			if Input.is_action_just_pressed("pounce"):
				state_machine.change_state("Pounce")
				
			if Input.is_action_just_pressed("fire"):
				state_machine.change_state("Fire")
		1:
			if character.attack_cooldown.is_stopped():
				if character.target_can_attack:
					character.attack_cooldown.start()
					state_machine.change_state("Attack",{"anim" : 0})

			if character.act_cooldown.is_stopped():
				var f = (GameManager.player.position.x - character.position.x) > 0
				character.character_filp(f)
				
			if character.need_move_attack:
				character.act_cooldown.start()
				if state_machine.get_current_state_name()  == "Idle":
					state_machine.change_state("Walk")
					character.need_move_attack = false
				
func get_state_name() -> String:
	return "Idle"
