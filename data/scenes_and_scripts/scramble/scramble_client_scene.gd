extends Control

var SERVER_PORT = 7777
const SERVER_NODE_PATH = "res://data/scenes_and_scripts/scramble/scramble_server_scene.tscn"
@onready var pregame_timer_node = get_node("/root/MainMenu/PregameTimer")
var big_dictionary = {}
var is_player_one = false
var is_player_two = false
var user_id
var letters_received = false
var current_chosen_letters_array = []
var current_chosen_letters_string = ""
var miniscore
var bonus_variant = false
var obscurity_variant = false
var wonder_variant = false
var bonus_pressed = false
var miniscore_pulsing_tween : Tween
var miniscore_ispulsing = false
var obscurity_displayed = false
var number_of_words_found = 0
var current_penalty = 0
var arguments = OS.get_cmdline_args()
@onready var shakeables = [ %Letter1, %Letter2, %Letter3, %Letter4, %Letter5, %Letter6, %Letter7, %MiniScore, %Submit, %Shuffle, %Clear, %GameTimerLabel, %GameScore, %BonusLetter, %SubmitShadow, %ClearShadow, %ShuffleShadow]
var shaker_offset
var username
var shadow_realm_node
var GMajor = []
var GMajorChords = []
var current_background = ""
var blocker_faded = false
var shadows_enabled = false

func _ready():
	#username = arguments[1]
	
	rpc_id(1, "send_player_information") # initial call to the server to give us some info
	
	for i in range (1,8): # this connects the signals from the 7 letters in the middle to this script, allowing us to get the text from those letter label nodes
		var letterstring = "%Letter" + str(i)
		var letternode = get_node(letterstring)
		letternode.connect("pressed", letter_collector)
		letternode.connect("text_changed", fade_blocker)
	if bonus_variant == true:
		%BonusReminder.visible = true
		%BonusScore.visible = true
		%BonusLetter.connect("pressed", letter_collector)
	
		

func _process(delta):

	%CurrentWord.text = current_chosen_letters_string
	if big_dictionary.has("Server Time Left"):
		%GameTimerLabel.text = str(big_dictionary["Server Time Left"])
	if bonus_variant == true:
		if big_dictionary.has("Bonus Time Value") and big_dictionary.has("Bonus Letter Value"):
			%BonusScore.text = str(big_dictionary["Bonus Time Value"]) + " + " + str(big_dictionary["Bonus Letter Value"])
	if big_dictionary.has("Player One Number Of Found Words") and big_dictionary.has("Player Two Number Of Found Words"):
		if is_player_one == true:
			if big_dictionary["Player One Number Of Found Words"] != number_of_words_found:
				number_of_words_found = big_dictionary["Player One Number Of Found Words"] # this is a really stupid way to get the moment when a new word is found, so that the obscurity popup only comes up once. 
				obscurity_displayed = false
			else: 
				number_of_words_found = big_dictionary["Player One Number Of Found Words"]
		if is_player_two == true:
			if big_dictionary["Player Two Number Of Found Words"] != number_of_words_found:
				number_of_words_found = big_dictionary["Player Two Number Of Found Words"]
				obscurity_displayed = false
			else: 
				number_of_words_found = big_dictionary["Player Two Number Of Found Words"]
	

func setup(background):
	
	
	if background == "Mars":
		%MarsBase.visible = true
		
	if background == "Jupiter":
		%Jupiter4.visible = true	
		%BackgroundFader.color = Color.TRANSPARENT
	pass

func letter_collector(letter, letternode, bonus): #updates the current chosen letter array and disables already pressed letters
	%PianoController.play_random_note()
	
	current_chosen_letters_array.append(letter)
	current_chosen_letters_string += str(letter) 
	letternode.mouse_filter = MOUSE_FILTER_IGNORE
	small_green_letters(letternode)
	letternode.add_theme_color_override("font_color", Color.LIGHT_BLUE)
	
	if bonus:
		bonus_pressed = true
		print("bonus pressed")
	mini_score_display()
	

