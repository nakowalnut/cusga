extends WeaponBase
class_name DaggerWeapon

@export var displacement_speed: float = 600.0
@export var combo_timeout: float = 3.0
var combo_timer: Timer

func _init() -> void:
	weapon_name = "短剑"
	damage = 8.0
	attack_range = 30.0
	attack_speed_multiplier = 1.5 # 攻速高
	color = Color.BLUE
	max_combo = 5

func _ready() -> void:
	combo_timer = Timer.new()
	combo_timer.one_shot = true
	combo_timer.timeout.connect(_on_combo_timeout)
	add_child(combo_timer)

func attack(target_pos: Vector2) -> void:
	if not is_instance_valid(player): return
	
	var mouse_pos = player.get_global_mouse_position()
	
	# 短剑位移：检测鼠标位置是否有敌人
	var space_state = player.get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = mouse_pos
	params.collision_mask = 4 # Enemy Layer
	params.collide_with_areas = true
	params.collide_with_bodies = true
	
	var results = space_state.intersect_point(params)
	var has_enemy = false
	for res in results:
		if res.collider and (res.collider is Enemy or res.collider.get_parent() is Enemy):
			has_enemy = true
			break
			
	if has_enemy:
		var dir = (mouse_pos - player.global_position).normalized()
		player.velocity = dir * displacement_speed
		# 短剑特有的前冲，状态机可能在下一帧重置velocity，可以在状态机/特定动画内持续
		print("短剑：目标处有敌人，产生位移突刺")
	else:
		print("短剑：目标处无敌人，原地攻击")

func on_hit(enemy: Node) -> void:
	if not enemy.is_dead:
		enemy.take_damage(damage)
		add_combo(1)
		# 刷新连击时间
		combo_timer.start(combo_timeout)

func _on_combo_timeout() -> void:
	if not is_synergy_ready:
		reset_combo()
		print("短剑连击超时，已重置")

func execute_synergy() -> void:
	print("执行短剑连携技！")
	# 具体的连携技效果按需补充，如爆发伤害等
