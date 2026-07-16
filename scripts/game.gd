extends Node2D

enum ScreenState { MENU, COLLECTION, BATTLE, RESULT }

const DESIGN_SIZE := Vector2(720.0, 1280.0)
const LANE_X := [210.0, 510.0]
const ARENA_TEXTURE := preload("res://assets/arena-v2.png")
const CARD_ART := preload("res://assets/card-art-v2.png")
const CARD_ART_V4 := preload("res://assets/card-art-v4.png")
const ICON_TEXTURE := preload("res://assets/icon.png")
const TOWER_SPRITES := preload("res://assets/tower-sprites-v3.png")
const UNIT_SPRITES := preload("res://assets/unit-sprites-v3.png")
const UNIT_SPRITES_V4 := preload("res://assets/unit-sprites-v4.png")
const CARD_SHORT := {
	"guardian": "G",
	"ranger": "E",
	"colossus": "C",
	"fireball": "★",
	"duelist": "D",
	"alchemist": "A",
	"bulwark": "R",
	"frost": "❄",
}
const CARD_QUADRANTS := {
	"guardian": Vector2i(0, 0),
	"ranger": Vector2i(1, 0),
	"colossus": Vector2i(0, 1),
	"fireball": Vector2i(1, 1),
	"duelist": Vector2i(0, 0),
	"alchemist": Vector2i(1, 0),
	"bulwark": Vector2i(0, 1),
	"frost": Vector2i(1, 1),
}
const V4_CARD_IDS := ["duelist", "alchemist", "bulwark", "frost"]
const DIFFICULTY_NAMES := ["INITIATION", "TACTIQUE", "EXPERT"]
const SAVE_PATH := "user://profile.json"

var state := ScreenState.MENU
var simulation: BattleSim
var opponent: BattleAI
var selected_card := ""
var selected_difficulty := 1
var sound_enabled := true
var haptics_enabled := true
var ui_layer: CanvasLayer
var time_label: Label
var energy_label: Label
var energy_bar: ProgressBar
var core_label: Label
var hint_label: Label
var card_buttons: Dictionary = {}
var profile := BattleProgression.default_profile()
var last_reward: Dictionary = {}
var tutorial: BattleTutorial
var tutorial_label: Label
var battle_paused := false
var pause_layer: CanvasLayer
var effects: Array[Dictionary] = []
var battle_intro_time := 0.0
var last_intro_count := 4
var sfx_bank: Dictionary = {}
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_player_index := 0
var last_hit_sound_msec := 0
var announcement_text := ""
var announcement_ttl := 0.0


func _ready() -> void:
	_setup_audio()
	_load_profile()
	_build_menu()
	queue_redraw()


func _process(delta: float) -> void:
	if state != ScreenState.BATTLE or battle_paused:
		return
	if battle_intro_time > 0.0:
		battle_intro_time = maxf(0.0, battle_intro_time - delta)
		var intro_count := ceili(maxf(0.0, battle_intro_time - 0.8))
		if intro_count != last_intro_count:
			_play_sfx("countdown" if intro_count > 0 else "battle_start")
			last_intro_count = intro_count
		queue_redraw()
		return
	simulation.step(delta)
	if tutorial == null or tutorial.is_complete():
		opponent.update(delta, simulation)
	_consume_battle_events()
	_update_effects(delta)
	_update_hud()
	simulation.events.clear()
	queue_redraw()
	if simulation.finished:
		_show_result()


func _unhandled_input(event: InputEvent) -> void:
	if state != ScreenState.BATTLE or battle_paused or battle_intro_time > 0.0 or selected_card.is_empty():
		return
	var pressed := false
	var position := Vector2.ZERO
	if event is InputEventScreenTouch:
		pressed = event.pressed
		position = event.position
	elif event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
		position = event.position
	if not pressed or position.y < 115.0 or position.y > 1060.0:
		return
	var lane := 0 if position.x < DESIGN_SIZE.x * 0.5 else 1
	var played_card := selected_card
	if tutorial != null and not tutorial.is_complete() and not tutorial.can_deploy(played_card, lane):
		hint_label.text = tutorial.instruction()
		return
	if simulation.play_card(BattleSim.PLAYER, selected_card, lane):
		_haptic(32, 0.35)
		if tutorial != null and not tutorial.is_complete():
			tutorial.deploy_card(played_card, lane)
			simulation.energy[BattleSim.PLAYER] = 10.0
			if tutorial.is_complete():
				last_reward = BattleProgression.complete_tutorial(profile)
				_save_profile()
		selected_card = ""
		_build_hud()
		if tutorial != null:
			_update_tutorial_hint()
		else:
			hint_label.text = "%s joué • suivante : %s" % [BattleSim.CARDS[played_card].name, BattleSim.CARDS[simulation.get_next_card(BattleSim.PLAYER)].name]
		queue_redraw()
	else:
		hint_label.text = "Pas assez d'énergie"
		_haptic(70, 0.22)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color("101827"))
	if state == ScreenState.MENU:
		_draw_menu_backdrop()
		return
	if state == ScreenState.COLLECTION:
		_draw_collection_backdrop()
		return
	_draw_arena()
	_draw_deployment_guide()
	_draw_objectives()
	_draw_units()
	_draw_effects()
	_draw_announcement()
	_draw_battle_intro()


func _draw_menu_backdrop() -> void:
	draw_texture_rect(ICON_TEXTURE, Rect2(160.0, 100.0, 400.0, 400.0), false)
	draw_rect(Rect2(0.0, 470.0, 720.0, 135.0), Color(0.04, 0.08, 0.13, 0.88), true)
	draw_line(Vector2(100.0, 810.0), Vector2(620.0, 810.0), Color("4e88aa"), 3.0)


func _draw_collection_backdrop() -> void:
	draw_rect(Rect2(0.0, 0.0, 720.0, 1280.0), Color("0d1725"), true)
	for row in range(7):
		draw_line(Vector2(24.0, 145.0 + row * 150.0), Vector2(696.0, 145.0 + row * 150.0), Color(0.25, 0.55, 0.72, 0.08), 2.0)
	draw_circle(Vector2(360.0, 54.0), 170.0, Color(0.12, 0.45, 0.62, 0.08))


