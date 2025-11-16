extends Control
signal game_over
var debug_mode = false
var PORT = 7777
var MAX_PLAYERS = 1000
var new_letter_interval_time = 5
var interval_increase_time = 8
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
var turn_time_length = 12
var timer_node
var chaos_variant = false
var chaos_shared_clues = false
var turn_based_variant = false
var ephemeral_hints_variant = true
var delay_variant = true
var big_dictionary
var game_dictionary = {
	"player_one_dictionary": {}, "player_two_dictionary": {}, "word_to_find": "", "player_one_time_to_new_letter": 0.0, 
	"player_two_time_to_new_letter": 0.0, "player_one_last_guess": "_______", "player_two_last_guess": "_______", "player_one_wrong_guesses": 0,
	"player_two_wrong_guesses": 0, "player_one_id": 0, "player_two_id": 0, "player_one_revealed_letters": 0,
	"player_two_revealed_letters": 0, "reveal_letter_order_array": [], "reveal_letter_order_dictionary": {}, 
	"player_one_delay": 1.00, "player_two_delay": 1.00, "which_player_turn": "one", "last_turn_ended_by_timeout": false,
	"player_one_turn_time": 0.00, "player_two_turn_time": 0.00, "turn_based_indices_found": [], "chaos_shared_indices_found" : [],
	"Player One Score": 0, "Player Two Score": 0, "game_type": "hangman"
}
#var word_list = ["CAPTAIN", "ELEVEN", "NEPTUNE", "JUPITER", "ASTRAL", "WESTERN", "OCCIDENT", "ORIENT", "CEPHALIC"]
var word_list = ["CRAVE", "DOVES", "LEARN", "CLOUD", "FLAME", "ERUPT", "ALIVE", "LOVER", "STONE", "WIELD", "MOUNT", "AREA", "NIGHT", "FLAMES",
"DANGER", "LANDED", "WINTER", "BLOUSE", "BRAVERY", "LAVA", "GREEN", "BOUGH", "ATTACK", "QUEEN", "KING", "DUKE", "DUCHESS", "EARL", "KINGDOM",
"HEAVEN", "ANGEL", "DEMON", "PLANET", "WINDY", "METEOR", "PULSE", "HELIUM", "GRAVITY", "LIGHT", "SPEED", "FORAGE", "FOREST", "ZEALOT", "SUMMER", 
"MOON", "STARS", "START", "ABOUT", "QUIET", "QUEST", "CLAIM", "CLOVE", "APPLE", "PEAR", "CHERRY", "WINE", "ORANGE", "BLACK", "ORCHARD", "STANDARD", 
"JUPITER", "SATURN", "VENUS", "EARTH", "MARS", "NEPTUNE", "PLUTO", "MERCURY", "URANUS", "ROSARY", "PRAYER", "PHASE", "SOLID", "LIQUID", "ACRID",
"ACRIMONY", "VELVET", "BANISH", "EXORCISE", "SPIRIT", "GHOST", "FAIRY", "VAMPIRE", "BRONZE", "IRON", "STEEL", "COPPER", "BAKER", "MATTER", "ENERGY"
]

func _ready():
	if debug_mode:
		_start_server()
		multiplayer.peer_connected.connect(_on_peer_connected)
	else:
		
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
		p1id = get_meta("userid1")
		p2id = get_meta("userid2")
		game_dictionary["player_one_id"] = p1id
		game_dictionary["player_two_id"] = p2id
		print("we got here...")
		rpc_id(p1id, "_initial_dictionary_server_to_client", game_dictionary)
		rpc_id(p2id, "_initial_dictionary_server_to_client", game_dictionary)
		_new_letter_timer_starter(p1id)
		_new_letter_timer_starter(p2id)
		%RoundTimer.start(100)
		_cycler()
		if turn_based_variant:
			%P1TurnTimer.start(turn_time_length)
			%P1TurnTimer.timeout.connect(_turn_time_ran_out)
			%P2TurnTimer.timeout.connect(_turn_time_ran_out)
		print(game_dictionary)	
	pass

func _on_peer_connected(id):
	if debug_mode:
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
			if turn_based_variant:
				%P1TurnTimer.start(turn_time_length)
				%P1TurnTimer.timeout.connect(_turn_time_ran_out)
				%P2TurnTimer.timeout.connect(_turn_time_ran_out)
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
	game_dictionary["player_one_turn_time"] = %P1TurnTimer.time_left
	game_dictionary["player_two_turn_time"] = %P2TurnTimer.time_left
	pass

func _initialize(dict):


	game_dictionary["player_one_dictionary"] = dict["player_one_dictionary"]
	game_dictionary["player_two_dictionary"] = dict["player_two_dictionary"]
	var variant = dict["selected_games"][dict["current_round"]]
	print(variant)
	_set_variants(variant)
	
		
	pass
