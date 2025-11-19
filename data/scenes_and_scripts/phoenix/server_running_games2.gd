extends Control

@onready var serverhost = get_parent()
signal match_ended(dict)
@onready var Database = get_node("/root/Firebase/Database")
var players_looking_for_match = []
var matched_players = []
var timers_scene = "res://data/scenes_and_scripts/phoenix/timers.tscn"
var round_time = 40
var match_found_time = 3
var rules_time = 5
var score_time = 3
var skip_dict = {}
var disconnected_limbo_firebase_ids = []
var disconnected_scene_dictionary = {}
var disconnected_dictionaries = []
var connected_limbo_peer_ids = []
var connected_limbo_firebase_ids = []

func _ready():
	serverhost.player_reconnected.connect(_reconnect_handler)

func _process(_delta):
	if players_looking_for_match.size() == 2: # this part is responsible for taking two players from the players looking for match array and passing them to new match function
		matched_players.append(players_looking_for_match[0])
		matched_players.append(players_looking_for_match[1])
		players_looking_for_match = []
		_new_match(matched_players)
		matched_players = []
	
	pass

#this function takes the two matched players, and sets up a dictionary below with all the pertinent match info
#it then sends this all through an rpc call to the client_running_games
func _new_match(matched_players):
	
	
	var player_one_peer_id = matched_players[0]
	var player_two_peer_id = matched_players[1]
	var player_one_firebase_id = serverhost.peerid_to_firebaseid_dictionary[player_one_peer_id]
	var player_two_firebase_id = serverhost.peerid_to_firebaseid_dictionary[player_two_peer_id]
	var player_one_dictionary = serverhost.legendary_dictionary[player_one_peer_id]
	var player_two_dictionary = serverhost.legendary_dictionary[player_two_peer_id]
	var match_node = Control.new()
	var timers_node = (load(timers_scene)).instantiate()
	
	add_child(match_node)
	add_child(timers_node)
	match_node.name = player_one_dictionary["email"] + player_two_dictionary["email"] + "matches"
	timers_node.name = player_one_dictionary["email"] + player_two_dictionary["email"] + "timers"
	var games_array = _game_selector()
	var match_info_dictionary = { # this forms the dictionary of all the information that will be needed for players about each other and the games.
	"player_one_peer_id": player_one_peer_id, "player_two_peer_id": player_two_peer_id, "player_one_firebase_id": player_one_firebase_id,
	"player_two_firebase_id": player_two_firebase_id, "player_one_dictionary": player_one_dictionary, "player_two_dictionary": player_two_dictionary,
	"match_node_name": match_node.name, "timers_node_name": timers_node.name, "selected_games": games_array, "match_stage": "initial", "current_round": 0,
	"match_winner": "", "rules_skipped": false, "end_by_disconnection": false, "p1_reconnection_timer_length": 10, "p2_reconnection_timer_length": 10
	}
	#serverhost.running_matches.append(str(match_info_dictionary["match_node_name"]))
	serverhost.running_matches.append(match_info_dictionary)
	rpc_id(serverhost.firebaseid_to_peerid_dictionary[match_info_dictionary["player_one_firebase_id"]], "_client_match_informer", match_info_dictionary)
	rpc_id(serverhost.firebaseid_to_peerid_dictionary[match_info_dictionary["player_two_firebase_id"]], "_client_match_informer", match_info_dictionary)
	#rpc_id(player_one_peer_id, "_client_match_informer", match_info_dictionary)
	#rpc_id(player_two_peer_id, "_client_match_informer", match_info_dictionary)
	
	
@rpc("any_peer", "call_remote", "reliable")	
func _client_match_informer(match_info_dictionary):
	pass


 #this function will keep track of the stages of the match between two players, and run the necessary functions to keep things moving
