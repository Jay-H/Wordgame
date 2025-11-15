extends Control

var firebase_local_id
var player_number
@onready var main_menu = get_parent()
@onready var winner_light = %WinnerLightPanel.duplicate()
@onready var loser_light = %LoserLightPanel.duplicate()
var dictionary
var current_game
var current_game_like_value
var db_ref
var path


func _ready():
	var game_likes_ref
	path = "server_data/game_likes/" 
	game_likes_ref = Firebase.Database.get_database_reference(path, {})
	game_likes_ref.new_data_update.connect(_game_likes_ref_collector)
	game_likes_ref.patch_data_update.connect(_game_likes_ref_collector)
	game_likes_ref.delete_data_update.connect(_game_likes_ref_collector)
	db_ref = game_likes_ref
	await get_tree().create_timer(1).timeout
	_light_mover(dictionary)


func _game_likes_ref_collector(resource):
	if resource.key == str(current_game):
		var like_value = int(resource.data)
		current_game_like_value = like_value
	if resource.key == "":
		if resource.data.has(str(current_game)):
			current_game_like_value = resource.data[str(current_game)] 
		
	pass

func _setup(dict, big_dictionary, firebase_id):
	%Thanks.modulate = Color.TRANSPARENT
	dictionary = dict
	firebase_local_id = firebase_id
	current_game = dictionary["selected_games"][dict["current_round"]]
	var player_one_username = dict["player_one_dictionary"]["username"]
	var player_two_username = dict["player_two_dictionary"]["username"]
	if firebase_local_id == dict["player_one_firebase_id"]:
		player_number = "one"
		%playerpic.setup(GlobalData.profile_pics[dict["player_one_dictionary"]["profilepic"]])
		%opponentpic.setup(GlobalData.profile_pics[dict["player_two_dictionary"]["profilepic"]])
	else:
		player_number = "two"	
		%playerpic.setup(GlobalData.profile_pics[dict["player_two_dictionary"]["profilepic"]])
		%opponentpic.setup(GlobalData.profile_pics[dict["player_one_dictionary"]["profilepic"]])
	if (big_dictionary.has("game_type") && big_dictionary["game_type"] == "wordsearch"):
		if firebase_local_id == dict["player_one_firebase_id"]:
			player_number = "one"
		else:
			player_number = "two"		
		if player_number == "one":
			%playerscore.text = ""
			%opponentscore.text = ""
			%playerbestword.text = ""
			%opponentbestword.text = ""
			%playername.text = dict["player_one_dictionary"]["username"]
			%opponentname.text = dict["player_two_dictionary"]["username"]
		if player_number == "two":
			%playerscore.text = ""
			%opponentscore.text = ""
			%playerbestword.text = ""
			%opponentbestword.text = ""
			%playername.text = dict["player_two_dictionary"]["username"]
			%opponentname.text = dict["player_one_dictionary"]["username"]
	elif (big_dictionary.has("game_type") && big_dictionary["game_type"] == "hangman"):
		if firebase_local_id == dict["player_one_firebase_id"]:
			player_number = "one"
		else:
			player_number = "two"		
		if player_number == "one":
			%playerscore.text = "Guesses\n" + str(big_dictionary["player_one_wrong_guesses"])
			%opponentscore.text = "Guesses\n" + str(big_dictionary["player_two_wrong_guesses"])
			%playerbestword.text = "Last Guess\n" + str(big_dictionary["player_one_last_guess"])
			%opponentbestword.text = "Last Guess\n" + str(big_dictionary["player_two_last_guess"])
			%playername.text = dict["player_one_dictionary"]["username"]
			%opponentname.text = dict["player_two_dictionary"]["username"]
		if player_number == "two":
			%playerscore.text = "Guesses\n" + str(big_dictionary["player_two_wrong_guesses"])
			%opponentscore.text = "Guesses\n" + str(big_dictionary["player_one_wrong_guesses"])
			%playerbestword.text = "Last Guess\n" + str(big_dictionary["player_two_last_guess"])
			%opponentbestword.text = "Last Guess\n" + str(big_dictionary["player_one_last_guess"])
			%playername.text = dict["player_two_dictionary"]["username"]
			%opponentname.text = dict["player_one_dictionary"]["username"]	
	else:
		var player_one_best_word = best_word_finder(big_dictionary["Player One Found Words"])
		var player_two_best_word = best_word_finder(big_dictionary["Player Two Found Words"])
		if firebase_local_id == dict["player_one_firebase_id"]:
			player_number = "one"
		else:
			player_number = "two"

		if player_number == "one":
			%playerscore.text = "Score\n" + str(big_dictionary["Player One Score"]) 
			%opponentscore.text = "Score\n" + str(big_dictionary["Player Two Score"]) 
			%playerbestword.text = "Best Word\n" + player_one_best_word
			%opponentbestword.text = "Best Word\n" + player_two_best_word
			%playername.text = dict["player_one_dictionary"]["username"]
			%opponentname.text = dict["player_two_dictionary"]["username"]
		if player_number == "two":
			%playerpic.setup(GlobalData.profile_pics[dict["player_two_dictionary"]["profilepic"]])
			%opponentpic.setup(GlobalData.profile_pics[dict["player_one_dictionary"]["profilepic"]])
			%playerscore.text = "Score\n" + str(big_dictionary["Player Two Score"]) 
			%opponentscore.text = "Score\n" + str(big_dictionary["Player One Score"]) 
			%playerbestword.text = "Best Word\n" + player_two_best_word
			%opponentbestword.text = "Best Word\n" + player_one_best_word
			%playername.text = dict["player_two_dictionary"]["username"]
			%opponentname.text = dict["player_one_dictionary"]["username"]	

		
	if dict.has("round1winner"):
		print(dict["round1winner"])
		if dict["round1winner"] == "one":
			%round1winner.text = "Round 1: " + player_one_username
		if dict["round1winner"] == "two":
			%round1winner.text = "Round 1: " + player_two_username
	if dict.has("round2winner"):
		if dict["round2winner"] == "one":
			%round2winner.text = "Round 2: " + player_one_username
		if dict["round2winner"] == "two":
			%round2winner.text = "Round 2: " + player_two_username
	if dict.has("round3winner"):
		if dict["round3winner"] == "one":
			%round3winner.text = "Round 3: " + player_one_username
		if dict["round3winner"] == "two":
			%round3winner.text = "Round 3: " + player_two_username
	pass

