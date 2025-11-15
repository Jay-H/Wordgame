extends Control
@onready var main_menu = get_parent()
var previous_experience
var previous_level
var previous_rank
var previous_rank_points
var new_experience
var new_level
var new_rank
var new_rank_points
var level_up
var rank_up
var rank_point_on_texture = "res://data/images/Icons/RankPointOn.png"
var rank_point_off_texture = "res://data/images/Icons/RankPointOff.png"
var opponent_disconnected

@onready var timer = %Timer

func _fade_in():
	await get_tree().process_frame
	#if main_menu.opponent_disconnected:
		#%TopBigLabel.text = "Technical Win!"
	%LevelStatusLabel.text = "Good game!"
	%RankStatusLabel.text = "Thanks for Playing!"
	%CanvasModulate.color = Color.TRANSPARENT
	var tween = create_tween()
	tween.tween_property(%CanvasModulate, "color", Color.WHITE, 1)
	await tween.finished
	%experiencebar.animate(previous_experience, new_experience)
	%OldLevelLabel.text = "Level " + str(previous_level) + ": " + Globals.level_name_array[previous_level]
	%OldRankLabel.text = "Rank " + str(previous_rank) + ": " + Globals.rank_name_array[previous_rank]
	if level_up == true:
		
		%LevelStatusLabel.text = "L"
		await get_tree().create_timer(0.05).timeout
		%LevelStatusLabel.text = "Le" 
		await get_tree().create_timer(0.05).timeout
		%LevelStatusLabel.text = "Lev"
		await get_tree().create_timer(0.05).timeout
		%LevelStatusLabel.text = "Leve"  	
		await get_tree().create_timer(0.05).timeout
		%LevelStatusLabel.text = "Level" 
		await get_tree().create_timer(0.05).timeout
		%LevelStatusLabel.text = "Level " 
		await get_tree().create_timer(0.05).timeout
		%LevelStatusLabel.text = "Level U" 
		await get_tree().create_timer(0.05).timeout
		%LevelStatusLabel.text = "Level Up" 
		await get_tree().create_timer(0.05).timeout
		%LevelStatusLabel.text = "Level Up!"
		 
		await get_tree().create_timer(1).timeout
		var tween2 = create_tween()
		tween2.tween_property(%OldLevelLabel, "self_modulate", Color.TRANSPARENT, 0.5)
		await tween2.finished
		
		%NewLevelLabel.text = "Level " + str(new_level) + ": " + Globals.level_name_array[new_level]
		var tween3 = create_tween()
		tween3.tween_property(%NewLevelLabel, "self_modulate", Color.WHITE, 1)
		await tween3.finished
		var tween4 = create_tween()
		tween4.tween_method(_set_level_shader_value, 0.0, 1.0, 2)
		tween4.chain().tween_method(_set_level_shader_value, 1.0, 0.0, 1)	
	if rank_up == true:
		%RankStatusLabel.text = "R"
		await get_tree().create_timer(0.05).timeout
		%RankStatusLabel.text = "Ra" 
		await get_tree().create_timer(0.05).timeout
		%RankStatusLabel.text = "Ran"
		await get_tree().create_timer(0.05).timeout
		%RankStatusLabel.text = "Rank"  	
		await get_tree().create_timer(0.05).timeout
		%RankStatusLabel.text = "Rank " 
		await get_tree().create_timer(0.05).timeout
		%RankStatusLabel.text = "Rank U" 
		await get_tree().create_timer(0.05).timeout
		%RankStatusLabel.text = "Rank Up" 
		await get_tree().create_timer(0.05).timeout
		%RankStatusLabel.text = "Rank Up!" 
		await get_tree().create_timer(0.05).timeout	
		
		
		await get_tree().create_timer(1).timeout
		var tween2 = create_tween()
		tween2.tween_property(%OldRankLabel, "self_modulate", Color.TRANSPARENT, 0.5)
		await tween2.finished
		
		%NewRankLabel.text = "Rank " + str(new_rank) + ": " + Globals.rank_name_array[new_rank]
		var tween3 = create_tween()
		tween3.tween_property(%NewRankLabel, "self_modulate", Color.WHITE, 1)
		#await tween3.finished
		
		var tween4 = create_tween()
		tween4.tween_method(_set_rank_shader_value, 0.0, 1.0, 2)
		tween4.chain().tween_method(_set_rank_shader_value, 1.0, 0.0, 1)	
	var texture_boxes = %HBoxContainer.get_children()
	if new_rank_points > previous_rank_points:
		var differential = new_rank_points - previous_rank_points
		var current_marginal_point = previous_rank_points
		for i in range(differential):
			texture_boxes[current_marginal_point].texture = load(rank_point_on_texture)
			texture_boxes[current_marginal_point].pivot_offset = texture_boxes[current_marginal_point].size/2
			var tween2 = create_tween()
			tween2.tween_property(texture_boxes[current_marginal_point], "scale", Vector2(2,2), 0.25)
			tween2.chain().tween_property(texture_boxes[current_marginal_point], "scale", Vector2(1,1), 0.25)
			await get_tree().create_timer(0.5).timeout
			current_marginal_point += 1
	if new_rank_points < previous_rank_points:
		if rank_up == true:
			var differential = (10 + new_rank_points) - previous_rank_points
			var current_marginal_point = previous_rank_points
			for i in range(differential):
				texture_boxes[current_marginal_point].texture = load(rank_point_on_texture)
				texture_boxes[current_marginal_point].pivot_offset = texture_boxes[current_marginal_point].size/2
				var tween2 = create_tween()
				tween2.tween_property(texture_boxes[current_marginal_point], "scale", Vector2(2,2), 0.25)
				tween2.chain().tween_property(texture_boxes[current_marginal_point], "scale", Vector2(1,1), 0.25)
				await get_tree().create_timer(0.5).timeout
				current_marginal_point += 1
				if current_marginal_point == 10:
					for x in texture_boxes:
						x.texture = load(rank_point_off_texture)
					%RankParticles.emitting = true
					current_marginal_point = 0
		if rank_up == false:
			print("yo")
			var differential = previous_rank_points - new_rank_points
			var current_marginal_point = previous_rank_points - 1
			for i in range(differential):
				print(i)
				texture_boxes[current_marginal_point].texture = load(rank_point_off_texture)
				await get_tree().create_timer(0.5).timeout
				current_marginal_point -= 1
	%Timer.start(3)
	

