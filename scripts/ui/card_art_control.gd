class_name CardArtControl
extends Control

const SPELL_ART := preload("res://assets/v040/ui/spell-art-v040.png")

var card_id := "guardian"
var animation_time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func set_card(value: String) -> void:
	card_id = value
	queue_redraw()


func _process(delta: float) -> void:
	animation_time += delta
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	if card_id in ["fireball", "frost"]:
		var half_width := SPELL_ART.get_width() * 0.5
		var source := Rect2(0.0 if card_id == "fireball" else half_width, 0.0, half_width, SPELL_ART.get_height())
		draw_texture_rect_region(SPELL_ART, rect, source)
		return
	var definition := UnitRigDefinition.for_card(card_id)
	draw_rect(rect, definition.card_background, true)
	var center := Vector2(rect.size.x * 0.5, rect.size.y * 0.52)
	var glow_radius := minf(rect.size.x, rect.size.y) * (0.44 + sin(animation_time * 1.8) * 0.012)
	draw_circle(center, glow_radius, Color(definition.accent, 0.17))
	draw_circle(center, glow_radius * 0.68, Color(definition.accent, 0.10))
	for ray in range(10):
		var angle := float(ray) * TAU / 10.0 + animation_time * 0.04
		var direction := Vector2.RIGHT.rotated(angle)
		draw_line(center + direction * glow_radius * 0.78, center + direction * glow_radius * 1.08, Color(definition.accent, 0.13), 2.0)
	var art_size := minf(rect.size.x * 0.98, rect.size.y * 1.25)
	var pulse := 1.0 + sin(animation_time * 2.2) * 0.016
	var art_rect := Rect2(center - Vector2.ONE * art_size * 0.5 + Vector2(0.0, rect.size.y * 0.06), Vector2.ONE * art_size * pulse)
	var idle_frame := int(animation_time * definition.state_fps("idle"))
	draw_texture_rect_region(definition.atlas, art_rect, definition.frame_region("idle", idle_frame, false))
	draw_rect(Rect2(Vector2(0.0, rect.size.y - 4.0), Vector2(rect.size.x, 4.0)), Color(definition.accent, 0.78), true)
