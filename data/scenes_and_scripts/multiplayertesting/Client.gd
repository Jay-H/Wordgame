# Client.gd
extends Control

# Must match the server's port.
const PORT = 7777
# IP address of the server. "127.0.0.1" is localhost (your own computer).
const IP_ADDRESS = "localhost"
var player_one_ready = false
var player_two_ready = false

@onready var id_label = $IdLabel
@onready var start_button = $StartButton


func _ready():
	# Clients don't need the start button.
	start_button.hide()
	
	# Create a new ENet multiplayer peer.
	var peer = ENetMultiplayerPeer.new()
	# Create the client and connect to the server.
	peer.create_client(IP_ADDRESS, PORT)
	
	# Set this new peer as the multiplayer peer.
	multiplayer.multiplayer_peer = peer
	id_label.text = "Connecting..."
	
	# Signal when the connection succeeds.
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	id_label.text = "connected"


func _on_connected_to_server():
	print("Successfully connected to the server!")
	# The client is ready, but waits for the server to provide the ID list.


# This is the Remote Procedure Call (RPC). The server calls this function on clients.
# The "any_peer" flag allows any peer (the server in this case) to call it.
# The "call_local" flag makes it so this function also runs on the machine that sends the RPC.
@rpc("any_peer", "call_local")
func update_id_label(peer_ids):
	# Update the label with the list of connected IDs.
	id_label.text = "My ID: %d\nConnected IDs: %s" % [multiplayer.get_unique_id(), str(peer_ids)]
	
@rpc("any_peer", "call_local")	
func _start_game():
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://data/scenes_and_scripts/scramble/scramble_client_scene.tscn")
	
	


func _on_ready_button_pressed() -> void:
	pass # Replace with function body.
