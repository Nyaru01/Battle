class_name BattleWorld2D
extends Control

const ARENA_TEXTURE: Texture2D = preload("res://assets/arena-v2.png")
const TOWER_SPRITES: Texture2D = preload("res://assets/tower-sprites-v3.png")
const UNIT_SPRITES: Texture2D = preload("res://assets/unit-sprites-v3.png")
const UNIT_SPRITES_V4: Texture2D = preload("res://assets/unit-sprites-v4.png")
const BODY_FONT: Font = preload("res://assets/fonts/Nunito-Variable.ttf")
const HEADING_FONT: Font = preload("res://assets/fonts/LilitaOne-Regular.ttf")

const DESIGN_WIDTH := 720.0
const DESIGN_TOP := 82.0
const DESIGN_HEIGHT := 982.0
const ARENA_ASPECT := 0.70
const HALF_Y := 580.0
const TEAM_BLUE := Color("35b9ff")
const TEAM_RED := Color("ff536b")
const GOLD := Color("ffd766")

var simulation: BattleSim
var arena_rect := Rect2()
var unit_views: Dictionary = {}
var dying_views: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var targeting_type := ""
var targeting_lane := -1
var animation_time := 0.0


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
			unit_views[id] = {
				"current": target,
				"target": target,
				"snapshot": unit.duplicate(true),
				"last_hp": float(unit.hp),
				"hit": 0.0,
			}
			_add_effect("deploy", target, _team_color(int(unit.side)), 0.42, 58.0)
		var view: Dictionary = unit_views[id]
		view.target = target
		if float(unit.hp) < float(view.last_hp):
			view.hit = 1.0
		view.last_hp = float(unit.hp)
		view.snapshot = unit.duplicate(true)
		unit_views[id] = view
	for id in unit_views.keys():
		if not active.has(id):
			var defeated: Dictionary = unit_views[id]
			defeated.ttl = 0.48
			dying_views.append(defeated)
			unit_views.erase(id)
	queue_redraw()


func set_targeting(card_type: String, hovered_lane := -1) -> void:
	targeting_type = card_type
	targeting_lane = hovered_lane
	queue_redraw()


func show_impact(projectile: Dictionary, impacted: bool) -> void:
	var color := _team_color(int(projectile.side))
	if String(projectile.kind) == "alchemist":
		color = Color("66efb6")
	_add_effect("impact" if impacted else "dissipate", Vector2(float(projectile.to_x), float(projectile.to_y)), color, 0.34 if impacted else 0.22, 54.0)


func show_spell(card_id: String, side: int, lane: int) -> void:
	var target := Vector2(210.0 if lane == 0 else 510.0, 285.0 if side == BattleSim.PLAYER else 855.0)
	var color := Color("ff9a3d") if card_id == "fireball" else Color("6ee3ff")
	_add_effect("spell", target, color, 0.58, 100.0)


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
	for id in unit_views.keys():
		var view: Dictionary = unit_views[id]
		view.current = Vector2(view.current).lerp(Vector2(view.target), minf(1.0, delta * 13.0))
		view.hit = maxf(0.0, float(view.hit) - delta * 5.5)
		unit_views[id] = view
	for index in range(dying_views.size() - 1, -1, -1):
		dying_views[index].ttl = float(dying_views[index].ttl) - delta
		if float(dying_views[index].ttl) <= 0.0:
			dying_views.remove_at(index)
	for index in range(effects.size() - 1, -1, -1):
		effects[index].time = float(effects[index].time) + delta
		if float(effects[index].time) >= float(effects[index].duration):
			effects.remove_at(index)
	if simulation != null:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("07131f"))
	if arena_rect.size.x <= 0.0:
		return
	draw_rect(arena_rect.grow(6.0), Color(0.0, 0.0, 0.0, 0.58), true)
	draw_texture_rect_region(ARENA_TEXTURE, arena_rect, Rect2(92.0, 100.0, 840.0, 1200.0))
	draw_rect(arena_rect, Color("4ca8c9"), false, 3.0)
	_draw_targeting()
	if simulation == null:
		return
	_draw_objectives()
	_draw_units()
	_draw_projectiles()
	_draw_effects()