#it is called from the client identified as player one exclusively to keep the stages of the game progressing
@rpc("any_peer", "call_remote", "reliable")	
func _match_runner(dict):
	if dict["end_by_disconnection"] == false:
		if dict["match_stage"] == "initial": # we use the match_stage dictionary entry to keep track of what stage of the game they are in
			var match_found_timer = get_node(str(dict["timers_node_name"]) + "/MatchFoundTimer")
			match_found_timer.start(match_found_time)
			await match_found_timer.timeout
			if dict["player_one_dictionary"]["auto_skip_rules"] == true and dict["player_two_dictionary"]["auto_skip_rules"] == true:
				dict["rules_skipped"] = true
			elif dict["player_one_dictionary"]["auto_skip_rules"] == true and dict["player_two_dictionary"]["auto_skip_rules"] == false:
				skip_dict[str(dict["match_node_name"])] = [dict["player_one_firebase_id"]]
				
			elif dict["player_one_dictionary"]["auto_skip_rules"] == false and dict["player_two_dictionary"]["auto_skip_rules"] == true:
				skip_dict[str(dict["match_node_name"])] = [dict["player_two_firebase_id"]]			
			else:
				pass
			dict["match_stage"] = "rules"
			rpc_id(serverhost.firebaseid_to_peerid_dictionary[dict["player_one_firebase_id"]], "_show_rules", dict)
			rpc_id(serverhost.firebaseid_to_peerid_dictionary[dict["player_two_firebase_id"]], "_show_rules", dict)

			return
		if dict["match_stage"] == "rules":
			
			var rules_timer = get_node(str(dict["timers_node_name"]) + "/RulesTimer")
			if dict["rules_skipped"]:
				
				rules_timer.start(0.5)
			else:
				rules_timer.start(rules_time)
		
			await rules_timer.timeout
	
	
			dict["match_stage"] = "game"


			_start_game(dict)

			var round_timer = get_node(str(dict["timers_node_name"]) + "/RoundTimer")
			round_timer.start(999)

			rpc_id(serverhost.firebaseid_to_peerid_dictionary[dict["player_one_firebase_id"]], "_start_game", dict)
			rpc_id(serverhost.firebaseid_to_peerid_dictionary[dict["player_two_firebase_id"]], "_start_game", dict)
			#rpc_id(dict["player_one_peer_id"], "_start_game", dict)
			#rpc_id(dict["player_two_peer_id"], "_start_game", dict)
			if dict["player_one_dictionary"]["auto_skip_rules"] == true and dict["player_two_dictionary"]["auto_skip_rules"] == true:
				dict["rules_skipped"] = true # this is to reset it for the next rules screen
			else:
				dict["rules_skipped"] = false		
			return
		if dict["match_stage"] == "game":
			var round_timer = get_node(str(dict["timers_node_name"]) + "/RoundTimer")
			if dict["selected_games"][dict["current_round"]].contains("Hangman"): # because hangman doesn't work the same way as other games
				round_timer.start(999)
				var match_container = get_node(str(dict["match_node_name"])) 
				var game = match_container.get_child(0)
				game.game_over.connect(func(): # this will make it so that the round ends when someone wins in hangman
					round_timer.start(0.5))
			else:
				round_timer.start(round_time)
			###### I MOVED  dict["match_stage"] = "score" from HERE WATCH OUT
			await round_timer.timeout
			dict["match_stage"] = "score"
	
			var winner = _end_game(dict)
			var string = "round" + str(dict["current_round"] + 1) + "winner" # this is to register into the dictionary who won each round.
			dict[string] = winner
		
			
			rpc_id(serverhost.firebaseid_to_peerid_dictionary[dict["player_one_firebase_id"]], "_end_game", dict)
			rpc_id(serverhost.firebaseid_to_peerid_dictionary[dict["player_two_firebase_id"]], "_end_game", dict)
			#rpc_id(dict["player_one_peer_id"], "_end_game", dict)
			#rpc_id(dict["player_two_peer_id"], "_end_game", dict)
			return
		if dict["match_stage"] == "score":
			var score_timer = get_node(str(dict["timers_node_name"]) + "/ScoreTimer") 
			score_timer.start(score_time)
			dict["current_round"] += 1
			dict["match_stage"] = "rules"
			await score_timer.timeout
			if dict["current_round"] == 2 and dict["round1winner"] == dict["round2winner"]: # if someone wins the first two games
				dict["match_stage"] == "ending"
				_end_match_prefunction(dict)
				return
			if dict["current_round"] == 3:
				dict["match_stage"] == "ending"
				_end_match_prefunction(dict)
				return
			rpc_id(serverhost.firebaseid_to_peerid_dictionary[dict["player_one_firebase_id"]], "_show_rules", dict)
			rpc_id(serverhost.firebaseid_to_peerid_dictionary[dict["player_two_firebase_id"]], "_show_rules", dict)
			#rpc_id(dict["player_one_peer_id"], "_show_rules", dict)
			#rpc_id(dict["player_two_peer_id"], "_show_rules", dict)		
			return
		return


@rpc("any_peer", "call_remote", "reliable")	
func _show_rules(dict):
	pass
	
