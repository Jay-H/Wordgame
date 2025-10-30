extends Control

@onready var label = $Label

var player_ids = ""

func _ready():
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
	
func _process(delta):
	if OS.has_feature("dedicated_server"):
		print(multiplayer.get_peers())
@rpc ("any_peer", "call_local", "reliable")

func _on_player_connected(id):
	if OS.has_feature("dedicated_server"):
		print("Player connected: %d" % id)
		player_ids += str(id)
		print(player_ids)
		
	
		label.text = player_ids
	
	
func _on_player_disconnected(id):
	print("Player disconnected: %d" % id)

@rpc ("any_peer", "call_local", "reliable")
func _client_id_sender():
	return player_ids
	
