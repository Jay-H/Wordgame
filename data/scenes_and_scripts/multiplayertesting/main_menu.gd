extends Control
signal background_chosen

var IP_ADDRESS =  "127.0.0.1"          #"localhost"    "99.232.235.123"
var PORT = 7777
var firstsceneclient = "res://data/scenes_and_scripts/multiplayertesting/FirstSceneClient.tscn" 
var finding_match_scene = "res://data/scenes_and_scripts/multiplayertesting/finding_match.tscn"
var finding_match_current_node
var rules_screen_scramble = "res://data/scenes_and_scripts/scramble/RulesTransition2.tscn"
var rules_scene_instance
var rules_screen_wordsearch = "res://data/scenes_and_scripts/scramble/RulesTransitionWordsearch.tscn"
var round_end_screen = "res://data/scenes_and_scripts/multiplayertesting/round_end_screen.tscn"
var round_end_screen_current_node
var matchmaking_timer_node
var find_match_pressed = false
var current_game_type
@onready var arguments = OS.get_cmdline_args()
@export var username : String
var player_number

var scramble_client_scene = "res://data/scenes_and_scripts/scramble/scramble_client_scene.tscn"
var current_game_node
var current_background_resource
var current_background_string
var profile_info
var opponent_information_dictionary : Dictionary

var pre_game_experience
var post_game_experience

@onready var client_side_save_path = "res://data/text_files/clientside.json"
@onready var file = FileAccess.open(client_side_save_path, FileAccess.READ)
@onready var client_side_dictionary = JSON.parse_string(file.get_as_text())

func _init():
	pass

func _ready():
	print(client_side_dictionary)
	print(client_side_dictionary["Background"])
	#username = arguments[1]
	#var peer = ENetMultiplayerPeer.new()
	# Create the client and connect to the server.
	#peer.create_client(IP_ADDRESS, PORT)
	
	# Set this new peer as the multiplayer peer.
	#multiplayer.multiplayer_peer = peer
	%StatusLabel.text = "Connecting..."
	#var profile_pic_path = "res://data/images/profilepics/" + username + ".jpg"
	#
	#%profilepic.texture = load(profile_pic_path)
	
	
	# Signal when the connection succeeds.
	#multiplayer.connected_to_server.connect(_on_connected_to_server)
	
	%findmatch.connect("pressed",find_match)
	%leaderboard.connect("pressed",on_leaderboard_pressed)
	%ProfilePicture.connect("pressed", on_profilepic_pressed)
	
	
	
func _process(delta: float) -> void:
	#if matchmaking_timer_node!=null:
		#print(matchmaking_timer_node.time_left)
	
	pass
	
func find_match():
	if find_match_pressed == false:
		find_match_pressed = true
		%FadeBox.fade_in()
		%findmatch.add_theme_color_override("font_color", Color.GREEN)
		var userid = multiplayer.get_unique_id()
		var finding_match_scene = load(finding_match_scene)
		var finding_match_scene_instance = finding_match_scene.instantiate()
		finding_match_scene_instance.setup(username, "opponent", profile_info, null) # this instance is the first one where you are waiting for an opponent.
		%Particles.emitting = true
		await get_tree().create_timer(1).timeout
		%Particles.emitting = false
		add_child(finding_match_scene_instance)
		%findmatch.add_theme_color_override("font_color", Color.BLACK)
		finding_match_current_node = finding_match_scene_instance
		rpc_id(1, "matchmaking", username)
		%FadeBox.visible = true
	

@rpc("any_peer", "call_local", "reliable")	
func start_game(username1, username2, userid1, userid2):
	pre_game_experience = profile_info["Experience"]
	%MatchmakingTimer.start()
	
	
	%RunningGames.visible = false
	if finding_match_current_node != null:
		print("if statement working")
		finding_match_current_node.fade_out()
		await get_tree().create_timer(1).timeout
		finding_match_current_node.queue_free()
		var my_username = username
		var both_usernames = [username1,username2]
		for i in both_usernames:
			if i == my_username:
				both_usernames.erase(i)
		var opponent_username = both_usernames[0]
		var finding_match_scene = load(finding_match_scene)
		var finding_match_scene_instance = finding_match_scene.instantiate()
		var opponent_info = await RpcAwait.send_rpc(1, (serve_opponent_information.bind(opponent_username)))
		print(opponent_info)
		opponent_information_dictionary = opponent_info
		finding_match_scene_instance.setup(username1, username2, profile_info, opponent_info) # this instance is the second time it shows, but with the name of the opponent who you are facing.
		finding_match_current_node = finding_match_scene_instance 
		add_child(finding_match_scene_instance)

	
	
	
