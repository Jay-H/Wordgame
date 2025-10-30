extends Control

signal time_up
signal tie

var serverhost 
var global_data
var game_paused = false
#region constant numbers
var seven_letter_bonus = 50
var eight_letter_bonus = 100
var wrong_word_penalty_player_one = 2 # needs to be two because each penalty will go up with more wrong words individually
var wrong_word_penalty_player_two = 2 # minus points for wrong word
var wrong_word_penalty_addition = 2 # added onto the minus points for wrong words each time
#endregion

#region bonus
var bonus_variant = false
var current_bonus_letter = ""
var current_bonus_time_value = 0
var current_bonus_letter_value
var player_one_bonus_passed = false
var player_two_bonus_passed = false

#endregion

#region obscurity
var obscurity_variant = false
var obscurity_score = 0
var player_one_last_obscurity_value
var player_two_last_obscurity_value
#endregion

#region wonder
var wonder_variant = false
#endregion


var big_dictionary = {}
var number_of_connected_players = 0
var player_one_id : int = 0
var player_two_id : int = 0

var possible_words_array = []
var final_letters_array = []
var found_words_array = []
var player_one_found_words_array = []
var player_two_found_words_array = []

var player_one_score = 0
var player_two_score = 0
var current_round_number = 0

var player_one_passed_word = ""
var player_two_passed_word = ""

var player_one_last_word_status = ""
var player_two_last_word_status = ""

var timeleftint = 45
var round_timer
var phoenix_dictionary

var process_pause = false

var important_information = []


func _ready():
	print(Globals.player_save_data)
	global_data = get_node("/root/GlobalData")
	round_timer = get_node(str("../../" + phoenix_dictionary["timers_node_name"]) + "/RoundTimer")
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	find_good_letters()
	if bonus_variant == true:
		current_bonus_letter = bonus_letter_chooser()
		
	#var players_array = multiplayer.get_peers()
	#player_one_id = players_array[0]
	#player_two_id = players_array[1]
	player_one_id = get_meta("userid1")
	player_two_id = get_meta("userid2")
	var parent = get_parent()
	serverhost = parent.get_parent()
	print("server host is " + str(serverhost))
	#%MainTimer.start()
	#if bonus_variant == true:
		#%BonusTimer.start()

func _process(delta):
	if round_timer.time_left < 0.5:
		if player_one_score == player_two_score:
			round_timer.start(10)
			print("TIE GAME, SUDDEN DEATH")

	if process_pause == false: # this process pause thing makes it so that the update to the big dictionary happens 2x/second minimum, also updating timer variables for sending
		process_pause = true
		await get_tree().create_timer(0.5).timeout
		timeleftint = int(round_timer.time_left)
		current_bonus_time_value = (10 - int($BonusTimer.time_left))
		rpc_id(player_one_id,"send_player_information")
		rpc_id(player_two_id,"send_player_information")
		send_player_information()
		process_pause = false

func game_starter():
	$MainTimer.start()
	if current_bonus_letter != null:
		%BonusTimer.start()
	pass

