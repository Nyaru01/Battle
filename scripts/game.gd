extends Node

const BattleWorldScript := preload("res://scripts/visual/battle_world_2d.gd")
const APP_ICON := preload("res://assets/v050/ui/app-icon-v050.png")
const UI_ICON_ATLAS := preload("res://assets/v040/ui/ui-icons-v040.png")
const SPELL_ART := preload("res://assets/v040/ui/spell-art-v040.png")
const ICON_HOME := preload("res://assets/v050/ui/icon-home.png")
const ICON_CARDS := preload("res://assets/v050/ui/icon-cards.png")
const ICON_TRAINING := preload("res://assets/v050/ui/icon-training.png")
const ICON_BATTLE := preload("res://assets/v050/ui/icon-battle.png")
const ICON_CROWN := preload("res://assets/v050/ui/icon-crown.png")
const ICON_TIME := preload("res://assets/v050/ui/icon-time.png")
const ICON_AWARD := preload("res://assets/v050/ui/icon-award.png")
const DifficultySheetScript := preload("res://scripts/ui/difficulty_sheet.gd")
const FantasyFrameScript := preload("res://scripts/ui/fantasy_frame.gd")
const SAVE_PATH := "user://profile.json"
const DIFFICULTY_NAMES := ["INITIATION", "TACTIQUE", "EXPERT"]
const ICON_BATTLE_INDEX := 0
const ICON_COLLECTION_INDEX := 1
const ICON_CROWN_INDEX := 2
const ICON_SHARD_INDEX := 3
const ICON_ENERGY_INDEX := 4
const ICON_HOME_INDEX := 5
const ICON_SETTINGS_INDEX := 6
const ICON_SOUND_INDEX := 7

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
var settings_layer: CanvasLayer
var time_label: Label
var energy_label: Label
var energy_mode_label: Label
var energy_bar: EnergySegments
var core_label: Label
var score_label: Label
var hint_label: Label
var tutorial_label: Label
var intro_label: Label
var next_card_preview: PanelContainer
var next_card_label: Label
var next_card_art: CardArtControl
var battle_announcement: BattleAnnouncement
var card_buttons: Dictionary = {}
var card_affordable_state: Dictionary = {}
var ready_card_timers: Dictionary = {}
var arena_container: Control
var battle_world: BattleWorld2D
var hovered_lane := -1
var drag_card_id := ""
var drag_candidate_start := Vector2.ZERO
var drag_active := false
var suppress_card_tap := false
var primary_action_button: Button
var difficulty_sheet: Control
var ui_animation_time := 0.0

var sfx_bank: Dictionary = {}
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_player_index := 0
var last_hit_sound_msec := 0


func _ready() -> void:
	_load_profile()
	_setup_audio()
	_build_menu()


func _process(delta: float) -> void:
	ui_animation_time += delta
	if is_instance_valid(primary_action_button):
		primary_action_button.pivot_offset = primary_action_button.size * 0.5
		var pulse := 1.0 + (sin(ui_animation_time * 2.5) + 1.0) * 0.006
		primary_action_button.scale = Vector2.ONE * pulse
	if state != ScreenState.BATTLE or simulation == null:
		return
	for card_id in ready_card_timers.keys():
		ready_card_timers[card_id] = maxf(0.0, float(ready_card_timers[card_id]) - delta)
		if float(ready_card_timers[card_id]) <= 0.0:
			ready_card_timers.erase(card_id)
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
	_clear_settings_overlay()
	_clear_difficulty_sheet()
	_clear_ui()
	state = ScreenState.MENU
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	ui_root = _screen_root(ArenaTheme.NAVY)
	var stage := LobbyDiorama.new()
	stage.name = "HeroStage"
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(stage)
	var safe := _safe_margin()
	ui_root.add_child(safe)
	var home := Control.new()
	home.name = "HomeLayout"
	safe.add_child(home)

	var header := _build_home_header()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = 70
	home.add_child(header)

	var dock := _build_home_dock()
	dock.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dock.offset_top = -196
	home.add_child(dock)


