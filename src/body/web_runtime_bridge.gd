class_name WebRuntimeBridge
extends RefCounted
## Read-only browser-test and shell state. Gameplay remains wholly inside Godot.

static func publish(values: Dictionary) -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval(
		"window.__tfn = Object.assign(window.__tfn || {}, %s);" % JSON.stringify(values)
	)

static func local_test_fixture_requested() -> bool:
	if not OS.has_feature("web"):
		return false
	return bool(JavaScriptBridge.eval(
		"(location.hostname === '127.0.0.1' || location.hostname === 'localhost') && new URLSearchParams(location.search).get('tfn_test') === 'placement';",
		true
	))
