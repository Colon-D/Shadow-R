extends AnimatedSprite3D

@export var nights_upper: Node3D

func _physics_process(_delta):
	look_at(nights_upper.global_position, Vector3.UP)
	var delta_pos = nights_upper.global_position - global_position
	global_position = (nights_upper.global_position - delta_pos).limit_length(1.0)
