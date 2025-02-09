@tool
extends Path3D

@export var y_offset: float = 0.0
@export_tool_button("Ground Path Points") var ground_path_action = ground_path
@export var length: float:
	get:
		return curve.get_baked_length() if curve else 0.0
@export var ring_fuel: float:
	get:
		return length / 1.25

func ground_path():
	if not is_inside_tree():
		return
	for p in range(curve.point_count):
		var p_pos_ground = ground_rel(curve.get_point_position(p))
		curve.set_point_position(p, p_pos_ground + Vector3.UP * y_offset)
		curve.set_point_in(p, ground_rel(curve.get_point_in(p) + p_pos_ground) - p_pos_ground)
		curve.set_point_out(p, ground_rel(curve.get_point_out(p) + p_pos_ground) - p_pos_ground)

func ground_rel(rel_pos: Vector3) -> Vector3:
	return ground(transform * rel_pos) * transform

# ground between [-0.1, 32.0] of y pos
func ground(pos: Vector3) -> Vector3:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 0.1, pos + Vector3.DOWN * 32.0, 0b1_0001)
	var result = space_state.intersect_ray(query)
	return result.position if result else pos * Vector3(1, 0, 1)
