extends Node

var json = {
	"Characters Unlocked" : {
		"Doom's Eye" : false,
		"Fake Metal Shadow" : false,
		"Fake Metal Rouge" : false,
		"Fake Metal Omega" : false,
	},
	"Courses Won" : {
		"Rubble Route" : false,
		"RAM Jam" : false,
		"Remote Lab" : false,
	}
}

func _ready() -> void:
	read()

func _exit_tree() -> void:
	write()

func write():
	var file = FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_line(JSON.stringify((json)))

func read():
	var file = FileAccess.open("user://save.json", FileAccess.READ)
	if file == null:
		return
	json = JSON.parse_string(file.get_as_text())
