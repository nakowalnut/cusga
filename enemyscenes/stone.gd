extends Area2D
class_name StoneProjectile

@export var speed: float = 600.0
@export var life_time: float = 2.0

var direction: Vector2 = Vector2.ZERO
var damage: float = 5.0
var weapon_owner: WeaponBase
var direct_damage: float = -1.0
var trigger_weapon_on_hit: bool = true

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	
	# 自毁定时器
func launch(start_pos: Vector2, dir: Vector2, w_owner: WeaponBase) -> void:
	# 1. 物理状态重置
	global_position = start_pos
	direction = dir.normalized()
	weapon_owner = w_owner
	rotation = direction.angle()
	
	# 2. 节点状态激活
	show()
	set_physics_process(true)
	monitoring = true 
	monitorable = true
	
	# 3. 替代原有的定时器逻辑
	# 使用场景树定时器，并在超时后调用回收函数
	get_tree().create_timer(life_time).timeout.connect(func():
		if is_inside_tree() and visible: # 确保没被提前回收
			recycle()
	)
func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	_hit(body)

func _on_area_entered(area: Area2D) -> void:
		if area is FieldOfView2D:
				return
		# 检测是否命中了敌人的 HitBox (Area2D)
		# 很多敌人的结构是 Character (Node) -> HitBox (Area2D)，所以找 parent
		var target = area.get_parent()
		
		# 针对 Slime 这种 HitBox 被放在孙子节点的特殊结构 (Character -> WeaponHolder -> HitBox)
		# 如果 parent 没有受击方法，则继续往上找一层
		if target and not target.has_method("take_damage"):
			target = target.get_parent()
			
		_hit(target)

func _hit(target: Node) -> void:
	if target and target.has_method("take_damage") and not target.get("is_dead"):
		if is_instance_valid(weapon_owner) and target == weapon_owner.weapon_owner:
			return

		if direct_damage >= 0.0:
			target.take_damage(direct_damage)
			if trigger_weapon_on_hit and is_instance_valid(weapon_owner):
				weapon_owner.on_hit(target)
		else:
			# 触发武器的命中逻辑从而叠加 combo
			if is_instance_valid(weapon_owner):
				weapon_owner.on_hit(target)
		recycle()
func recycle():
	set_physics_process(false)
	hide()
	
	if PoolManager:
		PoolManager.return_object(self)
	else:
		queue_free()
func _draw() -> void:
	# 绘制一个小三角形（素材代替）
	var points = PackedVector2Array([
		Vector2(10, 0),
		Vector2(-5, -5),
		Vector2(-5, 5)
	])
	draw_polygon(points, [Color.YELLOW, Color.YELLOW, Color.YELLOW])