@rpc("authority", "call_remote", "reliable")	
func _start_game(dict):
	var game_already_spawned
	var game
	var match_container = get_node(str(dict["match_node_name"]))
	if match_container.get_children().size() == 1:
		return
	if dict["selected_games"][dict["current_round"]].contains("Scramble"):
		game = load("res://data/scenes_and_scripts/scramble/scramble_server_scene.tscn")
	if dict["selected_games"][dict["current_round"]].contains("Wordsearch"):
		game = load("res://data/scenes_and_scripts/wordsearch/WsServer.tscn")
	if dict["selected_games"][dict["current_round"]].contains("Hangman"):
		game = load("res://data/scenes_and_scripts/phoenix/hangman_server_scene.tscn")	
	var game_instance = game.instantiate()
	game_instance._initialize(dict)
	game_instance.set_meta("userid1", dict["player_one_peer_id"])
	game_instance.set_meta("userid2", dict["player_two_peer_id"])
	#game_instance.name = str(dict["player_one_dictionary"]["email"]) + str(dict["player_two_dictionary"]["email"]) 

	
	
	match_container.add_child(game_instance)
	
	pass

@rpc("any_peer", "call_remote", "reliable")
func _end_game(dict):
	var match_container = get_node(str(dict["match_node_name"]))
	var current_game = match_container.get_child(0)

	var big_dictionary = current_game.big_dictionary
	var winner = _determine_winner(dict, big_dictionary)
	current_game.queue_free()
	return winner
	
	pass
	
func _game_selector(): 
	
	# this function will return three games at random from Globals.game_types (while preventing duplicates)
	var games_array = serverhost.selected_game_list.duplicate()
	#var games_array = ["HangmanChaosShared","HangmanChaosShared","HangmanChaosShared"]
	#var games_array = ["ScrambleBonus","ScrambleBonus","ScrambleBonus"]
	var games_array_size = games_array.size()
	var game_one = games_array[(randi_range(0, (games_array_size - 1)))]
	games_array.erase(game_one)
	var game_two = games_array[(randi_range(0, (games_array_size - 2)))]
	games_array.erase(game_two)
	var game_three = games_array[(randi_range(0, (games_array_size - 3)))]
	return [game_one, game_two, game_three]
	pass

func _determine_winner(dict, big_dictionary):
	var winner
	
	var player_one_score = big_dictionary["Player One Score"]
	var player_two_score = big_dictionary["Player Two Score"]
	if player_one_score > player_two_score:
		winner = "one"
	if player_one_score < player_two_score:
		winner = "two"
	return winner


# this prefunction is to get the "new dictionary" which is after the serverhost script has done all the tabulation
# regarding level, rank, experience etc. This is important to give back to the client so that it can populate it's match over screen
# the match_ended signal is emitted, goes to server host for processing and syncing to firebase
# then server host called the _end_match function which rpcs to the client to signal it's over, crucially with the new dict
func _end_match_prefunction(dict):  
	matched_players.erase(dict["player_one_peer_id"])
	matched_players.erase(dict["player_two_peer_id"])
	var match_container = get_node(str(dict["match_node_name"]))
	var timers_node = get_node(str(dict["timers_node_name"]))
	match_container.queue_free()
	timers_node.queue_free()
	_determine_match_winner(dict)	

	match_ended.emit(dict)
	pass
	
@rpc("any_peer", "call_remote", "reliable")	
func _end_match(dict):
	rpc_id(serverhost.firebaseid_to_peerid_dictionary[dict["player_one_firebase_id"]], "_end_match", dict)
	rpc_id(serverhost.firebaseid_to_peerid_dictionary[dict["player_two_firebase_id"]], "_end_match", dict)

	for i in serverhost.running_matches:
		if i["match_node_name"] == dict["match_node_name"]:
			serverhost.running_matches.erase(i)
	pass


func _determine_match_winner(dict):
	if dict["round1winner"] == dict["round2winner"]:
		dict["match_winner"] = dict["round1winner"]
		return
	if dict["round1winner"] == dict["round3winner"]:
		dict["match_winner"] = dict["round1winner"]
		return
	if dict["round2winner"] == dict["round3winner"]:
		dict["match_winner"] = dict["round2winner"]
		return
	


