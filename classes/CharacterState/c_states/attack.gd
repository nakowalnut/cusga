extends State
class_name AttackState




## 附加值使用示例
func enter(msg: Dictionary = {}) -> void:
	match msg.get("anim"):
		0:
			character.animation_player.play("attack1")
		1:
			character.animation_player.play("attack2")


func exit() -> void:
	pass

func physics_process(delta: float) -> void:
	# 播放攻击动画，停止移动
	character.velocity.x = 0

func get_state_name() -> String:
	return "Attack"
