class_name UnitView3D
extends Node3D

const TEAM_BLUE := Color("36b9ff")
const TEAM_RED := Color("ff5274")
const SKIN := Color("f2b98b")
const STEEL := Color("b9cad5")
const DARK_STEEL := Color("344957")

var unit_id := -1
var card_id := "guardian"
var side := 0
var target_position := Vector3.ZERO
var moving := false
var attack_amount := 0.0
var walk_time := 0.0
var hit_amount := 0.0
var dying := false
var death_time := 0.0
var last_hp := 0.0
var visual_scale := 1.0

var model_root: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var weapon_pivot: Node3D
var health_fill: MeshInstance3D


func setup(id_value: int, card_value: String, side_value: int) -> void:
	unit_id = id_value
	card_id = card_value
	side = side_value
	_build_model()
	rotation.y = 0.0 if side == 0 else PI


func sync_state(snapshot: Dictionary, world_position: Vector3) -> void:
	target_position = world_position
	moving = bool(snapshot.get("moving", false))
	attack_amount = maxf(attack_amount, clampf(float(snapshot.get("attack_pulse", 0.0)) / 0.22, 0.0, 1.0))
	var hp := float(snapshot.get("hp", 1.0))
	var max_hp := maxf(1.0, float(snapshot.get("max_hp", 1.0)))
	if last_hp > 0.0 and hp < last_hp:
		hit_amount = 1.0
	last_hp = hp
	if health_fill:
		var ratio := clampf(hp / max_hp, 0.0, 1.0)
		health_fill.scale.x = ratio
		health_fill.position.x = -0.64 * (1.0 - ratio)


func play_hit() -> void:
	hit_amount = 1.0


func die() -> void:
	if dying:
		return
	dying = true
	death_time = 0.0


func is_death_finished() -> bool:
	return dying and death_time >= 0.62


func projectile_socket_position() -> Vector3:
	if weapon_pivot:
		return weapon_pivot.global_position + Vector3(0.0, 0.15, -0.25 if side == 0 else 0.25)
	return global_position + Vector3(0.0, 1.25, 0.0)


func _process(delta: float) -> void:
	if dying:
		death_time += delta
		rotation.z = lerpf(rotation.z, -1.35 if side == 0 else 1.35, minf(1.0, delta * 7.0))
		position.y = maxf(-0.25, position.y - delta * 0.5)
		model_root.scale = Vector3.ONE * maxf(0.55, 1.0 - death_time * 0.45)
		return
	position = position.lerp(target_position, minf(1.0, delta * 13.0))
	attack_amount = maxf(0.0, attack_amount - delta * 4.2)
	hit_amount = maxf(0.0, hit_amount - delta * 5.5)
	if moving:
		walk_time += delta * (8.5 if card_id == "duelist" else 6.8)
	else:
		walk_time += delta * 1.5
	var stride := sin(walk_time) * (0.72 if moving else 0.06)
	var bob := absf(sin(walk_time)) * (0.09 if moving else 0.018)
	model_root.position.y = bob
	left_leg.rotation.x = stride
	right_leg.rotation.x = -stride
	left_arm.rotation.x = -stride * 0.68
	right_arm.rotation.x = stride * 0.68
	var attack_curve := sin((1.0 - attack_amount) * PI)
	if card_id in ["ranger", "alchemist"]:
		left_arm.rotation.x -= attack_curve * 1.05
		right_arm.rotation.x -= attack_curve * 1.35
		right_arm.rotation.z = attack_curve * 0.35
	else:
		right_arm.rotation.x -= attack_curve * 1.65
		right_arm.rotation.z = -attack_curve * 0.7
	model_root.rotation.z = sin(walk_time * 0.5) * 0.025 + hit_amount * (0.12 if side == 0 else -0.12)


