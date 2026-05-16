extends CanvasLayer

const CHEAT_SEQUENCE: Array[int] = [KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT]

@onready var panel: PanelContainer = $PanelContainer
@onready var output_label: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/Output
@onready var input_line: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/Input

var _buffer: Array[int] = []
var _affix_modifier_ids: Array[String] = []
var _next_affix_mod_index: int = 1
var _weapon_base_damage_cache: Dictionary = {}
var _weapon_damage_bonus: float = 0.0
var _infinite_combo_enabled: bool = false

func _ready() -> void:
	visible = false
	input_line.text_submitted.connect(_on_command_submitted)
	_log("Cheat console ready. Enter secret sequence to open.")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_handle_secret_key(event.keycode)
		if visible and event.keycode == KEY_ESCAPE:
			_toggle_console(false)
			get_viewport().set_input_as_handled()

func _handle_secret_key(keycode: int) -> void:
	if keycode not in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
		if _buffer.size() > 0:
			_buffer.clear()
		return

	_buffer.append(keycode)
	while _buffer.size() > CHEAT_SEQUENCE.size():
		_buffer.remove_at(0)

	if _buffer == CHEAT_SEQUENCE:
		_toggle_console(not visible)
		_buffer.clear()

func _toggle_console(open: bool) -> void:
	visible = open
	panel.visible = open
	if open:
		_log("Cheat enabled. Type 'help'.")
		input_line.grab_focus()
	else:
		_log("Cheat closed.")

func _on_command_submitted(text: String) -> void:
	var cmd := text.strip_edges()
	input_line.clear()
	if cmd.is_empty():
		return

	_log("> " + cmd)
	_execute_command(cmd)
	input_line.grab_focus()

func _execute_command(cmd: String) -> void:
	var args: PackedStringArray = cmd.to_lower().split(" ", false)
	if args.is_empty():
		return

	match args[0]:
		"help":
			_print_help()
		"list":
			if args.size() < 2:
				_log("Usage: list equips | list affixes")
				return
			if args[1] == "equips":
				_list_equips()
			elif args[1] == "affixes":
				_list_affixes()
			else:
				_log("Unknown list target: " + args[1])
		"give":
			_handle_give_command(cmd, args)
		"clear":
			if args.size() < 2:
				_log("Usage: clear equip | clear affix")
				return
			if args[1] == "equip":
				_clear_equip()
			elif args[1] == "affix":
				_clear_affixes()
			else:
				_log("Unknown clear target: " + args[1])
		"infinite_combo":
			_toggle_infinite_combo()
		"close":
			_toggle_console(false)
		_:
			_log("Unknown command. Type 'help'.")

func _handle_give_command(raw_cmd: String, args: PackedStringArray) -> void:
	if args.size() < 3:
		_log("Usage: give equip <item_id> | give affix <affix_id> | give all affixes")
		return

	if args[1] == "equip":
		var item_id := raw_cmd.substr("give equip ".length()).strip_edges()
		if item_id.is_empty():
			_log("Usage: give equip <item_id>")
			return
		_give_equip(item_id)
		return

	if args[1] == "affix":
		var affix_id := raw_cmd.substr("give affix ".length()).strip_edges()
		if affix_id.is_empty():
			_log("Usage: give affix <affix_id>")
			return
		_give_affix(affix_id)
		return

	if args[1] == "all" and args.size() >= 3 and args[2] == "affixes":
		_give_all_affixes()
		return

	_log("Unsupported give command.")

func _print_help() -> void:
	_log("Commands:")
	_log("help")
	_log("list equips")
	_log("list affixes")
	_log("give equip <item_id>")
	_log("give affix <affix_id>")
	_log("give all affixes")
	_log("clear equip")
	_log("clear affix")
	_log("infinite_combo")
	_log("close")

func _list_equips() -> void:
	if not is_instance_valid(DataManager):
		_log("DataManager unavailable.")
		return

	var ids: Array = DataManager.equipment_data_dict.keys()
	ids.sort()
	for item_id in ids:
		var equip: EquipmentData = DataManager.equipment_data_dict[item_id]
		_log("%s | part=%s | set=%s | rarity=%s" % [item_id, equip.part, equip.set_id, equip.rarity])

func _list_affixes() -> void:
	if not is_instance_valid(DataManager):
		_log("DataManager unavailable.")
		return

	var ids: Array = DataManager.random_affixes_data.keys()
	ids.sort()
	for affix_id in ids:
		var t: Dictionary = DataManager.random_affixes_data[affix_id]
		_log("%s | stat=%s | range=[%s, %s]" % [affix_id, t.get("stat_type", ""), str(t.get("min_val", 0.0)), str(t.get("max_val", 0.0))])

func _give_equip(item_id: String) -> void:
	var player := _get_player()
	if player == null:
		return
	if not DataManager.equipment_data_dict.has(item_id):
		_log("Equipment not found: " + item_id)
		return
	var equip: EquipmentData = DataManager.equipment_data_dict[item_id]
	if not is_instance_valid(player.equipment_manager):
		_log("Player equipment manager unavailable.")
		return
	player.equipment_manager.equip_item(equip.part, item_id)
	_log("Equipped %s on %s." % [item_id, equip.part])

func _give_affix(affix_id: String) -> void:
	var player := _get_player()
	if player == null:
		return
	if not DataManager.random_affixes_data.has(affix_id):
		_log("Affix not found: " + affix_id)
		return

	var affix: Dictionary = DataManager.generate_random_affix(affix_id)
	if affix.is_empty():
		_log("Failed to generate affix: " + affix_id)
		return

	_apply_affix(player, affix_id, affix)

