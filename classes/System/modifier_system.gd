extends Node
class_name ModifierSystem

## 统一处理角色属性和Buff逻辑。避免将“移速计算”、“暴击计算”散落在角色逻辑各处

var base_stats: Dictionary = {
	"max_hp": 100.0,
	"speed": 300.0,
	"crit_rate": 0.05,
	"crit_dmg": 1.5,
	"charge_dmg": 1.0,
	"charge_time": 1.0,
	"damage_reduction": 0.0,
	"dodge_stamina_cost": 10.0,
	"def": 0.0,
	"combo_dmg": 1.0,
	"atk_speed": 1.0
}

# 存储计算终值的属性
var current_stats: Dictionary = {}

# 存储所有来源于装备、技能的修饰器 (Buff)
# buff_id -> { "type": "stat"/"buff"/"special", "stat": "speed", "value": 0.1, "duration": (可选)5.0, ... }
var active_modifiers: Dictionary = {}

func _ready() -> void:
	_recalculate_all()

func _process(delta: float) -> void:
	var expired_buffs: Array = []
	for buff_id in active_modifiers.keys():
		var mod: Dictionary = active_modifiers[buff_id]
		if mod.has("duration") and float(mod["duration"]) > 0.0:
			mod["duration"] = float(mod["duration"]) - delta
			if float(mod["duration"]) <= 0.0:
				expired_buffs.append(buff_id)

	for buff_id in expired_buffs:
		remove_modifier(buff_id)
		EventBus.on_buff_removed.emit(buff_id)

func add_modifier(mod_id: String, mod_data: Dictionary) -> void:
	# 每次添加都深拷贝，防止污染原数据
	active_modifiers[mod_id] = mod_data.duplicate(true)
	_recalculate_all()
	if float(mod_data.get("duration", 0.0)) > 0.0:
		EventBus.on_buff_added.emit(mod_id, mod_data)

func remove_modifier(mod_id: String) -> void:
	if active_modifiers.has(mod_id):
		active_modifiers.erase(mod_id)
		_recalculate_all()

func clear_modifiers_by_source(source_prefix: String) -> void:
	var to_remove = []
	for mod_id in active_modifiers.keys():
		if mod_id.begins_with(source_prefix):
			to_remove.append(mod_id)

	for mod_id in to_remove:
		active_modifiers.erase(mod_id)

	if not to_remove.is_empty():
		_recalculate_all()

func set_base_stat(stat_name: String, value: float) -> void:
	base_stats[stat_name] = value
	_recalculate_all()

func set_base_stats(stats: Dictionary) -> void:
	for stat_name in stats.keys():
		base_stats[stat_name] = float(stats[stat_name])
	_recalculate_all()

func get_stat(stat_name: String) -> float:
	return float(current_stats.get(stat_name, base_stats.get(stat_name, 0.0)))

func _recalculate_all() -> void:
	current_stats = base_stats.duplicate(true)

	var stat_adds: Dictionary = {}
	var stat_mults: Dictionary = {}

	for mod in active_modifiers.values():
		var mod_dict: Dictionary = mod
		if not mod_dict.has("stat"):
			continue

		var stat_name: String = str(mod_dict["stat"])
		var val: float = float(mod_dict.get("value", 0.0))

		if not stat_adds.has(stat_name):
			stat_adds[stat_name] = 0.0
		if not stat_mults.has(stat_name):
			stat_mults[stat_name] = 1.0

		if stat_name in ["crit_rate", "damage_reduction", "dodge_stamina_cost", "crit_dmg", "def"]:
			stat_adds[stat_name] = float(stat_adds[stat_name]) + val
		else:
			stat_mults[stat_name] = float(stat_mults[stat_name]) + val

	for stat_name in current_stats.keys():
		var base_val: float = float(base_stats[stat_name])
		var add_val: float = float(stat_adds.get(stat_name, 0.0))
		var mult_val: float = float(stat_mults.get(stat_name, 1.0))

		var final_val: float = base_val * mult_val + add_val
		current_stats[stat_name] = final_val
		EventBus.on_stat_changed.emit(stat_name, final_val)
