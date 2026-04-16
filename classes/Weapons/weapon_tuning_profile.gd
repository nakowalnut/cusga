extends Resource
class_name WeaponTuningProfile

@export var weapon_id: String = ""

@export_group("Core")
@export var damage: float = -1.0
@export var crit_rate: float = -1.0 # 暴击率调优
@export var crit_damage_multiplier: float = -1.0 # 暴击伤害倍率调优
@export var attack_speed_multiplier: float = -1.0
@export var movement_speed_multiplier: float = -1.0
@export var max_combo: int = -1

@export_group("Attack Timing")
@export var attack_wind_up: float = -1.0
@export var attack_active: float = -1.0
@export var attack_recovery: float = -1.0
@export var attack_cooldown: float = -1.0

func apply_to(weapon: WeaponBase) -> void:
	if not is_instance_valid(weapon):
		return

	if damage >= 0.0:
		weapon.damage = damage
	if crit_rate >= 0.0:
		weapon.crit_rate = crit_rate
	if crit_damage_multiplier >= 0.0:
		weapon.crit_damage_multiplier = crit_damage_multiplier
	if attack_speed_multiplier >= 0.0:
		weapon.attack_speed_multiplier = attack_speed_multiplier
	if movement_speed_multiplier >= 0.0:
		weapon.movement_speed_multiplier = movement_speed_multiplier
	if max_combo >= 0:
		weapon.max_combo = max_combo
	if attack_wind_up >= 0.0:
		weapon.attack_wind_up = attack_wind_up
	if attack_active >= 0.0:
		weapon.attack_active = attack_active
	if attack_recovery >= 0.0:
		weapon.attack_recovery = attack_recovery
	if attack_cooldown >= 0.0:
		weapon.attack_cooldown = attack_cooldown