func _update_arena_rect() -> void:
	var available := Vector2(maxf(1.0, size.x - 12.0), maxf(1.0, size.y - 8.0))
	var target_size := available
	if available.x / available.y > ARENA_ASPECT:
		target_size.x = available.y * ARENA_ASPECT
	else:
		target_size.y = available.x / ARENA_ASPECT
	arena_rect = Rect2((size - target_size) * 0.5, target_size)
	queue_redraw()


func _draw_targeting() -> void:
	if targeting_type.is_empty():
		return
	for half in range(2):
		var is_player := half == 1
		var valid := is_player if targeting_type == "unit" else not is_player
		for lane in range(2):
			var design_rect := Rect2(lane * 360.0, HALF_Y if is_player else DESIGN_TOP, 360.0, DESIGN_TOP + DESIGN_HEIGHT - HALF_Y if is_player else HALF_Y - DESIGN_TOP)
			var screen_rect := _design_rect_to_screen(design_rect)
			var color := Color("4ce3a1") if valid else Color("ef5367")
			color.a = 0.23 if valid and lane == targeting_lane else 0.11 if valid else 0.055
			draw_rect(screen_rect, color, true)
			var border := color
			border.a = 0.78 if valid and lane == targeting_lane else 0.28
			draw_rect(screen_rect.grow(-4.0), border, false, 3.0)
	if targeting_lane >= 0:
		var center := _to_screen(Vector2(210.0 if targeting_lane == 0 else 510.0, 780.0 if targeting_type == "unit" else 330.0))
		var accent := Color("66f0bd")
		var radius := 42.0 * _uniform_scale()
		draw_circle(center, radius, Color(accent, 0.12))
		draw_arc(center, radius, 0.0, TAU, 32, accent, maxf(2.0, 4.0 * _uniform_scale()))
		draw_line(center - Vector2(radius * 0.45, 0.0), center + Vector2(radius * 0.45, 0.0), accent, 2.0)
		draw_line(center - Vector2(0.0, radius * 0.45), center + Vector2(0.0, radius * 0.45), accent, 2.0)


func _draw_objectives() -> void:
	for side in [BattleSim.PLAYER, BattleSim.ENEMY]:
		var tower_y := 900.0 if side == BattleSim.PLAYER else 240.0
		var core_y := 955.0 if side == BattleSim.PLAYER else 205.0
		for lane in range(BattleSim.LANE_COUNT):
			_draw_tower(Vector2(210.0 if lane == 0 else 510.0, tower_y), side, float(simulation.towers[side].lanes[lane]), 1200.0, false, false)
		_draw_tower(Vector2(360.0, core_y), side, float(simulation.towers[side].core), BattleSim.CORE_MAX_HEALTH, true, simulation.is_core_active(side))


func _draw_tower(center_design: Vector2, side: int, hp: float, maximum: float, is_core: bool, active: bool) -> void:
	var source_width := TOWER_SPRITES.get_width() * 0.5
	var source := Rect2(source_width if is_core else 0.0, 0.0, source_width, TOWER_SPRITES.get_height())
	var design_size := Vector2(170.0, 150.0) if is_core else Vector2(138.0, 142.0)
	var scale_value := _uniform_scale()
	var image_size := design_size * scale_value
	var center := _to_screen(center_design)
	var destination := Rect2(center.x - image_size.x * 0.5, center.y - image_size.y * 0.60, image_size.x, image_size.y)
	draw_circle(center + Vector2(7.0, 27.0) * scale_value, (39.0 if is_core else 31.0) * scale_value, Color(0.02, 0.05, 0.04, 0.34))
	if is_core and active and hp > 0.0:
		draw_arc(center + Vector2(0.0, 4.0) * scale_value, 67.0 * scale_value, 0.0, TAU, 36, GOLD, maxf(2.0, 4.0 * scale_value))
	var tint := Color.WHITE if hp > 0.0 else Color(0.32, 0.34, 0.36, 0.62)
	draw_texture_rect_region(TOWER_SPRITES, destination, source, tint)
	var banner_width := (52.0 if is_core else 42.0) * scale_value
	var banner_height := 18.0 * scale_value
	var banner_y := center.y - (28.0 if is_core else 22.0) * scale_value
	var team := _team_color(side) if hp > 0.0 else Color("45494c")
	draw_rect(Rect2(center.x - banner_width * 0.5, banner_y, banner_width, banner_height), team, true)
	var hp_position := Vector2(center.x - design_size.x * 0.31 * scale_value, center.y - design_size.y * 0.55 * scale_value)
	_draw_health_bar(hp_position, design_size.x * 0.62 * scale_value, hp, maximum, true)
	if hp > 0.0:
		var label_rect := Rect2(center.x - 38.0 * scale_value, hp_position.y - 24.0 * scale_value, 76.0 * scale_value, 20.0 * scale_value)
		draw_string(BODY_FONT, label_rect.position + Vector2(0.0, 16.0 * scale_value), str(int(hp)), HORIZONTAL_ALIGNMENT_CENTER, label_rect.size.x, maxi(10, int(15.0 * scale_value)), Color.WHITE)


