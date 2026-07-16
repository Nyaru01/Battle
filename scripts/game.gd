extends Node

const BattleWorldScript := preload("res://scripts/visual/battle_world_3d.gd")
const CARD_ART := preload("res://assets/card-art-v2.png")
const CARD_ART_V4 := preload("res://assets/card-art-v4.png")
const SAVE_PATH := "user://profile.json"
const DIFFICULTY_NAMES := ["INITIATION", "TACTIQUE", "EXPERT"]
const CARD_QUADRANTS := {
	"guardian": Vector2i(0, 0), "ranger": Vector2i(1, 0),
	"colossus": Vector2i(0, 1), "fireball": Vector2i(1, 1),
	"duelist": Vector2i(0, 0), "alchemist": Vector2i(1, 0),
	"bulwark": Vector2i(0, 1), "frost": Vector2i(1, 1),
}
const V4_CARD_IDS := ["duelist", "alchemist", "bulwark", "frost"]

enum ScreenState { MENU, COLLECTION, BATTLE, RESULT }

var state := ScreenState.MENU
var simulation: BattleSim
var opponent: BattleAI
var selected_card := ""
var selected_difficulty := 1
var sound_enabled := true
var haptics_enabled := true
var profile := BattleProgression.default_profile()
var last_reward: Dictionary = {}
var tutorial: BattleTutorial
var battle_paused := false
var battle_intro_time := 0.0
var last_intro_count := 4
var event_cursor := 0
var result_shown := false

var ui_layer: CanvasLayer
var ui_root: Control
var pause_layer: CanvasLayer
var time_label: Label
var energy_label: Label
var energy_bar: ProgressBar
var core_label: Label
var hint_label: Label
var tutorial_label: Label
var next_card_preview: PanelContainer
var next_card_label: Label
var card_buttons: Dictionary = {}
var arena_container: SubViewportContainer
var arena_viewport: SubViewport
var battle_world: BattleWorld3D
var hovered_lane := -1

var sfx_bank: Dictionary = {}
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_player_index := 0
var last_hit_sound_msec := 0


func _ready() -> void:
	_load_profile()
	_setup_audio()
	_build_menu()


func _process(delta: float) -> void:
	if state != ScreenState.BATTLE or simulation == null:
		return
	if not battle_paused:
		if battle_intro_time > 0.0:
			battle_intro_time = maxf(0.0, battle_intro_time - delta)
			var count := ceili(battle_intro_time)
			if count > 0 and count < last_intro_count:
				last_intro_count = count
				_play_sfx("countdown")
			if battle_intro_time <= 0.0:
				_play_sfx("battle_start")
		else:
			opponent.update(delta, simulation)
			simulation.step(delta)
	_consume_battle_events()
	if battle_world:
		battle_world.sync(simulation)
	_update_hud()
	if simulation.finished and not result_shown:
		result_shown = true
		call_deferred("_show_result")


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == ScreenState.BATTLE and not battle_paused:
		call_deferred("_pause_battle")


