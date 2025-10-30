# menu.gd
# Attach this to the root node of your menu scene.

extends Control

# --- Node References ---
# Assign these nodes in the Godot editor's inspector tab.
@onready var ip_address_edit = $IPAddressEdit
@onready var connect_button = $ConnectButton
@onready var status_label = $StatusLabel

# --- Network Configuration ---
const PORT = 7777 # This MUST match the port on your server!
var world_scene = "res://data/scenes_and_scripts/scramble/scramble_client_scene.tscn"
var lobby_scene = "res://data/scenes_and_scripts/scramble/matchmaking_lobby.tscn"
var client_lobby_scene = "res://data/scenes_and_scripts/scramble/client_matchmaking_lobby.tscn"
@onready var lobby_scene_node = $MatchmakingLobby

func _ready():
	# Set a default IP for easy testing
	ip_address_edit.text = "127.0.0.1" 
	
	# Connect the button's "pressed" signal to our function
	connect_button.pressed.connect(_on_connect_button_pressed)
	
	# Listen for multiplayer connection events
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)


# --- Button and Connection Logic ---

func _on_connect_button_pressed():
	# Get the IP address from the text box, defaulting to localhost if empty
	var ip = ip_address_edit.text
	if ip == "":
		ip = "127.0.0.1"

	# Disable the button and show a "connecting" message
	connect_button.disabled = true
	status_label.text = "Connecting..."
	
	# Create a new ENet peer for the client
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PORT)
	
	if error != OK:
		status_label.text = "❌ Error: Could not create client."
		connect_button.disabled = false
		return
	
	# Set this peer as the active multiplayer peer for the game
	multiplayer.multiplayer_peer = peer
	print("🔌 Connecting to server at %s:%d" % [ip, PORT])


# --- Signal Handlers ---

func _on_connected_to_server():
	print("✅ Successfully connected to server!")
	# Connection was successful, change to the game world scene
	queue_free()
	get_tree().change_scene_to_file(lobby_scene)
	

func _on_connection_failed():
	print("❌ Connection failed.")
	
	# Reset the multiplayer peer and UI
	multiplayer.multiplayer_peer = null
	status_label.text = "Failed to connect."
	connect_button.disabled = false
