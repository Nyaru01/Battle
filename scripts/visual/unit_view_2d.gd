class_name UnitView2D
extends Node2D

const PART_ORDER := ["far_leg", "far_arm", "torso", "head", "near_leg", "near_arm", "weapon", "accessory"]
const PART_CELLS := {
	"torso": Vector2i(0, 0), "head": Vector2i(1, 0), "far_arm": Vector2i(2, 0), "near_arm": Vector2i(3, 0),
	"far_leg": Vector2i(0, 1), "near_leg": Vector2i(1, 1), "weapon": Vector2i(2, 1), "accessory": Vector2i(3, 1),
}
const BASE_OFFSETS := {
	"torso": Vector2(0, -29), "head": Vector2(0, -68), "far_arm": Vector2(-27, -31), "near_arm": Vector2(27, -31),
	"far_leg": Vector2(-14, 18), "near_leg": Vector2(14, 18), "weapon": Vector2(35, -17), "accessory": Vector2(-38, -19),
}

var unit_id := -1
var side := BattleSim.PLAYER
var definition: UnitRigDefinition
var sprites: Dictionary = {}
var hp := 1.0
var max_hp := 1.0
var moving := false
var walk_phase := 0.0
var last_attack_pulse := 0.0
var animation_time := 0.0
var spawn_timer := 0.38
var attack_timer := 0.0
var hit_timer := 0.0
var death_timer := 0.0
var dying := false
var finished := false
var pose_scale := 1.0
var world_scale := 1.0


func configure(id: int, card_id: String, team: int) -> void:
	unit_id = id
	side = team
	definition = UnitRigDefinition.for_card(card_id)
	pose_scale = definition.visual_scale / 0.24
	_build_parts()
	queue_redraw()


func sync_state(unit: Dictionary) -> void:
	var previous_hp := hp
	hp = float(unit.hp)
	max_hp = maxf(1.0, float(unit.max_hp))
	moving = bool(unit.get("moving", false))
	walk_phase = float(unit.get("walk_phase", animation_time * 7.0))
	var pulse := float(unit.get("attack_pulse", 0.0))
	if pulse > 0.12 and last_attack_pulse <= 0.12:
		play_attack()
	last_attack_pulse = pulse
	if hp < previous_hp - 0.01:
		play_hit()
	queue_redraw()


func play_attack() -> void:
	if not dying:
		attack_timer = 0.34 if definition.motion_profile != "heavy" else 0.48


func play_hit() -> void:
	if not dying:
		hit_timer = 0.22


func play_death() -> void:
	if dying:
		return
	dying = true
	death_timer = 0.62
	moving = false


func is_finished() -> bool:
	return finished


func set_world_scale(value: float) -> void:
	world_scale = value


func _build_parts() -> void:
	for child in get_children():
		child.queue_free()
	sprites.clear()
	var back_row_offset := 2 if side == BattleSim.PLAYER else 0
	for part_name in PART_ORDER:
		var cell: Vector2i = PART_CELLS[part_name]
		var sprite := Sprite2D.new()
		sprite.texture = definition.cell_texture(cell.y + back_row_offset, cell.x)
		sprite.scale = Vector2.ONE * definition.visual_scale
		sprite.position = Vector2(BASE_OFFSETS[part_name]) * pose_scale
		sprite.z_index = PART_ORDER.find(part_name)
		add_child(sprite)
		sprites[part_name] = sprite


func _process(delta: float) -> void:
	animation_time += delta
	spawn_timer = maxf(0.0, spawn_timer - delta)
	attack_timer = maxf(0.0, attack_timer - delta)
	hit_timer = maxf(0.0, hit_timer - delta)
	if dying:
		death_timer = maxf(0.0, death_timer - delta)
		if death_timer <= 0.0:
			finished = true
	_apply_pose()
	queue_redraw()


