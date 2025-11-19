extends Control

signal player_reconnected(old_peer_id, new_peer_id, firebase_id)

var PORT = 7777
var MAX_PLAYERS = 1000

@onready var Database = get_node("/root/Firebase/Database")
@onready var RunningGames = get_node("RunningGames")
var initial_user_data: Dictionary = { 
	"country": "", "email": "@gmail.com", "experience": 0.0, "level": 0.0, "losses": 0.0, "matches_played": 0.0, "profilepic": 0.0, 
	"rank": 0.0, "username": "", "wins": 0.0, "music_enabled": true, "sound_enabled": true, "auto_skip_rules": false, "low_graphics_mode": false, 
	"rank_points": 0, "logged_in": false, "last_peer_id": 0,
	}
var peerid_to_firebaseid_dictionary = {}
var firebaseid_to_peerid_dictionary = {}
var logged_in_firebase_ids = []
var players_looking_for_match = []
var legendary_dictionary = {}
var running_matches = []
var process_test = false
var available_game_type_lists = {}
var game_types_ref
var user_information_ref
var selected_game_list_name
var selected_game_list
var selected_game_list_2 = ["HangmanChaosVanilla", "HangmanChaosShared", "HangmanChaosEphemeral", "HangmanTurnbased", "HangmanDelay", "HangmanDelayEphemeral"]
var timer_values_ref
var timer_values_dictionary = {"round_timer": 60, "match_found_timer": 5, "rules_screen_timer": 30, "score_timer": 10}
var pending_full_disconnect_array = []
var firebase_id_array = []
var connected_players : int = 0

func _ready():
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_start_server()
	Firebase.Auth.login_succeeded.connect(_on_FirebaseAuth_login_succeeded)
	Firebase.Auth.login_with_email_and_password("server@server.com", "supersonic")
	%RunningGames.connect("match_ended", _match_over_data_collection)

	printerr("server has logged in")

	pass

func _misc_to_firebase():
	var quick_ref = Firebase.Database.get_database_reference("server_data")	
	quick_ref.update("running_tallies", {"players_online": connected_players})
	quick_ref.update("running_tallies", {"running_matches": running_matches.size()})
func _process(_delta):
	
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
	user_information_ref = Firebase.Database.get_database_reference("users", {})
	user_information_ref.new_data_update.connect(_on_user_information_ref_update)
	user_information_ref.patch_data_update.connect(_on_user_information_ref_update)
	user_information_ref.delete_data_update.connect(_on_user_information_ref_update)	
	pass	
	
func _on_user_information_ref_update(resource):
	
	if resource.key.length() == 28:
		if not firebase_id_array.has(resource.key):
			firebase_id_array.append(resource.key)
	#for i in firebase_id_array:
		#user_information_ref = Firebase.Database.get_database_reference("users", {})	
		#user_information_ref.update(i, {"logged_in": false})
	#var key = resource.key
	#var data = resource.data
	#if typeof(data) == TYPE_BOOL:
		#return
	#if typeof(data) == TYPE_DICTIONARY:
		#if data.has("logged_in"):
			#if data["logged_in"]:
				#logged_in_firebase_ids.append(key)
			#else:
				#logged_in_firebase_ids.erase(key)
		#if data.has("last_peer_id"):
			#data["last_peer_id"] = int(data["last_peer_id"])
			#if firebaseid_to_peerid_dictionary.has(key):
				#
				#var old_peer_id = firebaseid_to_peerid_dictionary[key]
#
				#if %RunningGames.disconnected_limbo_firebase_ids.has(key):
#
					#player_reconnected.emit(old_peer_id, int(data["last_peer_id"]), key)			
				##peerid_to_firebaseid_dictionary.erase(old_peer_id)
				##firebaseid_to_peerid_dictionary.erase(key)
			#firebaseid_to_peerid_dictionary[key] = data["last_peer_id"]
			#
			#if pending_full_disconnect_array.has(key):
#
				#rpc_id(firebaseid_to_peerid_dictionary[key], "_full_disconnect_resolver")
				
		

 # here we will let the client know that they are connected to the server for the purpose of allowing them to now login through firebase
func _on_game_types_ref_update(resource):
	if resource.key == "selected_game":
		selected_game_list_name = resource.data 
	else:
		available_game_type_lists[str(resource.key)] = resource.data
	if available_game_type_lists != null and selected_game_list_name != null:
		if available_game_type_lists.has(selected_game_list_name):
			selected_game_list = available_game_type_lists[str(selected_game_list_name)]	

 
