import sys
import re
content = open(r'd:\godot\cusga\classes\Weapons\arrow_projectile.gd', encoding='utf-8').read()
# Clean up the messed up area_entered functions
pattern = r'func _on_area_entered\(area: Area2D\) -> void:.*?func _hit'
new_func = '''func _on_area_entered(area: Area2D) -> void:
        if area is FieldOfView2D:
                return
        # 检测是否命中了敌人的 HitBox (Area2D)
        # 很多敌人的结构是 Character (Node) -> HitBox (Area2D)，所以找 parent
        var target = area.get_parent()
        
        # 针对 Slime 这种 HitBox 被放在孙子节点的特殊结构 (Character -> WeaponHolder -> HitBox)
        # 如果 parent 没有受击方法，则继续往上找一层
        if target and not target.has_method(\"take_damage\"):
            target = target.get_parent()
            
        _hit(target)

func _hit'''
content = re.sub(pattern, new_func, content, flags=re.DOTALL)
open(r'd:\godot\cusga\classes\Weapons\arrow_projectile.gd', 'w', encoding='utf-8').write(content)
