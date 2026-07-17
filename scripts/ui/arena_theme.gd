class_name ArenaTheme
extends RefCounted

const HEADING_FONT: Font = preload("res://assets/fonts/Baloo2-Variable.ttf")
const BODY_FONT: Font = preload("res://assets/fonts/Nunito-Variable.ttf")
const KENNEY_BUTTON_BLUE: Texture2D = preload("res://assets/v050/ui/button-long-blue.png")
const KENNEY_BUTTON_BLUE_PRESSED: Texture2D = preload("res://assets/v050/ui/button-long-blue-pressed.png")
const KENNEY_BUTTON_GOLD: Texture2D = preload("res://assets/v050/ui/button-long-gold.png")
const KENNEY_BUTTON_GOLD_PRESSED: Texture2D = preload("res://assets/v050/ui/button-long-gold-pressed.png")

const NAVY := Color("0a2240")
const NAVY_DARK := Color("06162c")
const NAVY_RAISED := Color("123b68")
const NAVY_LIGHT := Color("246ba2")
const BLUE := Color("1676d2")
const CYAN := Color("63dcff")
const GOLD := Color("f6c548")
const GOLD_LIGHT := Color("fff0a6")
const RED := Color("e64e63")
const GREEN := Color("49d77f")
const MAGENTA := Color("b54bdd")
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
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
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


static func royal_panel(background := Color("0d315b"), border := CYAN, radius := 20) -> StyleBoxFlat:
	var style := panel(background, border, radius, 3, 10)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	style.border_color = Color(border, 0.78)
	return style


static func home_surface(background := Color("0b2949"), border := Color("3d7fac"), radius := 18, shadow := 5) -> StyleBoxFlat:
	var style := panel(background, Color(border, 0.62), radius, 1, shadow)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style


static func home_chip(accent := CYAN, filled := false) -> StyleBoxFlat:
	var background := Color(accent, 0.90) if filled else Color(0.02, 0.10, 0.19, 0.82)
	var border := Color(GOLD_LIGHT, 0.80) if filled else Color(accent, 0.48)
	var style := panel(background, border, 13, 1, 0)
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style


static func nav_button(active: bool, pressed := false) -> StyleBoxFlat:
	var background := Color("173d63") if active else Color("091d35")
	var border := Color(GOLD, 0.82) if active else Color("315b7c")
	if pressed:
		background = background.darkened(0.14)
	var style := panel(background, border, 14, 2 if active else 1, 2 if pressed else 4)
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	return style


static func chip(active: bool, accent := GOLD) -> StyleBoxFlat:
	var background := Color(accent, 0.96) if active else Color("11365e")
	var border := GOLD_LIGHT if active else Color("417bac")
	var style := panel(background, border, 18, 3, 4)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	return style


static func kenney_button(pressed := false, gold := false) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = KENNEY_BUTTON_GOLD_PRESSED if gold and pressed else KENNEY_BUTTON_GOLD if gold else KENNEY_BUTTON_BLUE_PRESSED if pressed else KENNEY_BUTTON_BLUE
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, 11.0)
		style.set_content_margin(side, 7.0)
	style.modulate_color = Color("ffe28b") if gold else Color("8ddcff")
	return style


static func button_colors(kind: String) -> Array[Color]:
	match kind:
		"primary": return [BLUE, CYAN, Color("0b4b96")]
		"gold": return [Color("d99c19"), GOLD_LIGHT, Color("8b5b08")]
		"success": return [Color("24a95b"), Color("90f4ae"), Color("116438")]
		"danger": return [Color("b62e47"), Color("ff9caa"), Color("71172c")]
		_: return [NAVY_RAISED, Color("6bb8e9"), NAVY_DARK]


static func apply_button(button: BaseButton, kind: String, font_size: int) -> void:
	var colors := button_colors(kind)
	button.add_theme_stylebox_override("normal", panel(colors[0], colors[1], 18, 4, 8))
	button.add_theme_stylebox_override("hover", panel(colors[0].lightened(0.08), colors[1].lightened(0.10), 18, 4, 10))
	button.add_theme_stylebox_override("pressed", panel(colors[0].darkened(0.13), colors[2], 18, 4, 3))
	button.add_theme_stylebox_override("focus", panel(colors[0], GOLD_LIGHT, 18, 5, 10))
	button.add_theme_stylebox_override("disabled", panel(Color("26343d"), Color("465965"), 16, 2, 3))
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
		"guardian": Color("17558d"), "ranger": Color("24704d"), "colossus": Color("795238"),
		"fireball": Color("913d2f"), "duelist": Color("66418e"), "alchemist": Color("713f8e"),
		"bulwark": Color("405d72"), "frost": Color("23789e"),
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
