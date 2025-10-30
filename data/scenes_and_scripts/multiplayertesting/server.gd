# Server.gd
extends Control

# Port to listen on. Must match the client.
const PORT = 7777
# Maximum number of players 
const MAX_PLAYERS = 2

var player_one_id 
var player_two_id
var game_countdown = false

# A list to store the IDs of connected peers.
var connected_peer_ids = [] 
@onready var id_label = $IdLabel
@onready var start_button = $StartButton


func _ready():
	# Connect the button's "pressed" signal to the function that starts the server.
	start_button.pressed.connect(_on_start_server_pressed)
	# Connect signals for when peers connect or disconnect.
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	await get_tree().process_frame
	_on_start_server_pressed()


func _process(delta):
	var players_array = multiplayer.get_peers()
	if players_array.size() == 2:
		player_one_id = players_array[0]
		player_two_id = players_array[1]
	if connected_peer_ids.size() > 1:
		if game_countdown == false:
			game_countdown = true
			print("starting in 10 seconds")
			await get_tree().create_timer(10).timeout
			rpc("_start_game")

func _on_start_server_pressed():
	# Create a new ENet multiplayer peer.
	var peer = ENetMultiplayerPeer.new()
	# Create the server.
	var error = peer.create_server(PORT, MAX_PLAYERS)
	
	if error != OK:
		id_label.text = "Error: Cannot create server."
		return
	
	# Set this new peer as the multiplayer peer.
	multiplayer.multiplayer_peer = peer
	id_label.text = "Server started. Waiting for players..."
	# Disable the button after starting.
	start_button.disabled = true
	print("Server is running on port %s" % PORT)



func _on_peer_connected(id):
	print("Player connected: " + str(id))
	# Add the new player's ID to our list.
	connected_peer_ids.append(id)
	# Call the RPC on all clients to update their labels.
	rpc("update_id_label", connected_peer_ids)


func _on_peer_disconnected(id):
	print("Player disconnected: " + str(id))
	# Remove the disconnected player's ID.
	connected_peer_ids.erase(id)
	# Call the RPC on all clients to update their labels.
	rpc("update_id_label", connected_peer_ids)

# This function is not called on the server itself, but it needs to exist
# so the server knows it's a valid RPC for its clients.

@rpc("any_peer", "call_local")
func update_id_label(peer_ids):
	pass
	
@rpc("any_peer", "call_local", "reliable")
func receive_server_information():
	pass

@rpc("any_peer", "call_local")
func _start_game():
	
		get_tree().change_scene_to_file("res://data/scenes_and_scripts/scramble/scramble_server_scene.tscn")
		return
	
