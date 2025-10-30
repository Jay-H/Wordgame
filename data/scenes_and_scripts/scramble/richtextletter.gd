extends RichTextLabel

signal pressed

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			print(text)
			pressed.emit(self.text, self, true)
			# Add your custom logc here
