class_name BattleWorld3D
extends Node3D

const UnitViewScript := preload("res://scripts/visual/unit_view_3d.gd")
const TEAM_BLUE := Color("29b6f6")
const TEAM_RED := Color("ff496d")

var camera: Camera3D
var unit_views: Dictionary = {}
var dying_views: Array[UnitView3D] = []
var projectile_views: Dictionary = {}
var objective_views: Dictionary = {}
var targeting_panels: Array[MeshInstance3D] = []
var effects: Array[Dictionary] = []


func _ready() -> void:
	_build_environment()
	_build_arena()
	_build_camera()


func sync(simulation: BattleSim) -> void:
	var active_units := {}
	for unit in simulation.units:
		var id := int(unit.id)
		active_units[id] = true
		if not unit_views.has(id):
			var view: UnitView3D = UnitViewScript.new()
			add_child(view)
			view.setup(id, String(unit.card_id), int(unit.side))
			view.position = sim_to_world(float(unit.y), int(unit.lane), float(unit.get("formation_x", 0.0)))
			unit_views[id] = view
		var existing: UnitView3D = unit_views[id]
		existing.sync_state(unit, sim_to_world(float(unit.y), int(unit.lane), float(unit.get("formation_x", 0.0))))
	for id in unit_views.keys():
		if not active_units.has(id):
			var defeated: UnitView3D = unit_views[id]
			defeated.die()
			dying_views.append(defeated)
			unit_views.erase(id)

	var active_projectiles := {}
	for projectile in simulation.projectiles:
		var projectile_id := int(projectile.id)
		active_projectiles[projectile_id] = true
		if not projectile_views.has(projectile_id):
			var view := _create_projectile(String(projectile.kind), int(projectile.side))
			add_child(view)
			projectile_views[projectile_id] = view
		var projectile_view: Node3D = projectile_views[projectile_id]
		var start := sim_point_to_world(float(projectile.from_x), float(projectile.from_y), 1.15)
		var finish := sim_point_to_world(float(projectile.to_x), float(projectile.to_y), 1.05)
		var progress := clampf(float(projectile.elapsed) / maxf(0.001, float(projectile.duration)), 0.0, 1.0)
		projectile_view.position = start.lerp(finish, progress) + Vector3.UP * sin(progress * PI) * 1.1
		projectile_view.look_at(finish, Vector3.UP)
	for id in projectile_views.keys():
		if not active_projectiles.has(id):
			projectile_views[id].queue_free()
			projectile_views.erase(id)
	_sync_objectives(simulation)


func show_impact(projectile: Dictionary, impacted: bool) -> void:
	var position := sim_point_to_world(float(projectile.to_x), float(projectile.to_y), 0.24)
	var color := TEAM_BLUE if int(projectile.side) == 0 else TEAM_RED
	if String(projectile.kind) == "alchemist":
		color = Color("63f5b5")
	var ring := _cylinder(0.28, 0.03, color, true)
	ring.position = position
	add_child(ring)
	effects.append({"node": ring, "time": 0.0, "duration": 0.34 if impacted else 0.22})


func show_spell(card_id: String, side: int, lane: int) -> void:
	var z := -3.0 if side == 0 else 3.0
	var x := -2.2 if lane == 0 else 2.2
	var color := Color("ff9a3c") if card_id == "fireball" else Color("68dcff")
	var burst := _cylinder(1.25, 0.06, color, true)
	burst.position = Vector3(x, 0.22, z)
	add_child(burst)
	effects.append({"node": burst, "time": 0.0, "duration": 0.55})


func set_targeting(card_type: String, hovered_lane := -1) -> void:
	for index in range(targeting_panels.size()):
		var panel := targeting_panels[index]
		panel.visible = not card_type.is_empty()
		if card_type.is_empty():
			continue
		var player_half := index < 2
		var valid := player_half if card_type == "unit" else not player_half
		var lane := index % 2
		var base := Color("4ee7a7") if valid else Color("ff5274")
		base.a = 0.30 if lane == hovered_lane and valid else 0.13 if valid else 0.055
		panel.material_override.albedo_color = base


