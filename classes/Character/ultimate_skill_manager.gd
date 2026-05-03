extends Node
class_name UltimateSkillManager

var player: Player

func _init(_player: Player):
	player = _player

func add_ultimate_point(amount: int = 1) -> void:
	if amount <= 0:
		return
	player.ultimate_points = min(player.ULTIMATE_MAX_POINTS, player.ultimate_points + amount)
	print("[Ultimate] 点数: ", player.ultimate_points, "/", player.ULTIMATE_MAX_POINTS)
	if player.ultimate_points == player.ULTIMATE_MAX_POINTS:
		print("[Ultimate] 大招已就绪！可以按下 ultimate 键释放！")

func _try_cast_ultimate() -> void:
	if player.in_ultimate_mode:
		return
	if player.ultimate_points < player.ULTIMATE_MAX_POINTS:
		print("[Ultimate] 点数不足: ", player.ultimate_points, "/", player.ULTIMATE_MAX_POINTS)
		return
	print("[Ultimate] 大招触发！状态锁定接管：开始连续乱舞！")
	player.ultimate_points = 0
	player.in_ultimate_mode = true
	player.ultimate_cycle_index = -1
	
	var timer := player.get_tree().create_timer(player.ULTIMATE_DURATION)
	timer.timeout.connect(func():
		player.in_ultimate_mode = false
		player.ultimate_cycle_index = -1
		print("[Ultimate] 大招时间到，效果结束")
	)

func _cycle_ultimate_weapon_before_attack() -> void:
	if player.ultimate_weapon_cycle.is_empty():
		return

	player.ultimate_cycle_index = (player.ultimate_cycle_index + 1) % player.ultimate_weapon_cycle.size()
	var target_weapon_id = player.ultimate_weapon_cycle[player.ultimate_cycle_index]
	var idx = player.weapon_wheel.find(target_weapon_id)
	if idx == -1:
		player.weapon_wheel.append(target_weapon_id)
		idx = player.weapon_wheel.size() - 1

	player.current_weapon_index = idx
	player.weapon_visual_system.update_weapon_visual()

func apply_ultimate_arrow_rain(target: Node) -> void:
	if not player.in_ultimate_mode or not is_instance_valid(target) or target.get("is_dead"):
		return
	if target.has_meta("ultimate_rain"):
		return
	target.set_meta("ultimate_rain", true)
	print("弓箭雨降临：目标 ", target.name)
	
	var rain_timer = Timer.new()
	rain_timer.wait_time = 0.5
	rain_timer.autostart = true
	var count = [0]
	rain_timer.timeout.connect(func():
		if not is_instance_valid(target) or target.get("is_dead") or count[0] >= 10:
			if is_instance_valid(target):
				target.remove_meta("ultimate_rain")
			if is_instance_valid(rain_timer):
				rain_timer.queue_free()
			return
		count[0] += 1
		spawn_ultimate_followup_arrow(target)
	)
	target.add_child(rain_timer)

func spawn_ultimate_followup_arrow(target: Node) -> void:
	if not player.in_ultimate_mode:
		return
	if not is_instance_valid(target):
		return
	if target.get("is_dead"):
		return
	if not player.ULTIMATE_ARROW_SCENE:
		return
	if not is_instance_valid(player.get_tree().current_scene):
		return

	var arrow = player.ULTIMATE_ARROW_SCENE.instantiate()
	var random_offset_x = randf_range(-24.0, 24.0)
	var spawn_pos = target.global_position + Vector2(random_offset_x, -220.0)
	arrow.global_position = spawn_pos
	arrow.direction = (target.global_position - spawn_pos).normalized()
	arrow.speed = 900.0
	arrow.life_time = 1.2
	arrow.direct_damage = player.ULTIMATE_ARROW_DAMAGE
	arrow.trigger_weapon_on_hit = false

	if player.all_weapons.has("bow"):
		arrow.weapon_owner = player.all_weapons["bow"]
	else:
		arrow.weapon_owner = player.current_weapon_node
	
	player.get_tree().current_scene.add_child(arrow)