func _build_home_header() -> Control:
	var panel := Control.new()
	panel.name = "ProfileHeader"
	panel.custom_minimum_size.y = 70
	var frame := FantasyFrameScript.new()
	frame.configure(FantasyFrame.FrameKind.HEADER)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(frame)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 11)
	margin.add_theme_constant_override("margin_right", 11)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	margin.add_child(row)
	var medallion := PanelContainer.new()
	medallion.custom_minimum_size = Vector2(55, 55)
	medallion.add_theme_stylebox_override("panel", ArenaTheme.fantasy_medallion())
	row.add_child(medallion)
	var portrait := TextureRect.new()
	portrait.texture = APP_ICON
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	medallion.add_child(portrait)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 1)
	row.add_child(identity)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	identity.add_child(name_row)
	var player_name := _title_label("CAPITAINE NYARU", 18, ArenaTheme.GOLD_LIGHT)
	player_name.name = "PlayerName"
	player_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	player_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(player_name)
	var wins := HBoxContainer.new()
	wins.add_theme_constant_override("separation", 2)
	name_row.add_child(wins)
	var crown := TextureRect.new()
	crown.texture = ICON_CROWN
	crown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crown.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crown.custom_minimum_size = Vector2(17, 17)
	wins.add_child(crown)
	var victories := _title_label(str(profile.wins), 11, ArenaTheme.CYAN)
	wins.add_child(victories)
	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 6)
	identity.add_child(progress_row)
	var level := _title_label("NIV. %d" % profile.level, 11, Color.WHITE)
	level.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	level.add_theme_stylebox_override("normal", ArenaTheme.fantasy_badge())
	progress_row.add_child(level)
	var xp_bar := ProgressBar.new()
	xp_bar.name = "ExperienceBar"
	xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp_bar.custom_minimum_size.y = 12
	xp_bar.show_percentage = false
	xp_bar.max_value = BattleProgression.xp_to_next(profile.level)
	xp_bar.value = profile.xp
	xp_bar.add_theme_stylebox_override("background", ArenaTheme.panel(Color("030b13"), Color("6b512f"), 6, 2, 0))
	xp_bar.add_theme_stylebox_override("fill", ArenaTheme.panel(Color("28a9dd"), Color("9feaff"), 6, 1, 0))
	progress_row.add_child(xp_bar)
	var wallet := PanelContainer.new()
	wallet.name = "Wallet"
	var wallet_style := ArenaTheme.fantasy_badge()
	wallet_style.set_corner_radius_all(15)
	wallet_style.content_margin_left = 9
	wallet_style.content_margin_right = 9
	wallet.add_theme_stylebox_override("panel", wallet_style)
	var wallet_row := HBoxContainer.new()
	wallet_row.alignment = BoxContainer.ALIGNMENT_CENTER
	wallet_row.add_theme_constant_override("separation", 3)
	wallet.add_child(wallet_row)
	var shard := TextureRect.new()
	shard.texture = _ui_icon(ICON_SHARD_INDEX)
	shard.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shard.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shard.custom_minimum_size = Vector2(25, 25)
	wallet_row.add_child(shard)
	wallet_row.add_child(_title_label(str(profile.coins), 18, ArenaTheme.GOLD_LIGHT))
	row.add_child(wallet)
	return panel


func _build_home_dock() -> Control:
	var dock := Control.new()
	dock.name = "HomeDock"
	dock.custom_minimum_size.y = 196
	var frame := FantasyFrameScript.new()
	frame.configure(FantasyFrame.FrameKind.DOCK)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dock.add_child(frame)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side_name in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side_name, 8)
	dock.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	margin.add_child(layout)
	var start := _build_home_primary_action()
	layout.add_child(start)
	primary_action_button = start
	layout.add_child(_build_home_navigation())
	return dock


func _build_home_primary_action() -> Button:
	var button := Button.new()
	button.name = "CombatButton"
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.custom_minimum_size = Vector2(clampf(get_viewport().get_visible_rect().size.x * 0.72, 310.0, 480.0), 90.0)
	button.tooltip_text = "Choisir la difficulté et lancer un duel"
	button.set_meta("role", "primary_action")
	button.add_theme_stylebox_override("normal", ArenaTheme.fantasy_action())
	button.add_theme_stylebox_override("hover", ArenaTheme.fantasy_action(false, true))
	button.add_theme_stylebox_override("pressed", ArenaTheme.fantasy_action(true))
	button.add_theme_stylebox_override("focus", ArenaTheme.fantasy_action(false, true))
	button.pressed.connect(_show_difficulty_sheet)
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 64
	content.offset_right = -64
	content.offset_top = 16
	content.offset_bottom = -16
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", -5)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)
	var title := _title_label("COMBAT", 25, ArenaTheme.GOLD_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title)
	return button


func _build_home_navigation() -> Control:
	var navigation := HBoxContainer.new()
	navigation.name = "HomeNavigation"
	navigation.custom_minimum_size.y = 74
	navigation.add_theme_constant_override("separation", 2)
	navigation.add_child(_menu_nav_button("ACCUEIL", ICON_HOME, _build_menu, true))
	navigation.add_child(_menu_nav_button("CARTES", ICON_CARDS, _build_collection))
	navigation.add_child(_menu_nav_button("ENTRAÎN.", ICON_TRAINING, _start_tutorial))
	navigation.add_child(_menu_nav_button("RÉGLAGES", _ui_icon(ICON_SETTINGS_INDEX), _show_settings))
	return navigation


