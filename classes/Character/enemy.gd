extends CharacterBase
class_name Enemy

##如需复杂逻辑,请继承覆盖
func Hit(damage:float):
	take_damage(damage)
	if damage>0:hurt.emit()
