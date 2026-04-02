extends Node

class_name ComboManagerClass

var combos: Dictionary = {}

func _ready() -> void:
	# 长剑组合
	_register_combo("sword", "sword", preload("res://classes/Weapons/Combos/Impl/combo_sword_sword.gd"))
	_register_combo("sword", "dagger", preload("res://classes/Weapons/Combos/Impl/combo_sword_dagger.gd"))
	_register_combo("sword", "bow", preload("res://classes/Weapons/Combos/Impl/combo_sword_bow.gd"))
	_register_combo("sword", "hammer", preload("res://classes/Weapons/Combos/Impl/combo_sword_hammer.gd"))
	_register_combo("sword", "spear", preload("res://classes/Weapons/Combos/Impl/combo_sword_spear.gd"))
	
	# 短剑组合
	_register_combo("dagger", "dagger", preload("res://classes/Weapons/Combos/Impl/combo_dagger_dagger.gd"))
	_register_combo("dagger", "bow", preload("res://classes/Weapons/Combos/Impl/combo_dagger_bow.gd"))
	_register_combo("dagger", "hammer", preload("res://classes/Weapons/Combos/Impl/combo_dagger_hammer.gd"))
	_register_combo("dagger", "spear", preload("res://classes/Weapons/Combos/Impl/combo_dagger_spear.gd"))
	
	# 弓组合
	_register_combo("bow", "bow", preload("res://classes/Weapons/Combos/Impl/combo_bow_bow.gd"))
	_register_combo("bow", "hammer", preload("res://classes/Weapons/Combos/Impl/combo_bow_hammer.gd"))
	_register_combo("bow", "spear", preload("res://classes/Weapons/Combos/Impl/combo_bow_spear.gd"))
	
	# 锤子组合
	_register_combo("hammer", "hammer", preload("res://classes/Weapons/Combos/Impl/combo_hammer_hammer.gd"))
	_register_combo("hammer", "spear", preload("res://classes/Weapons/Combos/Impl/combo_hammer_spear.gd"))

	# 矛组合
	_register_combo("spear", "spear", preload("res://classes/Weapons/Combos/Impl/combo_spear_spear.gd"))


func _register_combo(wp1: String, wp2: String, script: GDScript) -> void:
	if not script:
		return
	var key = _get_combo_key(wp1, wp2)
	combos[key] = script

func _get_combo_key(wp1: String, wp2: String) -> String:
	# 保证无方向性，按字母表排序 A_B
	var arr = [wp1.to_lower(), wp2.to_lower()]
	arr.sort()
	return arr[0] + "_" + arr[1]

func trigger_combo(player: CharacterBase, current_weapon: WeaponBase, next_weapon_name: String) -> void:
	var cur_name = ""
	# 处理 weapon_name 可能和 ID 不完全对应的情况，最好传 weapon id (如 "sword")
	# current_weapon.weapon_name 是中文名（"未命名武器"），所以我们要在武器本身或者通过转换拿到它的英文ID。
	# 为稳妥起见，我们提供一个映射：
	if current_weapon is SwordWeapon: cur_name = "sword"
	elif current_weapon is SpearWeapon: cur_name = "spear"
	elif current_weapon is DaggerWeapon: cur_name = "dagger"
	elif current_weapon is BowWeapon: cur_name = "bow"
	elif current_weapon is HammerWeapon: cur_name = "hammer"
	else:
		cur_name = current_weapon.name.to_lower().replace("weapon", "") # fallback

	var key = _get_combo_key(cur_name, next_weapon_name)
	print("[ComboManager] 尝试触发连携技: ", key)
	
	if combos.has(key):
		var combo_script_class = combos[key]
		var combo_instance = combo_script_class.new()
		# 将实例添加到树中以支持内部计时器、补间动画等
		add_child(combo_instance)
		combo_instance.execute(player, current_weapon, next_weapon_name)
	else:
		print("[ComboManager] 未找到对应连携技: ", key)
