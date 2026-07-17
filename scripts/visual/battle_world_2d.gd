class_name BattleWorld2D
extends Control

const ARENA_TEXTURE: Texture2D = preload("res://assets/v040/environment/arena-royale-v040.png")
const TOWER_PARTS: Texture2D = preload("res://assets/v040/environment/tower-parts-v040.png")
const SPELL_ART: Texture2D = preload("res://assets/v040/ui/spell-art-v040.png")
const BODY_FONT: Font = preload("res://assets/fonts/Nunito-Variable.ttf")
const HEADING_FONT: Font = preload("res://assets/fonts/Baloo2-Variable.ttf")

const DESIGN_WIDTH := 720.0
const DESIGN_TOP := 82.0
const DESIGN_HEIGHT := 982.0
const ARENA_ASPECT := 2.0 / 3.0
const HALF_Y := 580.0
const TEAM_BLUE := Color("35c4ff")
const TEAM_RED := Color("ff6174")
const GOLD := Color("ffd766")

var simulation: BattleSim
var arena_rect := Rect2()
var unit_views: Dictionary = {}
var unit_positions: Dictionary = {}
var dying_views: Array[UnitView2D] = []
var effects: Array[Dictionary] = []
var tower_pulses: Dictionary = {}
var targeting_type := ""
var targeting_lane := -1
var preview_card := ""
var preview_position := Vector2.ZERO
var preview_lane := -1
var preview_valid := false
var animation_time := 0.0
var shake_strength := 0.0
var camera_offset := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(_update_arena_rect)
	_update_arena_rect()
	set_process(true)


func sync(simulation_value: BattleSim) -> void:
	simulation = simulation_value
	var active := {}
	for unit in simulation.units:
		var id := int(unit.id)
		active[id] = true
		var target := _unit_design_position(unit)
		if not unit_views.has(id):
			var view := UnitView2D.new()
			view.configure(id, String(unit.card_id), int(unit.side))
			add_child(view)
			unit_views[id] = view
			unit_positions[id] = {"current": target, "target": target}
			_add_effect("deploy", target, _team_color(int(unit.side)), 0.52, 66.0)
		var position_state: Dictionary = unit_positions[id]
		position_state.target = target
		unit_positions[id] = position_state
		var unit_view: UnitView2D = unit_views[id]
		unit_view.sync_state(unit)
	for id in unit_views.keys():
		if active.has(id):
			continue
		var defeated: UnitView2D = unit_views[id]
		defeated.play_death()
		dying_views.append(defeated)
		unit_views.erase(id)
		unit_positions.erase(id)
	queue_redraw()


func present_event(event: Dictionary) -> void:
	match String(event.get("type", "")):
		"hit":
			_play_unit_attack(int(event.get("source", -1)))
			_play_unit_hit(int(event.get("target", -1)))
			if not bool(event.get("ranged", false)):
				var target_state: Dictionary = event.get("target_state", {})
				_add_effect("melee", _snapshot_position(target_state), _team_color(int(event.get("side", BattleSim.PLAYER))), 0.28, 48.0)
				shake_strength = maxf(shake_strength, 1.8)
		"objective_hit":
			_play_unit_attack(int(event.get("source", -1)))
			if not bool(event.get("ranged", false)):
				_add_effect("melee", Vector2(event.get("target_position", Vector2.ZERO)), _team_color(int(event.get("side", BattleSim.PLAYER))), 0.32, 58.0)
		"projectile_impact":
			var projectile: Dictionary = event.projectile
			_play_unit_hit(int(projectile.get("target_id", -1)))
			show_impact(projectile, true)
		"projectile_dissipated":
			show_impact(event.projectile, false)
		"tower_shot":
			_pulse_tower(int(event.side), int(event.lane), false, 1.0)
		"core_shot":
			_pulse_tower(int(event.side), -1, true, 1.0)
		"tower_hit":
			_pulse_tower(int(event.side), int(event.lane), false, -1.0)
			shake_strength = maxf(shake_strength, 3.0)
		"core_hit":
			_pulse_tower(int(event.side), -1, true, -1.0)
			shake_strength = maxf(shake_strength, 4.5)
		"tower_destroyed":
			var position := Vector2(210.0 if int(event.lane) == 0 else 510.0, 900.0 if int(event.side) == BattleSim.PLAYER else 240.0)
			_add_effect("destroy", position, GOLD, 0.84, 116.0)
			shake_strength = maxf(shake_strength, 9.0)
		"core_destroyed":
			var position := Vector2(360.0, 955.0 if int(event.side) == BattleSim.PLAYER else 205.0)
			_add_effect("destroy", position, GOLD, 1.05, 155.0)
			shake_strength = maxf(shake_strength, 13.0)
		"unit_defeated":
			_add_effect("defeat", Vector2(event.get("position", Vector2.ZERO)), _team_color(int(event.get("side", BattleSim.PLAYER))), 0.58, 72.0)
		"spell":
			show_spell(String(event.card), int(event.side), int(event.lane))
	queue_redraw()