func _draw_arena() -> void:
	draw_texture_rect_region(
		ARENA_TEXTURE,
		Rect2(24.0, 82.0, 672.0, 982.0),
		Rect2(92.0, 100.0, 840.0, 1200.0)
	)
	draw_rect(Rect2(24.0, 82.0, 672.0, 982.0), Color(0.05, 0.12, 0.14, 0.28), false, 4.0)
	draw_rect(Rect2(42.0, 590.0, 636.0, 430.0), Color(0.2, 0.75, 1.0, 0.025), true)


func _draw_deployment_guide() -> void:
	if state != ScreenState.BATTLE or selected_card.is_empty() or battle_intro_time > 0.0:
		return
	var is_spell: bool = BattleSim.CARDS[selected_card].type == "spell"
	var accent := Color("ff9a52") if selected_card == "fireball" else (Color("78e8ff") if is_spell else Color("6bd5ff"))
	for lane in range(BattleSim.LANE_COUNT):
		var area := Rect2(58.0 + lane * 330.0, 120.0 if is_spell else 610.0, 274.0, 400.0 if is_spell else 235.0)
		draw_rect(area, Color(accent, 0.07), true)
		draw_rect(area, Color(accent, 0.48), false, 3.0)
		if is_spell:
			var target := Vector2(LANE_X[lane], 285.0)
			draw_circle(target, 62.0, Color(accent, 0.10))
			draw_arc(target, 62.0, 0.0, TAU, 32, accent, 4.0)
			draw_line(target - Vector2(22.0, 0.0), target + Vector2(22.0, 0.0), accent, 3.0)
			draw_line(target - Vector2(0.0, 22.0), target + Vector2(0.0, 22.0), accent, 3.0)
			draw_string(ThemeDB.fallback_font, Vector2(area.position.x, 490.0), "CIBLE GAUCHE" if lane == 0 else "CIBLE DROITE", HORIZONTAL_ALIGNMENT_CENTER, area.size.x, 18, Color(accent, 0.92))
		else:
			draw_string(ThemeDB.fallback_font, Vector2(area.position.x, 660.0), "VOIE GAUCHE" if lane == 0 else "VOIE DROITE", HORIZONTAL_ALIGNMENT_CENTER, area.size.x, 18, Color(accent, 0.88))


func _draw_battle_intro() -> void:
	if state != ScreenState.BATTLE or battle_intro_time <= 0.0:
		return
	var message := "COMBAT !"
	if battle_intro_time > 0.8:
		message = str(ceili(battle_intro_time - 0.8))
	var center := Vector2(360.0, 565.0)
	var pulse := 1.0 + sin(battle_intro_time * 8.0) * 0.05
	draw_circle(center, 86.0 * pulse, Color(0.02, 0.06, 0.11, 0.82))
	draw_arc(center, 86.0 * pulse, 0.0, TAU, 40, Color("ffe07a"), 6.0)
	draw_string(ThemeDB.fallback_font, Vector2(210.0, 585.0), message, HORIZONTAL_ALIGNMENT_CENTER, 300.0, 50 if message == "COMBAT !" else 72, Color.WHITE)


func _draw_announcement() -> void:
	if state != ScreenState.BATTLE or announcement_ttl <= 0.0 or battle_intro_time > 0.0:
		return
	var opacity := clampf(announcement_ttl, 0.0, 1.0)
	draw_rect(Rect2(105.0, 500.0, 510.0, 82.0), Color(0.02, 0.06, 0.11, 0.76 * opacity), true)
	draw_rect(Rect2(105.0, 500.0, 510.0, 82.0), Color(1.0, 0.83, 0.35, 0.8 * opacity), false, 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(125.0, 551.0), announcement_text, HORIZONTAL_ALIGNMENT_CENTER, 470.0, 30, Color(1.0, 0.9, 0.55, opacity))


func _draw_objectives() -> void:
	for side in [BattleSim.PLAYER, BattleSim.ENEMY]:
		var color := Color("4eb7ff") if side == BattleSim.PLAYER else Color("ff5d70")
		var tower_y := 900.0 if side == BattleSim.PLAYER else 240.0
		var core_y := 955.0 if side == BattleSim.PLAYER else 205.0
		for lane in range(BattleSim.LANE_COUNT):
			var hp: float = simulation.towers[side].lanes[lane]
			_draw_tower(Vector2(LANE_X[lane], tower_y), color, hp, 1200.0, false)
		var core_hp: float = simulation.towers[side].core
		_draw_tower(Vector2(360.0, core_y), color, core_hp, 2200.0, true)


func _draw_units() -> void:
	for unit in simulation.units:
		var x: float = LANE_X[unit.lane] + float(unit.get("formation_x", 0.0))
		var radius := _draw_unit_avatar(Vector2(x, unit.y), unit)
		_draw_health_bar(Vector2(x - radius, unit.y - radius - 12.0), radius * 2.0, unit.hp, unit.max_hp)


func _draw_effects() -> void:
	for effect in effects:
		var progress := 1.0 - float(effect.ttl) / float(effect.duration)
		var opacity := clampf(1.0 - progress, 0.0, 1.0)
		var color: Color = effect.color
		color.a *= opacity
		match effect.kind:
			"deploy":
				var radius := lerpf(12.0, 58.0, progress)
				draw_circle(effect.position, radius * 0.55, Color(color, color.a * 0.12))
				draw_arc(effect.position, radius, 0.0, TAU, 32, color, 5.0)
			"burst":
				var radius := lerpf(8.0, float(effect.radius), progress)
				draw_circle(effect.position, radius, Color(color, color.a * 0.16))
				draw_arc(effect.position, radius, 0.0, TAU, 28, color, 4.0)
				for ray in range(8):
					var direction := Vector2.RIGHT.rotated(float(ray) * TAU / 8.0)
					draw_line(effect.position + direction * radius * 0.55, effect.position + direction * radius * 1.25, color, 3.0)
			"beam":
				var beam_color := Color(color, color.a * (0.65 + sin(progress * PI) * 0.35))
				draw_line(effect.from, effect.to, Color(beam_color, beam_color.a * 0.25), 9.0)
				draw_line(effect.from, effect.to, beam_color, 3.0)
				draw_circle(effect.to, lerpf(5.0, 17.0, progress), Color(beam_color, beam_color.a * 0.45))


