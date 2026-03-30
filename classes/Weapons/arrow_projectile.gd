extends Area2D
class_name ArrowProjectile

@export var speed: float = 600.0
@export var life_time: float = 2.0

var direction: Vector2 = Vector2.ZERO
var damage: float = 5.0
var weapon_owner: WeaponBase

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# 自毁定时器
	get_tree().create_timer(life_time).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	_hit(body)

func _on_area_entered(area: Area2D) -> void:
	# 如果敌人的受击区域是 Area2D
	_hit(area.get_parent())

func _hit(target: Node) -> void:
	if target and target.has_method("take_damage") and not target.get("is_dead"):
		# 触发武器的命中逻辑从而叠加 combo
		if is_instance_valid(weapon_owner):
			weapon_owner.on_hit(target)
		queue_free()

func _draw() -> void:
	# 绘制一个小三角形（素材代替）
	var points = PackedVector2Array([
		Vector2(10, 0),
		Vector2(-5, -5),
		Vector2(-5, 5)
	])
	draw_polygon(points, [Color.YELLOW, Color.YELLOW, Color.YELLOW])
