extends CanvasLayer

var debug_dictionary = {"Experience": 1.0, "Level": 1.0, "Password": "a", "Rank": 1.0, "WinsRemaining": int(3), "ProfilePic": "res://data/images/profilepic.jpg", "Username": "Auron"}
var debug_xp = 0
var debug_xp_2 = 50
var level_up = false
var information

func _ready():
	if level_up == true:
		level_up_label_changer(information)
	pass

func setup(experience_before, experience_after, player_info):
	%experiencebar.setup(experience_before)
	information = player_info
	var level = player_info["Level"]
	var rank = player_info["Rank"]
	var wins_remaining = player_info["WinsRemaining"]
	%playerpic.texture = load(player_info["ProfilePic"])
	%experiencebar.animate(experience_before, experience_after)
	if experience_after < experience_before:
		level_up = true
		#var label_node = Label.new()
		#label_node.add_theme_font_size_override("font_size", 100)
		#label_node.text = "LEVEL " + str(int(player_info["Level"])) + ": " + str(Globals.level_name_array[player_info["Level"]])
		#label_node.position = get_viewport().get_visible_rect().size/2
		#add_child(label_node)
	%RankProgress.text = "Wins Until Next Rank\n" + str(int(wins_remaining))
	%Rank.text = "Rank: " + str(Globals.rank_name_array[player_info["Rank"]])
	pass


func level_up_label_changer(player_info):
	%LevelUpLabel.text = "Level Up!"
	await get_tree().create_timer(1.5).timeout
	%LevelUpLabel.text = "LEVEL " + str(int(player_info["Level"])) + ": " + str(Globals.level_name_array[player_info["Level"]])

func _on_button_pressed() -> void:
	
	setup(debug_xp, debug_xp_2, debug_dictionary)
	debug_xp += 70
	debug_xp_2 += 70
	pass # Replace with function body.

func fade_out():
	var tween = create_tween()
	for i in get_children():
		tween.parallel().tween_property(i, "modulate", Color.TRANSPARENT, 1)
	await get_tree().create_timer(1.5).timeout
	queue_free()
	
func _on_main_menu_button_pressed() -> void:
	fade_out()
	pass # Replace with function body.
