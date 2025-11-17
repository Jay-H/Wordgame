extends Node

signal database_update

var opponent_disconnected = false
var yoyoyoyoyo
var country
var experience
var matches_played
var rank
var level
var wins
var losses
var profilepic
var true_menu = "res://data/scenes_and_scripts/phoenix/true_menu.tscn"
var true_settings = "res://data/scenes_and_scripts/phoenix/true_settings.tscn"
var finding_match_scene = "res://data/scenes_and_scripts/phoenix/finding_match.tscn"
var score_screen = "res://data/scenes_and_scripts/phoenix/score_screen.tscn"
var match_over_scene = "res://data/scenes_and_scripts/phoenix/match_over.tscn"
var rules_scene = "res://data/scenes_and_scripts/phoenix/new_rules.tscn"
var single_player_scramble_scene = "res://data/scenes_and_scripts/scramble/single_player_scramble_client_scene.tscn"
var logged_in_to_firebase = false
@onready var Database = get_node("/root/Firebase/Database")
var my_client_id
var firebase_local_id
var firebase_email

#this one is used for the match over screen to retain a copy of the pre match dictionary for comparison for experience, level etc.
var pre_match_info
# if we add new fields to user dictionary on firebase, add them to my_info in blank sort of fashion, but not to old_info. 
#Also make sure to add them to the serverhost version for new accounts too.
# after you sync once with the server, add the entry to old_info
var my_info : Dictionary = { 
	"country": "", "email": "@gmail.com", "experience": 0.0, "level": 0.0, "losses": 0.0, "matches_played": 0.0, "profilepic": 0.0, 
	"rank": 0.0, "username": "", "wins": 0.0, "music_enabled": true, "sound_enabled": true, "auto_skip_rules": false, "low_graphics_mode": false,
	"rank_points": 0 , "logged_in": false, "last_peer_id": 0}
var old_info : Dictionary = { 
	"country": "", "email": "@gmail.com", "experience": 0.0, "level": 0.0, "losses": 0.0, "matches_played": 0.0, "profilepic": 0.0, 
	"rank": 0.0, "username": "", "wins": 0.0, "music_enabled": true, "sound_enabled": true, "auto_skip_rules": false, "low_graphics_mode": false,
	"rank_points": 0, "logged_in": false, "last_peer_id": 0}
var username
var db_ref
var path
#var IP_ADDRESS = "localhost"
var IP_ADDRESS = "136.112.186.218" # VM
var PORT = 7777
var match_found_instance
var rules_instance
var score_screen_instance
var match_over_screen_instance
var login_screen_instance
var true_menu_instance_reference
var auth_data
var number_of_players_online 
var number_of_matches_currently_being_played
var process_test = false
var connected_to_server = false

@onready var arguments = OS.get_cmdline_args()

func _notification_disconnector():
	var path = "users"
	var db_ref = Database.get_database_reference(path)
	db_ref.update(firebase_local_id, {"logged_in": false})
	await get_tree().process_frame
	await get_tree().process_frame
	
	pass

func _notification_reconnector():
	var path = "users"
	var db_ref = Database.get_database_reference(path)
	db_ref.update(firebase_local_id, {"logged_in": true})
	
	
func _on_disconnection_from_server():
	connected_to_server = false
	_notification_disconnector()
	pass

func _notification(what):
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_notification_disconnector()
		print("paused")
		if true_menu_instance_reference != null:
			true_menu_instance_reference._console_output("paused")
	if what == NOTIFICATION_APPLICATION_RESUMED:
		_notification_reconnector()
		print("resumed")
		if true_menu_instance_reference != null:
			true_menu_instance_reference._console_output("resumed")
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("wm_close_request")
		await get_tree().create_timer(1).timeout
		await _notification_disconnector()
		get_tree().quit()
	if what == NOTIFICATION_EXIT_TREE:
		print("exit tree")


func _unhandled_input(event):
	# Press 'P' to simulate a pause
	if event.is_action_pressed("ui_text_p"):
		print("--- DEBUG: Forcing PAUSE notification ---")
		propagate_notification(NOTIFICATION_APPLICATION_PAUSED)

	# Press 'R' to simulate a resume
	if event.is_action_pressed("ui_text_r"):
		print("--- DEBUG: Forcing RESUME notification ---")
		propagate_notification(NOTIFICATION_APPLICATION_RESUMED)
	
	if event.is_action_pressed("ui_text_d"):
		print("---DEBUG: Disconnecting from server... ---")
		if multiplayer.multiplayer_peer:
			multiplayer.multiplayer_peer.close()
			
	if event.is_action_pressed("ui_text_a"):
		print("---DEBUG: Reconnecting to server... ---")
		connect_to_server()


