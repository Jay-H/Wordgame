extends Control
signal back_to_menu_pressed
var my_dictionary
var opponent_dictionary

func _ready():
	if opponent_dictionary == null:
		_status_label_dots()

func _fade_in():
	$CanvasLayer/CanvasModulate.color = Color.TRANSPARENT
	var tween = create_tween()
	tween.tween_property($CanvasLayer/CanvasModulate, "color", Color.WHITE, 1)
	await tween.finished
	
func _fade_out():
	$CanvasLayer/CanvasModulate.color = Color.WHITE
	var tween = create_tween()
	tween.tween_property($CanvasLayer/CanvasModulate, "color", Color.TRANSPARENT, 1)
	await tween.finished
	
func _setup(my_info, opponent_info):
	my_dictionary = my_info
	opponent_dictionary = opponent_info
	%ProfilePicture.setup(GlobalData.profile_pics[my_info["profilepic"]])
	%playername.text = my_dictionary["username"]
	%playerlevel.text = "Level " + str(int(my_dictionary["level"])) + ": " + str(Globals.level_name_array[int(my_dictionary["level"])])
	%playerrank.text = "Rank: " + str(Globals.rank_name_array[my_dictionary["rank"]])
	if opponent_info != null:
		%OpponentProfilePicture.setup(GlobalData.profile_pics[opponent_dictionary["profilepic"]])
		%opponentname.text = opponent_dictionary["username"]
		%opponentlevel.text = "Level " + str(int(opponent_dictionary["level"])) + ": " + str(Globals.level_name_array[int(opponent_dictionary["level"])])
		%opponentrank.text = "Rank: " + str(Globals.rank_name_array[opponent_dictionary["rank"]])
		%Status.text = "Match Found!"
		%BackToMenu.visible = false
	pass


func _on_back_to_menu_pressed() -> void:
	
	back_to_menu_pressed.emit()
	pass # Replace with function body.

func _status_label_dots():
	if opponent_dictionary != null:
		%Status.text = "Match Found!"
	%Status.text = "Waiting for Opponent."
	await get_tree().create_timer(0.3).timeout
	if opponent_dictionary != null:
		%Status.text = "Match Found!"	
	%Status.text = "Waiting for Opponent.."
	await get_tree().create_timer(0.3).timeout
	if opponent_dictionary != null:
		%Status.text = "Match Found!"
	%Status.text = "Waiting for Opponent..."
	await get_tree().create_timer(0.3).timeout	

	if opponent_dictionary == null:
		_status_label_dots()
	else:
		%Status.text = "Match Found!"