@rpc("authority", "call_local", "reliable")	
func game_spawner(username1, username2, userid1, userid2,gametype):
	print("client side game spawner run")
	current_game_type = gametype
	var scramble_node = load(scramble_client_scene)
	var scramble_instance = scramble_node.instantiate()
	var scramble_instance_name = "ScrambleScene" + username1 + username2
	scramble_instance.name = scramble_instance_name
	scramble_instance.set_meta("userid1", userid1)
	scramble_instance.set_meta("userid2", userid2)
	scramble_instance.setup(current_background_string)

	var wordsearch_instance = (load("res://data/scenes_and_scripts/wordsearch/WordSearch.tscn")).instantiate()
	var wordsearch_instance_name = "WordsearchScene" + username1 + username2
	wordsearch_instance.name = wordsearch_instance_name
	wordsearch_instance.set_meta("userid1", userid1)
	wordsearch_instance.set_meta("userid2", userid2)
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
		wordsearch_instance.variant = Globals.WordsearchVariants.DEFAULT
	if gametype == "WordsearchShared":
		wordsearch_instance.variant = Globals.WordsearchVariants.SHARED_BOARD
	if gametype == "WordsearchHidden":
		wordsearch_instance.variant = Globals.WordsearchVariants.HIDDEN		
	if gametype.contains("Scramble"):	
		%RunningGames.add_child(scramble_instance)
		current_game_node = scramble_instance
	if gametype.contains("Wordsearch"):	
		%RunningGames.add_child(wordsearch_instance)		
		current_game_node = wordsearch_instance
	
	var scramble_game = scramble_instance
	if username1 == username:
		player_number = 1
	else:
		player_number = 2
	

func _on_connected_to_server():
	var userid = multiplayer.get_unique_id()
	var information = [username, userid]
	print("connected")
	%StatusLabel.text = "Connected"
	rpc_id(1, "player_to_server", information)
	
	pass

@rpc("authority", "call_local", "reliable")
func player_to_server(information):
	
	pass
	
@rpc("any_peer", "call_local", "reliable")	
func matchmaking(userid): 
	pass



@rpc("authority", "call_remote", "reliable")
func server_to_player(info_from_server):
	
	%StatusLabel.text = "Online Players: " + str(info_from_server)
	rpc_id(1, "save_game_synchronizer", null)

@rpc("authority", "call_local", "reliable")
func save_game_synchronizer(player_id): 
	pass

@rpc("any_peer", "call_local", "reliable")
func rules_skip():
	
	if rules_scene_instance != null:
		
		rules_scene_instance.fade_out()
		await get_tree().create_timer(3).timeout
		rules_scene_instance.queue_free()
		%RulesTimer.stop()
	pass

@rpc("authority", "call_remote", "reliable")
func match_making_fade(username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer):
	print("CHUNGUS")
	print(finding_match_current_node)
	if finding_match_current_node != null:
		finding_match_current_node.fade_out()
		await get_tree().create_timer(1).timeout
		finding_match_current_node.queue_free()
	pass
	
@rpc("authority", "call_remote", "reliable")	
func rules_fade(username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer):
	%PregameTimer.start()
	print("rules fade worked on client")
	if rules_scene_instance != null:
		rules_scene_instance.fade_out()
		
		await get_tree().create_timer(1).timeout
		#rules_scene_instance.queue_free()
	await get_tree().create_timer(1).timeout
	%FadeBox.fade_out()
	pass
	
@rpc("authority", "call_remote", "reliable")	
func rules_load(username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer):
	%RulesTimer.start()

	if current_game_type.contains("Scramble"):
		var rules_scene = load(rules_screen_scramble)
		rules_scene_instance = rules_scene.instantiate()
		rules_scene_instance.setup(username1,username2,current_game_type, opponent_information_dictionary, profile_info)
		add_child(rules_scene_instance)
		rules_scene_instance.fade_in()
		%RunningGames.visible = true
	if current_game_type.contains("Wordsearch"):
		var rules_scene = load(rules_screen_wordsearch)
		rules_scene_instance = rules_scene.instantiate()
		var converted_game_type #this is so bad; we change the name to the scramble type of name, so that I didnt have to change too much on the rules screen
		if current_game_type == "WordsearchVanilla":
			converted_game_type = "ScrambleBonus"
		if current_game_type == "WordsearchShared":
			converted_game_type = "ScrambleWonder"
		if current_game_type == "WordsearchHidden":
			converted_game_type = "ScrambleObscurity"
		print(current_game_type)
		print(converted_game_type)
		rules_scene_instance.setup(username1,username2,converted_game_type, opponent_information_dictionary, profile_info)
		add_child(rules_scene_instance)
		%RunningGames.visible = true
	
@rpc("authority", "call_remote", "reliable")	
func pregame_timer_finished(username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer):
	print("clientside pregame timer finished")
	if current_game_node != null:
		current_game_node.fade_pregame()
	pass	

@rpc("authority", "call_local", "reliable")	
func game_ender(minigame_node, username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer, player_one_wins, player_two_wins, current_games, user_one_dictionary, user_two_dictionary):
	var user_one_score
	var user_two_score

	print("minigame_node is:   ", minigame_node)
	print(current_game_node)
	if current_game_node.name.contains("Scramble"):
		user_one_score = current_game_node.big_dictionary["Player One Score"]
		user_two_score = current_game_node.big_dictionary["Player Two Score"]
	else:
		user_one_score = ""
		user_two_score = ""
	var round_end = load(round_end_screen).instantiate()
	round_end.setup(username1, username2, user_one_score, user_two_score, player_one_wins, player_two_wins, player_number, current_games, user_one_dictionary, user_two_dictionary, profile_info, opponent_information_dictionary)
	%FadeBox.fade_in()
	add_child(round_end)
	round_end_screen_current_node = round_end
	await get_tree().create_timer(1).timeout
	current_game_node.queue_free()
	print("game over")

