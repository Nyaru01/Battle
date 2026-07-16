extends SceneTree

var failures := 0
var assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_card_cost_and_validation()
	_test_energy_regeneration()
	_test_double_energy()
	_test_spell_damage()
	_test_deck_cycle()
	_test_random_opening()
	_test_squad_card()
	_test_card_level_scaling()
	_test_frost_slow()
	_test_crown_scoring()
	_test_overtime_rules()
	_test_tutorial_flow()
	_test_forfeit()
	_test_profile_store()
	_test_android_export_configuration()
	_test_visual_system()
	_test_v040_rigs()
	_test_progression()
	_test_battle_intro()
	_test_units_fight()
	_test_motion_and_projectile_events()
	_test_tower_defends_lane()
	_test_core_defends_after_breach()
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


func _test_double_energy() -> void:
	var simulation := BattleSim.new(17)
	simulation.energy = [0.0, 0.0]
	simulation.time_left = 60.05
	simulation.step(0.1)
	_expect(simulation.double_energy, "the final regulation minute enables double energy")
	_expect(absf(simulation.energy[BattleSim.PLAYER] - 0.2) < 0.01, "double energy applies to regeneration")
	var announcements := simulation.events.filter(func(event: Dictionary) -> bool: return event.type == "double_energy_started")
	_expect(announcements.size() == 1, "double energy emits one announcement event")
	simulation.step(0.1)
	announcements = simulation.events.filter(func(event: Dictionary) -> bool: return event.type == "double_energy_started")
	_expect(announcements.size() == 1, "double energy announcement is not repeated")


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


func _test_random_opening() -> void:
	var first := BattleSim.new(98, {}, {}, true)
	var repeat := BattleSim.new(98, {}, {}, true)
	var different := BattleSim.new(99, {}, {}, true)
	_expect(first.get_hand(BattleSim.PLAYER) == first.get_hand(BattleSim.ENEMY), "random opening is symmetrical for both sides")
	_expect(first.get_hand(BattleSim.PLAYER) == repeat.get_hand(BattleSim.PLAYER), "random opening is deterministic for a seed")
	_expect(first.get_hand(BattleSim.PLAYER) != BattleSim.DEFAULT_DECK.slice(0, 4), "random opening changes the fixed starting hand")
	_expect(first.get_hand(BattleSim.PLAYER) != different.get_hand(BattleSim.PLAYER) or first.get_next_card(BattleSim.PLAYER) != different.get_next_card(BattleSim.PLAYER), "different seeds vary the opening cycle")


func _test_squad_card() -> void:
	var simulation := BattleSim.new(24)
	simulation.energy[BattleSim.PLAYER] = 100.0
	_expect(simulation.play_card(BattleSim.PLAYER, "guardian", 0), "deck cycle exposes the squad card")
	_expect(simulation.play_card(BattleSim.PLAYER, "duelist", 1), "squad card can be deployed")
	var squad := simulation.units.filter(func(unit: Dictionary) -> bool: return unit.card_id == "duelist")
	_expect(squad.size() == 2, "squad card spawns two independent fighters")
	_expect(squad[0].id != squad[1].id, "squad fighters receive distinct unit ids")
	_expect(float(squad[0].formation_x) < 0.0 and float(squad[1].formation_x) > 0.0, "squad fighters deploy in formation")


func _test_card_level_scaling() -> void:
	var simulation := BattleSim.new(25, {"guardian": 3}, {"guardian": 2})
	_expect(simulation.play_card(BattleSim.PLAYER, "guardian", 0), "upgraded player card can be played")
	_expect(simulation.play_card(BattleSim.ENEMY, "guardian", 1), "baseline enemy card can be played")
	var expected_hp: float = BattleSim.CARDS.guardian.hp * BattleSim.level_multiplier(3)
	_expect(is_equal_approx(simulation.units[0].hp, expected_hp), "card level scales player unit health")
	var expected_enemy_hp: float = BattleSim.CARDS.guardian.hp * BattleSim.level_multiplier(2)
	_expect(is_equal_approx(simulation.units[1].hp, expected_enemy_hp), "enemy uses its independently configured card level")


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
	_expect(absf(simulation.energy[BattleSim.PLAYER] - 3.2) < 0.02, "energy regenerates three times as fast in overtime")
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


