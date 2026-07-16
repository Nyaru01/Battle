extends Node

const BattleWorldScript := preload("res://scripts/visual/battle_world_2d.gd")
const CARD_ART := preload("res://assets/card-art-v2.png")
const CARD_ART_V4 := preload("res://assets/card-art-v4.png")
const ICON_TEXTURE := preload("res://assets/icon.png")
const ICON_BATTLE := preload("res://assets/ui/icon-battle.png")
const ICON_COLLECTION := preload("res://assets/ui/icon-collection.png")
const ICON_CROWN := preload("res://assets/ui/icon-crown.png")
const ICON_ENERGY := preload("res://assets/ui/icon-energy.png")
const ICON_SHARD := preload("res://assets/ui/icon-shard.png")
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
var result_layer: CanvasLayer
var time_label: Label
var energy_label: Label
var energy_bar: ProgressBar
var core_label: Label
var hint_label: Label
var tutorial_label: Label
var intro_label: Label
var next_card_preview: PanelContainer
var next_card_label: Label
var next_card_art: TextureRect
var card_buttons: Dictionary = {}
var arena_container: Control
var battle_world: BattleWorld2D
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
			if is_instance_valid(intro_label):
				intro_label.visible = battle_intro_time > 0.0
				intro_label.text = str(maxi(1, ceili(battle_intro_time - 0.55))) if battle_intro_time > 0.55 else "À L’ASSAUT !"
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
	_clear_result_overlay()
	_clear_ui()
	state = ScreenState.MENU
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	ui_root = _screen_root(ArenaTheme.NAVY)

	var hero := TextureRect.new()
	hero.texture = ICON_TEXTURE
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hero.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hero.anchor_left = 0.12
	hero.anchor_right = 0.88
	hero.anchor_bottom = 0.55
	hero.offset_left = 0.0
	hero.offset_right = 0.0
	hero.offset_top = 18.0
	hero.offset_bottom = 0.0
	hero.modulate = Color(1.0, 1.0, 1.0, 0.96)
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(hero)

	var fade_texture := GradientTexture2D.new()
	var fade_gradient := Gradient.new()
	fade_gradient.colors = PackedColorArray([Color(0.03, 0.08, 0.14, 0.02), ArenaTheme.NAVY])
	fade_texture.gradient = fade_gradient
	fade_texture.fill_from = Vector2(0.5, 0.0)
	fade_texture.fill_to = Vector2(0.5, 1.0)
	var fade := TextureRect.new()
	fade.texture = fade_texture
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(fade)

	var safe := _safe_margin()
	ui_root.add_child(safe)
	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_BEGIN
	layout.add_theme_constant_override("separation", 8)
	safe.add_child(layout)

	var hero_spacer := Control.new()
	hero_spacer.custom_minimum_size.y = 210
	hero_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(hero_spacer)
	var title := _title_label("BATTLE", 52, ArenaTheme.CYAN)
	layout.add_child(title)
	var subtitle := _title_label("CHRONIQUES DE L’ARÈNE", 17, ArenaTheme.TEXT_MUTED)
	layout.add_child(subtitle)

	var profile_panel := PanelContainer.new()
	profile_panel.add_theme_stylebox_override("panel", ArenaTheme.inset_panel(Color("102f47"), Color("4e9abb"), 16))
	profile_panel.custom_minimum_size = Vector2(0, 68)
	var profile_row := HBoxContainer.new()
	profile_row.alignment = BoxContainer.ALIGNMENT_CENTER
	profile_row.add_theme_constant_override("separation", 24)
	profile_panel.add_child(profile_row)
	profile_row.add_child(_stat_label("NIVEAU", str(profile.level), ArenaTheme.CYAN))
	profile_row.add_child(_stat_label("VICTOIRES", str(profile.wins), ArenaTheme.GREEN))
	profile_row.add_child(_stat_label("ÉCLATS", str(profile.coins), ArenaTheme.GOLD_LIGHT))
	layout.add_child(profile_panel)

	var mode := _title_label("DUEL CONTRE IA", 22, ArenaTheme.GOLD_LIGHT)
	layout.add_child(mode)
	var difficulty := HBoxContainer.new()
	difficulty.add_theme_constant_override("separation", 8)
	layout.add_child(difficulty)
	for index in range(3):
		var choice := Button.new()
		choice.text = DIFFICULTY_NAMES[index]
		choice.toggle_mode = true
		choice.button_pressed = selected_difficulty == index
		choice.custom_minimum_size = Vector2(0, 48)
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_apply_button_theme(choice, "gold" if selected_difficulty == index else "secondary", 14)
		choice.pressed.connect(_select_difficulty.bind(index))
		difficulty.add_child(choice)

	var start := Button.new()
	start.text = "COMBAT IA"
	start.icon = ICON_BATTLE
	start.expand_icon = true
	start.add_theme_constant_override("icon_max_width", 42)
	start.custom_minimum_size = Vector2(0, 72)
	_apply_button_theme(start, "primary", 28)
	start.pressed.connect(_start_battle)
	layout.add_child(start)
	var secondary := HBoxContainer.new()
	secondary.add_theme_constant_override("separation", 10)
	layout.add_child(secondary)
	var training := Button.new()
	training.text = "APPRENDRE"
	training.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	training.custom_minimum_size.y = 50
	_apply_button_theme(training, "secondary", 16)
	training.pressed.connect(_start_tutorial)
	secondary.add_child(training)
	var collection := Button.new()
	collection.text = "COLLECTION"
	collection.icon = ICON_COLLECTION
	collection.expand_icon = true
	collection.add_theme_constant_override("icon_max_width", 28)
	collection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection.custom_minimum_size.y = 50
	_apply_button_theme(collection, "secondary", 16)
	collection.pressed.connect(_build_collection)
	secondary.add_child(collection)

	var settings := HBoxContainer.new()
	settings.alignment = BoxContainer.ALIGNMENT_CENTER
	settings.add_theme_constant_override("separation", 22)
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
	var version := _title_label("v0.32 • ARÈNE 2,5D • HORS LIGNE", 12, Color("7599aa"))
	layout.add_child(version)