func _consume_battle_events() -> void:
	for event in simulation.events:
		var event_type: String = event.get("type", "")
		match event_type:
			"card_played":
				if BattleSim.CARDS[event.card].type == "unit":
					var spawn_y := 820.0 if event.side == BattleSim.PLAYER else 310.0
					_add_effect("deploy", Vector2(LANE_X[event.lane], spawn_y), _team_color(event.side), 0.42)
					_play_sfx("deploy")
			"spell":
				var target_y := 285.0 if event.side == BattleSim.PLAYER else 855.0
				var spell_color := Color("ff9d42") if event.card == "fireball" else Color("75e6ff")
				_add_effect("burst", Vector2(LANE_X[event.lane], target_y), spell_color, 0.55, 92.0)
				_play_sfx("fireball" if event.card == "fireball" else "frost")
			"hit":
				var source := _find_unit_position(event.source)
				var target := _find_unit_position(event.target)
				if source != Vector2.ZERO and target != Vector2.ZERO:
					_add_beam(source, target, Color("ffe39a"), 0.16)
					_play_hit_sfx()
			"tower_shot":
				var target := _find_unit_position(event.target)
				if target != Vector2.ZERO:
					var tower_y := 900.0 if event.side == BattleSim.PLAYER else 240.0
					_add_beam(Vector2(LANE_X[event.lane], tower_y - 35.0), target, _team_color(event.side), 0.22)
					_play_sfx("tower_shot")
			"tower_hit":
				_add_objective_burst(event.side, event.lane, false, 34.0)
			"core_hit":
				_add_objective_burst(event.side, 0, true, 42.0)
			"tower_destroyed":
				_add_objective_burst(event.side, event.lane, false, 105.0)
				_play_sfx("destroyed")
				_haptic(100, 0.62)
			"core_destroyed":
				_add_objective_burst(event.side, 0, true, 135.0)
				_play_sfx("destroyed")
				_haptic(180, 0.78)
			"double_energy_started":
				_show_announcement("ÉNERGIE x2")
				_play_sfx("battle_start")
				_haptic(70, 0.5)
			"overtime_started":
				_show_announcement("MORT SUBITE • ÉNERGIE x3")
				_play_sfx("destroyed")
				_haptic(120, 0.68)


func _show_announcement(message: String) -> void:
	announcement_text = message
	announcement_ttl = 2.2


func _setup_audio() -> void:
	sfx_bank = {
		"countdown": _make_sfx(520.0, 430.0, 0.11, 0.34, 0.0),
		"battle_start": _make_sfx(420.0, 920.0, 0.28, 0.42, 0.0),
		"deploy": _make_sfx(190.0, 80.0, 0.18, 0.48, 0.05),
		"hit": _make_sfx(580.0, 230.0, 0.08, 0.28, 0.18),
		"tower_shot": _make_sfx(820.0, 390.0, 0.12, 0.32, 0.0),
		"fireball": _make_sfx(170.0, 48.0, 0.34, 0.60, 0.42),
		"frost": _make_sfx(920.0, 1520.0, 0.36, 0.30, 0.06),
		"destroyed": _make_sfx(105.0, 32.0, 0.58, 0.68, 0.36),
	}
	for index in range(8):
		var player := AudioStreamPlayer.new()
		player.volume_db = -8.0
		add_child(player)
		sfx_players.append(player)


