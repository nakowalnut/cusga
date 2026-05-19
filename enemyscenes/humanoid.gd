extends EliteEnemy

var magic_skill: EliteSkill

func _ready() -> void:
	super._ready()
	# 祭司通常搭载：火球术、治疗阵或图腾组件
	for child in get_children():
		if child is EliteSkill:
			magic_skill = child
			magic_skill.owner_enemy = self
	
	# 祭司近战能力弱，sight_range[0]（攻击距离）通常设得较远
	self.speed = 200 # 移速较慢

func process_movement(delta: float) -> void:
	if not is_instance_valid(target_player): return
	
	var dist = position.distance_to(target_player.position)
	
	# 祭司 AI：保持距离，不主动贴脸
	if dist < 150:
		# 距离太近就后退
		var retreat_dir = target_player.position.direction_to(position)
		velocity = retreat_dir * speed
		return
	
	# 如果技能 Ready 且在射程内
	if magic_skill and magic_skill.is_ready and dist < 400:
		if c_state_machine:
			c_state_machine.change_state(STATE_ATTACK)
			return

	super.process_movement(delta)

func pre_attack(_msg: Dictionary = {}):
	if magic_skill and magic_skill.is_ready:
		# 执行搭载的法术逻辑
		magic_skill.execute(target_player)
		# 祭司施法完通常有较长的收招
		get_tree().create_timer(0.8).timeout.connect(finish_attack)
	else:
		# 没蓝/技能冷却：执行虚弱的法杖挥击
		if anim: anim.play("staff_swing")
		if character_weapon:
			character_weapon.attack(target_player.global_position)
		finish_attack()

func finish_attack():
	if c_state_machine: c_state_machine.change_state(STATE_IDLE)
