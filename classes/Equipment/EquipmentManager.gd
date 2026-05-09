extends Node
class_name EquipmentManager

## 绑定ModifierSystem并在其上施加装备和套装的效果
@export var modifier_system: ModifierSystem

# 记录当前装备 { "head": "set1_head_white", "body": "", "foot": "" }
var equipped_items: Dictionary = {
	"head": "",
	"body": "",
	"foot": ""
}

# 当前触发叠加类型的Buff记录
var combo_count: int = 0

func _ready() -> void:
	EventBus.on_combo_triggered.connect(_on_combo)
	EventBus.on_damage_taken.connect(_on_take_damage)
	EventBus.on_dodge.connect(_on_dodge)

func equip_item(part: String, item_id: String) -> void:
	if equipped_items.has(part):
		equipped_items[part] = item_id
		reapply_all_equipment_effects()
		EventBus.on_equipment_changed.emit(part, item_id)

func get_active_sets() -> Dictionary:
	var set_counts = {}
	for part in equipped_items.keys():
		var eq_id = equipped_items[part]
		if eq_id and DataManager.equipment_data_dict.has(eq_id):
			var eq: EquipmentData = DataManager.equipment_data_dict[eq_id]
			if eq.set_id:
				set_counts[eq.set_id] = set_counts.get(eq.set_id, 0) + 1
	return set_counts

func reapply_all_equipment_effects() -> void:
	if not modifier_system: return
	
	# 先移除所有装备来源的全局被动效果
	modifier_system.clear_modifiers_by_source("equip_")
	modifier_system.clear_modifiers_by_source("set_")
	
	var active_sets = get_active_sets()
	
	# 1. 还原装备的被动(passive)属性
	for part in equipped_items.keys():
		var eq_id = equipped_items[part]
		if not eq_id or not DataManager.equipment_data_dict.has(eq_id):
			continue
		
		var eq: EquipmentData = DataManager.equipment_data_dict[eq_id]
		var idx = 0
		for effect in eq.effects:
			if effect.get("trigger", "") == "passive":
				var mod_id = "equip_%s_%s_%d" % [part, eq_id, idx]
				modifier_system.add_modifier(mod_id, effect)
			idx += 1

	# 2. 还原套装的被动属性 (若有)
	for set_id in active_sets.keys():
		var count = active_sets[set_id]
		if count >= 3: # 假设3件套激活效果
			if DataManager.equipment_sets_dict.has(set_id):
				var set_data: EquipmentSetData = DataManager.equipment_sets_dict[set_id]
				var idx = 0
				for effect in set_data.effects:
					if set_data.trigger == "passive":
						var mod_id = "set_%s_%d" % [set_id, idx]
						modifier_system.add_modifier(mod_id, effect)
					idx += 1

func _trigger_effects(trigger_type: String, context: Dictionary = {}) -> void:
	if not modifier_system: return
	
	# 检查单件装备触发
	for part in equipped_items.keys():
		var eq_id = equipped_items[part]
		if not eq_id or not DataManager.equipment_data_dict.has(eq_id):
			continue
		
		var eq: EquipmentData = DataManager.equipment_data_dict[eq_id]
		var idx = 0
		for effect in eq.effects:
			if effect.get("trigger", "") == trigger_type:
				_apply_dynamic_effect("equip_buff_%s_%d" % [eq_id, idx], effect, context)
			idx += 1

	# 检查套装触发
	var active_sets = get_active_sets()
	for set_id in active_sets.keys():
		if active_sets[set_id] >= 3:
			var set_data: EquipmentSetData = DataManager.equipment_sets_dict.get(set_id)
			if set_data and set_data.trigger == trigger_type:
				var idx = 0
				for effect in set_data.effects:
					_apply_dynamic_effect("set_buff_%s_%d" % [set_id, idx], effect, context)
					idx += 1

func _apply_dynamic_effect(effect_id: String, effect: Dictionary, context: Dictionary) -> void:
	var e_type = effect.get("type", "buff")
	
	if e_type == "buff":
		# 给带duration的增加唯一标识避免覆盖失效（或者根据策略刷新时间）
		var final_id = effect_id + "_" + str(Time.get_ticks_msec())
		modifier_system.add_modifier(final_id, effect)
	elif e_type == "stack_buff":
		# 比如攻速按照层数叠加，此处的ID不能加时间戳
		var stacks = effect.get("max_stacks", 99)
		combo_count += 1
		var dynamic_effect = effect.duplicate()
		dynamic_effect["value"] = effect["value"] * min(combo_count, stacks)
		modifier_system.add_modifier(effect_id, dynamic_effect)
	elif e_type == "heal":
		print("触发治疗效果, 比例:", effect.get("value"))
		# 此处可抛出治疗事件给角色，让角色执行加血，通过EventBus解耦
	elif e_type == "special":
		EventBus.on_special_effect_triggered.emit(effect.get("effect"), effect)
	elif e_type == "next_combo_dmg_mult":
		# 根据需求处理套装1效果，例如记录下次攻击倍数
		EventBus.on_special_effect_triggered.emit("next_combo_dmg_mult", effect)
	elif e_type == "next_charge_instant":
		EventBus.on_special_effect_triggered.emit("next_charge_instant", effect)

# ====== 事件监听槽函数 ======

func _on_combo(level: int, wep_a: Node, wep_b: Node) -> void:
	_trigger_effects("on_combo")

func _on_take_damage(amount: float, source: Node) -> void:
	_trigger_effects("on_take_damage", {"amount": amount, "source": source})
	
func _on_dodge() -> void:
	_trigger_effects("on_dodge")