func _build_collection() -> void:
	_clear_pause_overlay()
	_clear_result_overlay()
	_clear_settings_overlay()
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
	var header_panel := PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", ArenaTheme.royal_panel(Color("0d315b"), ArenaTheme.CYAN, 21))
	layout.add_child(header_panel)
	var header := HBoxContainer.new()
	header_panel.add_child(header)
	var back := Button.new()
	back.text = "‹"
	back.custom_minimum_size = Vector2(58, 54)
	_apply_button_theme(back, "secondary", 32)
	back.pressed.connect(_build_menu)
	header.add_child(back)
	var title := _title_label("COLLECTION ROYALE", 30, ArenaTheme.CYAN)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var currency := HBoxContainer.new()
	currency.alignment = BoxContainer.ALIGNMENT_CENTER
	currency.custom_minimum_size.x = 112
	var shard := TextureRect.new()
	shard.texture = _ui_icon(ICON_SHARD_INDEX)
	shard.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shard.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shard.custom_minimum_size = Vector2(30, 30)
	currency.add_child(shard)
	var coins := _title_label(str(profile.coins), 21, ArenaTheme.GOLD_LIGHT)
	currency.add_child(coins)
	header.add_child(currency)
	var description := _title_label("AMÉLIORE TES CARTES ET PRÉPARE TON ESCOUADE", 14, ArenaTheme.TEXT_MUTED)
	layout.add_child(description)
	var summary := PanelContainer.new()
	summary.add_theme_stylebox_override("panel", ArenaTheme.inset_panel(Color("102b4c"), Color("356f9f"), 16))
	var summary_row := HBoxContainer.new()
	summary_row.alignment = BoxContainer.ALIGNMENT_CENTER
	summary_row.add_theme_constant_override("separation", 16)
	summary.add_child(summary_row)
	for summary_text in ["8 CARTES", "6 HÉROS", "2 SORTS", "DECK 4+1"]:
		var chip := Label.new()
		chip.text = summary_text
		chip.add_theme_stylebox_override("normal", ArenaTheme.chip(false, ArenaTheme.CYAN))
		ArenaTheme.apply_heading(chip, 11, Color.WHITE)
		summary_row.add_child(chip)
	layout.add_child(summary)
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
	panel.custom_minimum_size = Vector2(0, 310)
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
	var art := CardArtControl.new()
	art.set_card(card_id)
	art.custom_minimum_size.y = 145
	layout.add_child(art)
	var name := _title_label(String(card.name).to_upper(), 19, ArenaTheme.TEXT)
	layout.add_child(name)
	var stats := _title_label("NIV. %d  •  %d ÉLIXIR" % [level, int(card.cost)], 13, Color("f0a1ff"))
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
	_clear_settings_overlay()
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
	arena_container.add_theme_stylebox_override("panel", ArenaTheme.panel(Color("06111c"), Color("2b7aac"), 0, 2, 0))
	layout.add_child(arena_container)
	battle_world = BattleWorldScript.new()
	battle_world.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_world.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_world.gui_input.connect(_on_arena_input)
	arena_container.add_child(battle_world)
	hint_label = _title_label("CHOISIS UNE CARTE PUIS GLISSE-LA DANS L’ARÈNE", 13, Color.WHITE)
	hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint_label.offset_left = 54
	hint_label.offset_right = -54
	hint_label.offset_top = -54
	hint_label.offset_bottom = -12
	hint_label.add_theme_stylebox_override("normal", ArenaTheme.panel(Color(0.02, 0.10, 0.20, 0.88), Color("4c91ba"), 18, 2, 5))
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_world.add_child(hint_label)
	tutorial_label = _title_label("", 13, ArenaTheme.GOLD_LIGHT)
	tutorial_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tutorial_label.offset_left = 45
	tutorial_label.offset_right = -45
	tutorial_label.offset_top = 14
	tutorial_label.offset_bottom = 58
	tutorial_label.add_theme_stylebox_override("normal", ArenaTheme.panel(Color(0.15, 0.09, 0.01, 0.90), ArenaTheme.GOLD, 18, 3, 5))
	tutorial_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_label.visible = tutorial != null
	battle_world.add_child(tutorial_label)
	battle_announcement = BattleAnnouncement.new()
	battle_announcement.set_anchors_preset(Control.PRESET_TOP_WIDE)
	battle_announcement.offset_left = 78
	battle_announcement.offset_right = -78
	battle_announcement.offset_top = 76
	battle_announcement.offset_bottom = 154
	battle_announcement.z_index = 20
	battle_world.add_child(battle_announcement)

	intro_label = _title_label("3", 72, Color.WHITE)
	intro_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	intro_label.position = Vector2(-132, -70)
	intro_label.size = Vector2(264, 140)
	intro_label.add_theme_stylebox_override("normal", ArenaTheme.panel(Color(0.02, 0.06, 0.10, 0.86), ArenaTheme.GOLD_LIGHT, 70, 5, 12))
	intro_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_label.z_index = 30
	battle_world.add_child(intro_label)

	layout.add_child(_build_battle_footer())


