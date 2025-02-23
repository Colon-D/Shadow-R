extends Node

@export var save_file : Node
@export var player_select : Node

func _ready():
	# magic numbers weeeee!
	if save_file.json["Characters Unlocked"]["Doom's Eye"]:
		player_select.characters[4][2] = true
	if save_file.json["Characters Unlocked"]["Fake Metal Shadow"]:
		player_select.characters[5][2] = true
	if save_file.json["Characters Unlocked"]["Fake Metal Rouge"]:
		player_select.characters[6][2] = true
	if save_file.json["Characters Unlocked"]["Fake Metal Omega"]:
		player_select.characters[7][2] = true
