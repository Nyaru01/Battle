class_name BattleSim
extends RefCounted

const PLAYER := 0
const ENEMY := 1
const MAX_ENERGY := 10.0
const MAX_CARD_LEVEL := 5
const ENERGY_PER_SECOND := 1.0
const MATCH_DURATION := 180.0
const OVERTIME_DURATION := 45.0
const LANE_COUNT := 2
const TOWER_RANGE := 235.0
const TOWER_DAMAGE := 52.0
const TOWER_INTERVAL := 1.0
const CORE_RANGE := 275.0
const CORE_DAMAGE := 68.0
const CORE_INTERVAL := 1.15
const CORE_MAX_HEALTH := 2200.0
const DEFAULT_DECK := [
	"guardian", "ranger", "colossus", "fireball",
	"duelist", "alchemist", "bulwark", "frost",
]

const CARDS := {
	"guardian": {
		"name": "Gardien",
		"cost": 3.0,
		"type": "unit",
		"hp": 520.0,
		"damage": 62.0,
		"speed": 58.0,
		"range": 48.0,
		"interval": 1.0,
	},
	"ranger": {
		"name": "Éclaireuse",
		"cost": 3.0,
		"type": "unit",
		"hp": 270.0,
		"damage": 48.0,
		"speed": 46.0,
		"range": 155.0,
		"interval": 0.9,
	},
	"colossus": {
		"name": "Colosse",
		"cost": 5.0,
		"type": "unit",
		"hp": 1050.0,
		"damage": 88.0,
		"speed": 30.0,
		"range": 52.0,
		"interval": 1.4,
	},
	"fireball": {
		"name": "Comète",
		"cost": 4.0,
		"type": "spell",
		"damage": 185.0,
	},
	"duelist": {
		"name": "Lames jumelles",
		"cost": 3.0,
		"type": "unit",
		"count": 2,
		"hp": 220.0,
		"damage": 34.0,
		"speed": 72.0,
		"range": 44.0,
		"interval": 0.75,
	},
	"alchemist": {
		"name": "Alchimiste",
		"cost": 4.0,
		"type": "unit",
		"hp": 390.0,
		"damage": 74.0,
		"speed": 42.0,
		"range": 135.0,
		"interval": 1.25,
		"splash": 70.0,
	},
	"bulwark": {
		"name": "Rempart",
		"cost": 6.0,
		"type": "unit",
		"hp": 1550.0,
		"damage": 70.0,
		"speed": 24.0,
		"range": 48.0,
		"interval": 1.5,
	},
	"frost": {
		"name": "Stase",
		"cost": 3.0,
		"type": "spell",
		"damage": 95.0,
		"slow_duration": 3.0,
	},
}

var rng := RandomNumberGenerator.new()
var units: Array = []
var energy := [5.0, 5.0]
var towers: Array = []
var time_left := MATCH_DURATION
var finished := false
var winner := -1
var next_unit_id := 1
var events: Array = []
var tower_attack_timers := [[0.0, 0.0], [0.0, 0.0]]
var core_attack_timers := [0.0, 0.0]
var hands: Array = []
var draw_queues: Array = []
var crowns := [0, 0]
var overtime := false
var double_energy := false
var card_levels: Array = [{}, {}]


func _init(seed_value: int = 1, player_card_levels: Dictionary = {}, enemy_card_levels: Dictionary = {}, randomize_opening: bool = false) -> void:
	rng.seed = seed_value
	reset(seed_value, player_card_levels, enemy_card_levels, randomize_opening)


