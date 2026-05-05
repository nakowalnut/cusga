class_name WeaponManager extends Node

signal weapon_switched(weapon_id: String)
signal attack_requested(weapon_id: String, is_charged: bool, bypass_charge: bool)
signal hit_registered(target: Node)

@export var player: CharacterBase
@export var weapon_holder: Node2D
@export var weapon_tuning_profiles: Array[WeaponTuningProfile] = []
@export var weapon_sprite: Node2D
@export var weapon_hitbox: Area2D
@export var animation_player: AnimationPlayer
@export var animationsprite2d_node: AnimatedSprite2D
@export var prev_weapon_ani: AnimatedSprite2D
@export var new_weapon_ani: AnimatedSprite2D

var all_weapons: Dictionary = {}
var weapon_wheel: Array[String] = ["sword", "spear", "dagger", "bow", "hammer"]
var current_weapon_index: int = 0
var current_weapon_node = null
var current_weapon_tween: Tween

func _ready() -> void:
	# 延迟初始化等待父节点就绪
	pass

func init_weapons() -> void:
	# 迁移自原 player.gd 的 _init_weapons
	all_weapons["sword"] = SwordWeapon.new()
	all_weapons["spear"] = SpearWeapon.new()
	all_weapons["dagger"] = DaggerWeapon.new()
	all_weapons["bow"] = BowWeapon.new()
	all_weapons["hammer"] = HammerWeapon.new()

	for key in all_weapons:
		var wp = all_weapons[key]
		_apply_weapon_tuning(key, wp)
		wp.weapon_owner = player
		if weapon_holder:
			weapon_holder.add_child(wp)
			
	if all_weapons.size() > 0:
		switch_to_weapon(weapon_wheel[0])

func _apply_weapon_tuning(weapon_id: String, weapon: Node) -> void:
	if not is_instance_valid(weapon): return
	for profile in weapon_tuning_profiles:
		if not is_instance_valid(profile): continue
		if profile.weapon_id == weapon_id:
			profile.apply_to(weapon)
			return

func switch_to_weapon(weapon_id: String) -> void:
	if not all_weapons.has(weapon_id): return
	current_weapon_node = all_weapons[weapon_id]
	weapon_switched.emit(weapon_id)

func switch_and_attack() -> void:
	# 迁移 _switch_and_attack() 逻辑
	current_weapon_index = (current_weapon_index + 1) % weapon_wheel.size()
	var next_wep = weapon_wheel[current_weapon_index]
	switch_to_weapon(next_wep)
	attack_requested.emit(next_wep, false, false)

func process_hit(target: Node) -> void:
	hit_registered.emit(target)

## 攻击键按下 — 转发给当前武器
func on_attack_pressed() -> void:
	if is_instance_valid(current_weapon_node) and current_weapon_node.has_method("on_attack_pressed"):
		current_weapon_node.on_attack_pressed()

## 攻击键松开 — 转发给当前武器
func on_attack_released() -> void:
	if is_instance_valid(current_weapon_node) and current_weapon_node.has_method("on_attack_released"):
		current_weapon_node.on_attack_released()

## 当前武器是否为蓄力类型
func is_charge_weapon() -> bool:
	if is_instance_valid(current_weapon_node):
		return current_weapon_node.get("is_charge_weapon") == true
	return false

## 获取当前武器 ID（快捷方法）
func get_current_weapon_id() -> String:
	if weapon_wheel.size() > 0:
		return weapon_wheel[current_weapon_index]
	return ""

## 切枪并尝试连携（原 _switch_and_attack 逻辑）
func switch_and_combo(new_index: int) -> Dictionary:
	
	#返回一个字典，供 Player 决定是否进入攻击状态：
	#{ "combo_triggered": bool, "prev_weapon": String, "new_weapon": String }
   
	if new_index < 0 or new_index >= weapon_wheel.size():
		return {"combo_triggered": false, "prev_weapon": "", "new_weapon": ""}

	var prev_weapon_id = weapon_wheel[current_weapon_index]
	var new_weapon_id = weapon_wheel[new_index]

	var combo_triggered := false
	if is_instance_valid(current_weapon_node) and current_weapon_node.has_method("on_switch_out"):
		combo_triggered = current_weapon_node.on_switch_out(new_weapon_id)

	current_weapon_index = new_index
	switch_to_weapon(new_weapon_id)  # 会发出 weapon_switched 信号 → Player 更新视觉

	return {
		"combo_triggered": combo_triggered,
		"prev_weapon": prev_weapon_id,
		"new_weapon": new_weapon_id
	}

func get_attack_total_duration() -> float:
	if is_instance_valid(current_weapon_node):
		return max(current_weapon_node.attack_wind_up + current_weapon_node.attack_active + current_weapon_node.attack_recovery, 0.01)
	return 0.3

func execute_attack(mouse_pos: Vector2) -> void:
	if is_instance_valid(current_weapon_node):
		current_weapon_node.attack(mouse_pos)

