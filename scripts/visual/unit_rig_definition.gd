class_name UnitRigDefinition
extends Resource

const ATLAS_COLUMNS := 10
const VIEW_FRAME_COUNT := 50
const STATE_DATA := {
	"spawn": {"start": 0, "frames": 8, "fps": 12.0, "loop": false},
	"idle": {"start": 8, "frames": 8, "fps": 8.0, "loop": true},
	"walk": {"start": 16, "frames": 10, "fps": 12.0, "loop": true},
	"attack": {"start": 26, "frames": 10, "fps": 15.0, "loop": false},
	"hit": {"start": 36, "frames": 4, "fps": 15.0, "loop": false},
	"death": {"start": 40, "frames": 10, "fps": 12.0, "loop": false},
}

const RIG_TEXTURES := {
	"guardian": preload("res://assets/v050/characters/guardian-kaykit-v050.png"),
	"ranger": preload("res://assets/v050/characters/ranger-kaykit-v050.png"),
	"colossus": preload("res://assets/v050/characters/colossus-kaykit-v050.png"),
	"duelist": preload("res://assets/v050/characters/duelist-kaykit-v050.png"),
	"alchemist": preload("res://assets/v050/characters/alchemist-kaykit-v050.png"),
	"bulwark": preload("res://assets/v050/characters/bulwark-kaykit-v050.png"),
}

const PROFILES := {
	"guardian": {"scale": 0.61, "motion": "melee", "accent": Color("63dcff"), "card": Color("163f72")},
	"ranger": {"scale": 0.59, "motion": "ranged", "accent": Color("49d77f"), "card": Color("175a48")},
	"colossus": {"scale": 0.69, "motion": "heavy", "accent": Color("f6c548"), "card": Color("684b36")},
	"duelist": {"scale": 0.58, "motion": "dual", "accent": Color("d47cff"), "card": Color("56356f")},
	"alchemist": {"scale": 0.60, "motion": "ranged", "accent": Color("ffb74d"), "card": Color("5d3986")},
	"bulwark": {"scale": 0.67, "motion": "heavy", "accent": Color("9fe287"), "card": Color("40566b")},
}

@export var card_id := ""
@export var atlas: Texture2D
@export var visual_scale := 0.58
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


func frame_region(state: String, frame: int, back_view := false) -> Rect2:
	var data: Dictionary = STATE_DATA.get(state, STATE_DATA.idle)
	var local_frame := posmod(frame, int(data.frames)) if bool(data.loop) else clampi(frame, 0, int(data.frames) - 1)
	var atlas_frame := int(data.start) + local_frame + (VIEW_FRAME_COUNT if back_view else 0)
	return cell_region(atlas_frame / ATLAS_COLUMNS, atlas_frame % ATLAS_COLUMNS)


func frame_texture(state: String, frame: int, back_view := false) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = frame_region(state, frame, back_view)
	return texture


func state_frame_count(state: String) -> int:
	return int(Dictionary(STATE_DATA.get(state, STATE_DATA.idle)).frames)


func state_fps(state: String) -> float:
	return float(Dictionary(STATE_DATA.get(state, STATE_DATA.idle)).fps)


func state_duration(state: String) -> float:
	return float(state_frame_count(state)) / state_fps(state)


func cell_region(row: int, column: int) -> Rect2:
	var cell := Vector2(atlas.get_width() / float(ATLAS_COLUMNS), atlas.get_height() / float(ATLAS_COLUMNS))
	return Rect2(Vector2(column, row) * cell, cell)
