extends Node
class_name GameServer

signal time_up(wordsearch_winner)

const PORT = Globals.SERVER_PORT
const MAX_PLAYERS = 2

var SERVER_WORDS_LIST = GlobalData.scrabble_dictionary

var found_words: Dictionary = {}

var connected_peer_ids : Array = [1,2]

var words_for_client
var pending = true
var grid_cells: Array = []
var _word_placement_map: Array = []
var _total_weight = 100.0

var countdown_time = Globals.GAME_DURATION_SECONDS
var current_time = 0.0
var timer_active = false
var tiebreaker = false

var chosen_variant
var process_pause = false

var phoenix_dictionary = {}
var round_timer
var player_one_score
var player_two_score
var big_dictionary = {}
var game_over = false

func _ready():
	round_timer = get_node(str("../../" + phoenix_dictionary["timers_node_name"]) + "/RoundTimer")
	connected_peer_ids[0] = get_meta("userid1")
	connected_peer_ids[1] = get_meta("userid2")
	words_for_client = _generate_random_words()
	
	found_words[connected_peer_ids[0]] = []
	found_words[connected_peer_ids[1]] = []
	generate_grid()
	
	await get_tree().create_timer(2).timeout # Give client a moment to insantiate
	for peer in connected_peer_ids:
		rpc_id(peer, "_server_ready", {"words": words_for_client, "grid": grid_cells, "players": connected_peer_ids, "variant": chosen_variant})
	round_timer.start(Globals.GAME_DURATION_SECONDS)
	
func _process(delta):
	if round_timer.time_left < 0.5 && !game_over:
		if not tiebreaker:
			start_tiebreaker()
		else:
			check_game_win(true)

func start_manual_timer():
	timer_active = true
	round_timer.start(Globals.SUDDEN_DEATH_DURATION_SECONDS)
	
func start_tiebreaker():
	tiebreaker = true
	start_manual_timer()
	rpc_id(connected_peer_ids[0], "start_sudden_death")
	rpc_id(connected_peer_ids[1], "start_sudden_death")

@rpc("any_peer")
func _word_received(word: String, selection_path: Array):
	if word in words_for_client:
		# put the word in the right peron's dictionary array
		found_words[multiplayer.get_remote_sender_id()].append(word)
		
		# RIGHT OR WIN - add word to remote senders list of found words - client will handle making label green
		# then we need to send msg to other client with to make opponent label red
		# just learned this syntax for godot, similar to python
		var opponent_id = connected_peer_ids[0] if connected_peer_ids[1] == multiplayer.get_remote_sender_id() else connected_peer_ids[1]
		
		# selection path only utilized if its in the shared_board variant
		rpc_id(opponent_id, "set_red_label", word, multiplayer.get_remote_sender_id(), selection_path)

		# WIN - don't bother continuing with logic, end the match
		if check_game_win():
			var current_player = multiplayer.get_remote_sender_id()
			if connected_peer_ids[0] == current_player:
				_populate_big_dictionary("one")
			else:
				_populate_big_dictionary("two")
			game_over = true
			round_timer.start(0.01)
		
		# RIGHT
		return Globals.WordResult.RIGHT
	else:
		# WRONG
		return Globals.WordResult.WRONG

"""
	For the regular and hidden game mode, if the sudden death time ends and someone has more words,
	they win. Otherwise, randomely chosen
	
	For the shared board, its just whoever immediately gets the majority, otherwise randomely chosen
"""
func check_game_win(sudden_death_ended = false):
	if chosen_variant == Globals.WordsearchVariants.DEFAULT or chosen_variant == Globals.WordsearchVariants.HIDDEN:
		if !sudden_death_ended:
			return found_words[multiplayer.get_remote_sender_id()].size() >= Globals.GUARANTEED_WORD_COUNT
		else:
			get_winner_by_word_count()
	
	elif chosen_variant == Globals.WordsearchVariants.SHARED_BOARD:
		if !sudden_death_ended:
			return found_words[multiplayer.get_remote_sender_id()].size() > (Globals.GUARANTEED_WORD_COUNT / 2)
		else:
			get_winner_by_word_count()
			
func get_winner_by_word_count():
	var playerOneWordCount = found_words[connected_peer_ids[0]].size()
	var playerTwoWordCount = found_words[connected_peer_ids[1]].size()
	if playerOneWordCount == playerTwoWordCount:
		var winner = randi_range(0,1)
		if winner == 0:
			playerOneWordCount = 1000
		if winner == 1:
			playerTwoWordCount = 1000
	if playerOneWordCount > playerTwoWordCount:
		_populate_big_dictionary("one")
		game_over = true
	if playerOneWordCount < playerTwoWordCount:
		_populate_big_dictionary("two")
		game_over = true

func _generate_random_words() -> Array[String]:
	var words_to_select = SERVER_WORDS_LIST.duplicate()
	# wordsearch only 9x11, can't have a word more than 10 characters long
	var all_keys = words_to_select.keys().filter(func(ele): return ele.length() <= Globals.MAX_WORD_LENGTH)
	
	var selected_words: Array[String] = []
	for i in range(min(Globals.GUARANTEED_WORD_COUNT, words_to_select.size())):
		selected_words.append(all_keys.pick_random())
	
	return selected_words
	
func get_weighted_random_letter() -> String:
	if _total_weight <= 0:
		return "X"
		
	var random_point: float = randf_range(0, _total_weight)
	for letter in Globals.LETTER_FREQUENCIES:
		random_point -= Globals.LETTER_FREQUENCIES[letter]
		if random_point <= 0:
			return letter
	return "" # Fallback
	
