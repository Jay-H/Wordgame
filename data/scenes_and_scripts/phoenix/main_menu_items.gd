extends Node
@onready var canvaslayernode = get_parent()
@onready var true_menu = canvaslayernode.get_parent()



func _fade_out():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 1)
	await tween.finished
	self.visible = false

func _fade_in():
	self.modulate = Color.TRANSPARENT
	self.visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 1)


func _on_back_button_pressed() -> void:
	_fade_out()
	await _fade_out()
	%MainMenuItems._fade_in()
	
func _username_flash_green():
	%CurrentUsername.add_theme_color_override("font_color", Color.DARK_GREEN)
	await get_tree().create_timer(0.5).timeout
	%CurrentUsername.add_theme_color_override("font_color", Color.BLACK)

func _username_flash_red():
	%CurrentUsername.add_theme_color_override("font_color", Color.DARK_RED)
	await get_tree().create_timer(0.5).timeout
	%CurrentUsername.add_theme_color_override("font_color", Color.BLACK)
	
func _username_entry_flash_red(text):
	var initial_text = %NewUsername.text
	%NewUsername.add_theme_color_override("font_color", Color.DARK_RED)
	await get_tree().create_timer(0.25).timeout
	%NewUsername.text = text
	await get_tree().create_timer(0.5).timeout
	%NewUsername.text = initial_text
	%NewUsername.add_theme_color_override("font_color", Color.BLACK)


func _on_change_profile_picture_pressed() -> void:
	%ScrollContainer.visible = true
	%VBoxContainer3.visible = false
	for i in %HBoxContainer.get_children():
		i.connect("pressed", _new_profile_picture_pressed.bind(i.profile_picture))
	pass # Replace with function body.

func _new_profile_picture_pressed(picture):
	%ScrollContainer.visible = false
	%VBoxContainer3.visible = true
	%ProfilePicture.setup(picture)
	var picture_index = GlobalData.profile_pics.find(str(picture))
	true_menu._on_profile_pic_changed(picture_index)
	
	pass