func _build_model() -> void:
	model_root = Node3D.new()
	add_child(model_root)
	var team := TEAM_BLUE if side == 0 else TEAM_RED
	var armor := _unit_color(card_id)
	var scale_by_card := {
		"guardian": 1.0, "ranger": 0.88, "colossus": 1.34,
		"duelist": 0.82, "alchemist": 0.96, "bulwark": 1.26,
	}
	visual_scale = float(scale_by_card.get(card_id, 1.0))
	model_root.scale = Vector3.ONE * visual_scale

	var ring := _cylinder(0.78, 0.78, 0.055, team.darkened(0.08), true)
	ring.position.y = 0.03
	model_root.add_child(ring)

	var hips := _box(Vector3(0.72, 0.34, 0.46), DARK_STEEL)
	hips.position.y = 0.83
	model_root.add_child(hips)
	var torso := _box(Vector3(1.0, 0.95, 0.58), armor)
	torso.position.y = 1.42
	model_root.add_child(torso)
	var chest := _box(Vector3(0.74, 0.18, 0.62), team)
	chest.position = Vector3(0.0, 1.55, -0.30)
	model_root.add_child(chest)
	var head := _sphere(0.38, SKIN)
	head.position.y = 2.15
	model_root.add_child(head)
	var helmet := _cylinder(0.43, 0.36, 0.36, armor.lightened(0.18), false)
	helmet.position.y = 2.37
	model_root.add_child(helmet)
	var plume := _box(Vector3(0.14, 0.42, 0.16), team)
	plume.position = Vector3(0.0, 2.72, 0.05)
	model_root.add_child(plume)

	left_leg = _limb(Vector3(-0.25, 0.78, 0.0), 0.72, 0.22, DARK_STEEL)
	right_leg = _limb(Vector3(0.25, 0.78, 0.0), 0.72, 0.22, DARK_STEEL)
	model_root.add_child(left_leg)
	model_root.add_child(right_leg)
	left_arm = _limb(Vector3(-0.62, 1.78, 0.0), 0.78, 0.19, armor.lightened(0.08))
	right_arm = _limb(Vector3(0.62, 1.78, 0.0), 0.78, 0.19, armor.lightened(0.08))
	model_root.add_child(left_arm)
	model_root.add_child(right_arm)
	_add_equipment(team)
	_add_health_bar()


func _add_equipment(team: Color) -> void:
	weapon_pivot = right_arm
	match card_id:
		"ranger":
			var bow := _box(Vector3(0.08, 0.95, 0.12), Color("d79a4b"))
			bow.position = Vector3(0.0, -0.72, -0.20)
			right_arm.add_child(bow)
			var quiver := _box(Vector3(0.30, 0.72, 0.25), Color("79523a"))
			quiver.position = Vector3(0.42, 1.40, 0.34)
			model_root.add_child(quiver)
		"alchemist":
			var bottle := _sphere(0.24, Color("6dffcf"))
			bottle.position = Vector3(0.0, -0.75, -0.15)
			right_arm.add_child(bottle)
		"bulwark":
			var shield := _cylinder(0.58, 0.58, 0.15, team.lightened(0.18), false)
			shield.rotation.x = PI * 0.5
			shield.position = Vector3(0.0, -0.55, -0.42)
			left_arm.add_child(shield)
			_add_sword()
		"colossus":
			var hammer_head := _box(Vector3(0.74, 0.38, 0.38), Color("7f96a3"))
			hammer_head.position = Vector3(0.0, -1.0, -0.12)
			right_arm.add_child(hammer_head)
		"duelist":
			_add_sword()
			var blade := _box(Vector3(0.10, 0.86, 0.12), Color("e9f5ff"))
			blade.position = Vector3(0.0, -0.82, -0.08)
			left_arm.add_child(blade)
		_:
			_add_sword()
			var shield := _cylinder(0.46, 0.46, 0.13, team, false)
			shield.rotation.x = PI * 0.5
			shield.position = Vector3(0.0, -0.55, -0.36)
			left_arm.add_child(shield)


func _add_sword() -> void:
	var blade := _box(Vector3(0.12, 1.0, 0.14), STEEL)
	blade.position = Vector3(0.0, -0.88, -0.10)
	right_arm.add_child(blade)
	var guard := _box(Vector3(0.48, 0.10, 0.16), Color("e7b84d"))
	guard.position = Vector3(0.0, -0.42, -0.10)
	right_arm.add_child(guard)


func _add_health_bar() -> void:
	var back := _box(Vector3(1.34, 0.10, 0.08), Color("18212b"), false)
	back.position = Vector3(0.0, 2.92, 0.0)
	model_root.add_child(back)
	health_fill = _box(Vector3(1.28, 0.065, 0.09), Color("61e57a"), false)
	health_fill.position = Vector3(0.0, 2.92, -0.05)
	model_root.add_child(health_fill)


func _limb(origin: Vector3, length: float, radius: float, color: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = origin
	var mesh := _capsule(radius, length, color)
	mesh.position.y = -length * 0.45
	pivot.add_child(mesh)
	return pivot


func _unit_color(id_value: String) -> Color:
	match id_value:
		"ranger": return Color("5a7f46")
		"colossus": return Color("8a6b54")
		"duelist": return Color("694b86")
		"alchemist": return Color("a05d38")
		"bulwark": return Color("455a68")
		_: return Color("4d6f82")


func _material(color: Color, metallic := 0.0, roughness := 0.72) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material


func _box(size: Vector3, color: Color, shadows := true) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(color, 0.15 if color == STEEL else 0.0)
	instance.mesh = mesh
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


func _capsule(radius: float, height: float, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(height, radius * 2.1)
	mesh.radial_segments = 10
	mesh.rings = 4
	mesh.material = _material(color)
	instance.mesh = mesh
	return instance


func _cylinder(top_radius: float, bottom_radius: float, height: float, color: Color, no_shadow: bool) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 14
	mesh.material = _material(color)
	instance.mesh = mesh
	if no_shadow:
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance
