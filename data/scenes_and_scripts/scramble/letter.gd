extends Label

signal pressed
signal text_changed
var text_changed_already = false

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			print(text)
			pressed.emit(self.text, self, false)
			# Add your custom logc here

func _process(_delta):
	if text_changed_already == false:
		if text != "7":
			text_changed.emit()
			text_changed_already = true
