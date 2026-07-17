extends SceneTree

const SOURCE_ROOT := "C:/Users/Nyaru/AppData/Local/Temp/Battle-v050-vendor"
const ADVENTURERS := SOURCE_ROOT + "/adventurers/KayKit_Adventurers_2.0_FREE"
const ANIMATIONS := SOURCE_ROOT + "/animations/KayKit_Character_Animations_1.1/Animations/gltf/Rig_Medium"
const OUTPUT_DIR := "res://assets/v050/characters"
const CELL_SIZE := 192
const RENDER_SIZE := 384
const ATLAS_COLUMNS := 10
const ATLAS_ROWS := 10

const STATES := [
	{"name": "spawn", "animation": "Spawn_Ground", "frames": 8, "source": "general"},
	{"name": "idle", "animation": "Idle_A", "frames": 8, "source": "general", "loop": true},
	{"name": "walk", "animation": "Walking_A", "frames": 10, "source": "movement", "loop": true},
	{"name": "attack", "animation": "", "frames": 10, "source": "attack"},
	{"name": "hit", "animation": "Hit_A", "frames": 4, "source": "general"},
	{"name": "death", "animation": "Death_A", "frames": 10, "source": "general"},
]

const CHARACTERS := {
	"guardian": {
		"model": "Knight.glb", "attack": "Melee_1H_Attack_Slice_Horizontal", "attack_source": "melee",
		"hide": ["Knight_HelmetVisor"],
		"equipment": [["sword_1handed", "handslot.r"], ["shield_round_color", "handslot.l"]],
	},
	"ranger": {
		"model": "Ranger.glb", "attack": "Ranged_Bow_Release", "attack_source": "ranged",
		"equipment": [["bow_withString", "handslot.l"], ["quiver", "chest"]],
	},
	"colossus": {
		"model": "Barbarian.glb", "attack": "Melee_2H_Attack_Chop", "attack_source": "melee",
		"equipment": [["axe_2handed", "handslot.r"]],
	},
	"duelist": {
		"model": "Rogue_Hooded.glb", "attack": "Melee_Dualwield_Attack_Slice", "attack_source": "melee",
		"equipment": [["dagger", "handslot.r"], ["dagger", "handslot.l", Vector3(0.0, 0.0, 0.0), Vector3(0.0, PI, 0.0)]],
	},
	"alchemist": {
		"model": "Mage.glb", "attack": "Ranged_Magic_Shoot", "attack_source": "ranged",
		"equipment": [["wand", "handslot.r"], ["mug_full", "handslot.l"]],
	},
	"bulwark": {
		"model": "Knight.glb", "attack": "Melee_Block_Attack", "attack_source": "melee",
		"hide": ["Knight_Cape"],
		"equipment": [["axe_1handed", "handslot.r"], ["shield_square_color", "handslot.l"]],
	},
}

var animation_bank: Dictionary = {}
var viewport: SubViewport
var stage: Node3D
var camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_load_animation_bank()
	_build_render_stage()
	await process_frame
	for card_id in CHARACTERS:
		print("Rendering %s..." % card_id)
		await _render_character(String(card_id), CHARACTERS[card_id])
	viewport.queue_free()
	await process_frame
	print("Generated %d KayKit character atlases in %s" % [CHARACTERS.size(), OUTPUT_DIR])
	quit()


func _load_animation_bank() -> void:
	var sources := {
		"general": ANIMATIONS + "/Rig_Medium_General.glb",
		"movement": ANIMATIONS + "/Rig_Medium_MovementBasic.glb",
		"melee": ANIMATIONS + "/Rig_Medium_CombatMelee.glb",
		"ranged": ANIMATIONS + "/Rig_Medium_CombatRanged.glb",
	}
	for source_id in sources:
		var source_scene := _load_gltf(String(sources[source_id]))
		var source_player := _find_animation_player(source_scene)
		if source_player == null:
			push_error("No AnimationPlayer in %s" % sources[source_id])
			quit(1)
			return
		for animation_name in source_player.get_animation_list():
			if animation_name == "RESET":
				continue
			animation_bank[animation_name] = source_player.get_animation(animation_name).duplicate(true)
		queue_delete(source_scene)


