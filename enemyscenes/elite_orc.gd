
extends EliteEnemy

# 这里的 _msg 必须写在括号里，因为是从状态机传过来的
func pre_attack(_msg: Dictionary = {}):
	if not is_instance_valid(GameManager.player): return
	
	# 逻辑分流：冷却好了就放技能，没好就普通攻击
	if use_skill():
		_play_skill_animation()
	else:
		_play_normal_attack(_msg)

func _play_skill_animation():
	print("精英兽人发动：跳跃砸地！")
	var t = create_tween()
	
	# 1. 蓄力变色
	t.tween_property(self, "modulate", Color.ORANGE, 0.2)
	
	# 2. 向上跳起
	t.tween_property(self, "position:y", position.y - 60, 0.4).set_trans(Tween.TRANS_QUAD)
	
	# 3. 猛烈砸下
	t.tween_property(self, "position:y", position.y, 0.1).set_ease(Tween.EASE_IN)
	
	t.tween_callback(func():
		# 变回颜色
		modulate = Color.WHITE
		# 触发武器的大范围攻击逻辑
		if character_weapon:
			character_weapon.attack(GameManager.player.global_position)
		
		# --- 修复报错：手动调用父类或直接切换状态 ---
		_finish_attack()
	)

func _play_normal_attack(m: Dictionary):
	# 这里的 m 对应传进来的 _msg
	# super 指向父类 Enemy 的 pre_attack
	if super.has_method("pre_attack"):
		super.pre_attack(m)
	else:
		# 如果父类也没有，就手动收尾
		_finish_attack()

# 统一的收尾函数，替代缺失的 attack_callback
func _finish_attack():
	# 如果你的基类中有 attack_callback()，就用 super 调用
	if has_method("attack_callback"):
		call("attack_callback")
	elif c_state_machine:
		# 如果找不到函数，直接强行切回 Idle 状态
		c_state_machine.change_state("Idle")
