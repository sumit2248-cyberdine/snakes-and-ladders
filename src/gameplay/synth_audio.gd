class_name SnakesSynthAudio
extends Node
## Tiny procedural beep synth on the SFX bus. No audio assets needed.

var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)


func _tone(freq: float, dur: float = 0.12, vol: float = 0.5, slide_to: float = 0.0) -> void:
	var rate := 22050
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t: float = float(i) / float(rate)
		var f: float = freq if slide_to <= 0.0 else lerpf(freq, slide_to, t / dur)
		phase += TAU * f / float(rate)
		var env: float = 1.0 - (float(i) / float(n))
		var s: float = sin(phase) * env * vol
		var v := int(clampf(s, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.play()


func play_dice() -> void:
	_tone(330.0, 0.1, 0.4, 180.0)


func play_hop() -> void:
	_tone(520.0 + randf() * 120.0, 0.07, 0.35)


func play_slide() -> void:
	_tone(700.0, 0.35, 0.45, 150.0)


func play_climb() -> void:
	_tone(220.0, 0.35, 0.45, 660.0)


func play_turn() -> void:
	_tone(440.0, 0.09, 0.35)


func play_win() -> void:
	_tone(523.0, 0.16, 0.5)
	var timer := get_tree().create_timer(0.14)
	timer.timeout.connect(func() -> void: _tone(659.0, 0.16, 0.5))
	var timer2 := get_tree().create_timer(0.28)
	timer2.timeout.connect(func() -> void: _tone(784.0, 0.3, 0.5))
