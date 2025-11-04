extends Button


signal pressed2 

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			pressed.emit(self)
			
		
