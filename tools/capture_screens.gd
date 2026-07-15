extends SceneTree


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	_save_viewport("res://builds/menu.png")
	scene._start_battle()
	scene.simulation.energy = [10.0, 10.0]
	scene.simulation.play_card(BattleSim.PLAYER, "guardian", 0)
	scene.simulation.play_card(BattleSim.PLAYER, "ranger", 1)
	scene.simulation.play_card(BattleSim.ENEMY, "colossus", 0)
	scene.simulation.play_card(BattleSim.ENEMY, "ranger", 1)
	for index in range(4):
		await process_frame
	_save_viewport("res://builds/battle.png")
	quit()


func _save_viewport(path: String) -> void:
	var image := root.get_texture().get_image()
	var error := image.save_png(path)
	if error != OK:
		push_error("Unable to save screenshot %s: %s" % [path, error_string(error)])
