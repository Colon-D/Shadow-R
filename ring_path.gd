extends Path3D

@export var ring: PackedScene
@export var distance: float = 2.0

func _ready() -> void:
	for x in range(0, curve.get_baked_length(), distance):
		var instance = ring.instantiate()
		add_child(instance)
		instance.position = curve.sample_baked(x)
