import sys
content = open(r'd:\godot\cusga\classes\Weapons\arrow_projectile.gd', encoding='utf-8').read()
old_code = '''func _on_area_entered(area: Area2D) -> void:
        if area is FieldOfView2D:
                return
        # 濡傛灉鏁屼汉鐨勫彈鍑诲尯鍩熸槸 Area2D
        _hit(area.get_parent())'''
new_code = '''func _on_area_entered(area: Area2D) -> void:
        if area is FieldOfView2D:
                return
        # 如果是 HitBox 或其他 Area2D，尝试寻找目标
        var target = area.get_parent()
        # 如果父节点不是 CharacterBase，再往上一层找（适配不同的场景结构）
        if target and not target is CharacterBase:
            target = target.get_parent()
        _hit(target)'''
content = content.replace(old_code, new_code)
open(r'd:\godot\cusga\classes\Weapons\arrow_projectile.gd', 'w', encoding='utf-8').write(content)