func find_good_letters():
	print("find_good_letters function running")
	# Define your specific criteria for a "good" hand
	var min_other_words_required = 25 # At least 25 OTHER words (3-6 letters)
									  # This implies the t+otal words will be >= 26 (20 + the 7-letter word)

	var chosen_letters_string = ""
	var attempts = 0
	var max_attempts = 2000 

	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var start_total_time = Time.get_ticks_msec()

	# Essential check: make sure we actually have 7-letter words loaded
	if global_data.seven_letter_words_list.is_empty():
		print("Error: No 7-letter words found in the dictionary! Cannot generate a hand with a guaranteed 7-letter word.")
		return # Abort if the 7-letter word list is empty

	while true:
		attempts += 1
		if attempts > max_attempts:
			print("Failed to find suitable letters after ", max_attempts, " attempts.")
			print("Consider relaxing 'min_other_words_required' (current: ", min_other_words_required, ") or checking your dictionary.")
			return # Exit function if max attempts reached

		# 1. Pick a random 7-letter word from the pre-filtered list
		var random_seven_word_index = rng.randi_range(0, global_data.seven_letter_words_list.size() - 1)
		var chosen_seven_word = global_data.seven_letter_words_list[random_seven_word_index]
		
		# The hand for the player is now directly the letters of this chosen 7-letter word
		chosen_letters_string = chosen_seven_word
		var shuffled_letters_array = []
			# Convert the string into an array of its characters
		for char in chosen_letters_string:
			shuffled_letters_array.append(char)
			
			# Shuffle the array
			shuffled_letters_array.shuffle()
			
			# Join the array back into a string (if you need it as a string for display/storage)
			var final_shuffled_display_string = "".join(shuffled_letters_array)
			print("Shuffled letters for display: ", final_shuffled_display_string)
		print("\n--- Attempt ", attempts, ": Testing hand from chosen 7-letter word: '", chosen_letters_string, "' ---")

		var start_check_time = Time.get_ticks_msec()

		# 2. Find ALL possible words from this hand (including the 7-letter word itself, and 3-6 letter words)
		var all_possible_words_from_hand = global_data.find_valid_words_from_letters(chosen_letters_string)

		var end_check_time = Time.get_ticks_msec()
		print("Time taken for word generation and lookup: ", (end_check_time - start_check_time) / 1000.0, " seconds")

		# 3. Check the criteria:
		#    a. We know a 7-letter word exists (it's `chosen_seven_word`).
		#    b. We need to check for at least `min_other_words_required` *additional* words (3-6 letters).

		var total_words_found = all_possible_words_from_hand.size()
		
		# The number of "other" words is the total found minus the 7-letter word we picked
		# (assuming `find_valid_words_from_letters` only returns 3+ letter words, including the 7-letter one).
		var actual_other_words_count = total_words_found - 1

		var criteria_met = (actual_other_words_count >= min_other_words_required)

		if criteria_met:
			print("SUCCESS! Found a good hand: '", chosen_letters_string, "'")
			print("Total words found (3+ letters): ", total_words_found)
			#print(all_possible_words_from_hand)
			possible_words_array = all_possible_words_from_hand
			#print("Other words (3-6 letters): ", actual_other_words_count, " (>= ", min_other_words_required, " required)")
			break # Exit the loop, we found a suitable set of letters!
		else:
			print("Hand '", chosen_letters_string, "' did not meet criteria.")
			print("Only found ", actual_other_words_count, " other words (needed ", min_other_words_required, ").")

	var end_total_time = Time.get_ticks_msec()
	print("Total time to find suitable letters (including multiple attempts): ", (end_total_time - start_total_time) / 1000.0, " seconds")

	# `chosen_letters_string` now holds the letters for the player's hand
	print("\n--- Game will start with letters: ", chosen_letters_string, " ---")
	for character in chosen_letters_string:
		final_letters_array.append(character)
		final_letters_array.shuffle()
		if final_letters_array.size() == 7:
			return final_letters_array
	
	print(final_letters_array)

func bonus_letter_chooser():
	current_bonus_time_value = 0
	%BonusTimer.start()
	var letter = global_data.alphabet[randi_range(0,25)]
	current_bonus_letter_value = global_data.SCRABBLE_POINTS[letter]
	return letter
	
func obscurity_collector(word):
	if word in GlobalData.obscurity_dictionary:
		return int((GlobalData.obscurity_dictionary[word]))
	else:
		return 0
		
func word_verifier(word): #make sure that the word is legal and not already found
	
	if word.length() < 3:
		print("word too short")
		return("word too short")
		
	if found_words_array.has(word) == true: # if the word HAS been found
			print("word already found")
			return("word already found")
			
	if global_data.is_valid_word(word): # is this a real word
		if found_words_array.has(word) == false: # if the word HAS NOT already been found
			print("valid word")
			found_words_array.append(word.to_upper())
			CSignals.all_found_words.append(word)
			if word.length() ==7:
				print("seven")
				return("long word")
			if word.length() == 8:
				print("eight")
				return("super long word")
			else:
				return("valid word")
		
		
	else:
		print("invalid word")
		return("invalid word")
		
