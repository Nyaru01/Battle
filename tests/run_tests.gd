extends SceneTree

var failures := 0
var assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_card_cost_and_validation()
	_test_energy_regeneration()
	_test_spell_damage()
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
		for tick in range(2000):
			player_bot.update(0.1, simulation)
			enemy_bot.update(0.1, simulation)
			simulation.step(0.1)
			if simulation.finished:
				break
		_expect(simulation.finished, "bot match %d finishes" % match_index)
		_expect(simulation.winner >= -1 and simulation.winner <= 1, "bot match %d has a valid result" % match_index)


func _expect(condition: bool, message: String) -> void:
	assertions += 1
	if condition:
		return
	failures += 1
	push_error("FAILED: %s" % message)
