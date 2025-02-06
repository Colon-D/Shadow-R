extends Camera3D

@export var player: Node3D

func _physics_process(delta: float) -> void:
	# target position is 5 units behind the player, 2.5 units up
	var forwards := player.basis.z
	forwards.y /= 4.0 # reduce the height a bit
	var target_position := player.position - forwards * 5
	target_position.y += 2.5

	position = position.lerp(target_position, 10.0 * delta)

	# target look at is 1 units in front of the player, 2.5 units up
	var target_look_at := player.position + player.basis.z * 1
	target_look_at.y += 2.5

	var target_dir := position.direction_to(target_look_at)
	var current_dir := -basis.z
	var new_dir := current_dir.slerp(target_dir, 5.0 * delta)
	look_at(position + new_dir, Vector3.UP)
