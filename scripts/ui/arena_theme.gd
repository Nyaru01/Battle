class_name ArenaTheme
extends RefCounted

const HEADING_FONT: Font = preload("res://assets/fonts/LilitaOne-Regular.ttf")
const BODY_FONT: Font = preload("res://assets/fonts/Nunito-Variable.ttf")

const NAVY := Color("081522")
const NAVY_RAISED := Color("102b42")
const NAVY_LIGHT := Color("194862")
const BLUE := Color("167ec5")
const CYAN := Color("56d7ff")
const GOLD := Color("f2bd42")
const GOLD_LIGHT := Color("ffe38a")
const RED := Color("d9475c")
const GREEN := Color("55d985")
const MAGENTA := Color("c84fe1")
const TEXT := Color("f7fbff")
const TEXT_MUTED := Color("b9d0db")


static func root_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = BODY_FONT
	theme.default_font_size = 16
	return theme


static func panel(background: Color, border: Color, radius := 16, border_width := 3, shadow := 7) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.46)
	style.shadow_size = shadow
	style.shadow_offset = Vector2(0.0, 4.0)
	style.anti_aliasing = true
	return style


static func inset_panel(background := NAVY_RAISED, border := NAVY_LIGHT, radius := 14) -> StyleBoxFlat:
	var style := panel(background, border, radius, 3, 5)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style


static func button_colors(kind: String) -> Array[Color]:
	match kind:
		"primary": return [Color("087cbd"), CYAN, Color("075a89")]
		"gold": return [Color("a66d12"), GOLD_LIGHT, Color("714408")]
		"danger": return [Color("9d3045"), Color("ff8495"), Color("661d30")]
		_: return [NAVY_RAISED, Color("4e86a0"), Color("091b2a")]


static func apply_button(button: BaseButton, kind: String, font_size: int) -> void:
	var colors := button_colors(kind)
	button.add_theme_stylebox_override("normal", panel(colors[0], colors[1], 14, 3, 6))
	button.add_theme_stylebox_override("hover", panel(colors[0].lightened(0.08), colors[1].lightened(0.10), 14, 3, 8))
	button.add_theme_stylebox_override("pressed", panel(colors[0].darkened(0.13), colors[2], 14, 4, 3))
	button.add_theme_stylebox_override("focus", panel(colors[0], GOLD_LIGHT, 14, 4, 8))
	button.add_theme_stylebox_override("disabled", panel(Color("26343d"), Color("465965"), 14, 2, 3))
	button.add_theme_font_override("font", HEADING_FONT)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("75858e"))
	button.add_theme_constant_override("outline_size", 4)
	button.add_theme_color_override("font_outline_color", Color(0.02, 0.06, 0.10, 0.72))
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 48.0)


static func apply_heading(label: Label, font_size: int, color := TEXT) -> void:
	label.add_theme_font_override("font", HEADING_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.09, 0.78))


static func apply_body(label: Label, font_size: int, color := TEXT_MUTED) -> void:
	label.add_theme_font_override("font", BODY_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)


static func card_style(card_id: String, selected: bool, disabled: bool) -> StyleBoxFlat:
	var colors := {
		"guardian": Color("245c7b"), "ranger": Color("397052"), "colossus": Color("715039"),
		"fireball": Color("8a3d2b"), "duelist": Color("604485"), "alchemist": Color("87532f"),
		"bulwark": Color("435b66"), "frost": Color("2d7798"),
	}
	var background: Color = colors.get(card_id, NAVY_RAISED)
	if disabled:
		background = background.darkened(0.52)
	var border := GOLD_LIGHT if selected else background.lightened(0.30)
	return panel(background, border, 12, 5 if selected else 3, 9 if selected else 5)


static func badge(background := MAGENTA, border := Color("f3a5ff")) -> StyleBoxFlat:
	var style := panel(background, border, 18, 3, 4)
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	return style
