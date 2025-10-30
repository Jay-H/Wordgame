extends Control

@onready var firstsceneserver = "res://data/scenes_and_scripts/wordsearch/WsServer.tscn"
@onready var firstsceneclient = "res://data/scenes_and_scripts/wordsearch/Wordsearch.tscn"

func _ready():
	
	if OS.has_feature("dedicated_server"):
		print("✅ Starting wordsearch server...")
		get_tree().change_scene_to_file(firstsceneserver)
	else:
		print("👤 Starting wordsearch client...")
		
		get_tree().change_scene_to_file(firstsceneclient)
