extends CanvasLayer


func _ready():
	pass

func get_leaderboard_information():
	await get_tree().create_timer(1).timeout
	var top_players_dictionary = Globals.top_players_dictionary
	var top_players = Globals.top_players
	print (top_players_dictionary)
	for i in %VBoxContainer.get_children():
		var index = i.get_index()
		if top_players.size() >= index + 1:
			i.text = top_players[index] + "   " + "Level " + str(int(top_players_dictionary[top_players[index]]))
			
func _on_button_pressed() -> void:
	self.visible = false
	pass # Replace with function body.
