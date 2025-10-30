extends Control

@onready var serverhost = get_parent()
signal match_ended(dict)

var players_looking_for_match = []
var matched_players = []
var timers_scene = "res://data/scenes_and_scripts/phoenix/timers.tscn"
var round_time = 5
var match_found_time = 3
var rules_time = 7
var score_time = 3
var skip_dict = {}

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
	print(matched_players)
	
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
	"match_winner": "", "rules_skipped": false
	}
	serverhost.running_matches.append(str(match_info_dictionary["match_node_name"]))
	rpc_id(player_one_peer_id, "_client_match_informer", match_info_dictionary)
	rpc_id(player_two_peer_id, "_client_match_informer", match_info_dictionary)
	
	
@rpc("any_peer", "call_remote", "reliable")	
func _client_match_informer(match_info_dictionary):
	pass


 #this function will keep track of the stages of the match between two players, and run the necessary functions to keep things moving
#it is called from the client identified as player one exclusively to keep the stages of the game progressing
@rpc("any_peer", "call_remote", "reliable")	
func _match_runner(dict):
	if dict["match_stage"] == "initial": # we use the match_stage dictionary entry to keep track of what stage of the game they are in
		var match_found_timer = get_node(str(dict["timers_node_name"]) + "/MatchFoundTimer")
		match_found_timer.start(match_found_time)
		await match_found_timer.timeout
		if dict["player_one_dictionary"]["auto_skip_rules"] == true and dict["player_two_dictionary"]["auto_skip_rules"] == true:
			dict["rules_skipped"] = true
			dict["match_stage"] = "rules"
			rpc_id(dict["player_one_peer_id"], "_show_rules", dict)
			rpc_id(dict["player_two_peer_id"], "_show_rules", dict)
		else:
			dict["match_stage"] = "rules"
			rpc_id(dict["player_one_peer_id"], "_show_rules", dict)
			rpc_id(dict["player_two_peer_id"], "_show_rules", dict)
		return
	if dict["match_stage"] == "rules":
		print("match runner")
		var rules_timer = get_node(str(dict["timers_node_name"]) + "/RulesTimer")
		if dict["rules_skipped"]:
			rules_timer.start(0.5)
		else:
			rules_timer.start(rules_time)
		await rules_timer.timeout
		
		dict["match_stage"] = "game"
		if dict["player_one_dictionary"]["auto_skip_rules"] == true and dict["player_two_dictionary"]["auto_skip_rules"] == true:
			dict["rules_skipped"] = true # this is to reset it for the next rules screen
		else:
			dict["rules_skipped"] = false

		_start_game(dict)
		var round_timer = get_node(str(dict["timers_node_name"]) + "/RoundTimer")
		round_timer.start(100)
		rpc_id(dict["player_one_peer_id"], "_start_game", dict)
		rpc_id(dict["player_two_peer_id"], "_start_game", dict)		
		return
	if dict["match_stage"] == "game":
		var round_timer = get_node(str(dict["timers_node_name"]) + "/RoundTimer")
		round_timer.start(round_time)
		dict["match_stage"] = "score"
		await round_timer.timeout
		var winner = _end_game(dict)
		var string = "round" + str(dict["current_round"] + 1) + "winner" # this is to register into the dictionary who won each round.
		dict[string] = winner
		print(dict)
		rpc_id(dict["player_one_peer_id"], "_end_game", dict)
		rpc_id(dict["player_two_peer_id"], "_end_game", dict)
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
		rpc_id(dict["player_one_peer_id"], "_show_rules", dict)
		rpc_id(dict["player_two_peer_id"], "_show_rules", dict)		
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
	var game_instance = game.instantiate()
	game_instance._initialize(dict)
	game_instance.set_meta("userid1", dict["player_one_peer_id"])
	game_instance.set_meta("userid2", dict["player_two_peer_id"])
	#game_instance.name = str(dict["player_one_dictionary"]["email"]) + str(dict["player_two_dictionary"]["email"]) 
	print(dict["match_node_name"])
	
	
	match_container.add_child(game_instance)
	
	pass

@rpc("any_peer", "call_remote", "reliable")
func _end_game(dict):
	var match_container = get_node(str(dict["match_node_name"]))
	var current_game = match_container.get_child(0)
	print(current_game)
	var big_dictionary = current_game.big_dictionary
	var winner = _determine_winner(dict, big_dictionary)
	current_game.queue_free()
	return winner
	
	pass
	
func _game_selector(): 
	
	# this function will return three games at random from Globals.game_types (while preventing duplicates)
	var games_array = Globals.game_types.duplicate()
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
	#rpc_id(dict["player_one_peer_id"], "_end_match", dict)
	#rpc_id(dict["player_two_peer_id"], "_end_match", dict)				
	print("match over")
	match_ended.emit(dict)
	pass
	
@rpc("any_peer", "call_remote", "reliable")	
func _end_match(dict):
	rpc_id(dict["player_one_peer_id"], "_end_match", dict)
	rpc_id(dict["player_two_peer_id"], "_end_match", dict)
	serverhost.running_matches.erase(str(dict["match_node_name"]))
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
func _skip_rules_pressed(dict):
	print("server side skip rtules presed ")
	if not skip_dict.has(str(dict["match_node_name"])):
		skip_dict[str(dict["match_node_name"])] = []
	if multiplayer.get_remote_sender_id() == dict["player_one_peer_id"]:
		skip_dict[str(dict["match_node_name"])].append(multiplayer.get_remote_sender_id())
		if skip_dict[str(dict["match_node_name"])].size() == 2:
			skip_dict[str(dict["match_node_name"])] = []
			dict["rules_skipped"] = true
	if multiplayer.get_remote_sender_id() == dict["player_two_peer_id"]:
		skip_dict[str(dict["match_node_name"])].append(multiplayer.get_remote_sender_id())
		if skip_dict[str(dict["match_node_name"])].size() == 2:
			skip_dict[str(dict["match_node_name"])] = []
			dict["rules_skipped"] = true
	_match_runner(dict)	
	
	pass
