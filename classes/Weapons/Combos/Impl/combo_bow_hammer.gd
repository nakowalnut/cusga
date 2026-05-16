extends ComboBase

func execute(player: CharacterBase, current_weapon: WeaponBase, next_weapon_name: String) -> void:
	print("【连携技触发】弓 ⇄ 锤子：获得强化，弓/锤下一次攻击变为爆炸箭，落点击飞敌人！")
	
	var bow_weapon: BowWeapon = null
	
	var all_weapons = player.weapon_manager.all_weapons
	if all_weapons is Dictionary:
		if all_weapons.has("bow"):
			bow_weapon = all_weapons["bow"] as BowWeapon
		
		var hammer_weapon: HammerWeapon = null
		if all_weapons.has("hammer"):
			hammer_weapon = all_weapons["hammer"] as HammerWeapon
			
		if is_instance_valid(bow_weapon):
			bow_weapon.grant_hammer_synergy(10.0)
		
		if is_instance_valid(hammer_weapon):
			hammer_weapon.grant_bow_synergy(10.0)

	finish_combo()
