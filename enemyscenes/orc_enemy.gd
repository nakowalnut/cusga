extends Enemy
class_name OrcEnemy

@onready var sprite: AnimatedSprite2D = $orcs

func _ready() -> void:
	super._ready()
	# 监听动画播放完毕的信号，用来安全退出攻击状态
	if sprite:
		if not sprite.animation_finished.is_connected(_on_animation_finished):
			sprite.animation_finished.connect(_on_animation_finished)

func pre_attack(_msg: Dictionary = {}) -> void:
	if not is_instance_valid(target_player) or not sprite:
		_force_end_attack()
		return
	
	# 1. 面向玩家目标
	if "character_weapon" in self and character_weapon:
		character_weapon.look_at(target_player.global_position)

	# 2. 播放刚才你配好的 attack 动画
	sprite.play("attack")
	
	# 3. 监听帧改变，当播到特定帧（例如大棒砸下的那一帧）时，才触发伤害
	if not sprite.frame_changed.is_connected(_on_sprite_frame_changed):
		sprite.frame_changed.connect(_on_sprite_frame_changed)

# 核心：帧同步伤害判定
func _on_sprite_frame_changed() -> void:
	if sprite.animation == "attack":
		# 假设你的 attack 动画一共有 5 帧（0 到 4），第 3 帧是大棒砸到地面的那一瞬间
		# 你可以根据实际视觉效果，把 3 改成你满意的帧数
		if sprite.frame == 3: 
			if character_weapon and is_instance_valid(target_player):
				character_weapon.attack(target_player.global_position)
			# 触发完伤害就断开监听，防止一轮攻击里重复触发
			if sprite.frame_changed.is_connected(_on_sprite_frame_changed):
				sprite.frame_changed.disconnect(_on_sprite_frame_changed)

# 核心：动画播完后，安全退出攻击状态，防止卡死
func _on_animation_finished() -> void:
	if sprite.animation == "attack":
		# 如果帧改变的监听没断开，顺手断开它
		if sprite.frame_changed.is_connected(_on_sprite_frame_changed):
			sprite.frame_changed.disconnect(_on_sprite_frame_changed)
		
		# 通知状态机：攻击结束了！
		_force_end_attack()

## 强行结束攻击的辅助通知函数
func _force_end_attack() -> void:
	if "attack_controller" in self and is_instance_valid(attack_controller):
		if attack_controller.has_signal("attack_ended"):
			attack_controller.attack_ended.emit()
	if has_method("end_attack"):
		end_attack()
