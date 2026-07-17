extends SceneTree


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(540, 960))
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await _frames(4)
	_save_viewport("res://builds/screens/menu-540x960.png")
	scene._show_settings()
	await _frames(3)
	_save_viewport("res://builds/screens/settings-540x960.png")
	scene._clear_settings_overlay()
	scene._build_collection()
	await _frames(4)
	_save_viewport("res://builds/screens/collection-540x960.png")
	scene.tutorial = null
	scene._start_battle(false)
	await _frames(3)
	_save_viewport("res://builds/screens/intro-540x960.png")
	scene.battle_intro_time = 0.0
	scene.simulation.energy = [100.0, 100.0]
	scene.simulation.play_card(BattleSim.PLAYER, "guardian", 0, Vector2(120.0, 760.0))
	scene.simulation.play_card(BattleSim.PLAYER, "ranger", 1, Vector2(585.0, 690.0))
	scene.simulation.play_card(BattleSim.ENEMY, "guardian", 1, Vector2(600.0, 400.0))
	scene.simulation.play_card(BattleSim.ENEMY, "ranger", 0, Vector2(115.0, 470.0))
	await _frames(12)
	_save_viewport("res://builds/screens/battle-540x960.png")
	scene.simulation.double_energy = true
	scene.simulation.events.append({"type": "double_energy_started"})
	scene._consume_battle_events()
	scene._update_hud()
	scene.battle_announcement._process(0.22)
	await _frames(3)
	_save_viewport("res://builds/screens/double-energy-540x960.png")
	scene.battle_announcement._process(2.0)
	scene.simulation.double_energy = false
	scene.simulation.towers[BattleSim.ENEMY].lanes[0] = 0.0
	scene.simulation.crowns[BattleSim.PLAYER] = 1
	scene.simulation.events.append({"type": "tower_destroyed", "side": BattleSim.ENEMY, "lane": 0, "attacker": BattleSim.PLAYER})
	scene._consume_battle_events()
	scene.battle_world.sync(scene.simulation)
	scene._update_hud()
	scene.battle_announcement._process(0.22)
	await _frames(3)
	_save_viewport("res://builds/screens/tower-destroyed-540x960.png")
	scene.battle_announcement._process(2.0)
	scene.simulation.towers[BattleSim.ENEMY].lanes[0] = 1200.0
	scene.simulation.crowns[BattleSim.PLAYER] = 0
	scene._select_card("duelist")
	await _frames(4)
	_save_viewport("res://builds/screens/targeting-540x960.png")
	scene._pause_battle()
	await _frames(3)
	_save_viewport("res://builds/screens/pause-540x960.png")
	scene._resume_battle()
	DisplayServer.window_set_size(Vector2i(720, 1280))
	await _frames(6)
	_save_viewport("res://builds/screens/battle-720x1280.png")
	DisplayServer.window_set_size(Vector2i(800, 1280))
	await _frames(6)
	_save_viewport("res://builds/screens/battle-tablet-800x1280.png")
	DisplayServer.window_set_size(Vector2i(591, 1280))
	await _frames(6)
	_save_viewport("res://builds/screens/battle-tall-591x1280.png")
	DisplayServer.window_set_size(Vector2i(540, 960))
	await _frames(5)
	scene.simulation.forfeit(BattleSim.ENEMY)
	scene._show_result(false)
	await _frames(3)
	_save_viewport("res://builds/screens/result-540x960.png")
	quit()


func _frames(count: int) -> void:
	for index in range(count):
		await process_frame


func _save_viewport(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var image := root.get_texture().get_image()
	var error := image.save_png(path)
	if error != OK:
		push_error("Unable to save screenshot %s: %s" % [path, error_string(error)])
