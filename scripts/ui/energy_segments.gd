class_name EnergySegments
extends Control

@export var maximum := 10.0
@export var value := 0.0:
	set(new_value):
		value = clampf(new_value, 0.0, maximum)
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y = 22.0


func _draw() -> void:
	var gap := 3.0
	var segment_width := (size.x - gap * 9.0) / 10.0
	for index in 10:
		var rect := Rect2(index * (segment_width + gap), 1.0, segment_width, maxf(1.0, size.y - 2.0))
		draw_style_box(ArenaTheme.panel(Color("261936"), Color("67407b"), 6, 2, 1), rect)
		var fill := clampf(value - float(index), 0.0, 1.0)
		if fill > 0.0:
			var inner := rect.grow(-3.0)
			inner.size.x *= fill
			draw_rect(inner, ArenaTheme.MAGENTA, true)
			if fill > 0.45:
				draw_line(inner.position + Vector2(2.0, 2.0), inner.position + Vector2(inner.size.x - 2.0, 2.0), Color("f2a8ff"), 2.0)