func _build_menu() -> void:
	_clear_pause_overlay()
	_clear_ui()
	state = ScreenState.MENU
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	ui_root = _screen_root(Color("10283a"))
	var safe := _safe_margin()
	ui_root.add_child(safe)
	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 16)
	safe.add_child(layout)

	var crest := Label.new()
	crest.text = "♛"
	crest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crest.add_theme_font_size_override("font_size", 72)
	crest.add_theme_color_override("font_color", Color("ffd66b"))
	layout.add_child(crest)
	var title := _title_label("BATTLE", 56, Color("7be2ff"))
	layout.add_child(title)
	var subtitle := _title_label("CHRONIQUES DE L’ARÈNE", 18, Color("bed8e5"))
	layout.add_child(subtitle)

	var profile_panel := PanelContainer.new()
	profile_panel.add_theme_stylebox_override("panel", _panel_style(Color("173d50"), Color("3e7185"), 18))
	profile_panel.custom_minimum_size = Vector2(0, 84)
	var profile_row := HBoxContainer.new()
	profile_row.alignment = BoxContainer.ALIGNMENT_CENTER
	profile_row.add_theme_constant_override("separation", 28)
	profile_panel.add_child(profile_row)
	profile_row.add_child(_stat_label("NIVEAU", str(profile.level), Color("7be2ff")))
	profile_row.add_child(_stat_label("VICTOIRES", str(profile.wins), Color("77e58b")))
	profile_row.add_child(_stat_label("ÉCLATS", str(profile.coins), Color("ffd66b")))
	layout.add_child(profile_panel)

	var mode := _title_label("DUEL CONTRE IA", 23, Color("fff0b5"))
	mode.add_theme_constant_override("outline_size", 5)
	mode.add_theme_color_override("font_outline_color", Color("65441c"))
	layout.add_child(mode)
	var difficulty := HBoxContainer.new()
	difficulty.add_theme_constant_override("separation", 8)
	layout.add_child(difficulty)
	for index in range(3):
		var choice := Button.new()
		choice.text = DIFFICULTY_NAMES[index]
		choice.toggle_mode = true
		choice.button_pressed = selected_difficulty == index
		choice.custom_minimum_size = Vector2(0, 52)
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_apply_button_theme(choice, "gold" if selected_difficulty == index else "secondary", 15)
		choice.pressed.connect(_select_difficulty.bind(index))
		difficulty.add_child(choice)

	var start := Button.new()
	start.text = "⚔  COMBAT IA"
	start.custom_minimum_size = Vector2(0, 86)
	_apply_button_theme(start, "primary", 29)
	start.pressed.connect(_start_battle)
	layout.add_child(start)
	var secondary := HBoxContainer.new()
	secondary.add_theme_constant_override("separation", 10)
	layout.add_child(secondary)
	var training := Button.new()
	training.text = "APPRENDRE"
	training.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	training.custom_minimum_size.y = 58
	_apply_button_theme(training, "secondary", 17)
	training.pressed.connect(_start_tutorial)
	secondary.add_child(training)
	var collection := Button.new()
	collection.text = "COLLECTION"
	collection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection.custom_minimum_size.y = 58
	_apply_button_theme(collection, "secondary", 17)
	collection.pressed.connect(_build_collection)
	secondary.add_child(collection)

	var settings := HBoxContainer.new()
	settings.alignment = BoxContainer.ALIGNMENT_CENTER
	settings.add_theme_constant_override("separation", 28)
	layout.add_child(settings)
	var sound_toggle := CheckButton.new()
	sound_toggle.text = "SONS"
	sound_toggle.button_pressed = sound_enabled
	sound_toggle.toggled.connect(_toggle_sound)
	settings.add_child(sound_toggle)
	var haptics_toggle := CheckButton.new()
	haptics_toggle.text = "VIBRATIONS"
	haptics_toggle.button_pressed = haptics_enabled
	haptics_toggle.toggled.connect(_toggle_haptics)
	settings.add_child(haptics_toggle)
	var version := _title_label("v0.31 • VERTICAL SLICE 3D • HORS LIGNE", 13, Color("7599aa"))
	layout.add_child(version)


