extends CharacterBody3D

# THIS FILE IS A BIG MESS AND COULD BE SIMPLIFIED A LOT.
# RIGHT NOW THIS IS FEATURE CREEP OF ME TRYING TO MAKE IT MORE LIKE SONIC R.
# IDEALLY THIS SHOULD MAYBE BE SPLIT INTO MULTIPLE FILES OR AT LEAST FUNCTIONS.
# OR MAYBE I SHOULD ACTUALLY DO MATH INSTEAD OF TRIAL AND ERRORING UNTIL THINGS
# FEEL RIGHT.
# why am I in all caps? I'm tired.

const ACCEL := 21.0
const FLEET_FEET_ACCEL_MULT := 1.33 # I don't know what fleet feet actually does
var fleet_feet_timer := 0.0
const MAX_FLEET_FEET_TIME := 8.0
const DECEL := 0.75
const DECEL_LIN := 4.0
const TURN := 0.55 # seems slow but that's what I calculated
const BRAKE := 0.35 # turn speed too for l or r brake
const FAST_BRAKE_MULT := 4.0 # multiplier for DECEL and DECEL_LIN
const ROLLING_MULT := 0.25 # multiplier for TURN and BRAKE whilst rolling
const MOVING_MULT := 3.0 # multiplier for TURN whilst moving
const MOVING_MULT_BRAKE := 2.0 # multiplier for BRAKE whilst moving
const SWIM_MULT := 2.5 # multiplier for DECEL AND DECEL_LIN whilst swimming
const JUMP_MULT := 0.5 # multiplier for TURN AND BRAKE whilst jumping
const JUMP_VELOCITY := 9.0
const DOUBLE_JUMP_VELOCITY := 12.0
var double_jumping := false
var extend_jump := true # true until you let go of jump after jumping
const JUMP_GRAV_MULT := 3.0 # when going up and not holding jump
const MAX_JUMPS := 2
const ROT_SPEED := 4.5
const GRAVITY_AIR_MULT := 2.4 # multiplier when no kayote frames (we want less gravity on ground to make going uphill easier?)
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
@export var shield_mesh: MeshInstance3D
@export var water_shield_texture: Texture2D
@export var lightning_shield_texture: Texture2D
@export var ring_hitbox: CollisionShape3D
const RING_RADIUS := 0.5
const RING_RADIUS_LIGHTNING := 5.0

var kayote_time := 0.0
const MAX_KAYOTE_TIME := 0.1

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
var accelerator_speed_mult := 1.0
@export var accelerator_sfx: AudioStream

# [0, 4] -> 1st to 5th
var place := 0

signal end()

enum Shield { NONE, WATER, LIGHTNING }
@onready var shield := Shield.NONE:
	set(value):
		shield = value
		ring_hitbox.shape.radius = RING_RADIUS
		if shield == Shield.NONE:
			shield_mesh.hide()
		else:
			shield_mesh.show()
			var shield_texture := water_shield_texture if value == Shield.WATER else lightning_shield_texture
			var material := shield_mesh.mesh.surface_get_material(0) as ShaderMaterial
			material.set_shader_parameter("texture_albedo", shield_texture)
			lightning_shield_countdown = 0.0
			water_shield_triggered = 0.0
			if shield == Shield.LIGHTNING:
				lightning_shield_countdown = LIGHTNING_SHIELD_TIME
				ring_hitbox.shape.radius = RING_RADIUS_LIGHTNING
var water_shield_triggered := 0.0
const WATER_SHIELD_LENIENCY := 0.1
var lightning_shield_countdown := 0.0
const LIGHTNING_SHIELD_TIME := 30.0
var item_panel_cooldown := 0.0

signal set_cpu(value: bool)
@export var cpu := false:
	set(value):
		cpu = value
		set_cpu.emit(value)
@export var cpu_path: Path3D
@export var cpu_debug: Node3D

func collect_ring():
	rings += 1
	audio.stream = ring_sfx
	audio.pitch_scale = 1.0
	audio.play()

