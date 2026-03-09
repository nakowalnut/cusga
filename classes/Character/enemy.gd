extends CharacterBase
class_name Enemy

##如需复杂逻辑,请继承覆盖
func 受击(伤害:float):
	take_damage(伤害)
	if 伤害>0:hurt.emit()

func die():
	died.emit()
	super.die()
