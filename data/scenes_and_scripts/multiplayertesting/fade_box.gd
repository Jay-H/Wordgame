extends ColorRect

func fade_in():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 1)
	
func fade_out():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 1)
