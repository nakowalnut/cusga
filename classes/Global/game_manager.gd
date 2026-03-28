## 游戏的总逻辑，放在自动加载始终执行
extends Node
var player: Player

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass

func get_direction(from_position: Vector2, to_position: Vector2) -> Vector2:
	return from_position.direction_to(to_position)

func get_distance(from_position: Vector2, to_position: Vector2) -> float:
	return from_position.distance_to(to_position)

func player_die() -> void:
	print("Player died! Game Over!")
	# 如果有场景重启的逻辑可以在这里调用，比如 get_tree().reload_current_scene()
	pass
