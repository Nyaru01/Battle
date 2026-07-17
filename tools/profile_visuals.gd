extends SceneTree

const WARMUP_FRAMES := 90
const SAMPLE_FRAMES := 300


func _init() -> void:
	call_deferred("_profile")


func _profile() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(720, 1280))
	var simulation := BattleSim.new(4040, {}, {}, false)
	var attempt := 0
	while simulation.units.size() < 20 and attempt < 80:
		var side := attempt % 2
		simulation.energy[side] = 100.0
		var card_id: String = simulation.get_hand(side)[0]
		simulation.play_card(side, card_id, attempt % 2)
		attempt += 1
	if simulation.units.size() < 20:
		push_error("Unable to prepare the 20-unit visual profile")
		quit(1)
		return
	for index in range(simulation.units.size()):
		var unit: Dictionary = simulation.units[index]
		unit.y = 420.0 + float(index % 8) * 48.0
		unit.moving = true
		unit.walk_phase = float(index)
	var world := BattleWorld2D.new()
	world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(world)
	world.sync(simulation)
	for index in range(WARMUP_FRAMES):
		await process_frame
		for unit in simulation.units:
			unit.walk_phase += 0.12
		world.sync(simulation)
	var start_usec := Time.get_ticks_usec()
	for index in range(SAMPLE_FRAMES):
		await process_frame
		for unit in simulation.units:
			unit.walk_phase += 0.12
			unit.attack_pulse = 0.2 if index % 24 < 3 else 0.0
		world.sync(simulation)
	var duration_seconds := float(Time.get_ticks_usec() - start_usec) / 1000000.0
	var average_fps := float(SAMPLE_FRAMES) / maxf(duration_seconds, 0.001)
	var target_label := "ideal 60 FPS reached" if average_fps >= 60.0 else "30 FPS fallback reached"
	print("Visual profile: %d animated heroes | %d frames | %.1f FPS average | %.2f ms/frame | %s" % [simulation.units.size(), SAMPLE_FRAMES, average_fps, duration_seconds * 1000.0 / SAMPLE_FRAMES, target_label])
	quit(0 if average_fps >= 30.0 else 1)
