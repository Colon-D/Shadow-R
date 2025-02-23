extends Node

@export var model: Node3D

const SPIN_SPEED := 2.0

signal coin_collected()

func _on_body_entered(player: Node3D) -> void:
	if player.cpu:
		return
	coin_collected.emit()
	queue_free()

func _physics_process(delta):
	model.rotate_y(SPIN_SPEED * delta)
