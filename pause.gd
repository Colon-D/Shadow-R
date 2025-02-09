extends Control

@export var default_focus: Control

@export var pause_sound: AudioStream
@export var unpause_sound: AudioStream
@export var menu_select_sound: AudioStream
@export var menu_confirm_sound: AudioStream
@export var pause_player: AudioStreamPlayer
@export var menu_player: AudioStreamPlayer

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not get_tree().paused:
		pause()

func focus_entered() -> void:
	menu_player.stream = menu_select_sound
	menu_player.play()

func pause():
	pause_player.stream = pause_sound
	pause_player.play()
	get_tree().paused = true
	show()
	default_focus.grab_focus()

func unpause():
	pause_player.stream = unpause_sound
	pause_player.play()
	menu_player.stream = menu_confirm_sound
	menu_player.play()
	get_tree().paused = false
	hide()

func reload():
	unpause()
	menu_player.stream = menu_confirm_sound
	menu_player.play()
	get_tree().reload_current_scene()

func quit():
	menu_player.stream = menu_confirm_sound
	menu_player.play()
	get_tree().quit()
