# Server.gd
extends Control
signal game_beginning

# Port to listen on. Must match the client.
const PORT = 7777
# Maximum number of players 
const MAX_PLAYERS = 100
var legendary_synchronizing = false
var leaderboard_synchronizing = false
# A list to store the IDs of connected peers.
var connected_peer_ids = [] 
var legendary_dictionary = {}
var username_id_dictionary = {}
var connected_usernames = []
var current_games = {}
var players_searching_dictionary = {}
var scramble_server_scene = "res://data/scenes_and_scripts/scramble/scramble_server_scene.tscn"
var current_game_node
var players_skipping_rules = 0
var matchmaking_timer_time_left
var array_of_timers = []


func _ready():	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	printerr("It is me, server-chan")
	Globals.load_from_file()
	legendary_dictionary = Globals.player_save_data
	printerr(legendary_dictionary)
	start_server()
	var leaderboard_tabulator_array = leaderboard_tabulator()
	Globals.top_players_dictionary = leaderboard_tabulator_array[1]
	Globals.top_players = leaderboard_tabulator_array[0]
	print(leaderboard_tabulator_array)
	print(Globals.top_players)
	
	
func _process(delta):
	if legendary_synchronizing == false: # sync legendary dictionary to the json save file every 10 seconds
		legendary_synchronizing = true
		await get_tree().create_timer(10)
		Globals.load_from_file()
		Globals.player_save_data = legendary_dictionary
		Globals.save_to_file()
		legendary_synchronizing = false
	if leaderboard_synchronizing == false:
		leaderboard_synchronizing = true
		var leaderboard_tabulator_array = leaderboard_tabulator()
		Globals.top_players_dictionary = leaderboard_tabulator_array[1]
		Globals.top_players = leaderboard_tabulator_array[0]
		await get_tree().create_timer(30)
		leaderboard_synchronizing = false
	pass

func start_server():
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
	

func _on_peer_connected(id):
	print("Player connected: " + str(id))
	# Add the new player's ID to our list.
	connected_peer_ids.append(id)
	print(connected_peer_ids)
	
	
	
@rpc("any_peer", "call_local")	
func save_game_synchronizer(player_information):
	print("save_game_synch running on server ")
	var array_of_subkeys = ["Level", "Experience", "Rank", "Password", "ProfilePic"]
	var player_id
	print(username_id_dictionary)
	if player_information == null: # these few lines are to allow save game synchronizer to be run when a game is over to add experience and resynchronize from full_game_ender
		player_id = multiplayer.get_remote_sender_id()
	else:
		player_id = player_information
	
	for i in username_id_dictionary:
		
		var username = username_id_dictionary[i]
		
		#Globals.load_from_file()
		if not legendary_dictionary.has(username): #creates new entry if player has never connected before
			legendary_dictionary[username] = {}
			legendary_dictionary[username]["Level"] = int(1)
			legendary_dictionary[username]["Experience"] = int(1)
			legendary_dictionary[username]["Rank"] = int(1)
		if legendary_dictionary.has(username):  # this will update all existing users to have all the subkeys that might be missing
			var values = legendary_dictionary[username]
			var subkeys = values.keys()
			for x in subkeys:
				for y in array_of_subkeys:
					if not subkeys.has(y):
						legendary_dictionary[username][y] = null
				
			print(subkeys)
			pass
		#Globals.save_to_file()
	if username_id_dictionary.has(player_id):
		rpc_id(player_id, "receive_profile_info_from_server", legendary_dictionary[username_id_dictionary[player_id]])


func _on_peer_disconnected(id):
	print("Player disconnected: " + str(id))
	# Remove the disconnected player's ID from array and dictionary
	var username = username_id_dictionary[id]
	connected_usernames.erase(username)
	username_id_dictionary.erase(id)
	connected_peer_ids.erase(id)
	#print(username_id_dictionary)
	rpc("server_to_player", connected_peer_ids.size())
	
	
	
	



