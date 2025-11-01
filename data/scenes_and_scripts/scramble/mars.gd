extends TextureRect

var tween2

func _ready():
	animator()
	pass
	
func animator():
	var tween = create_tween()
	var random_number = randomizer()
	
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CIRC)
	tween.tween_property(self.material, "shader_parameter/bloom_intensity", random_number,  5)
	tween.parallel().tween_property(self.material, "shader_parameter/blood_treshold", random_number, 2.9)
	await tween.finished
	
	animator()
	
func randomizer():
	return randf_range(0.4, 1.5)
