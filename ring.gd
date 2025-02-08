extends Node3D

@export var hitbox: CollisionShape3D
@export var respawn: Timer

func _on_body_entered(body: Node3D) -> void:
	body.collect_ring()
	hide()
	hitbox.disabled = true
	respawn.start()

func _on_timer_timeout() -> void:
	show()
	hitbox.disabled = false
