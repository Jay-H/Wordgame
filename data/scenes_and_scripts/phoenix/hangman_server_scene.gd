extends Control
var PORT = 7777
var MAX_PLAYERS = 1000
var new_letter_interval_time = 5
var interval_increase_time = 5
var round_time = 100
var reveal_letter_order_array = []
var reveal_letter_order_dictionary = {}
var word_to_find
var testing_p1_dict = {
	  "auto_skip_rules": true,
	  "country": "",
	  "email": "christopherhaddad12@gmail.com",
	  "experience": 70,
	  "level": 35,
	  "losses": 44,
	  "low_graphics_mode": false,
	  "matches_played": 92,
	  "music_enabled": true,
	  "profilepic": 10,
	  "rank": 5,
	  "rank_points": 6,
	  "sound_enabled": true,
	  "username": "Christopher",
	  "wins": 48
	}
var testing_p2_dict = {
	  "auto_skip_rules": true,
	  "country": "unknown",
	  "email": "a@hotmail.com",
	  "experience": 50,
	  "level": 2,
	  "losses": 9,
	  "low_graphics_mode": false,
	  "matches_played": 20,
	  "music_enabled": true,
	  "profilepic": 6,
	  "rank": 0,
	  "rank_points": 1,
	  "sound_enabled": true,
	  "username": "Jehosophat",
	  "wins": 11
	}
var peers_connected = 0
var p1id
var p2id
var player_one_number_of_revealed_letters = 0
var player_two_number_of_revealed_letters = 0
var player_one_wrong_guesses = 0
var player_two_wrong_guesses = 0
var player_one_delay_multiplier = 1.00
var player_two_delay_multiplier = 1.00
var delay_multiplier_factor = 1.01

var chaos_variant = true
var turn_based_variant = false
var reveal_hints_variant = false
var delay_variant = true

var game_dictionary = {
	"player_one_dictionary": {}, "player_two_dictionary": {}, "word_to_find": "", "player_one_time_to_new_letter": 0.0, 
	"player_two_time_to_new_letter": 0.0, "player_one_last_guess": "_______", "player_two_last_guess": "_______", "player_one_wrong_guesses": 0,
	"player_two_wrong_guesses": 0, "player_one_id": 0, "player_two_id": 0, "player_one_revealed_letters": 0,
	"player_two_revealed_letters": 0, "reveal_letter_order_array": [], "reveal_letter_order_dictionary": {}, 
	"player_one_delay": 1.00, "player_two_delay": 1.00
}
var word_list = ["CAPTAIN", "ELEVEN", "NEPTUNE", "JUPITER", "ASTRAL", "WESTERN", "OCCIDENT", "ORIENT", "CEPHALIC"]


func _ready():
	_start_server()
	multiplayer.peer_connected.connect(_on_peer_connected)

	pass

func _on_peer_connected(id):
	peers_connected += 1
	if peers_connected == 2:
		print("peers connected")
		_debug_initialize()
		word_list.shuffle()
		game_dictionary["word_to_find"] = word_list[randi() % word_list.size()]
		word_to_find = game_dictionary["word_to_find"]
		var word_index_array = []
		for i in range(word_to_find.length()):
			word_index_array.append(i)
			word_index_array.shuffle()
			print(word_index_array)
		var word_index_dictionary = {}
		for i in range(word_to_find.length()):
			word_index_dictionary[i] = word_to_find[i]
		game_dictionary["reveal_letter_order_dictionary"] = word_index_dictionary
		game_dictionary["reveal_letter_order_array"] = word_index_array

		rpc_id(p1id, "_initial_dictionary_server_to_client", game_dictionary)
		rpc_id(p2id, "_initial_dictionary_server_to_client", game_dictionary)
		_new_letter_timer_starter(p1id)
		_new_letter_timer_starter(p2id)
		%RoundTimer.start(100)
		_cycler()
		print(game_dictionary)
func _cycler(): #repeating function which sends dictionary to clients every 0.5 seconds
	await get_tree().create_timer(0.5).timeout
	rpc_id(p1id, "_send_dictionary_server_to_client", game_dictionary)
	rpc_id(p2id, "_send_dictionary_server_to_client", game_dictionary)
	_cycler()
	pass		
		
		
func _process(_delta):
	game_dictionary["player_one_time_to_new_letter"] = %P1NewLetterTimer.time_left
	game_dictionary["player_two_time_to_new_letter"] = %P2NewLetterTimer.time_left
	pass

func _initialize(dict):
	game_dictionary["player_one_dictionary"] = dict["player_one_dictionary"]
	game_dictionary["player_two_dictionary"] = dict["player_two_dictionary"]
	pass

