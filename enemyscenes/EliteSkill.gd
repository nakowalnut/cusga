extends Node2D
class_name EliteSkill

@export var skill_name: String = "未命名技能"
@export var cooldown: float = 5.0
@export var damage_multiplier: float = 1.5

var is_ready: bool = true
var timer: float = 0.0
var owner_enemy: CharacterBase # 统一使用基类引用

func _ready() -> void:
	# 自动寻找父节点作为拥有者
	if get_parent() is CharacterBase:
		owner_enemy = get_parent()
	elif get_parent().get_parent() is CharacterBase:
		owner_enemy = get_parent().get_parent()
	
	timer = 0.0
	is_ready = true

func _process(delta: float) -> void:
	if not is_ready:
		timer -= delta
		if timer <= 0:
			is_ready = true
			timer = cooldown

# 外部调用的统一接口
func execute(target: Node2D) -> bool:
	if is_ready:
		is_ready = false
		timer = cooldown
		perform_skill_logic(target)
		return true
	return false

# 子类重写此方法实现具体逻辑
func perform_skill_logic(_target: Node2D) -> void:
	pass

# 技能动作完成后的回调
func _on_skill_finished():
	if owner_enemy and owner_enemy.has_method("end_attack"):
		owner_enemy.end_attack()
