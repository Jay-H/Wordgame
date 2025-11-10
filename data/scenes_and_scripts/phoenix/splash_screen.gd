extends ColorRect

func fade_process():
	%LoginScreenMusic.volume_linear = 0
	%LoginScreenMusic.play(1.21)
	var volume_tween = create_tween()
	volume_tween.tween_property(%LoginScreenMusic, "volume_linear", 1, 0.5)
	%Label2.modulate = Color.TRANSPARENT
	%TextureRect.modulate = Color.TRANSPARENT
	%Label3.modulate = Color.TRANSPARENT
	var particle_tween = create_tween()
	particle_tween.tween_property(%PathFollow2D, "progress_ratio", 1.0, 5)	
	for i in [%Label2, %TextureRect, %Label3]:
		var tween = create_tween()
		tween.tween_property(i, "modulate", Color.WHITE, 5/2)
		await tween.finished
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 5/3)
	

	