func _light_mover(dict):
	var current_round_string
	var number
	print(dict["current_round"])
	if dict["current_round"] == 0:
		current_round_string = "round1winner"
	if dict["current_round"] == 1:
		current_round_string = "round2winner"
	if dict["current_round"] == 2:
		current_round_string = "round3winner"
	if firebase_local_id == dict["player_one_firebase_id"]:
		number = "one"
	else:
		number = "two"	
	if number == "one":
		if dict[str(current_round_string)] == "one":
			%playerpic.add_child(winner_light)
			%opponentpic.add_child(loser_light)
			#%WinnerLightPanel.global_position = %playerpic.global_position
			#%LoserLightPanel.global_position = %opponentpic.global_position
		else:
			%playerpic.add_child(loser_light)
			%opponentpic.add_child(winner_light)
			#%LoserLightPanel.global_position = %playerpic.global_position
			#%WinnerLightPanel.global_position = %opponentpic.global_position			
	if number == "two":
		if dict[str(current_round_string)] == "two":
			%playerpic.add_child(winner_light)
			%opponentpic.add_child(loser_light)
			#%WinnerLightPanel.global_position = %playerpic.global_position
			#%LoserLightPanel.global_position = %opponentpic.global_position
		else:
			%playerpic.add_child(loser_light)
			%opponentpic.add_child(winner_light)
			#%LoserLightPanel.global_position = %playerpic.global_position
			#%WinnerLightPanel.global_position = %opponentpic.global_position	
	var tween = create_tween()
	winner_light.modulate = Color.TRANSPARENT
	loser_light.modulate = Color.TRANSPARENT
	winner_light.visible = true
	loser_light.visible = true
	tween.tween_property(winner_light, "modulate", Color.WHITE, 1)
	tween.tween_property(loser_light, "modulate", Color.WHITE, 1)	
	pass

func best_word_finder(found_words):
	var best_word 
	var best_word_score : int = 0
	for i in found_words:
		var score = word_scorer(i)
		if score > best_word_score:
			best_word_score = score
			best_word = i
	if best_word == null:
		best_word = "no words..."
	return str(best_word)
	
func word_scorer(word): # this will get the score of the word, not including additions for the bonus timer or obscurity. It will also add the 7 and 8 letter bonuses
	var score = 0
	var upper_word = word.to_upper() # Ensure word is uppercase for lookup
	
	# 1. Iterate through each CHARACTER of the word string
	for letter in upper_word:
		# Look up each individual letter in the points dictionary
		if GlobalData.SCRABBLE_POINTS.has(letter):
			score += GlobalData.SCRABBLE_POINTS[letter]
			
	# 2. Check the LENGTH of the original word STRING

	if upper_word.length() == 7:
		score += 50
	if upper_word.length() == 8:
		score += 100
	
	return score

func _fade_in():
	%CanvasModulate.color = Color.TRANSPARENT
	var tween = create_tween()
	tween.tween_property(%CanvasModulate, "color", Color.WHITE, 1)
	await tween.finished
	
func _fade_out():
	%CanvasModulate.color = Color.WHITE
	var tween = create_tween()
	tween.tween_property(%CanvasModulate, "color", Color.TRANSPARENT, 1)
	await tween.finished


func _on_yes_button_pressed() -> void:
	Haptics.double_quick_medium()
	%YesButton.disabled = true
	%NoButton.disabled = true
	var new_like_value = current_game_like_value 
	new_like_value += 1
	db_ref.update("",{current_game: new_like_value})
	var tween = create_tween()
	tween.parallel().tween_property(%VBoxContainer, "modulate", Color.TRANSPARENT, 0.5)
	tween.parallel().tween_property(%Thanks, "modulate", Color.WHITE, 0.5)
	pass # Replace with function body.


func _on_no_button_pressed() -> void:
	Haptics.double_quick_medium()
	%NoButton.disabled = true
	%YesButton.disabled = true
	var new_like_value = current_game_like_value 
	new_like_value -= 1
	db_ref.update("",{current_game: new_like_value})
	var tween = create_tween()
	tween.parallel().tween_property(%VBoxContainer, "modulate", Color.TRANSPARENT, 0.5)
	tween.parallel().tween_property(%Thanks, "modulate", Color.WHITE, 0.5)
	pass # Replace with function body.