func set_targeting(card_type: String, hovered_lane := -1) -> void:
	targeting_type = card_type
	targeting_lane = hovered_lane
	queue_redraw()


func begin_deploy_preview(card_id: String) -> void:
	preview_card = card_id
	preview_lane = -1
	preview_valid = false
	queue_redraw()


func update_deploy_preview(local_position: Vector2) -> void:
	preview_position = local_position
	var sim_position := to_sim_position(local_position)
	if is_inf(sim_position.x) or preview_card.is_empty():
		preview_lane = -1
		preview_valid = false
		queue_redraw()
		return
	preview_lane = lane_at(sim_position)
	var is_unit := String(BattleSim.CARDS[preview_card].type) == "unit"
	preview_valid = is_player_half(sim_position) if is_unit else not is_player_half(sim_position)
	targeting_type = String(BattleSim.CARDS[preview_card].type)
	targeting_lane = preview_lane
	queue_redraw()


func end_deploy_preview() -> void:
	preview_card = ""
	preview_lane = -1
	preview_valid = false
	queue_redraw()


func show_impact(projectile: Dictionary, impacted: bool) -> void:
	var color := _team_color(int(projectile.side))
	if String(projectile.kind) == "alchemist":
		color = Color("ffc253")
	_add_effect("impact" if impacted else "dissipate", Vector2(float(projectile.to_x), float(projectile.to_y)), color, 0.42 if impacted else 0.25, 62.0)
	if impacted:
		shake_strength = maxf(shake_strength, 2.6)


func show_spell(card_id: String, side: int, lane: int) -> void:
	var target := Vector2(210.0 if lane == 0 else 510.0, 310.0 if side == BattleSim.PLAYER else 830.0)
	var color := Color("ff9a3d") if card_id == "fireball" else Color("6ee3ff")
	_add_effect(card_id, target, color, 0.78, 125.0)
	shake_strength = maxf(shake_strength, 7.0 if card_id == "fireball" else 4.0)


func to_sim_position(local_position: Vector2) -> Vector2:
	if not arena_rect.has_point(local_position) or arena_rect.size.x <= 0.0 or arena_rect.size.y <= 0.0:
		return Vector2(INF, INF)
	var normalized := (local_position - arena_rect.position) / arena_rect.size
	return Vector2(normalized.x * DESIGN_WIDTH, DESIGN_TOP + normalized.y * DESIGN_HEIGHT)


func lane_at(sim_position: Vector2) -> int:
	return 0 if sim_position.x < DESIGN_WIDTH * 0.5 else 1


func is_player_half(sim_position: Vector2) -> bool:
	return sim_position.y >= HALF_Y


