extends LineEdit

signal pressed

func _gui_input(event):
	if event is InputEventKey:

		if event.is_action_pressed("enter"):
			var word = self.text.to_upper()
			text = ""
			print("pressed")
			pressed.emit(word)
		if event.is_action_pressed("backspace"):
			text = ""
		
