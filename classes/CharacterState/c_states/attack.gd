extends State
class_name AttackState

func enter(msg: Dictionary = {}) -> void:
	if not character.begin_attack(msg):
		return
	
	# 读取多态提供的攻击时长
	var lock_time = character.get_attack_duration()
	
	# 如果有传入anim的示例，可保留这部分自定义逻辑
	match msg.get("anim"):
		0:
			if "animation_player" in character:
				character.animation_player.play("attack1")
		1:
			if "animation_player" in character:
				character.animation_player.play("attack2")

	# 使用动态时长
	await get_tree().create_timer(lock_time).timeout
	
	# 确保还在 Attack 状态才执行后续攻击和切回 Idle，防止中途被受击等状态打断或动画提前结束
	if character.c_state_machine.get_current_state_name() == CharacterBase.STATE_ATTACK:
		character.execute_attack()
		character.end_attack()
		character.c_state_machine.change_state(CharacterBase.STATE_IDLE)

func exit() -> void:	
	character.end_attack()
	
func physics_process(delta: float) -> void:
	character.process_attack_physics(delta)
	# 播放攻击动画，停止移动

		
func get_state_name() -> String:
	return CharacterBase.STATE_ATTACK