func _test_android_export_configuration() -> void:
	var config := FileAccess.get_file_as_string("res://export_presets.cfg")
	_expect(config.count("export_filter=\"all_resources\"") == 2, "both Android presets include all runtime resources")
	_expect(config.count("export_files=PackedStringArray()") == 2, "Android presets do not rely on a selective scene list")
	_expect(config.count("exclude_filter=\"Android/*,builds/*,tests/*,tools/*\"") == 2, "Android presets exclude the downloadable APK and non-runtime project resources")
	_expect(config.count("export_path=\"Android/Battle-latest.apk\"") == 2, "both Android presets refresh the easy-to-find root APK")
	_expect(config.count("version/code=40") == 2 and config.count("version/name=\"0.40.0-alpha\"") == 2, "both Android presets expose the v0.40 package version")
	var project := FileAccess.get_file_as_string("res://project.godot")
	_expect("size/mode=3" in project and "stretch/aspect=\"expand\"" in project, "mobile canvas fills the screen without non-uniform stretching")
	_expect(project.count("renderer/rendering_method=\"mobile\"") == 1, "battle uses the Vulkan-oriented mobile renderer")
	_expect("window_width_override" not in project and "window_height_override" not in project, "desktop window overrides cannot letterbox Android")
	_expect("assets/v040/ui/app-icon-v040.png" in project, "the v0.40 crest is the packaged application icon")


func _test_visual_system() -> void:
	_expect(ResourceLoader.exists("res://assets/fonts/Baloo2-Variable.ttf"), "rounded premium heading font is packaged")
	_expect(ResourceLoader.exists("res://assets/fonts/Nunito-Variable.ttf"), "readable body font is packaged")
	_expect(ResourceLoader.exists("res://assets/v040/ui/ui-icons-v040.png") and ResourceLoader.exists("res://assets/v040/ui/spell-art-v040.png"), "original v0.40 UI and spell atlases are packaged")
	_expect(ResourceLoader.exists("res://assets/v040/environment/arena-royale-v040.png") and ResourceLoader.exists("res://assets/v040/environment/tower-parts-v040.png"), "original v0.40 arena and tower atlases are packaged")
	var world := BattleWorld2D.new()
	world.size = Vector2(540.0, 700.0)
	root.add_child(world)
	world._update_arena_rect()
	_expect(absf(world.arena_rect.size.x / world.arena_rect.size.y - 2.0 / 3.0) < 0.001, "portrait arena preserves its authored aspect ratio")
	var enemy_left := world.to_sim_position(world.arena_rect.position + world.arena_rect.size * Vector2(0.25, 0.25))
	var player_right := world.to_sim_position(world.arena_rect.position + world.arena_rect.size * Vector2(0.75, 0.75))
	_expect(world.lane_at(enemy_left) == 0 and world.lane_at(player_right) == 1, "responsive arena mapping preserves both lanes")
	_expect(not world.is_player_half(enemy_left) and world.is_player_half(player_right), "responsive arena mapping preserves deployment territories")
	_expect(is_inf(world.to_sim_position(Vector2(-20.0, -20.0)).x), "touches outside the arena are ignored")
	world.set_targeting("unit", 1)
	_expect(world.targeting_type == "unit" and world.targeting_lane == 1, "targeting state reaches the animated renderer")
	world.begin_deploy_preview("guardian")
	world.update_deploy_preview(world.arena_rect.position + world.arena_rect.size * Vector2(0.25, 0.75))
	_expect(world.preview_valid and world.preview_lane == 0, "unit drag preview accepts the allied half")
	world.begin_deploy_preview("fireball")
	world.update_deploy_preview(world.arena_rect.position + world.arena_rect.size * Vector2(0.75, 0.25))
	_expect(world.preview_valid and world.preview_lane == 1, "spell drag preview accepts the enemy half")
	world.end_deploy_preview()
	_expect(world.preview_card.is_empty(), "drag preview clears cleanly after release")
	world.free()


func _test_v040_rigs() -> void:
	for card_id in ["guardian", "ranger", "colossus", "duelist", "alchemist", "bulwark"]:
		var definition := UnitRigDefinition.for_card(card_id)
		_expect(definition.card_id == card_id and definition.atlas != null, "%s has a dedicated articulated atlas" % card_id)
		_expect(definition.cell_region(3, 3).end.x <= definition.atlas.get_width() and definition.cell_region(3, 3).end.y <= definition.atlas.get_height(), "%s rig exposes a valid 4x4 part grid" % card_id)
		var view := UnitView2D.new()
		view.configure(400 + assertions, card_id, BattleSim.PLAYER)
		root.add_child(view)
		_expect(view.sprites.size() == 8, "%s assembles eight independently animated body parts" % card_id)
		view.sync_state({"hp": 80.0, "max_hp": 100.0, "moving": true, "walk_phase": 1.4, "attack_pulse": 0.2})
		view._process(0.1)
		_expect(view.moving and view.attack_timer > 0.0, "%s reacts to movement and attack state" % card_id)
		view.play_hit()
		view.play_death()
		view._process(0.7)
		_expect(view.is_finished(), "%s completes its authored defeat animation" % card_id)
		view.free()


