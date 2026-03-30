extends State
class_name StunState

@export var stun_duration: float = 1.0

func enter(msg: Dictionary = {}) -> void:
	if msg.has("duration"):
		stun_duration = msg.duration
	
	# 停止角色当前的动作
	character.velocity = Vector2.ZERO
	if character.anim and character.anim.has_animation("idle"):
		character.anim.play("idle")
	
	# 如果有 shader 效果可以在这里应用提示（可选）
	# character.sprite.material.set_shader_parameter("active", true)

	await get_tree().create_timer(stun_duration).timeout
	
	if character.c_state_machine.get_current_state_name() == "Stun":
		character.c_state_machine.change_state(CharacterBase.STATE_IDLE)

func transition_reason(state_name: String) -> bool:
	# 眩晕期间不可主动切换至除死亡、受击之外的其他状态
	if state_name in [CharacterBase.STATE_DIED, CharacterBase.STATE_HURT]:
		return true
	return false