@rpc("any_peer", "call_local", "reliable")
func player_to_server(information):

	var username = information[0]
	var userid = information[1]
	username_id_dictionary[userid] = username
	var info_from_server = connected_peer_ids.size()
	rpc("server_to_player", info_from_server)
	pass
	
@rpc("any_peer", "call_local", "reliable")
func server_to_player(info_from_server):
	
	pass
	
@rpc("authority", "call_local", "reliable")
func start_game(username1, username2, userid1, userid2):
	current_games[str(username1) + str(username2) + "Round Number"] += 1
	var rulestimer = (load("res://data/scenes_and_scripts/multiplayertesting/rules_timer.tscn")).instantiate()
	var matchmakingtimer = (load("res://data/scenes_and_scripts/multiplayertesting/matchmaking_timer.tscn")).instantiate()
	var pregametimer = (load("res://data/scenes_and_scripts/multiplayertesting/pregame_timer.tscn")).instantiate()
	
	rulestimer.name = "RulesTimer" + username1 + username2
	matchmakingtimer.name = "MatchmakingTimer" + username1 + username2
	pregametimer.name = "PregameTimer" + username1 + username2
	
	
	add_child(rulestimer)
	add_child(matchmakingtimer)
	add_child(pregametimer)
	
	
	rulestimer.connect("timer_done", rules_fade.bind(username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer))
	pregametimer.connect("timer_done", pregame_timer_finished.bind(username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer))
	matchmakingtimer.connect("timer_done", match_making_fade.bind(username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer))
	
	
	var wordsearch_instance = (load("res://data/scenes_and_scripts/wordsearch/WsServer.tscn")).instantiate()
	var wordsearch_instance_name = "WordsearchScene" + username1 + username2
	wordsearch_instance.name = wordsearch_instance_name
	wordsearch_instance.set_meta("userid1", userid1)
	wordsearch_instance.set_meta("userid2", userid2)
	
	matchmakingtimer.start()
	var scramble_node = load(scramble_server_scene)
	var scramble_instance = scramble_node.instantiate()
	var scramble_instance_name = "ScrambleScene" + username1 + username2
	scramble_instance.name = scramble_instance_name
	scramble_instance.set_meta("userid1", userid1)
	scramble_instance.set_meta("userid2", userid2)
	

	
	var gametype = game_chooser()
	rpc_id(userid1, "game_spawner", username1, username2, userid1, userid2, gametype)
	rpc_id(userid2, "game_spawner", username1, username2, userid1, userid2, gametype)
	print("upcoming game type = " + str(gametype))
	if gametype == "ScrambleVanilla":
		pass
	if gametype == "ScrambleBonus":
		scramble_instance.bonus_variant = true
	if gametype == "ScrambleObscurity":
		scramble_instance.obscurity_variant = true
	if gametype == "ScrambleBonusObscurity":
		scramble_instance.bonus_variant = true
		scramble_instance.obscurity_variant = true		
	if gametype == "ScrambleWonder":
		scramble_instance.wonder_variant = true
	if gametype == "ScrambleBonusWonder":
		scramble_instance.bonus_variant = true
		scramble_instance.wonder_variant = true
	if gametype == "ScrambleBonusObscurityWonder":
		scramble_instance.bonus_variant = true
		scramble_instance.wonder_variant = true
		scramble_instance.obscurity_variant = true
	if gametype == "WordsearchVanilla":
		wordsearch_instance.chosen_variant = Globals.WordsearchVariants.DEFAULT
	if gametype == "WordsearchShared":
		wordsearch_instance.chosen_variant = Globals.WordsearchVariants.SHARED_BOARD
	if gametype == "WordsearchHidden":
		wordsearch_instance.chosen_variant = Globals.WordsearchVariants.HIDDEN		
	if gametype.contains("Scramble"):	
		%RunningGames.add_child(scramble_instance)
		current_game_node = scramble_instance
	if gametype.contains("Wordsearch"):	
		%RunningGames.add_child(wordsearch_instance)	
		current_game_node = wordsearch_instance
	var minigame_node = current_game_node
	var wordsearch_winner
	current_game_node.connect("time_up", test_function.bind("local_bind"))
	current_game_node.connect("time_up", game_ender_prefunction.bind(minigame_node,username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer))
	
	var player_one_wins = null
	var player_two_wins = null
	scramble_instance.important_information = [minigame_node, username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer, player_one_wins, player_two_wins, current_games]

	pass

