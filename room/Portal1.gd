extends Area2D

# 目标房间路径（现在由 Room 在生成时动态赋值）
var next_room_path: String = ""

func _ready():
	body_entered.connect(_on_body_entered)
	# 确保开启第 1 层的 Mask 检测（检测玩家身体）
	collision_mask |= 1 
	await get_tree().physics_frame
	$CollisionShape2D.disabled = false

func _on_body_entered(body):
	if body.is_in_group("player"):
		if next_room_path.is_empty():
			print("错误：该传送门未设置目标房间路径")
			return
		print("玩家触碰传送门，前往：", next_room_path)
		GameManager.load_room(next_room_path)
