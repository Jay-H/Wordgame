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
		
func _took_too_long_text():
	self.placeholder_text = "Took too long!"
	await get_tree().create_timer(0.75).timeout
	self.placeholder_text = "Opponent's Turn"