@rpc("any_peer", "call_remote", "reliable")	
func _skip_rules_pressed(dict, firebase_id):

	if not skip_dict.has(str(dict["match_node_name"])):
		skip_dict[str(dict["match_node_name"])] = []
	var this_firebase_id = firebase_id
	if skip_dict[str(dict["match_node_name"])].size() == 1:
		dict["rules_skipped"] = true
	else:
		skip_dict.append(this_firebase_id)
	
	_match_runner(dict)
	
	

	
	pass


func _reconnect_handler(fbid):
	var reconnecting_player_firebase_id = fbid
	var connected_player_firebase_id
	var connected_player_peer_id
	var reconnecting_player_peer_id
	var timers_node
	var match_node
	var reconnection_timer
	for i in disconnected_dictionaries:
		if i["player_one_firebase_id"] or i["player_two_firebase_id"] == fbid:
			if i["player_one_firebase_id"] == fbid:
				connected_player_firebase_id = i["player_two_firebase_id"]
				connected_player_peer_id = serverhost.firebaseid_to_peerid_dictionary[connected_player_firebase_id]
				reconnecting_player_peer_id = serverhost.firebaseid_to_peerid_dictionary[reconnecting_player_firebase_id]
				timers_node = get_node(str(i["timers_node_name"]))
				match_node = get_node(str(i["match_node_name"]))
				
			else:
				connected_player_firebase_id = i["player_one_firebase_id"]
				connected_player_peer_id = serverhost.firebaseid_to_peerid_dictionary[connected_player_firebase_id]
				reconnecting_player_peer_id = serverhost.firebaseid_to_peerid_dictionary[reconnecting_player_firebase_id]
				timers_node = get_node(str(i["timers_node_name"]))
				match_node = get_node(str(i["match_node_name"]))
	reconnection_timer = timers_node.get_node("ReconnectionTimer")
	reconnection_timer.stop()
	for i in timers_node.get_children():
		if i.name != "ReconnectionTimer":
			i.set_paused(false)
	disconnected_limbo_firebase_ids.erase(fbid)
	connected_limbo_firebase_ids.erase(connected_player_firebase_id)
	serverhost._reconnect_function(connected_player_peer_id, reconnecting_player_peer_id)
	var game_node = match_node.get_child(0)
	if game_node != null:
		game_node._reconnect_function([connected_player_peer_id, connected_player_firebase_id], [reconnecting_player_peer_id, reconnecting_player_firebase_id])
	
	
	

func _disconnect_handler(dict, dc_fbid):

	var disconnected_player_firebase_id = dc_fbid
	var disconnected_player_number
	var connected_player_firebase_id
	var connected_player_number
	var connected_player_peer_id
	if dict["player_one_firebase_id"] == disconnected_player_firebase_id:
		connected_player_firebase_id = dict["player_two_firebase_id"]
		connected_player_number = "two"
		disconnected_player_number = "one"
	else:
		connected_player_firebase_id = dict["player_one_firebase_id"]
		connected_player_number = "one"
		disconnected_player_number = "two"
	if connected_limbo_firebase_ids.has(disconnected_player_firebase_id): # this means both players disconnected
		_both_players_disconnected(dict)
		return
	connected_limbo_firebase_ids.append(connected_player_firebase_id)
	disconnected_limbo_firebase_ids.append(disconnected_player_firebase_id)
	connected_player_peer_id = serverhost.firebaseid_to_peerid_dictionary[connected_player_firebase_id]
	var match_node = get_node(str(dict["match_node_name"]))
	var timers_node = get_node(str(dict["timers_node_name"]))
	for i in timers_node.get_children():
		if i.name != "ReconnectionTimer":
			i.set_paused(true)
	var reconnect_timer = timers_node.get_node("ReconnectionTimer")
	var reconnect_time
	if disconnected_player_number == "one":
		reconnect_time = timers_node.p1_reconnection_timer_length
		reconnect_timer.start(reconnect_time)
		timers_node.p1_reconnection_timer_length -= 3
	else:
		reconnect_time = timers_node.p2_reconnection_timer_length
		reconnect_timer.start(reconnect_time)
		timers_node.p2_reconnection_timer_length -= 3
	reconnect_timer.timeout.connect(_disconnector.bind(dict))
	disconnected_dictionaries.append(dict)
	serverhost._disconnect_function(connected_player_peer_id, reconnect_time)
	


