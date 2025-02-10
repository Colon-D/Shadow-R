extends TextureRect

@export var player_icon: TextureRect
@export var player: Node3D

@export var xform_translate: Vector2
@export var xform_rotate_degrees: float
@export var xform_scale := Vector2.ONE

func _physics_process(_delta: float) -> void:
	if not player:
		return
	var xform = Transform2D(deg_to_rad(xform_rotate_degrees), xform_scale, 0, xform_translate)
	var player_xz = Vector2(player.position.x, player.position.z)
	var player_pos = xform * player_xz
	player_icon.position = player_pos
