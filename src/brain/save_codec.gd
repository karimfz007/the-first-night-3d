class_name SaveCodec
extends RefCounted

const SAVE_PATH := "user://world.json"
const BACKUP_PATH := "user://world.json.bak"
const TEMP_PATH := "user://world.json.tmp"

static func encode(state: Dictionary) -> String:
	return JSON.stringify(WorldState.sanitized(state), "\t", false)

static func decode(text: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	var parsed: Variant = json.data
	if parsed is not Dictionary:
		return {}
	var migrated := migrate(parsed)
	if migrated.is_empty():
		return {}
	return WorldState.sanitized(migrated)

static func migrate(raw: Dictionary) -> Dictionary:
	var state := raw.duplicate(true)
	var version := int(state.get("schema_version", 1))
	if version < 1 or version > Tune.SCHEMA_VERSION:
		return {}
	if version == 1:
		if state.has("temperature") and not state.has("warmth"):
			state["warmth"] = state.temperature
		state.erase("temperature")
		if not state.has("stable_ids"):
			state["stable_ids"] = {"counter": 1}
		state["schema_version"] = 2
	return state

static func save_file(state: Dictionary, path: String = SAVE_PATH) -> bool:
	var text := encode(state)
	var temp_path := path + ".tmp"
	var backup_path := path + ".bak"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	file.close()
	var absolute_path := ProjectSettings.globalize_path(path)
	var absolute_temp := ProjectSettings.globalize_path(temp_path)
	var absolute_backup := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(absolute_backup)
		if DirAccess.rename_absolute(absolute_path, absolute_backup) != OK:
			return false
	if DirAccess.rename_absolute(absolute_temp, absolute_path) != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(absolute_backup, absolute_path)
		return false
	return true

static func load_file(path: String = SAVE_PATH) -> Dictionary:
	var primary := _read(path)
	if not primary.is_empty():
		return primary
	return _read(path + ".bak")

static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	return decode(text)
