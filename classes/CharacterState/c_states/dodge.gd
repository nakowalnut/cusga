extends State
class_name DodgeState

var dodge_timer: float = 0.0
var dodge_direction: Vector2 = Vector2.ZERO

func enter(msg: Dictionary = {}) -> void:
	dodge_timer = character.dodge_duration
	character.is_invulnerable = true
	
	# 确定闪避方向：鼠标指针相对于玩家的方向
	var mouse_pos = character.get_global_mouse_position()
	dodge_direction = (mouse_pos - character.global_position).normalized()
	
	# 如果距离太近导致向量无效，则回退到当前面向
	if dodge_direction == Vector2.ZERO:
		dodge_direction = Vector2.RIGHT if character.toward == 1 else Vector2.LEFT
	
	# 播放动画（如果有的话）
	if character.anim and character.anim.has_animation("dodge"):
		character.anim.play("dodge")
	elif character.anim and character.anim.has_animation("jump"): # 备选
		character.anim.play("jump")

func exit() -> void:
	character.is_invulnerable = false

func physics_process(delta: float) -> void:
	dodge_timer -= delta
	
	character.velocity = dodge_direction * character.dodge_speed
	character.move_and_slide()
	
	if dodge_timer <= 0:
		if character.velocity.length() > 0.1:
			state_machine.change_state(CharacterBase.STATE_WALK)
		else:
			state_machine.change_state(CharacterBase.STATE_IDLE)

func get_state_name() -> String:
	return CharacterBase.STATE_DODGE