func _process(delta: float) -> void:
	animation_time += delta
	shake_strength = maxf(0.0, shake_strength - delta * 22.0)
	camera_offset = Vector2(sin(animation_time * 73.0), cos(animation_time * 91.0)) * shake_strength
	for id in unit_positions.keys():
		var position_state: Dictionary = unit_positions[id]
		position_state.current = Vector2(position_state.current).lerp(Vector2(position_state.target), minf(1.0, delta * 13.0))
		unit_positions[id] = position_state
		if unit_views.has(id):
			var view: UnitView2D = unit_views[id]
			view.position = _to_screen(Vector2(position_state.current))
			view.set_world_scale(_uniform_scale())
			view.z_index = int(Vector2(position_state.current).y)
	for index in range(dying_views.size() - 1, -1, -1):
		var dying := dying_views[index]
		dying.set_world_scale(_uniform_scale())
		if dying.is_finished():
			dying.queue_free()
			dying_views.remove_at(index)
	for key in tower_pulses.keys():
		var value := float(tower_pulses[key])
		value = move_toward(value, 0.0, delta * 4.8)
		if absf(value) < 0.01:
			tower_pulses.erase(key)
		else:
			tower_pulses[key] = value
	for index in range(effects.size() - 1, -1, -1):
		effects[index].time = float(effects[index].time) + delta
		if float(effects[index].time) >= float(effects[index].duration):
			effects.remove_at(index)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("06101c"))
	if arena_rect.size.x <= 0.0:
		return
	var draw_rect_value := Rect2(arena_rect.position + camera_offset, arena_rect.size)
	draw_rect(draw_rect_value.grow(7.0), Color(0.0, 0.0, 0.0, 0.58), true)
	draw_texture_rect(ARENA_TEXTURE, draw_rect_value, false)
	_draw_ambient()
	_draw_targeting()
	if simulation != null:
		_draw_objectives()
		_draw_projectiles()
	_draw_effects()
	_draw_preview()
	draw_rect(draw_rect_value, Color("61d7ff"), false, 3.0)


func _update_arena_rect() -> void:
	var available := Vector2(maxf(1.0, size.x - 12.0), maxf(1.0, size.y - 8.0))
	var target_size := available
	if available.x / available.y > ARENA_ASPECT:
		target_size.x = available.y * ARENA_ASPECT
	else:
		target_size.y = available.x / ARENA_ASPECT
	arena_rect = Rect2((size - target_size) * 0.5, target_size)
	queue_redraw()


func _draw_ambient() -> void:
	var river_y := _to_screen(Vector2(360, HALF_Y)).y
	for index in range(9):
		var phase := animation_time * (24.0 + index) + index * 47.0
		var x := arena_rect.position.x + fmod(phase, arena_rect.size.x + 90.0) - 45.0
		var alpha := 0.08 + float(index % 3) * 0.025
		draw_line(Vector2(x, river_y - 18 + index * 4), Vector2(x + 36, river_y - 18 + index * 4), Color(0.72, 0.97, 1.0, alpha), maxf(1.0, 2.0 * _uniform_scale()))
	for index in range(14):
		var seed := float(index * 83)
		var px := arena_rect.position.x + fmod(seed + animation_time * (4.0 + index % 4), arena_rect.size.x)
		var py := arena_rect.position.y + fmod(seed * 1.7 - animation_time * (7.0 + index % 3), arena_rect.size.y)
		draw_circle(Vector2(px, py), maxf(1.0, 1.8 * _uniform_scale()), Color(1.0, 0.89, 0.42, 0.16))


func _draw_targeting() -> void:
	if targeting_type.is_empty():
		return
	for half in range(2):
		var player_half := half == 1
		var valid := player_half if targeting_type == "unit" else not player_half
		for lane in range(2):
			var design_rect := Rect2(lane * 360.0, HALF_Y if player_half else DESIGN_TOP, 360.0, DESIGN_TOP + DESIGN_HEIGHT - HALF_Y if player_half else HALF_Y - DESIGN_TOP)
			var screen_rect := _design_rect_to_screen(design_rect)
			var color := Color("56edaa") if valid else Color("ff6578")
			color.a = 0.23 if valid and lane == targeting_lane else 0.095 if valid else 0.045
			draw_rect(screen_rect, color, true)
			var border := color
			border.a = 0.82 if valid and lane == targeting_lane else 0.20
			draw_rect(screen_rect.grow(-4.0), border, false, 3.0)


