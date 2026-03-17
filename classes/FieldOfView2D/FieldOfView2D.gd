extends Area2D
class_name FieldOfView2D

## 视野半径（像素）
@export var radius: float = 300.0:
	set(value):
		radius = value
		if _collision_shape and _collision_shape.shape:
			_collision_shape.shape.radius = radius
		if debug_draw:
			queue_redraw()

## 视野角度（度数），扇形张开的角度
@export var angle: float = 90.0:
	set(value):
		angle = value
		if debug_draw:
			queue_redraw()

## 是否自动旋转
@export var auto_rotate: bool = false

## 旋转速度（度/秒）
@export var rotation_speed: float = 45.0

## 需要检测的目标所在的组（可选，留空则检测所有进入的物理体）
@export var target_groups: Array[String] = []

## 用于射线检测的碰撞层（障碍物层），决定哪些物体会阻挡视线
@export_flags_2d_physics var obstacle_layers: int = 1

## 检测更新间隔（秒）。0 表示每帧更新；大于 0 则降低检测频率以提升性能
@export var update_interval: float = 0.0:
	set(value):
		update_interval = value
		_time_since_last_update = 0.0

## 是否在射线检测中排除自身和父节点（避免被自己的碰撞体遮挡）
@export var exclude_self_and_parent: bool = true

## 是否启用调试绘制（显示扇形边线和中线），仅在运行时可见（编辑器中总是绘制）
@export var debug_draw: bool = false:
	set(value):
		debug_draw = value
		queue_redraw()

## 信号：当某个物理体首次进入视野时发出
signal body_entered_vision(body: Node2D)

## 信号：当某个物理体离开视野时发出
signal body_exited_vision(body: Node2D)

# 内部变量
var _visible_bodies: Array[Node2D] = []          # 当前可见的物理体缓存
var _collision_shape: CollisionShape2D           # 圆形碰撞形状
var _time_since_last_update: float = 0.0         # 距离上次更新的时间


func _ready() -> void:
	# 创建圆形碰撞区域，用于粗略过滤潜在目标
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = radius
	_collision_shape = CollisionShape2D.new()
	_collision_shape.shape = circle_shape
	add_child(_collision_shape)

	# 初始绘制
	if debug_draw or Engine.is_editor_hint():
		queue_redraw()


func _process(delta: float) -> void:
	# 自动旋转
	if auto_rotate:
		rotation += deg_to_rad(rotation_speed) * delta

	# 调试绘制：如果启用 debug_draw，每帧重绘，以便实时反映参数变化
	if debug_draw:
		queue_redraw()


func _physics_process(delta: float) -> void:
	# 根据更新间隔决定是否进行检测
	if update_interval <= 0.0:
		# 每帧更新
		update_vision()
	else:
		_time_since_last_update += delta
		if _time_since_last_update >= update_interval:
			_time_since_last_update = 0.0
			update_vision()


## 强制立即更新可见列表（忽略更新间隔）
func force_update() -> void:
	update_vision()


## 返回当前缓存的可见物理体列表（若 update_interval > 0，可能不是实时最新）
func get_visible_bodies() -> Array[Node2D]:
	return _visible_bodies.duplicate()


## 执行视野检测：基于区域重叠、角度过滤和射线遮挡检查，更新 _visible_bodies 并发出信号
func update_vision() -> void:
	
	var space_state = get_world_2d().direct_space_state
	var all_overlapping = get_overlapping_bodies()
	var current_visible: Array[Node2D] = []

	# 当前面向方向（前方向量）
	var forward = Vector2.RIGHT.rotated(rotation)
	var half_angle_rad = deg_to_rad(angle) * 0.5

	# 构建要排除的物理对象 RID 列表（用于射线检测忽略自身和父节点）
	var exclude_rids: Array[RID] = []
	if exclude_self_and_parent:
		# 排除自身（Area2D 是 CollisionObject2D 的子类）
		if self is CollisionObject2D:
			exclude_rids.append(self.get_rid())
		# 排除父节点（假设它也是 CollisionObject2D）
		var parent = get_parent()
		if parent is CollisionObject2D:
			exclude_rids.append(parent.get_rid())

	for body in all_overlapping:

		# 目标组过滤
		if target_groups.size() > 0:
			var in_group = false
			for group in target_groups:
				if body.is_in_group(group):
					in_group = true
					break
			if not in_group:
				continue

		# 距离过滤（实际半径已由重叠区域保证，但可再次确认）
		var to_body = body.global_position - global_position
		var dist = to_body.length()
		if dist > radius:
			continue

		# 角度过滤
		var angle_diff = abs(forward.angle_to(to_body))
		if angle_diff > half_angle_rad:
			continue

		# 射线遮挡检测
		var query = PhysicsRayQueryParameters2D.create(
			global_position,
			body.global_position,
			obstacle_layers,
			exclude_rids
		)
		var result = space_state.intersect_ray(query)

		# 如果没有碰撞，或碰撞到的就是目标 body，则视为可见
		if result.is_empty() or result.collider == body:
			current_visible.append(body)

	# 与上一帧比较，发射进入/退出信号
	for body in current_visible:
		if body not in _visible_bodies and body != get_parent():
			body_entered_vision.emit(body)


	for body in _visible_bodies:
		if body not in current_visible and body != get_parent():
			body_exited_vision.emit(body)

	_visible_bodies = current_visible


func _draw() -> void:
	# 只在编辑器或启用 debug_draw 时绘制
	if not Engine.is_editor_hint() and not debug_draw:
		return

	# 绘制扇形填充（半透明）
	var fill_color = Color.YELLOW
	fill_color.a = 0.1
	var points = 32
	var arc_pts = PackedVector2Array()
	var step = deg_to_rad(angle) / (points - 1)
	var start_angle = rotation - deg_to_rad(angle) * 0.5
	for i in range(points):
		var a = start_angle + step * i
		arc_pts.append(Vector2.RIGHT.rotated(a) * radius)
	draw_polygon(arc_pts, [fill_color])

	# 绘制两条边界线（红色）
	var left_dir = Vector2.RIGHT.rotated(start_angle)
	var right_dir = Vector2.RIGHT.rotated(start_angle + deg_to_rad(angle))
	draw_line(Vector2.ZERO, left_dir * radius, Color.RED, 1.0)
	draw_line(Vector2.ZERO, right_dir * radius, Color.RED, 1.0)

	# 绘制中心线（黄色）
	draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(rotation) * radius, Color.YELLOW, 1.0)
