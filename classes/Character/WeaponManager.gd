class_name WeaponManager extends Node

signal weapon_switched(weapon_id: String)
signal attack_requested(weapon_id: String, is_charged: bool, bypass_charge: bool)
signal hit_registered(target: Node)

@export var player: CharacterBase
@export var weapon_holder: Node2D
@export var weapon_tuning_profiles: Array = []

var all_weapons: Dictionary = {}
var weapon_wheel: Array[String] = ["sword", "spear", "dagger", "bow", "hammer"]
var current_weapon_index: int = 0
var current_weapon_node = null

func _ready() -> void:
	# 延迟初始化等待父节点就绪
	pass

func init_weapons() -> void:
	# 迁移自原 player.gd 的 _init_weapons
	all_weapons["sword"] = SwordWeapon.new()
	all_weapons["spear"] = SpearWeapon.new()
	all_weapons["dagger"] = DaggerWeapon.new()
	all_weapons["bow"] = BowWeapon.new()
	all_weapons["hammer"] = HammerWeapon.new()

	for key in all_weapons:
		var wp = all_weapons[key]
		_apply_weapon_tuning(key, wp)
		wp.weapon_owner = player
		if weapon_holder:
			weapon_holder.add_child(wp)
			
	if all_weapons.size() > 0:
		switch_to_weapon(weapon_wheel[0])

func _apply_weapon_tuning(weapon_id: String, weapon: Node) -> void:
	if not is_instance_valid(weapon): return
	for profile in weapon_tuning_profiles:
		if not is_instance_valid(profile): continue
		if profile.weapon_id == weapon_id:
			profile.apply_to(weapon)
			return

func switch_to_weapon(weapon_id: String) -> void:
	if not all_weapons.has(weapon_id): return
	current_weapon_node = all_weapons[weapon_id]
	weapon_switched.emit(weapon_id)

func switch_and_attack() -> void:
	# 迁移 _switch_and_attack() 逻辑
	current_weapon_index = (current_weapon_index + 1) % weapon_wheel.size()
	var next_wep = weapon_wheel[current_weapon_index]
	switch_to_weapon(next_wep)
	attack_requested.emit(next_wep, false, false)

func process_hit(target: Node) -> void:
	hit_registered.emit(target)

## 攻击键按下 — 转发给当前武器
func on_attack_pressed() -> void:
	if is_instance_valid(current_weapon_node) and current_weapon_node.has_method("on_attack_pressed"):
		current_weapon_node.on_attack_pressed()

## 攻击键松开 — 转发给当前武器
func on_attack_released() -> void:
	if is_instance_valid(current_weapon_node) and current_weapon_node.has_method("on_attack_released"):
		current_weapon_node.on_attack_released()

## 当前武器是否为蓄力类型
func is_charge_weapon() -> bool:
	if is_instance_valid(current_weapon_node):
		return current_weapon_node.get("is_charge_weapon") == true
	return false

## 获取当前武器 ID（快捷方法）
func get_current_weapon_id() -> String:
	if weapon_wheel.size() > 0:
		return weapon_wheel[current_weapon_index]
	return ""

## 切枪并尝试连携（原 _switch_and_attack 逻辑）
func switch_and_combo(new_index: int) -> Dictionary:
	
	#返回一个字典，供 Player 决定是否进入攻击状态：
	#{ "combo_triggered": bool, "prev_weapon": String, "new_weapon": String }
   
	if new_index < 0 or new_index >= weapon_wheel.size():
		return {"combo_triggered": false, "prev_weapon": "", "new_weapon": ""}

	var prev_weapon_id = weapon_wheel[current_weapon_index]
	var new_weapon_id = weapon_wheel[new_index]

	var combo_triggered := false
	if is_instance_valid(current_weapon_node) and current_weapon_node.has_method("on_switch_out"):
		combo_triggered = current_weapon_node.on_switch_out(new_weapon_id)

	current_weapon_index = new_index
	switch_to_weapon(new_weapon_id)  # 会发出 weapon_switched 信号 → Player 更新视觉

	return {
		"combo_triggered": combo_triggered,
		"prev_weapon": prev_weapon_id,
		"new_weapon": new_weapon_id
	}
