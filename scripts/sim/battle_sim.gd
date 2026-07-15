class_name BattleSim
extends RefCounted

const PLAYER := 0
const ENEMY := 1
const MAX_ENERGY := 10.0
const ENERGY_PER_SECOND := 1.0
const MATCH_DURATION := 180.0
const LANE_COUNT := 2
const TOWER_RANGE := 235.0
const TOWER_DAMAGE := 52.0
const TOWER_INTERVAL := 1.0

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


func _init(seed_value: int = 1) -> void:
	rng.seed = seed_value
	reset(seed_value)


func reset(seed_value: int = 1) -> void:
	rng.seed = seed_value
	units.clear()
	energy = [5.0, 5.0]
	towers = [
		{"lanes": [1200.0, 1200.0], "core": 2200.0},
		{"lanes": [1200.0, 1200.0], "core": 2200.0},
	]
	time_left = MATCH_DURATION
	finished = false
	winner = -1
	next_unit_id = 1
	events.clear()
	tower_attack_timers = [[0.0, 0.0], [0.0, 0.0]]


func play_card(side: int, card_id: String, lane: int) -> bool:
	if finished or side < PLAYER or side > ENEMY or lane < 0 or lane >= LANE_COUNT:
		return false
	if not CARDS.has(card_id):
		return false
	var card: Dictionary = CARDS[card_id]
	if energy[side] + 0.001 < card.cost:
		return false
	energy[side] -= card.cost
	if card.type == "spell":
		_cast_spell(side, card_id, lane, card)
	else:
		_spawn_unit(side, card_id, lane, card)
	events.append({"type": "card_played", "side": side, "card": card_id, "lane": lane})
	return true


func step(delta: float) -> void:
	if finished or delta <= 0.0:
		return
	var safe_delta := minf(delta, 0.1)
	time_left = maxf(0.0, time_left - safe_delta)
	for side in [PLAYER, ENEMY]:
		energy[side] = minf(MAX_ENERGY, energy[side] + ENERGY_PER_SECOND * safe_delta)
	_update_units(safe_delta)
	_update_towers(safe_delta)
	_remove_defeated_units()
	_check_end()


func get_card_ids() -> Array[String]:
	var ids: Array[String] = []
	for card_id in CARDS.keys():
		ids.append(card_id)
	return ids


func get_total_health(side: int) -> float:
	return towers[side].core + towers[side].lanes[0] + towers[side].lanes[1]


func get_units_in_lane(side: int, lane: int) -> Array:
	return units.filter(func(unit: Dictionary) -> bool: return unit.side == side and unit.lane == lane)


func _spawn_unit(side: int, card_id: String, lane: int, card: Dictionary) -> void:
	var spawn_y := 820.0 if side == PLAYER else 310.0
	units.append({
		"id": next_unit_id,
		"side": side,
		"card_id": card_id,
		"lane": lane,
		"y": spawn_y,
		"hp": card.hp,
		"max_hp": card.hp,
		"damage": card.damage,
		"speed": card.speed,
		"range": card.range,
		"interval": card.interval,
		"attack_timer": rng.randf_range(0.0, 0.15),
	})
	next_unit_id += 1


func _cast_spell(side: int, card_id: String, lane: int, card: Dictionary) -> void:
	var target_side: int = 1 - side
	for unit in units:
		if unit.side == target_side and unit.lane == lane:
			unit.hp -= card.damage
	var lane_damage: float = card.damage * 0.45
	if towers[target_side].lanes[lane] > 0.0:
		towers[target_side].lanes[lane] = maxf(0.0, towers[target_side].lanes[lane] - lane_damage)
	else:
		towers[target_side].core = maxf(0.0, towers[target_side].core - lane_damage)
	events.append({"type": "spell", "side": side, "card": card_id, "lane": lane})


func _update_units(delta: float) -> void:
	for unit in units:
		if unit.hp <= 0.0:
			continue
		unit.attack_timer = maxf(0.0, unit.attack_timer - delta)
		var target = _closest_enemy_unit(unit)
		if target != null and absf(target.y - unit.y) <= unit.range:
			if unit.attack_timer <= 0.0:
				target.hp -= unit.damage
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
		unit.y += direction * unit.speed * delta


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
				target.hp -= TOWER_DAMAGE
				tower_attack_timers[side][lane] = TOWER_INTERVAL
				events.append({"type": "tower_shot", "side": side, "lane": lane, "target": target.id})


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


func _damage_objective(target_side: int, lane: int, damage: float) -> void:
	if towers[target_side].lanes[lane] > 0.0:
		towers[target_side].lanes[lane] = maxf(0.0, towers[target_side].lanes[lane] - damage)
		events.append({"type": "tower_hit", "side": target_side, "lane": lane})
	else:
		towers[target_side].core = maxf(0.0, towers[target_side].core - damage)
		events.append({"type": "core_hit", "side": target_side})


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
		var player_health := get_total_health(PLAYER)
		var enemy_health := get_total_health(ENEMY)
		_end_match(PLAYER if player_health > enemy_health else ENEMY if enemy_health > player_health else -1)


func _end_match(result: int) -> void:
	finished = true
	winner = result
	events.append({"type": "match_end", "winner": result})
