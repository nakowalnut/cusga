import sys
content = open(r'd:\godot\cusga\classes\Weapons\arrow_projectile.gd', encoding='utf-8').read()
content = content.replace('if target and target.has_method(\"take_damage\") and not target.get(\"is_dead\"):', 'if target and target.has_method(\"take_damage\") and not target.get(\"is_dead\"):\n\t\tif is_instance_valid(weapon_owner) and target == weapon_owner.weapon_owner:\n\t\t\treturn\n')
open(r'd:\godot\cusga\classes\Weapons\arrow_projectile.gd', 'w', encoding='utf-8').write(content)
