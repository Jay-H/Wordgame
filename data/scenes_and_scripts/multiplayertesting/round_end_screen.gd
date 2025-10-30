extends CanvasLayer

var username
var opponent_name = "b"
var player_score
var opponent_score
var p1wins
var p2wins
var thisplayer
var thisround
var current_game_dictionary
var p1bestword
var p2bestword

func _ready():
	%PlayerName.text = username
	%OpponentName.text = opponent_name
	%PlayerScore.text = str(player_score)
	%OpponentScore.text = str(opponent_score)
	%PlayerOneBestWord.text = str(p1bestword)
	%PlayerTwoBestWord.text = str(p2bestword)
	
	#var profile_pic_path = "res://data/images/profilepics/" + username + ".jpg"
	#var opponent_pic_path = "res://data/images/profilepics/" + opponent_name + ".jpg"
	#%playerpic.texture = load(profile_pic_path)
	#if opponent_name != "opponent":
		#%opponentpic.texture = load(opponent_pic_path)
	#else:
		#%opponentpic.texture = load("res://data/images/profilepic.jpg")
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(%CanvasModulate, "modulate", Color.WHITE, 1)
	
	for i in range(1,thisround + 1):
		var win_animation_name = "WinRound" + str(i)
		var lose_animation_name = "LoseRound" + str(i)
		print(lose_animation_name)
		var win_animation_node = get_node("CanvasModulate/" + str(win_animation_name))
		var lose_animation_node = get_node("CanvasModulate/" + str(lose_animation_name))
		if current_game_dictionary.has(str(username) + str(opponent_name) + "Round"+ str(i) + "Winner"):
			if thisplayer == current_game_dictionary[str(username) + str(opponent_name) + "Round"+ str(i) + "Winner"]:
				win_animation_node.start_animation()
			else:
				lose_animation_node.start_animation()
		if current_game_dictionary.has(str(opponent_name) + str(username) + "Round"+ str(i) + "Winner"):
			if thisplayer == current_game_dictionary[str(opponent_name) + str(username) + "Round"+ str(i) + "Winner"]:
				win_animation_node.start_animation()
			else:
				lose_animation_node.start_animation()
	
	
func setup(a, b, c, d, player_one_wins, player_two_wins, player_number, current_games, user_one_dictionary, user_two_dictionary, player_dictionary, opponent_dictionary):
	username = player_dictionary["Username"]
	opponent_name = opponent_dictionary["Username"]
	player_score = c
	opponent_score = d
	thisplayer = player_number
	thisround = current_games[str(a) + str(b) + "Round Number"]
	if thisround == 3:
		%RoundOver.text = "Game Over!"
	current_game_dictionary = current_games
	print(current_game_dictionary)
	p1bestword = current_games[str(a) + str(b) + "Player One Best Word"]
	p2bestword = current_games[str(a) + str(b) + "Player Two Best Word"]
	%playerpic.texture = load(user_one_dictionary["ProfilePic"])
	%opponentpic.texture = load(user_two_dictionary["ProfilePic"])
	
	%CanvasModulate.modulate = Color.TRANSPARENT

func fade_out():
	var tween = create_tween()
	tween.tween_property(%CanvasModulate, "modulate", Color.TRANSPARENT, 1)


func _on_button_pressed() -> void:
	%WinRound1.start_animation()
	%LoseRound2.start_animation()
	%WinRound3.start_animation()
	pass # Replace with function body.


	
