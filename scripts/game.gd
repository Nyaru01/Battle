extends Node2D

enum ScreenState { MENU, BATTLE, RESULT }

const DESIGN_SIZE := Vector2(720.0, 1280.0)
const LANE_X := [210.0, 510.0]
const ARENA_TEXTURE := preload("res://assets/arena-v2.png")
const CARD_ART := preload("res://assets/card-art-v2.png")
const ICON_TEXTURE := preload("res://assets/icon.png")
const TOWER_SPRITES := preload("res://assets/tower-sprites-v3.png")
const UNIT_SPRITES := preload("res://assets/unit-sprites-v3.png")
const CARD_ORDER := ["guardian", "ranger", "colossus", "fireball"]
const CARD_SHORT := {
	"guardian": "G",
	"ranger": "E",
	"colossus": "C",
	"fireball": "★",
}
const CARD_QUADRANTS := {
	"guardian": Vector2i(0, 0),
	"ranger": Vector2i(1, 0),
	"colossus": Vector2i(0, 1),
	"fireball": Vector2i(1, 1),
}
const SAVE_PATH := "user://profile.json"

var state := ScreenState.MENU
var simulation: BattleSim
var opponent: BattleAI
var selected_card := ""
var selected_difficulty := 1
var ui_layer: CanvasLayer
var time_label: Label
var energy_label: Label
var energy_bar: ProgressBar
var core_label: Label
var hint_label: Label
var card_buttons: Dictionary = {}
var profile := {"wins": 0, "losses": 0, "draws": 0}


func _ready() -> void:
	_load_profile()
	_build_menu()
	queue_redraw()


func _process(delta: float) -> void:
	if state != ScreenState.BATTLE:
		return
	simulation.step(delta)
	opponent.update(delta, simulation)
	_update_hud()
	simulation.events.clear()
	queue_redraw()
	if simulation.finished:
		_show_result()


func _unhandled_input(event: InputEvent) -> void:
	if state != ScreenState.BATTLE or selected_card.is_empty():
		return
	var pressed := false
	var position := Vector2.ZERO
	if event is InputEventScreenTouch:
		pressed = event.pressed
		position = event.position
	elif event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
		position = event.position
	if not pressed or position.y < 115.0 or position.y > 1060.0:
		return
	var lane := 0 if position.x < DESIGN_SIZE.x * 0.5 else 1
	if simulation.play_card(BattleSim.PLAYER, selected_card, lane):
		selected_card = ""
		hint_label.text = "Choisis une carte, puis touche une voie"
		_update_hud()
		queue_redraw()
	else:
		hint_label.text = "Pas assez d'énergie"


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color("101827"))
	if state == ScreenState.MENU:
		_draw_menu_backdrop()
		return
	_draw_arena()
	_draw_objectives()
	_draw_units()


func _draw_menu_backdrop() -> void:
	draw_texture_rect(ICON_TEXTURE, Rect2(160.0, 100.0, 400.0, 400.0), false)
	draw_rect(Rect2(0.0, 470.0, 720.0, 135.0), Color(0.04, 0.08, 0.13, 0.88), true)
	draw_line(Vector2(100.0, 810.0), Vector2(620.0, 810.0), Color("4e88aa"), 3.0)


func _draw_arena() -> void:
	draw_texture_rect_region(
		ARENA_TEXTURE,
		Rect2(24.0, 82.0, 672.0, 982.0),
		Rect2(92.0, 100.0, 840.0, 1200.0)
	)
	draw_rect(Rect2(24.0, 82.0, 672.0, 982.0), Color(0.05, 0.12, 0.14, 0.28), false, 4.0)
	draw_rect(Rect2(42.0, 590.0, 636.0, 430.0), Color(0.2, 0.75, 1.0, 0.025), true)


func _draw_objectives() -> void:
	for side in [BattleSim.PLAYER, BattleSim.ENEMY]:
		var color := Color("4eb7ff") if side == BattleSim.PLAYER else Color("ff5d70")
		var tower_y := 900.0 if side == BattleSim.PLAYER else 240.0
		var core_y := 955.0 if side == BattleSim.PLAYER else 205.0
		for lane in range(BattleSim.LANE_COUNT):
			var hp: float = simulation.towers[side].lanes[lane]
			_draw_tower(Vector2(LANE_X[lane], tower_y), color, hp, 1200.0, false)
		var core_hp: float = simulation.towers[side].core
		_draw_tower(Vector2(360.0, core_y), color, core_hp, 2200.0, true)


