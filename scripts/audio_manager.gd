extends Node

# Audio Manager - handles all game sounds and music
# This is an autoload singleton

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var MAX_SFX_PLAYERS = 8

# Volume settings
var music_volume: float = 0.5
var sfx_volume: float = 0.75

# Preloaded sounds
var sounds: Dictionary = {}

func _ready():
	# Create music player
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

	# Create pool of SFX players
	for i in range(MAX_SFX_PLAYERS):
		var player = AudioStreamPlayer.new()
		add_child(player)
		sfx_players.append(player)

	# Load sounds
	load_sounds()

func load_sounds():
	var sound_files = {
		"move": "res://assets/sounds/move.wav",
		"capture": "res://assets/sounds/slash.mp3",
		"check": "res://assets/sounds/check.wav",
		"click": "res://assets/sounds/click.mp3",
		"hover": "res://assets/sounds/hoverclick.wav",
		"typewriter": "res://assets/sounds/typesound.wav"
	}

	for key in sound_files:
		var path = sound_files[key]
		if ResourceLoader.exists(path):
			sounds[key] = load(path)

func play_music(stream: AudioStream, fade_in: float = 1.0):
	if music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80, 0.5)
		await tween.finished

	music_player.stream = stream
	music_player.volume_db = -80
	music_player.play()

	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), fade_in)

func stop_music(fade_out: float = 1.0):
	if music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80, fade_out)
		await tween.finished
		music_player.stop()

func play_sound(sound_name: String, volume_scale: float = 1.0):
	if not sounds.has(sound_name):
		return

	# Find available player
	for player in sfx_players:
		if not player.playing:
			player.stream = sounds[sound_name]
			player.volume_db = linear_to_db(sfx_volume * volume_scale)
			player.play()
			return

	# If all players busy, use first one
	sfx_players[0].stream = sounds[sound_name]
	sfx_players[0].volume_db = linear_to_db(sfx_volume * volume_scale)
	sfx_players[0].play()

func play_move_sound():
	play_sound("move")

func play_capture_sound():
	play_sound("capture")

func play_check_sound():
	play_sound("check")

func play_click_sound():
	play_sound("click")

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	if music_player.playing:
		music_player.volume_db = linear_to_db(music_volume)

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
