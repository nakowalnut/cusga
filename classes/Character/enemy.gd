extends CharacterBase
class_name Enemy

var is_stunned: bool = false
var stun_timer: Timer
var base_speed: float = 0.0

func _ready() -> void:
	anim = $AnimationPlayer
	base_speed = speed
	if not stun_timer:
		stun_timer = Timer.new()
		stun_timer.one_shot = true
		stun_timer.timeout.connect(_on_stun_timeout)
		add_child(stun_timer)
	super._ready()

##如需复杂逻辑,请继承覆盖
func Hit(damage:float):
	take_damage(damage)
	if damage>0:hurt.emit()

func apply_stun(duration: float) -> void:
	is_stunned = true
	# 如果使用了状态机，可以强制进入 Stun 状态
	if c_state_machine and c_state_machine.has_node("Stun"):
		c_state_machine.change_state("Stun", {"duration": duration})
	else:
		if not stun_timer.is_inside_tree():
			add_child(stun_timer)
		stun_timer.start(duration)
		# 临时降低速度模拟眩晕
		speed = 0

func _on_stun_timeout() -> void:
	is_stunned = false
	if c_state_machine and c_state_machine.get_current_state_name() == "Stun":
		c_state_machine.change_state(STATE_IDLE)
	else:
		speed = base_speed

## ---- 状态机重构：重写基类方法 ----
func process_movement(delta: float) -> void:
	if is_instance_valid(GameManager.player):
		var dist = position.distance_to(GameManager.player.position)
		if dist >= sight_range[1]:
			if c_state_machine: c_state_machine.change_state(STATE_IDLE)
		elif dist <= sight_range[0]:
			velocity = Vector2.ZERO
			if attack_timer and attack_timer.is_stopped():
				attack_timer.start(attack_cooldown_time)
				if c_state_machine: c_state_machine.change_state(STATE_ATTACK)
		else:
			velocity = position.direction_to(GameManager.player.position) * speed

func process_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	if is_instance_valid(GameManager.player):
		var dist = position.distance_to(GameManager.player.position)
		if dist >= sight_range[1]:
			pass
		elif dist <= sight_range[0]:
			if attack_timer and attack_timer.is_stopped():
				attack_timer.start(attack_cooldown_time)
				if c_state_machine: c_state_machine.change_state(STATE_ATTACK)
		else:
			if c_state_machine: c_state_machine.change_state(STATE_WALK)

func on_death_state_entered() -> void:
	pass
