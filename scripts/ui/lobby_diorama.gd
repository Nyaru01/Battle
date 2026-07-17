class_name LobbyDiorama
extends Control

const ARENA := preload("res://assets/v040/environment/arena-royale-v040.png")

var units: Array[UnitView2D] = []
var animation_time := 0.0
var showcase_timer := 1.35
var showcase_index := 0


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout_units)
	for data in [
		{"id": 901, "card": "ranger", "x": 0.23, "y": 0.77, "scale": 1.00, "accent": Color("49d77f")},
		{"id": 902, "card": "colossus", "x": 0.77, "y": 0.78, "scale": 1.06, "accent": Color("f6c548")},
		{"id": 903, "card": "guardian", "x": 0.50, "y": 0.76, "scale": 1.27, "accent": Color("63dcff")},
	]:
		var unit := UnitView2D.new()
		unit.configure(int(data.id), String(data.card), BattleSim.ENEMY)
		unit.show_health_bar = false
		unit.show_team_ring = false
		unit.set_meta("anchor", Vector2(float(data.x), float(data.y)))
		unit.set_meta("showcase_scale", float(data.scale))
		unit.set_meta("accent", Color(data.accent))
		unit.sync_state({"hp": 100.0, "max_hp": 100.0, "moving": false, "walk_phase": 0.0, "attack_pulse": 0.0})
		add_child(unit)
		units.append(unit)
	_layout_units()
	set_process(true)


func _process(delta: float) -> void:
	animation_time += delta
	showcase_timer -= delta
	if showcase_timer <= 0.0 and not units.is_empty():
		units[showcase_index].play_attack()
		showcase_index = (showcase_index + 1) % units.size()
		showcase_timer = 2.15
	for index in range(units.size()):
		var unit := units[index]
		var anchor: Vector2 = unit.get_meta("anchor")
		var drift := Vector2(sin(animation_time * 0.72 + index * 1.9) * 1.6, sin(animation_time * 1.55 + index) * 2.5)
		unit.position = anchor * size + drift
	queue_redraw()


func _layout_units() -> void:
	var scale_value := clampf(size.x / 560.0, 0.72, 1.18)
	for unit in units:
		unit.set_world_scale(scale_value * float(unit.get_meta("showcase_scale", 1.0)))


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var source := Rect2(110, 650, 804, 680)
	draw_texture_rect_region(ARENA, Rect2(Vector2.ZERO, size), source)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.09, 0.16, 0.12), true)
	draw_rect(Rect2(0, 0, size.x, size.y * 0.22), Color(0.01, 0.05, 0.11, 0.28), true)
	draw_rect(Rect2(0, size.y * 0.76, size.x, size.y * 0.24), Color(0.01, 0.05, 0.10, 0.34), true)
	_draw_podium(Vector2(0.23, 0.76) * size, Color("49d77f"), false)
	_draw_podium(Vector2(0.77, 0.77) * size, Color("f6c548"), false)
	_draw_podium(Vector2(0.50, 0.75) * size, Color("63dcff"), true)
	var pennant_y := size.y * 0.35
	draw_colored_polygon(PackedVector2Array([Vector2(0, pennant_y), Vector2(size.x * 0.12, pennant_y + 18), Vector2(0, pennant_y + 36)]), Color("d59b24"))
	draw_colored_polygon(PackedVector2Array([Vector2(size.x, pennant_y), Vector2(size.x * 0.88, pennant_y + 18), Vector2(size.x, pennant_y + 36)]), Color("d59b24"))


func _draw_podium(center: Vector2, accent: Color, featured: bool) -> void:
	var radius := 43.0 if featured else 35.0
	var pulse := 0.04 + (sin(animation_time * 2.0 + center.x * 0.01) + 1.0) * 0.025
	draw_set_transform(center + Vector2(4, 10), 0.0, Vector2(1.45, 0.42))
	draw_circle(Vector2.ZERO, radius + 8.0, Color(0.0, 0.02, 0.04, 0.42))
	draw_circle(Vector2.ZERO, radius + 3.0, Color(accent, pulse))
	draw_circle(Vector2.ZERO, radius, Color(0.03, 0.12, 0.20, 0.82))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 36, Color(accent, 0.92), 3.0 if featured else 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