func _build_collection() -> void:
	_clear_pause_overlay()
	_clear_ui()
	state = ScreenState.COLLECTION
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	ui_root = _screen_root(Color("10283a"))
	var safe := _safe_margin()
	ui_root.add_child(safe)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	safe.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var back := Button.new()
	back.text = "‹"
	back.custom_minimum_size = Vector2(58, 54)
	_apply_button_theme(back, "secondary", 32)
	back.pressed.connect(_build_menu)
	header.add_child(back)
	var title := _title_label("COLLECTION", 34, Color("7be2ff"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var coins := _title_label("◆ %d" % profile.coins, 21, Color("ffd66b"))
	coins.custom_minimum_size.x = 100
	header.add_child(coins)
	var description := _title_label("Améliore tes cartes et prépare ton escouade", 16, Color("aec9d5"))
	layout.add_child(description)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	for card_id in BattleSim.DEFAULT_DECK:
		grid.add_child(_collection_card(card_id))


func _collection_card(card_id: String) -> Control:
	var level: int = profile.card_levels[card_id]
	var card: Dictionary = BattleSim.scaled_card(BattleSim.CARDS[card_id], level)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 278)
	panel.add_theme_stylebox_override("panel", _card_panel_style(card_id, false, false))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	margin.add_child(layout)
	var art := TextureRect.new()
	art.texture = _card_texture(card_id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.custom_minimum_size.y = 112
	layout.add_child(art)
	var name := _title_label(String(card.name), 20, Color.WHITE)
	layout.add_child(name)
	var stats := _title_label("Niv. %d  •  %d énergie" % [level, int(card.cost)], 14, Color("f4a6ff"))
	layout.add_child(stats)
	var details := Label.new()
	details.text = _card_details(card)
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.custom_minimum_size.y = 42
	details.add_theme_font_size_override("font_size", 13)
	details.add_theme_color_override("font_color", Color("c2d6df"))
	layout.add_child(details)
	var upgrade := Button.new()
	upgrade.custom_minimum_size.y = 44
	if level >= BattleProgression.MAX_CARD_LEVEL:
		upgrade.text = "NIVEAU MAX"
		upgrade.disabled = true
	else:
		var cost := BattleProgression.card_upgrade_cost(level)
		upgrade.text = "AMÉLIORER  ◆ %d" % cost
		upgrade.disabled = profile.coins < cost
		upgrade.pressed.connect(_upgrade_card.bind(card_id))
	_apply_button_theme(upgrade, "gold", 14)
	layout.add_child(upgrade)
	return panel


func _start_battle(randomize_opening: bool = true, keep_tutorial: bool = false) -> void:
	_clear_pause_overlay()
	_clear_ui()
	state = ScreenState.BATTLE
	selected_card = ""
	hovered_lane = -1
	battle_intro_time = 3.2
	last_intro_count = 4
	result_shown = false
	event_cursor = 0
	if not keep_tutorial:
		tutorial = null
	var enemy_levels := BattleProgression.opponent_card_levels(profile.card_levels, selected_difficulty)
	simulation = BattleSim.new(Time.get_ticks_msec(), profile.card_levels, enemy_levels, randomize_opening)
	opponent = BattleAI.new(BattleSim.ENEMY, selected_difficulty, Time.get_ticks_msec() + 41)
	_build_battle_screen()
	if battle_world:
		battle_world.sync(simulation)


func _start_tutorial() -> void:
	tutorial = BattleTutorial.new()
	_start_battle(false, true)
	simulation.energy[BattleSim.PLAYER] = 10.0


func _build_battle_screen() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	ui_root = _screen_root(Color("0a1722"))
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 0)
	ui_root.add_child(layout)
	layout.add_child(_build_battle_header())

	arena_container = SubViewportContainer.new()
	arena_container.stretch = true
	arena_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena_container.mouse_filter = Control.MOUSE_FILTER_STOP
	arena_container.gui_input.connect(_on_arena_input)
	layout.add_child(arena_container)
	arena_viewport = SubViewport.new()
	arena_viewport.size = Vector2i(640, 780)
	arena_viewport.transparent_bg = true
	arena_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	arena_viewport.msaa_3d = Viewport.MSAA_4X
	arena_container.add_child(arena_viewport)
	battle_world = BattleWorldScript.new()
	arena_viewport.add_child(battle_world)

	layout.add_child(_build_battle_footer())


func _build_battle_header() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 78
	panel.add_theme_stylebox_override("panel", _panel_style(Color("10283a"), Color("2d6076"), 0))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)
	var enemy := VBoxContainer.new()
	enemy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(enemy)
	var enemy_name := _title_label("IA %s" % DIFFICULTY_NAMES[selected_difficulty], 15, Color("ff8ba0"))
	enemy_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	enemy.add_child(enemy_name)
	core_label = _title_label("♛ 2200   0 — 0   2200 ♛", 17, Color("d8edf5"))
	core_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(core_label)
	time_label = _title_label("3:00", 27, Color.WHITE)
	time_label.custom_minimum_size.x = 76
	row.add_child(time_label)
	var pause := Button.new()
	pause.text = "Ⅱ"
	pause.custom_minimum_size = Vector2(54, 54)
	_apply_button_theme(pause, "secondary", 21)
	pause.pressed.connect(_pause_battle)
	row.add_child(pause)
	return panel


