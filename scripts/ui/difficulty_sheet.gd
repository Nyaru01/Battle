class_name DifficultySheet
extends Control

signal confirmed(index: int)
signal cancelled

const NAMES := ["INITIATION", "TACTIQUE", "EXPERT"]
const DETAILS := [
	"IA LENTE  •  CARTES NIV. 1",
	"IA ÉQUILIBRÉE  •  CARTES NIV. -1",
	"IA RAPIDE  •  CARTES À TON NIVEAU",
]

var selected_index := 1
var choice_buttons: Array[Button] = []
var launch_button: Button


func configure(current_index: int) -> void:
	selected_index = clampi(current_index, 0, NAMES.size() - 1)


func _ready() -> void:
	name = "DifficultySheet"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_interface()


func _build_interface() -> void:
	var shade := ColorRect.new()
	shade.name = "Shade"
	shade.color = Color(0.005, 0.02, 0.045, 0.84)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.gui_input.connect(_on_shade_input)
	add_child(shade)

	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side_name in ["left", "right", "bottom"]:
		safe.add_theme_constant_override("margin_" + side_name, 18)
	safe.add_theme_constant_override("margin_top", 12)
	add_child(safe)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 0)
	safe.add_child(stack)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(spacer)

	var panel := PanelContainer.new()
	panel.name = "SheetPanel"
	panel.add_theme_stylebox_override("panel", ArenaTheme.royal_panel(Color("0a2848"), ArenaTheme.GOLD, 24))
	stack.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	panel.add_child(layout)

	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	layout.add_child(heading)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", -4)
	heading.add_child(titles)
	var title := Label.new()
	title.text = "CHOISIS TON DÉFI"
	ArenaTheme.apply_heading(title, 25, ArenaTheme.GOLD_LIGHT)
	titles.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "DUEL HORS LIGNE CONTRE L’IA"
	ArenaTheme.apply_body(subtitle, 12, ArenaTheme.CYAN)
	titles.add_child(subtitle)
	var close := Button.new()
	close.name = "CloseButton"
	close.text = "×"
	close.custom_minimum_size = Vector2(48, 48)
	ArenaTheme.apply_button(close, "secondary", 27)
	close.pressed.connect(_cancel)
	heading.add_child(close)

	for index in NAMES.size():
		var choice := Button.new()
		choice.name = "Difficulty%d" % index
		choice.text = "%s\n%s" % [NAMES[index], DETAILS[index]]
		choice.toggle_mode = true
		choice.custom_minimum_size.y = 62
		choice.set_meta("difficulty_index", index)
		choice.pressed.connect(_select.bind(index))
		choice_buttons.append(choice)
		layout.add_child(choice)

	launch_button = Button.new()
	launch_button.name = "LaunchButton"
	launch_button.custom_minimum_size.y = 66
	launch_button.pressed.connect(_confirm)
	layout.add_child(launch_button)
	_refresh_selection()


func _select(index: int) -> void:
	selected_index = clampi(index, 0, NAMES.size() - 1)
	_refresh_selection()


func _refresh_selection() -> void:
	for index in choice_buttons.size():
		var button := choice_buttons[index]
		button.button_pressed = index == selected_index
		ArenaTheme.apply_button(button, "gold" if index == selected_index else "secondary", 14)
	launch_button.text = "LANCER EN %s" % NAMES[selected_index]
	ArenaTheme.apply_button(launch_button, "gold", 21)


func _confirm() -> void:
	confirmed.emit(selected_index)


func _cancel() -> void:
	cancelled.emit()


func _on_shade_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_cancel()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_cancel()