func _draw_preview() -> void:
	if preview_card.is_empty():
		return
	var color := Color("5aefad") if preview_valid else Color("ff6679")
	var position := preview_position
	draw_circle(position, 42.0 * _uniform_scale(), Color(color, 0.18))
	draw_arc(position, 42.0 * _uniform_scale(), 0.0, TAU, 36, color, maxf(3.0, 4.0 * _uniform_scale()))
	var ghost_rect := Rect2(position - Vector2(38, 52) * _uniform_scale(), Vector2(76, 76) * _uniform_scale())
	if preview_card in ["fireball", "frost"]:
		var half_width := SPELL_ART.get_width() * 0.5
		var source := Rect2(0.0 if preview_card == "fireball" else half_width, 0.0, half_width, SPELL_ART.get_height())
		draw_texture_rect_region(SPELL_ART, ghost_rect, source, Color(1, 1, 1, 0.72))
	else:
		var definition := UnitRigDefinition.for_card(preview_card)
		draw_texture_rect_region(definition.atlas, ghost_rect, definition.frame_region("idle", 0, true), Color(1, 1, 1, 0.76))


func _draw_objectives() -> void:
	for side in [BattleSim.PLAYER, BattleSim.ENEMY]:
		var tower_y := 900.0 if side == BattleSim.PLAYER else 240.0
		var core_y := 955.0 if side == BattleSim.PLAYER else 205.0
		for lane in range(BattleSim.LANE_COUNT):
			_draw_tower(Vector2(210.0 if lane == 0 else 510.0, tower_y), side, lane, float(simulation.towers[side].lanes[lane]), 1200.0, false)
		_draw_tower(Vector2(360.0, core_y), side, -1, float(simulation.towers[side].core), BattleSim.CORE_MAX_HEALTH, true)


func _draw_tower(center_design: Vector2, side: int, lane: int, hp: float, maximum: float, is_core: bool) -> void:
	var center := _to_screen(center_design)
	var scale_value := _uniform_scale()
	var key := _tower_key(side, lane, is_core)
	var pulse := float(tower_pulses.get(key, 0.0))
	var base_radius := (59.0 if is_core else 45.0) * scale_value
	draw_circle(center + Vector2(6, 24) * scale_value, base_radius, Color(0.01, 0.03, 0.03, 0.34))
	draw_circle(center, base_radius * 0.92, Color(_team_color(side), 0.13))
	draw_arc(center, base_radius * 0.94, 0.0, TAU, 36, Color(_team_color(side), 0.88), maxf(2.0, 4.0 * scale_value))
	if hp <= 0.0:
		var debris_size := Vector2(154, 116) * scale_value
		draw_texture_rect_region(TOWER_PARTS, Rect2(center - debris_size * Vector2(0.5, 0.62), debris_size), _tower_cell(7), Color(0.72, 0.72, 0.72, 0.88))
		return
	var cell_index := 6 if is_core and pulse > 0.34 else 5 if is_core else 2 if pulse > 0.42 else 1
	var design_size := Vector2(186, 172) if is_core else Vector2(146, 142)
	var pulse_scale := 1.0 + absf(pulse) * 0.055
	var image_size := design_size * scale_value * pulse_scale
	var tint := Color(1.0, 0.62, 0.62) if pulse < -0.08 else Color.WHITE
	draw_texture_rect_region(TOWER_PARTS, Rect2(center - image_size * Vector2(0.5, 0.60), image_size), _tower_cell(cell_index), tint)
	if is_core and simulation.is_core_active(side):
		draw_arc(center - Vector2(0, 10) * scale_value, 69.0 * scale_value, animation_time, animation_time + PI * 1.42, 30, GOLD, maxf(2.0, 4.0 * scale_value))
	var width := (100.0 if is_core else 82.0) * scale_value
	var hp_position := Vector2(center.x - width * 0.5, center.y - (88.0 if is_core else 73.0) * scale_value)
	_draw_health_bar(hp_position, width, hp, maximum)
	var label_rect := Rect2(center.x - 44.0 * scale_value, hp_position.y - 24.0 * scale_value, 88.0 * scale_value, 20.0 * scale_value)
	draw_string(BODY_FONT, label_rect.position + Vector2(0.0, 16.0 * scale_value), str(int(hp)), HORIZONTAL_ALIGNMENT_CENTER, label_rect.size.x, maxi(10, int(15.0 * scale_value)), Color.WHITE)