func _make_sfx(start_frequency: float, end_frequency: float, duration: float, amplitude: float, noise_mix: float) -> AudioStreamWAV:
	var mix_rate := 22050
	var sample_count := int(duration * mix_rate)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var phase := 0.0
	var noise_state := 1733
	for index in range(sample_count):
		var progress := float(index) / float(sample_count)
		var frequency := lerpf(start_frequency, end_frequency, progress)
		phase += TAU * frequency / float(mix_rate)
		noise_state = int(posmod(noise_state * 48271, 2147483647))
		var noise := float(noise_state) / 1073741823.5 - 1.0
		var wave := lerpf(sin(phase), noise, noise_mix)
		var attack := minf(progress / 0.018, 1.0)
		var envelope := attack * pow(1.0 - progress, 2.0)
		var sample := int(clampf(wave * envelope * amplitude, -1.0, 1.0) * 32767.0)
		data[index * 2] = sample & 0xff
		data[index * 2 + 1] = (sample >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	return stream


func _play_sfx(sound_name: String) -> void:
	if not sound_enabled or not sfx_bank.has(sound_name) or sfx_players.is_empty():
		return
	var player := sfx_players[sfx_player_index]
	sfx_player_index = (sfx_player_index + 1) % sfx_players.size()
	player.stream = sfx_bank[sound_name]
	player.play()


func _play_hit_sfx() -> void:
	var now := Time.get_ticks_msec()
	if now - last_hit_sound_msec < 65:
		return
	last_hit_sound_msec = now
	_play_sfx("hit")


func _haptic(duration_ms: int, amplitude: float) -> void:
	if haptics_enabled:
		Input.vibrate_handheld(duration_ms, amplitude)


func _add_objective_burst(side: int, lane: int, is_core: bool, radius: float) -> void:
	var y: float = (955.0 if side == BattleSim.PLAYER else 205.0) if is_core else (900.0 if side == BattleSim.PLAYER else 240.0)
	var x: float = 360.0 if is_core else LANE_X[lane]
	_add_effect("burst", Vector2(x, y), _team_color(1 - side), 0.48 if radius < 100.0 else 0.9, radius)


func _add_effect(kind: String, position: Vector2, color: Color, duration: float, radius: float = 55.0) -> void:
	effects.append({
		"kind": kind,
		"position": position,
		"color": color,
		"duration": duration,
		"ttl": duration,
		"radius": radius,
	})


func _add_beam(from: Vector2, to: Vector2, color: Color, duration: float) -> void:
	effects.append({
		"kind": "beam",
		"from": from,
		"to": to,
		"color": color,
		"duration": duration,
		"ttl": duration,
	})


func _update_effects(delta: float) -> void:
	announcement_ttl = maxf(0.0, announcement_ttl - delta)
	for index in range(effects.size() - 1, -1, -1):
		effects[index].ttl = float(effects[index].ttl) - delta
		if effects[index].ttl <= 0.0:
			effects.remove_at(index)


func _find_unit_position(unit_id: int) -> Vector2:
	for unit in simulation.units:
		if unit.id == unit_id:
			return Vector2(LANE_X[unit.lane] + float(unit.get("formation_x", 0.0)), unit.y)
	return Vector2.ZERO


func _team_color(side: int) -> Color:
	return Color("57c4ff") if side == BattleSim.PLAYER else Color("ff6173")


func _draw_tower(center: Vector2, team_color: Color, hp: float, maximum: float, is_core: bool) -> void:
	var source_width := TOWER_SPRITES.get_width() * 0.5
	var source := Rect2(source_width if is_core else 0.0, 0.0, source_width, TOWER_SPRITES.get_height())
	var size := Vector2(170.0, 150.0) if is_core else Vector2(138.0, 142.0)
	var destination := Rect2(center.x - size.x * 0.5, center.y - size.y * 0.60, size.x, size.y)
	draw_circle(center + Vector2(7.0, 27.0), 39.0 if is_core else 31.0, Color(0.02, 0.05, 0.04, 0.35))
	var tint := Color.WHITE if hp > 0.0 else Color(0.35, 0.36, 0.37, 0.55)
	draw_texture_rect_region(TOWER_SPRITES, destination, source, tint)
	var banner_width := 52.0 if is_core else 42.0
	var banner_y := center.y - (28.0 if is_core else 22.0)
	draw_rect(Rect2(center.x - banner_width * 0.5, banner_y, banner_width, 18.0), team_color if hp > 0.0 else Color("45494c"), true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(center.x - banner_width * 0.5, banner_y + 18.0),
		Vector2(center.x, banner_y + 27.0),
		Vector2(center.x + banner_width * 0.5, banner_y + 18.0),
	]), team_color.darkened(0.12) if hp > 0.0 else Color("45494c"))
	if is_core and hp > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(center.x - 18.0, banner_y + 17.0), "♛", HORIZONTAL_ALIGNMENT_CENTER, 36.0, 19, Color("ffe180"))
	_draw_health_bar(Vector2(center.x - size.x * 0.31, center.y - size.y * 0.55), size.x * 0.62, hp, maximum)


func _draw_unit_avatar(center: Vector2, unit: Dictionary) -> float:
	var team := Color("57c4ff") if unit.side == BattleSim.PLAYER else Color("ff6173")
	var radius := 25.0
	var source := Rect2(20.0, 100.0, 630.0, 680.0)
	var size := Vector2(108.0, 116.0)
	var texture: Texture2D = UNIT_SPRITES
	if unit.card_id == "colossus":
		radius = 34.0
		source = Rect2(1100.0, 80.0, 674.0, 710.0)
		size = Vector2(132.0, 139.0)
	elif unit.card_id == "ranger":
		radius = 23.0
		source = Rect2(650.0, 130.0, 480.0, 650.0)
		size = Vector2(86.0, 116.0)
	elif unit.card_id == "duelist":
		radius = 23.0
		texture = UNIT_SPRITES_V4
		source = Rect2(35.0, 140.0, 520.0, 670.0)
		size = Vector2(88.0, 113.0)
	elif unit.card_id == "alchemist":
		radius = 25.0
		texture = UNIT_SPRITES_V4
		source = Rect2(565.0, 150.0, 515.0, 680.0)
		size = Vector2(94.0, 124.0)
	elif unit.card_id == "bulwark":
		radius = 36.0
		texture = UNIT_SPRITES_V4
		source = Rect2(1090.0, 85.0, 570.0, 760.0)
		size = Vector2(128.0, 154.0)
	draw_circle(center + Vector2(5.0, 20.0), radius * 0.95, Color(0.02, 0.05, 0.04, 0.38))
	draw_circle(center + Vector2(0.0, 18.0), radius * 0.72, Color(team, 0.20))
	draw_arc(center + Vector2(0.0, 18.0), radius * 0.76, 0.0, TAU, 28, team, 3.0)
	var destination := Rect2(center.x - size.x * 0.5, center.y - size.y * 0.66, size.x, size.y)
	draw_texture_rect_region(texture, destination, source)
	return radius


func _draw_health_bar(position: Vector2, width: float, value: float, maximum: float) -> void:
	draw_rect(Rect2(position, Vector2(width, 7.0)), Color(0.05, 0.07, 0.1, 0.85), true)
	var ratio := clampf(value / maximum, 0.0, 1.0)
	draw_rect(Rect2(position + Vector2(1.0, 1.0), Vector2((width - 2.0) * ratio, 5.0)), Color("6be675") if ratio > 0.3 else Color("ffca58"), true)