func mini_score_display():
	var score = 0
	if miniscore_ispulsing:
		miniscore_pulsing_tween.kill()
		miniscore_ispulsing = false
		%MiniScore.add_theme_color_override("font_color", Color.BLACK)
	for i in current_chosen_letters_array:
		score += GlobalData.SCRABBLE_POINTS[i]
	if current_chosen_letters_array.size() == 7:
		score += 50
		%MiniScore.add_theme_color_override("font_color", Color.NAVY_BLUE)
		miniscore_pulsing_tween = create_tween()
		miniscore_pulsing_tween.set_loops()
		miniscore_pulsing_tween.tween_property(%MiniScore, "scale", Vector2(1.2, 1.2), 0.5)
		miniscore_pulsing_tween.chain().tween_property(%MiniScore, "scale", Vector2(0.8, 0.8), 0.5)
		miniscore_ispulsing = true
	if current_chosen_letters_array.size() == 8:
		score += 100
		miniscore_pulsing_tween = create_tween()
		%MiniScore.add_theme_color_override("font_color", Color.GOLD)
		miniscore_pulsing_tween.set_loops()
		miniscore_pulsing_tween.tween_property(%MiniScore, "scale", Vector2(1.5, 1.5), 0.5)
		miniscore_pulsing_tween.chain().tween_property(%MiniScore, "scale", Vector2(0.8, 0.8), 0.5)
		miniscore_ispulsing = true
	miniscore = score
	%MiniScore.text = str(miniscore)

func submitter():
	
	send_word_to_server(current_chosen_letters_string)
	current_chosen_letters_string = ""
	current_chosen_letters_array = []
	bonus_pressed = false
	for i in range (1,8): 
		var letterstring = "%Letter" + str(i)
		var letternode = get_node(letterstring)
		letternode.add_theme_color_override("font_color", Color.BLACK)
		letternode.mouse_filter = MOUSE_FILTER_STOP
	if bonus_variant == true:
		%BonusLetter.mouse_filter = MOUSE_FILTER_STOP
	
	mini_score_display()
	

@rpc("authority", "call_local")
func word_listener(word, bonus):
	pass
	
func send_word_to_server(word):
	var bonus
	if bonus_pressed:
		bonus = true
	if not bonus_pressed:
		bonus = false
	rpc("word_listener", word, bonus)
	
	rpc_id(1, "send_player_information")
	

func letter_populator():
	var lettercontainer = %LetterContainer
	var letters = []
	if big_dictionary.has("Letters"):
		letters = big_dictionary["Letters"]
	if letters != []:
		for i in range(1,8):
			var labelnodestring = "%Letter" + str(i)
			var labelnode = get_node(labelnodestring)
			labelnode.text = letters[i-1]
	
		

@rpc("authority")
func found_words_populator():
	var p1foundwords
	var p2foundwords
	var all_found_words
	if big_dictionary.has("Player One Found Words"):
		p1foundwords = big_dictionary["Player One Found Words"]
	if big_dictionary.has("Player Two Found Words"):
		p2foundwords = big_dictionary["Player Two Found Words"]
	if big_dictionary.has("All Found Words"):
		all_found_words = big_dictionary["All Found Words"]
	
	for i in range(1,45):
		var labelnodestring = "%FoundWord" + str(i)
		var labelnode = get_node(labelnodestring)
		if all_found_words.size() > i-1:
			var word = all_found_words[i-1]
			labelnode.text = word
	for i in range(1,45): # setting opponent words to red
		var labelnodestring = "%FoundWord" + str(i)
		var labelnode = get_node(labelnodestring)
		if is_player_one:
			if p2foundwords.has(labelnode.text):
				labelnode.add_theme_color_override("font_color", Color.RED)
			if p1foundwords.has(labelnode.text):
				labelnode.add_theme_color_override("font_color", Color.BLACK)
		if is_player_two:
			if p1foundwords.has(labelnode.text):
				labelnode.add_theme_color_override("font_color", Color.RED)
			if p2foundwords.has(labelnode.text):
				labelnode.add_theme_color_override("font_color", Color.BLACK)
			
		 
	
	
				
			
		
	pass
	
@rpc("authority", "call_local")
func send_player_information():
	pass
	