@rpc("authority", "call_local", "reliable")		
func round_end_screen_fade(username1, username2, userid1, userid2, rulestimer, matchmakingtimer, pregametimer):
	round_end_screen_current_node.fade_out()
	await get_tree().create_timer(1).timeout
	round_end_screen_current_node.queue_free()
	
	pass
	
@rpc("authority", "call_local", "reliable")		
func full_game_ender(username1, username2, userid1, userid2):
	
	%FadeBox.fade_out()
	level_up_screen_load()
	find_match_pressed = false
	pass

func on_profilepic_pressed():
	%ProfileScreen.setup()
	%ProfileScreen.visible = true
	
	print(profile_info)
	pass

func on_leaderboard_pressed():
	print("leaderboard pressed")
	%LeaderboardScreen.get_leaderboard_information()
	%LeaderboardScreen.visible = true
	pass
	
@rpc("authority", "call_local", "reliable")	
func receive_profile_info_from_server(player_info):
	
	profile_info = player_info
	
	if profile_info.has("ProfilePic") and profile_info["ProfilePic"] != null:
		%profilepic.texture = load(profile_info["ProfilePic"])
	if profile_info.has("Level"):
		%level.text = "Level " + str(int(profile_info["Level"])) + ": " + str(Globals.level_name_array[profile_info["Level"]])
	if profile_info.has("Experience"):
		%experiencebar.setup(profile_info["Experience"])
	if profile_info.has("Rank"):
		%rank.text = "Rank: " + str(Globals.rank_name_array[profile_info["Rank"]])
	print("receive function run")
	%username.text = "Welcome " +str(username)
	pass


@rpc("authority", "call_remote", "reliable")	
func login_authenticator(user, password):
	var callable = (login_authenticator.bind(user, password))
	var valid = await RpcAwait.send_rpc(1, callable)
	if valid == "valid user":
		%Login.visible = false
		username = user
		_on_connected_to_server()
	else:
		print("invalid")
	

@rpc("authority", "call_remote", "reliable")	
func username_available_authenticator(username):
	var callable = (username_available_authenticator.bind(username))
	var exists = await RpcAwait.send_rpc(1, callable)
	if not exists:
		%Login.make_password_chooser_available(username)
	if exists:
		%Login.unavailable()

@rpc("authority", "call_remote", "reliable")	
func password_registration(username, password):
	rpc_id(1, "password_registration", username, password)
	pass

func connect_to_server():
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer
	%LeaderboardScreen.get_leaderboard_information()
	print(multiplayer.get_unique_id())
	
	pass

@rpc("authority", "call_remote", "reliable")	
func update_profile_pic(picture):
	
	await RpcAwait.send_rpc(1, (update_profile_pic.bind(picture)))
	%ProfilePicture.setup(load(profile_info["ProfilePic"]))
	pass

@rpc("authority", "call_remote", "reliable")	
func serve_opponent_information(username, information):
	pass

func level_up_screen_load():
	await RpcAwait.send_rpc(1,(save_game_synchronizer.bind(multiplayer.get_unique_id())))
	post_game_experience = profile_info["Experience"]
	var level_up_screen_instance = (load("res://data/scenes_and_scripts/multiplayertesting/level_up_screen.tscn")).instantiate()
	level_up_screen_instance.setup(pre_game_experience, post_game_experience, profile_info)
	add_child(level_up_screen_instance)
	


func _on_music_toggle_pressed() -> void:
	pass # Replace with function body.


func _on_quick_login_a_pressed() -> void:
	connect_to_server()
	await get_tree().create_timer(0.25).timeout
	login_authenticator("Auron","a")
	await get_tree().create_timer(0.25).timeout
	find_match()
	
	pass # Replace with function body.


func _on_quick_login_b_pressed() -> void:
	connect_to_server()
	await get_tree().create_timer(0.25).timeout
	login_authenticator("Tidus","a")
	await get_tree().create_timer(0.25).timeout
	find_match()
	pass # Replace with function body.
	
@rpc("authority", "call_remote", "reliable")	
func cancel_find_match(userid):
	var user_id = multiplayer.get_unique_id()
	%Particles.visible = false
	rpc_id(1, "cancel_find_match", user_id)
	find_match_pressed = false
	%FadeBox.fade_out()
	
	
	pass


func _on_settings_pressed() -> void:
	print("settings pressed ")
	%SettingsScene.visible = true
	%SettingsScene.fade_in()
	pass # Replace with function body.

func background_setter(bgname):
	current_background_resource = Globals.backgrounds_dictionary[bgname]
	current_background_string = bgname
	
	