func accelerator(new_accelerator_path: Path3D, new_accelerator_speed_mult := 1.0):
	var rings_taken: int = min(50, rings)
	accelerator_fuel = rings_taken * 1.25
	if accelerator_fuel <= 0:
		return
	accelerator_path = new_accelerator_path
	accelerator_progress = 0.0
	accelerator_speed_mult = new_accelerator_speed_mult
	rings -= rings_taken
	state = State.ACCELERATOR
	audio.stream = accelerator_sfx
	audio.pitch_scale = 1.0
	audio.play()

func _physics_process(delta: float) -> void:
	item_panel_cooldown -= delta

	# I'm just calling this every frame now because there is a bug that
	# seems to not call it when it should be called.
	if shield == Shield.LIGHTNING:
		ring_hitbox.shape.radius = RING_RADIUS_LIGHTNING
	else:
		ring_hitbox.shape.radius = RING_RADIUS

	var vel_mag := velocity.length()
	var moving := vel_mag > 1

	if state == State.ACCELERATOR:
		vel_mag = 40.0 * accelerator_speed_mult
		accelerator_progress += delta * vel_mag
		var trans = accelerator_path.transform * accelerator_path.curve.sample_baked_with_rotation(accelerator_progress, true)
		position = trans.origin
		look_at(position + trans.basis.z)
		if accelerator_progress >= accelerator_fuel:
			velocity = -trans.basis.z * 28.0 * accelerator_speed_mult
			state = State.NORMAL
			audio.stop()

	else:
		var in_jump       := false
		var in_just_jump  := false
		var in_l_brake    := false
		var in_r_brake    := false
		var in_accel      := 0.0
		var in_just_accel := false
		var in_duck       := false
		var in_x          := 0.0
		var in_brake_x    := 0.0

		if cpu:
			var cpu_curve := cpu_path.curve
			var cpu_offset := cpu_curve.get_closest_offset(position * cpu_path.transform)
			# aim towards a little further
			var target_pos := cpu_path.transform * cpu_curve.sample_baked(cpu_offset + 0.5 + vel_mag / 1.75)
			cpu_debug.global_position = target_pos
			var target_angle := (basis.z).signed_angle_to(target_pos - position, Vector3.UP)
			in_x = 0.0
			in_brake_x = 0.0
			if target_angle > 0.075:
				in_x = -1.0
				if target_angle > 0.2:
					in_brake_x = -1.0
			elif target_angle < -0.075:
				in_x = 1.0
				if target_angle < 0.2:
					in_brake_x = 1.0
			in_accel = max(1.0 * (((PI / 2) - abs(target_angle)) / (PI / 2)), 0.5)
			in_l_brake = (abs(target_angle) > PI / 2) and vel_mag > 20
			in_r_brake = in_l_brake
		else:
			in_jump       = Input.is_action_pressed("jump")
			in_just_jump  = Input.is_action_just_pressed("jump")
			in_l_brake    = Input.is_action_pressed("left_brake")
			in_r_brake    = Input.is_action_pressed("right_brake")
			in_accel      = Input.get_action_strength("accel")
			in_just_accel = Input.is_action_just_pressed("accel")
			in_duck       = Input.is_action_pressed("duck")
			in_x          = Input.get_axis("turn_left", "turn_right")
			in_brake_x    = Input.get_axis("left_brake", "right_brake")
		
			# normalise in_x and accel
			# (I know that the player should be allow to 100% accel and 100% turn
			#  at the same time, but using the analog stick for accel and turn is
			#  the most intuitive way to play, and it would be unfair to allow
			#  using buttons/keys to be better than using a stick)
			# CPU is allowed to cheat because they suck ass, and because they
			# fall in the water and get stuck now when I change this. They are
			# volatile little creatures
			var analog_vec := Vector2(in_x, in_accel).limit_length(1.0)
			in_x = analog_vec.x
			in_accel = analog_vec.y

		if shield == Shield.LIGHTNING:
			lightning_shield_countdown -= delta
			if lightning_shield_countdown <= 0:
				shield = Shield.NONE

		var on_floor := is_on_floor()
		if on_floor:
			jumps = 0
			double_jumping = false
			extend_jump = true
			kayote_time = MAX_KAYOTE_TIME
			set_new_up_direction(get_floor_normal())
			if state == State.JUMP or state == State.SWIM:
				state = State.NORMAL
			if water_shield_triggered > WATER_SHIELD_LENIENCY:
				shield = Shield.NONE
		else:
			kayote_time -= delta
			# check if swimming
			if position.y < 0:
				position.y = -0.001 # don't want to unswim yet
				velocity.y = 0
				jumps = 0
				if (shield == Shield.WATER):
					water_shield_triggered += delta
					# WET principle in action: from on_floor above
					double_jumping = false
					extend_jump = true
					kayote_time = MAX_KAYOTE_TIME
					set_new_up_direction(Vector3.UP)
					if state == State.JUMP or state == State.SWIM:
						state = State.NORMAL
				else:
					if (shield == Shield.LIGHTNING):
						shield = Shield.NONE
					if state != State.SWIM:
						anim_player.stop()
						audio.stream = splash_sfx
						audio.pitch_scale = 1.0
						audio.play()
						state = State.SWIM
			# otherwise, if no kayote frames, we are jumping/falling
			else:
				if water_shield_triggered > WATER_SHIELD_LENIENCY:
					shield = Shield.NONE
				var gravity = get_gravity()
				if (kayote_time <= 0):
					gravity *= GRAVITY_AIR_MULT
				# variable jump height (unless double jumping)
				if velocity.y > 0:
					if (not in_jump) and not double_jumping:
						extend_jump = false
						gravity *= JUMP_GRAV_MULT
				velocity += gravity * delta

		# jump
		if state != State.SPINDASH and state != State.SWIM:
			if in_just_jump:
				var jump = false
				var up = basis.y
				if kayote_time > 0 and (up.y > 0.05):
					jumps = MAX_JUMPS
					jump = true
				elif jumps > 0:
					jump = true
				if jump:
					jumps -= 1
					if jumps == 0:
						velocity.y = DOUBLE_JUMP_VELOCITY
						double_jumping = true
					else:
						velocity.y = JUMP_VELOCITY
					audio.stream = jump_sfx
					audio.pitch_scale = lerp(1.1, 1.0, jumps / float(MAX_JUMPS - 1))
					audio.play()
					on_floor = false
					state = State.JUMP

		# drag (RANDOM MATH! GOOO!)
		var fast_brake := in_l_brake and in_r_brake
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
		var forwards_dot := 0.5 + velocity.normalized().dot(basis.z) / 2.0
		var forwards_dot_mult := 4.0 - 3.0 * forwards_dot
		decel *= forwards_dot_mult
		decel_lin *= forwards_dot_mult
		var zero_xz := Vector3(0, velocity.y, 0)
		velocity = lerp(velocity, zero_xz, decel * delta) # exponential
		velocity = velocity.move_toward(zero_xz, decel_lin * delta) # linear

		# pressing back shouldn't make up move back nor decelerate
		fleet_feet_timer -= delta
		if state != State.SPINDASH:
			var forwards_input := maxf(in_accel, 0)
			var accel := ACCEL
			if fleet_feet_timer > 0:
				accel *= FLEET_FEET_ACCEL_MULT
			var forwards_accel := basis.z * forwards_input * accel
			velocity += forwards_accel * delta

		# roll
		if state == State.ROLL:
			if on_floor and not moving:
				state = State.NORMAL
		else:
			if on_floor and moving and in_duck:
				state = State.ROLL
				audio.stream = roll_sfx
				audio.pitch_scale = 1.0
				audio.play()

		# spindash
		if state == State.SPINDASH:
			if in_just_accel:
				spindash_charge = lerp(spindash_charge, 30.0, 0.15)
				audio.stream = spin_sfx
				audio.pitch_scale = 1.0
				audio.play()
			if not in_duck:
				velocity = basis.z * spindash_charge
				state = State.ROLL
				audio.stream = spin_go_sfx
				audio.pitch_scale = 1.0
				audio.play()
		else:
			if on_floor and not moving and in_duck:
				state = State.SPINDASH
				spindash_charge = 0

		# rotate with input
		var rotate_vel := TURN
		if state == State.ROLL:
			rotate_vel *= ROLLING_MULT
		elif state == State.JUMP:
			rotate_vel *= JUMP_MULT
		else:
			var move_mult_factor = lerp(1.0, MOVING_MULT, min(vel_mag / 35.0, 1.0))
			rotate_vel *= move_mult_factor
		var input_dir := in_x
		var rotate_by = -input_dir * delta * rotate_vel
		rotate_y(rotate_by)
		velocity = velocity.rotated(Vector3.UP, rotate_by * 0.75) # maybe og game has this?

		# left/right brake (similar to rotate, but slower + applying velocity?)
		# (maybe combine with above?)
		# (this is barely any different now that above rotates velocity too)
		if state != State.SWIM:
			var brake_input := in_brake_x
			var brake_vel := BRAKE
			if state == State.ROLL:
				brake_vel *= ROLLING_MULT
			elif state == State.JUMP:
				brake_vel *= JUMP_MULT
			else:
				var move_mult_factor_brake = lerp(1.0, MOVING_MULT_BRAKE, min(vel_mag / 35.0, 1.0))
				brake_vel *= move_mult_factor_brake
			rotate_by = -brake_input * delta * brake_vel
			rotate_y(rotate_by)
			velocity = velocity.rotated(Vector3.UP, rotate_by)
			# rotate model with brakes
			var target_roll := brake_input * 0.025 * vel_mag
			model.rotation.z = lerp(model.rotation.z, target_roll, 4.0 * delta)

		# rotate along ground (janky!!)
		var old_up_direction := basis.y
		if on_floor or kayote_time <= 0:
			var new_target_up_direction := get_floor_normal() if on_floor else Vector3.UP
			# stop jittering at slight angles
			if new_target_up_direction.y > 0.99:
				new_target_up_direction = Vector3.UP
			var orig_angle := old_up_direction.angle_to(new_target_up_direction)
			# too sharp, consider wall
			if orig_angle > PI / 4:
				new_target_up_direction = Vector3.UP
			var new_up_direction := old_up_direction.move_toward(
				new_target_up_direction, ROT_SPEED * delta
			).normalized()
			set_new_up_direction(new_up_direction)

		var collided := move_and_slide()
		if collided:
			# bounce off of wall (doesn't work too well anymore)
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
		if state != State.NORMAL:
			anim_player.play("jump")
			if state == State.JUMP || State.ACCELERATOR:
				anim_player.speed_scale = 2
			elif state == State.ROLL:
				anim_player.speed_scale = vel_mag * 0.33
			elif state == State.SPINDASH:
				anim_player.speed_scale = spindash_charge * 0.33
		else:
			if moving:
					anim_player.play("run")
					anim_player.speed_scale = vel_mag * 0.33
			else:
				anim_player.play("idle")
				anim_player.speed_scale = 1

	# calculate how far along path we are
	if path != null and path.curve != null:
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
			lap += 1
			# fake further distance to make sorting easier
			total_progress += (4 - place) * 1000
			# stop processing
			process_mode = PROCESS_MODE_DISABLED
			# main player will end game
			end.emit()

	# laps
	if (lap < 3):
		lap_time[lap] += delta

func set_new_up_direction(new_up_direction: Vector3) -> void:
	var old_up_direction := basis.y
	if not old_up_direction.is_equal_approx(new_up_direction):
		# calculate the rotation between the old and new up direction
		var rotate_along := old_up_direction.cross(new_up_direction).normalized()
		var by_angle := old_up_direction.angle_to(new_up_direction)
		# rotate the velocity?
		velocity = velocity.rotated(rotate_along, by_angle)
		# rotate this object's angle
		rotate(rotate_along, by_angle)
		up_direction = new_up_direction