func _process(delta):
	if opponent_disconnected:
		if rules_instance != null:
			await rules_instance.fade_out()
			rules_instance.queue_free()
		if score_screen_instance != null:
			await score_screen_instance._fade_out()
			score_screen_instance.queue_free()
		if match_found_instance != null:
			await match_found_instance._fade_out()
			match_found_instance.queue_free()
		
	if process_test == false:
		process_test = true
		await get_tree().create_timer(1).timeout
		rpc_id(1, "_ask_server_for_info", {})
		process_test = false




func _ready():
	get_tree().set_auto_accept_quit(false)
	Globals._load_rules()
	print(arguments)
	%LoginScreen.connect("login_successful", _on_login_successful)
	#connect_to_server() # this function will also set the "my_client_id" variable at the top, so now we have all the identifying information together. 
	
	
#this function triggers from the login screen sending a signal.
#this signal includes the localid and email which are used on firebase
#it will set the variables at the top of this script and switch to the main menu which is called "true menu"	
func _on_login_successful(auth):

	#rpc_id(1, "_send_firebase_info_to_server",auth)
	firebase_local_id = auth["localid"]
	firebase_email = auth["email"]
	await _database_initializer(auth)
	if my_info["logged_in"] == true:
		login_screen_instance._already_logged_in()
	else:
		logged_in_to_firebase = true
		var path = "users"
		var db_ref = Database.get_database_reference(path)
		db_ref.update(firebase_local_id, {"logged_in": true})
		await %LoginScreen.fade_out()
		%LoginScreen.queue_free()
		var true_menu_instance = (load(true_menu)).instantiate()
		add_child(true_menu_instance)
		true_menu_instance_reference = true_menu_instance
		true_menu_instance.fade_in()
		true_menu_instance.username_changed.connect(_update_username)
		true_menu_instance.find_game_pressed.connect(_find_game)
		true_menu_instance.profilepic_changed.connect(_update_profilepic)
		_settings_signals_manager(true_menu_instance)
		auth_data = auth
		connect_to_server()

	
func _true_menu_fade_in():
	var true_menu_instance = (load(true_menu)).instantiate()
	print("running")
	add_child(true_menu_instance)
	true_menu_instance_reference = true_menu_instance
	
	_database_initializer(auth_data)
	true_menu_instance.fade_in()
	true_menu_instance.username_changed.connect(_update_username)
	true_menu_instance.find_game_pressed.connect(_find_game)
	true_menu_instance.profilepic_changed.connect(_update_profilepic)
	_settings_signals_manager(true_menu_instance)
	pass
	
#this function simply connects to the server. 
func connect_to_server():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(IP_ADDRESS, PORT)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		my_client_id = multiplayer.get_unique_id()
		
		if %LoginScreen != null:
			%LoginScreen.connected_to_server = true
		Database.get_database_reference("users").update(firebase_local_id, {"last_peer_id": multiplayer.get_unique_id()})
		multiplayer.server_disconnected.connect(_on_disconnection_from_server)
		connected_to_server = true
		_notification_reconnector()
	else:
		print(error)
	

@rpc("authority", "call_remote", "reliable")
func _send_firebase_info_to_server(firebase_id, firebase_email):
	pass

@rpc("authority", "call_remote", "reliable")
func _create_account(email, password):
	var result = await RpcAwait.send_rpc(1, _create_account.bind(email, password))
	
@rpc("authority", "call_remote", "reliable")
func _receive_new_profile_info(auth): # this signals the client that their registration was successful from the server, and lets them know to pull data from the database.
	_database_initializer(auth)
	pass


func _database_initializer(auth):
	
	path = "users/" + str(auth["localid"])
	var general_client_settings_path = "client_data"
	var client_settings_db_ref
	db_ref = Database.get_database_reference(path, {})
	db_ref.new_data_update.connect(_on_db_data_update)
	db_ref.patch_data_update.connect(_on_db_data_update)
	db_ref.delete_data_update.connect(_on_db_data_update)
	client_settings_db_ref = Database.get_database_reference(general_client_settings_path, {})
	client_settings_db_ref.new_data_update.connect(_client_settings_db_update)
	client_settings_db_ref.patch_data_update.connect(_client_settings_db_update)
	client_settings_db_ref.delete_data_update.connect(_client_settings_db_update)
	await get_tree().create_timer(1).timeout #give time for all the signals to propagage and populate our "my_info"	
	#db_ref.push_successful.connect(_on_db_data_update)
	#db_ref.push_failed.connect(_on_db_data_update)
	#db_ref.once_successful.connect(_on_db_data_update)
	#db_ref.once_failed.connect(_on_db_data_update)

func _client_settings_db_update(argument):
	print(argument)
	
	if argument.key == "scramble_constants":
		Globals.submit_mode = argument.data["submit_mode"]
		
	pass
	
