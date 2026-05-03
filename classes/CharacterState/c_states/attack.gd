extends State
class_name AttackState

func enter(msg: Dictionary = {}) -> void:
	if not character.begin_attack(msg):
		if character.c_state_machine:
			character.c_state_machine.change_state(CharacterBase.STATE_IDLE)
		return

	var controller: AttackController = character.attack_controller
	if not is_instance_valid(controller):
		character.end_attack()
		if character.c_state_machine:
			character.c_state_machine.change_state(CharacterBase.STATE_IDLE)
		return
	
	# 如果有传入anim的示例，可保留这部分自定义逻辑
	match msg.get("anim"):
		0:
			if "animation_player" in character:
				character.animation_player.play("attack1")
		1:
			if "animation_player" in character:
				character.animation_player.play("attack2")

	await controller.attack_ended
	
	# 确保还在 Attack 状态才切回 Idle，防止中途被受击等状态打断
	if character.c_state_machine.get_current_state_name() == CharacterBase.STATE_ATTACK:
		character.end_attack()
		character.c_state_machine.change_state(CharacterBase.STATE_IDLE)

func exit() -> void:	
	if character.attack_controller:
		character.attack_controller.cancel_attack()
	character.end_attack()
	
func physics_process(delta: float) -> void:
	character.process_attack_physics(delta)
	# 播放攻击动画，停止移动
	
		
func get_state_name() -> String:
	return CharacterBase.STATE_ATTACK