func _debug_initialize():
	
	game_dictionary["player_one_dictionary"] = testing_p1_dict
	game_dictionary["player_two_dictionary"] = testing_p2_dict
	print (multiplayer.get_peers())
	set_meta("userid1", multiplayer.get_peers()[0])	
	set_meta("userid2", multiplayer.get_peers()[1])	
	game_dictionary["player_one_id"] = multiplayer.get_peers()[0]
	game_dictionary["player_two_id"] = multiplayer.get_peers()[1]
	p1id = multiplayer.get_peers()[0]
	p2id = multiplayer.get_peers()[1]
	
@rpc("any_peer", "call_local", "reliable")
func _guess_client_to_server(guess):
	pass

@rpc("any_peer", "call_local", "reliable")
func _initial_dictionary_server_to_client(dictionary):
	pass

@rpc("any_peer", "call_local", "reliable")
func _send_dictionary_server_to_client(dictionary):
	pass

func _new_letter_timer_starter(player):
	if player == p1id:
		%P1NewLetterTimer.start(new_letter_interval_time)
		%P1NewLetterTimer.timeout.connect(_new_letter_timer_timeout_function.bind(p1id))

	if player == p2id:
		%P2NewLetterTimer.start(new_letter_interval_time)
		%P2NewLetterTimer.timeout.connect(_new_letter_timer_timeout_function.bind(p2id))	
	pass

func _new_letter_timer_timeout_function(player):
	if player == p1id:
		if player_one_number_of_revealed_letters < word_to_find.length() - 1:
			%P1NewLetterTimer.start(new_letter_interval_time + interval_increase_time)
			game_dictionary["player_one_revealed_letters"] += 1
			rpc_id(p1id, "_send_dictionary_server_to_client", game_dictionary)
			player_one_number_of_revealed_letters += 1
	if player == p2id:
		if player_two_number_of_revealed_letters < word_to_find.length() - 1:
			%P2NewLetterTimer.start(new_letter_interval_time + interval_increase_time)
			game_dictionary["player_two_revealed_letters"] += 1
			rpc_id(p2id, "_send_dictionary_server_to_client", game_dictionary)
			player_two_number_of_revealed_letters += 1
	pass

@rpc("any_peer", "call_local", "reliable")
func _send_word_to_server(word):
	var peer_id = multiplayer.get_remote_sender_id()
	if word == word_to_find:
		print("Winner is: " + str(peer_id))
	if peer_id == p1id:
		
		game_dictionary["player_one_last_guess"] = word
		_delay_calculator(p1id)
		
	if peer_id == p2id:
		
		game_dictionary["player_two_last_guess"] = word
		_delay_calculator(p2id)
	rpc_id(p1id, "_send_dictionary_server_to_client", game_dictionary)
	rpc_id(p2id, "_send_dictionary_server_to_client", game_dictionary)
	pass

func _lockout():
	pass


# this function calculates the additional delay on seeing the new letter as you make incorrect guesses
func _delay_calculator(id): 
	var guesses
	var timer
	var number_of_revealed_letters
	if id == p1id: 
		player_one_wrong_guesses += 1
		guesses = player_one_wrong_guesses
		timer = %P1NewLetterTimer
		number_of_revealed_letters = player_one_number_of_revealed_letters
	if id == p2id:
		player_two_wrong_guesses += 1
		guesses = player_two_wrong_guesses
		timer = %P2NewLetterTimer
		number_of_revealed_letters = player_two_number_of_revealed_letters
	if number_of_revealed_letters <= 2: # this makes it so there is no penalty to guessing rapidly early on, and doesn't record wrong guesses
		if id == p1id:
			player_one_wrong_guesses = 0
		if id == p2id:
			player_two_wrong_guesses = 0
		return
	if number_of_revealed_letters > 2: # when more than two letters are revealed, we start counting the wrong guesses.
		if id == p1id:
			player_one_wrong_guesses += 1
			player_one_delay_multiplier *= delay_multiplier_factor # this multiplier causes an exponential rise in delay as you guess wrong.
			game_dictionary["player_one_delay"] = player_one_delay_multiplier
			timer.start(new_letter_interval_time * player_one_delay_multiplier) # can play around with this stuff to altar the penalty of delay
		if id == p2id:
			player_two_wrong_guesses += 1
			player_two_delay_multiplier *= delay_multiplier_factor
			game_dictionary["player_two_delay"] = player_two_delay_multiplier
			timer.start(new_letter_interval_time * player_two_delay_multiplier)		

	

	pass


func _start_server():
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
