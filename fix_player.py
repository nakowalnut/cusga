def fix(path):
    with open(path, 'r', encoding='utf-8') as f:
        t = f.read()

    old = '''prev_weapon_ani.animation = animationsprite2d_node.animation\n\tnew_weapon_ani.animation = current_weapon_id\n\tanimation_player.play("switchweapon")\n\tprev_weapon_ani.frame = 0\n\tnew_weapon_ani.frame = 0\n\t# switchweapon 动画轨道的连续更新会锁死子节点帧，动画结束后手动恢复播放\n\t_ensure_child_plays_after_switch(current_weapon_id)\n\t#武器切换（视觉）\n\tmatch current_weapon_id:\n\t\t"sword":\n\t\t\tanimationsprite2d_node.animation = "sword"\n\t\t"spear":\n\t\t\tpass\n\t\t"dagger":\n\t\t\tpass\n\t\t"bow":\n\t\t\tanimationsprite2d_node.animation = "bow"\n\t\t"hammer":\n\t\t\tanimationsprite2d_node.animation = "hammer"'''
    new = '''prev_weapon_ani.animation = animationsprite2d_node.animation\n\tnew_weapon_ani.animation = current_weapon_id\n\tprev_weapon_ani.visible = true\n\tnew_weapon_ani.visible = true\n\tanimation_player.play("switchweapon")\n\tprev_weapon_ani.frame = 0\n\tnew_weapon_ani.frame = 0\n\t_ensure_parent_plays_after_switch(current_weapon_id)'''
    t = t.replace(old, new)

    old2 = '''func _ensure_child_plays_after_switch(weapon_id: String) -> void:\n\tif not animation_player.is_playing() or animation_player.current_animation != "switchweapon":\n\t\tnew_weapon_ani.play(weapon_id)\n\t\treturn\n\t# 断开之前的连接，防止重复绑定\n\tif animation_player.animation_finished.is_connected(_on_switchweapon_finished):\n\t\tanimation_player.animation_finished.disconnect(_on_switchweapon_finished)\n\tanimation_player.animation_finished.connect(_on_switchweapon_finished.bind(weapon_id), CONNECT_ONE_SHOT)\n\nfunc _on_switchweapon_finished(anim_name: String, weapon_id: String) -> void:\n\tif anim_name == "switchweapon":\n\t\tnew_weapon_ani.play(weapon_id)'''
    new2 = '''func _ensure_parent_plays_after_switch(weapon_id: String) -> void:\n\tif not animation_player.is_playing() or animation_player.current_animation != "switchweapon":\n\t\t_finish_switch_to_parent(weapon_id)\n\t\treturn\n\tif animation_player.animation_finished.is_connected(_on_switchweapon_finished):\n\t\tanimation_player.animation_finished.disconnect(_on_switchweapon_finished)\n\tanimation_player.animation_finished.connect(_on_switchweapon_finished.bind(weapon_id), CONNECT_ONE_SHOT)\n\nfunc _on_switchweapon_finished(anim_name: String, weapon_id: String) -> void:\n\tif anim_name == "switchweapon":\n\t\t_finish_switch_to_parent(weapon_id)\n\nfunc _finish_switch_to_parent(weapon_id: String) -> void:\n\tprev_weapon_ani.visible = false\n\tnew_weapon_ani.visible = false\n\tanimationsprite2d_node.self_modulate = Color(1, 1, 1, 1)\n\tif weapon_id in ["sword", "bow", "hammer", "spear", "dagger"]:\n\t\tanimationsprite2d_node.animation = weapon_id\n\t\tanimationsprite2d_node.play(weapon_id)'''
    t = t.replace(old2, new2)

    with open(path, 'w', encoding='utf-8') as f:\n        f.write(t)

fix(r'd:\\godot\\cusga\\classes\\Character\\player.gd')