func _build_menu() -> void:
	_clear_pause_overlay()
	_clear_ui()
	state = ScreenState.MENU
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	var title := _label("BATTLE", Vector2(80.0, 485.0), Vector2(560.0, 82.0), 58)
	title.add_theme_color_override("font_color", Color("76d6ff"))
	var subtitle := _label("Stratégie d'arène • Prototype IA", Vector2(80.0, 557.0), Vector2(560.0, 45.0), 22)
	subtitle.add_theme_color_override("font_color", Color("b5c9d8"))
	var mode := _label("DUEL CONTRE IA", Vector2(120.0, 680.0), Vector2(480.0, 45.0), 26)
	mode.add_theme_color_override("font_color", Color("f5c867"))
	var difficulty := OptionButton.new()
	difficulty.position = Vector2(180.0, 745.0)
	difficulty.size = Vector2(360.0, 64.0)
	difficulty.add_item("Initiation • cartes niveau 1")
	difficulty.add_item("Tactique • un niveau de retard")
	difficulty.add_item("Expert • niveaux identiques")
	difficulty.select(selected_difficulty)
	difficulty.item_selected.connect(func(index: int) -> void:
		selected_difficulty = index
		_save_profile()
	)
	ui_layer.add_child(difficulty)
	var start := Button.new()
	start.text = "JOUER"
	start.position = Vector2(180.0, 840.0)
	start.size = Vector2(360.0, 88.0)
	start.add_theme_font_size_override("font_size", 30)
	start.pressed.connect(_start_battle)
	ui_layer.add_child(start)
	var training := Button.new()
	training.text = "APPRENDRE À JOUER"
	training.position = Vector2(180.0, 942.0)
	training.size = Vector2(360.0, 66.0)
	training.add_theme_font_size_override("font_size", 20)
	training.pressed.connect(_start_tutorial)
	ui_layer.add_child(training)
	var collection := Button.new()
	collection.text = "COLLECTION"
	collection.position = Vector2(180.0, 1018.0)
	collection.size = Vector2(360.0, 58.0)
	collection.add_theme_font_size_override("font_size", 19)
	collection.pressed.connect(_build_collection)
	ui_layer.add_child(collection)
	var version := _label("Prototype 0.23 • Hors ligne", Vector2(160.0, 1202.0), Vector2(400.0, 36.0), 18)
	version.add_theme_color_override("font_color", Color("71889a"))
	var record := _label("%d victoires  •  %d défaites" % [profile.wins, profile.losses], Vector2(160.0, 1080.0), Vector2(400.0, 36.0), 17)
	record.add_theme_color_override("font_color", Color("8fa7b8"))
	var progression := _label("Niveau %d  •  %d/%d XP  •  ◈ %d" % [profile.level, profile.xp, BattleProgression.xp_to_next(profile.level), profile.coins], Vector2(110.0, 1118.0), Vector2(500.0, 36.0), 17)
	progression.add_theme_color_override("font_color", Color("f2c96d"))
	var sound_toggle := CheckButton.new()
	sound_toggle.text = "SONS"
	sound_toggle.position = Vector2(105.0, 1150.0)
	sound_toggle.size = Vector2(230.0, 42.0)
	sound_toggle.button_pressed = sound_enabled
	sound_toggle.add_theme_font_size_override("font_size", 16)
	sound_toggle.toggled.connect(func(enabled: bool) -> void:
		sound_enabled = enabled
		if not enabled:
			for player in sfx_players:
				player.stop()
		_save_profile()
	)
	ui_layer.add_child(sound_toggle)
	var haptics_toggle := CheckButton.new()
	haptics_toggle.text = "VIBRATIONS"
	haptics_toggle.position = Vector2(365.0, 1150.0)
	haptics_toggle.size = Vector2(250.0, 42.0)
	haptics_toggle.button_pressed = haptics_enabled
	haptics_toggle.add_theme_font_size_override("font_size", 16)
	haptics_toggle.toggled.connect(func(enabled: bool) -> void:
		haptics_enabled = enabled
		if enabled:
			_haptic(30, 0.3)
		_save_profile()
	)
	ui_layer.add_child(haptics_toggle)
	queue_redraw()


func _build_collection() -> void:
	_clear_pause_overlay()
	_clear_ui()
	state = ScreenState.COLLECTION
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	var title := _label("COLLECTION", Vector2(80.0, 28.0), Vector2(560.0, 58.0), 38)
	title.add_theme_color_override("font_color", Color("76d6ff"))
	var subtitle := _label("8 cartes disponibles • ◈ %d éclats" % profile.coins, Vector2(90.0, 82.0), Vector2(540.0, 38.0), 18)
	subtitle.add_theme_color_override("font_color", Color("a9bdca"))
	for index in range(BattleSim.DEFAULT_DECK.size()):
		var card_id: String = BattleSim.DEFAULT_DECK[index]
		var level: int = profile.card_levels[card_id]
		var card: Dictionary = BattleSim.scaled_card(BattleSim.CARDS[card_id], level)
		var column := index % 2
		var row := index / 2
		var panel := Panel.new()
		panel.position = Vector2(24.0 + column * 348.0, 142.0 + row * 225.0)
		panel.size = Vector2(324.0, 205.0)
		panel.clip_contents = true
		panel.add_theme_stylebox_override("panel", _card_style(card_id, false))
		ui_layer.add_child(panel)
		var portrait := TextureRect.new()
		portrait.texture = _card_texture(card_id, CARD_QUADRANTS[card_id])
		portrait.position = Vector2(10.0, 10.0)
		portrait.size = Vector2(126.0, 126.0)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_SCALE
		portrait.clip_contents = true
		panel.add_child(portrait)
		var name_label := Label.new()
		name_label.text = card.name
		name_label.position = Vector2(145.0, 14.0)
		name_label.size = Vector2(165.0, 34.0)
		name_label.add_theme_font_size_override("font_size", 20)
		panel.add_child(name_label)
		var cost_label := Label.new()
		cost_label.text = "Niv. %d  •  ● %d énergie" % [level, int(card.cost)]
		cost_label.position = Vector2(145.0, 50.0)
		cost_label.size = Vector2(165.0, 30.0)
		cost_label.add_theme_font_size_override("font_size", 16)
		cost_label.add_theme_color_override("font_color", Color("e879ff"))
		panel.add_child(cost_label)
		var details := Label.new()
		details.text = _card_details(card)
		details.position = Vector2(145.0, 84.0)
		details.size = Vector2(165.0, 76.0)
		details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_theme_font_size_override("font_size", 14)
		details.add_theme_color_override("font_color", Color("b8c8d2"))
		panel.add_child(details)
		var upgrade := Button.new()
		upgrade.position = Vector2(12.0, 160.0)
		upgrade.size = Vector2(300.0, 36.0)
		upgrade.add_theme_font_size_override("font_size", 14)
		if level >= BattleProgression.MAX_CARD_LEVEL:
			upgrade.text = "NIVEAU MAXIMUM"
			upgrade.disabled = true
		else:
			var upgrade_cost := BattleProgression.card_upgrade_cost(level)
			upgrade.text = "AMÉLIORER NIV. %d  •  ◈ %d" % [level + 1, upgrade_cost]
			upgrade.disabled = profile.coins < upgrade_cost
			upgrade.pressed.connect(_upgrade_card.bind(card_id))
		panel.add_child(upgrade)
	var back := Button.new()
	back.text = "RETOUR"
	back.position = Vector2(210.0, 1070.0)
	back.size = Vector2(300.0, 68.0)
	back.add_theme_font_size_override("font_size", 21)
	back.pressed.connect(_build_menu)
	ui_layer.add_child(back)
	queue_redraw()


