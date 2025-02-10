extends Node

@export var animation_name: String = "loop"

func _ready():
	$AnimationPlayer.play(animation_name)