func shuffler():
	var seeds = ["asdfa", "132414", "sdfgshfg", "srgshrse", "ergjbnege", "rsegsrg", "ergiuhsrg", "gsrehjg", "giorsehg", "glisujerhg", "grsngss", "gserjklh", "gsioulhreg"]
	var my_seed = seeds[randi_range(0, (seeds.size()-1))].hash()
	
	var hbox_node_container = %LetterContainer
	var shadow_children
	var children = hbox_node_container.get_children()
	if shadow_realm_node != null:
		shadow_children = shadow_realm_node.get_children()
	seed(my_seed)
	children.shuffle()
	
	if shadow_realm_node != null:
		seed(my_seed)
		shadow_children.shuffle()
	
	for i in range(children.size()):
		var child_node = children[i]
		hbox_node_container.move_child(child_node, i)
		if shadow_realm_node != null:
			var shadow_child_node = shadow_children[i]
			shadow_realm_node.move_child(shadow_child_node, i)
			
	
	#if shadow_realm_node != null:
		#print(shadow_realm_node)
		#print("shadow shuffle")
		#for i in %LetterContainer.get_children(): # this makes it so if you shuffle while the shadows are active, the shadows shuffle too
			#var text = i.text
			#var node_name = i.name
			#for x in shadow_realm_node.get_children():
				#if x.name == i.name:
					#print(x.name)
					#print(i.name)
					#x.text = i.text
	#pass
	#

@rpc("authority", "call_local")
func receive_player_information(dictionary):
	
	big_dictionary = dictionary
	found_words_populator()
	user_id = multiplayer.get_unique_id()
	#%FoundWord43.text = username
	if user_id == big_dictionary["Player One ID"]:
		is_player_one = true
		
		#%FoundWord44.text = "Player 1"
		%GameScore.text = "Score = " + str(big_dictionary["Player One Score"])
	if user_id == big_dictionary["Player Two ID"]:
		is_player_two = true
		
		#%FoundWord44.text = "Player 2"
		%GameScore.text = "Score = " + str(big_dictionary["Player Two Score"])
	if letters_received == false:
		letters_received = true
		letter_populator()
	bonus_populator()
	if obscurity_displayed == false: # this is the counterpart to the part in process function, that allows us to know the moment and new word is found
		show_obscurity_popup()
		obscurity_displayed = true

	
	pass

@rpc("any_peer", "call_local")
func bonus_populator():
	%BonusLetter.text = big_dictionary["Bonus Letter"]
	
	
func _on_shuffle_pressed():
	%PianoController.play_random_chord()
	shuffler()
	remote_tester()
	
	
@rpc("any_peer", "call_local")
func remote_tester():
	if big_dictionary.has(["Parent"]):
		print(big_dictionary["Parent"])
	pass
	
func _on_submit_pressed():
	%PianoController.play_random_chord()
	submitter()
	


func _on_clear_pressed() -> void:
	%PianoController.play_random_chord()
	current_chosen_letters_string = ""
	current_chosen_letters_array = []
	bonus_pressed = false
	%BonusLetter.mouse_filter = MOUSE_FILTER_STOP
	for i in range (1,8): 
		var letterstring = "%Letter" + str(i)
		var letternode = get_node(letterstring)
		letternode.add_theme_color_override("font_color", Color.BLACK)
		letternode.mouse_filter = MOUSE_FILTER_STOP
	
	mini_score_display()
	


func _on_bonus_letter_pressed() -> void:
	pass # Replace with function body.


