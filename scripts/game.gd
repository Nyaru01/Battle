extends Node2D

enum ScreenState { MENU, BATTLE, RESULT }

const DESIGN_SIZE := Vector2(720.0, 1280.0)
const LANE_X := [210.0, 510.0]
const ARENA_TEXTURE := preload("res://assets/arena-v2.png")
const CARD_ART := preload("res://assets/card-art-v2.png")
const ICON_TEXTURE := preload("res://assets/icon.png")
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
	var width := 92.0 if is_core else 76.0
	var height := 76.0 if is_core else 66.0
	var shadow := PackedVector2Array([
		center + Vector2(-width * 0.52 + 8.0, height * 0.38 + 10.0),
		center + Vector2(width * 0.52 + 8.0, height * 0.38 + 10.0),
		center + Vector2(width * 0.40 + 8.0, height * 0.66 + 10.0),
		center + Vector2(-width * 0.40 + 8.0, height * 0.66 + 10.0),
	])
	draw_colored_polygon(shadow, Color(0.02, 0.05, 0.04, 0.38))
	var base_rect := Rect2(center.x - width * 0.46, center.y - height * 0.18, width * 0.92, height * 0.72)
	draw_rect(base_rect, Color("48545d") if hp > 0.0 else Color("343a3e"), true)
	draw_rect(Rect2(base_rect.position + Vector2(5.0, 5.0), base_rect.size - Vector2(10.0, 12.0)), Color("697984") if hp > 0.0 else Color("40474b"), true)
	var roof := PackedVector2Array([
		center + Vector2(-width * 0.55, -height * 0.34),
		center + Vector2(width * 0.55, -height * 0.34),
		center + Vector2(width * 0.42, height * 0.06),
		center + Vector2(-width * 0.42, height * 0.06),
	])
	draw_colored_polygon(roof, team_color.darkened(0.22) if hp > 0.0 else Color("394044"))
	draw_polyline(PackedVector2Array([roof[0], roof[1], roof[2], roof[3], roof[0]]), Color(1, 1, 1, 0.48), 2.0)
	for offset in [-0.36, 0.0, 0.36]:
		draw_rect(Rect2(center.x + width * offset - 8.0, center.y - height * 0.48, 16.0, 17.0), team_color if hp > 0.0 else Color("41494d"), true)
	if is_core and hp > 0.0:
		var crown := PackedVector2Array([
			center + Vector2(-20.0, 8.0), center + Vector2(-15.0, -5.0),
			center + Vector2(-5.0, 3.0), center + Vector2(0.0, -9.0),
			center + Vector2(7.0, 3.0), center + Vector2(17.0, -5.0),
			center + Vector2(20.0, 8.0),
		])
		draw_colored_polygon(crown, Color("ffd563"))
	_draw_health_bar(Vector2(center.x - width * 0.52, center.y - height * 0.68), width * 1.04, hp, maximum)


func _draw_unit_avatar(center: Vector2, unit: Dictionary) -> float:
	var team := Color("57c4ff") if unit.side == BattleSim.PLAYER else Color("ff6173")
	var facing := -1.0 if unit.side == BattleSim.PLAYER else 1.0
	var radius := 25.0
	if unit.card_id == "colossus":
		radius = 34.0
	elif unit.card_id == "ranger":
		radius = 23.0
	draw_circle(center + Vector2(7.0, radius * 0.64), radius * 0.92, Color(0.02, 0.05, 0.04, 0.32))
	if unit.card_id == "colossus":
		draw_rect(Rect2(center - Vector2(27.0, 23.0), Vector2(54.0, 48.0)), Color("727b72"), true)
		draw_rect(Rect2(center - Vector2(18.0, 30.0), Vector2(36.0, 24.0)), Color("9a895e"), true)
		draw_circle(center + Vector2(0.0, 5.0), 9.0, Color("67efff"))
		draw_line(center + Vector2(-27.0, -10.0), center + Vector2(-38.0, 18.0), Color("6a6252"), 10.0)
		draw_line(center + Vector2(27.0, -10.0), center + Vector2(38.0, 18.0), Color("6a6252"), 10.0)
	elif unit.card_id == "ranger":
		draw_colored_polygon(PackedVector2Array([center + Vector2(0.0, -26.0), center + Vector2(-22.0, 23.0), center + Vector2(22.0, 23.0)]), Color("1b8f83"))
		draw_circle(center + Vector2(0.0, -12.0), 11.0, Color("edc3a3"))
		draw_arc(center + Vector2(10.0 * facing, 2.0), 25.0, -1.2, 1.2, 16, Color("d6ad55"), 4.0)
		draw_line(center + Vector2(20.0 * facing, -20.0), center + Vector2(20.0 * facing, 22.0), Color("f4e4b0"), 2.0)
	else:
		draw_rect(Rect2(center - Vector2(17.0, 18.0), Vector2(34.0, 40.0)), team.darkened(0.18), true)
		draw_circle(center + Vector2(0.0, -20.0), 13.0, Color("d6a77f"))
		draw_circle(center + Vector2(-facing * 16.0, 2.0), 17.0, team)
		draw_circle(center + Vector2(-facing * 16.0, 2.0), 17.0, Color("f6d16e"), false, 3.0)
		draw_line(center + Vector2(facing * 13.0, -8.0), center + Vector2(facing * 30.0, -30.0), Color("edf2f4"), 5.0)
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
	var version := _label("Prototype 0.2 • Hors ligne", Vector2(160.0, 1140.0), Vector2(400.0, 36.0), 18)
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
	energy_label = _label("Énergie 5/10", Vector2(20.0, 1060.0), Vector2(210.0, 42.0), 22)
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	core_label = _label("", Vector2(20.0, 36.0), Vector2(680.0, 30.0), 17)
	hint_label = _label("Choisis une carte, puis touche une voie", Vector2(210.0, 1060.0), Vector2(490.0, 42.0), 17)
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