func _upgrade_card(card_id: String) -> void:
	if not BattleProgression.upgrade_card(profile, card_id):
		_haptic(70, 0.22)
		return
	_save_profile()
	_play_sfx("battle_start")
	_haptic(90, 0.55)
	_build_collection()


func _card_details(card: Dictionary) -> String:
	if card.type == "spell":
		var effect := " • ralentit" if card.has("slow_duration") else ""
		return "Sort • %d dégâts%s" % [int(card.damage), effect]
	if int(card.get("count", 1)) > 1:
		return "%d unités • %d PV chacune\n%d dégâts • portée %d" % [int(card.count), int(card.hp), int(card.damage), int(card.range)]
	return "%d PV\n%d dégâts • portée %d" % [int(card.hp), int(card.damage), int(card.range)]


func _start_battle() -> void:
	_clear_pause_overlay()
	effects.clear()
	battle_intro_time = 3.8
	last_intro_count = 4
	announcement_ttl = 0.0
	tutorial = null
	var enemy_levels := BattleProgression.opponent_card_levels(profile.card_levels, selected_difficulty)
	simulation = BattleSim.new(Time.get_ticks_msec(), profile.card_levels, enemy_levels)
	opponent = BattleAI.new(BattleSim.ENEMY, selected_difficulty, Time.get_ticks_msec() + 19)
	selected_card = ""
	last_reward = {}
	state = ScreenState.BATTLE
	_build_hud()
	queue_redraw()


func _start_tutorial() -> void:
	_clear_pause_overlay()
	effects.clear()
	battle_intro_time = 3.8
	last_intro_count = 4
	announcement_ttl = 0.0
	tutorial = BattleTutorial.new()
	simulation = BattleSim.new(101)
	simulation.energy[BattleSim.PLAYER] = 10.0
	opponent = BattleAI.new(BattleSim.ENEMY, 0, 202)
	selected_card = ""
	last_reward = {}
	state = ScreenState.BATTLE
	_build_hud()
	_update_tutorial_hint()
	queue_redraw()


func _build_hud() -> void:
	_clear_ui()
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	time_label = _label("03:00", Vector2(210.0, 0.0), Vector2(300.0, 38.0), 26)
	var pause_button := Button.new()
	pause_button.text = "Ⅱ"
	pause_button.position = Vector2(650.0, 4.0)
	pause_button.size = Vector2(58.0, 46.0)
	pause_button.add_theme_font_size_override("font_size", 22)
	pause_button.pressed.connect(_pause_battle)
	ui_layer.add_child(pause_button)
	energy_label = _label("Énergie 5/10", Vector2(18.0, 1060.0), Vector2(145.0, 36.0), 18)
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	energy_bar = ProgressBar.new()
	energy_bar.position = Vector2(148.0, 1067.0)
	energy_bar.size = Vector2(282.0, 24.0)
	energy_bar.min_value = 0.0
	energy_bar.max_value = 10.0
	energy_bar.value = 5.0
	energy_bar.show_percentage = false
	energy_bar.add_theme_stylebox_override("background", _energy_style(Color("111925")))
	energy_bar.add_theme_stylebox_override("fill", _energy_style(Color("c950ed")))
	ui_layer.add_child(energy_bar)
	core_label = _label("", Vector2(20.0, 36.0), Vector2(680.0, 30.0), 17)
	hint_label = _label("Suivante : %s" % BattleSim.CARDS[simulation.get_next_card(BattleSim.PLAYER)].name, Vector2(438.0, 1058.0), Vector2(264.0, 40.0), 15)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if tutorial != null:
		tutorial_label = _label(tutorial.instruction(), Vector2(45.0, 76.0), Vector2(630.0, 42.0), 16)
		tutorial_label.add_theme_color_override("font_color", Color("ffe17b"))
		tutorial_label.add_theme_color_override("font_outline_color", Color("101827"))
		tutorial_label.add_theme_constant_override("outline_size", 7)
	card_buttons.clear()
	var hand := simulation.get_hand(BattleSim.PLAYER)
	for index in range(hand.size()):
		var card_id: String = hand[index]
		var card: Dictionary = BattleSim.CARDS[card_id]
		var button := Button.new()
		button.position = Vector2(12.0 + index * 177.0, 1100.0)
		button.size = Vector2(165.0, 152.0)
		button.text = ""
		button.add_theme_stylebox_override("normal", _card_style(card_id, false))
		button.add_theme_stylebox_override("hover", _card_style(card_id, true))
		button.add_theme_stylebox_override("pressed", _card_style(card_id, true))
		button.add_theme_stylebox_override("disabled", _card_style(card_id, false, true))
		button.pressed.connect(_select_card.bind(card_id))
		ui_layer.add_child(button)
		var quadrant: Vector2i = CARD_QUADRANTS[card_id]
		var atlas := _card_texture(card_id, quadrant)
		var portrait := TextureRect.new()
		portrait.texture = atlas
		portrait.position = Vector2(6.0, 6.0)
		portrait.size = Vector2(153.0, 96.0)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(portrait)
		var name_label := Label.new()
		name_label.text = card.name
		name_label.position = Vector2(4.0, 101.0)
		name_label.size = Vector2(157.0, 25.0)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(name_label)
		var cost_label := Label.new()
		var card_level := int(simulation.card_levels[BattleSim.PLAYER].get(card_id, 1))
		cost_label.text = "Niv.%d  •  ● %d" % [card_level, int(card.cost)]
		cost_label.position = Vector2(4.0, 124.0)
		cost_label.size = Vector2(157.0, 24.0)
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_label.add_theme_font_size_override("font_size", 17)
		cost_label.add_theme_color_override("font_color", Color("e879ff"))
		cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(cost_label)
		card_buttons[card_id] = button
	_update_hud()