func _set_variants(variant):
	if variant == "HangmanChaosVanilla":
		chaos_variant = true
		chaos_shared_clues = false
		turn_based_variant = false
		ephemeral_hints_variant = false
		delay_variant = false
	if variant == "HangmanChaosShared":
		chaos_shared_clues = true
		chaos_variant = true
		turn_based_variant = false
		ephemeral_hints_variant = false
		delay_variant = false
	if variant == "HangmanChaosEphemeral":
		chaos_shared_clues = false
		chaos_variant = true
		turn_based_variant = false
		ephemeral_hints_variant = true
		delay_variant = false		
	if variant == "HangmanTurnbased":
		chaos_shared_clues = false
		chaos_variant = false
		turn_based_variant = true
		ephemeral_hints_variant = false
		delay_variant = false				
	if variant == "HangmanDelay":
		chaos_shared_clues = false
		chaos_variant = false
		turn_based_variant = false
		ephemeral_hints_variant = false
		delay_variant = true
	if variant == "HangmanDelayEphemeral":
		chaos_shared_clues = false
		chaos_variant = false
		turn_based_variant = false
		ephemeral_hints_variant = true
		delay_variant = true

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
	print("server _initial running")
	pass

@rpc("any_peer", "call_local", "reliable")
func _send_dictionary_server_to_client(dictionary):
	pass

func _new_letter_timer_starter(player):
	if delay_variant:
		# this part will make the letter new letter timer adjust based on how many letters there are in the word, to keep the total game time constant.
		var adjusted_interval_increase_time = 40/word_to_find.length()
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
			player_one_number_of_revealed_letters += 1
			%P1NewLetterTimer.start(new_letter_interval_time + (interval_increase_time * player_one_number_of_revealed_letters) )
			game_dictionary["player_one_revealed_letters"] += 1
			rpc_id(p1id, "_send_dictionary_server_to_client", game_dictionary)
			
	if player == p2id:
		if player_two_number_of_revealed_letters < word_to_find.length() - 1:
			player_two_number_of_revealed_letters += 1
			%P2NewLetterTimer.start(new_letter_interval_time + (interval_increase_time * player_two_number_of_revealed_letters))
			game_dictionary["player_two_revealed_letters"] += 1
			rpc_id(p2id, "_send_dictionary_server_to_client", game_dictionary)
			
	pass

@rpc("any_peer", "call_local", "reliable")
func _send_word_to_server(word):
	print("server receiving word")
	var peer_id = multiplayer.get_remote_sender_id()
	if word == word_to_find:
		print("Winner is: " + str(peer_id))
		if peer_id == p1id:
			game_dictionary["Player One Score"] = 99999
			game_dictionary["player_one_last_guess"] = word
		else:
			game_dictionary["Player Two Score"] = 99999
			game_dictionary["player_two_last_guess"] = word
		big_dictionary = game_dictionary
		game_over.emit()
		return
	if peer_id == p1id:
		game_dictionary["player_one_wrong_guesses"] += 1
		game_dictionary["player_one_last_guess"] = word
		_delay_calculator(p1id)
	if peer_id == p2id:
		game_dictionary["player_two_wrong_guesses"] += 1
		game_dictionary["player_two_last_guess"] = word
		_delay_calculator(p2id)
	if turn_based_variant:
		var turn_based_result = _turn_based_letter_logic(word)
		if game_dictionary["which_player_turn"] == "one":
			game_dictionary["which_player_turn"] = "two"
			%P2TurnTimer.start(turn_time_length)
			%P1TurnTimer.stop()
		else:
			game_dictionary["which_player_turn"] = "one"
			%P1TurnTimer.start(turn_time_length)
			%P2TurnTimer.stop()
	if chaos_shared_clues:
		_chaos_shared_indices_populator(word)
	rpc_id(p1id, "_send_dictionary_server_to_client", game_dictionary)
	rpc_id(p2id, "_send_dictionary_server_to_client", game_dictionary)
	
	pass

func _chaos_shared_indices_populator(word):
	if word.length() != word_to_find.length():
		return "wrong length"
	else:
		var array_of_indices = []
		for i in word.length():
			if word_to_find[i] == word[i]:
				array_of_indices.append(i)
		for i in array_of_indices:
			if game_dictionary["chaos_shared_indices_found"].has(i):
				pass
			else:
				game_dictionary["chaos_shared_indices_found"].append(i)
		pass
	
	pass

	pass


func _lockout():
	pass


# this function calculates the additional delay on seeing the new letter as you make incorrect guesses
func _delay_calculator(id): 
	var guesses
	var timer
	var number_of_revealed_letters
	if not delay_variant:
		return
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


func _turn_time_ran_out():
	if game_dictionary["which_player_turn"] == "one":
		game_dictionary["which_player_turn"] = "two"
		%P2TurnTimer.start(turn_time_length)
		%P1TurnTimer.stop()
	else:
		game_dictionary["which_player_turn"] = "one"
		%P1TurnTimer.start(turn_time_length)
		%P2TurnTimer.stop()
	game_dictionary["last_turn_ended_by_timeout"] = true
	rpc_id(p1id, "_send_dictionary_server_to_client", game_dictionary)
	rpc_id(p2id, "_send_dictionary_server_to_client", game_dictionary)
	game_dictionary["last_turn_ended_by_timeout"] = false

	pass 

func _turn_based_letter_logic(word):
	if word.length() != word_to_find.length():
		return "wrong length"
	else:
		var array_of_indices = []
		for i in word.length():
			if word_to_find[i] == word[i]:
				array_of_indices.append(i)
		for i in array_of_indices:
			if game_dictionary["turn_based_indices_found"].has(i):
				pass
			else:
				game_dictionary["turn_based_indices_found"].append(i)
		pass
	
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
