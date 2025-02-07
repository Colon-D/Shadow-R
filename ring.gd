extends Node

func _on_body_entered(body: Node3D) -> void:
	body.collect_ring()
	queue_free()