func _on_db_data_update(argument): 
	if argument.key == "IPs":
		if argument.data["selected_ip"] == "VM":
			IP_ADDRESS = "136.112.186.218"
		if argument.data["selected_ip"] == "Local":
			IP_ADDRESS = "localhost"
	
	if argument.get("key") != "": # this is stupid, i dont know why the initial population has the key and value, but further updates just have the vale/"data"
		my_info[str(argument.get("key"))] = argument.get("data")
		old_info[str(argument.get("key"))] = argument.get("data")
	else:
		var quick_dict = argument.get("data")
		my_info[str(quick_dict.keys()[0])] = quick_dict.values()[0]
		old_info[str(quick_dict.keys()[0])] = quick_dict.values()[0]	
	# this part is in case we add something new to the dictionary that needs to be synced to firebase, it should update firebase.
	# i think it is safe for this to be done from client because it's essentially some default values.
	for i in my_info: 
		if old_info.has(i):
			pass
		if not old_info.has(i):
			var path = "users" 
			var db_ref = Database.get_database_reference(path)
			db_ref.update(firebase_local_id, {str(i): my_info[i]})
	pass
	database_update.emit()
	rpc_id(1, "_get_user_data_from_client", my_info)
	pass

@rpc("authority", "call_remote", "reliable")
func _update_profilepic(picture, firebase_local_id):

	rpc_id(1, "_update_profilepic", picture, firebase_local_id)	
	pass
	
@rpc("authority", "call_remote", "reliable")	
func _update_username(username, firebase_local_id):
	rpc_id(1, "_update_username", username, firebase_local_id)
	pass
	
@rpc("authority", "call_remote", "reliable")	
func _find_game(): #this is the function for when you are looking for a game. It takes away the menu and puts the finding match screen.
	await $TrueMenu._fade_out()
	$TrueMenu.queue_free()
	var finding_match_scene_instance = (load(finding_match_scene)).instantiate()
	finding_match_scene_instance._setup(my_info, null) # null here for when you don't know your opponent's information
	add_child(finding_match_scene_instance)
	match_found_instance = finding_match_scene_instance
	await finding_match_scene_instance._fade_in()
	finding_match_scene_instance.back_to_menu_pressed.connect(_cancel_find_game)
	rpc_id(1, "_find_game")
	pass

@rpc("authority", "call_remote", "reliable")	
func _cancel_find_game():
	rpc_id(1, "_cancel_find_game")
	await $FindingMatch._fade_out()
	$FindingMatch.queue_free()
	_true_menu_fade_in()
	pass

func _match_found_screen(my_info, opponent_info):
	pre_match_info = my_info
	$FindingMatch/CanvasLayer/BackToMenu.disabled = true
	await $FindingMatch._fade_out()
	$FindingMatch._setup(my_info, opponent_info)
	await $FindingMatch._fade_in()
	pass

func _fade_out_match_found_screen():
	if opponent_disconnected == false:
		await $FindingMatch._fade_out()
		$FindingMatch.queue_free()

func _show_rules_screen(rules, dict): #this function will choose the rules screen based on the game, and display it.
	if opponent_disconnected == false:
		#var scramble_rules = "res://data/scenes_and_scripts/phoenix/RulesTransition2.tscn"
		#var wordsearch_rules = "res://data/scenes_and_scripts/phoenix/RulesTransitionWordsearch.tscn"
		#var hangman_rules = "res://data/scenes_and_scripts/phoenix/HangmanRules.tscn"
		#var current_rules_node
		#if rules.contains("Scramble"):
			#current_rules_node = ((load(scramble_rules)).instantiate())
		#if rules.contains("Wordsearch"):
			#current_rules_node = ((load(scramble_rules)).instantiate())
		#if rules.contains("Hangman"):
			#current_rules_node = ((load(hangman_rules)).instantiate())
		var current_rules_node = load(rules_scene).instantiate()
		add_child(current_rules_node)
		current_rules_node._setup(rules, dict)
		rules_instance = current_rules_node
		current_rules_node.skip_button_pressed.connect(_skip_pressed.bind(dict))
		await current_rules_node._fade_in()
			
		pass

func _fade_out_rules_screen():
	if opponent_disconnected == false:
		if rules_instance != null:
			await rules_instance._fade_out()
			rules_instance.queue_free()
		else:
			return
	
func _score_screen(dict, big_dictionary):
	if opponent_disconnected == false:
		score_screen_instance = (load(score_screen).instantiate())
		score_screen_instance._setup(dict,big_dictionary,firebase_local_id)
		add_child(score_screen_instance)
		await score_screen_instance._fade_in()
	pass
	
func _fade_out_score_screen(dict):
	if opponent_disconnected == false:
		await score_screen_instance._fade_out()
		score_screen_instance.queue_free()
		pass


