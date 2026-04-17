extends Node

var random_affixes_data : Dictionary = {}
var equipment_data_dict : Dictionary = {}
var equipment_sets_dict : Dictionary = {}

func _ready():
    load_random_affixes("res://Data/random_affixes.csv")
    load_equipment_data("res://Data/equipment_data.csv")
    load_equipment_sets("res://Data/equipment_sets.csv")

func load_equipment_data(file_path: String):
    var file = FileAccess.open(file_path, FileAccess.READ)
    if not file:
        print("未找到装备数据文件: ", file_path)
        return
        
    var headers = file.get_csv_line() 
    
    while not file.eof_reached():
        var line = file.get_csv_line()
        if line.size() < 6 or line[0] == "": 
            continue
            
        var dict = {}
        for i in range(headers.size()):
            if i < line.size():
                dict[headers[i]] = line[i]
                
        var equip = EquipmentData.new()
        equip.load_from_dict(dict)
        equipment_data_dict[equip.id] = equip
        
    file.close()
    print("成功加载装备数据: ", file_path, ", 共 ", equipment_data_dict.size(), " 条")

func load_equipment_sets(file_path: String):
    var file = FileAccess.open(file_path, FileAccess.READ)
    if not file:
        print("未找到套装数据文件: ", file_path)
        return
        
    var headers = file.get_csv_line() 
    
    while not file.eof_reached():
        var line = file.get_csv_line()
        if line.size() < 5 or line[0] == "": 
            continue
            
        var dict = {}
        for i in range(headers.size()):
            if i < line.size():
                dict[headers[i]] = line[i]
                
        var eq_set = EquipmentSetData.new()
        eq_set.load_from_dict(dict)
        equipment_sets_dict[eq_set.set_id] = eq_set
        
    file.close()
    print("成功加载套装数据: ", file_path, ", 共 ", equipment_sets_dict.size(), " 条")

func load_random_affixes(file_path: String):
    var file = FileAccess.open(file_path, FileAccess.READ)
    if not file:
        print("未找到词条文件: ", file_path)
        return
        
    var headers = file.get_csv_line() 
    
    while not file.eof_reached():
        var line = file.get_csv_line()
        if line.size() < 6 or line[0] == "": 
            continue
            
        var affix_id = line[0]
        random_affixes_data[affix_id] = {
            "name": line[1],
            "stat_type": line[2],
            "min_val": float(line[3]),
            "max_val": float(line[4]),
            "desc": line[5]
        }
    file.close()
    print("成功加载词条数据: Data/random_affixes.csv, 共 ", random_affixes_data.size(), " 条")

func generate_random_affix(affix_id: String) -> Dictionary:
    if not random_affixes_data.has(affix_id):
        return {}
        
    var template = random_affixes_data[affix_id]
    var final_value = randf_range(template["min_val"], template["max_val"])
    
    return {
        "id": affix_id,
        "name": template["name"],
        "stat_type": template["stat_type"],
        "value": final_value,
        "desc": template["desc"].replace("{val}", str(round(final_value * 100)))
    }