func word_scorer(word, bonus): # this will get the score of the word, not including additions for the bonus timer or obscurity. It will also add the 7 and 8 letter bonuses
	var score = 0
	var upper_word = word.to_upper() # Ensure word is uppercase for lookup
	
	# 1. Iterate through each CHARACTER of the word string
	for letter in upper_word:
		# Look up each individual letter in the points dictionary
		if global_data.SCRABBLE_POINTS.has(letter):
			score += global_data.SCRABBLE_POINTS[letter]
			
	# 2. Check the LENGTH of the original word STRING
	if bonus:
		score += (current_bonus_time_value + current_bonus_letter_value)
	if upper_word.length() == 7:
		score += seven_letter_bonus
	if upper_word.length() == 8:
		score += eight_letter_bonus
	
	return score



@rpc("any_peer", "call_local")
func word_listener(word, bonus):
	print("word listener running")
	var client_id = multiplayer.get_remote_sender_id()
	var upper_word = word.to_upper()
	var score_to_add :int = 0
	# Call word_verifier ONCE and store the result
	var verification_status = word_verifier(word)
	var obscurity_value = obscurity_collector(word)
	print("Verification Status:   " + str(verification_status))
	# Use a match statement to handle all possible outcomes cleanly
	match verification_status:
		
		"valid word", "long word", "super long word":
			if wonder_variant:
				print("Verification Status:   " + str(verification_status))
				if verification_status == "long word" or verification_status == "super long word":
					score_to_add += 9999
					wonder_game_ender(client_id)
			if verification_status == "long word" or verification_status == "super long word":
				rpc_id(client_id,"big_word_event")
					
			if bonus: # if the bonus letter was sent we choose a new bonus letter, only if the word was valid
				score_to_add += word_scorer(upper_word, true)
				current_bonus_letter = bonus_letter_chooser() #change bonus letter AFTER getting score which needs the previous bonus letter.
				
			if not bonus:
				score_to_add += word_scorer(upper_word, false)
			var last_word_status = "long word" if verification_status == "long word" else "valid short word"
			
			if client_id == player_one_id:
				player_one_found_words_array.append(upper_word)
				player_one_score += score_to_add
				rpc_id(player_one_id, "valid_word_event")
				if obscurity_variant:
					player_one_score += obscurity_value
				player_one_last_word_status = last_word_status
				player_one_last_obscurity_value = obscurity_value
			elif client_id == player_two_id:
				player_two_found_words_array.append(upper_word)
				player_two_score += score_to_add
				rpc_id(player_two_id, "valid_word_event")
				if obscurity_variant:
					player_two_score += obscurity_value
				player_two_last_word_status = last_word_status
				player_two_last_obscurity_value = obscurity_value

		"word already found", "word too short":
			if client_id == player_one_id:
				player_one_last_word_status = verification_status
			elif client_id == player_two_id:
				player_two_last_word_status = verification_status
		"invalid word":
			if client_id == player_one_id:
				player_one_score -= wrong_word_penalty_player_one
				rpc_id(player_one_id, "wrong_word_alert", wrong_word_penalty_player_one)
				wrong_word_penalty_player_one += wrong_word_penalty_addition
				player_one_last_word_status = verification_status
			elif client_id == player_two_id:
				player_two_last_word_status = verification_status
				rpc_id(player_two_id, "wrong_word_alert", wrong_word_penalty_player_two)
				player_two_score -= wrong_word_penalty_player_two
				wrong_word_penalty_player_two += wrong_word_penalty_addition

	send_player_information()
	
	print(" P1 words: " + str(player_one_found_words_array))
	print(" P2 words: " + str(player_two_found_words_array))
	print("Player one score =  " + str(player_one_score))
	print("Player two score =  " + str(player_two_score))
	
	
			
		
