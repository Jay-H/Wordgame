extends CanvasLayer
@onready var main_menu = get_parent()

func _ready():
	fade_out()
	
func fade_in():
	var tween = create_tween()
	for i in get_children():
		tween.tween_property(i, "modulate", Color.WHITE, 1)

func fade_out():
	var tween = create_tween()
	for i in get_children():
		tween.tween_property(i, "modulate", Color.TRANSPARENT, 1)
	await get_tree().create_timer(1).timeout
	self.visible = false

func _on_back_button_pressed() -> void:
	fade_out()
	pass # Replace with function body.


func _on_backgrounds_pressed() -> void:
	var background_screen = (load("res://data/scenes_and_scripts/multiplayertesting/background_settings.tscn")).instantiate()
	add_sibling(background_screen)
	background_screen.connect("background_chosen", main_menu.background_setter)
	pass # Replace with function body.