func _draw_units() -> void:
	for unit in simulation.units:
		var x: float = LANE_X[unit.lane]
		var radius := _draw_unit_avatar(Vector2(x, unit.y), unit)
		_draw_health_bar(Vector2(x - radius, unit.y - radius - 12.0), radius * 2.0, unit.hp, unit.max_hp)


func _draw_tower(center: Vector2, team_color: Color, hp: float, maximum: float, is_core: bool) -> void:
	var source_width := TOWER_SPRITES.get_width() * 0.5
	var source := Rect2(source_width if is_core else 0.0, 0.0, source_width, TOWER_SPRITES.get_height())
	var size := Vector2(170.0, 150.0) if is_core else Vector2(138.0, 142.0)
	var destination := Rect2(center.x - size.x * 0.5, center.y - size.y * 0.60, size.x, size.y)
	draw_circle(center + Vector2(7.0, 27.0), 39.0 if is_core else 31.0, Color(0.02, 0.05, 0.04, 0.35))
	var tint := Color.WHITE if hp > 0.0 else Color(0.35, 0.36, 0.37, 0.55)
	draw_texture_rect_region(TOWER_SPRITES, destination, source, tint)
	var banner_width := 52.0 if is_core else 42.0
	var banner_y := center.y - (28.0 if is_core else 22.0)
	draw_rect(Rect2(center.x - banner_width * 0.5, banner_y, banner_width, 18.0), team_color if hp > 0.0 else Color("45494c"), true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(center.x - banner_width * 0.5, banner_y + 18.0),
		Vector2(center.x, banner_y + 27.0),
		Vector2(center.x + banner_width * 0.5, banner_y + 18.0),
	]), team_color.darkened(0.12) if hp > 0.0 else Color("45494c"))
	if is_core and hp > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(center.x - 18.0, banner_y + 17.0), "♛", HORIZONTAL_ALIGNMENT_CENTER, 36.0, 19, Color("ffe180"))
	_draw_health_bar(Vector2(center.x - size.x * 0.31, center.y - size.y * 0.55), size.x * 0.62, hp, maximum)


func _draw_unit_avatar(center: Vector2, unit: Dictionary) -> float:
	var team := Color("57c4ff") if unit.side == BattleSim.PLAYER else Color("ff6173")
	var radius := 25.0
	var source := Rect2(20.0, 100.0, 630.0, 680.0)
	var size := Vector2(108.0, 116.0)
	if unit.card_id == "colossus":
		radius = 34.0
		source = Rect2(1100.0, 80.0, 674.0, 710.0)
		size = Vector2(132.0, 139.0)
	elif unit.card_id == "ranger":
		radius = 23.0
		source = Rect2(650.0, 130.0, 480.0, 650.0)
		size = Vector2(86.0, 116.0)
	draw_circle(center + Vector2(5.0, 20.0), radius * 0.95, Color(0.02, 0.05, 0.04, 0.38))
	draw_circle(center + Vector2(0.0, 18.0), radius * 0.72, Color(team, 0.20))
	draw_arc(center + Vector2(0.0, 18.0), radius * 0.76, 0.0, TAU, 28, team, 3.0)
	var destination := Rect2(center.x - size.x * 0.5, center.y - size.y * 0.66, size.x, size.y)
	draw_texture_rect_region(UNIT_SPRITES, destination, source)
	return radius


func _draw_health_bar(position: Vector2, width: float, value: float, maximum: float) -> void:
	draw_rect(Rect2(position, Vector2(width, 7.0)), Color(0.05, 0.07, 0.1, 0.85), true)
	var ratio := clampf(value / maximum, 0.0, 1.0)
	draw_rect(Rect2(position + Vector2(1.0, 1.0), Vector2((width - 2.0) * ratio, 5.0)), Color("6be675") if ratio > 0.3 else Color("ffca58"), true)


