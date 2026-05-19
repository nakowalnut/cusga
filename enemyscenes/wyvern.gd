extends EliteEnemy
class_name WyvernElite

# 删除了 var fire_skill: EliteSkill，直接使用父类的 equipped_skill

func _ready() -> void:
	super._ready()
	# 飞龙移动速度较快
	self.speed = 1.2 * 100 
	
	# 自动寻找喷火技能组件并绑定
	for child in get_children():
		if child is EliteSkill:
			equipped_skill = child
			equipped_skill.owner_enemy = self
			break

## 飞行怪特定的移动逻辑
func process_movement(delta: float) -> void:
	if not is_instance_valid(target_player):
		super.process_movement(delta)
		return
		
	var dist = global_position.distance_to(target_player.global_position)
	
	# 决策流：如果技能（喷火）就绪且距离合适
	if equipped_skill and equipped_skill.is_ready and dist < 250:
		if c_state_machine:
			c_state_machine.change_state(CharacterBase.STATE_ATTACK, {"use_skill": true})
			return
	
	# 常态：飞行追击逻辑（可以保持在空中盘旋或直接追向玩家）
	super.process_movement(delta)

## 状态机进入 Attack 时的具体表现
func pre_attack(msg: Dictionary = {}):
	if msg.get("use_skill") and equipped_skill:
		# 执行喷火技能
		equipped_skill.execute(target_player)
	else:
		# 执行普通攻击：爪击
		_perform_basic_attack()

func _perform_basic_attack():
	if anim: anim.play("claw_attack")
	# 爪击通常是近战或掠过攻击
	if character_weapon:
		character_weapon.attack(target_player.global_position)