func _draw_units() -> void:
	var ordered: Array[Dictionary] = []
	for view in unit_views.values():
		ordered.append(view)
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.current.y) < float(b.current.y))
	for view in ordered:
		_draw_unit_view(view, 1.0)
	for view in dying_views:
		_draw_unit_view(view, clampf(float(view.ttl) / 0.48, 0.0, 1.0))


func _draw_unit_view(view: Dictionary, opacity: float) -> void:
	var unit: Dictionary = view.snapshot
	var center_design: Vector2 = view.current
	var movement := sin(float(unit.get("walk_phase", animation_time * 8.0))) if bool(unit.get("moving", false)) else 0.0
	center_design.y -= absf(movement) * 4.0
	var center := _to_screen(center_design)
	var data := _unit_sprite_data(String(unit.card_id))
	var radius: float = float(data.radius) * _uniform_scale()
	var team := _team_color(int(unit.side))
	var hit: float = float(view.get("hit", 0.0))
	draw_circle(center + Vector2(5.0, 20.0) * _uniform_scale(), radius * 0.96, Color(0.02, 0.05, 0.04, 0.36 * opacity))
	draw_circle(center + Vector2(0.0, 18.0) * _uniform_scale(), radius * 0.75, Color(team, 0.24 * opacity))
	draw_arc(center + Vector2(0.0, 18.0) * _uniform_scale(), radius * 0.78, 0.0, TAU, 28, Color(team, opacity), maxf(2.0, 3.0 * _uniform_scale()))
	var image_size: Vector2 = Vector2(data.size) * _uniform_scale() * lerpf(0.84, 1.0, opacity)
	var destination := Rect2(center.x - image_size.x * 0.5, center.y - image_size.y * 0.66, image_size.x, image_size.y)
	var tint := Color(1.0, 1.0 - hit * 0.38, 1.0 - hit * 0.38, opacity)
	draw_texture_rect_region(data.texture, destination, data.source, tint)
	if float(unit.get("attack_pulse", 0.0)) > 0.0:
		var pulse := 1.0 + float(unit.attack_pulse) * 0.8
		draw_arc(center, radius * pulse, -0.7, 0.7, 12, Color("fff0a6"), maxf(2.0, 4.0 * _uniform_scale()))
	_draw_health_bar(Vector2(center.x - radius, center.y - radius - 12.0 * _uniform_scale()), radius * 2.0, float(unit.hp), float(unit.max_hp), false, opacity)
	var slow_time := float(unit.get("slow_timer", 0.0))
	if slow_time > 0.0:
		var remaining := clampf(slow_time / float(BattleSim.CARDS.frost.slow_duration), 0.0, 1.0)
		draw_arc(center, radius + 8.0 * _uniform_scale(), -PI * 0.5, -PI * 0.5 + TAU * remaining, 28, Color("75e6ff"), maxf(2.0, 4.0 * _uniform_scale()))