@rpc("any_peer", "call_local")	
func show_obscurity_popup():
	# 1. Create and style the Label
	if obscurity_variant:
		var obscurity
		if big_dictionary.has("Player One Last Obscurity Value") and big_dictionary.has("Player Two Last Obscurity Value"):
			if is_player_one == true:
				obscurity = big_dictionary["Player One Last Obscurity Value"]
			if is_player_two == true:
				obscurity = big_dictionary["Player Two Last Obscurity Value"]
		var label = Label.new()
		if obscurity != null:
			label.text = "Obscurity = %s/10" % obscurity
			label.add_theme_font_size_override("font_size", 80)
			label.add_theme_color_override("font_color", Color.BLACK)
			# Optional: Add an outline for better visibility
			#var outline = LabelSettings.new()
			#outline.outline_size = 5
			#outline.outline_color = Color.BLACK
			#label.label_settings = outline
			
			# 2. Add to scene and wait one frame for its size to be calculated
			add_child(label)
			await get_tree().process_frame
			
			
			# 3. Calculate start and end positions
			var screen_size = get_viewport_rect().size
			var label_size = label.size
			
			var start_pos = screen_size/2 - label.size/2 
			var end_pos = Vector2((screen_size.x - label_size.x) / 2, screen_size.y * 0.2)
			
			# 4. Set initial state (invisible and at the start position)
			label.global_position = start_pos
			label.modulate.a = 0.0
			
			# 5. Create and run animations
			# This tween handles the movement over 1 second
			var move_tween = create_tween()
			move_tween.tween_property(label, "global_position", end_pos, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			
			# This tween handles the fade-in and fade-out sequence
			var fade_tween = create_tween()
			fade_tween.tween_property(label, "modulate:a", 1.0, 0.3) # Fade in over 0.3s
			fade_tween.tween_property(label, "modulate:a", 0.0, 2) # Fade out over the remaining 0.7s
			
			# 6. Clean up the label after the animation is done
			await fade_tween.finished
			label.queue_free()
	else:
		return
func wrong_word_display():
	
	var sun_tween = create_tween()
	sun_tween.set_ease(Tween.EASE_IN_OUT)
	sun_tween.set_trans(Tween.TRANS_CIRC)
	sun_tween.parallel().tween_property(%Sun, "material:shader_parameter/edge_softness", 0.25, 0.5)
	sun_tween.parallel().tween_property(%Sun, "material:shader_parameter/sun_color", Color.PALE_VIOLET_RED, 0.5)	
	sun_tween.chain().tween_property(%Sun, "material:shader_parameter/edge_softness", 0.419, 0.5)
	sun_tween.parallel().tween_property(%Sun, "material:shader_parameter/sun_color", Color(1.0, 0.902, 0.502), 0.5)		
	
	var jupiter_tween = create_tween()
	jupiter_tween.tween_property(%Jupiter4, "material:shader_parameter/band_A_color_2", Color.PALE_VIOLET_RED, 0.5)
	jupiter_tween.parallel().tween_property(%Jupiter4, "material:shader_parameter/band_D_color_2", Color.PALE_VIOLET_RED, 0.5)
	jupiter_tween.chain().tween_property(%Jupiter4, "material:shader_parameter/band_A_color_2", Color(0.65, 0.53, 0.41), 0.5)
	jupiter_tween.parallel().tween_property(%Jupiter4, "material:shader_parameter/band_D_color_2", Color(0.8, 0.7, 0.6), 0.5)
	
	var label = Label.new()
	var label_container = CenterContainer.new()
	var score_display = %GameScore
	
	
	#label_container.position = score_display.position
	
	label.self_modulate.a = 0.0
	add_child(label_container)
	label_container.add_child(label)
	label.name = "wrong_word_display"
	label_container.name = "wrong_word_score_container"
	label.add_theme_font_size_override("font_size", 200)
	label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	label.set_vertical_alignment(VERTICAL_ALIGNMENT_CENTER)
	label.add_theme_color_override("font_color", Color.RED)
	label.text = "- " + str(current_penalty)
	await get_tree().process_frame
	await get_tree().process_frame
	
	
	var label_container_original_size = label_container.size
	
	label_container.scale = Vector2(0,0)
	
	await get_tree().process_frame
	label_container.set_pivot_offset(label_container.size / 2.0)
	label_container.global_position = score_display.position
	label_container.position.x += (score_display.size.x/2)
	label_container.position.y -= 100
	#label_container.position.y += (score_display.size.y) + ((score_display.size.y)/2)
	await get_tree().process_frame
	await get_tree().process_frame
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT) 
	tween.set_trans(Tween.TRANS_SPRING)
	score_display.add_theme_color_override("font_color", Color.RED)
	tween.parallel().tween_property(score_display, "self_modulate", Color.BLACK, 0.5)
	tween.parallel().tween_property(label, "self_modulate:a", 1, 0.5)
	tween.parallel().tween_property(label_container, "scale", Vector2(1,1), 0.5)
	
	
	tween.chain().tween_property(label, "self_modulate:a", 0, 0.5)
	
	await tween.finished
	score_display.self_modulate = Color.WHITE
	score_display.add_theme_color_override("font_color", Color.BLACK)
	label_container.queue_free()
	

@rpc("any_peer", "call_local")
func wrong_word_alert(amount):
	current_penalty = amount
	wrong_word_display()
	pass

func fade_pregame():
	var pregame_node = %ColoredBlocker
	var tween = create_tween()
	tween.tween_property(pregame_node, "modulate", Color.TRANSPARENT, 0.5)
	

func pre_timer():
	
	pass

func fade_out():
	var tween = create_tween()
	tween.tween_property(%CanvasModulate, "color", Color.TRANSPARENT, 1)
	await tween.finished
	pass

