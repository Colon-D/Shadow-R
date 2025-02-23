extends Control

func change_scene(path: String) -> void:
	Global.gameplay_scene = path
	get_tree().change_scene_to_file("res://menu/player_select/player_select.tscn")
