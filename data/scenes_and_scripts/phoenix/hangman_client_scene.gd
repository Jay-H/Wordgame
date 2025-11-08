extends Control
var my_client_id
var my_player_number
var IP_ADDRESS = "localhost"
var PORT = 7777
var game_dictionary 
var game_initialized = false

var array_of_letter_nodes = []

var reveal_letter_order_array = []
var reveal_letter_order_dictionary : Dictionary
var number_of_revealed_letters

var ephemeral_hints_variant = true

func _ready():
	
	connect_to_server()
	await get_tree().process_frame
	%GhostBox.visible = false
	await _starting_animations()
	for i in %LetterBox.get_children():
		i.visible = false
		array_of_letter_nodes.append(i)
	if ephemeral_hints_variant:
		%GhostBox.visible = true
		for i in %GhostBox.get_children():
			i.visible = false
	else:
		%GhostBox.visible = false
	
func _process(_delta):
	if game_initialized == false:
		return
	if game_initialized:
		if my_player_number == "one":
			%NextLetterTimeLeft.text = str(int(game_dictionary["player_one_time_to_new_letter"])) + " sec"
			for i in game_dictionary["player_one_revealed_letters"]:
				array_of_letter_nodes[reveal_letter_order_array[i]].text = reveal_letter_order_dictionary[reveal_letter_order_array[i]]
				
			%PlayerLastGuess.text = game_dictionary["player_one_last_guess"]
			%OpponentLastGuess.text = game_dictionary["player_two_last_guess"]
			%PlayerDelay.text = "%.2f" % game_dictionary["player_one_delay"]
			%OpponentDelay.text = "%.2f" % game_dictionary["player_two_delay"]
		if my_player_number == "two":
			%NextLetterTimeLeft.text = str(int(game_dictionary["player_two_time_to_new_letter"])) + " sec"
			for i in game_dictionary["player_one_revealed_letters"]:
				array_of_letter_nodes[reveal_letter_order_array[i]].text = reveal_letter_order_dictionary[reveal_letter_order_array[i]]
			%OpponentLastGuess.text = game_dictionary["player_one_last_guess"]
			%PlayerLastGuess.text = game_dictionary["player_two_last_guess"]	
			%OpponentDelay.text = "%.2f" % game_dictionary["player_one_delay"]
			%PlayerDelay.text = "%.2f" % game_dictionary["player_two_delay"]				
	
func _initialize(dict):
	pass


func _starting_animations():
	
	for i in [%ParticipantHBox, %HangmanTextEntry, %LetterBox, %NextLetterTimerTitle, %NextLetterTimeLeft]:
		i.visible = false
	for i in [%ParticipantHBox, %HangmanTextEntry, %LetterBox, %NextLetterTimerTitle, %NextLetterTimeLeft]:
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
		for a in range(game_dictionary["word_to_find"].length()):
			%LetterBox.get_child(a).visible = true
			%LetterBox.get_child(a).text = "_"
			if ephemeral_hints_variant:
				%GhostBox.get_child(a).visible = true
				%GhostBox.get_child(a).text = "_"
@rpc("authority", "call_local", "reliable")
func _guess_client_to_server(guess):
	pass

@rpc("authority", "call_local", "reliable")
func _initial_dictionary_server_to_client(dictionary):
	game_dictionary = dictionary
	game_initialized = true
	if my_client_id == game_dictionary["player_one_id"]:
		my_player_number = "one"
	else:
		my_player_number = "two"
	reveal_letter_order_array = game_dictionary["reveal_letter_order_array"]
	reveal_letter_order_dictionary = game_dictionary["reveal_letter_order_dictionary"]
	for i in range(game_dictionary["word_to_find"].length()):
		%LetterBox.get_child(i).visible = true
		%LetterBox.get_child(i).text = "_"
		if ephemeral_hints_variant:
			%GhostBox.get_child(i).visible = true
			%GhostBox.get_child(i).text = "_"
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


func _on_hangman_text_entry_pressed(word) -> void:
	_ephemeral_hint(word)
	rpc_id(1, "_send_word_to_server", word)
	pass # Replace with function body.

@rpc("authority", "call_local", "reliable")
func _send_word_to_server(word):
	pass


#this function reveals one of the letters that is not yet revealed if you guess a word with a correct letter in that same slot.
#the word guessed has to be same length as the word you're meant to find for this to work.

func _ephemeral_hint(word): 
	

	
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