@rpc("authority", "call_local")
func wonder_game_ender(winner_user_id):
	#big_word_event()
	var nodes_to_move = [%Submit, %Clear, %Shuffle, %BonusLetter, %BonusScore, %BonusReminder, %GameTimerLabel, %GameScore, %MiniScore, %HBoxContainer]
	var nodes_to_disable = [%LetterContainer, %Submit, %Clear, %Shuffle, %BonusLetter]
	for x in %LetterContainer.get_children():
		nodes_to_disable.append(x)
	for i in nodes_to_disable:
		i.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if winner_user_id == user_id:
		var sun_tween = create_tween()
		%Sun.pivot_offset = %Sun.size/2
		sun_tween.set_ease(Tween.EASE_IN)
		sun_tween.parallel().tween_property(%Sun, "material:shader_parameter/sun_color", Color.DARK_GREEN, 2)
		sun_tween.parallel().tween_property(%Sun, "scale", Vector2(7,7), 5)
		sun_tween.parallel().tween_property(%LetterContainer, "modulate", Color.TRANSPARENT, 1)
		sun_tween.chain().tween_property(%Sun, "material:shader_parameter/sun_color", Color.WHITE, 2)		
		
		for i in nodes_to_move:
			var tween2 = create_tween()
			tween2.set_ease(Tween.EASE_IN_OUT)
			tween2.set_trans(Tween.TRANS_SINE)
			var target_position = Vector2(i.position.x, i.position.y - 3000)
			
			tween2.tween_property(i, "position", target_position, 3)
		var big_label = Label.new()
		big_label.add_theme_font_size_override("font_size", 300)
		big_label.add_theme_font_override("font", load("res://data/fonts/elmora-classica/Elmora Classica.otf"))
		big_label.set_anchors_preset(Control.PRESET_CENTER)
		big_label.text = "Wonderful!"
		big_label.add_theme_color_override("font_color", Color.DARK_GOLDENROD)
		big_label.modulate = Color.TRANSPARENT
		big_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		$CanvasLayer.add_child(big_label)
		big_label.pivot_offset = big_label.size/2
		big_label.position -= big_label.size/2
		big_label.set_anchors_preset(Control.PRESET_CENTER)
		var tween = create_tween()
		tween.tween_property(big_label, "modulate", Color.WHITE, 3)
		tween.parallel().tween_property(big_label, "scale", Vector2(1.2,1.2), 3)
	if winner_user_id != user_id:
		
		var sun_tween = create_tween()
		%Sun.pivot_offset = %Sun.size/2
		sun_tween.set_ease(Tween.EASE_IN)
		sun_tween.parallel().tween_property(%Sun, "material:shader_parameter/sun_color", Color.DARK_RED, 3)
		sun_tween.parallel().tween_property(%Sun, "scale", Vector2(7,7), 5)
		sun_tween.parallel().tween_property(%LetterContainer, "modulate", Color.TRANSPARENT, 3)
		
		for i in nodes_to_move:
			i.pivot_offset = i.size/2
			var tween = create_tween()
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.set_trans(Tween.TRANS_SINE)
			var x_position = i.position.x
			var y_position = i.position.y
			var randomizer_x = randi_range(-300, 300)
			var target_position = Vector2(x_position + randomizer_x , y_position + 3000)
			var random_rotation = randf_range(-50, 50)
			tween.tween_property(i, "position", target_position, 3 )
			tween.parallel().tween_property(i, "modulate", Color.TRANSPARENT, 3)
			tween.parallel().tween_property(i, "rotation", random_rotation, 4)
		for i in %LetterContainer.get_children():
			var tween = create_tween()	
			tween.tween_property(i, "scale", Vector2(0,0), 4)
		var big_label = Label.new()
		big_label.add_theme_font_size_override("font_size", 300)
		big_label.add_theme_font_override("font", load("res://data/fonts/elmora-classica/Elmora Classica.otf"))
		big_label.set_anchors_preset(Control.PRESET_CENTER)
		big_label.text = "Terrible!"
		big_label.add_theme_color_override("font_color", Color.DARK_GOLDENROD)
		big_label.modulate = Color.TRANSPARENT
		big_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		$CanvasLayer.add_child(big_label)
		big_label.pivot_offset = big_label.size/2
		big_label.position -= big_label.size/2
		big_label.set_anchors_preset(Control.PRESET_CENTER)
		var tween = create_tween()
		tween.tween_property(big_label, "modulate", Color.WHITE, 3)
		tween.parallel().tween_property(big_label, "scale", Vector2(1.2,1.2), 3)
		#for i in %CanvasLayer.get_children():
			#print(i)
			#
			#var tween = create_tween()
			#tween.tween_property(i, "modulate", Color.BLACK, 2)
			##tween.parallel().tween_property(i, "modulate", Color.BLACK, 3)
			##tween.chain().tween_property(i, "modulate", Color.DARK_RED, 3)
			
			
	
	print("WONDER GAME OVER")
	pass

