extends State
class_name WalkState

func enter(msg: Dictionary = {}) -> void:
	character.anim.play("walk")
	
func exit() -> void:
	pass

func physics_process(_delta: float) -> void:
	if character.type == 0:
		if Input.get_axis("left", "right") != 0:
			character.toward = int(Input.get_axis("left", "right"))
			# 更新移动逻辑
			character.velocity.x = character.toward * character.speed
			character.anim.play("walk")
		else:
			if character.hp > 0:
				state_machine.change_state("Idle")
			

	else:
		if character.target_character.position.y - 100 < character. position.y:
			character.velocity.y = -character.speed
		else:
			character.velocity.y = -character.speed * 0.25
			if abs(character.target_character.position.x - character. position.x) < 100:
				state_machine.change_state("Idle")
		character.velocity.x = - character.toward * character.speed
		if character.attack_cooldown.is_stopped():
			if character.target_can_attack:
				character.attack_cooldown.start()
				state_machine.change_state("Idle")
		if character.act_cooldown.is_stopped():
				var f = (GameManager.player.position.x - character.position.x) > 0
				character.character_filp(f)
		
func get_state_name() -> String:
	return "Walk"
	
