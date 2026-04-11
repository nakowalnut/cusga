extends Enemy
class_name EliteEnemy

@export_group("精英属性")
@export var poise_max: float = 80.0      # 霸体值
@export var skill_cooldown: float = 5.0  # 技能冷却时间

var current_poise: float
var skill_timer: float = 0.0             # 技能计时器
var can_use_skill: bool = true

func _ready() -> void:
	# 霸体初始化
	current_poise = poise_max
	
	# 如果父类有 _ready 则调用（即便现在没有，加上这句也是良好的编程习惯）
	if super.has_method("_ready"):
		super._ready()

func _process(delta: float) -> void:
	# 独立处理技能冷却计时
	if not can_use_skill:
		skill_timer -= delta
		if skill_timer <= 0:
			can_use_skill = true

## 重写受击逻辑
## 注意：这会拦截子类原本的 take_damage
func take_damage(amount: float) -> void:
	# 1. 霸体削减
	current_poise -= amount
	
	# 2. 判断是否触发硬直
	if current_poise <= 0:
		current_poise = poise_max
		# 霸体碎了，允许进入 HurtState
		# 我们调用 super.take_damage(amount) 让父类处理实际扣血和状态切换
		if super.has_method("take_damage"):
			super.take_damage(amount)
	else:
		# 霸体还在：
		# 我们手动处理扣血，但不切换状态机（不触发 super.take_damage）
		_apply_damage_only(amount)
		flash_red_effect()

## 内部方法：只扣血，不回退状态
func _apply_damage_only(amount: float):
	# 关键：既然父类没定义血量，我们就假设子类（如 Orc）有 health 变量
	# 使用 set/get 可以避免编译器因为找不到变量而报错
	if "health" in self:
		set("health", get("health") - amount)
	elif "current_health" in self:
		set("current_health", get("current_health") - amount)
	
	# 如果你有死亡检测逻辑，也需要在这里补上
	if get("health") <= 0 or get("current_health") <= 0:
		if has_method("die"): # 假设你有 die 方法
			call("die")

func flash_red_effect() -> void:
	var t = create_tween()
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, "modulate", Color.RED, 0.05)
	t.tween_property(self, "modulate", Color.WHITE, 0.05)

func reset_enemy() -> void:
	if super.has_method("reset_enemy"):
		super.reset_enemy()
	current_poise = poise_max
	skill_timer = 0
	can_use_skill = true

## 供子类在攻击状态中检查并触发技能
func use_skill() -> bool:
	if can_use_skill:
		can_use_skill = false
		skill_timer = skill_cooldown
		return true
	return false
