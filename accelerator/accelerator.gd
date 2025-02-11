extends Area3D

@export var path: Path3D
@export var accelerator_speed_mult := 1.0

func _on_body_entered(body: Node3D) -> void:
	body.accelerator(path, accelerator_speed_mult)