func _build_battle_header() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 60
	panel.add_theme_stylebox_override("panel", ArenaTheme.panel(Color("0b294b"), Color("3b8abc"), 0, 2, 4))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	margin.add_child(row)
	var enemy := VBoxContainer.new()
	enemy.custom_minimum_size.x = 105
	enemy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(enemy)
	var enemy_caption := _title_label("ADVERSAIRE", 9, ArenaTheme.TEXT_MUTED)
	enemy_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	enemy.add_child(enemy_caption)
	var enemy_name := _title_label("IA %s" % DIFFICULTY_NAMES[selected_difficulty], 13, Color("ff8798"))
	enemy_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	enemy.add_child(enemy_name)
	var score_stack := VBoxContainer.new()
	score_stack.custom_minimum_size.x = 118
	score_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_stack.add_theme_constant_override("separation", -6)
	row.add_child(score_stack)
	var score_row := HBoxContainer.new()
	score_row.alignment = BoxContainer.ALIGNMENT_CENTER
	score_row.add_theme_constant_override("separation", 5)
	score_stack.add_child(score_row)
	var crown := TextureRect.new()
	crown.texture = ICON_CROWN
	crown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crown.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crown.custom_minimum_size = Vector2(24, 24)
	score_row.add_child(crown)
	score_label = _title_label("0  —  0", 20, ArenaTheme.GOLD_LIGHT)
	score_row.add_child(score_label)
	core_label = _title_label("2200  •  2200", 9, ArenaTheme.TEXT_MUTED)
	score_stack.add_child(core_label)
	var clock := TextureRect.new()
	clock.texture = ICON_TIME
	clock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	clock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	clock.custom_minimum_size = Vector2(22, 22)
	row.add_child(clock)
	time_label = _title_label("3:00", 22, Color.WHITE)
	time_label.custom_minimum_size.x = 57
	row.add_child(time_label)
	var pause := Button.new()
	pause.text = "Ⅱ"
	pause.custom_minimum_size = Vector2(44, 44)
	_apply_button_theme(pause, "secondary", 17)
	pause.pressed.connect(_pause_battle)
	row.add_child(pause)
	return panel


func _build_battle_footer() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 174
	panel.add_theme_stylebox_override("panel", ArenaTheme.panel(Color("0b294b"), Color("3c83af"), 0, 2, 0))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 4)
	margin.add_child(layout)
	var energy_row := HBoxContainer.new()
	energy_row.add_theme_constant_override("separation", 6)
	layout.add_child(energy_row)
	var energy_icon := TextureRect.new()
	energy_icon.texture = _ui_icon(ICON_ENERGY_INDEX)
	energy_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	energy_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	energy_icon.custom_minimum_size = Vector2(30, 30)
	energy_row.add_child(energy_icon)
	energy_label = _title_label("10", 21, Color("f5a5ff"))
	energy_label.custom_minimum_size.x = 30
	energy_row.add_child(energy_label)
	energy_mode_label = _title_label("x1", 13, ArenaTheme.TEXT_MUTED)
	energy_mode_label.custom_minimum_size = Vector2(38, 28)
	energy_mode_label.add_theme_stylebox_override("normal", ArenaTheme.chip(false, ArenaTheme.MAGENTA))
	energy_row.add_child(energy_mode_label)
	energy_bar = EnergySegments.new()
	energy_bar.maximum = BattleSim.MAX_ENERGY
	energy_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	energy_bar.custom_minimum_size.y = 24
	energy_row.add_child(energy_bar)
	next_card_preview = PanelContainer.new()
	next_card_preview.custom_minimum_size = Vector2(66, 50)
	next_card_preview.add_theme_stylebox_override("panel", ArenaTheme.inset_panel(Color("102b49"), Color("4c83a4"), 11))
	var next_layout := VBoxContainer.new()
	next_layout.add_theme_constant_override("separation", -2)
	next_card_preview.add_child(next_layout)
	next_card_art = CardArtControl.new()
	next_card_art.custom_minimum_size.y = 31
	next_layout.add_child(next_card_art)
	next_card_label = _title_label("APRÈS", 8, ArenaTheme.TEXT_MUTED)
	next_layout.add_child(next_card_label)
	energy_row.add_child(next_card_preview)
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
	button.custom_minimum_size = Vector2(0, 108)
	button.clip_contents = true
	button.set_meta("card_id", card_id)
	button.add_theme_stylebox_override("normal", _card_panel_style(card_id, false, false))
	button.add_theme_stylebox_override("hover", _card_panel_style(card_id, true, false))
	button.add_theme_stylebox_override("pressed", _card_panel_style(card_id, true, false))
	button.add_theme_stylebox_override("disabled", _card_panel_style(card_id, false, true))
	button.pressed.connect(_select_card.bind(card_id))
	button.gui_input.connect(_on_card_button_input.bind(card_id, button))
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)
	layout.add_theme_constant_override("separation", 1)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(layout)
	var art := CardArtControl.new()
	art.set_card(card_id)
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(art)
	var caption := _title_label(String(card.name).to_upper(), 10, Color.WHITE)
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(caption)
	var cost_badge := Label.new()
	cost_badge.text = str(int(card.cost))
	cost_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_badge.position = Vector2(5, 5)
	cost_badge.size = Vector2(31, 31)
	cost_badge.add_theme_stylebox_override("normal", ArenaTheme.badge())
	ArenaTheme.apply_heading(cost_badge, 16, Color.WHITE)
	cost_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(cost_badge)
	return button