func _select_card(card_id: String) -> void:
	if selected_card == card_id and (tutorial == null or tutorial.is_complete()):
		selected_card = ""
		hint_label.text = "Sélection annulée • choisis une carte"
		_haptic(18, 0.18)
		_update_hud()
		queue_redraw()
		return
	if tutorial != null and not tutorial.is_complete():
		if not tutorial.select_card(card_id):
			hint_label.text = tutorial.instruction()
			return
	selected_card = card_id
	_haptic(18, 0.24)
	if tutorial != null:
		_update_tutorial_hint()
	else:
		hint_label.text = "%s sélectionné • %s" % [BattleSim.CARDS[card_id].name, "vise une zone ennemie" if BattleSim.CARDS[card_id].type == "spell" else "touche la voie gauche ou droite"]
	_update_hud()
	queue_redraw()


func _update_tutorial_hint() -> void:
	if tutorial == null:
		return
	var message := tutorial.instruction()
	if is_instance_valid(tutorial_label):
		tutorial_label.text = message
	hint_label.text = "Suis l’indication jaune"


func _update_hud() -> void:
	if state != ScreenState.BATTLE:
		return
	var seconds := ceili(simulation.time_left)
	time_label.text = ("MORT SUBITE  " if simulation.overtime else "") + "%02d:%02d" % [seconds / 60, seconds % 60]
	time_label.add_theme_color_override("font_color", Color("ffcf68") if simulation.overtime else Color.WHITE)
	var energy_prefix := "x3  " if simulation.overtime else ("x2  " if simulation.double_energy else "")
	energy_label.text = energy_prefix + "%.1f/10" % simulation.energy[BattleSim.PLAYER]
	energy_bar.value = simulation.energy[BattleSim.PLAYER]
	var enemy_level := BattleProgression.average_card_level(simulation.card_levels[BattleSim.ENEMY])
	var opponent_name := "ENTRAÎNEUR" if tutorial != null else "IA %s NIV.%d" % [DIFFICULTY_NAMES[selected_difficulty], enemy_level]
	core_label.text = "%s %d   ◆ %d — %d ◆   %d TOI" % [opponent_name, int(simulation.towers[BattleSim.ENEMY].core), simulation.crowns[BattleSim.ENEMY], simulation.crowns[BattleSim.PLAYER], int(simulation.towers[BattleSim.PLAYER].core)]
	for card_id in card_buttons:
		var button: Button = card_buttons[card_id]
		button.disabled = BattleSim.CARDS[card_id].cost > simulation.energy[BattleSim.PLAYER] + 0.001
		button.add_theme_stylebox_override("normal", _card_style(card_id, selected_card == card_id))


func _card_style(card_id: String, highlighted: bool, disabled: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("182230") if not disabled else Color("15191e")
	var accent := Color("59c9ff")
	if card_id == "ranger":
		accent = Color("54d9be")
	elif card_id == "colossus":
		accent = Color("d6b365")
	elif card_id == "fireball":
		accent = Color("ff8a47")
	elif card_id == "duelist":
		accent = Color("ef6b67")
	elif card_id == "alchemist":
		accent = Color("ffb940")
	elif card_id == "bulwark":
		accent = Color("80a66c")
	elif card_id == "frost":
		accent = Color("73ddff")
	style.border_color = Color("ffe17b") if highlighted else accent.darkened(0.18)
	style.set_border_width_all(4 if highlighted else 2)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0.0, 4.0)
	return style


func _card_texture(card_id: String, quadrant: Vector2i) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	var sheet: Texture2D = CARD_ART_V4 if card_id in V4_CARD_IDS else CARD_ART
	atlas.atlas = sheet
	atlas.region = Rect2(
		quadrant.x * sheet.get_width() * 0.5,
		quadrant.y * sheet.get_height() * 0.5,
		sheet.get_width() * 0.5,
		sheet.get_height() * 0.5
	)
	return atlas


func _energy_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(12)
	style.border_color = Color("70278a") if color.get_luminance() > 0.2 else Color("354052")
	style.set_border_width_all(2)
	return style


