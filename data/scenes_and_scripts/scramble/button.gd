extends Button



func _on_pressed() -> void:
	CSignals.buttonPressed.emit()
	print("hi")
	pass # Replace with function body.


func _on_mouse_entered() -> void:
	print("mouse entered")
	CSignals.buttonPressed.emit()
	pass # Replace with function body.


func _on_toggled(toggled_on: bool) -> void:
	CSignals.buttonPressed.emit()
	print("hi")
	pass # Replace with function body.
