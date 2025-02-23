extends Node

# [name, fake_metal, unlocked]
var characters = [
	["Shadow", false, true],
	["Rouge", false, true],
	["Omega", false, true],
	["Zavok", false, true],
	["DoomsEye", false, false],
	["Shadow", true, false],
	["Rouge", true, false],
	["Omega", true, false],
]
var character = 0:
	set(value):
		var old_node = char_to_node(character)
		character = value % characters.size()
		var new_node = char_to_node(character)
		old_node.hide()
		new_node.show()
		set_fake_metal(characters[character][1])

@export var fake_metal_material_overrides: Dictionary[Node, ShaderMaterial]

func _ready():
	return

# WET: copied directly to `gameplay.gd`
func set_fake_metal(enabled: bool):
	for node in fake_metal_material_overrides:
		if enabled:
			var mat = fake_metal_material_overrides[node]
			node.propagate_call("set_surface_override_material", [0, mat])
		else:
			node.propagate_call("set_surface_override_material", [0, null])

func char_to_node(character_index):
	return $Character.get_node(NodePath(characters[character_index][0]))

func _input(event):
	if event.is_action_pressed("ui_left"):
		while true:
			character -= 1
			if characters[character][2]:
				break
	elif event.is_action_pressed("ui_right"):
		while true:
			character += 1
			if characters[character][2]:
				break
	elif event.is_action_pressed("ui_accept"):
		Global.character = characters[character][0]
		Global.fake_metal = characters[character][1]
		get_tree().change_scene_to_file(Global.gameplay_scene)
	elif event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://menu/menu.tscn")
