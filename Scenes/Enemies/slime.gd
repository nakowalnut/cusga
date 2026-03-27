extends Enemy

func pre_attack(msg):
	# 使用直线距离判断是否满足攻击范围
	if global_position.distance_to(GameManager.player.global_position) <= sight_range[0]:
		var start_pos = global_position
		var target_pos = GameManager.player.global_position
		
		var tween = create_tween()
		# 1. 本体快速扑向玩家的全局位置
		tween.tween_property(self, "global_position", target_pos, 0.1)
		# 2. 然后马上弹回起始位置（利用 Tween 的自动排队特性连续播放）
		tween.tween_property(self, "global_position", start_pos, 0.15)
		
		# 3. 冲击-返回 这套动作全结束后再呼叫回调
		tween.tween_callback(attack_callback)

func attack_callback():
	pass # 攻击动作结束（可以在这里接状态机切回 Idle 等逻辑）
