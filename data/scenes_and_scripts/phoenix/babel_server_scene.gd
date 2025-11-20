extends Control
var debug_peers_connected
var debug_first_timer_started = false
var PORT = 7777
var MAX_PLAYERS = 1000
var player_one_firebase_id
var player_two_firebase_id
var player_one_peer_id
var player_two_peer_id
var letter_node_dictionary = {}
var current_letter_index = 0
var player_one_words = []
var player_two_words = []
var game_over_by_word_count = false

func _debug_initializer():
		# Create a new ENet multiplayer peer.
	var peer = ENetMultiplayerPeer.new()
	# Create the server.
	var error = peer.create_server(PORT, MAX_PLAYERS)

	if error != OK:
		print("Error: Cannot create server.")
		return
	
	# Set this new peer as the multiplayer peer.
	multiplayer.multiplayer_peer = peer
	printerr("Server started. Waiting for players...")

	printerr("Server is running on port %s" % PORT)

	
@rpc("any_peer")
func _debug_get_user_peer_id(id):
	printerr("debug get user")
	if player_one_peer_id == null:
		player_one_peer_id = id
	if player_one_peer_id != null:
		player_two_peer_id = id
	pass

func _process(_delta):
	if player_one_peer_id != null and player_two_peer_id != null:

		debug_peers_connected = true
		if debug_first_timer_started == false:
			
			debug_first_timer_started = true
			%NewLetterTimer.start(1)
			print("started")

func _ready():
	_debug_initializer()
	%NewLetterTimer.timeout.connect(_random_letter_generator)
	pass

func _random_letter_generator():

	var letter_index = current_letter_index
	current_letter_index += 1
	%NewLetterTimer.start(randi_range(1,1))
	var font_size = randi_range(180,230)
	var time_to_fall = randf_range(5, 15)
	var letter_node = %PrototypeFallingLetter.duplicate()
	var percentage_position = randf_range(0,1)
	var consonant_or_vowel
	var random = randi_range(0,10)
	if random >= 0 and random <= 4:
		consonant_or_vowel = "vowel"
	else:
		consonant_or_vowel = "consonant"
	if consonant_or_vowel == "vowel":
		letter_node.text = GlobalData.vowels[randi_range(0, GlobalData.vowels.size() - 1)]
	else:
		letter_node.text = GlobalData.consonants[randi_range(0, GlobalData.consonants.size() - 1)]
	var letter_node_info_array = [letter_node.text, font_size, time_to_fall, current_letter_index, percentage_position]
	rpc_id(player_one_peer_id, "_random_letter_node_creator", letter_node_info_array)
	rpc_id(player_two_peer_id, "_random_letter_node_creator", letter_node_info_array)
	
@rpc("any_peer")	
func _random_letter_node_creator(letter_information_array):
	pass
	
@rpc("any_peer")
func _inform_server_letter_pressed(letter_index):
	rpc_id(player_one_peer_id, "_inform_clients_letter_pressed", letter_index)
	rpc_id(player_two_peer_id, "_inform_clients_letter_pressed", letter_index)
	pass

@rpc("any_peer")
func _inform_clients_letter_pressed(letter_index):
	pass
@rpc("any_peer")
func _submit_word(word):
	var peer_id = multiplayer.get_remote_sender_id()
	if GlobalData.is_valid_word(word):
		print("valid word")
		
		if peer_id == player_one_peer_id:
			player_one_words.append(word)
		else:
			player_two_words.append(word)
			
		rpc_id(peer_id, "_valid_word_informer", word)
	else:
		rpc_id(peer_id, "_invalid_word_informer", word)
	if player_one_words.size() == 3 or player_two_words.size() == 3: # end condition number 1
		game_over_by_word_count = true
	pass
	
@rpc("any_peer")
func _valid_word_informer(word):
	pass
@rpc("any_peer")
func _invalid_word_informer(word):
	pass
