extends Node

# 战斗核心事件
signal on_combo_triggered(combo_level, weapon_a, weapon_b)
signal on_damage_taken(damage_amount, source)
signal on_damage_dealt(damage_amount, target)
signal on_dodge()

# 装备与属性事件
signal on_equipment_changed(part, new_item_id)
signal on_stat_changed(stat_name, new_value)
signal on_buff_added(buff_id, buff_data)
signal on_buff_removed(buff_id)

# 特殊效果事件 (如“下一次蓄力满蓄”)
signal on_special_effect_triggered(effect_name, effect_params)
