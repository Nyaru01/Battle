class_name BattleProfileStore
extends RefCounted


static func load_profile(path: String) -> Dictionary:
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var file := FileAccess.open(candidate, FileAccess.READ)
		if file == null:
			continue
		var json := JSON.new()
		if json.parse(file.get_as_text()) != OK:
			continue
		var parsed = json.data
		if typeof(parsed) == TYPE_DICTIONARY:
			return parsed
	return {}


static func save_profile(path: String, profile: Dictionary) -> bool:
	var temporary := path + ".tmp"
	var backup := path + ".bak"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(profile))
	file.flush()
	file.close()

	var absolute_path := ProjectSettings.globalize_path(path)
	var absolute_temporary := ProjectSettings.globalize_path(temporary)
	var absolute_backup := ProjectSettings.globalize_path(backup)
	if FileAccess.file_exists(backup):
		DirAccess.remove_absolute(absolute_backup)
	if FileAccess.file_exists(path):
		if DirAccess.rename_absolute(absolute_path, absolute_backup) != OK:
			DirAccess.remove_absolute(absolute_temporary)
			return false
	var replace_error := DirAccess.rename_absolute(absolute_temporary, absolute_path)
	if replace_error != OK:
		if FileAccess.file_exists(backup):
			DirAccess.rename_absolute(absolute_backup, absolute_path)
		DirAccess.remove_absolute(absolute_temporary)
		return false
	if FileAccess.file_exists(backup):
		DirAccess.remove_absolute(absolute_backup)
	return true
