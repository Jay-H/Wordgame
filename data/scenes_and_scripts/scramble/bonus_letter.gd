extends Label




func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		CSignals.bonus_clicked.emit(text)
	pass # Replace with function body.
