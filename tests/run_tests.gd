extends SceneTree

var failures := 0
var assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_card_cost_and_validation()
	_test_energy_regeneration()
	_test_spell_damage()
	_test_deck_cycle()
	_test_frost_slow()
	_test_crown_scoring()
	_test_overtime_rules()
	_test_tutorial_flow()
	_test_forfeit()
	_test_profile_store()
	_test_progression()
	_test_battle_intro()
	_test_units_fight()
	_test_tower_defends_lane()
	_test_bot_matches_finish()
	print("Battle tests: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)


func _test_card_cost_and_validation() -> void:
	var simulation := BattleSim.new(10)
	_expect(simulation.play_card(BattleSim.PLAYER, "guardian", 0), "a valid card can be played")
	_expect(is_equal_approx(simulation.energy[BattleSim.PLAYER], 2.0), "playing a card spends energy")
	_expect(not simulation.play_card(BattleSim.PLAYER, "colossus", 0), "a card cannot be played without energy")
	_expect(not simulation.play_card(BattleSim.PLAYER, "unknown", 0), "an unknown card is rejected")
	_expect(not simulation.play_card(BattleSim.PLAYER, "guardian", 3), "an invalid lane is rejected")


func _test_energy_regeneration() -> void:
	var simulation := BattleSim.new(11)
	simulation.energy[BattleSim.PLAYER] = 0.0
	for index in range(20):
		simulation.step(0.1)
	_expect(absf(simulation.energy[BattleSim.PLAYER] - 2.0) < 0.01, "energy regenerates at one point per second")


func _test_spell_damage() -> void:
	var simulation := BattleSim.new(12)
	_expect(simulation.play_card(BattleSim.ENEMY, "guardian", 1), "enemy unit spawns")
	var initial_hp: float = simulation.units[0].hp
	_expect(simulation.play_card(BattleSim.PLAYER, "fireball", 1), "spell can be cast")
	_expect(simulation.units[0].hp < initial_hp, "spell damages units in its lane")
	_expect(simulation.towers[BattleSim.ENEMY].lanes[1] < 1200.0, "spell damages the lane tower")


func _test_deck_cycle() -> void:
	var simulation := BattleSim.new(15)
	_expect(simulation.get_hand(BattleSim.PLAYER) == ["guardian", "ranger", "colossus", "fireball"], "battle starts with four cards")
	_expect(simulation.get_next_card(BattleSim.PLAYER) == "duelist", "next card is exposed")
	_expect(not simulation.play_card(BattleSim.PLAYER, "duelist", 0), "a card outside the hand is rejected")
	_expect(simulation.play_card(BattleSim.PLAYER, "guardian", 0), "a hand card can be played")
	_expect("duelist" in simulation.get_hand(BattleSim.PLAYER), "playing draws the next card")
	_expect(simulation.get_next_card(BattleSim.PLAYER) == "alchemist", "draw queue advances")


func _test_frost_slow() -> void:
	var simulation := BattleSim.new(16)
	simulation.energy = [100.0, 10.0]
	simulation.play_card(BattleSim.ENEMY, "guardian", 0)
	simulation.play_card(BattleSim.PLAYER, "guardian", 1)
	simulation.play_card(BattleSim.PLAYER, "ranger", 1)
	simulation.play_card(BattleSim.PLAYER, "colossus", 1)
	simulation.play_card(BattleSim.PLAYER, "fireball", 1)
	_expect("frost" in simulation.get_hand(BattleSim.PLAYER), "frost rotates into the hand")
	var initial_hp: float = simulation.units[0].hp
	_expect(simulation.play_card(BattleSim.PLAYER, "frost", 0), "frost can be cast from the hand")
	_expect(simulation.units[0].hp < initial_hp, "frost damages its lane")
	_expect(simulation.units[0].slow_timer > 0.0, "frost slows affected units")


func _test_crown_scoring() -> void:
	var simulation := BattleSim.new(17)
	simulation.towers[BattleSim.ENEMY].lanes[0] = 20.0
	simulation._damage_objective(BattleSim.ENEMY, 0, 25.0)
	_expect(simulation.crowns[BattleSim.PLAYER] == 1, "destroying a lane tower awards one crown")
	simulation._damage_objective(BattleSim.ENEMY, 0, 25.0)
	_expect(simulation.crowns[BattleSim.PLAYER] == 1, "a destroyed tower cannot award another crown")
	simulation.towers[BattleSim.ENEMY].core = 10.0
	simulation._damage_objective(BattleSim.ENEMY, 0, 20.0)
	_expect(simulation.crowns[BattleSim.PLAYER] == 3, "destroying the core sets a three-crown victory")
	simulation.step(0.1)
	_expect(simulation.finished and simulation.winner == BattleSim.PLAYER, "core destruction ends the match")


func _test_overtime_rules() -> void:
	var simulation := BattleSim.new(18)
	simulation.energy = [0.0, 0.0]
	simulation.time_left = 0.05
	simulation.step(0.1)
	_expect(simulation.overtime, "a tied regulation enters overtime")
	_expect(not simulation.finished, "overtime keeps the match active")
	_expect(is_equal_approx(simulation.time_left, BattleSim.OVERTIME_DURATION), "overtime receives its full duration")
	for index in range(10):
		simulation.step(0.1)
	_expect(absf(simulation.energy[BattleSim.PLAYER] - 2.1) < 0.02, "energy regenerates twice as fast in overtime")
	simulation.towers[BattleSim.ENEMY].lanes[0] = 1.0
	simulation._damage_objective(BattleSim.ENEMY, 0, 5.0)
	_expect(simulation.finished and simulation.winner == BattleSim.PLAYER, "the next crown wins overtime")

	var crown_lead := BattleSim.new(19)
	crown_lead.crowns = [1, 0]
	crown_lead.time_left = 0.05
	crown_lead.step(0.1)
	_expect(crown_lead.finished and crown_lead.winner == BattleSim.PLAYER, "a crown lead wins at regulation time")

	var tiebreak := BattleSim.new(20)
	tiebreak.overtime = true
	tiebreak.time_left = 0.05
	tiebreak.towers[BattleSim.ENEMY].lanes[0] = 1000.0
	tiebreak.step(0.1)
	_expect(tiebreak.finished and tiebreak.winner == BattleSim.PLAYER, "remaining health breaks an overtime tie")

	var draw := BattleSim.new(21)
	draw.overtime = true
	draw.time_left = 0.05
	draw.step(0.1)
	_expect(draw.finished and draw.winner == -1, "equal health after overtime produces a draw")


func _test_tutorial_flow() -> void:
	var tutorial := BattleTutorial.new()
	_expect(not tutorial.can_select("ranger"), "tutorial rejects the wrong first card")
	_expect(tutorial.select_card("guardian"), "tutorial accepts Guardian first")
	_expect(not tutorial.can_deploy("guardian", 1), "tutorial rejects the wrong first lane")
	_expect(tutorial.deploy_card("guardian", 0), "tutorial accepts Guardian on the left")
	_expect(tutorial.select_card("ranger"), "tutorial asks for Ranger second")
	_expect(not tutorial.deploy_card("ranger", 0), "tutorial rejects Ranger on the left")
	_expect(tutorial.deploy_card("ranger", 1), "tutorial accepts Ranger on the right")
	_expect(tutorial.is_complete(), "tutorial completes after four guided actions")


func _test_forfeit() -> void:
	var simulation := BattleSim.new(22)
	_expect(not simulation.forfeit(3), "an invalid side cannot forfeit")
	_expect(simulation.forfeit(BattleSim.PLAYER), "the player can forfeit an active match")
	_expect(simulation.finished and simulation.winner == BattleSim.ENEMY, "forfeit awards the match to the opponent")
	_expect(not simulation.forfeit(BattleSim.ENEMY), "a finished match cannot be forfeited again")


func _test_profile_store() -> void:
	var path := "user://battle_profile_store_test.json"
	for suffix in ["", ".tmp", ".bak"]:
		var absolute := ProjectSettings.globalize_path(path + suffix)
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(absolute)
	var saved := {"version": 3, "wins": 4, "sound_enabled": false}
	_expect(BattleProfileStore.save_profile(path, saved), "profile store writes transactionally")
	_expect(BattleProfileStore.load_profile(path).wins == 4, "profile store reloads saved data")
	saved.wins = 5
	_expect(BattleProfileStore.save_profile(path, saved), "profile store replaces an existing save")
	_expect(BattleProfileStore.load_profile(path).wins == 5 and not FileAccess.file_exists(path + ".bak"), "successful replacement cleans its backup")
	var backup := FileAccess.open(path + ".bak", FileAccess.WRITE)
	backup.store_string(JSON.stringify({"version": 3, "wins": 7}))
	backup.close()
	var corrupted := FileAccess.open(path, FileAccess.WRITE)
	corrupted.store_string("{truncated")
	corrupted.close()
	_expect(BattleProfileStore.load_profile(path).wins == 7, "profile store recovers from a valid backup")
	for suffix in ["", ".tmp", ".bak"]:
		var absolute := ProjectSettings.globalize_path(path + suffix)
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(absolute)


func _test_progression() -> void:
	var legacy := {"wins": 3, "losses": 2}
	var profile := BattleProgression.normalize(legacy)
	_expect(profile.wins == 3 and profile.level == 1, "legacy profiles migrate with defaults")
	_expect(profile.sound_enabled and profile.difficulty == 1, "legacy profiles receive default settings")
	var settings := BattleProgression.normalize({"sound_enabled": false, "difficulty": 9})
	_expect(not settings.sound_enabled and settings.difficulty == 2, "local settings are normalized safely")
	var tutorial_reward := BattleProgression.complete_tutorial(profile)
	_expect(tutorial_reward.coins == 15 and profile.tutorial_completed, "tutorial grants its first completion reward")
	_expect(BattleProgression.complete_tutorial(profile).coins == 0, "tutorial reward cannot be claimed twice")
	var reward := BattleProgression.apply_match_result(profile, BattleSim.PLAYER, 2)
	_expect(reward.coins == 31 and reward.xp == 35, "a win grants base and crown rewards")
	profile.xp = BattleProgression.xp_to_next(profile.level) - 5
	var level_reward := BattleProgression.apply_match_result(profile, BattleSim.ENEMY, 0)
	_expect(level_reward.levels == 1 and profile.level == 2, "experience carries into a new level")
	_expect(profile.xp == 10, "excess experience is preserved after leveling")


func _test_battle_intro() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	_expect(scene.sfx_bank.size() == 8 and scene.sfx_players.size() == 8, "procedural sound bank is ready")
	_expect(scene.sfx_bank["fireball"].data.size() > 1000, "procedural sound contains PCM samples")
	scene._start_battle()
	var initial_time: float = scene.simulation.time_left
	scene._process(1.0)
	_expect(is_equal_approx(scene.simulation.time_left, initial_time), "battle countdown freezes the simulation")
	scene.battle_intro_time = 0.0
	scene._process(0.1)
	_expect(scene.simulation.time_left < initial_time, "battle starts after the countdown")
	var initial_wins: int = scene.profile.wins
	scene.simulation.forfeit(BattleSim.ENEMY)
	scene.last_reward = {"coins": 25, "xp": 35, "levels": 0}
	scene._show_result(false)
	_expect(scene.profile.wins == initial_wins, "preview result does not mutate progression")
	scene.free()


func _test_units_fight() -> void:
	var simulation := BattleSim.new(13)
	simulation.energy = [10.0, 10.0]
	simulation.play_card(BattleSim.PLAYER, "guardian", 0)
	simulation.play_card(BattleSim.ENEMY, "guardian", 0)
	for index in range(1000):
		simulation.step(0.1)
		if simulation.units.size() < 2:
			break
	_expect(simulation.units.size() < 2, "opposing units eventually defeat each other")


func _test_tower_defends_lane() -> void:
	var simulation := BattleSim.new(14)
	simulation.energy[BattleSim.ENEMY] = 10.0
	simulation.play_card(BattleSim.ENEMY, "guardian", 0)
	var unit: Dictionary = simulation.units[0]
	unit.y = 820.0
	var initial_hp: float = unit.hp
	for index in range(12):
		simulation.step(0.1)
	_expect(unit.hp < initial_hp, "a lane tower attacks an approaching enemy")


func _test_bot_matches_finish() -> void:
	for match_index in range(20):
		var simulation := BattleSim.new(1000 + match_index)
		var player_bot := BattleAI.new(BattleSim.PLAYER, 2, 2000 + match_index)
		var enemy_bot := BattleAI.new(BattleSim.ENEMY, 2, 3000 + match_index)
		for tick in range(2500):
			player_bot.update(0.1, simulation)
			enemy_bot.update(0.1, simulation)
			simulation.step(0.1)
			if simulation.finished:
				break
		_expect(simulation.finished, "bot match %d finishes" % match_index)
		_expect(simulation.winner >= -1 and simulation.winner <= 1, "bot match %d has a valid result" % match_index)
		_expect(player_bot.invalid_actions == 0, "player bot %d only submits valid actions" % match_index)
		_expect(enemy_bot.invalid_actions == 0, "enemy bot %d only submits valid actions" % match_index)


func _expect(condition: bool, message: String) -> void:
	assertions += 1
	if condition:
		return
	failures += 1
	push_error("FAILED: %s" % message)
