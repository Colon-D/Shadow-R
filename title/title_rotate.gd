extends Node3D

var look_at_me = Vector3.FORWARD
var elapsed = 1337

func _physics_process(delta):
	elapsed += delta
	# I feel like this points down more often than up... hence +-0.5
	look_at_me.y = -0.5 + sin((1.5 + cos(elapsed * 1.9314))) * 0.5 + sin(elapsed * 1.5321) / 3.0
	look_at_me.x = cos((1.5 + sin(elapsed * 1.7413))) * 0.5 + cos(elapsed * 1.3123) / 3.0
	look_at(global_position + look_at_me, Vector3.UP)
