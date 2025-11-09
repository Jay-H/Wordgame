extends Control
var PORT = 7777
var MAX_PLAYERS = 1000
@onready var Database = get_node("/root/Firebase/Database")

var initial_user_data: Dictionary = { 
	"country": "", "email": "@gmail.com", "experience": 0.0, "level": 0.0, "losses": 0.0, "matches_played": 0.0, "profilepic": 0.0, 
	"rank": 0.0, "username": "", "wins": 0.0, "music_enabled": true, "sound_enabled": true, "auto_skip_rules": false, "low_graphics_mode": false, 
	"rank_points": 0,
	}
var peerid_to_firebaseid_dictionary = {}
var logged_in_firebase_ids = []
var players_looking_for_match = []
var legendary_dictionary = {}
var running_matches = []
var process_test = false
var available_game_type_lists = {}
var game_types_ref
var selected_game_list_name
var selected_game_list
var selected_game_list_2 = ["HangmanChaosVanilla", "HangmanChaosShared", "HangmanChaosEphemeral", "HangmanTurnbased", "HangmanDelay", "HangmanDelayEphemeral"]
var timer_values_ref
var timer_values_dictionary = {}

func _ready():
	print("IF THIS PRINTS IT MEANS THE SERVER IS USING NEW BUILD")
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_start_server()
	Firebase.Auth.login_succeeded.connect(_on_FirebaseAuth_login_succeeded)
	Firebase.Auth.login_with_email_and_password("server@server.com", "supersonic")
	%RunningGames.connect("match_ended", _match_over_data_collection)
	print("server has logged in")
	pass
	
func _process(_delta):
	#await _debug_vm(selected_game_list)
	pass
	
func _on_FirebaseAuth_login_succeeded(auth):

	game_types_ref = Firebase.Database.get_database_reference("server_data/game_types", {})
	game_types_ref.new_data_update.connect(_on_game_types_ref_update)
	game_types_ref.patch_data_update.connect(_on_game_types_ref_update)
	game_types_ref.delete_data_update.connect(_on_game_types_ref_update)
	timer_values_ref = Firebase.Database.get_database_reference("server_data/timer_values", {})
	timer_values_ref.new_data_update.connect(_on_timer_ref_update)
	timer_values_ref.patch_data_update.connect(_on_timer_ref_update)
	timer_values_ref.delete_data_update.connect(_on_timer_ref_update)	
	pass	
	
	
	
 # here we will let the client know that they are connected to the server for the purpose of allowing them to now login through firebase
func _on_game_types_ref_update(resource):
	if resource.key == "selected_game":
		selected_game_list_name = resource.data 
	else:
		available_game_type_lists[str(resource.key)] = resource.data
	if available_game_type_lists != null and selected_game_list_name != null:
		if available_game_type_lists.has(selected_game_list_name):
			selected_game_list = available_game_type_lists[str(selected_game_list_name)]	
			
		
	
	print(resource)
	#print(resource["selected_game_list"])
 
func _on_timer_ref_update(resource):
	if resource.key == "match_found_timer":
		timer_values_dictionary["match_found_timer"] = resource.data
	if resource.key == "round_timer":
		timer_values_dictionary["round_timer"] = resource.data
	if resource.key == "rules_screen_timer":
		timer_values_dictionary["rules_screen_timer"] = resource.data
	if resource.key == "score_timer":
		timer_values_dictionary["score_timer"] = resource.data
	pass
	
func _on_peer_connected(id):
	print(id)
	rpc_id(id, "_confirm_connected_to_server")
	print("peers connected")
	
	pass
	
func _on_peer_disconnected(id):
	
	# the logic for ending a game if a player disconnects
	if peerid_to_firebaseid_dictionary.has(id):
		for i in running_matches:
			if i["player_one_peer_id"] == id or i["player_two_peer_id"] == id:
				%RunningGames._disconnect_handler(i, id)
				
	if peerid_to_firebaseid_dictionary.has(id):
		logged_in_firebase_ids.erase(peerid_to_firebaseid_dictionary[id])
	if peerid_to_firebaseid_dictionary.has(id):
		peerid_to_firebaseid_dictionary.erase(id)
			
	

		
	pass


	

