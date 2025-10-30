extends Control

@onready var firstsceneserver = "res://data/scenes_and_scripts/phoenix/serverhost2.tscn"
@onready var firstsceneclient = "res://data/scenes_and_scripts/phoenix/main_menu_2.tscn"

func _ready():
	
	if OS.has_feature("dedicated_server"):
		print("✅ Starting server...")
		get_tree().change_scene_to_file(firstsceneserver)
	else:
		print("👤 Starting client...")
		
		get_tree().change_scene_to_file(firstsceneclient)
		
