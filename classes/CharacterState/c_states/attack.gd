extends State
class_name AttackState

func enter(msg: Dictionary = {}) -> void:
	if character is Player:
		if character.weapon_wheel.size() == 0:
			character.c_state_machine.change_state("Idle")
			return
		
		character.is_attacking = true
	character.pre_attack(msg)
	# 如果有传入anim的示例，可保留这部分自定义逻辑
	match msg.get("anim"):
		0:
			character.animation_player.play("attack1")
		1:
			character.animation_player.play("attack2")

	# 模拟攻击硬直结束
	await get_tree().create_timer(0.3).timeout
	
	# 确保还在 Attack 状态才执行后续攻击和切回 Idle，防止中途被受击等状态打断或动画提前结束
	if character.c_state_machine.get_current_state_name() == "Attack":
		if character is not Player and is_instance_valid(character.character_weapon):
			character.character_weapon.attack(character.global_position)
		character.is_attacking = false
		if character is Player:
			character.set_weapon_hitbox_active(false)
		character.c_state_machine.change_state("Idle")

func exit() -> void:	
	character.is_attacking = false
	if character is Player:
		character.set_weapon_hitbox_active(false)
	
func physics_process(delta: float) -> void:
	if character is Player:
		character.player_attack()

	# 播放攻击动画，停止移动

		
func get_state_name() -> String:
	return "Attack"