func _build_battle_footer() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 208
	panel.add_theme_stylebox_override("panel", _panel_style(Color("122738"), Color("39667a"), 0))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	margin.add_child(layout)
	hint_label = _title_label("Choisis une carte puis touche une voie", 15, Color("b9dbe9"))
	hint_label.custom_minimum_size.y = 23
	layout.add_child(hint_label)
	tutorial_label = _title_label("", 14, Color("ffe580"))
	tutorial_label.visible = tutorial != null
	layout.add_child(tutorial_label)
	var energy_row := HBoxContainer.new()
	energy_row.add_theme_constant_override("separation", 9)
	layout.add_child(energy_row)
	next_card_preview = PanelContainer.new()
	next_card_preview.custom_minimum_size = Vector2(86, 48)
	next_card_preview.add_theme_stylebox_override("panel", _panel_style(Color("1a3548"), Color("4e7990"), 12))
	next_card_label = _title_label("APRÈS", 12, Color("b7d0db"))
	next_card_preview.add_child(next_card_label)
	energy_row.add_child(next_card_preview)
	energy_label = _title_label("10.0", 18, Color("f5a5ff"))
	energy_label.custom_minimum_size.x = 54
	energy_row.add_child(energy_label)
	energy_bar = ProgressBar.new()
	energy_bar.max_value = BattleSim.MAX_ENERGY
	energy_bar.show_percentage = false
	energy_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	energy_bar.custom_minimum_size.y = 22
	energy_bar.add_theme_stylebox_override("background", _panel_style(Color("281b35"), Color("563b66"), 11))
	energy_bar.add_theme_stylebox_override("fill", _panel_style(Color("d84ee9"), Color("f19cff"), 11))
	energy_row.add_child(energy_bar)
	var hand := HBoxContainer.new()
	hand.add_theme_constant_override("separation", 7)
	layout.add_child(hand)
	card_buttons.clear()
	for card_id in simulation.get_hand(BattleSim.PLAYER):
		var button := _battle_card_button(card_id)
		hand.add_child(button)
		card_buttons[card_id] = button
	return panel


