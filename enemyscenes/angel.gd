extends BossBase

## 折翼天使：编号 11
## 普攻：pierce（穿刺）、slash_combo（连斩）

func _ready() -> void:
	super._ready()
	# 对应表格移速 1.2
	self.speed = 1.2 * 100 
	# 初始化本怪物的攻击模式（确保父类中有此变量）
	self.basic_attack_modes = ["pierce", "slash_combo"]

func process_movement(delta: float) -> void:
	if not is_instance_valid(target_player):
		super.process_movement(delta)
		return
		
	var dist = global_position.distance_to(target_player.global_position)
	
	# 技能决策
	var ready_skills = all_skills.filter(func(s): return s.is_ready)
	if ready_skills.size() > 0 and dist < 300:
		if c_state_machine and not is_attacking:
			c_state_machine.change_state(STATE_ATTACK, {"type": "skill", "node": ready_skills.pick_random()})
			return

	super.process_movement(delta)

## 状态机进入 Attack 状态时调用
func pre_attack(msg: Dictionary = {}):
	if not character_weapon: 
		attack_callback()
		return
	
	if msg.get("type") == "skill":
		var skill_node = msg.get("node")
		if skill_node:
			skill_node.execute(target_player)
			# 技能执行完毕的回调通常在 EliteSkill 组件内部通过 owner_enemy.attack_callback() 触发
	else:
		_perform_random_basic_attack(msg)

func _perform_random_basic_attack(_m: Dictionary):
	if basic_attack_modes.is_empty():
		attack_callback()
		return
		
	var selected_mode = basic_attack_modes.pick_random()
	
	if anim and anim.has_animation(selected_mode):
		anim.play(selected_mode)
	
	# 武器执行攻击
	character_weapon.attack(target_player.global_position, selected_mode)
	
	# 动作结束回调：使用 Timer 模拟动画时长，完成后务必调用 attack_callback
	get_tree().create_timer(0.6).timeout.connect(attack_callback)