@rpc("any_peer", "call_local", "reliable")
func matchmaking(username): # every time the number of players search for a game hits 2, get those users, start game with them, and clear the list of searching players.
	var userid = multiplayer.get_remote_sender_id()
	players_searching_dictionary[userid] = username
	print(players_searching_dictionary)
	if players_searching_dictionary.size() == 2:
		var username1 = players_searching_dictionary.values()[0]
		var username2 = players_searching_dictionary.values()[1]
		var userid1 = players_searching_dictionary.keys()[0]
		var userid2 = players_searching_dictionary.keys()[1]
		players_searching_dictionary.clear()
		rpc_id(userid1,"start_game", username1, username2, userid1, userid2)
		rpc_id(userid2,"start_game", username1, username2, userid1, userid2)
		current_games[str(username1) + str(username2) + "Round Number"] = 0 
		
		start_game(username1, username2, userid1, userid2)
		
		
	
func experience_tabulator(player, experience_to_gain, is_winner): # handles leveling up and ranking up
	legendary_dictionary[player]["Experience"] += experience_to_gain
	if legendary_dictionary[player]["Experience"] >= 100:
		var experience = legendary_dictionary[player]["Experience"]
		legendary_dictionary[player]["Level"] += 1
		legendary_dictionary[player]["Experience"] = experience - 100
	if is_winner == true:
		legendary_dictionary[player]["WinsRemaining"] -= 1
		if legendary_dictionary[player]["WinsRemaining"] == 0:
			legendary_dictionary[player]["WinsRemaining"] = 3
			legendary_dictionary[player]["Rank"] += 1
			
			
	pass	
	
@rpc("any_peer", "call_remote", "reliable")
func rules_skip(username_1, username_2):
	var unique_rules_timer = get_node("RulesTimer" + str(username_1) + str(username_2))
	var unique_rules_timer2 = get_node("RulesTimer" + str(username_2) + str(username_1))
	print(unique_rules_timer)
	print("rules skip run on server ")
	players_skipping_rules += 1
	if players_skipping_rules == 2:
		players_skipping_rules = 0
		print("2 players skipping")
		if unique_rules_timer!=null:
			unique_rules_timer.start(0.01)
		if unique_rules_timer2!=null:
			unique_rules_timer2.start(0.01)
		
		
	pass
	
@rpc("authority", "call_local", "reliable")
func match_making_fade(username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer):
	rulestimer.start()
	print(userid1)
	print(userid2)
	rpc_id(userid1, "match_making_fade", username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer)
	rpc_id(userid2, "match_making_fade", username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer)
	rpc_id(userid1, "rules_load", username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer)
	rpc_id(userid2, "rules_load", username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer)
	print("server side match making fade")
	pass

@rpc("authority", "call_remote", "reliable")	
func rules_load(username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer):
	pass
	
@rpc("authority", "call_local", "reliable")	
func rules_fade(username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer):
	rpc_id(userid1, "rules_fade", username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer)
	rpc_id(userid2, "rules_fade", username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer)
	rulestimer.stop()
	print("server side rules fade")
	pregametimer.start()
	pass
	
@rpc("authority", "call_local", "reliable")	
func pregame_timer_finished(username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer):
	rpc_id(userid1, "pregame_timer_finished", username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer)
	rpc_id(userid2, "pregame_timer_finished", username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer)
	print("server side pregame timer finished")
	var scramble_instance_name = "ScrambleScene" + username1 + username2
	print(scramble_instance_name)
	var scramble_instance_node = get_node("/root/MainMenu/RunningGames/" + str(scramble_instance_name))
	print(scramble_instance_node)
	if scramble_instance_node != null:
		scramble_instance_node.game_starter()
		
	pass

