extends Control

@onready var hbox = get_parent()
@onready var scroll_box = hbox.get_parent()

signal pressed
var profile_picture


func setup(picture):
	profile_picture = picture
	$ColorRect/TextureRect.texture = load(picture)


func _on_texture_button_pressed() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	print(mouse_filter)
	pressed.emit()
	print("texture button presseds")
	pass # Replace with function body.
