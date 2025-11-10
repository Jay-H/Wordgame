extends Control

var firebase_local_id
var player_number
@onready var main_menu = get_parent()


func _setup(dict, big_dictionary, firebase_id):
	firebase_local_id = firebase_id
	var player_one_username = dict["player_one_dictionary"]["username"]
	var player_two_username = dict["player_two_dictionary"]["username"]
	%playerpic.setup(GlobalData.profile_pics[dict["player_one_dictionary"]["profilepic"]])
	%opponentpic.setup(GlobalData.profile_pics[dict["player_two_dictionary"]["profilepic"]])
	if (big_dictionary.has("game_type") && big_dictionary["game_type"] == "wordsearch"):
		pass
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