func _on_timer_ref_update(resource):
	if resource.key == "match_found_timer":
		timer_values_dictionary["match_found_timer"] = resource.data
	if resource.key == "round_timer":
		timer_values_dictionary["round_timer"] = resource.data
	if resource.key == "rules_screen_timer":
		timer_values_dictionary["rules_screen_timer"] = resource.data
	if resource.key == "score_timer":
		timer_values_dictionary["score_timer"] = resource.data
	$RunningGames.round_time = timer_values_dictionary["round_timer"]
	$RunningGames.match_found_time = timer_values_dictionary["match_found_timer"]
	$RunningGames.rules_time = timer_values_dictionary["rules_screen_timer"]
	$RunningGames.score_time = timer_values_dictionary["score_timer"]

	
func _on_peer_connected(id):
	print("connected id: " + str(id))
	rpc_id(id, "_confirm_connected_to_server")
	connected_players += 1
	_misc_to_firebase()
	pass

@rpc("any_peer")
func _quick_firebase_id_getter(fbid):
	printerr("quick getter running")
	firebaseid_to_peerid_dictionary[fbid] = multiplayer.get_remote_sender_id()
	peerid_to_firebaseid_dictionary[multiplayer.get_remote_sender_id()] = fbid
	if pending_full_disconnect_array.has(fbid): # this is if the person fully disconnected from match, but app still open in background
		rpc_id(firebaseid_to_peerid_dictionary[fbid], "_full_disconnect_resolver")
		return
	if %RunningGames.disconnected_limbo_firebase_ids.has(fbid): # this is if the person reconnects in time to continue the match
		%RunningGames._reconnect_handler(fbid)

	pass
	
func _on_peer_disconnected(id):
	
	connected_players -= 1
	print(str(id) + " has disconnected")
	# the logic for ending a game if a player disconnects
	if peerid_to_firebaseid_dictionary.has(id):
		var fbid = peerid_to_firebaseid_dictionary[id]
		for i in running_matches:
			if i["player_one_firebase_id"] == fbid or i["player_two_firebase_id"] == fbid:
				%RunningGames._disconnect_handler(i, fbid)
				#This part seems to be working fine.

		Firebase.Database.get_database_reference("users").update(peerid_to_firebaseid_dictionary[id],{"logged_in": false})
				
				
	if peerid_to_firebaseid_dictionary.has(id):
		logged_in_firebase_ids.erase(peerid_to_firebaseid_dictionary[id])
	if peerid_to_firebaseid_dictionary.has(id):
		peerid_to_firebaseid_dictionary.erase(id)
	_misc_to_firebase()

		
	pass


	

@rpc("any_peer", "call_remote", "reliable")
func _send_firebase_info_to_server(auth):
	var peer_id = multiplayer.get_remote_sender_id()
	#peerid_to_firebaseid_dictionary[peer_id] = auth["localid"]
	#logged_in_firebase_ids.append(auth["localid"])
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



@rpc("any_peer","call_remote")
func _lifeboat(firebase_id):
	print("lifeboat made it")
	Database.get_database_reference("users").update(firebase_id, {"logged_in": false})
	pass



@rpc("any_peer", "call_local")
func _disconnect_function(connected_player_peer_id, time_left):
	rpc_id(connected_player_peer_id, "_disconnect_function", connected_player_peer_id, time_left)
	pass
	
@rpc("any_peer", "call_local")
func _reconnect_function(p1id, p2id):
	rpc_id(p1id, "_reconnect_function", p1id, p2id)
	rpc_id(p2id, "_reconnect_function", p1id, p2id)
	pass



@rpc("any_peer", "call_local")
func _full_disconnect_function(dict, connected_player_firebase_id, disconnected_player_firebase_id):

	pending_full_disconnect_array.append(disconnected_player_firebase_id)
	#the following RPC is just so that the connected player who won by disconnection fades the reconnection pending overlay
	rpc_id(firebaseid_to_peerid_dictionary[dict["player_one_firebase_id"]], "_reconnect_function", 1, 2)
	rpc_id(firebaseid_to_peerid_dictionary[dict["player_two_firebase_id"]], "_reconnect_function", 1, 2)
	#rpc_id(firebaseid_to_peerid_dictionary[connected_player_firebase_id], "_reconnect_function", connected_player_firebase_id, disconnected_player_firebase_id)
	
	pass
	
@rpc("any_peer", "call_remote", "reliable")
func _full_disconnect_resolver():
	
	pass

@rpc("any_peer", "call_remote", "reliable")
func _full_disconnect_fulfilled(firebase_id):
	if pending_full_disconnect_array.has(firebase_id):
		pending_full_disconnect_array.erase(firebase_id)
	