func game_ender_prefunction(wordsearch_winner, minigame_node,username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer):
	var user_one_score
	var user_two_score
	var user_one_best_word_score_array
	var user_two_best_word_score_array
	var user_one_best_word
	var user_two_best_word
	print(minigame_node.name)
	
	if minigame_node.name.contains("Scramble"):
		
		user_one_score = minigame_node.big_dictionary["Player One Score"]
		user_two_score = minigame_node.big_dictionary["Player Two Score"]
		user_one_best_word_score_array = best_word_finder(minigame_node.big_dictionary["Player One Found Words"], minigame_node)
		user_two_best_word_score_array = best_word_finder(minigame_node.big_dictionary["Player Two Found Words"], minigame_node)
		user_one_best_word = user_one_best_word_score_array[0]
		user_two_best_word = user_two_best_word_score_array[0]
		current_games[str(username1) + str(username2) + "Player One Best Word"] = user_one_best_word
		current_games[str(username1) + str(username2) + "Player Two Best Word"] = user_two_best_word
	
	if minigame_node.name.contains("Wordsearch"):
		current_games[str(username1) + str(username2) + "Player One Best Word"] = ""
		current_games[str(username1) + str(username2) + "Player Two Best Word"] = ""
		if userid1 == wordsearch_winner:
			user_one_score = 10
			user_two_score = 1
		if userid2 == wordsearch_winner:
			user_one_score = 1
			user_two_score = 10
				
	var player_one_wins
	var player_two_wins
	
	var current_round = current_games[str(username1) + str(username2) + "Round Number"] 
	if user_one_score > user_two_score:
		player_one_wins = true
		current_games[str(username1) + str(username2) + "Round" + str(current_round) + "Winner"] = 1 
	if user_two_score > user_one_score:
		player_two_wins = true
		current_games[str(username1) + str(username2) + "Round" + str(current_round) + "Winner"] = 2
	if user_one_score == user_two_score: # tiebreaker number 1 based on best word of the round sans any bonuses
		if user_one_best_word_score_array[1] > user_two_best_word_score_array[1]:
			player_one_wins = true
			current_games[str(username1) + str(username2) + "Round" + str(current_round) + "Winner"] = 1 
		if user_two_best_word_score_array[1] > user_one_best_word_score_array[1]:
			player_two_wins = true		
			current_games[str(username1) + str(username2) + "Round" + str(current_round) + "Winner"] = 2
		if user_one_best_word_score_array[1] == user_two_best_word_score_array[1]: #tiebreaker number 2 based on number of words found
			if minigame_node.big_dictionary["Player One Number Of Found Words"] > minigame_node.big_dictionary["Player Two Number Of Found Words"]:
				player_one_wins = true
				current_games[str(username1) + str(username2) + "Round" + str(current_round) + "Winner"] = 1 
			if minigame_node.big_dictionary["Player Two Number Of Found Words"] > minigame_node.big_dictionary["Player One Number Of Found Words"]:
				player_two_wins = true
				current_games[str(username1) + str(username2) + "Round" + str(current_round) + "Winner"] = 2
			if minigame_node.big_dictionary["Player Two Number Of Found Words"] == minigame_node.big_dictionary["Player One Number Of Found Words"]: #tiebreaker number 3 is randomly chosen
				var number = randi_range(0,1)
				if number == 1:
					player_one_wins = true
					current_games[str(username1) + str(username2) + "Round" + str(current_round) + "Winner"] = 1 
				if number == 0:
					player_two_wins = true
					current_games[str(username1) + str(username2) + "Round" + str(current_round) + "Winner"] = 2
		pass 
		
	print("game_ender prefunction run")
	 
	
	game_ender(minigame_node, username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer, player_one_wins, player_two_wins, current_games)
	rpc_id(userid1, "game_ender", minigame_node, username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer, player_one_wins, player_two_wins, current_games)
	rpc_id(userid2, "game_ender", minigame_node, username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer, player_one_wins, player_two_wins, current_games)
	pass