func _battle_card_button(card_id: String) -> Button:
	var card: Dictionary = BattleSim.CARDS[card_id]
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 108)
	button.clip_contents = true
	button.set_meta("card_id", card_id)
	button.add_theme_stylebox_override("normal", _card_panel_style(card_id, false, false))
	button.add_theme_stylebox_override("hover", _card_panel_style(card_id, true, false))
	button.add_theme_stylebox_override("pressed", _card_panel_style(card_id, true, false))
	button.add_theme_stylebox_override("disabled", _card_panel_style(card_id, false, true))
	button.pressed.connect(_select_card.bind(card_id))
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 5)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(layout)
	var art := TextureRect.new()
	art.texture = _card_texture(card_id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(art)
	var caption := _title_label("%s  ◆%d" % [String(card.name), int(card.cost)], 12, Color.WHITE)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(caption)
	return button


func _on_arena_input(event: InputEvent) -> void:
	if selected_card.is_empty() or battle_paused or battle_intro_time > 0.0:
		return
	var local_position := Vector2.ZERO
	var released := false
	if event is InputEventScreenTouch:
		local_position = event.position
		released = event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		local_position = event.position
		released = event.pressed
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		local_position = event.position
	else:
		return
	var world_position := battle_world.screen_to_arena(local_position)
	if is_inf(world_position.x):
		return
	hovered_lane = battle_world.world_lane(world_position)
	battle_world.set_targeting(String(BattleSim.CARDS[selected_card].type), hovered_lane)
	if not released:
		return
	var is_unit := String(BattleSim.CARDS[selected_card].type) == "unit"
	var valid_half := battle_world.is_player_half(world_position) if is_unit else not battle_world.is_player_half(world_position)
	if not valid_half:
		hint_label.text = "Zone interdite : vise la moitié %s" % ("alliée" if is_unit else "ennemie")
		_haptic(55, 0.25)
		return
	if tutorial != null and not tutorial.can_deploy(selected_card, hovered_lane):
		hint_label.text = tutorial.instruction()
		_haptic(55, 0.25)
		return
	var played_card := selected_card
	if simulation.play_card(BattleSim.PLAYER, played_card, hovered_lane):
		if tutorial != null:
			tutorial.deploy_card(played_card, hovered_lane)
		selected_card = ""
		hovered_lane = -1
		battle_world.set_targeting("")
		_rebuild_hand()
		_play_sfx("deploy")
		_haptic(38, 0.38)
	else:
		hint_label.text = "Pas assez d’énergie"
		_haptic(60, 0.28)


func _select_card(card_id: String) -> void:
	if simulation == null or simulation.finished:
		return
	if selected_card == card_id:
		selected_card = ""
		if battle_world:
			battle_world.set_targeting("")
		_update_hud()
		return
	if tutorial != null and not tutorial.can_select(card_id):
		hint_label.text = tutorial.instruction()
		return
	selected_card = card_id
	if tutorial != null:
		tutorial.select_card(card_id)
	var type := String(BattleSim.CARDS[card_id].type)
	hint_label.text = "Pose l’unité dans ta moitié" if type == "unit" else "vise une zone ennemie"
	if battle_world:
		battle_world.set_targeting(type)
	_update_hud()


func _deployment_error(card_id: String, position: Vector2) -> String:
	if not BattleSim.CARDS.has(card_id):
		return "Carte inconnue"
	var is_unit := String(BattleSim.CARDS[card_id].type) == "unit"
	if is_unit and position.y < 590.0:
		return "Déploie les unités dans ta moitié"
	if not is_unit and position.y >= 590.0:
		return "Vise une zone ennemie"
	return ""


func _consume_battle_events() -> void:
	while event_cursor < simulation.events.size():
		var event: Dictionary = simulation.events[event_cursor]
		event_cursor += 1
		match String(event.type):
			"card_played":
				_play_sfx("deploy")
			"hit":
				if not bool(event.get("ranged", false)):
					_play_hit_sfx()
			"tower_shot":
				_play_sfx("tower_shot")
			"core_shot":
				_play_sfx("core_shot")
			"projectile_impact":
				_play_hit_sfx()
				if battle_world:
					battle_world.show_impact(event.projectile, true)
			"projectile_dissipated":
				if battle_world:
					battle_world.show_impact(event.projectile, false)
			"spell":
				_play_sfx(String(event.card))
				if battle_world:
					battle_world.show_spell(String(event.card), int(event.side), int(event.lane))
			"tower_destroyed", "core_destroyed":
				_play_sfx("destroyed")
				_haptic(120, 0.68)


func _update_hud() -> void:
	if not is_instance_valid(time_label) or simulation == null:
		return
	var seconds := ceili(simulation.time_left)
	time_label.text = "%d:%02d" % [seconds / 60, seconds % 60]
	if battle_intro_time > 0.0:
		time_label.text = str(maxi(1, ceili(battle_intro_time)))
	energy_label.text = "%.1f" % simulation.energy[BattleSim.PLAYER]
	energy_bar.value = simulation.energy[BattleSim.PLAYER]
	core_label.text = "♛ %d   %d — %d   %d ♛" % [
		int(simulation.towers[BattleSim.ENEMY].core), simulation.crowns[BattleSim.ENEMY],
		simulation.crowns[BattleSim.PLAYER], int(simulation.towers[BattleSim.PLAYER].core),
	]
	var next_id := simulation.get_next_card(BattleSim.PLAYER)
	next_card_preview.set_meta("card_id", next_id)
	next_card_label.text = "APRÈS\n%s" % String(BattleSim.CARDS[next_id].name)
	for card_id in card_buttons:
		var button: Button = card_buttons[card_id]
		var affordable: bool = float(simulation.energy[BattleSim.PLAYER]) + 0.001 >= float(BattleSim.CARDS[card_id].cost)
		button.disabled = not affordable
		button.add_theme_stylebox_override("normal", _card_panel_style(card_id, selected_card == card_id, false))
	if tutorial != null:
		tutorial_label.visible = true
		tutorial_label.text = tutorial.instruction()
		if tutorial.is_complete():
			tutorial = null
	else:
		tutorial_label.visible = false


func _rebuild_hand() -> void:
	var parent: Node = card_buttons.values()[0].get_parent() if not card_buttons.is_empty() else null
	if parent == null:
		return
	for child in parent.get_children():
		child.queue_free()
	card_buttons.clear()
	for card_id in simulation.get_hand(BattleSim.PLAYER):
		var button := _battle_card_button(card_id)
		parent.add_child(button)
		card_buttons[card_id] = button


func _show_result(award_progression: bool = true) -> void:
	if simulation == null:
		return
	_clear_pause_overlay()
	state = ScreenState.RESULT
	if tutorial == null and award_progression:
		if simulation.winner == BattleSim.PLAYER:
			profile.wins += 1
		elif simulation.winner == BattleSim.ENEMY:
			profile.losses += 1
		else:
			profile.draws += 1
		last_reward = BattleProgression.apply_match_result(profile, simulation.winner, simulation.crowns[BattleSim.PLAYER])
		_save_profile()
	_clear_ui()
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	ui_root = _screen_root(Color("10283a"))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 620)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("17384a"), Color("e7bd58"), 24))
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side_name in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side_name, 28)
	panel.add_child(margin)
	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)
	var text := "ÉGALITÉ" if simulation.winner == -1 else "VICTOIRE" if simulation.winner == BattleSim.PLAYER else "DÉFAITE"
	var color := Color("76e58b") if simulation.winner == BattleSim.PLAYER else Color("ffd66b") if simulation.winner == -1 else Color("ff7d91")
	layout.add_child(_title_label(text, 48, color))
	layout.add_child(_title_label("COURONNES  %d — %d" % [simulation.crowns[0], simulation.crowns[1]], 22, Color.WHITE))
	var reward_text := "Partie de démonstration"
	if tutorial == null and not last_reward.is_empty():
		reward_text = "+%d éclats   +%d XP" % [last_reward.coins, last_reward.xp]
	layout.add_child(_title_label(reward_text, 20, Color("ffd66b")))
	var replay := Button.new()
	replay.text = "REJOUER"
	replay.custom_minimum_size = Vector2(350, 72)
	_apply_button_theme(replay, "primary", 24)
	replay.pressed.connect(_start_battle)
	layout.add_child(replay)
	var menu := Button.new()
	menu.text = "RETOUR À L’ACCUEIL"
	menu.custom_minimum_size = Vector2(350, 58)
	_apply_button_theme(menu, "secondary", 18)
	menu.pressed.connect(_build_menu)
	layout.add_child(menu)


