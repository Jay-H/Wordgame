extends LineEdit

signal pressed

#func _process(_delta):
	#%HangmanTextEntry.text = %HangmanTextEntry.text.to_upper()

func _took_too_long_text():
	self.placeholder_text = "Took too long!"
	await get_tree().create_timer(0.75).timeout
	self.placeholder_text = "Opponent's Turn"
