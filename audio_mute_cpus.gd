extends AudioStreamPlayer3D

func set_cpu(enabled: bool) -> void:
	if enabled:
		process_mode = PROCESS_MODE_DISABLED
	else:
		process_mode = PROCESS_MODE_INHERIT
