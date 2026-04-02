import sys
content = open(r'd:\godot\cusga\classes\Weapons\arrow_projectile.gd', encoding='utf-8').read()
old_code = 'func _on_area_entered(area: Area2D) -> void:'
new_code = '''func _on_area_entered(area: Area2D) -> void:
        if area is FieldOfView2D:
                return
        # 如果是 HitBox 或其他 Area2D，尝试寻找目标
        var target = area.get_parent()
        # 针对 Slime 等敌人结构的特殊处理：HitBox 在 WeaponHolder 下，需往上找两层
        if target and not (target.has_method(\"take_damage\") or target is CharacterBase):
            target = target.get_parent()
        _hit(target)

func _on_area_entered_old(area: Area2D) -> void:'''
content = content.replace(old_code, new_code)
open(r'd:\godot\cusga\classes\Weapons\arrow_projectile.gd', 'w', encoding='utf-8').write(content)