func reset(seed_value: int = 1, player_card_levels: Dictionary = {}, enemy_card_levels: Dictionary = {}, randomize_opening: bool = false) -> void:
	rng.seed = seed_value
	units.clear()
	energy = [5.0, 5.0]
	towers = [
		{"lanes": [1200.0, 1200.0], "core": CORE_MAX_HEALTH},
		{"lanes": [1200.0, 1200.0], "core": CORE_MAX_HEALTH},
	]
	time_left = MATCH_DURATION
	finished = false
	winner = -1
	next_unit_id = 1
	events.clear()
	tower_attack_timers = [[0.0, 0.0], [0.0, 0.0]]
	core_attack_timers = [0.0, 0.0]
	var opening_deck := DEFAULT_DECK.duplicate()
	if randomize_opening:
		_shuffle_deck(opening_deck)
	hands = [opening_deck.slice(0, 4), opening_deck.slice(0, 4)]
	draw_queues = [opening_deck.slice(4), opening_deck.slice(4)]
	crowns = [0, 0]
	overtime = false
	double_energy = false
	card_levels = [player_card_levels.duplicate(true), enemy_card_levels.duplicate(true)]


func _shuffle_deck(deck: Array) -> void:
	for index in range(deck.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var card = deck[index]
		deck[index] = deck[swap_index]
		deck[swap_index] = card


func play_card(side: int, card_id: String, lane: int) -> bool:
	if finished or side < PLAYER or side > ENEMY or lane < 0 or lane >= LANE_COUNT:
		return false
	if not CARDS.has(card_id):
		return false
	if card_id not in hands[side]:
		return false
	var level := clampi(int(card_levels[side].get(card_id, 1)), 1, MAX_CARD_LEVEL)
	var card: Dictionary = scaled_card(CARDS[card_id], level)
	if energy[side] + 0.001 < card.cost:
		return false
	energy[side] -= card.cost
	if card.type == "spell":
		_cast_spell(side, card_id, lane, card)
	else:
		_spawn_unit(side, card_id, lane, card)
	_cycle_card(side, card_id)
	events.append({"type": "card_played", "side": side, "card": card_id, "lane": lane, "level": level})
	return true


static func level_multiplier(level: int) -> float:
	return 1.0 + float(clampi(level, 1, MAX_CARD_LEVEL) - 1) * 0.08


static func scaled_card(base_card: Dictionary, level: int) -> Dictionary:
	var card := base_card.duplicate(true)
	var multiplier := level_multiplier(level)
	if card.has("hp"):
		card.hp = float(card.hp) * multiplier
	if card.has("damage"):
		card.damage = float(card.damage) * multiplier
	return card


func forfeit(side: int) -> bool:
	if finished or side < PLAYER or side > ENEMY:
		return false
	events.append({"type": "forfeit", "side": side})
	_end_match(1 - side)
	return true


func step(delta: float) -> void:
	if finished or delta <= 0.0:
		return
	var safe_delta := minf(delta, 0.1)
	time_left = maxf(0.0, time_left - safe_delta)
	if not overtime and not double_energy and time_left <= 60.0:
		double_energy = true
		events.append({"type": "double_energy_started"})
	for side in [PLAYER, ENEMY]:
		var energy_multiplier := 3.0 if overtime else (2.0 if double_energy else 1.0)
		energy[side] = minf(MAX_ENERGY, energy[side] + ENERGY_PER_SECOND * energy_multiplier * safe_delta)
	_update_units(safe_delta)
	_update_towers(safe_delta)
	_remove_defeated_units()
	_check_end()


func get_card_ids() -> Array[String]:
	var ids: Array[String] = []
	for card_id in CARDS.keys():
		ids.append(card_id)
	return ids


func get_hand(side: int) -> Array:
	return hands[side].duplicate()


func get_next_card(side: int) -> String:
	return "" if draw_queues[side].is_empty() else String(draw_queues[side][0])


func is_core_active(side: int) -> bool:
	return towers[side].core < CORE_MAX_HEALTH or towers[side].lanes[0] <= 0.0 or towers[side].lanes[1] <= 0.0


func get_total_health(side: int) -> float:
	return towers[side].core + towers[side].lanes[0] + towers[side].lanes[1]


func get_units_in_lane(side: int, lane: int) -> Array:
	return units.filter(func(unit: Dictionary) -> bool: return unit.side == side and unit.lane == lane)


func _spawn_unit(side: int, card_id: String, lane: int, card: Dictionary) -> void:
	var spawn_y := 820.0 if side == PLAYER else 310.0
	var unit_count := maxi(1, int(card.get("count", 1)))
	for member in range(unit_count):
		var formation_x := (float(member) - float(unit_count - 1) * 0.5) * 56.0
		units.append({
			"id": next_unit_id,
			"side": side,
			"card_id": card_id,
			"lane": lane,
			"y": spawn_y,
			"formation_x": formation_x,
			"hp": card.hp,
			"max_hp": card.hp,
			"damage": card.damage,
			"speed": card.speed,
			"range": card.range,
			"interval": card.interval,
			"splash": float(card.get("splash", 0.0)),
			"slow_timer": 0.0,
			"attack_timer": rng.randf_range(0.0, 0.15),
		})
		next_unit_id += 1


func _cast_spell(side: int, card_id: String, lane: int, card: Dictionary) -> void:
	var target_side: int = 1 - side
	for unit in units:
		if unit.side == target_side and unit.lane == lane:
			unit.hp = maxf(0.0, unit.hp - card.damage)
			unit.slow_timer = maxf(float(unit.slow_timer), float(card.get("slow_duration", 0.0)))
	_damage_objective(target_side, lane, card.damage * 0.45)
	events.append({"type": "spell", "side": side, "card": card_id, "lane": lane})


func _update_units(delta: float) -> void:
	for unit in units:
		if unit.hp <= 0.0:
			continue
		unit.attack_timer = maxf(0.0, unit.attack_timer - delta)
		unit.slow_timer = maxf(0.0, unit.slow_timer - delta)
		var target = _closest_enemy_unit(unit)
		if target != null and absf(target.y - unit.y) <= unit.range:
			if unit.attack_timer <= 0.0:
				_damage_unit_target(unit, target)
				unit.attack_timer = unit.interval
				events.append({"type": "hit", "source": unit.id, "target": target.id})
			continue
		var target_y := 240.0 if unit.side == PLAYER else 900.0
		var target_side: int = 1 - int(unit.side)
		if towers[target_side].lanes[unit.lane] <= 0.0:
			target_y = 205.0 if unit.side == PLAYER else 955.0
		var distance := absf(target_y - unit.y)
		if distance <= unit.range:
			if unit.attack_timer <= 0.0:
				_damage_objective(target_side, unit.lane, unit.damage)
				unit.attack_timer = unit.interval
			continue
		var direction := -1.0 if unit.side == PLAYER else 1.0
		var speed_multiplier := 0.55 if unit.slow_timer > 0.0 else 1.0
		unit.y += direction * unit.speed * speed_multiplier * delta


func _damage_unit_target(source: Dictionary, target: Dictionary) -> void:
	target.hp = maxf(0.0, target.hp - source.damage)
	if source.splash <= 0.0:
		return
	for candidate in units:
		if candidate.id == target.id or candidate.side == source.side or candidate.lane != source.lane:
			continue
		if absf(float(candidate.y) - float(target.y)) <= source.splash:
			candidate.hp = maxf(0.0, candidate.hp - source.damage * 0.55)


func _cycle_card(side: int, card_id: String) -> void:
	hands[side].erase(card_id)
	var drawn_card: String = draw_queues[side].pop_front()
	hands[side].append(drawn_card)
	draw_queues[side].append(card_id)


func _closest_enemy_unit(source: Dictionary):
	var best = null
	var best_distance := INF
	for candidate in units:
		if candidate.hp <= 0.0 or candidate.side == source.side or candidate.lane != source.lane:
			continue
		var distance: float = absf(candidate.y - source.y)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best


func _update_towers(delta: float) -> void:
	for side in [PLAYER, ENEMY]:
		var tower_y := 900.0 if side == PLAYER else 240.0
		for lane in range(LANE_COUNT):
			tower_attack_timers[side][lane] = maxf(0.0, tower_attack_timers[side][lane] - delta)
			if towers[side].lanes[lane] <= 0.0 or tower_attack_timers[side][lane] > 0.0:
				continue
			var target = _closest_unit_to_position(1 - side, lane, tower_y, TOWER_RANGE)
			if target != null:
				target.hp = maxf(0.0, target.hp - TOWER_DAMAGE)
				tower_attack_timers[side][lane] = TOWER_INTERVAL
				events.append({"type": "tower_shot", "side": side, "lane": lane, "target": target.id})
		core_attack_timers[side] = maxf(0.0, core_attack_timers[side] - delta)
		if not is_core_active(side) or towers[side].core <= 0.0 or core_attack_timers[side] > 0.0:
			continue
		var core_y := 955.0 if side == PLAYER else 205.0
		var core_target = _closest_unit_to_core(1 - side, Vector2(360.0, core_y), CORE_RANGE)
		if core_target != null:
			core_target.hp = maxf(0.0, core_target.hp - CORE_DAMAGE)
			core_attack_timers[side] = CORE_INTERVAL
			events.append({"type": "core_shot", "side": side, "target": core_target.id})


func _closest_unit_to_position(target_side: int, lane: int, position_y: float, maximum_distance: float):
	var best = null
	var best_distance := maximum_distance
	for unit in units:
		if unit.hp <= 0.0 or unit.side != target_side or unit.lane != lane:
			continue
		var distance: float = absf(float(unit.y) - position_y)
		if distance <= best_distance:
			best = unit
			best_distance = distance
	return best


func _closest_unit_to_core(target_side: int, position: Vector2, maximum_distance: float):
	var best = null
	var best_distance := maximum_distance
	for unit in units:
		if unit.hp <= 0.0 or unit.side != target_side:
			continue
		var unit_position := Vector2(210.0 if unit.lane == 0 else 510.0, float(unit.y))
		var distance := position.distance_to(unit_position)
		if distance <= best_distance:
			best = unit
			best_distance = distance
	return best


func _damage_objective(target_side: int, lane: int, damage: float) -> void:
	if towers[target_side].lanes[lane] > 0.0:
		var previous_hp: float = towers[target_side].lanes[lane]
		towers[target_side].lanes[lane] = maxf(0.0, towers[target_side].lanes[lane] - damage)
		events.append({"type": "tower_hit", "side": target_side, "lane": lane})
		if previous_hp > 0.0 and towers[target_side].lanes[lane] <= 0.0:
			_award_crown(1 - target_side, target_side, lane)
	else:
		var previous_core_hp: float = towers[target_side].core
		towers[target_side].core = maxf(0.0, towers[target_side].core - damage)
		events.append({"type": "core_hit", "side": target_side})
		if previous_core_hp > 0.0 and towers[target_side].core <= 0.0:
			crowns[1 - target_side] = 3
			events.append({"type": "core_destroyed", "side": target_side, "attacker": 1 - target_side})


func _award_crown(attacker: int, target_side: int, lane: int) -> void:
	crowns[attacker] += 1
	events.append({"type": "tower_destroyed", "side": target_side, "lane": lane, "attacker": attacker})
	if overtime:
		_end_match(attacker)


func _remove_defeated_units() -> void:
	for index in range(units.size() - 1, -1, -1):
		if units[index].hp <= 0.0:
			events.append({"type": "unit_defeated", "id": units[index].id})
			units.remove_at(index)


func _check_end() -> void:
	if towers[PLAYER].core <= 0.0:
		_end_match(ENEMY)
	elif towers[ENEMY].core <= 0.0:
		_end_match(PLAYER)
	elif time_left <= 0.0:
		if not overtime:
			if crowns[PLAYER] != crowns[ENEMY]:
				_end_match(PLAYER if crowns[PLAYER] > crowns[ENEMY] else ENEMY)
			else:
				overtime = true
				time_left = OVERTIME_DURATION
				events.append({"type": "overtime_started"})
		else:
			var player_health := get_total_health(PLAYER)
			var enemy_health := get_total_health(ENEMY)
			_end_match(PLAYER if player_health > enemy_health else ENEMY if enemy_health > player_health else -1)


func _end_match(result: int) -> void:
	_remove_defeated_units()
	finished = true
	winner = result
	events.append({"type": "match_end", "winner": result})
