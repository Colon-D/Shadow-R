extends Camera3D

@export var main_player: Node3D
func set_main_player(player: Node3D):
	main_player = player

func _physics_process(delta: float) -> void:
	# target position is 3 units behind the player, 2 units up
	var forwards := main_player.basis.z
	forwards.y /= 4.0 # reduce the height a bit
	var target_position := main_player.position - forwards * 3
	target_position.y += 2

	position = position.lerp(target_position, 10.0 * delta)

	# target look at is 1 units in front of the player, 1 units up
	var target_look_at := main_player.position + main_player.basis.z * 1
	target_look_at.y += 1

	var target_dir := position.direction_to(target_look_at)
	var current_dir := -basis.z
	var new_dir := current_dir.slerp(target_dir, 5.0 * delta)
	look_at(position + new_dir, Vector3.UP)
