extends WeaponBase

@onready var hit_area: Area2D = $HitArea

func _ready() -> void:
	hit_area.monitoring = false
	hit_area.body_entered.connect(_on_body_entered)

func attack(target_pos: Vector2) -> void:
	look_at(target_pos)
	hit_area.monitoring = true
	# 持续时间匹配基类的 attack_duration
	await get_tree().create_timer(attack_duration).timeout
	hit_area.monitoring = false

func _on_body_entered(body):
	if body.is_in_group("player"):
		deal_damage(body) # 调用基类接口，处理伤害、打印和Combo
		on_hit(body)
