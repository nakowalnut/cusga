extends Node
class_name StatManager

var base_stats : Dictionary = {
    "attack": 100.0,
    "crit_rate": 0.05,
    "combo_dmg": 1.0,
    "atk_speed": 1.0,
    "damage_reduction": 0.0,
    "move_speed": 300.0
}

var stat_modifiers : Dictionary = {}

func get_stat(stat_type: String) -> float:
    if not base_stats.has(stat_type):
        return 0.0
        
    var base = base_stats[stat_type]
    var modifier = stat_modifiers.get(stat_type, 0.0)
    
    if stat_type in ["crit_rate", "damage_reduction"]:
        return base + modifier
    else:
        return base * (1.0 + modifier)

func add_affix(affix_data: Dictionary):
    var stype = affix_data["stat_type"]
    var val = affix_data["value"]
    
    if stat_modifiers.has(stype):
        stat_modifiers[stype] += val
    else:
        stat_modifiers[stype] = val
        
    print("属性更新！当前 ", stype, " 的增益变为: ", stat_modifiers[stype])
    
func remove_affix(affix_data: Dictionary):
    var stype = affix_data["stat_type"]
    var val = affix_data["value"]
    
    if stat_modifiers.has(stype):
        stat_modifiers[stype] -= val
        print("属性移除！当前 ", stype, " 的增益变为: ", stat_modifiers[stype])
