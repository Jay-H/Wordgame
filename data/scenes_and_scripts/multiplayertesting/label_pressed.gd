extends Label

signal pressed

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			print("pressed")
			pressed.emit()
