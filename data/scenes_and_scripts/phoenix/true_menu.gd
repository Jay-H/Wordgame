extends Control

signal username_changed
signal find_game_pressed
signal profilepic_changed
signal sound_enabled
signal sound_disabled
signal music_enabled
signal music_disabled
signal logout_pressed
signal auto_skip_rules_enabled
signal auto_skip_rules_disabled
signal low_graphics_enabled
signal low_graphics_disabled

@onready var main_menu = get_parent()


func _process(delta):
	%PlayersOnline.text = "Players Online: " + str(main_menu.number_of_players_online)
	%MatchesRunning.text = "Matches Running: " + str(main_menu.number_of_matches_currently_being_played)
	pass

func _ready():
	main_menu.connect("database_update", _database_update)
	%Hider.color = Color.WHITE
	visible = false
	%MainMenuBox.modulate = Color.TRANSPARENT
	%PlayersOnline.modulate = Color.TRANSPARENT
	%MatchesRunning.modulate = Color.TRANSPARENT
	await get_tree().process_frame
	var initial_position = %MainMenuBox.global_position
	print(initial_position)
	%MainMenuBox.position.x = initial_position.x - 1000
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(%MainMenuBox, "position", initial_position, 2)
	tween.parallel().tween_property(%MainMenuBox, "modulate", Color.WHITE, 2)
	tween.parallel().tween_property(%PlayersOnline, "modulate", Color.WHITE, 2)
	tween.parallel().tween_property(%MatchesRunning, "modulate", Color.WHITE, 2)
	%WeatherTimer.start(10)
	%WeatherTimer.timeout.connect(_weather_function)
func fade_in():
	%Hider.color = Color.WHITE
	visible = true
	var tween = create_tween()
	tween.tween_property(%Hider, "color", Color.TRANSPARENT, 0.5)

func _fade_out():
	%CanvasModulate.color = Color.WHITE
	visible = true
	var tween = create_tween()
	tween.tween_property(%CanvasModulate, "color", Color.TRANSPARENT, 0.5)
	
	await tween.finished
	
	return
	
func _on_profile_pressed() -> void:
	Haptics.stacatto_doublet()
	await %MainMenuItems._fade_out()
	
	%ProfileMenuItems._fade_in()
	
	pass # Replace with function body.


func _on_change_username_pressed() -> void:
	if %NewUsername.text.length() > 3 and %NewUsername.text.length() < 13:
		username_changed.emit(%NewUsername.text, main_menu.firebase_local_id)
		%NewUsername.text = ""
		return
	if %NewUsername.text.length() < 4:
		%ProfileMenuItems._username_entry_flash_red("TOO SHORT!")
		return
	if %NewUsername.text.length() > 12:
		%ProfileMenuItems._username_entry_flash_red("TOO LONG!")
		return
	pass # Replace with function body.

func _on_profile_pic_changed(picture):
	profilepic_changed.emit(picture, main_menu.firebase_local_id)

func _database_update(): # this gets triggered by signal whenever data is updated on the firebase server
	var my_info = main_menu.my_info

	if my_info.has_all(["username", "rank", "level", "wins", "losses", "matches_played", "profilepic"]):
		
		var old_username = %CurrentUsername.text
		%CurrentUsername.text = my_info["username"]
		if old_username != %CurrentUsername.text:
			%ProfileMenuItems._username_flash_green()
		%rank.text = "Rank: " + str(Globals.rank_name_array[my_info["rank"]])
		%level.text = "Level " + str(int(my_info["level"])) + ": " + str(Globals.level_name_array[my_info["level"]])
		%wins.text = "Wins: " + str(int(my_info["wins"]))
		%losses.text = "Losses: " + str(int(my_info["losses"]))
		%matchesplayed.text = "Matches: " + str(int(my_info["matches_played"]))	
		%ProfilePicture.setup(GlobalData.profile_pics[my_info["profilepic"]])
		if my_info["auto_skip_rules"] == true:
			%AutoSkipRulesSwitch.button_pressed = true
		if my_info["low_graphics_mode"] == true:
			%LowGraphicsSwitch.button_pressed = true


func _on_find_game_pressed() -> void:
	Haptics.stacatto_doublet()
	find_game_pressed.emit()
	pass # Replace with function body.


func _on_settings_pressed() -> void:
	Haptics.stacatto_doublet()
	await %MainMenuItems._fade_out()
	%SettingsMenuItems._fade_in()
	pass # Replace with function body.
	
func _on_music_switch_toggled(toggled_on: bool) -> void:
	Haptics.triple_quick_medium()
	if toggled_on:
		music_enabled.emit()
	if not toggled_on:
		music_disabled.emit()
	pass # Replace with function body.


func _on_sound_switch_toggled(toggled_on: bool) -> void:
	Haptics.triple_quick_medium()
	if toggled_on:
		sound_enabled.emit()
	if not toggled_on:
		sound_disabled.emit()
	pass # Replace with function body.


func _on_auto_skip_rules_switch_toggled(toggled_on: bool) -> void:
	Haptics.triple_quick_medium()
	if toggled_on:
		auto_skip_rules_enabled.emit()
	if not toggled_on:
		auto_skip_rules_disabled.emit()
	pass # Replace with function body.


func _on_low_graphics_switch_toggled(toggled_on: bool) -> void:
	Haptics.triple_quick_medium()
	if toggled_on:
		low_graphics_enabled.emit()
	if not toggled_on:
		low_graphics_disabled.emit()
	pass # Replace with function body.


func _on_single_player_pressed() -> void:
	Haptics.stacatto_doublet()
	await %MainMenuItems._fade_out()
	%SinglePlayerMenuItems._fade_in()
	pass # Replace with function body.


func _single_player_start(parameters):
	main_menu._start_single_player_game(parameters)
	pass


func _on_debug_pressed() -> void:
	add_child(load("res://data/scenes_and_scripts/phoenix/vibration_tester.tscn").instantiate())
	pass # Replace with function body.

func _weather_function():
	%RainParticles.amount_ratio = 0
	%RainParticles.emitting = true
	%SoakSpotControl._begin(5)
	var tween = create_tween()
	tween.tween_property(%RainParticles, "amount_ratio", 1.0, 25)
