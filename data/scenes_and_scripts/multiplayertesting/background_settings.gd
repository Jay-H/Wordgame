extends CanvasLayer

signal background_chosen

var current_collection_displayed
var current_collection_song
var solar_system_path = "res://data/scenes_and_scripts/multiplayertesting/solar_system.tscn"
var colors_system_path = "res://data/scenes_and_scripts/multiplayertesting/colours_collection.tscn"
var current_background

func _on_jupiter_pressed() -> void:
	var jupiter_material = load("res://data/scenes_and_scripts/scramble/jupiter4test.tres")
	%BackgroundPreview.material = jupiter_material
	%BackgroundPreview.modulate = Color(1.0, 1.0, 1.0, 0.678)
	
	pass # Replace with function body.


func _on_cloudscape_pressed() -> void:
	var cloudscape_material = load("res://data/scenes_and_scripts/scramble/cloudscape2test.tres")
	%BackgroundPreview.material = cloudscape_material
	pass # Replace with function body.


func _on_preview_background_button_pressed() -> void:
	%BackgroundPreview.visible = true
	pass # Replace with function body.


func _on_hide_background_button_pressed() -> void:
	%BackgroundPreview.visible = false
	pass # Replace with function body.

func fade_transition():
	var tween = create_tween()
	tween.tween_property(%FadeBox, "modulate", Color.BLACK, 0.75)
	tween.tween_property(%FadeBox, "modulate", Color.TRANSPARENT, 1.5)	


func _on_solar_system_collection_pressed() -> void:
	fade_transition()
	await get_tree().create_timer(0.75).timeout
	var solar_system_instance = (load(solar_system_path)).instantiate()
	%Control.add_child(solar_system_instance)
	%FadeBox.move_to_front()
	current_collection_displayed = solar_system_instance


func _on_back_pressed() -> void:
	fade_transition()
	await get_tree().create_timer(0.75).timeout
	current_collection_displayed.queue_free()
	
func background_setter(bgname):
	background_chosen.emit(bgname)
	%BackgroundPreview.material = load(Globals.backgrounds_dictionary[bgname])
	pass


func _on_button_pressed() -> void:
	queue_free()
	pass # Replace with function body.


func _on_colours_pressed() -> void:
	fade_transition()
	await get_tree().create_timer(0.75).timeout
	var colours_collection_instance = (load(colors_system_path)).instantiate()
	%Control.add_child(colours_collection_instance)
	%FadeBox.move_to_front()
	current_collection_displayed = colours_collection_instance
	pass # Replace with function body.
