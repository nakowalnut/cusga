extends Resource
class_name EquipmentSetData

@export var set_id: String = ""
@export var set_name: String = ""
@export var trigger: String = ""
@export var effects: Array = []
@export var raw_desc: String = ""

func load_from_dict(data: Dictionary) -> void:
    set_id = data.get("set_id", "")
    set_name = data.get("set_name", "")
    trigger = data.get("trigger", "")
    raw_desc = data.get("raw_desc", "")
    
    var effects_json = data.get("effects", "[]")
    var json = JSON.new()
    if json.parse(effects_json) == OK:
        if typeof(json.get_data()) == TYPE_ARRAY:
            effects = json.get_data()
    else:
        push_error("Failed to parse equipment set effects for " + set_id)
