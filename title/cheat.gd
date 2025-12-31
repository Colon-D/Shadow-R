extends Node

const order = ["accel", "accel", "duck", "duck", "turn_left", "turn_right", "turn_left", "turn_right"]
var progress = 0

@onready var get_all: AudioStreamPlayer = $get_all
@onready var save_file: Node = $".."

func _input(event: InputEvent) -> void:
	if progress >= 8:
		return
	# joystick won't work, i don't care
	# also, pressing wrong button won't do anything, i also don't care
	if event is InputEventKey or event is InputEventJoypadButton:
		if event.pressed:
			if event.is_action(order[progress]):
				progress += 1
				if progress >= 8:
					get_all.play()
					save_file.json = {
						"Characters Unlocked" : {
							"Doom's Eye" : true,
							"Fake Metal Shadow" : true,
							"Fake Metal Rouge" : true,
							"Fake Metal Omega" : true,
						},
						"Courses Won" : {
							"Rubble Route" : true,
							"RAM Jam" : true,
							"Remote Lab" : true,
						}
					}
