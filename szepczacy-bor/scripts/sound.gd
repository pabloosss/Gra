extends Node

var started = false
var music: AudioStreamPlayer
var forest: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var samples = {}
var cursor = 0

func _ready():
	for bus_name in ["Muzyka","Efekty"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count-1,bus_name)
	for id in ["chop_0","chop_1","chop_2","fell","coins","build","upgrade","whisper","win"]:
		samples[id] = load("res://assets/"+id+".wav")
	music = make_loop("ambient_music","Muzyka")
	forest = make_loop("forest_ambience","Efekty")
	for i in range(12):
		var player = AudioStreamPlayer.new()
		player.bus = "Efekty"
		add_child(player)
		voices.append(player)
	apply_settings()

func make_loop(id: String, bus_name: String) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	var stream = load("res://assets/"+id+".wav").duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length()*stream.mix_rate)
	player.stream = stream
	player.bus = bus_name
	add_child(player)
	return player

func begin():
	if started: return
	started = true
	music.play()
	forest.play()

func play(id: String, pitch: float = 1.0):
	if not started or not samples.has(id): return
	var player = voices[cursor]
	cursor = (cursor+1)%voices.size()
	player.stream = samples[id]
	player.pitch_scale = pitch
	player.play()

func apply_settings():
	var m = AudioServer.get_bus_index("Muzyka")
	var e = AudioServer.get_bus_index("Efekty")
	if m < 0 or e < 0: return
	AudioServer.set_bus_volume_db(m,linear_to_db(maxf(0.0001,State.music_volume)))
	AudioServer.set_bus_volume_db(e,linear_to_db(maxf(0.0001,State.effects_volume)))
	AudioServer.set_bus_mute(m,State.music_muted or State.music_volume<=0)
	AudioServer.set_bus_mute(e,State.effects_muted or State.effects_volume<=0)

func _exit_tree():
	for player in voices:
		player.stop()
		player.stream=null
	if is_instance_valid(music):
		music.stop()
		music.stream=null
	if is_instance_valid(forest):
		forest.stop()
		forest.stream=null
	voices.clear()
	samples.clear()
