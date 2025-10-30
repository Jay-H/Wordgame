extends GPUParticles2D


func fade_in_particles():
	var tween = create_tween()
	# Animate from transparent to opaque
	tween.tween_property(self, "modulate:a", 1, 5)
