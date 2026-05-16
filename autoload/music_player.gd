# author: (TheBuddyAdrian?)

## This is a default audio player, but a singleton.
## It includes shorthands for some commonly used audio files.
## To play a sound file on it, call play_track with a resource path to a sound file;
## To stop the sound, call play_track(null)

extends AudioStreamPlayer

const MAIN_MENU = preload("res://assets/audio/bgm/main_menu.mp3")
const CHALLENGE_BATTLE_MODE = preload("res://assets/audio/bgm/challenge_battle_mode.mp3")

func _ready() -> void:
	bus = "BGM"


func play_track(audio_stream: AudioStream):
	stop()
	stream = audio_stream
	play()
