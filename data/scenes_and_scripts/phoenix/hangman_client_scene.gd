extends Control
var debug_mode = false
var my_client_id
var my_player_number
var opponent_player_number
var IP_ADDRESS = "localhost"
var PORT = 7777
var game_dictionary 
var game_initialized = false
var initial_sequence_completed = false
var big_dictionary
var array_of_letter_nodes = []

var reveal_letter_order_array = []
var reveal_letter_order_dictionary : Dictionary
var number_of_revealed_letters

var ephemeral_hints_variant = false
var chaos_variant = false #3 chaos options. 1. has ephemeral hints. 2. has shared clues so any revealed letters are revealed to both players
#the 3. is only chaos variant, this means your revealed letters only shown to you.
var chaos_shared_clues = false
var turn_based_variant = false
var delay_variant = false


var turn_based_known_indices = []
var chaos_known_indices = [] # for use with the basic chaos variant only
var your_turn = false
var your_turn_timer
var opponent_turn_timer


func _ready():
	%WinBlocker.visible = false
	%NextLetterTimeLeft.visible = false
	%NextLetterTimerTitle.visible = false
	my_client_id = multiplayer.get_unique_id()
	for i in [%ParticipantHBox, %HangmanTextEntry, %NextLetterTimerTitle, %NextLetterTimeLeft]:
		i.visible = false
	if turn_based_variant:
		%TurnTimerLabel.visible = true
	else:
		%TurnTimerLabel.visible = false
	if debug_mode:
		connect_to_server()
	%GhostBox.visible = false
	%LetterBox.visible = false
	if not delay_variant:
		%PlayerDelayTitle.visible = false
		%PlayerDelay.visible = false
		%OpponentDelay.visible = false
		%OpponentDelayTitle.visible = false
	%HangmanTextEntry.text_submitted.connect(_on_hangman_text_entry_text_submitted.bind(%HangmanTextEntry.text))
func _initial_sequence():
	if my_player_number == "one":
		%PlayerName.text = game_dictionary["player_one_dictionary"]["username"]
		%OpponentName.text = game_dictionary["player_two_dictionary"]["username"]	
		%PlayerPic.setup(GlobalData.profile_pics[game_dictionary["player_one_dictionary"]["profilepic"]])
		%OpponentPic.setup(GlobalData.profile_pics[game_dictionary["player_two_dictionary"]["profilepic"]])	
	if my_player_number == "two":
		%PlayerPic.setup(GlobalData.profile_pics[game_dictionary["player_two_dictionary"]["profilepic"]])
		%OpponentPic.setup(GlobalData.profile_pics[game_dictionary["player_one_dictionary"]["profilepic"]])	
		%PlayerName.text = game_dictionary["player_two_dictionary"]["username"]
		%OpponentName.text = game_dictionary["player_one_dictionary"]["username"]	
	await get_tree().process_frame
	await _starting_animations()
	var tween = create_tween()
	%LetterBox.modulate = Color.TRANSPARENT
	%GhostBox.modulate = Color.TRANSPARENT
	tween.tween_property(%LetterBox, "modulate", Color.WHITE, 1)
	tween.tween_property(%GhostBox, "modulate", Color.WHITE, 1)
	%LetterBox.visible = true
	for i in %LetterBox.get_children():
		i.visible = false
		array_of_letter_nodes.append(i)
	if ephemeral_hints_variant:
		%GhostBox.visible = true
		for i in %GhostBox.get_children():
			i.visible = false
	else:
		%GhostBox.visible = false
	for i in range(game_dictionary["word_to_find"].length()):
		%LetterBox.get_child(i).visible = true
		%LetterBox.get_child(i).text = "_"
		if ephemeral_hints_variant:
			%GhostBox.get_child(i).visible = true
			%GhostBox.get_child(i).text = "_"
	initial_sequence_completed = true
	if delay_variant:
		%NextLetterTimeLeft.visible = true
		%NextLetterTimerTitle.visible = true
	else:
		%NextLetterTimeLeft.visible = false
		%NextLetterTimerTitle.visible = false		
	