func _input(event: InputEvent) -> void:
	if is_instance_valid(difficulty_sheet) and event.is_action_pressed("ui_cancel"):
		_clear_difficulty_sheet()
		get_viewport().set_input_as_handled()
		return
	if state != ScreenState.BATTLE or drag_card_id.is_empty() or not is_instance_valid(battle_world):
		return
	var viewport_position := Vector2.ZERO
	var is_motion := false
	var is_release := false
	if event is InputEventScreenDrag:
		viewport_position = event.position
		is_motion = true
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		viewport_position = event.position
		is_motion = true
	elif event is InputEventScreenTouch and not event.pressed:
		viewport_position = event.position
		is_release = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		viewport_position = event.position
		is_release = true
	else:
		return
	if is_motion and not drag_active and viewport_position.distance_to(drag_candidate_start) >= 14.0:
		if selected_card != drag_card_id:
			_select_card(drag_card_id)
		if selected_card != drag_card_id:
			drag_card_id = ""
			return
		drag_active = true
		battle_world.begin_deploy_preview(drag_card_id)
	if drag_active:
		var local_position := battle_world.get_global_transform_with_canvas().affine_inverse() * viewport_position
		battle_world.update_deploy_preview(local_position)
		var sim_position := battle_world.to_sim_position(local_position)
		if not is_inf(sim_position.x):
			hovered_lane = battle_world.lane_at(sim_position)
			battle_world.set_targeting(String(BattleSim.CARDS[drag_card_id].type), hovered_lane)
		if is_release:
			_try_deploy(drag_card_id, local_position)
			battle_world.end_deploy_preview()
			suppress_card_tap = true
			call_deferred("_clear_tap_suppression")
	if is_release:
		drag_card_id = ""
		drag_active = false


func _on_card_button_input(event: InputEvent, card_id: String, button: Button) -> void:
	if battle_paused or battle_intro_time > 0.0 or button.disabled:
		return
	var pressed := false
	var local_position := Vector2.ZERO
	if event is InputEventScreenTouch:
		pressed = event.pressed
		local_position = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = event.pressed
		local_position = event.position
	if pressed:
		drag_card_id = card_id
		drag_candidate_start = button.get_global_transform_with_canvas() * local_position
		drag_active = false


func _clear_tap_suppression() -> void:
	suppress_card_tap = false


func _on_arena_input(event: InputEvent) -> void:
	if selected_card.is_empty() or battle_paused or battle_intro_time > 0.0 or drag_active:
		return
	var local_position := Vector2.ZERO
	var pressed := false
	if event is InputEventScreenTouch:
		local_position = event.position
		pressed = event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		local_position = event.position
		pressed = event.pressed
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		local_position = event.position
	else:
		return
	var sim_position := battle_world.to_sim_position(local_position)
	if is_inf(sim_position.x):
		return
	hovered_lane = battle_world.lane_at(sim_position)
	battle_world.set_targeting(String(BattleSim.CARDS[selected_card].type), hovered_lane)
	if pressed:
		_try_deploy(selected_card, local_position)