@rpc("any_peer", "call_local", "reliable")		
func send_player_information():
	var playerid = multiplayer.get_remote_sender_id()
	
	big_dictionary["Player One ID"] = player_one_id
	big_dictionary["Player Two ID"] = player_two_id
	big_dictionary["All Found Words"] = found_words_array
	big_dictionary["All Found Words"].sort()	
	big_dictionary["Player One Found Words"] = player_one_found_words_array
	big_dictionary["Player Two Found Words"] = player_two_found_words_array
	big_dictionary["Letters"] = final_letters_array
	big_dictionary["Player One Last Word Status"] = player_one_last_word_status
	big_dictionary["Player Two Last Word Status"] = player_two_last_word_status
	big_dictionary["Player One Score"] = player_one_score
	big_dictionary["Player Two Score"] = player_two_score
	big_dictionary["Server Time Left"] = timeleftint 
	big_dictionary["Bonus Letter"] = current_bonus_letter
	big_dictionary["Bonus Time Value"] = current_bonus_time_value
	big_dictionary["Bonus Letter Value"] = current_bonus_letter_value
	big_dictionary["Player One Last Obscurity Value"] = player_one_last_obscurity_value
	big_dictionary["Player Two Last Obscurity Value"] = player_two_last_obscurity_value
	big_dictionary["Player One Number Of Found Words"] = player_one_found_words_array.size()
	big_dictionary["Player Two Number Of Found Words"] = player_two_found_words_array.size()
	var root = get_node("/root")
	big_dictionary["Parent"] = (root.get_child(2)).name
	rpc_id(player_one_id,"receive_player_information", big_dictionary)
	rpc_id(player_two_id,"receive_player_information", big_dictionary)

@rpc("any_peer", "call_local")
func show_obscurity_popup():
	pass

func bonus_adder():
	pass
	
@rpc("any_peer", "call_local")
func bonus_populator(bonusletter):
	pass
	

	
@rpc("authority", "call_local")
func receive_player_information(dictionary):
	pass

@rpc("any_peer", "call_local")
func found_words_populator():
	return [player_one_found_words_array, player_two_found_words_array]
	




func _on_player_connected(id):
	print("Player connected: %d" % id)
	number_of_connected_players += 1
	
	if player_one_id == 0:
		player_one_id = id
		
	if player_two_id == 0:
		player_two_id = id
	if player_one_id != 0:
		if player_two_id != 0:	
			return

func _on_player_disconnected(id):
	print("Player disconnected: %d" % id)
	queue_free()

@rpc("any_peer", "call_local")
func wrong_word_alert(amount):
	pass
	
@rpc("any_peer", "call_local")
func remote_tester():
	big_dictionary["Parent"] = get_parent()
	

	


func _on_main_timer_timeout():
	time_up.emit(null)
	print(time_up.get_name())
	print("time up on server scene")
	pass # Replace with function body.

func best_word_finder():
	
	pass
	
	
@rpc("authority", "call_local")
func wonder_game_ender(winner_user_id):
	round_timer.set_wait_time(6)
	round_timer.start()
	%BonusTimer.stop()
	var player_one_id = big_dictionary["Player One ID"]
	var player_two_id =big_dictionary["Player Two ID"]
	rpc_id(player_one_id, "send_player_information")
	rpc_id(player_two_id, "send_player_information")

	var player_one_wins
	var player_two_wins
	if winner_user_id == player_one_id:
		player_one_wins = true
		rpc_id(player_one_id, "wonder_game_ender", player_one_id)
		rpc_id(player_two_id, "wonder_game_ender", player_one_id)
	if winner_user_id == player_two_id:
		player_two_wins = true
		rpc_id(player_one_id, "wonder_game_ender", player_two_id)
		rpc_id(player_two_id, "wonder_game_ender", player_two_id)
	print("the serverhost is " + str(serverhost))
	#important_information[0]
	#serverhost.game_ender(important_information[0], important_information[1], important_information[2], important_information[3], important_information[4], player_one_wins, player_two_wins, "wonder")
	pass

@rpc("authority", "call_local")			
func big_word_event():
	pass
@rpc("authority", "call_local")			
func valid_word_event():
	pass

func _initialize(dict):
	phoenix_dictionary = dict
	var variant = dict["selected_games"][dict["current_round"]]
	if variant.contains("Bonus"):
		bonus_variant = true
	if variant.contains("Obscurity"):
		obscurity_variant = true	
	if variant.contains("Wonder"):
		wonder_variant = true		
	pass