func _test_progression() -> void:
	var legacy := {"wins": 3, "losses": 2}
	var profile := BattleProgression.normalize(legacy)
	_expect(profile.wins == 3 and profile.level == 1, "legacy profiles migrate with defaults")
	_expect(profile.sound_enabled and profile.haptics_enabled and profile.difficulty == 1, "legacy profiles receive default settings")
	_expect(profile.card_levels.size() == BattleSim.DEFAULT_DECK.size() and profile.card_levels.guardian == 1, "legacy profiles receive level-one cards")
	var settings := BattleProgression.normalize({"sound_enabled": false, "haptics_enabled": false, "difficulty": 9})
	_expect(not settings.sound_enabled and not settings.haptics_enabled and settings.difficulty == 2, "local settings are normalized safely")
	var upgrade_profile := BattleProgression.default_profile()
	upgrade_profile.coins = 160
	_expect(BattleProgression.upgrade_card(upgrade_profile, "guardian"), "coins can upgrade a card")
	_expect(upgrade_profile.card_levels.guardian == 2 and upgrade_profile.coins == 110, "upgrade spends the correct amount")
	_expect(BattleProgression.upgrade_card(upgrade_profile, "guardian"), "a card can be upgraded again")
	_expect(not BattleProgression.upgrade_card(upgrade_profile, "guardian"), "upgrade is rejected without enough coins")
	var capped := BattleProgression.normalize({"card_levels": {"guardian": 99}})
	_expect(capped.card_levels.guardian == BattleProgression.MAX_CARD_LEVEL, "stored card levels are capped safely")
	var player_levels: Dictionary = BattleProgression.default_profile().card_levels
	player_levels.guardian = 5
	var initiation := BattleProgression.opponent_card_levels(player_levels, 0)
	var tactical := BattleProgression.opponent_card_levels(player_levels, 1)
	var expert := BattleProgression.opponent_card_levels(player_levels, 2)
	_expect(initiation.guardian == 1, "initiation keeps baseline enemy cards")
	_expect(tactical.guardian == 4, "tactical AI trails the player by one card level")
	_expect(expert.guardian == 5, "expert AI matches player card levels")
	_expect(BattleProgression.average_card_level(player_levels) == 2, "average card level is rounded for the HUD")
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
	_expect(scene.sfx_bank.size() == 9 and scene.sfx_bank.has("core_shot") and scene.sfx_players.size() == 8, "procedural sound bank includes central fortress fire")
	_expect(scene.sfx_bank["fireball"].data.size() > 1000, "procedural sound contains PCM samples")
	scene._start_battle(false)
	_expect(scene.battle_world is BattleWorld2D, "battle uses the responsive 2.5D renderer")
	_expect(scene.card_buttons.size() == 4, "battle HUD always exposes a four-card hand")
	var initial_time: float = scene.simulation.time_left
	scene._process(1.0)
	_expect(is_equal_approx(scene.simulation.time_left, initial_time), "battle countdown freezes the simulation")
	scene.battle_intro_time = 0.0
	scene._process(0.1)
	_expect(scene.simulation.time_left < initial_time, "battle starts after the countdown")
	scene._select_card("guardian")
	scene._select_card("guardian")
	_expect(scene.selected_card.is_empty(), "tapping the selected card again cancels targeting")
	scene._select_card("fireball")
	_expect("vise une zone ennemie" in scene.hint_label.text, "spell selection explains enemy targeting")
	_expect(not scene._deployment_error("guardian", Vector2(210.0, 300.0)).is_empty(), "unit targeting rejects the enemy half")
	_expect(scene._deployment_error("guardian", Vector2(210.0, 800.0)).is_empty(), "unit targeting accepts the allied half")
	_expect(not scene._deployment_error("fireball", Vector2(210.0, 800.0)).is_empty(), "spell targeting rejects the allied half")
	_expect(scene._deployment_error("fireball", Vector2(210.0, 300.0)).is_empty(), "spell targeting accepts the enemy half")
	_expect(scene.next_card_preview.get_meta("card_id") == scene.simulation.get_next_card(BattleSim.PLAYER), "HUD renders the next card preview")
	var guardian_button: Button = scene.card_buttons.guardian
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = guardian_button.size * 0.5
	scene._on_card_button_input(press, "guardian", guardian_button)
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.position = scene.drag_candidate_start + Vector2(30.0, -40.0)
	scene._input(motion)
	_expect(scene.drag_active and scene.battle_world.preview_card == "guardian", "dragging a card creates its animated arena preview")
	var allied_local: Vector2 = scene.battle_world.arena_rect.position + scene.battle_world.arena_rect.size * Vector2(0.25, 0.75)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = scene.battle_world.get_global_transform_with_canvas() * allied_local
	scene._input(release)
	_expect(scene.simulation.units.size() == 1 and scene.simulation.units[0].card_id == "guardian", "drag release deploys the selected card on the valid lane")
	_expect(not scene.drag_active and scene.battle_world.preview_card.is_empty(), "drag state clears after deployment")
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


