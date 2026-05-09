import re

path = r'd:\godot\cusga\classes\Character\player.gd'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

pattern1 = r'\tprev_weapon_ani\.animation = animationsprite2d_node\.animation\n\tnew_weapon_ani\.animation = current_weapon_id\n\tanimation_player\.play\("switchweapon"\)\n\tprev_weapon_ani\.frame = 0\n\tnew_weapon_ani\.frame = 0\n\t#.*?\n\t_ensure_child_plays_after_switch\(current_weapon_id\)\n[\s\S]*?animationsprite2d_node\.animation = "hammer"'

repl1 = '''\tprev_weapon_ani.animation = animationsprite2d_node.animation\n\tnew_weapon_ani.animation = current_weapon_id\n\tprev_weapon_ani.visible = true\n\tnew_weapon_ani.visible = true\n\tanimation_player.play("switchweapon")\n\tprev_weapon_ani.frame = 0\n\tnew_weapon_ani.frame = 0\n\t_ensure_parent_plays_after_switch(current_weapon_id)\n\n\tif current_weapon_id in ["sword", "bow", "hammer", "spear", "dagger"]:\n\t\tanimationsprite2d_node.animation = current_weapon_id'''

content = re.sub(pattern1, repl1, content, flags=re.MULTILINE)

pattern2 = r'func _ensure_child_plays_after_switch.*?func _on_switchweapon_finished.*?new_weapon_ani\.play\(weapon_id\)'

repl2 = '''func _ensure_parent_plays_after_switch(weapon_id: String) -> void:\n\tif not animation_player.is_playing() or animation_player.current_animation != "switchweapon":\n\t\t_finish_switch_to_parent(weapon_id)\n\t\treturn\n\tif animation_player.animation_finished.is_connected(_on_switchweapon_finished):\n\t\tanimation_player.animation_finished.disconnect(_on_switchweapon_finished)\n\tanimation_player.animation_finished.connect(_on_switchweapon_finished.bind(weapon_id), CONNECT_ONE_SHOT)\n\nfunc _on_switchweapon_finished(anim_name: String, weapon_id: String) -> void:\n\tif anim_name == "switchweapon":\n\t\t_finish_switch_to_parent(weapon_id)\n\nfunc _finish_switch_to_parent(weapon_id: String) -> void:\n\tprev_weapon_ani.visible = false\n\tnew_weapon_ani.visible = false\n\tanimationsprite2d_node.self_modulate = Color(1, 1, 1, 1)\n\tif weapon_id in ["sword", "bow", "hammer", "spear", "dagger"]:\n\t\tanimationsprite2d_node.animation = weapon_id\n\t\tanimationsprite2d_node.play(weapon_id)'''

content = re.sub(pattern2, repl2, content, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
