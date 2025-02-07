extends Node

@export var total_time_ui: Label
@export var lap_time_ui: Array[Label]

@export var rings_ui: Label

@export var main_player: Node

func format_time(seconds : float) -> String:
		var m = int(seconds / 60)
		var s = fmod(seconds, 60.0)
		# ugly fix to stop the seconds displaying as 60, I think its some
		# floating point error issue
		if s > 59.95:
			s = 0.0
			m += 1
		return "%02d:%05.2f" % [m, s]

func _physics_process(_delta: float) -> void:
	lap_time_ui[main_player.lap].text = format_time(main_player.lap_time[main_player.lap])
	
	var total_time := 0.0
	for i in range(3):
		total_time += main_player.lap_time[i]

	total_time_ui.text = format_time(total_time)

	rings_ui.text = str(main_player.rings)
