class_name RoyalBackdrop
extends Control

var animation_time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	animation_time += delta
	queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), ArenaTheme.NAVY_DARK, true)
	var bands := [Color("0a2240"), Color("0d2b50"), Color("10365f"), Color("0d2b50"), Color("0a2240")]
	var band_height := size.y / float(bands.size())
	for index in bands.size():
		draw_rect(Rect2(0.0, band_height * index, size.x, band_height + 1.0), bands[index], true)
	var glow_center := Vector2(size.x * 0.5, size.y * 0.28)
	for radius_index in range(7, 0, -1):
		var radius := minf(size.x, size.y) * 0.08 * float(radius_index)
		draw_circle(glow_center, radius, Color(ArenaTheme.BLUE, 0.014 * float(8 - radius_index)))
	for ray in range(12):
		var angle := float(ray) * TAU / 12.0 + sin(animation_time * 0.08) * 0.015
		var direction := Vector2.RIGHT.rotated(angle)
		draw_line(glow_center + direction * 50.0, glow_center + direction * size.y * 0.52, Color(ArenaTheme.CYAN, 0.045), 3.0)
	for star_index in range(18):
		var x := fposmod(float(star_index * 137), size.x)
		var y := fposmod(float(star_index * 83), size.y * 0.78)
		var pulse := 0.20 + sin(animation_time * 1.4 + star_index) * 0.10
		draw_circle(Vector2(x, y), 1.5 + float(star_index % 3), Color(ArenaTheme.CYAN, pulse))
	draw_rect(Rect2(0.0, size.y * 0.82, size.x, size.y * 0.18), Color("07172c"), true)
	draw_line(Vector2(0.0, size.y * 0.82), Vector2(size.x, size.y * 0.82), Color(ArenaTheme.GOLD, 0.24), 2.0)