func _pause_battle() -> void:
	if state != ScreenState.BATTLE or battle_paused:
		return
	battle_paused = true
	pause_layer = CanvasLayer.new()
	pause_layer.layer = 20
	add_child(pause_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.06, 0.09, 0.84)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 430)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("17384a"), Color("e7bd58"), 24))
	center.add_child(panel)
	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 22)
	panel.add_child(layout)
	layout.add_child(_title_label("PARTIE EN PAUSE", 32, Color("ffe17b")))
	var resume := Button.new()
	resume.text = "REPRENDRE"
	resume.custom_minimum_size = Vector2(340, 72)
	_apply_button_theme(resume, "primary", 23)
	resume.pressed.connect(_resume_battle)
	layout.add_child(resume)
	var abandon := Button.new()
	abandon.text = "ABANDONNER"
	abandon.custom_minimum_size = Vector2(340, 60)
	_apply_button_theme(abandon, "danger", 18)
	abandon.pressed.connect(_abandon_battle)
	layout.add_child(abandon)


func _resume_battle() -> void:
	_clear_pause_overlay()


func _abandon_battle() -> void:
	if simulation != null and simulation.forfeit(BattleSim.PLAYER):
		_clear_pause_overlay()
		_show_result()


func _clear_pause_overlay() -> void:
	battle_paused = false
	if is_instance_valid(pause_layer):
		pause_layer.queue_free()
	pause_layer = null