func _build_menu() -> void:
	_clear_ui()
	state = ScreenState.MENU
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	var title := _label("BATTLE", Vector2(80.0, 485.0), Vector2(560.0, 82.0), 58)
	title.add_theme_color_override("font_color", Color("76d6ff"))
	var subtitle := _label("Stratégie d'arène • Prototype IA", Vector2(80.0, 557.0), Vector2(560.0, 45.0), 22)
	subtitle.add_theme_color_override("font_color", Color("b5c9d8"))
	var mode := _label("DUEL CONTRE IA", Vector2(120.0, 680.0), Vector2(480.0, 45.0), 26)
	mode.add_theme_color_override("font_color", Color("f5c867"))
	var difficulty := OptionButton.new()
	difficulty.position = Vector2(180.0, 745.0)
	difficulty.size = Vector2(360.0, 64.0)
	difficulty.add_item("Initiation")
	difficulty.add_item("Tactique")
	difficulty.add_item("Expert")
	difficulty.select(selected_difficulty)
	difficulty.item_selected.connect(func(index: int) -> void: selected_difficulty = index)
	ui_layer.add_child(difficulty)
	var start := Button.new()
	start.text = "JOUER"
	start.position = Vector2(180.0, 840.0)
	start.size = Vector2(360.0, 88.0)
	start.add_theme_font_size_override("font_size", 30)
	start.pressed.connect(_start_battle)
	ui_layer.add_child(start)
	var version := _label("Prototype 0.3 • Hors ligne", Vector2(160.0, 1140.0), Vector2(400.0, 36.0), 18)
	version.add_theme_color_override("font_color", Color("71889a"))
	var record := _label("%d victoires  •  %d défaites" % [profile.wins, profile.losses], Vector2(160.0, 950.0), Vector2(400.0, 40.0), 18)
	record.add_theme_color_override("font_color", Color("8fa7b8"))
	queue_redraw()


func _start_battle() -> void:
	simulation = BattleSim.new(Time.get_ticks_msec())
	opponent = BattleAI.new(BattleSim.ENEMY, selected_difficulty, Time.get_ticks_msec() + 19)
	selected_card = ""
	state = ScreenState.BATTLE
	_build_hud()
	queue_redraw()


func _build_hud() -> void:
	_clear_ui()
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	time_label = _label("03:00", Vector2(290.0, 0.0), Vector2(140.0, 38.0), 26)
	energy_label = _label("Énergie 5/10", Vector2(18.0, 1060.0), Vector2(145.0, 36.0), 18)
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	energy_bar = ProgressBar.new()
	energy_bar.position = Vector2(148.0, 1067.0)
	energy_bar.size = Vector2(282.0, 24.0)
	energy_bar.min_value = 0.0
	energy_bar.max_value = 10.0
	energy_bar.value = 5.0
	energy_bar.show_percentage = false
	energy_bar.add_theme_stylebox_override("background", _energy_style(Color("111925")))
	energy_bar.add_theme_stylebox_override("fill", _energy_style(Color("c950ed")))
	ui_layer.add_child(energy_bar)
	core_label = _label("", Vector2(20.0, 36.0), Vector2(680.0, 30.0), 17)
	hint_label = _label("Choisis une carte, puis touche une voie", Vector2(438.0, 1058.0), Vector2(264.0, 40.0), 15)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	card_buttons.clear()
	for index in range(CARD_ORDER.size()):
		var card_id: String = CARD_ORDER[index]
		var card: Dictionary = BattleSim.CARDS[card_id]
		var button := Button.new()
		button.position = Vector2(12.0 + index * 177.0, 1100.0)
		button.size = Vector2(165.0, 152.0)
		button.text = ""
		button.add_theme_stylebox_override("normal", _card_style(card_id, false))
		button.add_theme_stylebox_override("hover", _card_style(card_id, true))
		button.add_theme_stylebox_override("pressed", _card_style(card_id, true))
		button.add_theme_stylebox_override("disabled", _card_style(card_id, false, true))
		button.pressed.connect(_select_card.bind(card_id))
		ui_layer.add_child(button)
		var quadrant: Vector2i = CARD_QUADRANTS[card_id]
		var atlas := AtlasTexture.new()
		atlas.atlas = CARD_ART
		atlas.region = Rect2(
			quadrant.x * CARD_ART.get_width() * 0.5,
			quadrant.y * CARD_ART.get_height() * 0.5,
			CARD_ART.get_width() * 0.5,
			CARD_ART.get_height() * 0.5
		)
		var portrait := TextureRect.new()
		portrait.texture = atlas
		portrait.position = Vector2(6.0, 6.0)
		portrait.size = Vector2(153.0, 96.0)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(portrait)
		var name_label := Label.new()
		name_label.text = card.name
		name_label.position = Vector2(4.0, 101.0)
		name_label.size = Vector2(157.0, 25.0)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(name_label)
		var cost_label := Label.new()
		cost_label.text = "●  %d" % int(card.cost)
		cost_label.position = Vector2(4.0, 124.0)
		cost_label.size = Vector2(157.0, 24.0)
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_label.add_theme_font_size_override("font_size", 17)
		cost_label.add_theme_color_override("font_color", Color("e879ff"))
		cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(cost_label)
		card_buttons[card_id] = button
	_update_hud()