func small_green_letters(letternode):
	var letter_score = GlobalData.SCRABBLE_POINTS[letternode.text]
	var label_node = Label.new()
	label_node.add_theme_font_size_override("font_size", 88)
	label_node.add_theme_color_override("font_color", Color.GREEN)
	letternode.add_child(label_node)
	label_node.text = str(letter_score)
	label_node.position += letternode.size/2
	
	var tween = create_tween()
	tween.parallel().tween_property(label_node, "position", Vector2((label_node.size.x/2) - 25,letternode.position.y - 150), 1)
	tween.parallel().tween_property(label_node, "modulate", Color.TRANSPARENT, 0.8)
	await get_tree().create_timer(1).timeout
	label_node.queue_free()


# Shakes a node smoothly using a Tween.
# number: The maximum distance the shake will move the node.
# i: The actual node to shake (e.g., a letter).
# duration: The total time for the shake (out and back).

func shaker(number, i, duration = 0.2, repeats = 10):
	# 1. Store the starting position to ensure we return to the exact same spot.
	
	var original_position = i.position

	# 2. Create a new tween. All shake animations will be chained to this one.
	var tween = create_tween()

	# 3. Loop for the number of repetitions desired.
	for n in repeats:
		# 3a. Calculate a NEW random offset vector for EACH shake.
		var random = randf()
		var shaker_offset_val = number * random
		var shaker_offset_vector = Vector2.ZERO
		
		var w = randi_range(0, 1)
		if w == 0:
			shaker_offset_vector = Vector2(-shaker_offset_val, shaker_offset_val)
		else: # w == 1
			shaker_offset_vector = Vector2(shaker_offset_val, -shaker_offset_val)
			
		var target_position = original_position + shaker_offset_vector

		# 3b. Animate the node's "position" TO the new target_position.
		# This animation will take up the first half of the duration for one shake.
		tween.tween_property(i, "position", target_position, duration / 2.0)\
			 .set_trans(Tween.TRANS_SINE)\
			 .set_ease(Tween.EASE_OUT)

		# 3c. Chain the return animation. This starts automatically after the first one finishes.
		# Animate the "position" back TO the original_position.
		tween.tween_property(i, "position", original_position, duration / 2.0)\
			 .set_trans(Tween.TRANS_SINE)\
			 .set_ease(Tween.EASE_IN)

	
		
	
	
