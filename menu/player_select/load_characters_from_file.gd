extends Node

@export var save_file : Node
@export var player_select : Node

@export var rr_trophy: TextureRect
@export var rr_coin: TextureRect
@export var rj_trophy: TextureRect
@export var rj_coin: TextureRect
@export var rl_trophy: TextureRect
@export var rl_coin: TextureRect

func _ready():
	# magic numbers weeeee!
	if save_file.json["Courses Won"]["Rubble Route"]:
		rr_trophy.visible = true
	if save_file.json["Courses Won"]["RAM Jam"]:
		rj_trophy.visible = true
	if save_file.json["Courses Won"]["Remote Lab"]:
		rl_trophy.visible = true
	if save_file.json["Characters Unlocked"]["Doom's Eye"]:
		player_select.characters[4][2] = true
	if save_file.json["Characters Unlocked"]["Fake Metal Shadow"]:
		player_select.characters[5][2] = true
		rr_coin.visible = true
	if save_file.json["Characters Unlocked"]["Fake Metal Rouge"]:
		player_select.characters[6][2] = true
		rj_coin.visible = true
	if save_file.json["Characters Unlocked"]["Fake Metal Omega"]:
		player_select.characters[7][2] = true
		rl_coin.visible = true
