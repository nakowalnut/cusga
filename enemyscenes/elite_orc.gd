
extends EliteEnemy

# 删掉这一行：var equipped_skill: EliteSkill 

func _ready() -> void:
	super._ready() # 确保调用基类的初始化逻辑
	
	# 如果基类没有自动查找组件，子类可以手动赋值
	for child in get_children():
		if child is EliteSkill:
			equipped_skill = child # 直接使用父类的变量
			equipped_skill.owner_enemy = self
			break
