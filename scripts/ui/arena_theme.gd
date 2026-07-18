class_name ArenaTheme
extends RefCounted

const HEADING_FONT: Font = preload("res://assets/fonts/Baloo2-Variable.ttf")
const BODY_FONT: Font = preload("res://assets/fonts/Nunito-Variable.ttf")
const KENNEY_BUTTON_BLUE: Texture2D = preload("res://assets/v050/ui/button-long-blue.png")
const KENNEY_BUTTON_BLUE_PRESSED: Texture2D = preload("res://assets/v050/ui/button-long-blue-pressed.png")
const KENNEY_BUTTON_GOLD: Texture2D = preload("res://assets/v050/ui/button-long-gold.png")
const KENNEY_BUTTON_GOLD_PRESSED: Texture2D = preload("res://assets/v050/ui/button-long-gold-pressed.png")
const FORGED_BUTTON_BLUE: Texture2D = preload("res://assets/v057/ui/button-forged-blue-v057.png")
const FORGED_BUTTON_COMPACT: Texture2D = preload("res://assets/v058/ui/button-forged-compact-v058.png")
const FORGED_BUTTON_SQUARE: Texture2D = preload("res://assets/v058/ui/button-forged-square-v058.png")

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


static func fantasy_medallion() -> StyleBoxFlat:
	var style := panel(Color("07172a"), Color("e0ae45"), 28, 3, 6)
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style


static func fantasy_badge() -> StyleBoxFlat:
	var style := panel(Color("6f471f"), Color("f2c65b"), 10, 2, 2)
	style.content_margin_left = 7.0
	style.content_margin_right = 7.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	return style


static func fantasy_action(pressed := false, hovered := false) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = FORGED_BUTTON_BLUE
	style.texture_margin_left = 75.0
	style.texture_margin_right = 75.0
	style.texture_margin_top = 0.0
	style.texture_margin_bottom = 0.0
	style.content_margin_left = 64.0
	style.content_margin_right = 64.0
	style.content_margin_top = 9.0
	style.content_margin_bottom = 9.0
	style.modulate_color = Color("c8e5ff") if hovered else Color("b5d3ed") if pressed else Color.WHITE
	return style


static func nav_button(active: bool, pressed := false, hovered := false) -> StyleBoxTexture:
	var style := _forged_button_style(false, pressed, hovered, false, "primary" if active else "secondary")
	style.texture_margin_left = 24.0
	style.texture_margin_right = 24.0
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
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


static func _forged_button_style(square: bool, pressed: bool, hovered: bool, disabled: bool, kind: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = FORGED_BUTTON_SQUARE if square else FORGED_BUTTON_COMPACT
	if square:
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			style.set_texture_margin(side, 0.0)
			style.set_content_margin(side, 7.0)
	else:
		style.texture_margin_left = 50.0
		style.texture_margin_right = 50.0
		style.texture_margin_top = 0.0
		style.texture_margin_bottom = 0.0
		style.content_margin_left = 28.0
		style.content_margin_right = 28.0
		style.content_margin_top = 7.0
		style.content_margin_bottom = 7.0
	var tint := Color.WHITE
	if kind == "secondary":
		tint = Color("b9c7d5")
	elif kind == "danger":
		tint = Color("e0b9c4")
	if hovered:
		tint = tint.lightened(0.12)
	if pressed:
		tint = tint.darkened(0.24)
	if disabled:
		tint = Color(0.35, 0.39, 0.44, 0.72)
	style.modulate_color = tint
	return style


static func apply_button(button: BaseButton, kind: String, font_size: int) -> void:
	var square := button.custom_minimum_size.x > 0.0 and button.custom_minimum_size.x <= 76.0
	button.add_theme_stylebox_override("normal", _forged_button_style(square, false, false, false, kind))
	button.add_theme_stylebox_override("hover", _forged_button_style(square, false, true, false, kind))
	button.add_theme_stylebox_override("pressed", _forged_button_style(square, true, false, false, kind))
	button.add_theme_stylebox_override("focus", _forged_button_style(square, false, true, false, kind))
	button.add_theme_stylebox_override("disabled", _forged_button_style(square, false, false, true, kind))
	button.add_theme_font_override("font", HEADING_FONT)
	button.add_theme_font_size_override("font_size", font_size)
	var font_color := Color("ffc2ca") if kind == "danger" else GOLD_LIGHT
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_color_override("font_disabled_color", Color("75858e"))
	button.add_theme_color_override("icon_normal_color", Color.WHITE)
	button.add_theme_color_override("icon_hover_color", GOLD_LIGHT)
	button.add_theme_color_override("icon_pressed_color", Color("b7c6d4"))
	button.add_theme_color_override("icon_disabled_color", Color("68727c"))
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
