extends EliteEnemy
class_name MagicOrc


func _ready() -> void:
	super._ready()
	self.base_speed = 0.8 * 100 
	self.speed = base_speed
	
	# 自动寻找召唤技能组件
	for child in get_children():
		if child is EliteSkill:
			equipped_skill = child
			equipped_skill.owner_enemy = self
			break

## AI 决策逻辑
func process_movement(delta: float) -> void:
	if not is_instance_valid(target_player):
		super.process_movement(delta)
		return
		
	var dist = global_position.distance_to(target_player.global_position)
	
	# 1. 优先检查召唤技能
	if equipped_skill and equipped_skill.is_ready:
		if c_state_machine:
			c_state_machine.change_state(CharacterBase.STATE_ATTACK, {"use_skill": true})
			return

	# 这里保持基础追踪，但 Attack 状态会处理远程投射
	super.process_movement(delta)

## 状态机进入 Attack 状态时调用
func pre_attack(msg: Dictionary = {}):
	if not is_instance_valid(target_player): return

	if msg.get("use_skill") == true and equipped_skill:
		# 执行召唤技能
		equipped_skill.execute(target_player)
	else:
		# 执行普通攻击：远程施法/投射
		_perform_ranged_attack()

func _perform_ranged_attack():
	if anim: anim.play("cast_spell") 
	# 确保祭司装备的是远程武器，并在其内部逻辑中处理子弹发射
	if character_weapon:
		character_weapon.attack(target_player.global_position)
