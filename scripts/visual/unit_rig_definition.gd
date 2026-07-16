class_name UnitRigDefinition
extends Resource

const RIG_TEXTURES := {
	"guardian": preload("res://assets/v040/rigs/guardian-rig-v040.png"),
	"ranger": preload("res://assets/v040/rigs/ranger-rig-v040.png"),
	"colossus": preload("res://assets/v040/rigs/colossus-rig-v040.png"),
	"duelist": preload("res://assets/v040/rigs/duelist-rig-v040.png"),
	"alchemist": preload("res://assets/v040/rigs/alchemist-rig-v040.png"),
	"bulwark": preload("res://assets/v040/rigs/bulwark-rig-v040.png"),
}

const PROFILES := {
	"guardian": {"scale": 0.255, "motion": "melee", "accent": Color("3fbfff"), "card": Color("183e68")},
	"ranger": {"scale": 0.235, "motion": "ranged", "accent": Color("52e6a1"), "card": Color("185943")},
	"colossus": {"scale": 0.292, "motion": "heavy", "accent": Color("5ee9ff"), "card": Color("4a5c67")},
	"duelist": {"scale": 0.225, "motion": "dual", "accent": Color("ff6f7f"), "card": Color("5c294b")},
	"alchemist": {"scale": 0.245, "motion": "ranged", "accent": Color("ffbf4f"), "card": Color("625028")},
	"bulwark": {"scale": 0.285, "motion": "heavy", "accent": Color("a9cf67"), "card": Color("344a35")},
}

@export var card_id := ""
@export var atlas: Texture2D
@export var visual_scale := 0.24
@export var motion_profile := "melee"
@export var accent := Color.WHITE
@export var card_background := Color("17324c")


static func for_card(id: String) -> UnitRigDefinition:
	var definition := UnitRigDefinition.new()
	definition.card_id = id
	definition.atlas = RIG_TEXTURES.get(id, RIG_TEXTURES.guardian)
	var profile: Dictionary = PROFILES.get(id, PROFILES.guardian)
	definition.visual_scale = float(profile.scale)
	definition.motion_profile = String(profile.motion)
	definition.accent = Color(profile.accent)
	definition.card_background = Color(profile.card)
	return definition


func cell_region(row: int, column: int) -> Rect2:
	var cell := Vector2(atlas.get_width() / 4.0, atlas.get_height() / 4.0)
	return Rect2(Vector2(column, row) * cell, cell)


func cell_texture(row: int, column: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = cell_region(row, column)
	return texture