func _build_collection() -> void:
	_clear_pause_overlay()
	_clear_result_overlay()
	_clear_ui()
	state = ScreenState.COLLECTION
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	ui_root = _screen_root(ArenaTheme.NAVY)
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
	var title := _title_label("COLLECTION", 34, ArenaTheme.CYAN)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var currency := HBoxContainer.new()
	currency.alignment = BoxContainer.ALIGNMENT_CENTER
	currency.custom_minimum_size.x = 112
	var shard := TextureRect.new()
	shard.texture = ICON_SHARD
	shard.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shard.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shard.custom_minimum_size = Vector2(30, 30)
	currency.add_child(shard)
	var coins := _title_label(str(profile.coins), 21, ArenaTheme.GOLD_LIGHT)
	currency.add_child(coins)
	header.add_child(currency)
	var description := _title_label("Améliore tes cartes et prépare ton escouade", 16, ArenaTheme.TEXT_MUTED)
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
	panel.custom_minimum_size = Vector2(0, 270)
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
	var name := _title_label(String(card.name), 20, ArenaTheme.TEXT)
	layout.add_child(name)
	var stats := _title_label("Niv. %d  •  %d énergie" % [level, int(card.cost)], 14, Color("f4a6ff"))
	layout.add_child(stats)
	var details := Label.new()
	details.text = _card_details(card)
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.custom_minimum_size.y = 42
	details.add_theme_font_size_override("font_size", 13)
	ArenaTheme.apply_body(details, 13, Color("d5e5ec"))
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
	_clear_result_overlay()
	_clear_ui()
	state = ScreenState.BATTLE
	selected_card = ""
	hovered_lane = -1
	battle_intro_time = 3.55
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
	ui_root = _screen_root(ArenaTheme.NAVY)
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 0)
	ui_root.add_child(layout)
	layout.add_child(_build_battle_header())

	arena_container = PanelContainer.new()
	arena_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena_container.add_theme_stylebox_override("panel", ArenaTheme.panel(Color("06111c"), Color("29627a"), 0, 2, 0))
	layout.add_child(arena_container)
	battle_world = BattleWorldScript.new()
	battle_world.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_world.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_world.gui_input.connect(_on_arena_input)
	arena_container.add_child(battle_world)

	intro_label = _title_label("3", 72, Color.WHITE)
	intro_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	intro_label.position = Vector2(-132, -70)
	intro_label.size = Vector2(264, 140)
	intro_label.add_theme_stylebox_override("normal", ArenaTheme.panel(Color(0.02, 0.06, 0.10, 0.86), ArenaTheme.GOLD_LIGHT, 70, 5, 12))
	intro_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_world.add_child(intro_label)

	layout.add_child(_build_battle_footer())


