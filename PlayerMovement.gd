extends CharacterBody3D

const ACCEL := 18.0
const DECEL := 0.75
const DECEL_LIN := 4.0
const TURN := 0.55 # seems slow but that's what I calculated
const BRAKE := 0.35 # turn speed too for l or r brake
const FAST_BRAKE_MULT := 4.0 # multiplier for DECEL and DECEL_LIN
const ROLLING_MULT := 0.25 # multiplier for TURN and BRAKE whilst rolling
const MOVING_MULT := 3.5 # multiplier for TURN and BRAKE whilst moving
const SWIM_MULT := 2.5 # multiplier for DECEL AND DECEL_LIN whilst swimming
const JUMP_MULT := 0.5 # multiplier for TURN AND BRAKE whilst jumping
const JUMP_VELOCITY := 10.0
const MAX_JUMPS := 2
const ROT_SPEED := 4.5
var jumps := 0
@export var audio: AudioStreamPlayer3D
@export var jump_sfx: AudioStream # not part of animation as don't want loop
@export var roll_sfx: AudioStream
@export var spin_sfx: AudioStream
@export var spin_go_sfx: AudioStream
@export var splash_sfx: AudioStream
@export var path: Path3D

@export var anim_player: AnimationPlayer
@export var model: Node3D
@export var ripple: AnimatedSprite3D

var kayote_time := 0.0
const MAX_KAYOTE_TIME := 0.2

#var rolling := false # should be a state? alongside and exclusive to jumping?

# mutually exclusive states
enum State { NORMAL, JUMP, SPINDASH, ROLL, ACCELERATOR, SWIM }
var state := State.NORMAL

var spindash_charge := 0.0

var lap_time: Array[float] = [0.0, 0.0, 0.0]
var lap := 0
var total_progress := 0.0

var prev_lap_percent := 0.0

@export var rings := 0
@export var ring_sfx: AudioStream

var accelerator_path: Path3D
var accelerator_fuel := 0.0
var accelerator_progress := 0.0
@export var accelerator_sfx: AudioStream

func collect_ring():
	rings += 1
	audio.stream = ring_sfx
	audio.pitch_scale = 1.0
	audio.play()

func accelerator(new_accelerator_path: Path3D):
	var rings_taken: int = min(50, rings)
	accelerator_fuel = rings_taken * 1.25
	if accelerator_fuel <= 0:
		return
	accelerator_path = new_accelerator_path
	accelerator_progress = 0.0
	rings -= rings_taken
	state = State.ACCELERATOR
	audio.stream = accelerator_sfx
	audio.pitch_scale = 1.0
	audio.play()

