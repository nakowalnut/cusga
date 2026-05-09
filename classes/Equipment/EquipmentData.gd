extends Resource
class_name EquipmentData

@export var id: String = ""
@export var set_id: String = ""
@export var part: String = ""
@export var rarity: String = ""
@export var effects: Array = []
@export var raw_desc: String = ""

func load_from_dict(data: Dictionary) -> void:
    id = data.get("id", "")
    set_id = data.get("set_id", "")
    part = data.get("part", "")
    rarity = data.get("rarity", "")
    raw_desc = data.get("raw_desc", "")
    
    var effects_json = data.get("effects", "[]")
    var json = JSON.new()
    if json.parse(effects_json) == OK:
        if typeof(json.get_data()) == TYPE_ARRAY:
            effects = json.get_data()
    else:
        push_error("Failed to parse equipment effects for " + id)
