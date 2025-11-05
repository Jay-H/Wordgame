extends Control
var my_client_id
var my_player_number
var IP_ADDRESS = "localhost"
var PORT = 7777
var game_dictionary 
var game_initialized = false

var array_of_letter_nodes = []
var reveal_letter_order_array = []
var reveal_letter_order_dictionary :Dictionary

func _ready():
	connect_to_server()
	for i in %LetterBox.get_children():
		i.visible = false
		array_of_letter_nodes.append(i)
	pass
	
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
		if my_player_number == "two":
			%NextLetterTimeLeft.text = str(int(game_dictionary["player_two_time_to_new_letter"])) + " sec"
			for i in game_dictionary["player_one_revealed_letters"]:
				array_of_letter_nodes[reveal_letter_order_array[i]].text = reveal_letter_order_dictionary[reveal_letter_order_array[i]]
			%OpponentLastGuess.text = game_dictionary["player_one_last_guess"]
			%PlayerLastGuess.text = game_dictionary["player_two_last_guess"]	
				
	
func _initialize(dict):
	pass


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
	
	rpc_id(1, "_send_word_to_server", word)
	pass # Replace with function body.

@rpc("authority", "call_local", "reliable")
func _send_word_to_server(word):
	pass
