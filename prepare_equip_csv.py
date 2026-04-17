import csv
import json

sets_data = [
    {"set_id": "set_1", "set_name": "套装一", "trigger": "on_combo_x3", "effects": [{"type": "next_combo_dmg_mult", "value": 2.0}], "raw_desc": "每触发3次不同的连携技，下一次连携技伤害翻倍"},
    {"set_id": "set_2", "set_name": "套装二", "trigger": "on_combo", "effects": [{"type": "next_charge_instant", "value": True}], "raw_desc": "连携技触发后，下一次蓄力攻击无需蓄力（直接满蓄力效果）"},
    {"set_id": "set_3", "set_name": "套装三", "trigger": "passive", "effects": [{"type": "combo_req_reduce", "value": 1}], "raw_desc": "所有连携技的触发条件计数需求-1"}
]

items_data = [
    # Set 1
    ["set1_head_white", "set_1", "head", "white", [{"trigger": "on_combo", "type": "buff", "target": "next_hit", "stat": "crit_rate", "value": 0.10}], "触发连携技后，下次攻击暴击率+10%"],
    ["set1_head_blue", "set_1", "head", "blue", [{"trigger": "on_combo", "type": "buff", "target": "next_hit", "stat": "crit_rate", "value": 0.15}, {"trigger": "on_combo", "type": "buff", "target": "next_hit", "stat": "crit_dmg", "value": 0.20}], "触发连携技后，下次攻击暴击率+15%，暴击伤害+20%"],
    ["set1_head_gold", "set_1", "head", "gold", [{"trigger": "on_combo", "type": "buff", "target": "next_hit", "stat": "crit_rate", "value": 1.0}, {"trigger": "on_combo", "type": "buff", "target": "next_hit", "stat": "crit_dmg", "value": 0.30}], "触发连携技后，下次攻击必定暴击，暴击伤害+30%"],
    
    ["set1_body_white", "set_1", "body", "white", [{"trigger": "on_take_damage", "type": "buff", "stat": "speed", "value": 0.15, "duration": 5.0}], "受到伤害时，5秒内移速+15%"],
    ["set1_body_blue", "set_1", "body", "blue", [{"trigger": "on_take_damage", "type": "buff", "stat": "speed", "value": 0.20, "duration": 5.0}, {"trigger": "on_take_damage", "type": "buff", "stat": "damage_reduction", "value": 0.10, "duration": 5.0}], "受到伤害时，5秒内移速+20%，并获得10%减伤"],
    ["set1_body_gold", "set_1", "body", "gold", [{"trigger": "on_take_damage", "type": "buff", "stat": "speed", "value": 0.30, "duration": 5.0}, {"trigger": "on_take_damage", "type": "buff", "stat": "damage_reduction", "value": 0.15, "duration": 5.0}], "受到伤害时，5秒内移速+30%，获得15%减伤"],
    
    ["set1_foot_white", "set_1", "foot", "white", [{"trigger": "passive", "type": "stat", "stat": "speed", "value": 0.08}], "移速+8%"],
    ["set1_foot_blue", "set_1", "foot", "blue", [{"trigger": "passive", "type": "stat", "stat": "speed", "value": 0.12}, {"trigger": "on_dodge", "type": "buff", "stat": "speed", "value": 0.10, "duration": 3.0}], "移速+12%，闪避后移速额外+10%持续3秒"],
    ["set1_foot_gold", "set_1", "foot", "gold", [{"trigger": "passive", "type": "stat", "stat": "speed", "value": 0.15}, {"trigger": "passive", "type": "stat", "stat": "dodge_stamina_cost", "value": -0.50}, {"trigger": "on_dodge", "type": "buff", "stat": "speed", "value": 0.20, "duration": 3.0}], "移速+15%，闪避后移速额外+20%持续3秒，且闪避消耗体力-50%"],
    
    # Set 2
    ["set2_head_white", "set_2", "head", "white", [{"trigger": "passive", "type": "stat", "stat": "charge_dmg", "value": 0.15}], "蓄力攻击伤害+15%"],
    ["set2_head_blue", "set_2", "head", "blue", [{"trigger": "passive", "type": "stat", "stat": "charge_dmg", "value": 0.25}, {"trigger": "passive", "type": "stat", "stat": "charge_time", "value": -0.10}], "蓄力攻击伤害+25%，蓄力时间-10%"],
    ["set2_head_gold", "set_2", "head", "gold", [{"trigger": "passive", "type": "stat", "stat": "charge_dmg", "value": 0.35}, {"trigger": "passive", "type": "stat", "stat": "charge_time", "value": -0.20}, {"trigger": "passive", "type": "special", "effect": "full_charge_ignore_def", "value": 0.20}], "蓄力攻击伤害+35%，蓄力时间-20%，满蓄力时无视敌人20%防御"],
    
    ["set2_body_white", "set_2", "body", "white", [{"trigger": "passive", "type": "stat", "stat": "max_hp", "value": 0.12}], "最大生命值+12%"],
    ["set2_body_blue", "set_2", "body", "blue", [{"trigger": "passive", "type": "stat", "stat": "max_hp", "value": 0.18}, {"trigger": "passive", "type": "special", "effect": "charge_enemy_dmg_reduction", "value": 0.15}], "最大生命值+18%，受到蓄力攻击类敌人伤害-15%"],
    ["set2_body_gold", "set_2", "body", "gold", [{"trigger": "passive", "type": "stat", "stat": "max_hp", "value": 0.25}, {"trigger": "passive", "type": "stat", "stat": "damage_reduction", "value": 0.15}, {"trigger": "passive", "type": "special", "effect": "low_hp_dmg_reduction", "threshold": 0.30, "value": 0.20}], "最大生命值+25%，受到所有伤害-15%，生命值低于30%时获得20%减伤"],
    
    ["set2_foot_white", "set_2", "foot", "white", [{"trigger": "passive", "type": "stat", "stat": "speed", "value": -0.05}, {"trigger": "passive", "type": "stat", "stat": "dodge_stamina_cost", "value": 0.10}, {"trigger": "passive", "type": "stat", "stat": "def", "value": 0.10}], "移速-5%，闪避消耗体力+10%，防御力+10%"],
    ["set2_foot_blue", "set_2", "foot", "blue", [{"trigger": "passive", "type": "stat", "stat": "speed", "value": -0.03}, {"trigger": "passive", "type": "stat", "stat": "dodge_stamina_cost", "value": 0.05}, {"trigger": "passive", "type": "stat", "stat": "def", "value": 0.15}], "移速-3%，闪避消耗体力+5%，防御力+15%"],
    ["set2_foot_gold", "set_2", "foot", "gold", [{"trigger": "passive", "type": "stat", "stat": "def", "value": 0.20}], "防御力+20%"],
    
    # Set 3
    ["set3_head_white", "set_3", "head", "white", [{"trigger": "passive", "type": "stat", "stat": "combo_dmg", "value": 0.10}], "连携技伤害+10%"],
    ["set3_head_blue", "set_3", "head", "blue", [{"trigger": "passive", "type": "stat", "stat": "combo_dmg", "value": 0.15}], "连携技伤害+15%"],
    ["set3_head_gold", "set_3", "head", "gold", [{"trigger": "passive", "type": "stat", "stat": "combo_dmg", "value": 0.20}], "连携技伤害+20%"],
    
    ["set3_body_white", "set_3", "body", "white", [{"trigger": "on_combo", "type": "heal", "stat": "hp_percent", "value": 0.02}], "触发连携技后，回复2%生命"],
    ["set3_body_blue", "set_3", "body", "blue", [{"trigger": "on_combo", "type": "heal", "stat": "hp_percent", "value": 0.03}], "触发连携技后，回复3%生命"],
    ["set3_body_gold", "set_3", "body", "gold", [{"trigger": "on_combo", "type": "heal", "stat": "hp_percent", "value": 0.03}], "触发连携技后，回复3%生命"],
    
    ["set3_foot_white", "set_3", "foot", "white", [{"trigger": "passive", "type": "stat", "stat": "atk_speed", "value": 0.10}], "所有武器攻速+10%"],
    ["set3_foot_blue", "set_3", "foot", "blue", [{"trigger": "passive", "type": "stat", "stat": "atk_speed", "value": 0.15}], "所有武器攻速+15%"],
    ["set3_foot_gold", "set_3", "foot", "gold", [{"trigger": "passive", "type": "stat", "stat": "atk_speed", "value": 0.20}, {"trigger": "on_combo", "type": "stack_buff", "stat": "atk_speed", "value": 0.01}], "所有武器攻速+20%，每触发一次连携技所有武器攻速+1%（可叠加）"]
]

with open("Data/equipment_sets.csv", "w", encoding="utf-8", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["set_id", "set_name", "trigger", "effects", "raw_desc"])
    for s in sets_data:
        writer.writerow([s["set_id"], s["set_name"], s["trigger"], json.dumps(s["effects"]), s["raw_desc"]])

with open("Data/equipment_data.csv", "w", encoding="utf-8", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["id", "set_id", "part", "rarity", "effects", "raw_desc"])
    for item in items_data:
        writer.writerow([item[0], item[1], item[2], item[3], json.dumps(item[4]), item[5]])

print("Created Data/equipment_sets.csv and Data/equipment_data.csv")
