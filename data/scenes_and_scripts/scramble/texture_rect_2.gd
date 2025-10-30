extends TextureRect
var tween = create_tween()

func _ready():
	tween.set_loops(0)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(0.75,0.75), 1)
	tween.tween_property(self, "scale", Vector2(1,1), 1)
	print("hello")
