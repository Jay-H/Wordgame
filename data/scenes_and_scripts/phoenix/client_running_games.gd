extends Control
@onready var main_menu = get_parent()
@onready var timers_node = "res://data/scenes_and_scripts/phoenix/timers.tscn"
@onready var matches_node = "res://data/scenes_and_scripts/phoenix/matches_node.tscn"

var match_information_dictionary = {}
var current_timer_node
var current_match_node
var my_player_number


func _process(_delta):
	pass

@rpc("authority", "call_remote", "reliable")	
func _client_match_informer(dict):
	match_information_dictionary = dict
	var match_node = (load(matches_node)).instantiate()
	var timers_instance = (load(timers_node)).instantiate()
	
	var my_info
	var opponent_info
	match_node.name = dict["match_node_name"]
	timers_instance.name = dict["timers_node_name"]
	add_child(match_node)
	add_child(timers_instance)
	var mmm = get_node(str(dict["match_node_name"]))
	mmm.set_anchors_preset(Control.PRESET_FULL_RECT)
	print(match_node)
	if dict["player_one_dictionary"]["email"] == main_menu.firebase_email:
		my_player_number = "one"
		my_info = dict["player_one_dictionary"]
		opponent_info = dict["player_two_dictionary"]
	else:
		my_player_number = "two"
		my_info = dict["player_two_dictionary"]
		opponent_info = dict["player_one_dictionary"]
	main_menu._match_found_screen(my_info, opponent_info) # this sends to mainmenu to change the found match screen
	if my_player_number == "one":
		rpc_id(1, "_match_runner", dict)
	pass

@rpc("authority", "call_remote", "reliable")	
func _match_runner(dict):
	pass



@rpc("authority", "call_remote", "reliable")	
func _show_rules(dict):
	if dict["current_round"] == 0:
		await main_menu._fade_out_match_found_screen()
		await main_menu._show_rules_screen(dict["selected_games"][dict["current_round"]], dict)
	if dict["current_round"] > 0:
		await main_menu._fade_out_score_screen(dict)
		await main_menu._show_rules_screen(dict["selected_games"][dict["current_round"]], dict)
	if my_player_number == "one":
		rpc_id(1, "_match_runner", dict)

@rpc("authority", "call_remote", "reliable")	
func _start_game(dict):
	if main_menu.opponent_disconnected == false:
		await main_menu._fade_out_rules_screen()
		var game
		var match_container = get_node(str(dict["match_node_name"]))
		if match_container != null:
			if match_container.get_children().size() == 1:
				return
		if dict["selected_games"][dict["current_round"]].contains("Scramble"):
			game = load("res://data/scenes_and_scripts/scramble/scramble_client_scene.tscn")
		if dict["selected_games"][dict["current_round"]].contains("Wordsearch"):
			game = load("res://data/scenes_and_scripts/wordsearch/WordSearch.tscn")
		if dict["selected_games"][dict["current_round"]].contains("Hangman"):
			game = load("res://data/scenes_and_scripts/phoenix/hangman_client_scene.tscn")
		var game_instance = game.instantiate()
		game_instance._initialize(dict)
		#game_instance.name = str(dict["player_one_dictionary"]["email"]) + str(dict["player_two_dictionary"]["email"]) 
		current_match_node = game_instance
		if my_player_number == "one":
			rpc_id(1, "_match_runner", dict)	
		
		if match_container != null:
			match_container.add_child(game_instance)
		pass

@rpc("authority", "call_remote", "reliable")	
func _end_game(dict):
	var big_dictionary = current_match_node.big_dictionary
	await current_match_node.fade_out()
	current_match_node.queue_free()
	await main_menu._score_screen(dict, big_dictionary) # big_dictionary is the dictionary from the individual game itself(scramble, etc), containing scores, etc
	if my_player_number == "one":
		rpc_id(1, "_match_runner", dict)
	
	pass

@rpc("authority", "call_remote", "reliable")	
func _end_match(dict):
	printerr("client side _end_match run")
	if dict["end_by_disconnection"]:
		for i in get_children():
			i.queue_free()
		await main_menu._match_over_screen(dict)
		
		return
	for i in get_children():
		i.queue_free()

		
		
	
	await main_menu._fade_out_score_screen(dict)
	main_menu._match_over_screen(dict)
	pass


@rpc("authority", "call_remote", "reliable")	
func _skip_rules_pressed(dict, firebase_id): # this is from the score screen -- > main menu by signal --> to here by direct call
	rpc_id(1, "_skip_rules_pressed", dict, firebase_id)
	pass

@rpc("authority", "call_remote", "reliable")
func _on_opponent_disconnected(dict):
	print("_client_side_on_opponent_disconnected_run")
	main_menu.opponent_disconnected = true
	main_menu._reconnect_function(1,1)
	pass
