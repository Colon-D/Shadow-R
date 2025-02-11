@tool
extends "res://grounded_path.gd"

@export var ring: PackedScene
@export var distance: float = 2.0:
	set(new_distance):
		distance = new_distance
		create_rings()
@export var children: int:
	get:
		return get_child_count()

# create rings on transform
func _enter_tree() -> void:
	set_notify_transform(true)
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		create_rings()

func create_rings():
	if not is_inside_tree():
		return
	for child in get_children():
		child.queue_free()
	if curve == null:
		return
	for x in Vector3(0.0, curve.get_baked_length() + 0.01, distance):
		var instance = ring.instantiate()
		add_child(instance)
		instance.global_position = transform * curve.sample_baked(x)

func _ready() -> void:
	create_rings()
