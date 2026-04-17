extends Node

var random_affixes_data : Dictionary = {}

func _ready():
    load_random_affixes("res://Data/random_affixes.csv")

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
