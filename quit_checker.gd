extends Node

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().change_scene_to_file("res://quit.tscn")
		DisplayServer.window_set_position(Vector2i(-10000, -10000))
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