@rpc("authority", "call_local")			
func big_word_event():
	if wonder_variant: # disallow in wonder variant, we have a different animation there
		return

	
	#var shadows = [%SubmitShadow, %ClearShadow, %ShuffleShadow]
	
	for i in shakeables:
		
		
		shaker(20, i)	
	

	
	#var shadow_realm = (load("res://data/scenes_and_scripts/scramble/letter_container.tscn")).instantiate()
	#shadow_realm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#for i in %LetterContainer.get_children():
		#var text = i.text
		#var node_name = i.name
		#for x in shadow_realm.get_children():
			#x.mouse_filter = Control.MOUSE_FILTER_IGNORE
			#if x.name == i.name:
				#x.text = i.text
	#add_child(shadow_realm)
	#shadows.append(shadow_realm)
	#shadow_realm_node = shadow_realm
	
	#for i in shadows:
		#i.visible = true
		#var shadow_position = i.position
		#shadow_position.y -= 250
		#var shadow_tween = create_tween()
		#shadow_tween.set_ease(Tween.EASE_IN_OUT)
		#shadow_tween.set_trans(Tween.TRANS_BACK)
		#shadow_tween.tween_property(i, "modulate", Color.TRANSPARENT, 0.75)
		#shadow_tween.chain().tween_property(i, "modulate", Color(1.0, 1.0, 1.0, 0.553), 1)
		#shadow_tween.chain().tween_property(i, "scale", Vector2(1, 6), 7)
		#
		#shadow_tween.parallel().tween_property(i, "position", shadow_position, 7)
		#shadow_tween.parallel().tween_property(i, "modulate", Color.TRANSPARENT, 7)
	
	var god_light_tween = create_tween()
	var god_light_music_tween = create_tween()
	god_light_tween.set_ease(Tween.EASE_IN_OUT)
	god_light_tween.tween_property(%GodLight, "energy", 1.7, 4.3)
	$GodLightMusic.play(1)
	god_light_music_tween.tween_property($GodLightMusic, "volume_db", 0, 1)
	var big_boss = Label.new()
	big_boss.add_theme_font_size_override("font_size", 200)
	big_boss.add_theme_color_override("font_color", Color.GOLDENROD)
	big_boss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big_boss.text = "SEVEN"
	add_child(big_boss)
	big_boss.position = get_viewport_rect().size/2 - big_boss.size/2
	big_boss.pivot_offset += big_boss.size/2
	var tween = create_tween()
	tween.tween_property(big_boss, "position", (get_viewport_rect().size/2 - Vector2(0, 800) - big_boss.size/2), 1)
	
	tween.parallel().tween_property(big_boss, "scale", Vector2(1.5,1.5), 1)
	tween.chain().tween_property(big_boss, "modulate", Color.TRANSPARENT, 1).set_delay(1)
	
	god_light_tween.chain().tween_property(%GodLight, "energy", 1.8, 3.1)
	god_light_tween.chain().tween_property(%GodLight, "energy", 0, 0.5)
	god_light_music_tween.chain().tween_property($GodLightMusic, "volume_db", 1, 6.3)
	god_light_music_tween.chain().tween_property($GodLightMusic, "volume_db", -80, 1)
	await tween.finished
	big_boss.queue_free()
	pass

@rpc("authority", "call_local")			
func valid_word_event():
	var sun_tween = create_tween()
	sun_tween.set_ease(Tween.EASE_IN_OUT)
	sun_tween.set_trans(Tween.TRANS_CIRC)
	sun_tween.parallel().tween_property(%Sun, "material:shader_parameter/edge_softness", 0.25, 0.5)
	sun_tween.parallel().tween_property(%Sun, "material:shader_parameter/sun_color", Color.PALE_GREEN, 0.5)	
	sun_tween.chain().tween_property(%Sun, "material:shader_parameter/edge_softness", 0.419, 0.5)
	sun_tween.parallel().tween_property(%Sun, "material:shader_parameter/sun_color", Color(1.0, 0.902, 0.502), 0.5)		
	
	var jupiter_tween = create_tween()
	jupiter_tween.tween_property(%Jupiter4, "material:shader_parameter/band_A_color_2", Color(0.491, 0.585, 0.494), 0.5)
	jupiter_tween.parallel().tween_property(%Jupiter4, "material:shader_parameter/band_D_color_2", Color(0.8, 1.0, 0.6), 0.5)
	jupiter_tween.chain().tween_property(%Jupiter4, "material:shader_parameter/band_A_color_2", Color(0.65, 0.53, 0.41), 0.5)
	jupiter_tween.parallel().tween_property(%Jupiter4, "material:shader_parameter/band_D_color_2", Color(0.8, 0.7, 0.6), 0.5)
	pass
	
func _on_button_pressed() -> void:
	#wrong_word_display()
	#big_word_event()
	big_dictionary["Player One Found Words"] = ["allan", "simon", "gary", "john", "chris", "mike", "allan", "simon", "gary"]
	big_dictionary["Player Two Found Words"] = ["john", "chris", "mike", "john", "chris", "mike", "allan", "simon", "gary"]
	big_dictionary["All Found Words"] = ["john", "chris", "mike", "allan", "simon", "gary", "john", "chris", "mike", "allan", "simon", "gary","john", "chris", "mike", "allan", "simon", "gary"]
	found_words_populator()
	wonder_game_ender(user_id)
	pass # Replace with function body.

func _initialize(dict):
	var variant = dict["selected_games"][dict["current_round"]]
	if variant.contains("Bonus"):
		bonus_variant = true
	if variant.contains("Obscurity"):
		obscurity_variant = true	
	if variant.contains("Wonder"):
		wonder_variant = true		
	pass

func fade_blocker():
	
	%Blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween = create_tween()
	tween.tween_property(%Blocker, "modulate", Color.TRANSPARENT, 1)
	
