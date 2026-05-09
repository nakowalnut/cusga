extends ComboBase

func execute(player: CharacterBase, current_weapon: WeaponBase, next_weapon_name: String) -> void:
	print("【连携技触发】短剑 ⇄ 锤子：获得10秒强化，短剑突刺击飞且锤子可位移突进！")

	var dagger_weapon: DaggerWeapon = null
	if current_weapon is DaggerWeapon:
		dagger_weapon = current_weapon as DaggerWeapon
	else:
		var all_weapons = player.weapon_manager.all_weapons
		if all_weapons is Dictionary and all_weapons.has("dagger"):
			var dagger_candidate = all_weapons["dagger"]
			if dagger_candidate is DaggerWeapon:
				dagger_weapon = dagger_candidate as DaggerWeapon

	if is_instance_valid(dagger_weapon):
		dagger_weapon.grant_hammer_synergy(10.0)
	else:
		print("【短剑 ⇄ 锤子】未找到短剑实例，无法施加强化")

	var hammer_weapon: HammerWeapon = null
	var all_weapons = player.weapon_manager.all_weapons
	if all_weapons is Dictionary and all_weapons.has("hammer"):
		var hammer_candidate = all_weapons["hammer"]
		if hammer_candidate is HammerWeapon:
			hammer_weapon = hammer_candidate as HammerWeapon

	if is_instance_valid(hammer_weapon):
		hammer_weapon.grant_dagger_synergy(10.0)
	else:
		print("【短剑 ⇄ 锤子】未找到锤子实例，无法施加位移强化")

	finish_combo()
