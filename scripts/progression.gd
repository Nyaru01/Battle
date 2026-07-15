class_name BattleProgression
extends RefCounted

const CURRENT_VERSION := 3


static func default_profile() -> Dictionary:
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
	}


static func normalize(raw: Dictionary) -> Dictionary:
	var profile := default_profile()
	for key in ["wins", "losses", "draws", "coins", "xp"]:
		profile[key] = maxi(0, int(raw.get(key, profile[key])))
	profile.level = maxi(1, int(raw.get("level", 1)))
	profile.tutorial_completed = bool(raw.get("tutorial_completed", false))
	profile.sound_enabled = bool(raw.get("sound_enabled", true))
	profile.difficulty = clampi(int(raw.get("difficulty", 1)), 0, 2)
	return profile


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