func _show_result(award_progression: bool = true) -> void:
	_clear_pause_overlay()
	state = ScreenState.RESULT
	if tutorial == null and award_progression:
		if simulation.winner == BattleSim.PLAYER:
			profile.wins += 1
		elif simulation.winner == BattleSim.ENEMY:
			profile.losses += 1
		else:
			profile.draws += 1
		last_reward = BattleProgression.apply_match_result(profile, simulation.winner, simulation.crowns[BattleSim.PLAYER])
		_save_profile()
		if last_reward.levels > 0:
			_haptic(180, 0.72)
	_clear_ui()
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	var panel := ColorRect.new()
	panel.position = Vector2(80.0, 350.0)
	panel.size = Vector2(560.0, 540.0)
	panel.color = Color(0.04, 0.08, 0.13, 0.94)
	ui_layer.add_child(panel)
	var result_text := "ÉGALITÉ"
	if simulation.winner == BattleSim.PLAYER:
		result_text = "VICTOIRE"
	elif simulation.winner == BattleSim.ENEMY:
		result_text = "DÉFAITE"
	var result_color := Color("76e68b") if simulation.winner == BattleSim.PLAYER else (Color("ffcf68") if simulation.winner == -1 else Color("ff7785"))
	var result := _label(result_text, Vector2(120.0, 405.0), Vector2(480.0, 80.0), 48)
	result.add_theme_color_override("font_color", result_color)
	var summary := _label("Score : %d — %d  •  Noyaux : %d — %d" % [simulation.crowns[BattleSim.PLAYER], simulation.crowns[BattleSim.ENEMY], int(simulation.towers[BattleSim.PLAYER].core), int(simulation.towers[BattleSim.ENEMY].core)], Vector2(105.0, 510.0), Vector2(510.0, 45.0), 19)
	var reward_text := "Entraînement • statistiques inchangées"
	if tutorial == null:
		reward_text = "+%d éclats  •  +%d XP" % [last_reward.coins, last_reward.xp]
	var reward := _label(reward_text, Vector2(105.0, 560.0), Vector2(510.0, 36.0), 18)
	reward.add_theme_color_override("font_color", Color("f2c96d"))
	if tutorial == null:
		var xp_max := BattleProgression.xp_to_next(profile.level)
		var level := _label("NIVEAU %d  •  %d/%d XP" % [profile.level, profile.xp, xp_max], Vector2(160.0, 610.0), Vector2(400.0, 32.0), 17)
		level.add_theme_color_override("font_color", Color("b9d9ec"))
		var xp_bar := ProgressBar.new()
		xp_bar.position = Vector2(160.0, 647.0)
		xp_bar.size = Vector2(400.0, 24.0)
		xp_bar.max_value = xp_max
		xp_bar.value = profile.xp
		xp_bar.show_percentage = false
		xp_bar.add_theme_stylebox_override("background", _energy_style(Color("111925")))
		xp_bar.add_theme_stylebox_override("fill", _energy_style(Color("55bfe8")))
		ui_layer.add_child(xp_bar)
		var progress_message := "NIVEAU SUPÉRIEUR !" if last_reward.levels > 0 else "%d XP avant le niveau %d" % [xp_max - profile.xp, profile.level + 1]
		var progress := _label(progress_message, Vector2(150.0, 677.0), Vector2(420.0, 32.0), 17)
		progress.add_theme_color_override("font_color", Color("ffe17b") if last_reward.levels > 0 else Color("8fa7b8"))
	else:
		var training_done := _label("Tutoriel terminé • prêt pour le duel", Vector2(130.0, 625.0), Vector2(460.0, 42.0), 18)
		training_done.add_theme_color_override("font_color", Color("b9d9ec"))
	var replay := Button.new()
	replay.text = "REJOUER"
	replay.position = Vector2(180.0, 720.0)
	replay.size = Vector2(360.0, 70.0)
	replay.pressed.connect(_start_tutorial if tutorial != null else _start_battle)
	ui_layer.add_child(replay)
	var menu := Button.new()
	menu.text = "MENU"
	menu.position = Vector2(180.0, 805.0)
	menu.size = Vector2(360.0, 54.0)
	menu.pressed.connect(_build_menu)
	ui_layer.add_child(menu)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == ScreenState.BATTLE and not battle_paused:
		call_deferred("_pause_battle")


func _pause_battle() -> void:
	if state != ScreenState.BATTLE or battle_paused:
		return
	battle_paused = true
	pause_layer = CanvasLayer.new()
	pause_layer.layer = 20
	add_child(pause_layer)
	var shade := ColorRect.new()
	shade.position = Vector2.ZERO
	shade.size = DESIGN_SIZE
	shade.color = Color(0.02, 0.04, 0.08, 0.82)
	pause_layer.add_child(shade)
	var panel := ColorRect.new()
	panel.position = Vector2(90.0, 390.0)
	panel.size = Vector2(540.0, 420.0)
	panel.color = Color("111c2b")
	pause_layer.add_child(panel)
	var title := Label.new()
	title.text = "PARTIE EN PAUSE"
	title.position = Vector2(120.0, 435.0)
	title.size = Vector2(480.0, 72.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("ffe17b"))
	pause_layer.add_child(title)
	var resume := Button.new()
	resume.text = "REPRENDRE"
	resume.position = Vector2(180.0, 550.0)
	resume.size = Vector2(360.0, 76.0)
	resume.add_theme_font_size_override("font_size", 23)
	resume.pressed.connect(_resume_battle)
	pause_layer.add_child(resume)
	var abandon := Button.new()
	abandon.text = "ABANDONNER"
	abandon.position = Vector2(180.0, 650.0)
	abandon.size = Vector2(360.0, 62.0)
	abandon.add_theme_font_size_override("font_size", 19)
	abandon.pressed.connect(_abandon_battle)
	pause_layer.add_child(abandon)


func _resume_battle() -> void:
	_clear_pause_overlay()


func _abandon_battle() -> void:
	if simulation == null or not simulation.forfeit(BattleSim.PLAYER):
		return
	_clear_pause_overlay()
	_show_result()


func _clear_pause_overlay() -> void:
	battle_paused = false
	if is_instance_valid(pause_layer):
		pause_layer.queue_free()
	pause_layer = null


func _label(text_value: String, position_value: Vector2, size_value: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = position_value
	label.size = size_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	ui_layer.add_child(label)
	return label


func _clear_ui() -> void:
	if is_instance_valid(ui_layer):
		ui_layer.queue_free()


func _load_profile() -> void:
	var parsed := BattleProfileStore.load_profile(SAVE_PATH)
	if parsed.is_empty():
		return
	profile = BattleProgression.normalize(parsed)
	sound_enabled = profile.sound_enabled
	selected_difficulty = profile.difficulty
	haptics_enabled = profile.haptics_enabled


func _save_profile() -> void:
	profile.sound_enabled = sound_enabled
	profile.difficulty = selected_difficulty
	profile.haptics_enabled = haptics_enabled
	profile.version = BattleProgression.CURRENT_VERSION
	BattleProfileStore.save_profile(SAVE_PATH, profile)
