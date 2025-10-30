extends Control
@onready var main_menu = get_parent()

func _ready():
	%ScrollContainer.connect("picture_selected", _on_picture_selection_pressed)
	pass

func setup():
	if main_menu.profile_info["ProfilePic"] == null:
		print("no profile pic assigned yet")
	if main_menu.profile_info["ProfilePic"] != null:
		%ProfilePicture2.setup(load(main_menu.profile_info["ProfilePic"]))
		%ProfilePicture.setup(load(main_menu.profile_info["ProfilePic"]))
	if main_menu.profile_info["Rank"] != null:
		%CurrentRank.text = "Rank: " + str(Globals.rank_name_array[main_menu.profile_info["Rank"]])
	if main_menu.profile_info.has("Level"):
		%CurrentLevel.text = "Level " + str(int(main_menu.profile_info["Level"])) + ": " + str(Globals.level_name_array[main_menu.profile_info["Level"]])	
	if main_menu.profile_info.has("Username"):
		%Username.text = main_menu.profile_info["Username"]
	
func _on_picture_selection_pressed(picture):
	var selected_profile_pic = picture
	print("picture pressed")
	print(selected_profile_pic.resource_path)
	%ProfilePicture.setup(load(selected_profile_pic.resource_path))
	%ProfilePicture2.setup(load(selected_profile_pic.resource_path))
	main_menu.update_profile_pic(selected_profile_pic.resource_path)
	pass


func _on_button_pressed() -> void:
	%ProfilePicChooserScreen.visible = false
	pass # Replace with function body.


func _on_change_profile_button_pressed() -> void:
	%ProfilePicChooserScreen.visible = true
	pass # Replace with function body.


func _on_back_button_pressed() -> void:
	self.visible = false
	pass # Replace with function body.
