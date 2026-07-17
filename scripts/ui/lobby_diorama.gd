class_name LobbyDiorama
extends Control

const ARENA := preload("res://assets/v040/environment/arena-royale-v040.png")
const BASE_SOURCE := Rect2(0, 590, 1024, 820)

var units: Array[UnitView2D] = []
var animation_time := 0.0
var showcase_timer := 2.4
var showcase_index := 0
var last_source_rect := BASE_SOURCE


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout_units)
	for data in [
		{"id": 901, "card": "ranger", "x": 0.24, "y": 0.76, "scale": 1.30, "facing": 1.0, "accent": Color("49d77f")},
		{"id": 902, "card": "colossus", "x": 0.76, "y": 0.77, "scale": 1.37, "facing": -1.0, "accent": Color("f6c548")},
		{"id": 903, "card": "guardian", "x": 0.50, "y": 0.72, "scale": 1.68, "facing": 1.0, "accent": Color("63dcff")},
	]:
		var unit := UnitView2D.new()
		unit.configure(int(data.id), String(data.card), BattleSim.ENEMY)
		unit.show_health_bar = false
		unit.show_team_ring = false
		unit.set_meta("anchor", Vector2(float(data.x), float(data.y)))
		unit.set_meta("showcase_scale", float(data.scale))
		unit.set_meta("accent", Color(data.accent))
		unit.sync_state({"hp": 100.0, "max_hp": 100.0, "moving": false, "walk_phase": 0.0, "attack_pulse": 0.0, "facing_x": float(data.facing)})
		unit.spawn_elapsed = -0.12 * float(units.size())
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
		showcase_timer = 3.8
	queue_redraw()


func _layout_units() -> void:
	var scale_value := clampf(minf(size.x / 540.0, size.y / 500.0), 0.68, 1.24)
	for unit in units:
		unit.set_world_scale(scale_value * float(unit.get_meta("showcase_scale", 1.0)))
		unit.position = Vector2(unit.get_meta("anchor")) * size


func cover_source_rect(target_size: Vector2) -> Rect2:
	if target_size.x <= 0.0 or target_size.y <= 0.0:
		return BASE_SOURCE
	var target_aspect := target_size.x / target_size.y
	var source_aspect := BASE_SOURCE.size.x / BASE_SOURCE.size.y
	var cropped := BASE_SOURCE
	if target_aspect > source_aspect:
		cropped.size.y = BASE_SOURCE.size.x / target_aspect
		cropped.position.y += (BASE_SOURCE.size.y - cropped.size.y) * 0.5
	else:
		cropped.size.x = BASE_SOURCE.size.y * target_aspect
		cropped.position.x += (BASE_SOURCE.size.x - cropped.size.x) * 0.5
	return cropped


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	last_source_rect = cover_source_rect(size)
	draw_texture_rect_region(ARENA, Rect2(Vector2.ZERO, size), last_source_rect)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.07, 0.12, 0.10), true)
	draw_rect(Rect2(0, 0, size.x, size.y * 0.20), Color(0.005, 0.025, 0.06, 0.36), true)
	draw_rect(Rect2(0, size.y * 0.78, size.x, size.y * 0.22), Color(0.005, 0.025, 0.05, 0.34), true)
	_draw_ground_glow(Vector2(0.24, 0.76) * size, Color("49d77f"), false)
	_draw_ground_glow(Vector2(0.76, 0.77) * size, Color("f6c548"), false)
	_draw_ground_glow(Vector2(0.50, 0.72) * size, Color("63dcff"), true)


func _draw_ground_glow(center: Vector2, accent: Color, featured: bool) -> void:
	var radius := 48.0 if featured else 38.0
	var pulse := 0.06 + (sin(animation_time * 1.8 + center.x * 0.01) + 1.0) * 0.018
	draw_set_transform(center + Vector2(0, 29), 0.0, Vector2(1.35, 0.34))
	draw_circle(Vector2.ZERO, radius + 5.0, Color(0.0, 0.02, 0.04, 0.24))
	draw_circle(Vector2.ZERO, radius, Color(accent, pulse))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 36, Color(accent, 0.54), 2.0 if featured else 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
