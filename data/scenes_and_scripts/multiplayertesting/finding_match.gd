extends Control

var username
var opponent_name = "b"
var user_info
var opponent_info
var opponent_picture


func _ready():
	%playername.text = user_info["Username"]
	if opponent_info != null:
		%opponentname.text = opponent_info["Username"]
	%playerpic.texture = load(user_info["ProfilePic"])
	%playerlevel.text = "Level: " + str(int(user_info["Level"]))
	%playerrank.text = "Rank: " + Globals.rank_name_array[int(user_info["Rank"])]
	
	if opponent_name != "opponent":
		%opponentpic.texture = load(opponent_picture)
	else:
		%opponentpic.texture = load("res://data/images/profilepic.jpg")
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(%CanvasModulate, "modulate", Color.WHITE, 1)
	
	if opponent_picture == null:
		finding_match_period_cycler()


	
func finding_match_period_cycler():	
	%FindingMatch.text = "Finding Match"
	await get_tree().create_timer(0.5).timeout
	%FindingMatch.text = "Finding Match."
	await get_tree().create_timer(0.5).timeout
	%FindingMatch.text = "Finding Match.."
	await get_tree().create_timer(0.5).timeout
	%FindingMatch.text = "Finding Match..."
	await get_tree().create_timer(0.5).timeout
	finding_match_period_cycler()

func setup(a, b, c, d):
	username = a
	opponent_name = b
	user_info = c
	
	if d != null:
		opponent_picture = d["ProfilePic"]
		%opponentlevel.text = "Level: " + str(int(d["Level"]))
		%opponentrank.text = "Rank: " + Globals.rank_name_array[int(d["Rank"])]
		%FindingMatch.text = "Match Found!"
	opponent_info = d
	%CanvasModulate.modulate = Color.TRANSPARENT

func fade_out():
	var tween = create_tween()
	tween.tween_property(%CanvasModulate, "modulate", Color.TRANSPARENT, 1)


func _on_button_pressed() -> void:
	var main_menu_node = get_parent()
	main_menu_node.cancel_find_match(null)
	fade_out()
	await get_tree().create_timer(1).timeout
	queue_free()
