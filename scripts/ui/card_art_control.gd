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
	var pulse := 1.0 + sin(animation_time * 2.2) * 0.018
	var torso_size := Vector2(rect.size.x * 0.88, rect.size.y * 1.18) * pulse
	var torso_rect := Rect2(Vector2(rect.size.x * 0.5 - torso_size.x * 0.5, rect.size.y * 0.23 - torso_size.y * 0.18), torso_size)
	var head_size := Vector2(rect.size.x * 0.78, rect.size.y * 0.96) * pulse
	var head_rect := Rect2(Vector2(rect.size.x * 0.5 - head_size.x * 0.5, -rect.size.y * 0.08 + sin(animation_time * 2.2) * 2.0), head_size)
	draw_circle(Vector2(rect.size.x * 0.5, rect.size.y * 0.48), minf(rect.size.x, rect.size.y) * 0.43, Color(definition.accent, 0.13))
	draw_texture_rect_region(definition.atlas, torso_rect, definition.cell_region(0, 0))
	draw_texture_rect_region(definition.atlas, head_rect, definition.cell_region(0, 1))
