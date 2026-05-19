extends Enemy
class_name EliteEnemy

@export_group("精英属性")
@export var poise_max: float = 80.0
@onready var current_poise: float = poise_max

# 技能组件引用
var equipped_skill: EliteSkill = null

func _ready() -> void:
	super._ready()
	# 自动获取子节点中的第一个技能组件
	for child in get_children():
		if child is EliteSkill:
			equipped_skill = child
			break

## 重写攻击准备逻辑
func pre_attack(_msg: Dictionary = {}):
	if not is_instance_valid(target_player): return
	
	# 精英怪决策流：有技能先放技能，没技能执行普通武器攻击
	if equipped_skill and equipped_skill.is_ready:
		equipped_skill.execute(target_player)
	else:
		# 执行 Enemy 基类默认的普攻位移/逻辑
		super.pre_attack(_msg)

# 霸体逻辑保留
func take_damage(amount: float) -> void:
	current_poise -= amount
	if current_poise <= 0:
		current_poise = poise_max
		super.take_damage(amount)
	else:
		current_health -= amount # 只扣血不进受击态
		# 播放红色闪烁等特效
