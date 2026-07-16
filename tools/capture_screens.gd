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
	scene._build_collection()
	await _frames(4)
	_save_viewport("res://builds/screens/collection-540x960.png")
	scene.tutorial = null
	scene._start_battle(false)
	await _frames(3)
	_save_viewport("res://builds/screens/intro-540x960.png")
	scene.battle_intro_time = 0.0
	scene.simulation.energy = [100.0, 100.0]
	scene.simulation.play_card(BattleSim.PLAYER, "guardian", 0)
	scene.simulation.play_card(BattleSim.PLAYER, "ranger", 1)
	scene.simulation.play_card(BattleSim.ENEMY, "guardian", 1)
	scene.simulation.play_card(BattleSim.ENEMY, "ranger", 0)
	for unit in scene.simulation.units:
		unit.y = 680.0 if unit.side == BattleSim.PLAYER else 470.0
	await _frames(12)
	_save_viewport("res://builds/screens/battle-540x960.png")
	scene._select_card("fireball")
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
