class_name LobbyDiorama
extends Control

const ARENA := preload("res://assets/v040/environment/arena-royale-v040.png")

var units: Array[UnitView2D] = []
var animation_time := 0.0


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout_units)
	for data in [
		{"id": 901, "card": "guardian", "x": 0.23, "y": 0.69},
		{"id": 902, "card": "ranger", "x": 0.50, "y": 0.58},
		{"id": 903, "card": "colossus", "x": 0.77, "y": 0.70},
	]:
		var unit := UnitView2D.new()
		unit.configure(int(data.id), String(data.card), BattleSim.ENEMY)
		unit.set_meta("anchor", Vector2(float(data.x), float(data.y)))
		unit.sync_state({"hp": 100.0, "max_hp": 100.0, "moving": false, "walk_phase": 0.0, "attack_pulse": 0.0})
		add_child(unit)
		units.append(unit)
	_layout_units()
	set_process(true)


func _process(delta: float) -> void:
	animation_time += delta
	for index in range(units.size()):
		var unit := units[index]
		var anchor: Vector2 = unit.get_meta("anchor")
		unit.position = anchor * size + Vector2(0, sin(animation_time * 1.6 + index) * 2.0)
	queue_redraw()


func _layout_units() -> void:
	var scale_value := clampf(size.x / 560.0, 0.72, 1.18)
	for unit in units:
		unit.set_world_scale(scale_value)


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var source := Rect2(110, 650, 804, 680)
	draw_texture_rect_region(ARENA, Rect2(Vector2.ZERO, size), source)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.09, 0.16, 0.16), true)
