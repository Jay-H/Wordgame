extends TextureRect

signal pressed 

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			pressed.emit(texture)
			