func screen_to_arena(viewport_position: Vector2) -> Vector3:
	if camera == null:
		return Vector3(INF, INF, INF)
	var origin := camera.project_ray_origin(viewport_position)
	var direction := camera.project_ray_normal(viewport_position)
	if absf(direction.y) < 0.0001:
		return Vector3(INF, INF, INF)
	var distance := (0.12 - origin.y) / direction.y
	return origin + direction * distance


func world_lane(position: Vector3) -> int:
	return 0 if position.x < 0.0 else 1


func is_player_half(position: Vector3) -> bool:
	return position.z > 0.0


func sim_to_world(y: float, lane: int, formation_x := 0.0) -> Vector3:
	var x := -2.25 if lane == 0 else 2.25
	return Vector3(x + formation_x / 95.0, 0.16, (y - 580.0) / 58.0)


func sim_point_to_world(x: float, y: float, height := 0.16) -> Vector3:
	return Vector3((x - 360.0) / 68.0, height, (y - 580.0) / 58.0)


func _process(delta: float) -> void:
	for index in range(dying_views.size() - 1, -1, -1):
		if dying_views[index].is_death_finished():
			dying_views[index].queue_free()
			dying_views.remove_at(index)
	for index in range(effects.size() - 1, -1, -1):
		var effect := effects[index]
		effect.time = float(effect.time) + delta
		var progress := clampf(float(effect.time) / float(effect.duration), 0.0, 1.0)
		var node: Node3D = effect.node
		node.scale = Vector3.ONE * lerpf(0.5, 3.4, progress)
		if node is MeshInstance3D and node.material_override:
			node.material_override.albedo_color.a = 1.0 - progress
		if progress >= 1.0:
			node.queue_free()
			effects.remove_at(index)


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("173447")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d9efff")
	environment.ambient_light_energy = 0.62
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-54.0, -28.0, 0.0)
	sun.light_energy = 1.25
	sun.light_color = Color("fff2d0")
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 28.0
	add_child(sun)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 17.4
	camera.position = Vector3(0.0, 15.5, 12.8)
	camera.look_at_from_position(camera.position, Vector3(0.0, 0.0, 0.0), Vector3.UP)
	camera.current = true
	add_child(camera)


func _build_arena() -> void:
	var underlay := _box(Vector3(12.2, 0.45, 18.8), Color("294c3e"))
	underlay.position.y = -0.25
	add_child(underlay)
	for row in range(14):
		for column in range(8):
			var tile_color := Color("65a94e") if (row + column) % 2 == 0 else Color("70b755")
			var tile := _box(Vector3(1.35, 0.08, 1.26), tile_color, false)
			tile.position = Vector3((float(column) - 3.5) * 1.35, 0.02, (float(row) - 6.5) * 1.26)
			add_child(tile)
	var river := _box(Vector3(11.2, 0.10, 1.25), Color("27a9d2"), false)
	river.position.y = 0.09
	add_child(river)
	for lane_x in [-2.25, 2.25]:
		var bridge := _box(Vector3(1.72, 0.24, 1.55), Color("b9783c"))
		bridge.position = Vector3(lane_x, 0.23, 0.0)
		add_child(bridge)
		for plank in range(5):
			var line := _box(Vector3(1.78, 0.04, 0.07), Color("704224"), false)
			line.position = Vector3(lane_x, 0.37, -0.55 + plank * 0.28)
			add_child(line)
	_build_borders()
	_build_objectives()
	_build_targeting_panels()


func _build_borders() -> void:
	for x in [-5.85, 5.85]:
		var wall := _box(Vector3(0.55, 0.6, 18.8), Color("667260"))
		wall.position = Vector3(x, 0.20, 0.0)
		add_child(wall)
	for z in [-9.15, 9.15]:
		var wall := _box(Vector3(12.2, 0.6, 0.55), Color("667260"))
		wall.position = Vector3(0.0, 0.20, z)
		add_child(wall)


