extends ColorRect

func fade_process():
	%Label2.modulate = Color.TRANSPARENT
	%TextureRect.modulate = Color.TRANSPARENT
	%Label3.modulate = Color.TRANSPARENT
	
	
	
	
	for i in [%Label2, %TextureRect, %Label3]:
		var tween = create_tween()
		tween.tween_property(i, "modulate", Color.WHITE, 1)
		await tween.finished
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 1)
	
	#for i in [%Label2, %TextureRect, %Label3]:
		#var tween = create_tween()
		#tween.tween_property(i, "modulate", Color.WHITE, 1)
		#tween.chain().tween_property(i, "modulate", Color.WHITE, 1)
		#tween.chain().tween_property(i, "modulate", Color.TRANSPARENT, 1)
		#tween.parallel().tween_property(self, "modulate", Color.TRANSPARENT, 1)
