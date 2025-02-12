extends Camera3D

var elapsed = 0.0
@export var camera_target_out : Node3D
@export var camera_target_in : Node3D

func _physics_process(delta):
	elapsed += delta
	global_transform = lerp(camera_target_out.global_transform, camera_target_in.global_transform, 0.5 - cos(elapsed / 8.0) / 2.0)
	pass