func update_weapon_visual() -> void:
	if weapon_wheel.size() == 0: return
	
	var current_weapon_id = weapon_wheel[current_weapon_index]
	var weapon = all_weapons[current_weapon_id]
	current_weapon_node = weapon
	var hammer = all_weapons.get("hammer")
	if is_instance_valid(hammer) and hammer.has_method("_clear_custom_weapon_shapes"):
		hammer._clear_custom_weapon_shapes()
	
	# 重置被Tween影响的位置和旋转，防止切枪时由于动画残留导致表现错乱
	if weapon_sprite:
		weapon_sprite.position = Vector2(22, -5)
		weapon_sprite.rotation = -1.16588
	
	prev_weapon_ani.animation = animationsprite2d_node.animation
	new_weapon_ani.animation = current_weapon_id
	prev_weapon_ani.visible = true
	new_weapon_ani.visible = true
	animation_player.play("switchweapon")
	prev_weapon_ani.frame = 0
	new_weapon_ani.frame = 0
	# switchweapon 动画轨道的连续更新会锁死子节点帧，动画结束后手动恢复播放
	ensure_parent_plays_after_switch(current_weapon_id)
	
	# 武器切换（视觉）设置
	if current_weapon_id in ["sword", "bow", "hammer", "spear", "dagger"]:
		animationsprite2d_node.animation = current_weapon_id

func apply_weapon_transforms(weapon_id: String, weapon_color: Color) -> void:
	# 视觉与物理同步变化：CurrentWeapon 是 HitBox 的父节点，缩放会同时影响碰撞判定
	weapon_sprite.scale = Vector2(1.0, 1.125)
	
	match weapon_id:
		"dagger":
			# 短剑：更短
			weapon_sprite.scale = Vector2(0.5, 1.125)
		"spear":
			# 矛：更细、更长
			weapon_sprite.scale = Vector2(1.6, 0.55)
			# 矛头方向与鼠标一致：本地旋转归零，由 weapon_holder.look_at 接管朝向
			weapon_sprite.rotation = 0.0
		"hammer":
			weapon_sprite.scale = Vector2(0.9, 1.0)
			var hammer = all_weapons.get("hammer")
			if is_instance_valid(hammer) and hammer.has_method("build_hammer_head"):
				hammer.build_hammer_head(weapon_color)
	
	# 如果有攻击判定，可以在这里调整碰撞盒大小模拟不同武器长度
	# attack_collider.shape.extents = Vector2(weapon.attack_range, 10)

func set_weapon_hitbox_active(active: bool) -> void:
	if weapon_hitbox:
		weapon_hitbox.monitoring = active

func play_charge_animation() -> void:
	if animation_player.is_playing() and animation_player.current_animation.begins_with("Attack"):
		animation_player.stop()
	
	if current_weapon_tween and current_weapon_tween.is_valid():
		current_weapon_tween.kill()
		
	current_weapon_tween = create_tween()
	# 蓄力时将武器向后方高高举起 (旋转角度后仰，并稍微收回)
	var final_rotation = weapon_sprite.rotation - deg_to_rad(45.0)
	var final_position = weapon_sprite.position + Vector2(-10, -10)
	
	current_weapon_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	current_weapon_tween.tween_property(weapon_sprite, "rotation", final_rotation, 0.4)
	current_weapon_tween.parallel().tween_property(weapon_sprite, "position", final_position, 0.4)

func spear_poke_animation(total_duration: float) -> void:
	# 停止动画播放器，以免与代码Tween冲突
	if animation_player.is_playing() and animation_player.current_animation.begins_with("Attack"):
		animation_player.stop()

	if current_weapon_tween and current_weapon_tween.is_valid():
		current_weapon_tween.kill()
		
	var base_pos = Vector2(22, -5)
	weapon_sprite.position = base_pos
	# 矛的默认角度由 weapon_holder.look_at 驱动，这里保持本地零旋转
	weapon_sprite.rotation = 0.0
	
	# 向本地 X 轴直接延伸进行“戳”的动作
	# 父节点 weapon_holder 已经 look_at 指向了鼠标，因此增加 X 轴位置即为向前突刺
	var target_pos = base_pos + Vector2(60, 0)
	var poke_time = max(total_duration * 0.35, 0.04)
	var back_time = max(total_duration * 0.65, 0.06)
	
	current_weapon_tween = create_tween()
	# 快速突刺
	current_weapon_tween.tween_property(weapon_sprite, "position", target_pos, poke_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# 慢速收回
	current_weapon_tween.tween_property(weapon_sprite, "position", base_pos, back_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func rotate_weapon_to_mouse(mouse_pos: Vector2) -> void:
	if weapon_holder:
		weapon_holder.look_at(mouse_pos)
		# 当鼠标在左边时翻转Y轴，避免武器倒挂
		var is_left = mouse_pos.x < weapon_holder.global_position.x
		weapon_holder.scale.y = -1.0 if is_left else 1.0

func ensure_parent_plays_after_switch(weapon_id: String) -> void:
	if not animation_player.is_playing() or animation_player.current_animation != "switchweapon":
		finish_switch_to_parent(weapon_id)
		return
	# 断开之前的连接，防止重复绑定
	if animation_player.animation_finished.is_connected(_on_switchweapon_finished):
		animation_player.animation_finished.disconnect(_on_switchweapon_finished)
	animation_player.animation_finished.connect(_on_switchweapon_finished.bind(weapon_id), CONNECT_ONE_SHOT)

func _on_switchweapon_finished(anim_name: String, weapon_id: String) -> void:
	if anim_name == "switchweapon":
		finish_switch_to_parent(weapon_id)

func finish_switch_to_parent(weapon_id: String) -> void:
	prev_weapon_ani.visible = false
	new_weapon_ani.visible = false
	animationsprite2d_node.self_modulate = Color(1, 1, 1, 1)
	if weapon_id in ["sword", "bow", "hammer", "spear", "dagger"]:
		animationsprite2d_node.animation = weapon_id
		animationsprite2d_node.play(weapon_id)
