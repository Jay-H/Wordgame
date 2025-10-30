extends Button


func _on_pressed() -> void:
	
	CSignals.buttonPressed.emit()
	print("hi")
	pass # Replace with function body.
