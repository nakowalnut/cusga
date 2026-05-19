
extends EliteEnemy
class_name BossBase


@export_group("Boss 配置")
@export var boss_name: String = "未命名 Boss"
@export var basic_attack_modes: Array[String] = ["default"]
# 技能列表改为自动扫描或手动指定
var all_skills: Array[EliteSkill] = []

func _ready() -> void:
	super._ready()
	# 收集所有技能组件
	for child in get_children():
		if child is EliteSkill:
			all_skills.append(child)

## 重写 Boss 的决策逻辑
func pre_attack(_msg: Dictionary = {}):
	if not is_instance_valid(target_player): return
	
	# 1. 获取所有 CD 好的技能
	var ready_skills = all_skills.filter(func(s): return s.is_ready)
	
	# 2. 行为优先级决策
	if ready_skills.size() > 0:
		# 随机释放一个可用技能
		var selected_skill = ready_skills.pick_random()
		selected_skill.execute(target_player)
	else:
		# 3. 技能全在 CD，执行随机普攻模式
		_perform_basic_attack()

func _perform_basic_attack():
	# 这里可以根据之前定义的 basic_attack_modes 随机选一个动画
	# 或者直接调用 super.pre_attack
	super.pre_attack()