func _build_render_stage() -> void:
	viewport = SubViewport.new()
	viewport.name = "CharacterRenderer"
	viewport.size = Vector2i(RENDER_SIZE, RENDER_SIZE)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	get_root().add_child(viewport)
	stage = Node3D.new()
	viewport.add_child(stage)

	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.0, 0.0, 0.0, 0.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("cce7ff")
	environment.ambient_light_energy = 0.92
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	stage.add_child(world_environment)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	key.light_color = Color("fff0cf")
	key.light_energy = 1.65
	stage.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-22.0, 142.0, 8.0)
	fill.light_color = Color("8cdcff")
	fill.light_energy = 0.72
	stage.add_child(fill)

	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.15
	camera.position = Vector3(3.8, 2.85, 5.8)
	stage.add_child(camera)
	camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	camera.current = true


func _render_character(card_id: String, config: Dictionary) -> void:
	var character := _load_gltf(ADVENTURERS + "/Characters/gltf/" + String(config.model))
	character.name = "Character"
	stage.add_child(character)
	for hidden_name in config.get("hide", []):
		var hidden := character.find_child(String(hidden_name), true, false)
		if hidden is VisualInstance3D:
			hidden.visible = false
	var skeleton := character.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null:
		push_error("No skeleton for %s" % card_id)
		quit(1)
		return
	for equipment_data in config.equipment:
		_attach_equipment(skeleton, equipment_data)
	var player := AnimationPlayer.new()
	player.name = "SpriteAnimationPlayer"
	character.add_child(player)
	var library := AnimationLibrary.new()
	player.add_animation_library("", library)
	for animation_name in animation_bank:
		library.add_animation(StringName(animation_name), animation_bank[animation_name])

	var atlas := Image.create_empty(CELL_SIZE * ATLAS_COLUMNS, CELL_SIZE * ATLAS_ROWS, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(0.0, 0.0, 0.0, 0.0))
	var output_frame := 0
	for view_index in 2:
		character.rotation.y = PI if view_index == 1 else 0.0
		for state_config_value in STATES:
			var state_config: Dictionary = state_config_value
			var animation_name := String(state_config.animation)
			if String(state_config.source) == "attack":
				animation_name = String(config.attack)
			if not player.has_animation(animation_name):
				push_error("Missing animation %s for %s" % [animation_name, card_id])
				quit(1)
				return
			var animation := player.get_animation(animation_name)
			var frame_count := int(state_config.frames)
			for frame_index in frame_count:
				var divisor := float(frame_count) if bool(state_config.get("loop", false)) else float(maxi(1, frame_count - 1))
				var sample_time := animation.length * float(frame_index) / divisor
				player.play(animation_name)
				player.seek(sample_time, true)
				player.advance(0.0)
				await process_frame
				await process_frame
				var rendered := viewport.get_texture().get_image()
				rendered.resize(CELL_SIZE, CELL_SIZE, Image.INTERPOLATE_LANCZOS)
				var target := Vector2i(output_frame % ATLAS_COLUMNS, output_frame / ATLAS_COLUMNS) * CELL_SIZE
				atlas.blit_rect(rendered, Rect2i(Vector2i.ZERO, rendered.get_size()), target)
				output_frame += 1
	var output_path := OUTPUT_DIR + "/%s-kaykit-v050.png" % card_id
	var save_error := atlas.save_png(ProjectSettings.globalize_path(output_path))
	if save_error != OK:
		push_error("Unable to save %s: %s" % [output_path, error_string(save_error)])
		quit(1)
	character.queue_free()
	await process_frame


func _attach_equipment(skeleton: Skeleton3D, equipment_data: Array) -> void:
	var asset_name := String(equipment_data[0])
	var bone_name := String(equipment_data[1])
	var prop := _load_gltf(ADVENTURERS + "/Assets/gltf/%s.gltf" % asset_name)
	prop.name = asset_name
	if equipment_data.size() > 2:
		prop.position = Vector3(equipment_data[2])
	if equipment_data.size() > 3:
		prop.rotation = Vector3(equipment_data[3])
	var attachment := BoneAttachment3D.new()
	attachment.name = "Attachment_%s_%s" % [bone_name.replace(".", "_"), asset_name]
	attachment.bone_name = bone_name
	skeleton.add_child(attachment)
	attachment.add_child(prop)


func _load_gltf(path: String) -> Node3D:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_file(path, state)
	if error != OK:
		push_error("Unable to load %s: %s" % [path, error_string(error)])
		quit(1)
		return Node3D.new()
	return document.generate_scene(state)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result := _find_animation_player(child)
		if result != null:
			return result
	return null