func _build_battle_header() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 70
	panel.add_theme_stylebox_override("panel", ArenaTheme.panel(Color("0d2639"), Color("3e819e"), 0, 2, 4))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	var enemy := VBoxContainer.new()
	enemy.custom_minimum_size.x = 94
	enemy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(enemy)
	var enemy_caption := _title_label("ADVERSAIRE", 10, ArenaTheme.TEXT_MUTED)
	enemy_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	enemy.add_child(enemy_caption)
	var enemy_name := _title_label("IA %s" % DIFFICULTY_NAMES[selected_difficulty], 14, Color("ff8296"))
	enemy_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	enemy.add_child(enemy_name)
	var crown := TextureRect.new()
	crown.texture = ICON_CROWN
	crown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crown.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crown.custom_minimum_size = Vector2(28, 28)
	row.add_child(crown)
	core_label = _title_label("2200  0 — 0  2200", 16, ArenaTheme.TEXT)
	core_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(core_label)
	time_label = _title_label("3:00", 25, Color.WHITE)
	time_label.custom_minimum_size.x = 64
	row.add_child(time_label)
	var pause := Button.new()
	pause.text = "Ⅱ"
	pause.custom_minimum_size = Vector2(48, 48)
	_apply_button_theme(pause, "secondary", 19)
	pause.pressed.connect(_pause_battle)
	row.add_child(pause)
	return panel


