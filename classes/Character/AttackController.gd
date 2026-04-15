extends Node
class_name AttackController

signal attack_started
signal wind_up_started(duration: float)
signal active_started(duration: float)
signal recovery_started(duration: float)
signal attack_ended
signal cooldown_started(duration: float)
signal cooldown_ended

@export var default_wind_up: float = 0.05
@export var default_active: float = 0.12
@export var default_recovery: float = 0.18
@export var default_cooldown: float = 0.08

enum AttackPhase {
	IDLE,
	WIND_UP,
	ACTIVE,
	RECOVERY
}

var _phase: AttackPhase = AttackPhase.IDLE
var _phase_timer: Timer
var _cooldown_timer: Timer

var _wind_up_time: float = 0.0
var _active_time: float = 0.0
var _recovery_time: float = 0.0
var _cooldown_time: float = 0.0

func _ready() -> void:
	_phase_timer = Timer.new()
	_phase_timer.one_shot = true
	_phase_timer.timeout.connect(_on_phase_timeout)
	add_child(_phase_timer)

	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	_cooldown_timer.timeout.connect(_on_cooldown_timeout)
	add_child(_cooldown_timer)

func configure_attack_timing(wind_up: float, active: float, recovery: float, cooldown: float) -> void:
	_wind_up_time = max(wind_up, 0.0)
	_active_time = max(active, 0.0)
	_recovery_time = max(recovery, 0.0)
	_cooldown_time = max(cooldown, 0.0)

func configure_from_weapon(weapon: WeaponBase) -> void:
	if not is_instance_valid(weapon):
		configure_attack_timing(default_wind_up, default_active, default_recovery, default_cooldown)
		return

	configure_attack_timing(
		weapon.attack_wind_up,
		weapon.attack_active,
		weapon.attack_recovery,
		weapon.attack_cooldown
	)

func can_start_attack() -> bool:
	return _phase == AttackPhase.IDLE and not is_on_cooldown()

func start_attack() -> bool:
	if not can_start_attack():
		return false

	emit_signal("attack_started")
	if _wind_up_time > 0.0:
		_enter_phase(AttackPhase.WIND_UP, _wind_up_time)
	else:
		_enter_active_phase()
	return true

func cancel_attack(start_cooldown: bool = false) -> void:
	if _phase == AttackPhase.IDLE:
		return
	_phase_timer.stop()
	_phase = AttackPhase.IDLE
	emit_signal("attack_ended")
	if start_cooldown:
		_start_cooldown()

func is_busy() -> bool:
	return _phase != AttackPhase.IDLE

func is_on_cooldown() -> bool:
	return _cooldown_timer != null and not _cooldown_timer.is_stopped()

func get_phase_name() -> String:
	match _phase:
		AttackPhase.WIND_UP:
			return "wind_up"
		AttackPhase.ACTIVE:
			return "active"
		AttackPhase.RECOVERY:
			return "recovery"
		_:
			return "idle"

func _enter_phase(phase: AttackPhase, duration: float) -> void:
	_phase = phase
	match phase:
		AttackPhase.WIND_UP:
			emit_signal("wind_up_started", duration)
		AttackPhase.ACTIVE:
			emit_signal("active_started", duration)
		AttackPhase.RECOVERY:
			emit_signal("recovery_started", duration)
		_:
			pass

	if duration <= 0.0:
		_on_phase_timeout()
		return

	_phase_timer.start(duration)

func _enter_active_phase() -> void:
	if _active_time > 0.0:
		_enter_phase(AttackPhase.ACTIVE, _active_time)
	else:
		_enter_recovery_phase()

func _enter_recovery_phase() -> void:
	if _recovery_time > 0.0:
		_enter_phase(AttackPhase.RECOVERY, _recovery_time)
	else:
		_finish_attack()

func _finish_attack() -> void:
	_phase = AttackPhase.IDLE
	emit_signal("attack_ended")
	_start_cooldown()

func _start_cooldown() -> void:
	if _cooldown_time <= 0.0:
		return
	emit_signal("cooldown_started", _cooldown_time)
	_cooldown_timer.start(_cooldown_time)

func _on_phase_timeout() -> void:
	match _phase:
		AttackPhase.WIND_UP:
			_enter_active_phase()
		AttackPhase.ACTIVE:
			_enter_recovery_phase()
		AttackPhase.RECOVERY:
			_finish_attack()
		_:
			pass

func _on_cooldown_timeout() -> void:
	emit_signal("cooldown_ended")
