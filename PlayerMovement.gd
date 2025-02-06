extends CharacterBody3D

const ACCEL = 15.0
const DECEL = 0.5
const DECEL_LIN = 2.0
const TURN = 1.667
const BREAK = 0.8
const JUMP_VELOCITY = 10.0
const MAX_JUMPS = 2
const ROT_SPEED = 4.5
var jumps = 0
@export var audio: AudioStreamPlayer3D
@export var jump_sfx: AudioStream # todo: should be part of animation?
@export var path: Path3D

@export var anim_player: AnimationPlayer

func _physics_process(delta: float) -> void:
	if is_on_floor():
		jumps = 0
	else:
		# gravity
		velocity += get_gravity() * delta

	# jump
	var aim := transform.basis
	if Input.is_action_just_pressed("jump"):
		var jump = false
		var up = aim.y
		if is_on_floor() and (up.y > 0.05):
			jumps = MAX_JUMPS
			jump = true
		elif jumps > 0:
			jump = true
		if jump:
			jumps -= 1
			velocity.y = JUMP_VELOCITY
			audio.stream = jump_sfx
			audio.pitch_scale = lerp(1.1, 1.0, jumps / float(MAX_JUMPS - 1))
			audio.play()

	# drag
	velocity = lerp(velocity, Vector3.ZERO, DECEL * delta) # exponential
	velocity = velocity.move_toward(Vector3.ZERO, DECEL_LIN * delta) # linear

	# default strafe movement
	#var current_yaw := get_rotation_degrees().y

	var input_dir := Input.get_vector("turn_left", "turn_right", "move_backwards", "move_forwards")
	var forwards_accel := aim * Vector3(0, 0, input_dir.y) * ACCEL
	velocity.x += forwards_accel.x * delta
	velocity.z += forwards_accel.z * delta

	# rotate with input
	rotate_y(-input_dir.x * delta * TURN)

	# left/right brake (similar to rotate, but slower + applying velocity?)
	var brake_input := Input.get_axis("left_brake", "right_brake")
	var rotate_by = brake_input * delta * BREAK
	rotate_y(-rotate_by)
	velocity = velocity.rotated(Vector3.UP, -rotate_by)

	# rotate along ground (janky)
	var old_up_direction := aim.y
	var new_target_up_direction := get_floor_normal() if is_on_floor() else Vector3.UP
	if not old_up_direction.is_equal_approx(new_target_up_direction):
		var new_up_direction := old_up_direction.move_toward(new_target_up_direction, ROT_SPEED * delta).normalized()
		# calculate the rotation between the old and new up direction
		var rotate_along := old_up_direction.cross(new_up_direction).normalized()
		var by_angle := old_up_direction.angle_to(new_up_direction)
		#if by_angle < PI / 4:
		# rotate the velocity?
		velocity = velocity.rotated(rotate_along, by_angle)
		# rotate this models angle
		rotate(rotate_along, by_angle)
		up_direction = new_up_direction

	move_and_slide()

	# if we have velocity, update animation
	var magnitude := velocity.length()
	if magnitude > 0.1:
		anim_player.play("Armature|run")
		# change speed
		anim_player.speed_scale = magnitude * 0.33
	else:
		anim_player.play("Armature|idle")

	# calculate how far along path we are
	var curve := path.curve
	print(100.0 * curve.get_closest_offset(position) / curve.get_baked_length(), "%")
