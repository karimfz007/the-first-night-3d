class_name AudioFeedback
extends Node

var _player: AudioStreamPlayer
var _generator: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback

const CUES := {
	"pickup": [620.0, 0.08],
	"craft": [760.0, 0.14],
	"fail": [145.0, 0.16],
	"impact_wood": [180.0, 0.09],
	"impact_stone": [260.0, 0.08],
	"build": [420.0, 0.12],
	"ignite": [520.0, 0.2],
	"confirm": [680.0, 0.06]
}

func _ready() -> void:
	_generator = AudioStreamGenerator.new()
	_generator.mix_rate = 22050.0
	_generator.buffer_length = 0.5
	_player = AudioStreamPlayer.new()
	_player.stream = _generator
	_player.volume_db = -11.0
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()

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