func _process(_delta):
	
	if game_dictionary != null and game_initialized == false:
		_initial_dictionary_server_to_client(game_dictionary)
		game_initialized = true
	big_dictionary = game_dictionary
	
	if game_initialized == false:
		return
	if game_initialized:
		if not initial_sequence_completed:
			_initial_sequence()
			initial_sequence_completed = true
			
		if my_player_number == "one":

			%NextLetterTimeLeft.text = str(int(game_dictionary["player_one_time_to_new_letter"])) + " sec"

			for i in game_dictionary["player_one_revealed_letters"]:
				array_of_letter_nodes[reveal_letter_order_array[i]].text = reveal_letter_order_dictionary[reveal_letter_order_array[i]]
			if turn_based_variant:
				if game_dictionary["which_player_turn"] == "one":
					your_turn = true
				else:
					your_turn = false	
			%PlayerLastGuess.text = game_dictionary["player_one_last_guess"]
			%OpponentLastGuess.text = game_dictionary["player_two_last_guess"]
			%PlayerDelay.text = "%.2f" % game_dictionary["player_one_delay"]
			%OpponentDelay.text = "%.2f" % game_dictionary["player_two_delay"]
			
		if my_player_number == "two":

			%NextLetterTimeLeft.text = str(int(game_dictionary["player_two_time_to_new_letter"])) + " sec"

			for i in game_dictionary["player_one_revealed_letters"]:
				array_of_letter_nodes[reveal_letter_order_array[i]].text = reveal_letter_order_dictionary[reveal_letter_order_array[i]]
			if turn_based_variant:
				if game_dictionary["which_player_turn"] == "two":
					your_turn = true
				else:
					your_turn = false	
			%OpponentLastGuess.text = game_dictionary["player_one_last_guess"]
			%PlayerLastGuess.text = game_dictionary["player_two_last_guess"]	
			%OpponentDelay.text = "%.2f" % game_dictionary["player_one_delay"]
			%PlayerDelay.text = "%.2f" % game_dictionary["player_two_delay"]				
		if turn_based_variant:
			if your_turn:
				%TurnTimerLabel.text = str(int(game_dictionary["player_" + my_player_number + "_turn_time"]))
				%TurnTimerLabel.add_theme_color_override("font_color", Color.DARK_GREEN)
				%HangmanTextEntry.placeholder_text = "START TYPING!"
				%HangmanTextEntry.editable = true
				%HangmanTextEntry.add_theme_color_override("caret_color", Color.WHITE)
			if not your_turn:
				%TurnTimerLabel.text = str(int(game_dictionary["player_" + opponent_player_number + "_turn_time"]))
				%TurnTimerLabel.add_theme_color_override("font_color", Color.FIREBRICK)
				%HangmanTextEntry.placeholder_text = "Opponent's Turn!"
				%HangmanTextEntry.text = ""
				%HangmanTextEntry.editable = false
				%HangmanTextEntry.add_theme_color_override("caret_color", Color.TRANSPARENT)
				if game_dictionary["last_turn_ended_by_timeout"] == true:
					%HangmanTextEntry._took_too_long_text()
					%HangmanTextEntry.editable = false
					%HangmanTextEntry.add_theme_color_override("caret_color", Color.TRANSPARENT)
		if turn_based_variant:
			for i in game_dictionary["turn_based_indices_found"]:
				if i not in turn_based_known_indices:
					await _turn_based_reveal_letter(i)
					turn_based_known_indices.append(i)
				else:
					array_of_letter_nodes[i].text = reveal_letter_order_dictionary[i]
		if chaos_variant and chaos_shared_clues:
			for i in game_dictionary["chaos_shared_indices_found"]:
				if i not in turn_based_known_indices:
					await _turn_based_reveal_letter(i)
					turn_based_known_indices.append(i)
				else:
					array_of_letter_nodes[i].text = reveal_letter_order_dictionary[i]
		if chaos_variant and not chaos_shared_clues and not ephemeral_hints_variant:
			pass
			
			
func _initialize(dict):
	_set_variants(dict["selected_games"][dict["current_round"]])
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
func _starting_animations():
	var array_to_animate = [%ParticipantHBox, %HangmanTextEntry]
	if delay_variant:
		array_to_animate.append(%NextLetterVBox)
	
	for i in array_to_animate:
		i.visible = true
		var target_position = i.position
		var initial_position = target_position
		initial_position.y += 3000
		i.position = initial_position
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(i, "position", target_position, 0.5)
		await tween.finished

@rpc("authority", "call_local", "reliable")
func _guess_client_to_server(guess):
	pass

@rpc("authority", "call_local", "reliable")
func _initial_dictionary_server_to_client(dictionary):
	game_dictionary = dictionary
	game_initialized = true
	if my_client_id == game_dictionary["player_one_id"]:
		my_player_number = "one"
		opponent_player_number = "two"
		
	else:
		my_player_number = "two"
		opponent_player_number = "one"
	reveal_letter_order_array = game_dictionary["reveal_letter_order_array"]
	reveal_letter_order_dictionary = game_dictionary["reveal_letter_order_dictionary"]

	pass

@rpc("authority", "call_local", "reliable")
func _send_dictionary_server_to_client(dictionary):
	game_dictionary = dictionary
	pass



func connect_to_server():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(IP_ADDRESS, PORT)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		my_client_id = multiplayer.get_unique_id()
		print(my_client_id)
		if %LoginScreen != null:
			%LoginScreen.connected_to_server = true
	else:
		print(error)



@rpc("authority", "call_local", "reliable")
func _send_word_to_server(word):
	pass