func _physics_process(delta: float) -> void:
	var vel_mag := velocity.length()
	var moving := vel_mag > 1
	var aim := transform.basis

	if state == State.ACCELERATOR:
		vel_mag = 32.0
		accelerator_progress += delta * vel_mag
		var trans = accelerator_path.curve.sample_baked_with_rotation(accelerator_progress, true)
		position = accelerator_path.global_position + trans.origin
		look_at(position + trans.basis.z)
		if accelerator_progress >= accelerator_fuel:
			velocity = aim.z * 24.0
			state = State.NORMAL

	else:
		var on_floor := is_on_floor()
		if on_floor:
			jumps = 0
			kayote_time = MAX_KAYOTE_TIME
			if state == State.JUMP or state == State.SWIM:
				state = State.NORMAL
		else:
			kayote_time -= delta
			# check if swimming
			if position.y < 0:
				anim_player.stop()
				jumps = 0
				if state != State.SWIM:
					audio.stream = splash_sfx
					audio.pitch_scale = 1.0
					audio.play()
					state = State.SWIM
				position.y = -0.001 # don't want to unswim yet
				velocity.y = 0
			else:
				# gravity
				velocity += get_gravity() * delta


		# jump
		if state != State.SPINDASH and state != State.SWIM:
			if Input.is_action_just_pressed("jump"):
				var jump = false
				var up = aim.y
				if kayote_time > 0 and (up.y > 0.05):
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
					on_floor = false
					state = State.JUMP

		# drag (RANDOM MATH! GOOO!)
		var fast_brake := Input.is_action_pressed("left_brake")\
			and Input.is_action_pressed("right_brake")
		var decel := DECEL
		var decel_lin := DECEL_LIN
		if fast_brake:
			decel *= FAST_BRAKE_MULT
			decel_lin *= FAST_BRAKE_MULT
		if state == State.SWIM:
			decel *= SWIM_MULT
			decel_lin *= SWIM_MULT
		# I have no clue if game has this but it would make somewhat sense?
		# if it controls like a car, then cars should only move forwards?
		var forwards_dot := 0.5 + velocity.normalized().dot(aim.z) / 2.0
		var forwards_dot_mult := 4.0 - 3.0 * forwards_dot
		decel *= forwards_dot_mult
		decel_lin *= forwards_dot_mult
		var zero_xz := Vector3(0, velocity.y, 0)
		velocity = lerp(velocity, zero_xz, decel * delta) # exponential
		velocity = velocity.move_toward(zero_xz, decel_lin * delta) # linear

		# pressing back shouldn't make up move back nor decelerate
		if state != State.SPINDASH:
			var forwards_input := maxf(Input.get_action_strength("accel"), 0)
			var forwards_accel := aim.z * forwards_input * ACCEL
			velocity += forwards_accel * delta

		# roll
		if state == State.ROLL:
			if on_floor and not moving:
				state = State.NORMAL
		else:
			if on_floor and moving and Input.is_action_pressed("duck"):
				state = State.ROLL
				audio.stream = roll_sfx
				audio.pitch_scale = 1.0
				audio.play()

		# spindash
		if state == State.SPINDASH:
			if Input.is_action_just_pressed("accel"):
				spindash_charge = lerp(spindash_charge, 30.0, 0.15)
				audio.stream = spin_sfx
				audio.pitch_scale = 1.0
				audio.play()
			if not Input.is_action_pressed("duck"):
				velocity = aim.z * spindash_charge
				state = State.ROLL
				audio.stream = spin_go_sfx
				audio.pitch_scale = 1.0
				audio.play()
		else:
			if on_floor and not moving and Input.is_action_pressed("duck"):
				state = State.SPINDASH
				spindash_charge = 0

		# rotate with input
		var rotate_vel := TURN
		var move_mult_factor = lerp(1.0, MOVING_MULT, min(vel_mag / 30.0, 1.0))
		if state == State.ROLL:
			rotate_vel *= ROLLING_MULT
		elif state == State.JUMP:
			rotate_vel *= JUMP_MULT
		else:
			rotate_vel *= move_mult_factor
		var input_dir := Input.get_axis("turn_left", "turn_right")
		var rotate_by = -input_dir * delta * rotate_vel
		rotate_y(rotate_by)
		velocity = velocity.rotated(Vector3.UP, rotate_by * 0.75) # maybe og game has this?

		# left/right brake (similar to rotate, but slower + applying velocity?)
		# (maybe combine with above?)
		# (this is barely any different now that above rotates velocity too)
		if state != State.SWIM:
			var brake_input := Input.get_axis("left_brake", "right_brake")
			var brake_vel := BRAKE
			if state == State.ROLL:
				brake_vel *= ROLLING_MULT
			elif state == State.JUMP:
				brake_vel *= JUMP_MULT
			else:
				brake_vel *= move_mult_factor
			rotate_by = -brake_input * delta * brake_vel
			rotate_y(rotate_by)
			velocity = velocity.rotated(Vector3.UP, rotate_by)
			# rotate model with brakes
			var target_roll := brake_input * 0.035 * vel_mag
			model.rotation.z = lerp(model.rotation.z, target_roll, 8.0 * delta)


		# rotate along ground (janky!!)
		var old_up_direction := aim.y
		var new_target_up_direction := get_floor_normal() if kayote_time > 0 else Vector3.UP
		# stop jittering at slight angles
		if new_target_up_direction.y > 0.975:
			new_target_up_direction = Vector3.UP
		var orig_angle := old_up_direction.angle_to(new_target_up_direction)
		# too sharp, consider wall
		if orig_angle > PI / 4:
			new_target_up_direction = Vector3.UP
		var new_up_direction := old_up_direction.move_toward(
			new_target_up_direction, ROT_SPEED * delta
		).normalized()
		if not old_up_direction.is_equal_approx(new_up_direction):
			# calculate the rotation between the old and new up direction
			var rotate_along := old_up_direction.cross(new_up_direction).normalized()
			var by_angle := old_up_direction.angle_to(new_up_direction)
			#if by_angle < PI / 16:
			# rotate the velocity?
			velocity = velocity.rotated(rotate_along, by_angle)
			# rotate this models angle
			rotate(rotate_along, by_angle)
			up_direction = new_up_direction

		var collided := move_and_slide()
		if collided:
			# bounce off of wall
			var collided_with := get_last_slide_collision()
			var collider: CollisionObject3D = collided_with.get_collider()
			if collider.collision_layer == 1: # regular geometry, not track, bouncy
				# blender importing with "-col" doesn't let me set collision layer...
				# so all collisions will be bouncy. I'm just not bouncing if
				# normal is too ground like.
				var normal = collided_with.get_normal()
				# only bounce off wall shaped walls
				if abs(normal.y) < 0.25:
					# normal.y *= 0.25
					# normal = normal.normalized()
					# if normal.length_squared() > 0.1:
					velocity = velocity.bounce(normal)

	# update animation
	if state == State.SWIM:
		model.hide()
		ripple.show()
		var bubbles := ripple.get_node("Bubbles")
		if not bubbles.is_playing():
			ripple.get_node("Bubbles").play()
	else:
		model.show()
		ripple.hide()
		ripple.get_node("Bubbles").stop()
		if state != State.NORMAL and state != State.ACCELERATOR:
			anim_player.play("Armature|jump")
			if state == State.JUMP:
				anim_player.speed_scale = 2
			elif state == State.ROLL:
				anim_player.speed_scale = vel_mag * 0.33
			elif state == State.SPINDASH:
				anim_player.speed_scale = spindash_charge * 0.33
		else:
			if moving:
					anim_player.play("Armature|run")
					anim_player.speed_scale = vel_mag * 0.33
			else:
				anim_player.play("Armature|idle")
				anim_player.speed_scale = 1

	# calculate how far along path we are
	if path != null:
		var curve := path.curve
		var curve_percent := 100.0 * curve.get_closest_offset(position) / curve.get_baked_length()
		# get the change in progress
		var delta_progress := curve_percent - prev_lap_percent
		if delta_progress < -50: # going forwards from 100% to 0%
			delta_progress += 100
		elif delta_progress > 50: # going backwards from 0% to 100%
			delta_progress -= 100
		prev_lap_percent = curve_percent
		# apply the change in progress
		total_progress += delta_progress

		if lap == 0 and total_progress >= 100:
			lap += 1
		elif lap == 1 and total_progress >= 200:
			lap += 1
		elif lap == 2 and total_progress >= 300:
			# you win!
			pass

	# laps
	lap_time[lap] += delta