func _try_deploy(card_id: String, local_position: Vector2) -> bool:
	if card_id.is_empty() or simulation == null or simulation.finished or battle_paused or battle_intro_time > 0.0:
		return false
	var sim_position := battle_world.to_sim_position(local_position)
	if is_inf(sim_position.x):
		return false
	hovered_lane = battle_world.lane_at(sim_position)
	var is_unit := String(BattleSim.CARDS[card_id].type) == "unit"
	var valid_zone := BattleSim.is_valid_unit_placement(BattleSim.PLAYER, sim_position) if is_unit else not battle_world.is_player_half(sim_position)
	if not valid_zone:
		hint_label.text = "Zone interdite : reste dans la base alliée" if is_unit else "Zone interdite : vise la moitié ennemie"
		_haptic(55, 0.25)
		return false
	if tutorial != null and not tutorial.can_deploy(card_id, hovered_lane):
		hint_label.text = tutorial.instruction()
		_haptic(55, 0.25)
		return false
	var placement := sim_position if is_unit else Vector2(INF, INF)
	if simulation.play_card(BattleSim.PLAYER, card_id, hovered_lane, placement):
		if tutorial != null:
			tutorial.deploy_card(card_id, hovered_lane)
		selected_card = ""
		hovered_lane = -1
		battle_world.set_targeting("")
		battle_world.end_deploy_preview()
		_rebuild_hand()
		_play_sfx("deploy")
		_haptic(38, 0.38)
		return true
	hint_label.text = "Pas assez d’énergie"
	_haptic(60, 0.28)
	return false


func _select_card(card_id: String) -> void:
	if suppress_card_tap:
		return
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
	var card_name := String(BattleSim.CARDS[card_id].name).to_upper()
	hint_label.text = "%s • Pose-la où tu veux dans ta base" % card_name if type == "unit" else "%s • vise une zone ennemie" % card_name
	if battle_world:
		battle_world.set_targeting(type)
	_update_hud()


func _deployment_error(card_id: String, position: Vector2) -> String:
	if not BattleSim.CARDS.has(card_id):
		return "Carte inconnue"
	var is_unit := String(BattleSim.CARDS[card_id].type) == "unit"
	if is_unit and not BattleSim.is_valid_unit_placement(BattleSim.PLAYER, position):
		return "Déploie les unités dans ta base"
	if not is_unit and position.y >= 590.0:
		return "Vise une zone ennemie"
	return ""


func _consume_battle_events() -> void:
	while event_cursor < simulation.events.size():
		var event: Dictionary = simulation.events[event_cursor]
		event_cursor += 1
		if battle_world:
			battle_world.present_event(event)
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
			"spell":
				_play_sfx(String(event.card))
			"objective_hit":
				if not bool(event.get("ranged", false)):
					_play_hit_sfx()
			"tower_destroyed", "core_destroyed":
				_play_sfx("destroyed")
				_haptic(120, 0.68)
		_announce_battle_event(event)


func _announce_battle_event(event: Dictionary) -> void:
	var event_type := String(event.get("type", ""))
	match event_type:
		"double_energy_started":
			_show_battle_announcement("ÉNERGIE x2", "LE RYTHME S’ACCÉLÈRE", ArenaTheme.GOLD_LIGHT)
		"overtime_started":
			_show_battle_announcement("MORT SUBITE", "LA PROCHAINE TOUR DÉCIDE", Color("ff7185"), 2.0)
		"tower_destroyed":
			var allied_fell := int(event.get("side", BattleSim.ENEMY)) == BattleSim.PLAYER
			_show_battle_announcement("TOUR ALLIÉE DÉTRUITE" if allied_fell else "TOUR ENNEMIE DÉTRUITE", "CONTRE-ATTAQUE !" if allied_fell else "UNE COURONNE GAGNÉE", Color("ff7185") if allied_fell else ArenaTheme.CYAN)
		"core_destroyed":
			var allied_fell := int(event.get("side", BattleSim.ENEMY)) == BattleSim.PLAYER
			_show_battle_announcement("FORTERESSE DÉTRUITE", "DÉFAITE" if allied_fell else "VICTOIRE ROYALE", Color("ff7185") if allied_fell else ArenaTheme.GOLD_LIGHT, 2.0)


func _show_battle_announcement(title: String, subtitle: String, color: Color, duration := 1.7) -> void:
	if is_instance_valid(battle_announcement):
		battle_announcement.show_message(title, subtitle, color, duration)