func _select_card(card_id: String) -> void:
	selected_card = card_id
	hint_label.text = "%s sélectionné • touche la voie gauche ou droite" % BattleSim.CARDS[card_id].name
	_update_hud()


func _update_hud() -> void:
	if state != ScreenState.BATTLE:
		return
	var seconds := ceili(simulation.time_left)
	time_label.text = "%02d:%02d" % [seconds / 60, seconds % 60]
	energy_label.text = "Énergie %.1f/10" % simulation.energy[BattleSim.PLAYER]
	energy_bar.value = simulation.energy[BattleSim.PLAYER]
	core_label.text = "IA  %d     •     NOYAU     •     %d  TOI" % [int(simulation.towers[BattleSim.ENEMY].core), int(simulation.towers[BattleSim.PLAYER].core)]
	for card_id in card_buttons:
		var button: Button = card_buttons[card_id]
		button.disabled = BattleSim.CARDS[card_id].cost > simulation.energy[BattleSim.PLAYER] + 0.001
		button.add_theme_stylebox_override("normal", _card_style(card_id, selected_card == card_id))


func _card_style(card_id: String, highlighted: bool, disabled: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("182230") if not disabled else Color("15191e")
	var accent := Color("59c9ff")
	if card_id == "ranger":
		accent = Color("54d9be")
	elif card_id == "colossus":
		accent = Color("d6b365")
	elif card_id == "fireball":
		accent = Color("ff8a47")
	style.border_color = Color("ffe17b") if highlighted else accent.darkened(0.18)
	style.set_border_width_all(4 if highlighted else 2)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0.0, 4.0)
	return style


func _energy_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(12)
	style.border_color = Color("70278a") if color.get_luminance() > 0.2 else Color("354052")
	style.set_border_width_all(2)
	return style


func _show_result() -> void:
	state = ScreenState.RESULT
	if simulation.winner == BattleSim.PLAYER:
		profile.wins += 1
	elif simulation.winner == BattleSim.ENEMY:
		profile.losses += 1
	else:
		profile.draws += 1
	_save_profile()
	_clear_ui()
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	var panel := ColorRect.new()
	panel.position = Vector2(80.0, 390.0)
	panel.size = Vector2(560.0, 420.0)
	panel.color = Color(0.04, 0.08, 0.13, 0.94)
	ui_layer.add_child(panel)
	var result_text := "ÉGALITÉ"
	if simulation.winner == BattleSim.PLAYER:
		result_text = "VICTOIRE"
	elif simulation.winner == BattleSim.ENEMY:
		result_text = "DÉFAITE"
	var result := _label(result_text, Vector2(120.0, 450.0), Vector2(480.0, 80.0), 48)
	result.add_theme_color_override("font_color", Color("76e68b") if simulation.winner == BattleSim.PLAYER else Color("ff7785"))
	var summary := _label("Noyau : %d  •  IA : %d" % [int(simulation.towers[BattleSim.PLAYER].core), int(simulation.towers[BattleSim.ENEMY].core)], Vector2(120.0, 555.0), Vector2(480.0, 45.0), 20)
	var replay := Button.new()
	replay.text = "REJOUER"
	replay.position = Vector2(180.0, 650.0)
	replay.size = Vector2(360.0, 70.0)
	replay.pressed.connect(_start_battle)
	ui_layer.add_child(replay)
	var menu := Button.new()
	menu.text = "MENU"
	menu.position = Vector2(180.0, 735.0)
	menu.size = Vector2(360.0, 54.0)
	menu.pressed.connect(_build_menu)
	ui_layer.add_child(menu)
	queue_redraw()


func _label(text_value: String, position_value: Vector2, size_value: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = position_value
	label.size = size_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	ui_layer.add_child(label)
	return label


func _clear_ui() -> void:
	if is_instance_valid(ui_layer):
		ui_layer.queue_free()


func _load_profile() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for key in profile.keys():
		profile[key] = maxi(0, int(parsed.get(key, 0)))


func _save_profile() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(profile))