func _build_objectives() -> void:
	for side in [0, 1]:
		var z_lane := 5.55 if side == 0 else -5.55
		var z_core := 7.0 if side == 0 else -7.0
		for lane in range(2):
			var tower := _tower_model(TEAM_BLUE if side == 0 else TEAM_RED, false)
			tower.position = Vector3(-2.25 if lane == 0 else 2.25, 0.15, z_lane)
			add_child(tower)
			objective_views["%d_%d" % [side, lane]] = tower
		var core := _tower_model(TEAM_BLUE if side == 0 else TEAM_RED, true)
		core.position = Vector3(0.0, 0.15, z_core)
		add_child(core)
		objective_views["%d_core" % side] = core


func _tower_model(team: Color, core: bool) -> Node3D:
	var root := Node3D.new()
	var base := _cylinder(0.85 if core else 0.67, 0.62, Color("60717a"))
	base.position.y = 0.32
	root.add_child(base)
	var keep := _box(Vector3(1.35 if core else 1.05, 1.25 if core else 1.0, 1.15 if core else 0.95), Color("738793"))
	keep.position.y = 1.15 if core else 1.0
	root.add_child(keep)
	var roof := _cylinder(0.88 if core else 0.70, 0.25, Color("445965"))
	roof.position.y = 1.86 if core else 1.58
	root.add_child(roof)
	var banner := _box(Vector3(0.54, 0.58, 0.09), team, false)
	banner.position = Vector3(0.0, 1.62 if core else 1.34, -0.61)
	root.add_child(banner)
	root.set_meta("banner", banner)
	return root


func _sync_objectives(simulation: BattleSim) -> void:
	for side in [0, 1]:
		for lane in range(2):
			var tower: Node3D = objective_views["%d_%d" % [side, lane]]
			var hp := float(simulation.towers[side].lanes[lane])
			tower.scale = Vector3.ONE if hp > 0.0 else Vector3(1.0, 0.32, 1.0)
		var core: Node3D = objective_views["%d_core" % side]
		var core_hp := float(simulation.towers[side].core)
		core.scale = Vector3.ONE if core_hp > 0.0 else Vector3(1.0, 0.25, 1.0)


func _build_targeting_panels() -> void:
	for player_half in [true, false]:
		for lane in range(2):
			var panel := _box(Vector3(4.65, 0.035, 7.3), Color(0.3, 1.0, 0.65, 0.1), false, true)
			panel.position = Vector3(-2.55 if lane == 0 else 2.55, 0.16, 4.25 if player_half else -4.25)
			panel.visible = false
			add_child(panel)
			targeting_panels.append(panel)


func _create_projectile(kind: String, side: int) -> Node3D:
	var root := Node3D.new()
	var color := TEAM_BLUE if side == 0 else TEAM_RED
	if kind == "ranger":
		var shaft := _cylinder(0.045, 0.8, Color("f1d49a"), false)
		shaft.rotation.x = PI * 0.5
		root.add_child(shaft)
	elif kind == "alchemist":
		root.add_child(_sphere(0.22, Color("5dffbf")))
	else:
		root.add_child(_sphere(0.16 if kind == "tower" else 0.21, color.lightened(0.28)))
	var light := OmniLight3D.new()
	light.omni_range = 2.2
	light.light_energy = 1.1
	light.light_color = color
	root.add_child(light)
	return root


func _material(color: Color, transparent := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	if transparent or color.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _box(size: Vector3, color: Color, shadows := true, transparent := false) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(color, transparent)
	instance.mesh = mesh
	instance.material_override = mesh.material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


func _sphere(radius: float, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 7
	mesh.material = _material(color)
	instance.mesh = mesh
	return instance


func _cylinder(radius: float, height: float, color: Color, transparent := false) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 18
	mesh.material = _material(color, transparent)
	instance.mesh = mesh
	instance.material_override = mesh.material
	return instance