@rpc("any_peer", "call_remote", "reliable")
func _send_firebase_info_to_server(auth):
	var peer_id = multiplayer.get_remote_sender_id()
	peerid_to_firebaseid_dictionary[peer_id] = auth["localid"]
	logged_in_firebase_ids.append(auth["localid"])
	pass

#_create_account and _create_account_succeeded will run and enter the multiplayer peer id and firebase id into a dictionary so that they are joined
#then it will run _save_user_data with the initial user data dictionary so that there is some information for that player when they login
@rpc("any_peer", "call_remote", "reliable")
func _create_account(email, password):
	var peer_id = multiplayer.get_remote_sender_id()
	Firebase.Auth.signup_with_email_and_password(email, password)
	Firebase.Auth.signup_succeeded.connect(_save_new_user_data.bind(peer_id))


#This function will save a new user's information to the database.
func _save_new_user_data(auth, peer_id):
	peerid_to_firebaseid_dictionary[peer_id] = auth["localid"] # associates a firebase id with a currently logged in peer id for godot.
	var user_data = initial_user_data
	user_data["email"] = auth["email"] #applies the email to database entry
	var db_ref = Database.get_database_reference("users")
	db_ref.update(auth["localid"], user_data) # this is what puts in the user data into the specific firebase id's section of the database



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

@rpc("authority", "call_remote", "reliable")
func _receive_new_profile_info(auth):
	pass

@rpc("any_peer", "call_remote", "reliable")	
func _update_username(username, firebase_local_id):
	var path = "users"
	var db_ref = Database.get_database_reference(path)
	db_ref.update(firebase_local_id, {"username": username})
	
	pass

@rpc("any_peer", "call_remote", "reliable")
func _update_profilepic(picture, firebase_local_id):
	var path = "users" 
	var db_ref = Database.get_database_reference(path)
	db_ref.update(firebase_local_id, {"profilepic": picture})
	pass

@rpc("any_peer", "call_remote", "reliable")	
func _get_user_data_from_client(data):
	legendary_dictionary[multiplayer.get_remote_sender_id()] = data

@rpc("any_peer", "call_remote", "reliable")	
func _find_game():
	print("received find game rpc")
	%RunningGames.players_looking_for_match.append(multiplayer.get_remote_sender_id())

	
@rpc("any_peer", "call_remote", "reliable")	
func _cancel_find_game():
	var peer_id = multiplayer.get_remote_sender_id()
	%RunningGames.players_looking_for_match.erase(peer_id)
	pass

func _match_over_data_collection(dict):
	_experience_rank_level(dict)
	if dict["match_winner"] == "one":
		dict["player_one_dictionary"]["wins"] += 1
		dict["player_two_dictionary"]["losses"] += 1	
	else:
		dict["player_two_dictionary"]["wins"] += 1
		dict["player_one_dictionary"]["losses"] += 1	
	dict["player_one_dictionary"]["matches_played"] += 1
	dict["player_two_dictionary"]["matches_played"] += 1	
	legendary_dictionary[dict["player_one_peer_id"]] = dict["player_one_dictionary"] 
	legendary_dictionary[dict["player_two_peer_id"]] = dict["player_two_dictionary"] 
	_sync_legendary_to_firebase(dict["player_one_dictionary"], dict["player_one_firebase_id"])
	_sync_legendary_to_firebase(dict["player_two_dictionary"], dict["player_two_firebase_id"])
	%RunningGames._end_match(dict)
	pass

func _sync_legendary_to_firebase(dict, firebase_local_id):
	var path = "users"
	var db_ref = Database.get_database_reference(path)
	db_ref.update(firebase_local_id, dict)
	pass

@rpc("any_peer", "call_remote", "reliable")
func _confirm_connected_to_server():
	pass

