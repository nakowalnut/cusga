extends State
class_name AttackState




## 附加值使用示例
func enter(msg: Dictionary = {}) -> void:
<<<<<<< Updated upstream
	match msg.get("anim"):
		0:
			character.animation_player.play("attack1")
		1:
			character.animation_player.play("attack2")
=======
	get_parent().character._perform_attack()
	
	if "animation_player" in character:
		match msg.get("anim"):
			0:
				character.animation_player.play("attack1")
			1:
				character.animation_player.play("attack2")
>>>>>>> Stashed changes


func exit() -> void:
	pass

func physics_process(delta: float) -> void:
<<<<<<< Updated upstream
=======
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
			#print(character.velocity)

			if character.hp > 0:
				character.velocity.x = 0
				character.velocity.y = 0

>>>>>>> Stashed changes
	# 播放攻击动画，停止移动
	character.velocity.x = 0

func get_state_name() -> String:
	return "Attack"
