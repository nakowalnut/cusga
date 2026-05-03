extends Node
class_name PlayerWeaponVisualSystem

var player: Player
var weapon_sprite: Node2D
var prev_weapon_ani: AnimatedSprite2D
var new_weapon_ani: AnimatedSprite2D
var animation_player: AnimationPlayer
var animationsprite2d_node: AnimatedSprite2D
var current_weapon_tween: Tween

func _init(_player: Player, _weapon_sprite: Node2D, _prev_ani: AnimatedSprite2D, _new_ani: AnimatedSprite2D, _anim_player: AnimationPlayer, _anim2d: AnimatedSprite2D):
	player = _player
	weapon_sprite = _weapon_sprite
	prev_weapon_ani = _prev_ani
	new_weapon_ani = _new_ani
	animation_player = _anim_player
	animationsprite2d_node = _anim2d

func update_weapon_visual() -> void:
	if player.weapon_wheel.size() == 0: return
	
	var current_weapon_id = player.weapon_wheel[player.current_weapon_index]
	var weapon = player.all_weapons[current_weapon_id]
	player.current_weapon_node = weapon
	_clear_custom_weapon_shapes()
	
	if weapon_sprite:
		weapon_sprite.position = Vector2(22, -5)
		weapon_sprite.rotation = -1.16588
		weapon.update_weapon_visual(self)
		
	prev_weapon_ani.animation = animationsprite2d_node.animation
	new_weapon_ani.animation = current_weapon_id
	animation_player.play("switchweapon")
	prev_weapon_ani.frame = 0
	new_weapon_ani.frame = 0
	
	_ensure_child_plays_after_switch(current_weapon_id)
	
	match current_weapon_id:
		"sword":
			animationsprite2d_node.animation = "sword"
		"spear":
			pass
		"dagger":
			pass
		"bow":
			animationsprite2d_node.animation = "bow"
		"hammer":
			animationsprite2d_node.animation = "hammer"

func play_attack_visual(weapon_id: String) -> void:
	player._apply_attack_animation_speed()
	if weapon_id == "spear" and player.all_weapons.has("spear"):
		player.all_weapons["spear"].play_attack_visual(self, player._get_current_attack_total_duration())
	else:
		# 隐藏父节点 Weaponanim，避免与子节点重叠
		animationsprite2d_node.self_modulate.a = 0.0
		# 在活跃的子节点上播放武器攻击动画
		var active_child := _get_active_weapon_child()
		if weapon_id in ["sword", "bow", "hammer"]:
			active_child.animation = weapon_id
			active_child.play(weapon_id)
		# 注意：Attack1 动画的所有轨道已禁用，不重复播放以免中断 switchweapon

func _get_active_weapon_child() -> AnimatedSprite2D:
	if new_weapon_ani.modulate.a > prev_weapon_ani.modulate.a:
		return new_weapon_ani
	return prev_weapon_ani

func _ensure_child_plays_after_switch(weapon_id: String) -> void:
	if not animation_player.is_playing():
		new_weapon_ani.stop()
		new_weapon_ani.frame = 0
		return
	var callable := _on_switchweapon_finished.bind(weapon_id)
	for c in animation_player.animation_finished.get_connections():
		if c.callable == callable:
			return
	animation_player.animation_finished.connect(callable, CONNECT_ONE_SHOT)

func _on_switchweapon_finished(anim_name: String, weapon_id: String) -> void:
	if anim_name == "switchweapon":
		new_weapon_ani.stop()
		new_weapon_ani.frame = 0

func _clear_custom_weapon_shapes() -> void:
	if not weapon_sprite:
		return
	for child in weapon_sprite.get_children():
		if child.name.begins_with("CustomShape_"):
			child.free()

func play_charge_animation() -> void:
	if animation_player.is_playing() and animation_player.current_animation.begins_with("Attack"):
		animation_player.stop()
	
	if current_weapon_tween and current_weapon_tween.is_valid():
		current_weapon_tween.kill()
		
	current_weapon_tween = player.create_tween()
	var final_rotation = weapon_sprite.rotation - deg_to_rad(45.0)
	var final_position = weapon_sprite.position + Vector2(-10, -10)
	
	current_weapon_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	current_weapon_tween.tween_property(weapon_sprite, "rotation", final_rotation, 0.4)
	current_weapon_tween.parallel().tween_property(weapon_sprite, "position", final_position, 0.4)

func _create_tween() -> Tween:
	return player.create_tween()

func reset_weapon_visual() -> void:
	# 恢复父节点 AnimatedSprite 的可见性
	animationsprite2d_node.self_modulate.a = 1.0
	# 停止子节点的武器动画
	prev_weapon_ani.stop()
	new_weapon_ani.stop()
	prev_weapon_ani.frame = 0
	new_weapon_ani.frame = 0