func _select_difficulty(index: int) -> void:
	selected_difficulty = index
	_save_profile()
	_build_menu()


func _toggle_sound(enabled: bool) -> void:
	sound_enabled = enabled
	if not enabled:
		for player in sfx_players:
			player.stop()
	_save_profile()


func _toggle_haptics(enabled: bool) -> void:
	haptics_enabled = enabled
	if enabled:
		_haptic(30, 0.3)
	_save_profile()


func _upgrade_card(card_id: String) -> void:
	if BattleProgression.upgrade_card(profile, card_id):
		_save_profile()
		_play_sfx("battle_start")
		_haptic(90, 0.55)
		_build_collection()
	else:
		_haptic(60, 0.22)


func _card_details(card: Dictionary) -> String:
	if card.type == "spell":
		return "%d dégâts%s" % [int(card.damage), " • ralentit" if card.has("slow_duration") else ""]
	return "%d PV • %d dégâts • portée %d" % [int(card.hp), int(card.damage), int(card.range)]


func _screen_root(color: Color) -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(root)
	var background := ColorRect.new()
	background.color = color
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	return root


func _safe_margin() -> MarginContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	return margin


func _title_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _stat_label(caption: String, value: String, color: Color) -> Control:
	var layout := VBoxContainer.new()
	layout.add_child(_title_label(caption, 12, Color("9ebdca")))
	layout.add_child(_title_label(value, 24, color))
	return layout


func _panel_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.34)
	style.shadow_size = 7
	return style


func _apply_button_theme(button: Button, kind: String, font_size: int) -> void:
	var colors := {
		"primary": [Color("168bc1"), Color("55cdf3")],
		"secondary": [Color("1e4558"), Color("4e788b")],
		"gold": [Color("8b6420"), Color("e3b850")],
		"danger": [Color("7c3040"), Color("d45b70")],
	}
	var pair: Array = colors.get(kind, colors.secondary)
	button.add_theme_stylebox_override("normal", _panel_style(pair[0], pair[1], 14))
	button.add_theme_stylebox_override("hover", _panel_style(pair[0].lightened(0.08), pair[1].lightened(0.12), 14))
	button.add_theme_stylebox_override("pressed", _panel_style(pair[0].darkened(0.10), pair[1], 14))
	button.add_theme_stylebox_override("disabled", _panel_style(Color("26333a"), Color("47555b"), 14))
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("74838a"))


func _card_panel_style(card_id: String, selected: bool, disabled: bool) -> StyleBoxFlat:
	var color_map := {
		"guardian": Color("315f72"), "ranger": Color("426d44"), "colossus": Color("6b513e"),
		"fireball": Color("84422c"), "duelist": Color("624577"), "alchemist": Color("82512f"),
		"bulwark": Color("405966"), "frost": Color("36718a"),
	}
	var background: Color = color_map.get(card_id, Color("315366"))
	if disabled:
		background = background.darkened(0.48)
	var border := Color("ffe27b") if selected else background.lightened(0.28)
	var style := _panel_style(background, border, 12)
	style.set_border_width_all(4 if selected else 2)
	return style


