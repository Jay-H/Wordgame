extends Node2D

var line_end_point = Vector2.ZERO:
	set(value):
		line_end_point = value
		queue_redraw()
		

func _ready():
	animate()
	pass
	

func _draw():
	draw_line(Vector2(0,0), line_end_point, Color.CORAL, 11, true)
	
	
func animate():
	var final_destination = Vector2(700,0)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self,"line_end_point", final_destination, 0.75)
	
