class_name LobbyDiorama
extends Control

const ARENA := preload("res://assets/v055/environment/lobby-castle-v055.png")
const BASE_SOURCE := Rect2(0, 0, 1024, 1536)

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
		{"id": 901, "card": "ranger", "x": 0.29, "y": 0.655, "scale": 1.60, "facing": 1.0},
		{"id": 902, "card": "colossus", "x": 0.71, "y": 0.655, "scale": 1.69, "facing": -1.0},
		{"id": 903, "card": "guardian", "x": 0.50, "y": 0.615, "scale": 1.98, "facing": 1.0},
	]:
		var unit := UnitView2D.new()
		unit.configure(int(data.id), String(data.card), BattleSim.ENEMY)
		unit.show_health_bar = false
		unit.show_team_ring = false
		unit.ground_shadow_alpha = 0.18
		unit.set_meta("anchor", Vector2(float(data.x), float(data.y)))
		unit.set_meta("showcase_scale", float(data.scale))
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
	var scale_value := clampf(minf(size.x / 720.0, size.y / 1280.0), 0.72, 1.28)
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
