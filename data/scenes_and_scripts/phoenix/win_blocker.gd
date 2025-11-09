extends ColorRect

func _appear():
	pivot_offset = size/2
	scale = Vector2.ZERO
	self.visible = true
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1,1), 0.3)
	await tween.finished
	await get_tree().create_timer(1).timeout
