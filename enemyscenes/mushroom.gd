extends Enemy
class_name MushroomEnemy

func _ready() -> void:
	super._ready()
	# 确保蘑菇不动
	speed = 0
	base_speed = 0
	
	# 蘑菇通常有 360 度视野，在编辑器里设置 fov.angle = 360
	if fov:
		fov.angle = 360.0

# 重写移动逻辑：蘑菇不需要走动，只需要在原地判断是否攻击
func process_movement(_delta: float) -> void:
	if is_instance_valid(target_player):
		var dist = global_position.distance_to(target_player.global_position)
		
		# 只要玩家在攻击范围内，就尝试攻击
		if dist <= sight_range[0]:
			velocity = Vector2.ZERO
			if attack_controller and attack_controller.can_start_attack():
				c_state_machine.change_state(CharacterBase.STATE_ATTACK)
		else:
			# 玩家在视野内但够不着，蘑菇也只是看着，不走过去
			velocity = Vector2.ZERO
