class_name BattleAnnouncement
extends PanelContainer

var title_label: Label
var subtitle_label: Label
var accent := ArenaTheme.GOLD
var duration := 1.7
var remaining := 0.0
var message_count := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	set_process(false)
	pivot_offset = size * 0.5
	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", -3)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layout)
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ArenaTheme.apply_heading(title_label, 28, Color.WHITE)
	layout.add_child(title_label)
	subtitle_label = Label.new()
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ArenaTheme.apply_heading(subtitle_label, 11, ArenaTheme.TEXT_MUTED)
	layout.add_child(subtitle_label)


func show_message(title: String, subtitle: String, color: Color, display_duration := 1.7) -> void:
	if title_label == null:
		return
	accent = color
	duration = maxf(0.5, display_duration)
	remaining = duration
	message_count += 1
	title_label.text = title
	title_label.add_theme_color_override("font_color", color)
	subtitle_label.text = subtitle
	add_theme_stylebox_override("panel", ArenaTheme.royal_panel(Color(0.02, 0.08, 0.15, 0.94), color, 22))
	visible = true
	modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.82, 0.82)
	pivot_offset = size * 0.5
	set_process(true)


func _process(delta: float) -> void:
	remaining = maxf(0.0, remaining - delta)
	var elapsed := duration - remaining
	if elapsed < 0.18:
		var entrance := smoothstep(0.0, 1.0, elapsed / 0.18)
		modulate.a = entrance
		scale = Vector2.ONE * lerpf(0.82, 1.0, entrance)
	elif remaining < 0.28:
		var exit_progress := 1.0 - remaining / 0.28
		modulate.a = 1.0 - exit_progress
		scale = Vector2.ONE * lerpf(1.0, 1.06, exit_progress)
	else:
		modulate.a = 1.0
		scale = Vector2.ONE
	if remaining <= 0.0:
		visible = false
		set_process(false)
