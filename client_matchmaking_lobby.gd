extends Control

@onready var label = $Label
@onready var server_matchmaking_node = 
var player_ids = ""

func _ready():
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
	

@rpc ("any_peer", "call_local", "reliable")

func _process(delta):
	label.text = server_node.rpc("word_listener", word)

func _player_id_populator(id):
	pass

#func _on_player_connected(id):
	#if OS.has_feature("dedicated_server"):
		#print("Player connected: %d" % id)
		#player_ids += str(id)
		#print(player_ids)
	#await get_tree().get_frame()
	#if OS.has_feature("dedicated_server") == false:
		#label.text = player_ids
	#
	#
#func _on_player_disconnected(id):
	#print("Player disconnected: %d" % id)
