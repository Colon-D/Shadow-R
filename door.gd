extends Node

@export var price := 20
@export var door_sfx: AudioStream

signal door_opened()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.rings >= price:
		body.rings = max(0, body.rings - price)
		body.audio.stream = door_sfx
		body.audio.pitch_scale = 1.0
		body.audio.play()
		door_opened.emit()
		queue_free()