@rpc("authority", "call_local", "reliable")	
func game_ender(minigame_node, username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer, player_one_wins, player_two_wins, current_games):
	rulestimer.queue_free()
	matchmakingtimer.queue_free()
	pregametimer.queue_free()
	minigame_node.queue_free()
	var roundendtimer = (load("res://data/scenes_and_scripts/multiplayertesting/round_end_timer.tscn")).instantiate()
	roundendtimer.name = "RoundEndTimer" + username1 + username2
	add_child(roundendtimer)
	roundendtimer.connect("timer_done", round_end_screen_fade.bind(username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer))
	roundendtimer.start()
	print("serverside game_ender run.")


	
@rpc("authority", "call_local", "reliable")		
func round_end_screen_fade(username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer):
	rpc_id(userid1, "round_end_screen_fade",  username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer)
	rpc_id(userid2, "round_end_screen_fade",  username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer)
	await get_tree().create_timer(2).timeout
	print(current_games[str(username1) + str(username2) + "Round Number"])
	if current_games[str(username1) + str(username2) + "Round Number"] == 2: # if best 2/3 is reached at end of roudn 2
		if current_games[str(username1) + str(username2) + "Round1Winner"] == current_games[str(username1) + str(username2) + "Round2Winner"]:
			rpc_id(userid1, "full_game_ender",  username1, username2, userid1, userid2)
			rpc_id(userid2, "full_game_ender",  username1, username2, userid1, userid2)
			full_game_ender(username1, username2, userid1, userid2)
			print("FULL GAME OVER")
			return
		
	if current_games[str(username1) + str(username2) + "Round Number"] <3:
		start_game(username1, username2, userid1, userid2)
		rpc_id(userid1, "start_game",  username1, username2, userid1, userid2)
		rpc_id(userid2, "start_game",  username1, username2, userid1, userid2)
	else:
		rpc_id(userid1, "full_game_ender",  username1, username2, userid1, userid2)
		rpc_id(userid2, "full_game_ender",  username1, username2, userid1, userid2)
		full_game_ender(username1, username2, userid1, userid2)
		print("FULL GAME OVER")
	pass
	
	
@rpc("authority", "call_local", "reliable")		
func full_game_ender(username1, username2, userid1, userid2):
	print("full game ender run serverside")
	var winner_username
	var loser_username
	var round1winner = current_games[str(username1) + str(username2) + "Round1Winner"]
	var round2winner = current_games[str(username1) + str(username2) + "Round2Winner"]
	if current_games[str(username1) + str(username2) + "Round Number"] == 2:
		var winner = round1winner
		if winner == 1:
			winner_username = username1
			loser_username = username2
		if winner == 2:
			winner_username = username2
			loser_username = username1
		print("winner is " + str(winner_username))
		
	if current_games[str(username1) + str(username2) + "Round Number"] == 3: # prevent crash if same player won first two rounds
		var round3winner = current_games[str(username1) + str(username2) + "Round3Winner"]
		if round3winner == round1winner:
			var winner = round1winner
			if winner == 1:
				winner_username = username1
				loser_username = username2
			if winner == 2:
				winner_username = username2
				loser_username = username1
			print("winner is " + str(winner_username))
		if round3winner == round2winner:
			var winner = round2winner
			if winner == 1:
				winner_username = username1
				loser_username = username2
			if winner == 2:
				winner_username = username2
				loser_username = username1
			print("winner is " + str(winner_username))
	experience_tabulator(winner_username, 50, true)
	experience_tabulator(loser_username, 20, false)
	
	rpc_id(userid1, "receive_profile_info_from_server",  legendary_dictionary[username1])
	rpc_id(userid2, "receive_profile_info_from_server",  legendary_dictionary[username2])
		
	#save_game_synchronizer(userid1)
	#save_game_synchronizer(userid2)
	