func _test_motion_and_projectile_events() -> void:
	var movement := BattleSim.new(27)
	movement.energy[BattleSim.PLAYER] = 10.0
	movement.play_card(BattleSim.PLAYER, "guardian", 0)
	var walker: Dictionary = movement.units[0]
	var initial_y: float = walker.y
	movement.step(0.1)
	_expect(bool(walker.moving) and walker.y < initial_y, "advancing units expose visible movement state")
	_expect(float(walker.walk_phase) > 0.0, "advancing units progress their walk animation phase")

	var combat := BattleSim.new(28)
	combat.energy = [10.0, 10.0]
	combat.play_card(BattleSim.PLAYER, "ranger", 0)
	combat.play_card(BattleSim.ENEMY, "guardian", 0)
	combat.units[0].y = 600.0
	combat.units[1].y = 500.0
	combat.units[0].attack_timer = 0.0
	combat.units[1].attack_timer = 10.0
	var target_hp: float = combat.units[1].hp
	combat.step(0.1)
	var ranged_hits := combat.events.filter(func(event: Dictionary) -> bool: return event.type == "hit" and bool(event.get("ranged", false)))
	_expect(ranged_hits.size() == 1, "ranged unit attacks emit a projectile event")
	_expect(ranged_hits[0].has("source_state") and ranged_hits[0].has("target_state"), "projectile events preserve positions after defeated units are removed")
	_expect(combat.units[1].hp == target_hp and combat.projectiles.size() == 1, "ranged damage is deferred while the projectile travels")
	for index in range(10):
		combat.step(0.1)
	var impacts := combat.events.filter(func(event: Dictionary) -> bool: return event.type == "projectile_impact")
	_expect(combat.units[1].hp < target_hp and impacts.size() >= 1, "ranged damage is applied exactly when the projectile arrives")

	var miss := BattleSim.new(30)
	miss.energy = [10.0, 10.0]
	miss.play_card(BattleSim.PLAYER, "ranger", 0)
	miss.play_card(BattleSim.ENEMY, "guardian", 0)
	miss.units[0].y = 600.0
	miss.units[1].y = 500.0
	miss.units[0].attack_timer = 0.0
	miss.units[1].attack_timer = 10.0
	miss.step(0.1)
	miss.units[1].hp = 0.0
	for index in range(10):
		miss.step(0.1)
	var dissipated := miss.events.filter(func(event: Dictionary) -> bool: return event.type == "projectile_dissipated")
	_expect(dissipated.size() == 1, "a projectile dissipates harmlessly when its target dies before impact")

	var objective := BattleSim.new(29)
	objective.energy[BattleSim.PLAYER] = 10.0
	objective.play_card(BattleSim.PLAYER, "ranger", 0)
	objective.units[0].y = 360.0
	objective.units[0].attack_timer = 0.0
	objective.step(0.1)
	var objective_hits := objective.events.filter(func(event: Dictionary) -> bool: return event.type == "objective_hit")
	_expect(objective_hits.size() == 1 and bool(objective_hits[0].ranged), "ranged attacks against towers remain visible")
	_expect(objective_hits[0].has("source") and objective_hits[0].card == "ranger", "objective events identify the rig that must animate")


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


func _test_core_defends_after_breach() -> void:
	var simulation := BattleSim.new(26)
	_expect(not simulation.is_core_active(BattleSim.PLAYER), "central fortress starts inactive")
	simulation.towers[BattleSim.PLAYER].lanes[0] = 0.0
	_expect(simulation.is_core_active(BattleSim.PLAYER), "destroying a lane tower activates the central fortress")
	simulation.energy[BattleSim.ENEMY] = 10.0
	simulation.play_card(BattleSim.ENEMY, "guardian", 0)
	var unit: Dictionary = simulation.units[0]
	unit.y = 820.0
	var initial_hp: float = unit.hp
	simulation.step(0.1)
	_expect(unit.hp == initial_hp and simulation.projectiles.size() == 1, "central fortress launches a projectile before applying damage")
	for index in range(10):
		simulation.step(0.1)
	_expect(unit.hp < initial_hp, "active central fortress damages on projectile impact")
	var shots := simulation.events.filter(func(event: Dictionary) -> bool: return event.type == "core_shot")
	_expect(shots.size() == 1, "central fortress emits a projectile event")


func _test_bot_matches_finish() -> void:
	for match_index in range(20):
		var simulation := BattleSim.new(1000 + match_index, {}, {}, true)
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