func generate_grid() -> void:
	grid_cells.clear()
	_word_placement_map.clear()

	# Create the 2D array structure
	grid_cells.resize(Globals.GRID_SIZE.y)
	_word_placement_map.resize(Globals.GRID_SIZE.y)
	
	# Populate the grid with words and letters
	for y in range(Globals.GRID_SIZE.y):
		grid_cells[y] = []
		grid_cells[y].resize(Globals.GRID_SIZE.x)
		_word_placement_map[y] = []
		_word_placement_map[y].resize(Globals.GRID_SIZE.x)
		for x in range(Globals.GRID_SIZE.x):
			_word_placement_map[y][x] = false
			grid_cells[y][x] = get_weighted_random_letter()

	# --- FIRST: Insert words into the grid ---
	insert_words()
	
	# --- SECOND: Populate the remaining cells with random letters and start animation ---
	for y in range(Globals.GRID_SIZE.y):
		for x in range(Globals.GRID_SIZE.x):
			var cell = grid_cells[y][x]
			if not _word_placement_map[y][x]: # If this cell is NOT occupied by a word
				cell = get_weighted_random_letter()

func insert_words() -> void:
	var words_to_place = []
	var placed_count = 0
	
	# The list of words that have been attempted and failed
	var failed_words: Array[String] = []
	
	"""
	 Keep trying until we reach the the word count we need
	 
	 When the length of words allowed are like, above 8, SOMETIMES it fails to place it after 1000 attempts and would
	 just not try another word. So I asked gemini to make another loop that handles adding another word if one fails. it added
	 a touch of complexity but still understandable.
	 I've yet to see this problem occur at words of only 6 or less length, but need to account for it!
	"""
	while placed_count < Globals.GUARANTEED_WORD_COUNT:
		# Step 1: Get a word to place
		var word_to_try: String
		var all_keys = SERVER_WORDS_LIST.keys().filter(func(ele): return ele.length() <= Globals.MAX_WORD_LENGTH)
		
		# Prevent infinite loops if all words in dictionary fail
		if all_keys.size() - failed_words.size() <= 0:
			print("All available words have been tried and failed. Exiting.")
			break

		var attempts = 0
		var word_found = false
		while not word_found and attempts < 1000:
			var picked_word = all_keys.pick_random()
			if not failed_words.has(picked_word) and not words_to_place.has(picked_word):
				word_to_try = picked_word.to_upper()
				words_to_place.append(word_to_try) # Add to our list of words for the puzzle
				word_found = true
			attempts += 1
		
		if not word_found:
			print("Could not find a new valid word to try. Exiting.")
			break

		var word_len = word_to_try.length()
		var placed_this_word = false
		
		var placement_attempts = 0
		
		# Step 2: Try to place the word
		while placement_attempts < 1000 and not placed_this_word:
			placement_attempts += 1
			
			# Random starting position
			var start_x = randi_range(0, Globals.GRID_SIZE.x - 1)
			var start_y = randi_range(0, Globals.GRID_SIZE.y - 1)
			var start_pos = Vector2i(start_x, start_y)
			
			# Random direction
			var direction_idx = randi_range(0, Globals.DIRECTIONS.size() - 1)
			var direction = Globals.DIRECTIONS[direction_idx]
			
			var can_place = true
			var cells_to_occupy: Array[Vector2i] = []
			
			for j in range(word_len):
				var current_pos = start_pos + direction * j
				
				if not (current_pos.x >= 0 and current_pos.x < Globals.GRID_SIZE.x and current_pos.y >= 0 and current_pos.y < Globals.GRID_SIZE.y):
					can_place = false
					break
				
				if _word_placement_map[current_pos.y][current_pos.x]:
					if grid_cells[current_pos.y][current_pos.x] != word_to_try[j]:
						can_place = false
						break
				
				cells_to_occupy.append(current_pos)
			
			if can_place:
				for j in range(word_len):
					var cell_pos = cells_to_occupy[j]
					grid_cells[cell_pos.y][cell_pos.x] = word_to_try[j]
					_word_placement_map[cell_pos.y][cell_pos.x] = true
				
				placed_this_word = true
				placed_count += 1
				print("Successfully placed word: ", word_to_try)
		
		if not placed_this_word:
			# If the word fails to place after 1000 attempts, mark it as failed
			# so we don't try it again, and let the outer loop pick a new one.
			print("Could not place word: ", word_to_try, " after ", placement_attempts, " attempts.")
			failed_words.append(word_to_try)
			# Do not increment placed_count, the outer loop will continue.

	# The `words_for_client` list is now filled with the words that were successfully placed
	words_for_client = words_to_place
	print("Finished placing words. Placed count: ", placed_count, " out of ", Globals.GUARANTEED_WORD_COUNT)

@rpc("any_peer", "call_local")
func process_loss():
	pass

@rpc("any_peer", "call_local")
func set_red_label(word: String, opponent_id: int, selection_path_opponent: Array):
	pass

@rpc("any_peer", "call_local")
func start_sudden_death():
	pass

@rpc("any_peer", "call_local")
func _server_ready(_information_from_server):
	pass

func _initialize(dict):
	phoenix_dictionary = dict
	var variant = dict["selected_games"][dict["current_round"]]
	if variant == "WordsearchVanilla":
		chosen_variant = 0
	if variant == "WordsearchShared":
		chosen_variant = 1
	if variant == "WordsearchHidden":
		chosen_variant = 2		
	pass

func _populate_big_dictionary(who_won):
	if who_won == "one":
		big_dictionary["Player One Score"] = 100
		big_dictionary["Player Two Score"] = 0
	if who_won == "two":
		big_dictionary["Player Two Score"] = 100
		big_dictionary["Player One Score"] = 0
	pass