func _draw_projectiles() -> void:
	for projectile in simulation.projectiles:
		var start := _to_screen(Vector2(float(projectile.from_x), float(projectile.from_y)))
		var finish := _to_screen(Vector2(float(projectile.to_x), float(projectile.to_y)))
		var progress := clampf(float(projectile.elapsed) / maxf(0.001, float(projectile.duration)), 0.0, 1.0)
		var position := start.lerp(finish, smoothstep(0.0, 1.0, progress))
		position.y -= sin(progress * PI) * 54.0 * _uniform_scale()
		var color := _team_color(int(projectile.side)).lightened(0.28)
		if String(projectile.kind) == "alchemist":
			color = Color("ffc550")
		elif String(projectile.kind) == "ranger":
			color = Color("fff0b0")
		var previous := start.lerp(position, 0.72)
		draw_line(previous, position, Color(color, 0.32), maxf(6.0, 13.0 * _uniform_scale()))
		draw_line(previous, position, color, maxf(2.0, 5.0 * _uniform_scale()))
		draw_circle(position, 10.0 * _uniform_scale(), Color(color, 0.38))
		draw_circle(position, 5.0 * _uniform_scale(), Color.WHITE)


func _draw_effects() -> void:
	for effect in effects:
		var progress := clampf(float(effect.time) / maxf(0.001, float(effect.duration)), 0.0, 1.0)
		var opacity := 1.0 - progress
		var center := _to_screen(Vector2(effect.position))
		var radius := lerpf(10.0, float(effect.radius), progress) * _uniform_scale()
		var color: Color = effect.color
		color.a = opacity
		match String(effect.kind):
			"deploy":
				draw_circle(center, radius * 0.58, Color(color, opacity * 0.13))
				draw_arc(center, radius, 0.0, TAU, 32, color, maxf(2.0, 6.0 * _uniform_scale()))
			"fireball":
				draw_circle(center, radius, Color("ff8d36", opacity * 0.22))
				for ray in range(10):
					var direction := Vector2.RIGHT.rotated(float(ray) * TAU / 10.0)
					draw_line(center + direction * radius * 0.35, center + direction * radius * 1.18, color, maxf(2.0, 5.0 * _uniform_scale()))
			"frost":
				draw_circle(center, radius, Color("75eaff", opacity * 0.18))
				draw_arc(center, radius, -PI * 0.5, PI * 1.5, 36, color, maxf(3.0, 7.0 * _uniform_scale()))
				for ray in range(6):
					var direction := Vector2.UP.rotated(float(ray) * TAU / 6.0)
					draw_line(center, center + direction * radius * 0.82, color, maxf(2.0, 4.0 * _uniform_scale()))
			"destroy":
				draw_circle(center, radius, Color(GOLD, opacity * 0.20))
				for ray in range(12):
					var direction := Vector2.RIGHT.rotated(float(ray) * TAU / 12.0)
					draw_circle(center + direction * radius, maxf(2.0, 7.0 * _uniform_scale() * opacity), color)
			"melee":
				var slash_angle := -0.9 + progress * 1.8
				draw_arc(center, radius, slash_angle - 0.7, slash_angle + 0.7, 16, Color.WHITE, maxf(2.0, 8.0 * _uniform_scale() * opacity))
				draw_arc(center, radius * 0.72, slash_angle - 0.6, slash_angle + 0.6, 14, color, maxf(2.0, 5.0 * _uniform_scale() * opacity))
			"defeat":
				draw_circle(center, radius * 0.52, Color(color, opacity * 0.12))
				for ray in range(8):
					var direction := Vector2.UP.rotated(float(ray) * TAU / 8.0 + 0.25)
					var particle := center + direction * radius * (0.45 + progress * 0.65)
					draw_circle(particle, maxf(1.5, 5.0 * _uniform_scale() * opacity), Color(color.lightened(0.35), opacity))
			_:
				draw_circle(center, radius * 0.48, Color(color, opacity * 0.16))
				draw_arc(center, radius, 0.0, TAU, 28, color, maxf(2.0, 5.0 * _uniform_scale()))