func _fade_out():
	%CanvasModulate.color = Color.WHITE
	
	var tween = create_tween()
	tween.tween_property(%CanvasModulate, "color", Color.TRANSPARENT, 1)
	tween.parallel().tween_property(%BigWhiteRect, "modulate", Color.WHITE, 1)
	await tween.finished
	
func _setup(new, old): # new is the updated dictionary from the match just played, while old is before those results.
	previous_experience = int(old["experience"])
	new_experience = int(new["experience"])
	previous_level = int(old["level"])
	new_level = int(new["level"])
	previous_rank = int(old["rank"])
	new_rank = int(new["rank"])
	previous_rank_points = int(old["rank_points"])
	new_rank_points = int(new["rank_points"])
	if new_rank > previous_rank:
		rank_up = true
	if new_level > previous_level:
		level_up = true
	var points = %HBoxContainer.get_children()
	for i in range(previous_rank_points):
		points[i].texture = load(rank_point_on_texture)
	%ProfilePicture.setup(GlobalData.profile_pics[new["profilepic"]])
	%LevelStatusLabel.text = ""
	%NewLevelLabel.self_modulate = Color.TRANSPARENT
	%RankStatusLabel.text = ""
	%NewRankLabel.self_modulate = Color.TRANSPARENT
	%Username.text = new["username"]
	%experiencebar.setup(previous_experience)
	
func _on_button_pressed() -> void:
	previous_experience = 20
	new_experience = 10
	previous_level = 3
	new_level = 4
	previous_rank = 2
	new_rank = 3
	previous_rank_points = 9
	new_rank_points = 7
	rank_up = true
	level_up = true
	%experiencebar.setup(previous_experience)
	%ProfilePicture.setup(GlobalData.profile_pics[1])
	var points = %HBoxContainer.get_children()
	for i in range(previous_rank_points):
		points[i].texture = load(rank_point_on_texture)
	%LevelStatusLabel.text = ""
	%RankStatusLabel.text = ""
	%NewLevelLabel.self_modulate = Color.TRANSPARENT	
	%NewRankLabel.self_modulate = Color.TRANSPARENT
	
	%Username.text = "Arcenciel"
	_fade_in()
	pass # Replace with function body.

func _set_level_shader_value(value):
	%NewLevelLabel.material.set_shader_parameter("brightness", value)

func _set_rank_shader_value(value):
	%NewRankLabel.material.set_shader_parameter("brightness", value)
