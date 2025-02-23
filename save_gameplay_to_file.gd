extends Node

@export var save_file : Node
@export var gameplay : Node

@export var course_name : String
@export var unlockable_character_name : String

func _on_race_end():
	if gameplay.main_player.place == 0:
		save_file.json["Courses Won"][course_name] = true
		if save_file.json["Courses Won"]["Rubble Route"]\
			and save_file.json["Courses Won"]["RAM Jam"]\
			and save_file.json["Courses Won"]["Remote Lab"]\
		:
			save_file.json["Characters Unlocked"]["Doom's Eye"] = true
		if gameplay.coins >= 5:
			save_file.json["Characters Unlocked"][unlockable_character_name] = true
