extends Node3D

func _input(event):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("pause"):
		get_tree().change_scene_to_file("res://menu/menu.tscn")