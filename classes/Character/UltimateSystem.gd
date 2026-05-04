class_name UltimateSystem extends Node

@export var ULTIMATE_MAX_POINTS: int = 3
@export var ULTIMATE_DURATION: float = 150.0

var ultimate_points: int = 0
var in_ultimate_mode: bool = false
var ultimate_weapon_cycle: Array[String] = ["sword", "dagger", "spear", "hammer"]
var ultimate_cycle_index: int = -1

@export var player: CharacterBase
@export var weapon_manager: WeaponManager

const ULTIMATE_ARROW_SCENE = preload("res://Scenes/Prefab/arrow_projectile.tscn")
const ULTIMATE_ARROW_DAMAGE: float = 4.0

func _ready() -> void:
	if weapon_manager:
		weapon_manager.hit_registered.connect(_on_weapon_hit)

func add_point() -> void:
	if ultimate_points < ULTIMATE_MAX_POINTS:
		ultimate_points += 1
		print("大招能量: ", ultimate_points, "/", ULTIMATE_MAX_POINTS)

func try_cast_ultimate() -> void:
	if ultimate_points >= ULTIMATE_MAX_POINTS and not in_ultimate_mode:
		in_ultimate_mode = true
		ultimate_points = 0
		print("大招开启")
		# 触发大招相关的状态逻辑...

func cycle_weapon() -> void:
	ultimate_cycle_index = (ultimate_cycle_index + 1) % ultimate_weapon_cycle.size()
	var next_wep = ultimate_weapon_cycle[ultimate_cycle_index]
	weapon_manager.switch_to_weapon(next_wep)

func _on_weapon_hit(target: Node) -> void:
	if in_ultimate_mode:
		apply_ultimate_arrow_rain(target)

func apply_ultimate_arrow_rain(target: Node) -> void:
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return
	spawn_ultimate_followup_arrow(target, 0.2)
	spawn_ultimate_followup_arrow(target, 0.4)

func spawn_ultimate_followup_arrow(target: Node, delay: float) -> void:
	var timer = get_tree().create_timer(delay)
	timer.timeout.connect(func():
		if not is_instance_valid(target): return
		var proj = ULTIMATE_ARROW_SCENE.instantiate()
		proj.damage = ULTIMATE_ARROW_DAMAGE
		proj.global_position = target.global_position + Vector2(randf_range(-20, 20), -60)
		proj.direction = Vector2.DOWN
		get_tree().current_scene.add_child(proj)
	)
