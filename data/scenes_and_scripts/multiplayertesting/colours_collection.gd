extends ColorRect
var big_parent

func _ready():
	var parent = get_parent()
	big_parent = parent.get_parent()

func _on_confirm_colour_pressed() -> void:
	big_parent._on_back_pressed()
	pass # Replace with function body.
