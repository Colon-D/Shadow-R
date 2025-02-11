extends Node3D

@export var hitbox: CollisionShape3D
@export var respawn: Timer

func _on_area_3d_area_entered(body: Area3D) -> void:
	body.get_parent().collect_ring()
	hide()
	hitbox.disabled = true
	respawn.start()

func _on_timer_timeout() -> void:
	show()
	hitbox.disabled = false