func _match_over_screen(dict):
	match_over_screen_instance = (load(match_over_scene)).instantiate()
	var player_number
	if dict["player_one_dictionary"]["email"] == firebase_email:
		player_number = "one"
		match_over_screen_instance._setup(dict["player_one_dictionary"], pre_match_info)
		
	else:
		player_number = "two"
		match_over_screen_instance._setup(dict["player_two_dictionary"], pre_match_info)
	
	add_child(match_over_screen_instance)
	await match_over_screen_instance._fade_in()
	match_over_screen_instance.timer.timeout.connect(_fade_out_match_over_screen) # we use a timer on the match_over_screen node itself for this last stage
	pass

func _fade_out_match_over_screen():
	await match_over_screen_instance._fade_out()
	match_over_screen_instance.queue_free()
	_true_menu_fade_in()
	opponent_disconnected = false
	pass




@rpc("authority", "call_remote", "reliable")	
func _get_user_data_from_client(data):
	pass

@rpc("authority", "call_remote", "reliable")
func _confirm_connected_to_server():
	if %LoginScreen != null:
		%LoginScreen.connected_to_server = true
	pass

@rpc("authority", "call_remote", "reliable")
func _verify_not_already_logged_in_firebase(auth):

	rpc_id(1, "_verify_not_already_logged_in_firebase", auth)
	pass

@rpc("authority", "call_remote", "reliable")
func _logged_in_verification_result(auth, result):
	if result == "already logged in":
		if %LoginScreen != null:
			%LoginScreen._already_logged_in()

	else: 
		_on_login_successful(auth)
	pass

#The next two functions recieve signals regarding the settings screen and send the state of those toggles to firebase

func _settings_signals_manager(true_menu_instance):
	true_menu_instance.music_enabled.connect(_settings_to_firebase.bind("music_enabled"))
	true_menu_instance.music_disabled.connect(_settings_to_firebase.bind("music_disabled"))
	true_menu_instance.sound_enabled.connect(_settings_to_firebase.bind("sound_enabled"))
	true_menu_instance.sound_disabled.connect(_settings_to_firebase.bind("sound_disabled"))
	true_menu_instance.auto_skip_rules_enabled.connect(_settings_to_firebase.bind("auto_skip_rules_enabled"))
	true_menu_instance.auto_skip_rules_disabled.connect(_settings_to_firebase.bind("auto_skip_rules_disabled"))
	true_menu_instance.low_graphics_enabled.connect(_settings_to_firebase.bind("low_graphics_enabled"))
	true_menu_instance.low_graphics_disabled.connect(_settings_to_firebase.bind("low_graphics_disabled"))

	pass

func _settings_to_firebase(signal_name):
	var path = "users"
	var db_ref = Database.get_database_reference(path)
	
	if signal_name == "music_enabled":
		db_ref.update(firebase_local_id, {"music_enabled": true})
		pass
	if signal_name == "music_disabled":
		db_ref.update(firebase_local_id, {"music_enabled": false})
		pass
	if signal_name == "sound_enabled":
		db_ref.update(firebase_local_id, {"sound_enabled": true})
		pass
	if signal_name == "sound_disabled":
		db_ref.update(firebase_local_id, {"sound_enabled": false})
		pass
	if signal_name == "auto_skip_rules_enabled":
		db_ref.update(firebase_local_id, {"auto_skip_rules": true})
		pass
	if signal_name == "auto_skip_rules_disabled":
		db_ref.update(firebase_local_id, {"auto_skip_rules": false})
		pass
	if signal_name == "low_graphics_enabled":
		db_ref.update(firebase_local_id, {"low_graphics_mode": true})
		pass
	if signal_name == "low_graphics_disabled":
		db_ref.update(firebase_local_id, {"low_graphics_mode": false})
		pass
	if signal_name == "logged_in":
		db_ref.update(firebase_local_id, {"logged_in": true})
	pass	

func _skip_pressed(dict):
	$RunningGames._skip_rules_pressed(dict)
	pass

@rpc("authority", "call_remote", "reliable")
func _ask_server_for_info(info_dictionary):
	number_of_players_online = info_dictionary["players"]
	number_of_matches_currently_being_played = info_dictionary["matches"]
	pass


func _start_single_player_game(parameters):
	await $TrueMenu._fade_out()
	$TrueMenu.queue_free()
	if parameters[0] == "Scramble":
		var single_player_node_instance = load(single_player_scramble_scene).instantiate()
		single_player_node_instance.game_over.connect(_end_single_player_game)
		single_player_node_instance._setup(parameters)
		add_child(single_player_node_instance)
		print(single_player_node_instance)
		
	pass

func _end_single_player_game(node):
	print(node)
	_true_menu_fade_in()
	node.queue_free()
	
#@rpc("authority", "call_remote", "reliable")	
#func _debug_vm(data):
	##print(data)
	#pass
