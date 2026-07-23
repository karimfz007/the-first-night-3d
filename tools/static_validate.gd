extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_require("project.godot")
	_require("export_presets.cfg")
	_require("src/data/tune.gd")
	_require("src/body/main.tscn")
	_require("docs/3D_PIVOT.md")
	_require("DEPENDENCIES.md")
	_validate_save_schema()
	_validate_brain_boundary("res://src/brain")
	_validate_no_secrets("res://")
	if failures.is_empty():
		print("STATIC VALIDATION PASS")
		quit(0)
	else:
		for failure in failures:
			printerr("STATIC VALIDATION FAIL: " + failure)
		quit(1)

func _require(relative_path: String) -> void:
	if not FileAccess.file_exists("res://" + relative_path):
		failures.append("missing " + relative_path)

func _validate_save_schema() -> void:
	var text := FileAccess.get_file_as_string("res://src/data/tune.gd")
	if "SCHEMA_VERSION" not in text:
		failures.append("tune.gd lacks SCHEMA_VERSION")
	var save_text := FileAccess.get_file_as_string("res://src/brain/save_codec.gd")
	if "\"schema_version\"" not in save_text and "SCHEMA_VERSION" not in save_text:
		failures.append("save codec lacks schema handling")

func _validate_brain_boundary(path: String) -> void:
	for file_path in _files_recursive(path):
		if not file_path.ends_with(".gd"):
			continue
		var text := FileAccess.get_file_as_string(file_path)
		for forbidden in ["Node3D", "Camera3D", "Input.", "RenderingServer", "AudioStream", "get_tree()"]:
			if forbidden in text:
				failures.append("%s contains forbidden body dependency %s" % [file_path, forbidden])

func _validate_no_secrets(path: String) -> void:
	for file_path in _files_recursive(path):
		if file_path.contains("/.git/") or file_path.contains("/.godot/"):
			continue
		if file_path.ends_with("/tools/static_validate.gd"):
			continue
		if not file_path.get_extension().to_lower() in ["gd", "md", "godot", "cfg", "yml", "yaml", "txt", "svg"]:
			continue
		var text := FileAccess.get_file_as_string(file_path)
		for pattern in ["BEGIN PRIVATE KEY", "ghp_", "github_pat_", "AKIA"]:
			if pattern in text:
				failures.append("%s contains secret-like token %s" % [file_path, pattern])

func _files_recursive(path: String) -> Array[String]:
	var result: Array[String] = []
	var directory := DirAccess.open(path)
	if directory == null:
		return result
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry != "." and entry != "..":
			var child := path.path_join(entry)
			if directory.current_is_dir():
				result.append_array(_files_recursive(child))
			else:
				result.append(child)
		entry = directory.get_next()
	directory.list_dir_end()
	return result