#this function reveals one of the letters that is not yet revealed if you guess a word with a correct letter in that same slot.
#the word guessed has to be same length as the word you're meant to find for this to work.

func _ephemeral_hint(word): 
	if not ephemeral_hints_variant:
		return

	
	var word_to_find = game_dictionary["word_to_find"]
	if word_to_find.length() != word.length(): # no benefit if the word you submit is a different length than the word to find
		return
	var indices_found = []
	for i in word.length():
		var letter = word[i]
		if letter == word_to_find[i]:
			if array_of_letter_nodes[i].text != "_":
				pass
			if array_of_letter_nodes[i].text == "_":
				indices_found.append(i)
	
	if indices_found.size() > 0:
		var letter_index_to_reveal = indices_found[randi() % indices_found.size()]
		var ghost_letter = %GhostBox.get_child(letter_index_to_reveal)
		ghost_letter.text = word_to_find[letter_index_to_reveal]
		
		print(ghost_letter.text)
		var ghost_letter_particles = load("res://data/scenes_and_scripts/particles/blue_blur_particles.tscn").instantiate()
		ghost_letter_particles.position = ghost_letter.global_position
		ghost_letter_particles.position += ghost_letter.size/2
		ghost_letter_particles.modulate.a = 0.12
		var ghost_letter_particles_GPU = ghost_letter_particles.get_child(0)
		%CanvasLayer.add_child(ghost_letter_particles)
		ghost_letter.modulate.a = 0
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(ghost_letter, "modulate", Color.WHITE, 0.25)
		tween.chain().tween_method(func(a):
			ghost_letter.modulate.a = ghost_letter.modulate.a * randf_range(0.9, 1.1)
			ghost_letter_particles.modulate.a = ghost_letter.modulate.a * 0.25
			, 0.25, 0.75, 1).set_trans(Tween.TRANS_SINE)
		tween.chain().tween_property(ghost_letter, "modulate", Color.TRANSPARENT, 0.5)
		tween.parallel().tween_property(ghost_letter_particles, "modulate", Color.TRANSPARENT, 0.5)
		tween.parallel().tween_property(ghost_letter_particles_GPU, "emitting", false, 0.5)
		await tween.finished
		ghost_letter_particles.queue_free()
		ghost_letter.text = "_"		

		
	pass

func _turn_based_reveal_letter(index):

	var tween = create_tween()
	var node = array_of_letter_nodes[index]
	node.modulate = Color.TRANSPARENT
	node.scale = Vector2.ZERO
	node.pivot_offset = node.size/2
	node.text = reveal_letter_order_dictionary[index]
	tween.tween_property(node, "scale", Vector2(1,1), 0.5)
	tween.parallel().tween_property(node, "modulate", Color.WHITE, 0.5)
	await tween.finished
	pass

func fade_out():
	%TextureRect.z_index = 7
	%WinningWord.text = str(game_dictionary["word_to_find"])
	if game_dictionary["Player One Score"] > game_dictionary["Player Two Score"]:
		%WinningWordTitle.text = game_dictionary["player_one_dictionary"]["username"] + "\n" + "Found"
	else:
		%WinningWordTitle.text = game_dictionary["player_two_dictionary"]["username"] + "\n" + "Found"
	await %WinBlocker._appear()
	%ParticipantHBox.visible = false
	%NextLetterTimeLeft.visible = false
	%NextLetterTimerTitle.visible = false
	%TurnTimerLabel.visible = false
	%HangmanTextEntry.visible = false
	var tween = create_tween()
	tween.tween_property(%CanvasModulate, "color", Color.TRANSPARENT, 1)
	await tween.finished


func _on_hangman_text_entry_text_submitted(word: String) -> void:
	word = word.to_upper()
	%HangmanTextEntry.text = ""
	
	if word == game_dictionary["word_to_find"]:
		%LetterBox.visible = false
		%GhostBox.visible = false
		rpc_id(1, "_send_word_to_server", word)
		return
	if not GlobalData.is_valid_word(word):
		print("not a valid word bro")
		%HangmanTextEntry.placeholder_text = "INVALID!"
		await get_tree().create_timer(1).timeout
		%HangmanTextEntry.placeholder_text = "START TYPING!"
		return
	await get_tree().create_timer(0.25).timeout
	%HangmanTextEntry.grab_click_focus()
	%HangmanTextEntry.grab_focus()
	_ephemeral_hint(word)
	if chaos_variant and not ephemeral_hints_variant and not chaos_shared_clues:
		if word.length() != game_dictionary["word_to_find"].length():
			return
		else: 
			for i in word.length():
				if word[i] == game_dictionary["word_to_find"][i]:
					if i not in chaos_known_indices:
						await _turn_based_reveal_letter(i)
						chaos_known_indices.append(i)
				
					
	rpc_id(1, "_send_word_to_server", word)
	pass # Replace with function body.