func _apply_pose() -> void:
	if definition == null:
		return
	var idle := sin(animation_time * 3.2 + float(unit_id) * 0.7)
	var stride := sin(walk_phase)
	var body_bob := absf(stride) * 3.0 if moving else idle * 1.5
	for part_name in sprites:
		var sprite: Sprite2D = sprites[part_name]
		sprite.position = Vector2(BASE_OFFSETS[part_name]) * pose_scale + Vector2(0, -body_bob)
		sprite.rotation = 0.0
		sprite.modulate = Color.WHITE
	var torso: Sprite2D = sprites.torso
	var head: Sprite2D = sprites.head
	var far_arm: Sprite2D = sprites.far_arm
	var near_arm: Sprite2D = sprites.near_arm
	var far_leg: Sprite2D = sprites.far_leg
	var near_leg: Sprite2D = sprites.near_leg
	var weapon: Sprite2D = sprites.weapon
	var accessory: Sprite2D = sprites.accessory
	torso.rotation = idle * 0.018
	head.rotation = -idle * 0.028
	if moving:
		far_leg.rotation = stride * 0.19
		near_leg.rotation = -stride * 0.19
		far_arm.rotation = -stride * 0.14
		near_arm.rotation = stride * 0.14
		weapon.rotation = stride * 0.10
		accessory.rotation = -stride * 0.06
	else:
		far_arm.rotation = idle * 0.025
		near_arm.rotation = -idle * 0.025
	var attack_duration := 0.48 if definition.motion_profile == "heavy" else 0.34
	if attack_timer > 0.0:
		var progress := 1.0 - attack_timer / attack_duration
		var strike := sin(progress * PI)
		match definition.motion_profile:
			"ranged":
				near_arm.rotation -= strike * 0.34
				weapon.position.x += strike * 8.0
				weapon.rotation -= strike * 0.12
				torso.position.x -= strike * 3.0
			"dual":
				far_arm.rotation -= strike * 0.92
				near_arm.rotation += strike * 0.92
				weapon.rotation -= strike * 1.05
				accessory.rotation += strike * 1.05
				torso.rotation += (progress - 0.5) * 0.14
			"heavy":
				near_arm.rotation -= strike * 0.74
				weapon.rotation -= strike * 0.86
				torso.position.y += strike * 5.0
			_:
				near_arm.rotation -= strike * 0.82
				weapon.rotation -= strike * 1.0
				torso.rotation -= strike * 0.08
	if hit_timer > 0.0:
		var hit_strength := hit_timer / 0.22
		var hit_offset := sin(hit_strength * PI * 3.0) * 4.0
		for sprite in sprites.values():
			sprite.position.x += hit_offset
			sprite.modulate = Color(1.0, 0.52 + 0.48 * (1.0 - hit_strength), 0.52 + 0.48 * (1.0 - hit_strength))
	var spawn_progress := 1.0 - spawn_timer / 0.38
	if spawn_timer > 0.0:
		var bounce := 1.0 + sin(spawn_progress * PI) * 0.18
		scale = Vector2.ONE * world_scale * lerpf(0.42, bounce, spawn_progress)
		modulate.a = spawn_progress
	elif dying:
		var remaining := death_timer / 0.62
		scale = Vector2(0.84 + remaining * 0.16, maxf(0.08, remaining)) * world_scale
		rotation = (1.0 - remaining) * (0.42 if unit_id % 2 == 0 else -0.42)
		modulate.a = remaining
	else:
		scale = Vector2.ONE * world_scale
		rotation = 0.0
		modulate.a = 1.0


func _draw() -> void:
	if definition == null:
		return
	var alpha := modulate.a
	draw_circle(Vector2(5, 31), 29.0 * pose_scale, Color(0.01, 0.03, 0.05, 0.28 * alpha))
	draw_circle(Vector2(0, 28), 24.0 * pose_scale, Color(definition.accent, 0.14 * alpha))
	draw_arc(Vector2(0, 28), 25.0 * pose_scale, 0.0, TAU, 28, Color(definition.accent, 0.82 * alpha), 2.5)
	var width := 58.0 * pose_scale
	var bar_position := Vector2(-width * 0.5, -105.0 * pose_scale)
	draw_rect(Rect2(bar_position, Vector2(width, 8)), Color(0.02, 0.04, 0.07, 0.92 * alpha), true)
	var ratio := clampf(hp / max_hp, 0.0, 1.0)
	var health_color := Color("5ee483") if ratio > 0.3 else Color("ffbd52")
	health_color.a = alpha
	draw_rect(Rect2(bar_position + Vector2(2, 2), Vector2((width - 4) * ratio, 4)), health_color, true)