func _give_all_affixes() -> void:
	var ids: Array = DataManager.random_affixes_data.keys()
	ids.sort()
	for affix_id in ids:
		_give_affix(str(affix_id))
	_log("Applied all affixes once.")

func _apply_affix(player: Player, affix_id: String, affix: Dictionary) -> void:
	var stat_type := str(affix.get("stat_type", ""))
	var value := float(affix.get("value", 0.0))

	if stat_type == "attack":
		_cache_weapon_base_damage(player)
		_weapon_damage_bonus += value
		_apply_weapon_damage_bonus(player)
		_log("Affix %s applied: weapon damage +%s%%" % [affix_id, str(round(value * 100.0))])
		return

	var mapped_stat := _map_affix_stat(stat_type)
	if mapped_stat.is_empty():
		_log("Affix %s ignored. Unsupported stat '%s'." % [affix_id, stat_type])
		return

	if not is_instance_valid(player.modifier_system):
		_log("Player modifier system unavailable.")
		return

	if not player.modifier_system.base_stats.has(mapped_stat):
		_log("Affix %s ignored. Stat '%s' is not in ModifierSystem." % [affix_id, mapped_stat])
		return

	var mod_id := "cheat_affix_%d" % _next_affix_mod_index
	_next_affix_mod_index += 1
	player.modifier_system.add_modifier(mod_id, {
		"type": "stat",
		"stat": mapped_stat,
		"value": value
	})
	_affix_modifier_ids.append(mod_id)
	_log("Affix %s applied: %s %+0.3f" % [affix_id, mapped_stat, value])

func _map_affix_stat(stat_type: String) -> String:
	match stat_type:
		"move_speed":
			return "speed"
		_:
			return stat_type

func _clear_equip() -> void:
	var player := _get_player()
	if player == null:
		return
	if not is_instance_valid(player.equipment_manager):
		_log("Player equipment manager unavailable.")
		return

	player.equipment_manager.equip_item("head", "")
	player.equipment_manager.equip_item("body", "")
	player.equipment_manager.equip_item("foot", "")
	_log("All equipment slots cleared.")

func _clear_affixes() -> void:
	var player := _get_player()
	if player == null:
		return
	if not is_instance_valid(player.modifier_system):
		_log("Player modifier system unavailable.")
		return

	for mod_id in _affix_modifier_ids:
		player.modifier_system.remove_modifier(mod_id)
	_affix_modifier_ids.clear()

	_weapon_damage_bonus = 0.0
	_restore_weapon_damage(player)
	_log("All cheat affixes cleared.")

func _cache_weapon_base_damage(player: Player) -> void:
	if _weapon_base_damage_cache.is_empty() and player.weapon_manager.all_weapons is Dictionary:
		for weapon_id in player.weapon_manager.all_weapons.keys():
			var weapon = player.weapon_manager.all_weapons[weapon_id]
			if is_instance_valid(weapon):
				_weapon_base_damage_cache[str(weapon_id)] = float(weapon.damage)

func _apply_weapon_damage_bonus(player: Player) -> void:
	if player.weapon_manager.all_weapons is Dictionary:
		for weapon_id in player.weapon_manager.all_weapons.keys():
			var weapon = player.weapon_manager.all_weapons[weapon_id]
			if is_instance_valid(weapon):
				var key := str(weapon_id)
				var base := float(_weapon_base_damage_cache.get(key, weapon.damage))
				weapon.damage = base * (1.0 + _weapon_damage_bonus)

func _restore_weapon_damage(player: Player) -> void:
	if player.weapon_manager.all_weapons is Dictionary:
		for weapon_id in player.weapon_manager.all_weapons.keys():
			var weapon = player.weapon_manager.all_weapons[weapon_id]
			if is_instance_valid(weapon):
				var key := str(weapon_id)
				if _weapon_base_damage_cache.has(key):
					weapon.damage = float(_weapon_base_damage_cache[key])

func _get_player() -> Player:
	if not is_instance_valid(GameManager):
		_log("GameManager unavailable.")
		return null
	if not is_instance_valid(GameManager.player):
		_log("Player is not ready yet.")
		return null
	return GameManager.player

func _toggle_infinite_combo() -> void:
	_infinite_combo_enabled = not _infinite_combo_enabled
	
	var player := _get_player()
	if player == null:
		return
	
	if _infinite_combo_enabled:
		_apply_infinite_combo(player, true)
		if is_instance_valid(player.weapon_manager):
			player.weapon_manager.weapon_switched.connect(_on_weapon_switched_for_infinite_combo)
		_log("无限连携技已开启！切换武器即可触发连携技。")
	else:
		if is_instance_valid(player.weapon_manager):
			player.weapon_manager.weapon_switched.disconnect(_on_weapon_switched_for_infinite_combo)
		_apply_infinite_combo(player, false)
		_log("无限连携技已关闭。")

func _on_weapon_switched_for_infinite_combo(weapon_id: String) -> void:
	if _infinite_combo_enabled:
		var player := _get_player()
		if player != null:
			_apply_infinite_combo(player, true)

func _apply_infinite_combo(player: Player, enabled: bool) -> void:
	if not is_instance_valid(player.weapon_manager):
		_log("Player weapon manager unavailable.")
		return
	
	for weapon_id in player.weapon_manager.all_weapons:
		var weapon = player.weapon_manager.all_weapons[weapon_id]
		if is_instance_valid(weapon):
			if enabled:
				weapon.is_synergy_ready = true
				weapon.current_combo = weapon.max_combo
			else:
				weapon.is_synergy_ready = false
				weapon.current_combo = 0

func _log(msg: String) -> void:
	output_label.text += msg + "\n"
	output_label.scroll_to_line(max(output_label.get_line_count() - 1, 0))
