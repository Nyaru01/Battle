extends Node2D

enum ScreenState { MENU, BATTLE, RESULT }

const DESIGN_SIZE := Vector2(720.0, 1280.0)
const LANE_X := [210.0, 510.0]
const CARD_ORDER := ["guardian", "ranger", "colossus", "fireball"]
const CARD_SHORT := {
	"guardian": "G",
	"ranger": "E",
	"colossus": "C",
	"fireball": "★",
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
	for index in range(7):
		var radius := 90.0 + index * 42.0
		var alpha := 0.12 - index * 0.012
		draw_circle(Vector2(360.0, 390.0), radius, Color(0.25, 0.75, 0.95, alpha))
	draw_line(Vector2(100.0, 810.0), Vector2(620.0, 810.0), Color("29445f"), 3.0)


func _draw_arena() -> void:
	draw_rect(Rect2(32.0, 112.0, 656.0, 948.0), Color("183c35"), true)
	draw_rect(Rect2(45.0, 555.0, 630.0, 475.0), Color(0.1, 0.55, 0.4, 0.08), true)
	draw_rect(Rect2(32.0, 510.0, 656.0, 78.0), Color("17678a"), true)
	for lane_x in LANE_X:
		draw_line(Vector2(lane_x, 130.0), Vector2(lane_x, 1040.0), Color(0.75, 0.9, 0.7, 0.12), 4.0)
		draw_rect(Rect2(lane_x - 47.0, 510.0, 94.0, 78.0), Color("a57843"), true)
	draw_line(Vector2(360.0, 118.0), Vector2(360.0, 1050.0), Color(1, 1, 1, 0.06), 2.0)


func _draw_objectives() -> void:
	for side in [BattleSim.PLAYER, BattleSim.ENEMY]:
		var color := Color("4eb7ff") if side == BattleSim.PLAYER else Color("ff5d70")
		var tower_y := 920.0 if side == BattleSim.PLAYER else 190.0
		var core_y := 1005.0 if side == BattleSim.PLAYER else 110.0
		for lane in range(BattleSim.LANE_COUNT):
			var hp: float = simulation.towers[side].lanes[lane]
			var rect := Rect2(LANE_X[lane] - 42.0, tower_y - 32.0, 84.0, 64.0)
			draw_rect(rect, Color("263746") if hp <= 0.0 else color.darkened(0.25), true)
			draw_rect(rect, Color(1, 1, 1, 0.35), false, 3.0)
			_draw_health_bar(Vector2(rect.position.x, rect.position.y - 13.0), rect.size.x, hp, 1200.0)
		var core_hp: float = simulation.towers[side].core
		var core_rect := Rect2(310.0, core_y - 28.0, 100.0, 56.0)
		draw_rect(core_rect, color.darkened(0.08), true)
		draw_rect(core_rect, Color.WHITE, false, 3.0)
		_draw_health_bar(Vector2(core_rect.position.x, core_rect.position.y - 13.0), core_rect.size.x, core_hp, 2200.0)


func _draw_units() -> void:
	for unit in simulation.units:
		var x: float = LANE_X[unit.lane]
		var color := Color("65c8ff") if unit.side == BattleSim.PLAYER else Color("ff687a")
		var radius := 25.0
		if unit.card_id == "colossus":
			radius = 34.0
		elif unit.card_id == "ranger":
			radius = 21.0
		draw_circle(Vector2(x, unit.y), radius + 5.0, Color(0, 0, 0, 0.3))
		draw_circle(Vector2(x, unit.y), radius, color)
		draw_circle(Vector2(x, unit.y), radius, Color.WHITE, false, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(x - 15.0, unit.y + 7.0), CARD_SHORT[unit.card_id], HORIZONTAL_ALIGNMENT_CENTER, 30.0, 18, Color("102030"))
		_draw_health_bar(Vector2(x - radius, unit.y - radius - 12.0), radius * 2.0, unit.hp, unit.max_hp)


func _draw_health_bar(position: Vector2, width: float, value: float, maximum: float) -> void:
	draw_rect(Rect2(position, Vector2(width, 7.0)), Color(0.05, 0.07, 0.1, 0.85), true)
	var ratio := clampf(value / maximum, 0.0, 1.0)
	draw_rect(Rect2(position + Vector2(1.0, 1.0), Vector2((width - 2.0) * ratio, 5.0)), Color("6be675") if ratio > 0.3 else Color("ffca58"), true)


func _build_menu() -> void:
	_clear_ui()
	state = ScreenState.MENU
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	var title := _label("BATTLE", Vector2(80.0, 190.0), Vector2(560.0, 100.0), 64)
	title.add_theme_color_override("font_color", Color("76d6ff"))
	var subtitle := _label("Stratégie d'arène • Prototype IA", Vector2(80.0, 290.0), Vector2(560.0, 55.0), 24)
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
	var version := _label("Prototype 0.1 • Hors ligne", Vector2(160.0, 1140.0), Vector2(400.0, 36.0), 18)
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
		button.position = Vector2(18.0 + index * 175.0, 1110.0)
		button.size = Vector2(160.0, 138.0)
		button.text = "%s\n⚡ %d" % [card.name, int(card.cost)]
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(_select_card.bind(card_id))
		ui_layer.add_child(button)
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
		button.modulate = Color("ffe082") if selected_card == card_id else Color.WHITE


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
