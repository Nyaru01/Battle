extends SceneTree


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	_save_viewport("res://builds/menu.png")
	scene._start_tutorial()
	scene._select_card("guardian")
	for index in range(2):
		await process_frame
	_save_viewport("res://builds/tutorial.png")
	scene._start_battle()
	scene.simulation.energy = [100.0, 100.0]
	for card_id in ["guardian", "ranger", "colossus", "fireball"]:
		scene.simulation.play_card(BattleSim.PLAYER, card_id, 1)
		scene.simulation.play_card(BattleSim.ENEMY, card_id, 0)
	scene.simulation.units.clear()
	scene.simulation.play_card(BattleSim.PLAYER, "duelist", 0)
	scene.simulation.play_card(BattleSim.PLAYER, "alchemist", 1)
	scene.simulation.play_card(BattleSim.PLAYER, "bulwark", 0)
	scene.simulation.play_card(BattleSim.ENEMY, "duelist", 1)
	scene.simulation.play_card(BattleSim.ENEMY, "alchemist", 0)
	scene.simulation.play_card(BattleSim.ENEMY, "bulwark", 1)
	scene.simulation.towers[BattleSim.ENEMY].lanes[0] = 1.0
	scene.simulation._damage_objective(BattleSim.ENEMY, 0, 5.0)
	scene.simulation.towers[BattleSim.PLAYER].lanes[1] = 1.0
	scene.simulation._damage_objective(BattleSim.PLAYER, 1, 5.0)
	scene.simulation.overtime = true
	scene.simulation.time_left = 45.0
	scene._build_hud()
	for index in range(4):
		await process_frame
	_save_viewport("res://builds/battle.png")
	scene._pause_battle()
	for index in range(2):
		await process_frame
	_save_viewport("res://builds/pause.png")
	scene._resume_battle()
	scene.simulation.forfeit(BattleSim.ENEMY)
	scene._show_result()
	for index in range(2):
		await process_frame
	_save_viewport("res://builds/result.png")
	quit()


func _save_viewport(path: String) -> void:
	var image := root.get_texture().get_image()
	var error := image.save_png(path)
	if error != OK:
		push_error("Unable to save screenshot %s: %s" % [path, error_string(error)])
