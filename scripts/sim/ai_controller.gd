class_name BattleAI
extends RefCounted

var side := BattleSim.ENEMY
var difficulty := 1
var decision_timer := 0.0
var rng := RandomNumberGenerator.new()
var actions_played := 0
var invalid_actions := 0


func _init(ai_side: int = BattleSim.ENEMY, level: int = 1, seed_value: int = 2) -> void:
	side = ai_side
	difficulty = clampi(level, 0, 2)
	rng.seed = seed_value
	decision_timer = _next_delay()


func update(delta: float, simulation: BattleSim) -> void:
	if simulation.finished:
		return
	decision_timer -= delta
	if decision_timer > 0.0:
		return
	decision_timer = _next_delay()
	_take_turn(simulation)


func _take_turn(simulation: BattleSim) -> void:
	var available: Array[String] = []
	for card_id in simulation.get_hand(side):
		if BattleSim.CARDS[card_id].cost <= simulation.energy[side] + 0.001:
			available.append(card_id)
	if available.is_empty():
		return
	var target_lane := _threatened_lane(simulation)
	var enemy_side: int = 1 - side
	var enemy_count := simulation.get_units_in_lane(enemy_side, target_lane).size()
	if "fireball" in available and enemy_count >= (3 if difficulty == 0 else 2):
		_play(simulation, "fireball", target_lane)
		return
	if "frost" in available and enemy_count >= 2:
		_play(simulation, "frost", target_lane)
		return
	var chosen := _choose_unit(available, simulation, target_lane)
	if chosen.is_empty():
		return
	if difficulty == 0 and rng.randf() < 0.25:
		target_lane = 1 - target_lane
	_play(simulation, chosen, target_lane)


func _choose_unit(available: Array[String], simulation: BattleSim, lane: int) -> String:
	var candidates := available.filter(func(card_id: String) -> bool: return BattleSim.CARDS[card_id].type == "unit")
	if candidates.is_empty():
		return ""
	if difficulty == 0:
		return candidates[rng.randi_range(0, candidates.size() - 1)]
	var threat_count := simulation.get_units_in_lane(1 - side, lane).size()
	var lane_damage: float = (1200.0 - simulation.towers[side].lanes[lane]) / 1200.0
	var best_card := String(candidates[0])
	var best_score := -INF
	for card_id in candidates:
		var score := rng.randf_range(0.0, 0.35)
		match card_id:
			"guardian":
				score += 2.0 + threat_count * 0.35
			"ranger":
				score += 1.5 + threat_count * 0.8
			"colossus":
				score += 1.4 + threat_count * 0.65 + lane_damage
			"duelist":
				score += 2.4 if threat_count == 0 else 0.8
			"alchemist":
				score += 1.2 + threat_count * 1.3
			"bulwark":
				score += 1.0 + threat_count + lane_damage * 2.0
		if score > best_score:
			best_score = score
			best_card = card_id
	return best_card


func _play(simulation: BattleSim, card_id: String, lane: int) -> void:
	if simulation.play_card(side, card_id, lane):
		actions_played += 1
	else:
		invalid_actions += 1


func _threatened_lane(simulation: BattleSim) -> int:
	var enemy_side: int = 1 - side
	var scores := [0.0, 0.0]
	for lane in range(BattleSim.LANE_COUNT):
		for unit in simulation.get_units_in_lane(enemy_side, lane):
			var progress: float = float(unit.y) / 1090.0 if side == BattleSim.ENEMY else 1.0 - float(unit.y) / 1090.0
			scores[lane] += unit.hp / unit.max_hp + progress
		scores[lane] += (1200.0 - simulation.towers[side].lanes[lane]) / 600.0
	if is_equal_approx(scores[0], scores[1]):
		return rng.randi_range(0, 1)
	return 0 if scores[0] > scores[1] else 1


func _next_delay() -> float:
	match difficulty:
		0:
			return rng.randf_range(1.8, 2.7)
		1:
			return rng.randf_range(1.15, 1.75)
		_:
			return rng.randf_range(0.7, 1.15)
