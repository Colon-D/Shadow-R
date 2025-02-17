extends Node

@export var skip := false
@export var players : Array[Node]
@export var music_player : AudioStreamPlayer
@export var music : AudioStream
@export var end_music : AudioStream
@export var ready_timer : Timer
@export var set_timer : Timer
@export var go_timer : Timer
@export var post_go_timer : Timer
@export var end_timer : Timer

@export var ui_ready : Control
@export var ui_set : Control
@export var ui_go : Control
@export var ui_end : Control

func _ready():
	if not skip:
		ready_timer.start()
		set_timer.start()
		go_timer.start()
		post_go_timer.start()
		music_player.play()
		for player in players:
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
	for player in players:
		player.process_mode = PROCESS_MODE_INHERIT

func post_go_timeout() -> void:
	ui_go.hide()
	music_player.stream = music
	music_player.play()

func main_player_end() -> void:
	end_timer.start()
	ui_end.show()
	music_player.stream = end_music
	music_player.play()

func end_timeout() -> void:
	get_tree().change_scene_to_file("res://menu/menu.tscn")
