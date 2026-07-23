class_name AudioFeedback
extends Node

var _player: AudioStreamPlayer
var _generator: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback
var _ambient_phase := 0.0

const CUES := {
	"pickup": [620.0, 0.08],
	"craft": [760.0, 0.14],
	"fail": [145.0, 0.16],
	"impact_wood": [180.0, 0.09],
	"impact_stone": [260.0, 0.08],
	"step_sand": [92.0, 0.055],
	"build": [420.0, 0.12],
	"ignite": [520.0, 0.2],
	"confirm": [680.0, 0.06]
}

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_generator = AudioStreamGenerator.new()
	_generator.mix_rate = Tune.AMBIENT_SAMPLE_RATE
	_generator.buffer_length = 0.5
	_player = AudioStreamPlayer.new()
	_player.stream = _generator
	_player.volume_db = -11.0
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()

func _process(delta: float) -> void:
	if _playback == null or _playback.get_frames_available() < int(_generator.mix_rate * 0.06):
		return
	var game := get_tree().get_first_node_in_group("game")
	if game == null:
		return
	var is_night := Tune.is_night(float(game.world_seconds))
	var fire: Campfire = game.current_fire()
	var fire_active := fire != null and fire.lit
	if not is_night and not fire_active:
		return
	var frames := int(_generator.mix_rate * minf(delta + 0.012, 0.06))
	for _index in range(frames):
		_ambient_phase += 1.0 / _generator.mix_rate
		var night_wave := (sin(TAU * 54.0 * _ambient_phase) + sin(TAU * 83.0 * _ambient_phase)) * 0.002 if is_night else 0.0
		var crackle := sin(TAU * (190.0 + 75.0 * sin(_ambient_phase * 7.0)) * _ambient_phase) * 0.0035 if fire_active else 0.0
		_playback.push_frame(Vector2(night_wave + crackle, night_wave + crackle))

func cue(cue_name: String) -> void:
	if _playback == null or not CUES.has(cue_name):
		return
	var definition: Array = CUES[cue_name]
	var frequency := float(definition[0])
	var duration := float(definition[1])
	var frames := int(_generator.mix_rate * duration)
	for index in range(frames):
		var envelope := 1.0 - float(index) / float(frames)
		var sample := sin(TAU * frequency * float(index) / _generator.mix_rate) * 0.12 * envelope
		_playback.push_frame(Vector2(sample, sample))

func apply_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(linear, 0.001, 1.0)))

func _exit_tree() -> void:
	if _player:
		_player.stop()
		_player.stream = null
	_playback = null
	_generator = null
