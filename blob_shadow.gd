extends Node3D

func _physics_process(delta: float) -> void:
	var space_state = get_world_3d().direct_space_state
	# use global coordinates, not local to node
	position = Vector3.ZERO
	var query = PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.1, global_position + Vector3.DOWN * 4.0, 0b1_0001)
	var result = space_state.intersect_ray(query)
	if result:
		show()
		global_position = result.position + Vector3.UP * 0.04
		# don't give me some warning about vectors being the same...
		if result.normal != Vector3.UP:
			look_at(result.position - result.normal)
		else:
			global_rotation = Vector3(-PI / 2, 0, 0)
	else:
		pass
		hide()
