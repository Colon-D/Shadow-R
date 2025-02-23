extends Node

@export var total_time_ui: Label
@export var lap_time_ui: Array[Label]

@export var rings_ui: Label

@export var players: Array[Node]
@export var place_ui: Label

@export var coins_ui: Label
@export var coin_player : AudioStreamPlayer
@export var get_coin : AudioStream
@export var get_all_coin : AudioStream
var coins := 0:
	set(value):
		coins = value
		coins_ui.text = str(value)
func collect_coin():
	coins += 1
	coin_player.stream = get_coin
	if coins == 5:
		coin_player.stream = get_all_coin
	coin_player.play()

var main_player: Node:
	set(value):
		main_player = value
		set_main_player.emit(value)
		main_player.cpu = false
signal set_main_player(player: Node)

func _ready() -> void:
	main_player = get_node(Global.character)
	set_fake_metal(Global.fake_metal)

# WET: copied almost directly from `player_select.gd`
@export var fake_metal_material_overrides: Dictionary[Node, ShaderMaterial]
func set_fake_metal(enabled: bool):
	if fake_metal_material_overrides.has(main_player):
		if enabled:
			var mat = fake_metal_material_overrides[main_player]
			main_player.get_node("Model").propagate_call("set_surface_override_material", [0, mat])
		else:
			main_player.get_node("Model").propagate_call("set_surface_override_material", [0, null])

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
	if main_player.lap < 3:
		lap_time_ui[main_player.lap].text = format_time(main_player.lap_time[main_player.lap])
	
		var total_time := 0.0
		for i in range(3):
			total_time += main_player.lap_time[i]

		total_time_ui.text = format_time(total_time)

		rings_ui.text = "%03d" % [main_player.rings]

	# sort players by placement
	var sorted_players := players.duplicate()
	sorted_players.sort_custom(sort_by_place)
	for i in range(players.size()):
		var player = sorted_players[i]
		player.place = i

	const suffixes := ["st", "nd", "rd", "th", "th"]
	place_ui.text = str(main_player.place + 1) + suffixes[main_player.place]
	
func sort_by_place(lhs, rhs):
	return lhs.total_progress > rhs.total_progress