func _draw_projectiles() -> void:
	for projectile in simulation.projectiles:
		var start := _to_screen(Vector2(float(projectile.from_x), float(projectile.from_y)))
		var finish := _to_screen(Vector2(float(projectile.to_x), float(projectile.to_y)))
		var progress := clampf(float(projectile.elapsed) / maxf(0.001, float(projectile.duration)), 0.0, 1.0)
		var position := start.lerp(finish, smoothstep(0.0, 1.0, progress))
		position.y -= sin(progress * PI) * 48.0 * _uniform_scale()
		var color := _team_color(int(projectile.side)).lightened(0.28)
		if String(projectile.kind) == "alchemist":
			color = Color("64f5b5")
		elif String(projectile.kind) == "ranger":
			color = Color("f2d59b")
		var previous := start.lerp(position, 0.76)
		draw_line(previous, position, Color(color, 0.34), maxf(4.0, 10.0 * _uniform_scale()))
		draw_line(previous, position, color, maxf(2.0, 4.0 * _uniform_scale()))
		draw_circle(position, 8.0 * _uniform_scale(), Color(color, 0.42))
		draw_circle(position, 4.0 * _uniform_scale(), color)


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
				draw_circle(center, radius * 0.58, Color(color, opacity * 0.12))
				draw_arc(center, radius, 0.0, TAU, 28, color, maxf(2.0, 5.0 * _uniform_scale()))
			"spell":
				draw_circle(center, radius, Color(color, opacity * 0.20))
				draw_arc(center, radius, 0.0, TAU, 32, color, maxf(3.0, 6.0 * _uniform_scale()))
				for ray in range(8):
					var direction := Vector2.RIGHT.rotated(float(ray) * TAU / 8.0)
					draw_line(center + direction * radius * 0.55, center + direction * radius * 1.15, color, maxf(2.0, 3.0 * _uniform_scale()))
			_:
				draw_circle(center, radius * 0.48, Color(color, opacity * 0.16))
				draw_arc(center, radius, 0.0, TAU, 28, color, maxf(2.0, 4.0 * _uniform_scale()))


func _draw_health_bar(position: Vector2, width: float, value: float, maximum: float, framed: bool, opacity := 1.0) -> void:
	var height := maxf(6.0, (9.0 if framed else 7.0) * _uniform_scale())
	draw_rect(Rect2(position, Vector2(width, height)), Color(0.03, 0.06, 0.09, 0.88 * opacity), true)
	var ratio := clampf(value / maxf(1.0, maximum), 0.0, 1.0)
	var color := Color("5be37f") if ratio > 0.30 else Color("ffbf50")
	color.a = opacity
	draw_rect(Rect2(position + Vector2(1.5, 1.5), Vector2(maxf(0.0, width - 3.0) * ratio, maxf(1.0, height - 3.0))), color, true)


func _unit_sprite_data(card_id: String) -> Dictionary:
	match card_id:
		"ranger": return {"texture": UNIT_SPRITES, "source": Rect2(650.0, 130.0, 480.0, 650.0), "size": Vector2(86.0, 116.0), "radius": 23.0}
		"colossus": return {"texture": UNIT_SPRITES, "source": Rect2(1100.0, 80.0, 674.0, 710.0), "size": Vector2(132.0, 139.0), "radius": 34.0}
		"duelist": return {"texture": UNIT_SPRITES_V4, "source": Rect2(35.0, 140.0, 520.0, 670.0), "size": Vector2(88.0, 113.0), "radius": 23.0}
		"alchemist": return {"texture": UNIT_SPRITES_V4, "source": Rect2(565.0, 150.0, 515.0, 680.0), "size": Vector2(94.0, 124.0), "radius": 25.0}
		"bulwark": return {"texture": UNIT_SPRITES_V4, "source": Rect2(1090.0, 85.0, 570.0, 760.0), "size": Vector2(128.0, 154.0), "radius": 36.0}
		_: return {"texture": UNIT_SPRITES, "source": Rect2(20.0, 100.0, 630.0, 680.0), "size": Vector2(108.0, 116.0), "radius": 25.0}


func _unit_design_position(unit: Dictionary) -> Vector2:
	return Vector2(210.0 if int(unit.lane) == 0 else 510.0, float(unit.y)) + Vector2(float(unit.get("formation_x", 0.0)), 0.0)


func _to_screen(design_position: Vector2) -> Vector2:
	return arena_rect.position + Vector2(design_position.x / DESIGN_WIDTH * arena_rect.size.x, (design_position.y - DESIGN_TOP) / DESIGN_HEIGHT * arena_rect.size.y)


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
