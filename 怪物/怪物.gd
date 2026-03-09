extends CharacterBody2D
class_name 怪物

signal 死亡_
var 生命:int:
	set(a):
		生命=a
		if a<=0:死亡_.emit()

signal 受伤_ 
##如需复杂逻辑,请继承覆盖
func 受击(伤害:int):
	if 伤害>0:受伤_.emit()
	生命-=伤害
