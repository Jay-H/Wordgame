extends Timer
signal timer_done

func _on_timeout() -> void:
	timer_done.emit()
	pass # Replace with function body.