# this is to make sure that the player who just logged in through firebase auth is not already logged in. 
@rpc("any_peer", "call_remote", "reliable")
func _verify_not_already_logged_in_firebase(auth):
	print("verify server")
	if logged_in_firebase_ids.has(auth["localid"]):
		rpc_id(multiplayer.get_remote_sender_id(), "_logged_in_verification_result", auth, "already logged in")
	if not logged_in_firebase_ids.has(auth["localid"]):
		rpc_id(multiplayer.get_remote_sender_id(), "_logged_in_verification_result", auth, "not already logged in")
		
	pass

@rpc("any_peer", "call_remote", "reliable")
func _logged_in_verification_result(auth, result):
	pass

func _experience_rank_level(dict):
	var winner = dict["match_winner"]
	var p1rank = dict["player_one_dictionary"]["rank"]
	var p2rank = dict["player_two_dictionary"]["rank"]
	var p1level = dict["player_one_dictionary"]["level"]
	var p2level = dict["player_two_dictionary"]["level"]
	var p1experience = dict["player_one_dictionary"]["experience"]
	var p2experience = dict["player_two_dictionary"]["experience"]
	var p1rankpoints = dict["player_one_dictionary"]["rank_points"]
	var p2rankpoints = dict["player_two_dictionary"]["rank_points"]
	
	if winner == "one": # this part is for the experience and level
		dict["player_one_dictionary"]["experience"] += 60
		var differential = dict["player_one_dictionary"]["experience"] - 100
		if differential >= 0: # this part is so that if the experience is 100 or over it will loop back from 0.
			dict["player_one_dictionary"]["experience"] = differential
			dict["player_one_dictionary"]["level"] += 1
		dict["player_two_dictionary"]["experience"] += 30
		var differential2 = dict["player_two_dictionary"]["experience"] - 100
		if differential2 >= 0: # this part is so that if the experience is 100 or over it will loop back from 0.
			dict["player_two_dictionary"]["experience"] = differential2
			dict["player_two_dictionary"]["level"] += 1
	if winner == "two": # this part is for the experience and level
		dict["player_two_dictionary"]["experience"] += 60
		var differential = dict["player_two_dictionary"]["experience"] - 100
		if differential >= 0: # this part is so that if the experience is 100 or over it will loop back from 0.
			dict["player_two_dictionary"]["experience"] = differential
			dict["player_two_dictionary"]["level"] += 1
		dict["player_one_dictionary"]["experience"] += 30
		var differential2 = dict["player_one_dictionary"]["experience"] - 100
		if differential2 >= 0: # this part is so that if the experience is 100 or over it will loop back from 0.
			dict["player_one_dictionary"]["experience"] = differential2		
			dict["player_one_dictionary"]["level"] += 1
	if winner == "one": # this part is for rank
		if p1rank == p2rank: # if ranks are equal
			dict["player_one_dictionary"]["rank_points"] += 2
			var differential = dict["player_one_dictionary"]["rank_points"] - 10 # this part is so that your rank points go back to 0 if you rank up
			if differential >= 0:
				dict["player_one_dictionary"]["rank_points"] = differential
				dict["player_one_dictionary"]["rank"] += 1
			dict["player_two_dictionary"]["rank_points"] -= 1 # this part is so your rank points as the loser go down
			var differential2 = dict["player_two_dictionary"]["rank_points"]
			if differential2 < 0:# this part is so that if you go below 0 for rank points you rank down, unless you are at lowest rank then you stay at 0
				dict["player_two_dictionary"]["rank_points"] = 10 + differential2
				dict["player_two_dictionary"]["rank"] -= 1
				if dict["player_two_dictionary"]["rank"] < 0:
					dict["player_two_dictionary"]["rank"] = 0
					dict["player_two_dictionary"]["rank_points"] = 0
		if p1rank > p2rank: # if winner is higher rank
			dict["player_one_dictionary"]["rank_points"] += 1
			var differential = dict["player_one_dictionary"]["rank_points"] - 10 # this part is so that your rank points go back to 0 if you rank up
			if differential >= 0:
				dict["player_one_dictionary"]["rank_points"] = differential
				dict["player_one_dictionary"]["rank"] += 1
			# nothing happens to player 2 here, the loser, because you don't lose rank points if you are lower ranked
		if p1rank < p2rank: # if winner is lower rank
			dict["player_one_dictionary"]["rank_points"] += 3
			var differential = dict["player_one_dictionary"]["rank_points"] - 10 # this part is so that your rank points go back to 0 if you rank up
			if differential >= 0:
				dict["player_one_dictionary"]["rank_points"] = differential
				dict["player_one_dictionary"]["rank"] += 1
			dict["player_two_dictionary"]["rank_points"] -= 1 # this part is so your rank points as the loser go down
			var differential2 = dict["player_two_dictionary"]["rank_points"]
			if differential2 < 0:# this part is so that if you go below 0 for rank points you rank down, unless you are at lowest rank then you stay at 0
				dict["player_two_dictionary"]["rank_points"] = 10 + differential2
				dict["player_two_dictionary"]["rank"] -= 1
				if dict["player_two_dictionary"]["rank"] < 0:
					dict["player_two_dictionary"]["rank"] = 0
					dict["player_two_dictionary"]["rank_points"] = 0
	if winner == "two": # this part is for rank
		if p2rank == p1rank: # if ranks are equal
			dict["player_two_dictionary"]["rank_points"] += 2
			var differential = dict["player_two_dictionary"]["rank_points"] - 10 # this part is so that your rank points go back to 0 if you rank up
			if differential >= 0:
				dict["player_two_dictionary"]["rank_points"] = differential
				dict["player_two_dictionary"]["rank"] += 1
			dict["player_one_dictionary"]["rank_points"] -= 1 # this part is so your rank points as the loser go down
			var differential2 = dict["player_one_dictionary"]["rank_points"]
			if differential2 < 0:# this part is so that if you go below 0 for rank points you rank down, unless you are at lowest rank then you stay at 0
				dict["player_one_dictionary"]["rank_points"] = 10 + differential2
				dict["player_one_dictionary"]["rank"] -= 1
				if dict["player_one_dictionary"]["rank"] < 0:
					dict["player_one_dictionary"]["rank"] = 0
					dict["player_one_dictionary"]["rank_points"] = 0
		if p2rank > p1rank: # if winner is higher rank
			dict["player_two_dictionary"]["rank_points"] += 1
			var differential = dict["player_two_dictionary"]["rank_points"] - 10 # this part is so that your rank points go back to 0 if you rank up
			if differential >= 0:
				dict["player_two_dictionary"]["rank_points"] = differential
				dict["player_two_dictionary"]["rank"] += 1
			# nothing happens toplayer 1 here, the loser, because you don't lose rank points if you are lower ranked
		if p2rank < p1rank: # if winner is lower rank
			dict["player_two_dictionary"]["rank_points"] += 3
			var differential = dict["player_two_dictionary"]["rank_points"] - 10 # this part is so that your rank points go back to 0 if you rank up
			if differential >= 0:
				dict["player_two_dictionary"]["rank_points"] = differential
				dict["player_two_dictionary"]["rank"] += 1
			dict["player_one_dictionary"]["rank_points"] -= 1 # this part is so your rank points as the loser go down
			var differential2 = dict["player_one_dictionary"]["rank_points"]
			if differential2 < 0:# this part is so that if you go below 0 for rank points you rank down, unless you are at lowest rank then you stay at 0
				dict["player_one_dictionary"]["rank_points"] = 10 + differential2
				dict["player_one_dictionary"]["rank"] -= 1
				if dict["player_one_dictionary"]["rank"] < 0:
					dict["player_one_dictionary"]["rank"] = 0
					dict["player_one_dictionary"]["rank_points"] = 0			
	pass



@rpc("any_peer", "call_remote", "reliable")
func _ask_server_for_info(info_dictionary):
	info_dictionary["players"] = logged_in_firebase_ids.size()
	info_dictionary["matches"] = running_matches.size()
	rpc_id(multiplayer.get_remote_sender_id(), "_ask_server_for_info", info_dictionary)
	pass


#@rpc("any_peer", "call_remote", "reliable")	
#func _debug_vm(data):
	#await get_tree().create_timer(1).timeout
	#for i in multiplayer.get_peers():
		#rpc_id(i, "_debug_vm", data)
	#pass