func best_word_finder(found_words, minigame_node):
	var best_word 
	var best_word_score : int = 0
	for i in found_words:
		var score = minigame_node.word_scorer(i, false)
		if score > best_word_score:
			best_word_score = score
			best_word = i
	if best_word == null:
		best_word = "no words..."
	return [best_word, best_word_score]
	pass
	
	pass

@rpc("authority", "call_local", "reliable")	
func receive_profile_info_from_server(info):
	pass

func game_chooser():
	var number_of_games = Globals.game_types.size()
	var random_number = randi_range(0,number_of_games - 1)
	return Globals.game_types[random_number]
	#return "ScrambleBonusObscurityWonder"
	pass

@rpc("authority", "call_local", "reliable")	
func game_spawner(username1, username2, userid1, userid2, gametype):
	
	pass

func leaderboard_tabulator():
	var sorted_names = legendary_dictionary.keys()
	var sorted_names_dictionary = {}
	sorted_names.sort_custom(func(a, b): return legendary_dictionary[a].Level > legendary_dictionary[b].Level)
	for i in sorted_names:
		sorted_names_dictionary[i] = legendary_dictionary[i]["Level"]
	return [sorted_names, sorted_names_dictionary]



@rpc("any_peer", "call_remote", "reliable")	
func login_authenticator(username, password):
	var id = multiplayer.get_remote_sender_id()
	print(id)
	if legendary_dictionary.has(username):
		if legendary_dictionary[username].has("Password"):
			if legendary_dictionary[username]["Password"] == password:
				if not connected_usernames.has(username): # prevent duplicate logons
					connected_usernames.append(username)
					username_id_dictionary[id] = username
					return "valid user"
				else:
					return "already logged in..."
			else:
				return "incorrect password"
	if not legendary_dictionary.has(username):
		return "not a user"
	


@rpc("any_peer", "call_local", "reliable")	
func username_available_authenticator(username):
	var users = legendary_dictionary.keys()
	if users.has(username):
		return true
	else:
		return false

@rpc("any_peer", "call_remote", "reliable")	
func password_registration(username, password):
	legendary_dictionary[username] = {}
	legendary_dictionary[username]["Password"] = password
	new_user_initialization(username)
	print(legendary_dictionary)
	pass

func new_user_initialization(username):
	legendary_dictionary[username]["Level"] = int(0)
	legendary_dictionary[username]["Experience"] = int(0)
	legendary_dictionary[username]["Rank"] = int(0)
	legendary_dictionary[username]["ProfilePic"] = "res://data/images/profilepics/profilepic.jpg"
	legendary_dictionary[username]["Username"] = str(username)
	save_big_dictionary()
	
@rpc("any_peer", "call_remote", "reliable")	
func update_profile_pic(picture):
	var id = multiplayer.get_remote_sender_id()
	var username
	username = username_id_dictionary[id]
	legendary_dictionary[username]["ProfilePic"] = picture
	rpc_id(id, "receive_profile_info_from_server", legendary_dictionary[username_id_dictionary[id]]) 
	save_big_dictionary()
	pass
	
@rpc("any_peer", "call_remote", "reliable")	
func serve_opponent_information(username):
	var cleaned_dictionary = legendary_dictionary[username].duplicate()
	cleaned_dictionary.erase("Password")
	
	return cleaned_dictionary
	pass

func save_big_dictionary():
	Globals.load_from_file()
	Globals.player_save_data = legendary_dictionary
	Globals.save_to_file()
	pass

func test_function(signal_bind, local_bind):
	print("test function worked")
	print(signal_bind)
	print(local_bind)
	
@rpc("any_peer", "call_remote", "reliable")
func cancel_find_match(userid):
	if players_searching_dictionary.has(userid):
		players_searching_dictionary.erase(userid)
	pass