func _build_battle_footer() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 196
	panel.add_theme_stylebox_override("panel", ArenaTheme.panel(Color("0e2435"), Color("3e7891"), 0, 2, 0))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 4)
	margin.add_child(layout)
	hint_label = _title_label("Choisis une carte puis touche une voie", 14, ArenaTheme.TEXT_MUTED)
	hint_label.custom_minimum_size.y = 20
	layout.add_child(hint_label)
	tutorial_label = _title_label("", 13, ArenaTheme.GOLD_LIGHT)
	tutorial_label.visible = tutorial != null
	layout.add_child(tutorial_label)
	var energy_row := HBoxContainer.new()
	energy_row.add_theme_constant_override("separation", 6)
	layout.add_child(energy_row)
	next_card_preview = PanelContainer.new()
	next_card_preview.custom_minimum_size = Vector2(70, 48)
	next_card_preview.add_theme_stylebox_override("panel", ArenaTheme.inset_panel(Color("142f42"), Color("4e8096"), 11))
	var next_layout := VBoxContainer.new()
	next_layout.add_theme_constant_override("separation", 0)
	next_card_preview.add_child(next_layout)
	next_card_art = TextureRect.new()
	next_card_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	next_card_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	next_card_art.custom_minimum_size.y = 26
	next_card_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_layout.add_child(next_card_art)
	next_card_label = _title_label("APRÈS", 9, ArenaTheme.TEXT_MUTED)
	next_layout.add_child(next_card_label)
	energy_row.add_child(next_card_preview)
	var energy_icon := TextureRect.new()
	energy_icon.texture = ICON_ENERGY
	energy_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	energy_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	energy_icon.custom_minimum_size = Vector2(28, 28)
	energy_row.add_child(energy_icon)
	energy_label = _title_label("10", 18, Color("f5a5ff"))
	energy_label.custom_minimum_size.x = 34
	energy_row.add_child(energy_label)
	energy_bar = ProgressBar.new()
	energy_bar.max_value = BattleSim.MAX_ENERGY
	energy_bar.show_percentage = false
	energy_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	energy_bar.custom_minimum_size.y = 20
	energy_bar.add_theme_stylebox_override("background", ArenaTheme.panel(Color("281b35"), Color("654276"), 10, 2, 1))
	energy_bar.add_theme_stylebox_override("fill", ArenaTheme.panel(ArenaTheme.MAGENTA, Color("f4a3ff"), 10, 2, 1))
	energy_row.add_child(energy_bar)
	var hand := HBoxContainer.new()
	hand.add_theme_constant_override("separation", 6)
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
	button.custom_minimum_size = Vector2(0, 104)
	button.clip_contents = true
	button.set_meta("card_id", card_id)
	button.add_theme_stylebox_override("normal", _card_panel_style(card_id, false, false))
	button.add_theme_stylebox_override("hover", _card_panel_style(card_id, true, false))
	button.add_theme_stylebox_override("pressed", _card_panel_style(card_id, true, false))
	button.add_theme_stylebox_override("disabled", _card_panel_style(card_id, false, true))
	button.pressed.connect(_select_card.bind(card_id))
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)
	layout.add_theme_constant_override("separation", 1)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(layout)
	var art := TextureRect.new()
	art.texture = _card_texture(card_id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(art)
	var caption := _title_label(String(card.name), 11, Color.WHITE)
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(caption)
	var cost_badge := Label.new()
	cost_badge.text = str(int(card.cost))
	cost_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_badge.position = Vector2(4, 4)
	cost_badge.size = Vector2(30, 30)
	cost_badge.add_theme_stylebox_override("normal", ArenaTheme.badge())
	ArenaTheme.apply_heading(cost_badge, 16, Color.WHITE)
	cost_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(cost_badge)
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
	var sim_position := battle_world.to_sim_position(local_position)
	if is_inf(sim_position.x):
		return
	hovered_lane = battle_world.lane_at(sim_position)
	battle_world.set_targeting(String(BattleSim.CARDS[selected_card].type), hovered_lane)
	if not released:
		return
	var is_unit := String(BattleSim.CARDS[selected_card].type) == "unit"
	var valid_half := battle_world.is_player_half(sim_position) if is_unit else not battle_world.is_player_half(sim_position)
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
	if is_instance_valid(intro_label):
		intro_label.visible = battle_intro_time > 0.0
		intro_label.text = str(maxi(1, ceili(battle_intro_time - 0.55))) if battle_intro_time > 0.55 else "À L’ASSAUT !"
	var seconds := ceili(simulation.time_left)
	time_label.text = "%d:%02d" % [seconds / 60, seconds % 60]
	energy_label.text = str(int(floor(float(simulation.energy[BattleSim.PLAYER]))))
	energy_bar.value = simulation.energy[BattleSim.PLAYER]
	core_label.text = "%d  %d — %d  %d" % [
		int(simulation.towers[BattleSim.ENEMY].core), simulation.crowns[BattleSim.ENEMY],
		simulation.crowns[BattleSim.PLAYER], int(simulation.towers[BattleSim.PLAYER].core),
	]
	var next_id := simulation.get_next_card(BattleSim.PLAYER)
	next_card_preview.set_meta("card_id", next_id)
	next_card_art.texture = _card_texture(next_id)
	next_card_label.text = "APRÈS • %s" % String(BattleSim.CARDS[next_id].name)
	for card_id in card_buttons:
		var button: Button = card_buttons[card_id]
		var affordable: bool = float(simulation.energy[BattleSim.PLAYER]) + 0.001 >= float(BattleSim.CARDS[card_id].cost)
		button.disabled = not affordable
		button.add_theme_stylebox_override("normal", _card_panel_style(card_id, selected_card == card_id, false))
		button.pivot_offset = button.size * 0.5
		button.scale = Vector2(1.035, 1.035) if selected_card == card_id else Vector2.ONE
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
	_clear_result_overlay()
	result_layer = CanvasLayer.new()
	result_layer.layer = 30
	add_child(result_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = ArenaTheme.root_theme()
	result_layer.add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.035, 0.06, 0.80)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 510)
	panel.add_theme_stylebox_override("panel", ArenaTheme.panel(Color("102f47"), ArenaTheme.GOLD_LIGHT, 24, 5, 16))
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side_name in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side_name, 24)
	panel.add_child(margin)
	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)
	var crown := TextureRect.new()
	crown.texture = ICON_CROWN
	crown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crown.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crown.custom_minimum_size = Vector2(0, 82)
	layout.add_child(crown)
	var text := "ÉGALITÉ" if simulation.winner == -1 else "VICTOIRE" if simulation.winner == BattleSim.PLAYER else "DÉFAITE"
	var color := ArenaTheme.GREEN if simulation.winner == BattleSim.PLAYER else ArenaTheme.GOLD_LIGHT if simulation.winner == -1 else Color("ff7d91")
	layout.add_child(_title_label(text, 48, color))
	layout.add_child(_title_label("COURONNES  %d — %d" % [simulation.crowns[BattleSim.PLAYER], simulation.crowns[BattleSim.ENEMY]], 22, Color.WHITE))
	var reward_text := "Partie de démonstration"
	if tutorial == null and not last_reward.is_empty():
		reward_text = "+%d éclats   +%d XP" % [last_reward.coins, last_reward.xp]
	layout.add_child(_title_label(reward_text, 20, ArenaTheme.GOLD_LIGHT))
	layout.add_child(_title_label("NIVEAU %d  •  %d/%d XP" % [profile.level, profile.xp, BattleProgression.xp_to_next(profile.level)], 14, ArenaTheme.TEXT_MUTED))
	var replay := Button.new()
	replay.text = "REJOUER"
	replay.icon = ICON_BATTLE
	replay.expand_icon = true
	replay.add_theme_constant_override("icon_max_width", 34)
	replay.custom_minimum_size = Vector2(350, 66)
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
	root.theme = ArenaTheme.root_theme()
	pause_layer.add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.06, 0.09, 0.84)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 400)
	panel.add_theme_stylebox_override("panel", ArenaTheme.panel(Color("102f47"), ArenaTheme.GOLD_LIGHT, 24, 5, 16))
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side_name in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side_name, 26)
	panel.add_child(margin)
	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 22)
	margin.add_child(layout)
	var crown := TextureRect.new()
	crown.texture = ICON_CROWN
	crown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crown.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crown.custom_minimum_size.y = 72
	layout.add_child(crown)
	layout.add_child(_title_label("PARTIE EN PAUSE", 32, ArenaTheme.GOLD_LIGHT))
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