func _update_hud() -> void:
	if not is_instance_valid(time_label) or simulation == null:
		return
	if is_instance_valid(intro_label):
		intro_label.visible = battle_intro_time > 0.0
		intro_label.text = str(maxi(1, ceili(battle_intro_time - 0.55))) if battle_intro_time > 0.55 else "À L’ASSAUT !"
	var seconds := ceili(simulation.time_left)
	time_label.text = "%d:%02d" % [seconds / 60, seconds % 60]
	time_label.add_theme_color_override("font_color", ArenaTheme.GOLD_LIGHT if simulation.double_energy else Color.WHITE)
	energy_label.text = str(int(floor(float(simulation.energy[BattleSim.PLAYER]))))
	energy_bar.value = simulation.energy[BattleSim.PLAYER]
	energy_bar.boosted = simulation.double_energy
	energy_mode_label.text = "x2" if simulation.double_energy else "x1"
	energy_mode_label.add_theme_color_override("font_color", ArenaTheme.GOLD_LIGHT if simulation.double_energy else ArenaTheme.TEXT_MUTED)
	score_label.text = "%d  —  %d" % [simulation.crowns[BattleSim.ENEMY], simulation.crowns[BattleSim.PLAYER]]
	core_label.text = "%d  •  %d" % [int(simulation.towers[BattleSim.ENEMY].core), int(simulation.towers[BattleSim.PLAYER].core)]
	var next_id := simulation.get_next_card(BattleSim.PLAYER)
	next_card_preview.set_meta("card_id", next_id)
	next_card_art.set_card(next_id)
	next_card_label.text = "APRÈS  %d" % int(BattleSim.CARDS[next_id].cost)
	for card_id in card_buttons:
		var button: Button = card_buttons[card_id]
		var affordable: bool = float(simulation.energy[BattleSim.PLAYER]) + 0.001 >= float(BattleSim.CARDS[card_id].cost)
		var was_affordable: bool = bool(card_affordable_state.get(card_id, affordable))
		if affordable and not was_affordable:
			ready_card_timers[card_id] = 0.72
		card_affordable_state[card_id] = affordable
		var ready_flash := float(ready_card_timers.get(card_id, 0.0)) > 0.0
		button.disabled = not affordable
		button.add_theme_stylebox_override("normal", _card_panel_style(card_id, selected_card == card_id or ready_flash, false))
		button.pivot_offset = button.size * 0.5
		var selected_scale := 1.065 + sin(ui_animation_time * 6.0) * 0.008
		var ready_scale := 1.0 + sin(ui_animation_time * 14.0) * 0.018
		button.scale = Vector2.ONE * selected_scale if selected_card == card_id else Vector2.ONE * ready_scale if ready_flash else Vector2.ONE
		button.modulate = Color("fff1bd") if ready_flash else Color.WHITE if affordable else Color(0.53, 0.56, 0.62, 0.88)
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
	card_affordable_state.clear()
	ready_card_timers.clear()
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
	panel.add_theme_stylebox_override("panel", ArenaTheme.royal_panel(Color("0d315b"), ArenaTheme.GOLD, 26))
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
	crown.texture = ICON_AWARD
	crown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crown.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crown.custom_minimum_size = Vector2(0, 82)
	layout.add_child(crown)
	var text := "ÉGALITÉ ROYALE" if simulation.winner == -1 else "VICTOIRE ROYALE" if simulation.winner == BattleSim.PLAYER else "DÉFAITE"
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
	replay.icon = _ui_icon(ICON_BATTLE_INDEX)
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
	panel.add_theme_stylebox_override("panel", ArenaTheme.royal_panel(Color("0d315b"), ArenaTheme.GOLD, 26))
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


func _show_settings() -> void:
	_clear_settings_overlay()
	settings_layer = CanvasLayer.new()
	settings_layer.layer = 35
	add_child(settings_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = ArenaTheme.root_theme()
	settings_layer.add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.04, 0.09, 0.86)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(470, 430)
	panel.add_theme_stylebox_override("panel", ArenaTheme.royal_panel(Color("0d315b"), ArenaTheme.GOLD, 26))
	center.add_child(panel)
	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 16)
	panel.add_child(layout)
	layout.add_child(_title_label("RÉGLAGES", 36, ArenaTheme.GOLD_LIGHT))
	layout.add_child(_title_label("PERSONNALISE TON EXPÉRIENCE", 13, ArenaTheme.CYAN))
	for config in [
		{"label": "SONS DU COMBAT", "enabled": sound_enabled, "callback": _toggle_sound},
		{"label": "VIBRATIONS", "enabled": haptics_enabled, "callback": _toggle_haptics},
	]:
		var toggle := CheckButton.new()
		toggle.text = String(config.label)
		toggle.custom_minimum_size = Vector2(370, 66)
		toggle.button_pressed = bool(config.enabled)
		ArenaTheme.apply_button(toggle, "gold" if bool(config.enabled) else "secondary", 17)
		toggle.toggled.connect(Callable(config.callback))
		layout.add_child(toggle)
	layout.add_child(_title_label("AUCUN COMPTE • AUCUNE PUBLICITÉ • 100 % HORS LIGNE", 11, ArenaTheme.TEXT_MUTED))
	layout.add_child(_title_label("BATTLE v0.58 • KAYKIT + KENNEY CC0", 11, Color("7eb5d4")))
	var close := Button.new()
	close.text = "FERMER"
	close.custom_minimum_size = Vector2(300, 58)
	_apply_button_theme(close, "primary", 20)
	close.pressed.connect(_clear_settings_overlay)
	layout.add_child(close)


