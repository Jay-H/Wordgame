extends Control

@onready var firstsceneserver = "res://data/scenes_and_scripts/phoenix/hangman_server_scene.tscn"
@onready var firstsceneclient = "res://data/scenes_and_scripts/phoenix/hangman_client_scene.tscn"

func _ready():
	
	if OS.has_feature("dedicated_server"):
		print("✅ Starting server...")
		get_tree().change_scene_to_file(firstsceneserver)
	else:
		print("👤 Starting client...")
		
		get_tree().change_scene_to_file(firstsceneclient)
		