func _disconnector(dict):
	var connected_player_firebase_id
	var disconnected_player_firebase_id
	var connected_player_number
	var disconnected_player_number
	
	for i in serverhost.running_matches:
		if i["player_one_firebase_id"] or i["player_two_firebase_id"] == dict["player_one_firebase_id"]:
			for x in connected_limbo_firebase_ids:
				if connected_limbo_firebase_ids.has(dict["player_one_firebase_id"]):
					connected_player_firebase_id = x
					disconnected_player_firebase_id = dict["player_two_firebase_id"]
					connected_player_number = "one"
				if connected_limbo_firebase_ids.has(dict["player_two_firebase_id"]):
					connected_player_firebase_id = x
					disconnected_player_firebase_id = dict["player_one_firebase_id"]
					connected_player_number = "two"
	serverhost.pending_full_disconnect_array.append(disconnected_player_firebase_id)
	dict["match_winner"] = connected_player_number
	dict["end_by_disconnection"] = true
	dict["current_round"] = 3
	dict["round1winner"] = str(connected_player_number)
	dict["round2winner"] = str(connected_player_number)
	dict["round3winner"] = str(connected_player_number)
	
	serverhost._full_disconnect_function(dict, connected_player_firebase_id, disconnected_player_firebase_id)
	_end_match_prefunction(dict)

	var temp_array = []
	for i in disconnected_dictionaries:
		if i["player_one_firebase_id"] != connected_player_firebase_id and i["player_two_firebase_id"] != connected_player_firebase_id:
			temp_array.append(i)
		disconnected_dictionaries = temp_array
	temp_array = []
	for i in skip_dict:
		if i == dict["match_node_name"]:
			skip_dict.erase(i)
	temp_array = []		
	for i in range(connected_limbo_firebase_ids.size() - 1):
		if connected_limbo_firebase_ids[i] != connected_player_firebase_id and  connected_limbo_firebase_ids[i] != disconnected_player_firebase_id:
			
			temp_array.append(connected_limbo_firebase_ids[i])
	connected_limbo_firebase_ids = temp_array
	temp_array = []		
	for i in range(disconnected_limbo_firebase_ids.size() - 1):
		if disconnected_limbo_firebase_ids[i] != connected_player_firebase_id and  disconnected_limbo_firebase_ids[i] != disconnected_player_firebase_id:
			temp_array.append(disconnected_limbo_firebase_ids[i])
	disconnected_limbo_firebase_ids = temp_array		



@rpc("any_peer", "call_remote", "reliable")
func _on_opponent_disconnected(dict):
	pass

func _both_players_disconnected(dict):
	# these are not actually connected and disconnected players, just using for consistency for the cleanup code at the end of this function.
	var connected_player_firebase_id = dict["player_one_firebase_id"]
	var disconnected_player_firebase_id = dict["player_two_firebase_id"]
	serverhost.pending_full_disconnect_array.append(connected_player_firebase_id)
	serverhost.pending_full_disconnect_array.append(disconnected_player_firebase_id)
	var timers_node = get_node(str(dict["timers_node_name"]))
	var matches_node = get_node(str(dict["match_node_name"]))
	var reconnect_timer = timers_node.get_node("ReconnectionTimer")
	reconnect_timer.stop()
	timers_node.queue_free()
	matches_node.queue_free()
	
	var temp_array = []
	for i in disconnected_dictionaries:
		if i["player_one_firebase_id"] != connected_player_firebase_id and i["player_two_firebase_id"] != connected_player_firebase_id:
			temp_array.append(i)
		disconnected_dictionaries = temp_array
	temp_array = []
	for i in skip_dict:
		if i == dict["match_node_name"]:
			skip_dict.erase(i)
	temp_array = []		
	for i in range(connected_limbo_firebase_ids.size() - 1):
		if connected_limbo_firebase_ids[i] != connected_player_firebase_id and  connected_limbo_firebase_ids[i] != disconnected_player_firebase_id:
			
			temp_array.append(connected_limbo_firebase_ids[i])
	connected_limbo_firebase_ids = temp_array
	temp_array = []		
	for i in range(disconnected_limbo_firebase_ids.size() - 1):
		if disconnected_limbo_firebase_ids[i] != connected_player_firebase_id and  disconnected_limbo_firebase_ids[i] != disconnected_player_firebase_id:
			temp_array.append(disconnected_limbo_firebase_ids[i])
	disconnected_limbo_firebase_ids = temp_array		
	for i in serverhost.running_matches:
		if i["player_one_firebase_id"] == connected_player_firebase_id or i["player_two_firebase_id"] == connected_player_firebase_id:
			serverhost.running_matches.erase(i)	
