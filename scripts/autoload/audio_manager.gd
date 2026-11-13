extends Node

const SFX_VOICE_COUNT: int = 8

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx_voice: int = 0


func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")

	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	add_child(music_player)

	for index in range(SFX_VOICE_COUNT):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % index
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

	Settings.master_volume_changed.connect(_on_master_volume_changed)
	Settings.apply_master_volume()


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return

	AudioServer.add_bus()
	var bus_index: int = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, "Master")


func _on_master_volume_changed(_value: float) -> void:
	Settings.apply_master_volume()


func play_music(stream: AudioStream, fade_in: bool = false) -> void:
	if stream == null:
		return

	music_player.stream = stream
	music_player.play()
	if fade_in:
		music_player.volume_db = -40.0
		create_tween().tween_property(music_player, "volume_db", 0.0, 0.8)


func stop_music() -> void:
	music_player.stop()


func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null or sfx_players.is_empty():
		return

	var player: AudioStreamPlayer = sfx_players[_next_sfx_voice]
	_next_sfx_voice = (_next_sfx_voice + 1) % sfx_players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.play()
