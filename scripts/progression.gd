class_name BattleProgression
extends RefCounted

const CURRENT_VERSION := 5
const MAX_CARD_LEVEL := 5


static func default_profile() -> Dictionary:
	var card_levels := {}
	for card_id in BattleSim.DEFAULT_DECK:
		card_levels[card_id] = 1
	return {
		"version": CURRENT_VERSION,
		"wins": 0,
		"losses": 0,
		"draws": 0,
		"coins": 0,
		"xp": 0,
		"level": 1,
		"tutorial_completed": false,
		"sound_enabled": true,
		"difficulty": 1,
		"haptics_enabled": true,
		"card_levels": card_levels,
	}


static func normalize(raw: Dictionary) -> Dictionary:
	var profile := default_profile()
	for key in ["wins", "losses", "draws", "coins", "xp"]:
		profile[key] = maxi(0, int(raw.get(key, profile[key])))
	profile.level = maxi(1, int(raw.get("level", 1)))
	profile.tutorial_completed = bool(raw.get("tutorial_completed", false))
	profile.sound_enabled = bool(raw.get("sound_enabled", true))
	profile.difficulty = clampi(int(raw.get("difficulty", 1)), 0, 2)
	profile.haptics_enabled = bool(raw.get("haptics_enabled", true))
	var raw_levels := {}
	var stored_levels = raw.get("card_levels", {})
	if typeof(stored_levels) == TYPE_DICTIONARY:
		raw_levels = stored_levels
	for card_id in BattleSim.DEFAULT_DECK:
		profile.card_levels[card_id] = clampi(int(raw_levels.get(card_id, 1)), 1, MAX_CARD_LEVEL)
	return profile


static func card_upgrade_cost(level: int) -> int:
	return 50 * clampi(level, 1, MAX_CARD_LEVEL)


static func upgrade_card(profile: Dictionary, card_id: String) -> bool:
	if card_id not in BattleSim.DEFAULT_DECK:
		return false
	var level := clampi(int(profile.card_levels.get(card_id, 1)), 1, MAX_CARD_LEVEL)
	if level >= MAX_CARD_LEVEL:
		return false
	var cost := card_upgrade_cost(level)
	if int(profile.coins) < cost:
		return false
	profile.coins -= cost
	profile.card_levels[card_id] = level + 1
	profile.version = CURRENT_VERSION
	return true


static func xp_to_next(level: int) -> int:
	return 80 + maxi(1, level) * 20


static func apply_match_result(profile: Dictionary, winner: int, player_crowns: int) -> Dictionary:
	var coins := 15
	var xp := 20
	if winner == BattleSim.PLAYER:
		coins = 25
		xp = 35
	elif winner == BattleSim.ENEMY:
		coins = 10
		xp = 15
	coins += maxi(0, player_crowns) * 3
	return _grant(profile, coins, xp)


static func complete_tutorial(profile: Dictionary) -> Dictionary:
	if profile.tutorial_completed:
		return {"coins": 0, "xp": 0, "levels": 0}
	profile.tutorial_completed = true
	return _grant(profile, 15, 20)


static func _grant(profile: Dictionary, coins: int, xp: int) -> Dictionary:
	profile.coins += coins
	profile.xp += xp
	var levels_gained := 0
	while profile.xp >= xp_to_next(profile.level):
		profile.xp -= xp_to_next(profile.level)
		profile.level += 1
		levels_gained += 1
	profile.version = CURRENT_VERSION
	return {"coins": coins, "xp": xp, "levels": levels_gained}
