extends Node

@export var skip := false
@export var player : Node
@export var music_player : AudioStreamPlayer
@export var music : AudioStream
@export var ready_timer : Timer
@export var set_timer : Timer
@export var go_timer : Timer
@export var post_go_timer : Timer

@export var ui_ready : Control
@export var ui_set : Control
@export var ui_go : Control

func _ready():
	if not skip:
		ready_timer.start()
		set_timer.start()
		go_timer.start()
		post_go_timer.start()
		music_player.play()
		player.process_mode = PROCESS_MODE_DISABLED
	else:
		music_player.stream = music
		music_player.play()

func ready_timeout() -> void:
	ui_ready.show()

func set_timeout() -> void:
	ui_ready.hide()
	ui_set.show()

func go_timeout():
	ui_set.hide()
	ui_go.show()
	player.process_mode = PROCESS_MODE_INHERIT

func post_go_timeout() -> void:
	ui_go.hide()
	music_player.stream = music
	music_player.play()
