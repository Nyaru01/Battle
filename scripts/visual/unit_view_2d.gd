class_name UnitView2D
extends Node2D

var unit_id := -1
var side := BattleSim.PLAYER
var definition: UnitRigDefinition
var character_sprite: Sprite2D
var hp := 1.0
var max_hp := 1.0
var moving := false
var walk_phase := 0.0
var last_attack_pulse := 0.0
var animation_time := 0.0
var spawn_elapsed := 0.0
var attack_elapsed := -1.0
var hit_elapsed := -1.0
var death_elapsed := -1.0
var dying := false
var finished := false
var world_scale := 1.0
var current_state := "spawn"
var show_health_bar := true
var show_team_ring := true


func configure(id: int, card_id: String, team: int) -> void:
	unit_id = id
	side = team
	definition = UnitRigDefinition.for_card(card_id)
	_build_character()
	_refresh_frame()
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
		attack_elapsed = 0.0


func play_hit() -> void:
	if not dying:
		hit_elapsed = 0.0


func play_death() -> void:
	if dying:
		return
	dying = true
	death_elapsed = 0.0
	moving = false


func is_finished() -> bool:
	return finished


func set_world_scale(value: float) -> void:
	world_scale = value
	scale = Vector2.ONE * world_scale


func _build_character() -> void:
	for child in get_children():
		child.queue_free()
	character_sprite = Sprite2D.new()
	character_sprite.name = "KayKitCharacter"
	character_sprite.texture = definition.atlas
	character_sprite.region_enabled = true
	character_sprite.region_filter_clip_enabled = true
	character_sprite.scale = Vector2.ONE * definition.visual_scale
	character_sprite.position.y = -36.0
	add_child(character_sprite)


func _process(delta: float) -> void:
	if definition == null:
		return
	animation_time += delta
	spawn_elapsed += delta
	if attack_elapsed >= 0.0:
		attack_elapsed += delta
		if attack_elapsed >= definition.state_duration("attack"):
			attack_elapsed = -1.0
	if hit_elapsed >= 0.0:
		hit_elapsed += delta
		if hit_elapsed >= definition.state_duration("hit"):
			hit_elapsed = -1.0
	if dying:
		death_elapsed += delta
		if death_elapsed >= definition.state_duration("death"):
			finished = true
	_refresh_frame()
	queue_redraw()


func _refresh_frame() -> void:
	if definition == null or character_sprite == null:
		return
	var elapsed := animation_time
	if dying:
		current_state = "death"
		elapsed = death_elapsed
	elif hit_elapsed >= 0.0:
		current_state = "hit"
		elapsed = hit_elapsed
	elif attack_elapsed >= 0.0:
		current_state = "attack"
		elapsed = attack_elapsed
	elif spawn_elapsed < definition.state_duration("spawn"):
		current_state = "spawn"
		elapsed = spawn_elapsed
	elif moving:
		current_state = "walk"
		elapsed = animation_time
	else:
		current_state = "idle"
		elapsed = animation_time + float(posmod(unit_id, 7)) * 0.11
	var frame := int(floor(elapsed * definition.state_fps(current_state)))
	character_sprite.region_rect = definition.frame_region(current_state, frame, side == BattleSim.PLAYER)
	character_sprite.modulate = Color(1.0, 0.58, 0.58) if hit_elapsed >= 0.0 else Color.WHITE
	if current_state == "spawn":
		character_sprite.modulate.a = clampf(spawn_elapsed * 7.0, 0.0, 1.0)


func _draw() -> void:
	if definition == null:
		return
	var alpha := character_sprite.modulate.a if character_sprite != null else 1.0
	var footprint_scale := definition.visual_scale / 0.58
	var team_color := ArenaTheme.CYAN if side == BattleSim.PLAYER else Color("ff6378")
	draw_circle(Vector2(5, 31), 31.0 * footprint_scale, Color(0.01, 0.03, 0.05, 0.32 * alpha))
	if show_team_ring:
		draw_circle(Vector2(0, 28), 25.0 * footprint_scale, Color(team_color, 0.14 * alpha))
		draw_arc(Vector2(0, 28), 26.0 * footprint_scale, 0.0, TAU, 30, Color(team_color, 0.90 * alpha), 3.0)
	if not show_health_bar:
		return
	var width := 65.0 * footprint_scale
	var bar_position := Vector2(-width * 0.5, -104.0 * footprint_scale)
	draw_rect(Rect2(bar_position, Vector2(width, 11)), Color(team_color, 0.96 * alpha), true)
	draw_rect(Rect2(bar_position + Vector2(2, 2), Vector2(width - 4.0, 7)), Color(0.02, 0.04, 0.07, 0.96 * alpha), true)
	var ratio := clampf(hp / max_hp, 0.0, 1.0)
	var health_color := Color("49d77f") if ratio > 0.3 else Color("f6c548")
	health_color.a = alpha
	draw_rect(Rect2(bar_position + Vector2(4, 4), Vector2((width - 8.0) * ratio, 3)), health_color, true)
