extends CharacterBase
class_name 怪物

signal 死亡_

signal 受伤_ 
##如需复杂逻辑,请继承覆盖
func 受击(伤害:float):
	take_damage(伤害)
	if 伤害>0:受伤_.emit()

func die():
	死亡_.emit()
	super.die()
