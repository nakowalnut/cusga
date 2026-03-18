extends State
class_name AttackState

func enter(msg: Dictionary = {}) -> void:
	if not character is Player:
		return
		
	if character.weapon_wheel.size() == 0:
		character.c_state_machine.change_state("Idle")
		return
	
	character.is_attacking = true
	var current_weapon_id = msg.get("weapon", character.weapon_wheel[character.current_weapon_index])
	var prev_weapon_id = msg.get("prev_weapon", current_weapon_id)
	var is_switch = msg.get("is_switch", false)
	
	var weapon = character.all_weapons[current_weapon_id]
	
	if is_switch:
		print("执行连携攻击: ", prev_weapon_id, " -> ", current_weapon_id)
		# 可以在此处执行连携动画播放逻辑
		character.animation_player.play("Attack1") 
	else:
		print("使用武器普通攻击: ", weapon.weapon_name)
		character.animation_player.play("Attack1") 
	
	# 调用武器子类的特定攻击逻辑（位移、射箭等）
	var mouse_pos = character.get_global_mouse_position()
	weapon.attack(mouse_pos)
	
	character._update_weapon_visual()
	character.set_weapon_hitbox_active(true)
	
	# 如果有传入anim的示例，可保留这部分自定义逻辑
	match msg.get("anim"):
		0:
			character.animation_player.play("attack1")
		1:
			character.animation_player.play("attack2")

	# 模拟攻击硬直结束
	await get_tree().create_timer(0.3).timeout
	# 确保还在 Attack 状态才切回 Idle，防止中途被受击等状态打断
	if character.c_state_machine.get_current_state_name() == "Attack":
		character.is_attacking = false
		character.set_weapon_hitbox_active(false)
		character.c_state_machine.change_state("Idle")

func exit() -> void:
	if character is Player:
		character.is_attacking = false
		character.set_weapon_hitbox_active(false)

func physics_process(delta: float) -> void:
	if character is Player:
		var current_weapon_node = character.current_weapon_node
		var is_bow = current_weapon_node != null and current_weapon_node.weapon_name == "弓"
		
		if is_bow:
			# 弓箭攻击时必定无法移动
			character.velocity = Vector2.ZERO
		else:
			# 其它武器支持普通移动（或者根据你的游戏设定修改）
			if Input.get_axis("move_left", "move_right") != 0:
				character.toward = int(Input.get_axis("move_left", "move_right"))
				character.velocity.x = character.toward * character.speed
				character.anim.play("walk")
			elif Input.get_axis("up", "down") != 0:
				character.velocity.y = int(Input.get_axis("up", "down")) * character.speed
			else:
				if character.hp > 0:
					character.velocity = Vector2.ZERO

	# 播放攻击动画，停止移动

		
func get_state_name() -> String:
	return "Attack"
