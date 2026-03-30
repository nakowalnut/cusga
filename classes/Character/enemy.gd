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
		c_state_machine.change_state("Idle")
	else:
		speed = base_speed
