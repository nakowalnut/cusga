extends CharacterBase
class_name Player

@export var debug_mode: bool = false
var toward: int = 1# 面向方向 (Walk/Hurt 等状态依赖)

var hp: float:
	get: return current_health
	set(value): current_health = value
	
@onready var anim = $Sprite2D
@onready var animation_player = $AnimationPlayer

## 检查是否处于无法切换状态的硬直中
func can_change_state() -> bool:
	# 1. 检查是否正在播放攻击动画 
	if animation_player.is_playing():
		var anim_name = animation_player.current_animation
		if anim_name.begins_with("attack"):
			return false
	
	# 2. 检查基础状态机当前是否处于 受击 或 死亡 状态
	if c_state_machine.is_in_state("Hurt") or c_state_machine.is_in_state("Died"):
		return false
		
	return true

# 1. 武器数据定义
class Weapon:
	var name: String
	var damage: int
	var attack_range: float
	var animation: String
	var color: Color # 新增：用于演示切换的颜色
	
	func _init(_name: String, _color: Color, _damage: int, _range: float, _anim: String):
		self.name = _name
		self.color = _color
		self.damage = _damage
		self.attack_range = _range
		self.animation = _anim

# 2. 玩家/武器轮属性
@export var is_auto_mode: bool = true # 是否开启自动轮换模式

# 武器库 (已解锁的所有武器)
var all_weapons = {
	"sword": Weapon.new("长剑", Color.WHITE, 10, 50.0, "attack_sword"),
	"spear": Weapon.new("长矛", Color.RED, 8, 80.0, "attack_spear"),
	"dagger": Weapon.new("短刀", Color.BLUE, 15, 30.0, "attack_dagger"),
	"bow": Weapon.new("弓箭", Color.GREEN, 5, 200.0, "attack_bow")
}

# 当前武器轮 (玩家可自定义顺序)
var weapon_wheel: Array[String] = ["sword", "spear", "dagger"]
var current_weapon_index: int = 0
var is_attacking: bool = false

# 演示用节点引用
@onready var weapon_holder = $WeaponHolder
@onready var weapon_sprite = $WeaponHolder/CurrentWeapon # 这个 Sprite 的 Texture 设置为一个白色条状图片（棍子）
@onready var attack_hitbox = $AttackHitBox
@onready var attack_collider = $AttackHitBox/AttackCollider

func _ready() -> void:
	# 初始更新一次视觉
	_update_weapon_visual()

func _physics_process(_delta: float) -> void:
	move_and_slide()
	
	# 输入处理
	_handle_input()

func _handle_input() -> void:
	# 检查切换前置条件：必须没有正在攻击，且没在受击/死亡中
	if not can_change_state(): 
		return

	# 平A 
	if Input.is_action_just_pressed("attack"):
		c_state_machine.change_state("Attack", {"weapon": weapon_wheel[current_weapon_index]})
		
	# 手动切换 (滚轮): 显式切换
	if Input.is_action_just_pressed("switch_next"):
		_switch_weapon(1)
	elif Input.is_action_just_pressed("switch_prev"):
		_switch_weapon(-1)

# 核心逻辑：执行攻击并自动轮换
func _perform_attack() -> void:
	if weapon_wheel.size() == 0: return
	
	is_attacking = true
	var current_weapon_id = weapon_wheel[current_weapon_index]
	var weapon = all_weapons[current_weapon_id]
	
	print("使用武器攻击: ", weapon.name)
	
	# --- 视觉动画：让棍子摇一摇 ---
	var tween = create_tween()
	# 模拟攻击：向前伸出然后缩回 (刺击效果)，同时带点旋转抖动
	tween.tween_property(weapon_sprite, "position:x", 15.0, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(weapon_sprite, "rotation_degrees", 15.0, 0.05)
	
	tween.tween_property(weapon_sprite, "position:x", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(weapon_sprite, "rotation_degrees", 0.0, 0.15)
	
	if is_auto_mode:
		current_weapon_index = (current_weapon_index + 1) % weapon_wheel.size()
		print("自动轮换 - 下一次攻击将使用: ", weapon_wheel[current_weapon_index])
	else:
		print("手动模式 - 保持当前武器: ", weapon_wheel[current_weapon_index])
	
	_update_weapon_visual() # 更新视觉演示
	
	# 模拟攻击硬直结束
	await get_tree().create_timer(0.3).timeout
	is_attacking = false

# 手动切换逻辑
func _switch_weapon(dir: int) -> void:
	current_weapon_index = (current_weapon_index + dir) % weapon_wheel.size()
	if current_weapon_index < 0:
		current_weapon_index = weapon_wheel.size() - 1
	
	_update_weapon_visual() # 更新视觉演示
	print("手动切换至武器: ", weapon_wheel[current_weapon_index])

# 核心演示逻辑：更换棍子颜色
func _update_weapon_visual() -> void:
	if weapon_wheel.size() == 0: return
	
	var current_weapon_id = weapon_wheel[current_weapon_index]
	var weapon = all_weapons[current_weapon_id]
	
	# 通过调制颜色 (Self Modulate) 来模拟武器切换
	if weapon_sprite:
		weapon_sprite.self_modulate = weapon.color
	
	# 如果有攻击判定，可以在这里调整碰撞盒大小模拟不同武器长度
	# attack_collider.shape.extents = Vector2(weapon.attack_range, 10)

# 自定义武器轮接口 (供Tab菜单调用)
func update_weapon_sequence(new_sequence: Array[String]) -> void:
	weapon_wheel = new_sequence
	current_weapon_index = 0
