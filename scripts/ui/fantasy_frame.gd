class_name FantasyFrame
extends Control

enum FrameKind { HEADER, DOCK }

var frame_kind := FrameKind.HEADER


func configure(kind: FrameKind) -> void:
	frame_kind = kind
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var cut := 15.0 if frame_kind == FrameKind.HEADER else 18.0
	var outer := _notched_rect(Rect2(Vector2.ZERO, size), cut)
	draw_colored_polygon(outer, Color("5b3b1d"))
	draw_polyline(_closed(outer), Color("f2c65b"), 2.0, true)
	var inner_rect := Rect2(Vector2(4, 4), size - Vector2(8, 8))
	var inner := _notched_rect(inner_rect, maxf(7.0, cut - 5.0))
	draw_colored_polygon(inner, Color(0.025, 0.075, 0.125, 0.96))
	draw_polyline(_closed(inner), Color("9b7133"), 1.5, true)
	draw_line(Vector2(cut + 8, 6), Vector2(size.x - cut - 8, 6), Color(1.0, 0.88, 0.48, 0.62), 1.5)
	var jewel_y := size.y * 0.5
	_draw_jewel(Vector2(7, jewel_y), 5.0)
	_draw_jewel(Vector2(size.x - 7, jewel_y), 5.0)


func _notched_rect(rect: Rect2, cut: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(rect.position.x + cut, rect.position.y),
		Vector2(rect.end.x - cut, rect.position.y),
		Vector2(rect.end.x, rect.position.y + cut),
		Vector2(rect.end.x, rect.end.y - cut),
		Vector2(rect.end.x - cut, rect.end.y),
		Vector2(rect.position.x + cut, rect.end.y),
		Vector2(rect.position.x, rect.end.y - cut),
		Vector2(rect.position.x, rect.position.y + cut),
	])


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	result.append(points[0])
	return result


func _draw_jewel(center: Vector2, radius: float) -> void:
	var diamond := PackedVector2Array([
		center + Vector2(0, -radius), center + Vector2(radius, 0),
		center + Vector2(0, radius), center + Vector2(-radius, 0),
	])
	draw_colored_polygon(diamond, Color("31c9f2"))
	draw_polyline(_closed(diamond), Color("d8f8ff"), 1.0, true)
