extends BossBase
class_name ChimeraBoss

## 奇美拉：编号 12
## 普攻：claw（利爪）、tail（扫尾）、dash（冲撞）

func _ready() -> void:
	super._ready()
	self.boss_name = "奇美拉"
	self.speed = 1.0 * 100 # 对应表格移速
	self.basic_attack_modes = ["claw", "tail", "dash"]

## 移动逻辑中加入技能决策
func process_movement(delta: float) -> void:
	if not is_instance_valid(target_player):
		super.process_movement(delta)
		return
		
	var dist = global_position.distance_to(target_player.global_position)
	
	# 检查当前冷却完毕的挂载技能
	var ready_skills = all_skills.filter(func(s): return s.is_ready)
	if ready_skills.size() > 0 and dist < 200:
		if c_state_machine and not is_attacking:
			c_state_machine.change_state(STATE_ATTACK, {"type": "skill", "node": ready_skills.pick_random()})
			return

	super.process_movement(delta)

## 攻击入口逻辑
func pre_attack(msg: Dictionary = {}):
	if not character_weapon: 
		attack_callback()
		return
		
	if msg.get("type") == "skill":
		var skill_node = msg.get("node")
		skill_node.execute(target_player)
	else:
		_perform_random_basic_attack(msg)

## 奇美拉普攻表现：对应表格中的 冲撞，利爪攻击，扫尾
func _perform_random_basic_attack(_m: Dictionary):
	var selected = basic_attack_modes.pick_random()
	
	# 特殊逻辑：冲撞模式下配合本体 Tween 位移
	if selected == "dash":
		var dir = global_position.direction_to(target_player.global_position)
		var t = create_tween()
		t.tween_property(self, "velocity", dir * speed * 3.5, 0.2)
		t.tween_property(self, "velocity", Vector2.ZERO, 0.1)
	
	if anim and anim.has_animation(selected):
		anim.play(selected)
	
	# 统一由武器执行攻击判定
	character_weapon.attack(target_player.global_position, selected)
	
	# 动作结束后回调状态机
	get_tree().create_timer(0.8).timeout.connect(attack_callback)