func _clear_settings_overlay() -> void:
	if is_instance_valid(settings_layer):
		settings_layer.queue_free()
	settings_layer = null


func _show_difficulty_sheet() -> void:
	if state != ScreenState.MENU or not is_instance_valid(ui_root):
		return
	_clear_difficulty_sheet()
	difficulty_sheet = DifficultySheetScript.new()
	difficulty_sheet.configure(selected_difficulty)
	difficulty_sheet.confirmed.connect(_confirm_difficulty)
	difficulty_sheet.cancelled.connect(_clear_difficulty_sheet)
	ui_root.add_child(difficulty_sheet)


func _confirm_difficulty(index: int) -> void:
	selected_difficulty = clampi(index, 0, DIFFICULTY_NAMES.size() - 1)
	_save_profile()
	_clear_difficulty_sheet()
	_start_battle()


func _clear_difficulty_sheet() -> void:
	if is_instance_valid(difficulty_sheet):
		difficulty_sheet.queue_free()
	difficulty_sheet = null


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
	var background := RoyalBackdrop.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.modulate = color.lightened(0.02)
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


func _menu_nav_button(label_text: String, icon_texture: Texture2D, callback: Callable, active := false) -> Button:
	var button := Button.new()
	button.name = "Nav%s" % label_text.replace(".", "").replace("É", "E")
	button.set_meta("navigation_label", label_text)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 74
	button.add_theme_stylebox_override("normal", ArenaTheme.nav_button(active))
	button.add_theme_stylebox_override("hover", ArenaTheme.nav_button(active, false, true))
	button.add_theme_stylebox_override("pressed", ArenaTheme.nav_button(active, true))
	button.add_theme_stylebox_override("focus", ArenaTheme.nav_button(active))
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_top = 9
	content.offset_bottom = -9
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", -3)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)
	var icon := TextureRect.new()
	icon.texture = icon_texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(0, 25)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)
	var caption := _title_label(label_text, 10, ArenaTheme.GOLD_LIGHT if active else Color("d8e4eb"))
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(caption)
	button.pressed.connect(callback)
	return button


func _card_panel_style(card_id: String, selected: bool, disabled: bool) -> StyleBoxFlat:
	return ArenaTheme.card_style(card_id, selected, disabled)


func _ui_icon(index: int) -> AtlasTexture:
	var columns := 4
	var cell_size := Vector2(UI_ICON_ATLAS.get_width() / columns, UI_ICON_ATLAS.get_height() / 2)
	var atlas := AtlasTexture.new()
	atlas.atlas = UI_ICON_ATLAS
	atlas.region = Rect2(Vector2(index % columns, index / columns) * cell_size, cell_size)
	return atlas


func _card_texture(card_id: String) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	if card_id in ["fireball", "frost"]:
		var cell_size := Vector2(SPELL_ART.get_width() * 0.5, SPELL_ART.get_height())
		atlas.atlas = SPELL_ART
		atlas.region = Rect2(Vector2(0.0 if card_id == "fireball" else cell_size.x, 0.0), cell_size)
		return atlas
	var definition := UnitRigDefinition.for_card(card_id)
	atlas.atlas = definition.atlas
	atlas.region = definition.frame_region("idle", 0, false)
	return atlas


func _clear_ui() -> void:
	if is_instance_valid(ui_layer):
		ui_layer.free()
	ui_layer = null
	ui_root = null
	difficulty_sheet = null
	primary_action_button = null
	battle_world = null
	arena_container = null
	intro_label = null
	next_card_art = null
	energy_mode_label = null
	battle_announcement = null
	score_label = null
	card_buttons.clear()
	card_affordable_state.clear()
	ready_card_timers.clear()
	drag_card_id = ""
	drag_active = false
	suppress_card_tap = false


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