func _clear_result_overlay() -> void:
	if is_instance_valid(result_layer):
		result_layer.queue_free()
	result_layer = null


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
	root.theme = ArenaTheme.root_theme()
	ui_layer.add_child(root)
	var background := ColorRect.new()
	background.color = color
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	return root


func _safe_margin() -> MarginContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var left := 18
	var right := 18
	var top := 18
	var bottom := 18
	var viewport_size := get_viewport().get_visible_rect().size
	var screen_size := Vector2(DisplayServer.screen_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if screen_size.x > 0.0 and screen_size.y > 0.0 and safe.size.x > 0.0 and safe.size.y > 0.0:
		left = maxi(left, roundi(safe.position.x / screen_size.x * viewport_size.x))
		right = maxi(right, roundi((screen_size.x - safe.end.x) / screen_size.x * viewport_size.x))
		top = maxi(top, roundi(safe.position.y / screen_size.y * viewport_size.y))
		bottom = maxi(bottom, roundi((screen_size.y - safe.end.y) / screen_size.y * viewport_size.y))
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


func _title_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ArenaTheme.apply_heading(label, font_size, color)
	return label


func _stat_label(caption: String, value: String, color: Color) -> Control:
	var layout := VBoxContainer.new()
	layout.add_child(_title_label(caption, 11, ArenaTheme.TEXT_MUTED))
	layout.add_child(_title_label(value, 23, color))
	return layout


func _panel_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	return ArenaTheme.panel(background, border, radius)


func _apply_button_theme(button: Button, kind: String, font_size: int) -> void:
	ArenaTheme.apply_button(button, kind, font_size)


func _card_panel_style(card_id: String, selected: bool, disabled: bool) -> StyleBoxFlat:
	return ArenaTheme.card_style(card_id, selected, disabled)


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
	arena_container = null
	intro_label = null
	next_card_art = null
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
