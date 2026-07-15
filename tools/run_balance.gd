extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var match_count := _match_count()
	var wins := [0, 0]
	var draws := 0
	var overtime_matches := 0
	var unfinished := 0
	var invalid_states := 0
	var invalid_actions := 0
	var total_duration := 0.0
	for match_index in range(match_count):
		var difficulty := match_index % 3
		var simulation := BattleSim.new(10000 + match_index)
		var player_bot := BattleAI.new(BattleSim.PLAYER, difficulty, 20000 + match_index)
		var enemy_bot := BattleAI.new(BattleSim.ENEMY, difficulty, 30000 + match_index)
		for tick in range(2500):
			if match_index % 2 == 0:
				player_bot.update(0.1, simulation)
				enemy_bot.update(0.1, simulation)
			else:
				enemy_bot.update(0.1, simulation)
				player_bot.update(0.1, simulation)
			simulation.step(0.1)
			if simulation.finished:
				break
		if not simulation.finished:
			unfinished += 1
		elif simulation.winner == -1:
			draws += 1
		else:
			wins[simulation.winner] += 1
		if simulation.overtime:
			overtime_matches += 1
		var duration := BattleSim.MATCH_DURATION - simulation.time_left
		if simulation.overtime:
			duration = BattleSim.MATCH_DURATION + BattleSim.OVERTIME_DURATION - simulation.time_left
		total_duration += duration
		invalid_actions += player_bot.invalid_actions + enemy_bot.invalid_actions
		if not _valid_final_state(simulation):
			invalid_states += 1
	var summary := {
		"matches": match_count,
		"player_wins": wins[BattleSim.PLAYER],
		"enemy_wins": wins[BattleSim.ENEMY],
		"draws": draws,
		"overtime_matches": overtime_matches,
		"unfinished": unfinished,
		"invalid_states": invalid_states,
		"invalid_actions": invalid_actions,
		"average_duration_seconds": snappedf(total_duration / match_count, 0.1),
	}
	print("Balance report: %s" % JSON.stringify(summary))
	quit(1 if unfinished > 0 or invalid_states > 0 or invalid_actions > 0 else 0)


func _match_count() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--matches="):
			return clampi(int(argument.trim_prefix("--matches=")), 1, 10000)
	return 1000


func _valid_final_state(simulation: BattleSim) -> bool:
	for side in [BattleSim.PLAYER, BattleSim.ENEMY]:
		if simulation.energy[side] < 0.0 or simulation.energy[side] > BattleSim.MAX_ENERGY + 0.001:
			return false
		if simulation.get_hand(side).size() != 4:
			return false
		if simulation.towers[side].core < 0.0:
			return false
		for lane_hp in simulation.towers[side].lanes:
			if lane_hp < 0.0:
				return false
	for unit in simulation.units:
		if unit.hp <= 0.0:
			return false
	return true