func _card_texture(card_id: String) -> AtlasTexture:
	var sheet: Texture2D = CARD_ART_V4 if card_id in V4_CARD_IDS else CARD_ART
	var quadrant: Vector2i = CARD_QUADRANTS[card_id]
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(
		quadrant.x * sheet.get_width() * 0.5,
		quadrant.y * sheet.get_height() * 0.5,
		sheet.get_width() * 0.5,
		sheet.get_height() * 0.5
	)
	return atlas


func _clear_ui() -> void:
	if is_instance_valid(ui_layer):
		ui_layer.free()
	ui_layer = null
	ui_root = null
	battle_world = null
	arena_viewport = null
	arena_container = null
	card_buttons.clear()


func _load_profile() -> void:
	var parsed := BattleProfileStore.load_profile(SAVE_PATH)
	if not parsed.is_empty():
		profile = BattleProgression.normalize(parsed)
	sound_enabled = bool(profile.sound_enabled)
	selected_difficulty = int(profile.difficulty)
	haptics_enabled = bool(profile.haptics_enabled)


func _save_profile() -> void:
	profile.sound_enabled = sound_enabled
	profile.difficulty = selected_difficulty
	profile.haptics_enabled = haptics_enabled
	BattleProfileStore.save_profile(SAVE_PATH, profile)


func _setup_audio() -> void:
	sfx_bank = {
		"countdown": _make_sfx(520.0, 430.0, 0.11, 0.34, 0.0),
		"battle_start": _make_sfx(420.0, 920.0, 0.28, 0.42, 0.0),
		"deploy": _make_sfx(190.0, 80.0, 0.18, 0.48, 0.05),
		"hit": _make_sfx(580.0, 230.0, 0.08, 0.28, 0.18),
		"tower_shot": _make_sfx(820.0, 390.0, 0.12, 0.32, 0.0),
		"core_shot": _make_sfx(1080.0, 510.0, 0.16, 0.40, 0.0),
		"fireball": _make_sfx(170.0, 48.0, 0.34, 0.60, 0.42),
		"frost": _make_sfx(920.0, 1520.0, 0.36, 0.30, 0.06),
		"destroyed": _make_sfx(105.0, 32.0, 0.58, 0.68, 0.36),
	}
	for index in range(8):
		var player := AudioStreamPlayer.new()
		player.volume_db = -8.0
		add_child(player)
		sfx_players.append(player)


func _make_sfx(start_frequency: float, end_frequency: float, duration: float, amplitude: float, noise_mix: float) -> AudioStreamWAV:
	var mix_rate := 22050
	var sample_count := int(duration * mix_rate)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var phase := 0.0
	var noise_state := 1733
	for index in range(sample_count):
		var progress := float(index) / float(sample_count)
		phase += TAU * lerpf(start_frequency, end_frequency, progress) / float(mix_rate)
		noise_state = int(posmod(noise_state * 48271, 2147483647))
		var noise := float(noise_state) / 1073741823.5 - 1.0
		var wave := lerpf(sin(phase), noise, noise_mix)
		var envelope := minf(progress / 0.018, 1.0) * pow(1.0 - progress, 2.0)
		var sample := int(clampf(wave * envelope * amplitude, -1.0, 1.0) * 32767.0)
		data[index * 2] = sample & 0xff
		data[index * 2 + 1] = (sample >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	return stream


func _play_sfx(sound_name: String) -> void:
	if not sound_enabled or not sfx_bank.has(sound_name) or sfx_players.is_empty():
		return
	var player := sfx_players[sfx_player_index]
	sfx_player_index = (sfx_player_index + 1) % sfx_players.size()
	player.stream = sfx_bank[sound_name]
	player.play()


func _play_hit_sfx() -> void:
	var now := Time.get_ticks_msec()
	if now - last_hit_sound_msec >= 65:
		last_hit_sound_msec = now
		_play_sfx("hit")


func _haptic(duration_ms: int, amplitude: float) -> void:
	if haptics_enabled:
		Input.vibrate_handheld(duration_ms, amplitude)
