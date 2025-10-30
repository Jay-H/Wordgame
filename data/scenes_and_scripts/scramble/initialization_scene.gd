# Main.gd
extends Node

const PORT = 7777
const MAX_PLAYERS = 2
const ip = "127.0.0.1" # Use 127.0.0.1 for localhost

var lobby_scene = "res://data/scenes_and_scripts/scramble/matchmaking_lobby.tscn"

func _ready():
	if OS.has_feature("dedicated_server"):
		print("✅ Starting server...")
		_start_server()
	else:
		print("Starting client...")
		_start_client()

# --- Server Logic ---
func _start_server():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PLAYERS)
	
	if error != OK:
		print("❌ Error: Cannot start server.")
		get_tree().quit()
		return
	
	multiplayer.multiplayer_peer = peer
	print("✅ Server started successfully. Waiting for players...")

	# The server needs to know when players connect to decide when to start.
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
	# The server loads the lobby scene for itself and waits.
	get_tree().change_scene_to_file(lobby_scene)

func _on_player_connected(id):
	print("Player connected: %d" % id)
	
	
	rpc("load_scene", lobby_scene)
		
@rpc("any_peer", "call_local")
func load_scene(scene_path):
	print("Received command to load scene: %s" % scene_path)
	get_tree().change_scene_to_file(scene_path)
	
func _on_player_disconnected(id):
	print("Player disconnected: %d" % id)


# --- Client Logic ---
func _start_client():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PORT)
	
	if error != OK:
		print("❌ Error: Could not connect to server.")
		return
	
	multiplayer.multiplayer_peer = peer
	print("🔌 Connecting to server at %s:%d" % [IP, PORT])
	# That's it! The client's job is done.
	# It now waits for the server to send the 'load_scene' RPC.
