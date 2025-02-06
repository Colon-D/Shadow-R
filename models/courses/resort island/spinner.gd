extends MeshInstance3D

func _physics_process(delta: float) -> void:
	rotate_y(delta * 32.0)
