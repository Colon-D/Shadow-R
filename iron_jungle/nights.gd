extends PathFollow3D

@export var speed = 20.0

func _physics_process(delta):
	progress += delta * speed