func _draw_health_bar(position: Vector2, width: float, value: float, maximum: float) -> void:
	var height := maxf(7.0, 10.0 * _uniform_scale())
	draw_rect(Rect2(position, Vector2(width, height)), Color(0.02, 0.04, 0.07, 0.92), true)
	var ratio := clampf(value / maxf(1.0, maximum), 0.0, 1.0)
	var color := Color("5be37f") if ratio > 0.30 else Color("ffbf50")
	draw_rect(Rect2(position + Vector2(2, 2), Vector2(maxf(0.0, width - 4.0) * ratio, maxf(1.0, height - 4.0))), color, true)


func _play_unit_attack(id: int) -> void:
	if unit_views.has(id):
		var view: UnitView2D = unit_views[id]
		view.play_attack()


func _play_unit_hit(id: int) -> void:
	if unit_views.has(id):
		var view: UnitView2D = unit_views[id]
		view.play_hit()


func _pulse_tower(side: int, lane: int, is_core: bool, value: float) -> void:
	tower_pulses[_tower_key(side, lane, is_core)] = value


func _tower_key(side: int, lane: int, is_core: bool) -> String:
	return "%d:%s:%d" % [side, "core" if is_core else "lane", lane]


func _tower_cell(index: int) -> Rect2:
	var cell := Vector2(TOWER_PARTS.get_width() / 4.0, TOWER_PARTS.get_height() / 2.0)
	return Rect2(Vector2(index % 4, index / 4) * cell, cell)


func _unit_design_position(unit: Dictionary) -> Vector2:
	return Vector2(210.0 if int(unit.lane) == 0 else 510.0, float(unit.y)) + Vector2(float(unit.get("formation_x", 0.0)), 0.0)


func _snapshot_position(snapshot: Dictionary) -> Vector2:
	if snapshot.is_empty():
		return Vector2.ZERO
	return Vector2(210.0 if int(snapshot.get("lane", 0)) == 0 else 510.0, float(snapshot.get("y", HALF_Y))) + Vector2(float(snapshot.get("formation_x", 0.0)), 0.0)


func _to_screen(design_position: Vector2) -> Vector2:
	return arena_rect.position + camera_offset + Vector2(design_position.x / DESIGN_WIDTH * arena_rect.size.x, (design_position.y - DESIGN_TOP) / DESIGN_HEIGHT * arena_rect.size.y)


func _design_rect_to_screen(design_rect: Rect2) -> Rect2:
	var top_left := _to_screen(design_rect.position)
	var bottom_right := _to_screen(design_rect.end)
	return Rect2(top_left, bottom_right - top_left)


func _uniform_scale() -> float:
	return arena_rect.size.x / DESIGN_WIDTH


func _team_color(side: int) -> Color:
	return TEAM_BLUE if side == BattleSim.PLAYER else TEAM_RED


func _add_effect(kind: String, position: Vector2, color: Color, duration: float, radius: float) -> void:
	effects.append({"kind": kind, "position": position, "color": color, "duration": duration, "time": 0.0, "radius": radius})
