extends Control


var submit_mode = "chris_mode" # "default_mode", "steph_mode", "double_press" # issue with asap mode is it nullifies the penalty to submitting wrong wordv
var double_press_buttons = []
var SERVER_PORT = 7777
const SERVER_NODE_PATH = "res://data/scenes_and_scripts/scramble/scramble_server_scene.tscn"
@onready var pregame_timer_node = get_node("/root/MainMenu/PregameTimer")
var big_dictionary = { "Player One ID": 0, "Player Two ID": 0 , "All Found Words": [], "Player One Found Words": [], "Player Two Found Words": [], "Letters": [], "Player One Last Word Status": "", "Player Two Last Word Status": "", "Player One Score": 0, "Player Two Score": 0, "Server Time Left": 0, "Bonus Letter": "H", "Bonus Time Value": 0, "Bonus Letter Value": 0, "Player One Last Obscurity Value": null, "Player Two Last Obscurity Value": null, "Player One Number Of Found Words": 0, "Player Two Number Of Found Words": 0, "Parent": "RpcAwait", "Player One Last Word Counter": 0, "Player Two Last Word Counter": 0}
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
var tie_game = false
var tie_cycles 
var tie_animations_running = false
var sun_color = Color(1.0, 0.902, 0.502)
var last_found_word_counter = 0
var variant_button_status = "on" # on, off, dim
func _ready():
	%DisconnectionCover.visible = false
	%CanvasModulate.color = Color.TRANSPARENT
	%GameTimerLabel.modulate = Color.TRANSPARENT
	#username = arguments[1]
	submit_mode = Globals.submit_mode
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
	var tween = create_tween()
	tween.tween_property(%CanvasModulate, "color", Color.WHITE, 1)
	await tween.finished
	%MouseBlocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween2 = create_tween()
	tween2.tween_property(%GameTimerLabel, "modulate", Color.WHITE, 1)
	
		

func _process(delta):
	if bonus_pressed:
		%BonusLetter.add_theme_color_override("default_color", Color.BLUE)
		%BonusLetter.add_theme_font_size_override("normal_font_size", 350)
	if not bonus_pressed:
		%BonusLetter.add_theme_color_override("default_color", Color.DARK_RED)
		%BonusLetter.add_theme_font_size_override("normal_font_size", 310)
	%CurrentWord.text = current_chosen_letters_string
	if big_dictionary.has("Server Time Left"):
		if tie_game == false:
			if big_dictionary["Server Time Left"] <900:
				%GameTimerLabel.text = str(big_dictionary["Server Time Left"])
			else:
				%GameTimerLabel.text = ""
		else:
			%GameTimerLabel.add_theme_font_size_override("font_size", 100)
			%GameTimerLabel.text = "TIE GAME, OVERTIME!"
			
			if tie_animations_running == false:
				tie_game_pulse()
				tie_game_cloudscape()
				tie_animations_running = true
			
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
	

#func setup(background):
	#
	#
	#if background == "Mars":
		#%MarsBase.visible = true
		#
	#if background == "Jupiter":
		#%Jupiter4.visible = true	
		#%BackgroundFader.color = Color.TRANSPARENT
	#pass

func letter_collector(letter, letternode, bonus): #updates the current chosen letter array and disables already pressed letters
	Haptics.stacatto_singleton()
	current_chosen_letters_array.append(letter)
	current_chosen_letters_string += str(letter)
	if submit_mode == "default_mode": 
		letternode.mouse_filter = MOUSE_FILTER_IGNORE
		small_green_letters(letternode)
		letternode.add_theme_color_override("font_color", Color.LIGHT_BLUE)
		

	
	if submit_mode == "chris_mode":
		var button = Button.new()
		button.modulate = Color.TRANSPARENT
		double_press_buttons.append(button)
		button.size = letternode.size
		button.pressed.connect(submitter)
		letternode.add_child(button)
		small_green_letters(letternode)
		letternode.add_theme_color_override("font_color", Color.LIGHT_BLUE)
		
	if submit_mode == "steph_mode": 
		letternode.add_theme_color_override("font_color", Color.LIGHT_BLUE)
		letternode.mouse_filter = MOUSE_FILTER_IGNORE
		if current_chosen_letters_string.length() > 2:
			print("here")
			if GlobalData.is_valid_word(current_chosen_letters_string):
				print("here")
				if big_dictionary.has("All Found Words"):
					if big_dictionary["All Found Words"].has(current_chosen_letters_string):
						pass
					else:
						Haptics.stacatto_doublet()
						if bonus:
							bonus_pressed = true
						submitter()
	if bonus:
		bonus_pressed = true
		
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
	if submit_mode == "chris_mode":
		Haptics.stacatto_doublet()
		for i in double_press_buttons:
			i.queue_free()
		double_press_buttons = []
		
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
	%FoundWordLabel.text = ""
	#all_found_words.sort() #enable this option if you want to sort the list of found words before listing them
	for i in all_found_words:
		if p1foundwords.has(i):
			if is_player_one:
				%FoundWordLabel.text += "[color=dark_green]" + str(i) + "[/color]  "
			else:
				%FoundWordLabel.text += "[color=web_maroon]" + str(i) + "[/color]  "
		if p2foundwords.has(i):
			if is_player_one:
				%FoundWordLabel.text += "[color=web_maroon]" + str(i) + "[/color]  "
			else:
				%FoundWordLabel.text += "[color=dark_green]" + str(i) + "[/color]  "
	
	#for i in range(1,45):
		#var labelnodestring = "%FoundWord" + str(i)
		#var labelnode = get_node(labelnodestring)
		#if all_found_words.size() > i-1:
			#var word = all_found_words[i-1]
			#labelnode.text = word
	#for i in range(1,45): # setting opponent words to red
		#var labelnodestring = "%FoundWord" + str(i)
		#var labelnode = get_node(labelnodestring)
		#if is_player_one:
			#if p2foundwords.has(labelnode.text):
				#labelnode.add_theme_color_override("font_color", Color.RED)
			#if p1foundwords.has(labelnode.text):
				#labelnode.add_theme_color_override("font_color", Color.BLACK)
		#if is_player_two:
			#if p1foundwords.has(labelnode.text):
				#labelnode.add_theme_color_override("font_color", Color.RED)
			#if p2foundwords.has(labelnode.text):
				#labelnode.add_theme_color_override("font_color", Color.BLACK)
			
		 
	
	
				
			
		
	pass
	
@rpc("authority", "call_local")
func send_player_information():
	pass
	
func shuffler():
	Haptics.pitter_patter_light()
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
	
	
	if is_player_one:
		if last_found_word_counter != big_dictionary["Player One Last Word Counter"]:
			last_found_word_counter = big_dictionary["Player One Last Word Counter"]
			if big_dictionary["Player One Last Word Status"] == "word too short" or big_dictionary["Player One Last Word Status"] == "word already found" or big_dictionary["Player One Last Word Status"] == "invalid word":
				var status = big_dictionary["Player One Last Word Status"]
				var temp_label = %GameScore.duplicate()
				
				temp_label.add_theme_color_override("font_color", Color.DARK_RED)
				temp_label.modulate = Color.TRANSPARENT
				if status == "word too short":
					temp_label.text = "Too Short!"
				elif status == "word already found":
					temp_label.text = "Already Found!"
				elif status == "invalid word":
					temp_label.text = "Invalid Word! " + "- " + str(current_penalty) + " points" 
				
				%CanvasLayer.add_child(temp_label)
				var tween = create_tween()
				tween.set_ease(Tween.EASE_IN_OUT)
				tween.chain().tween_property(%GameScore, "modulate", Color.TRANSPARENT, 0.25)
				tween.chain().tween_property(temp_label, "modulate", Color.WHITE, 0.25)
				tween.chain().tween_property(temp_label, "modulate", Color.TRANSPARENT, 0.25)
				tween.chain().tween_property(%GameScore, "modulate", Color.WHITE, 0.25)
				await tween.finished
				temp_label.queue_free()
			
	if is_player_two:
		if last_found_word_counter != big_dictionary["Player Two Last Word Counter"]:
			last_found_word_counter = big_dictionary["Player Two Last Word Counter"]
			if big_dictionary["Player Two Last Word Status"] == "word too short" or big_dictionary["Player Two Last Word Status"] == "word already found" or big_dictionary["Player Two Last Word Status"] == "invalid word":
				var status = big_dictionary["Player Two Last Word Status"]
				var temp_label = %GameScore.duplicate()
				
				temp_label.add_theme_color_override("font_color", Color.DARK_RED)
				temp_label.modulate = Color.TRANSPARENT
				if status == "word too short":
					temp_label.text = "Too Short!"
				elif status == "word already found":
					temp_label.text = "Already Found!"
				elif status == "invalid word":
					temp_label.text = "Invalid Word! " + "- " + str(current_penalty) + " points" 
				%CanvasLayer.add_child(temp_label)
				var tween = create_tween()
				tween.set_ease(Tween.EASE_IN_OUT)
				tween.chain().tween_property(%GameScore, "modulate", Color.TRANSPARENT, 0.25)
				tween.chain().tween_property(temp_label, "modulate", Color.WHITE, 0.25)
				tween.chain().tween_property(temp_label, "modulate", Color.TRANSPARENT, 0.25)
				tween.chain().tween_property(%GameScore, "modulate", Color.WHITE, 0.25)
				await tween.finished
				
				
				temp_label.queue_free()
			
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
	shuffler()
	remote_tester()
	
	
@rpc("any_peer", "call_local")
func remote_tester():
	if big_dictionary.has(["Parent"]):
		#print(big_dictionary["Parent"])
		pass
	pass
	
func _on_submit_pressed():
	submitter()
	


func _on_clear_pressed() -> void:
	Haptics.triple_quick_soft()
	if submit_mode == "chris_mode":
		for i in double_press_buttons:
			i.queue_free()
		double_press_buttons = []
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
		print("obsc variant")
		var obscurity
		if big_dictionary.has("Player One Last Obscurity Value") and big_dictionary.has("Player Two Last Obscurity Value"):
			if is_player_one == true:
				obscurity = big_dictionary["Player One Last Obscurity Value"]
				print(obscurity)
			if is_player_two == true:
				obscurity = big_dictionary["Player Two Last Obscurity Value"]
				print(obscurity)
		
		if obscurity != null:
			
			var obscurity_label = %GameScore.duplicate()
			obscurity_label.text = "Obscurity = %s/10" % obscurity
			obscurity_label.modulate = Color.TRANSPARENT
			%CanvasLayer.add_child(obscurity_label)
			var tween = create_tween()
			tween.chain().tween_property(%GameScore, "modulate", Color.TRANSPARENT, 0.25)
			tween.chain().tween_property(obscurity_label, "modulate", Color.WHITE, 0.3)
			tween.chain().tween_property(obscurity_label, "modulate", Color.TRANSPARENT, 0.3)
			tween.chain().tween_property(%GameScore, "modulate", Color.WHITE, 0.25)
			
	else:
		return
func wrong_word_display():
	
	Haptics.double_normal_hard()
	var sun_tween = create_tween()
	sun_tween.set_ease(Tween.EASE_IN_OUT)
	sun_tween.set_trans(Tween.TRANS_CIRC)
	sun_tween.parallel().tween_property(%Sun, "material:shader_parameter/edge_softness", 0.25, 0.5)
	sun_tween.parallel().tween_property(%Sun, "material:shader_parameter/sun_color", Color.PALE_VIOLET_RED, 0.5)	
	sun_tween.chain().tween_property(%Sun, "material:shader_parameter/edge_softness", 0.419, 0.5)
	sun_tween.parallel().tween_property(%Sun, "material:shader_parameter/sun_color", sun_color, 0.5)		
	
	var jupiter_tween = create_tween()
	jupiter_tween.tween_property(%Jupiter4, "material:shader_parameter/band_A_color_2", Color.PALE_VIOLET_RED, 0.5)
	jupiter_tween.parallel().tween_property(%Jupiter4, "material:shader_parameter/band_D_color_2", Color.PALE_VIOLET_RED, 0.5)
	jupiter_tween.chain().tween_property(%Jupiter4, "material:shader_parameter/band_A_color_2", Color(0.65, 0.53, 0.41), 0.5)
	jupiter_tween.parallel().tween_property(%Jupiter4, "material:shader_parameter/band_D_color_2", Color(0.8, 0.7, 0.6), 0.5)
	
	

@rpc("authority", "call_local")
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
	var nodes_to_move = [%Submit, %Clear, %Shuffle, %BonusLetter, %BonusScore, %BonusReminder, %GameTimerLabel, %GameScore, %MiniScore, %HBoxContainer, %FoundWordLabel, %VariantControl, %CurrentWord]
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
	var particles = (load("res://data/scenes_and_scripts/particles/small_green_particles.tscn").instantiate())
	label_node.add_theme_font_size_override("font_size", 88)
	label_node.add_theme_color_override("font_color", Color.GREEN)
	letternode.add_child(label_node)
	
	
	
	
	label_node.text = str(letter_score)
	label_node.position += letternode.size/2
	var target_position = letternode.position
	target_position.y -= 2000
	target_position.x = 0

	label_node.add_child(particles)
	particles.position = label_node.size/2
	
	var tween = create_tween()
	tween.tween_property(label_node, "position", target_position, 1)
	#tween.parallel().tween_property(label_node, "position", Vector2((label_node.size.x/2) - 25,letternode.position.y - 150), 1)
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
	sun_tween.parallel().tween_property(%Sun, "material:shader_parameter/sun_color", sun_color, 0.5)		
	
	var jupiter_tween = create_tween()
	jupiter_tween.tween_property(%Jupiter4, "material:shader_parameter/band_A_color_2", Color(0.491, 0.585, 0.494), 0.5)
	jupiter_tween.parallel().tween_property(%Jupiter4, "material:shader_parameter/band_D_color_2", Color(0.8, 1.0, 0.6), 0.5)
	jupiter_tween.chain().tween_property(%Jupiter4, "material:shader_parameter/band_A_color_2", Color(0.65, 0.53, 0.41), 0.5)
	jupiter_tween.parallel().tween_property(%Jupiter4, "material:shader_parameter/band_D_color_2", Color(0.8, 0.7, 0.6), 0.5)
	pass
	
func _on_button_pressed() -> void:
	#wrong_word_display()
	#big_word_event()
	
	
	#big_dictionary["Player One Found Words"] = ["allan", "simon", "gary", "john", "chris", "mike", "allan", "simon", "gary"]
	#big_dictionary["Player Two Found Words"] = ["john", "chris", "mike", "john", "chris", "mike", "allan", "simon", "gary"]
	#big_dictionary["All Found Words"] = ["john", "chris", "mike", "allan", "simon", "gary", "john", "chris", "mike", "allan", "simon", "gary","john", "chris", "mike", "allan", "simon", "gary"]
	#found_words_populator()
	#wonder_game_ender(user_id)
	
	tie_game = true
	tie_game_pulse()
	tie_game_cloudscape()
	%GameTimerLabel.add_theme_font_size_override("font_size", 100)
	%GameTimerLabel.text = "TIE GAME! OVERTIME!"
	
	pass # Replace with function body.

func _initialize(dict):
	for i in [%Variant1, %Variant2, %Variant3]:
		i.visible = false
	var variant = dict["selected_games"][dict["current_round"]]
	if variant.contains("Bonus"):
		bonus_variant = true
		%Variant1.text = "Bonus"
		%Variant1.visible = true
	if variant.contains("Obscurity"):
		obscurity_variant = true
		%Variant2.text = "Obscurity"	
		%Variant2.visible = true
	if variant.contains("Wonder"):
		wonder_variant = true		
		%Variant3.text = "Wonder"
		%Variant3.visible = true
	pass

func fade_blocker():
	
	%Blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween = create_tween()
	tween.tween_property(%Blocker, "modulate", Color.TRANSPARENT, 1)
	
@rpc("authority", "call_local", "reliable")			
func tie_game_informer(tie_game_cycles):
	tie_game = true
	tie_cycles = tie_game_cycles
	pass

func tie_game_pulse():
	
	var tween = create_tween()
	tween.set_loops()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	%GameTimerLabel.pivot_offset = %GameTimerLabel.size/2
	%GameTimerLabel.add_theme_color_override("font_color", Color.FIREBRICK)
	tween.tween_property(%GameTimerLabel, "scale", Vector2(0.75, 0.75), 0.5)
	tween.chain().tween_property(%GameTimerLabel, "scale", Vector2(1, 1), 0.5)
	pass

func tie_game_cloudscape():
	%Sun.pivot_offset = %Sun.size/2
	var sun_tween = create_tween()
	sun_tween.tween_property(%Sun, "material:shader_parameter/sun_color", Color.BLACK, 2)
	sun_color = Color.BLACK
	sun_tween.parallel().tween_property(%Sun, "scale", Vector2 (1.3, 1.3), 1)
	if %Cloudscape1.visible == true:
		
		var cloud_tween = create_tween()
		cloud_tween.set_ease(Tween.EASE_IN_OUT)
		cloud_tween.set_trans(Tween.TRANS_SINE)
		cloud_tween.tween_property(%Cloudscape1, "material:shader_parameter/sky_color", Color(1.0, 0.0, 0.0, 0.949), 2)
		cloud_tween.parallel().tween_property(%Cloudscape1, "material:shader_parameter/cloud_color", Color(0.773, 0.573, 0.0), 2)
		

	pass


func _on_button_2_pressed() -> void:
	for i in %LetterContainer.get_children():
		i.text = "A"
	pass # Replace with function body.


func _on_variant_button_pressed() -> void:
	Haptics.double_quick_medium()
	if variant_button_status == "on":
		var tween = create_tween()
		tween.tween_property(%VariantBox, "modulate:a", 0.5, 0.5)
		await tween.finished
		variant_button_status = "dim"
		return
	if variant_button_status == "dim":
		var tween = create_tween()
		tween.tween_property(%VariantBox, "modulate:a", 0.05, 0.5)
		await tween.finished
		variant_button_status = "off"
		return
	if variant_button_status == "off":
		var tween = create_tween()
		tween.tween_property(%VariantBox, "modulate:a", 1.0, 0.5)
		await tween.finished
		variant_button_status = "on"	
		return
		
	pass # Replace with function body.

@rpc("authority", "call_local")
func _disconnect_function(connected_player_peer_id, time_left):
	print("fhwuiefoiuwehfewfewf")
	print("ran   connectd player: " + str(connected_player_peer_id))	
	%DisconnectionCover._begin(time_left)
	pass
	
@rpc("authority", "call_local")
func _reconnect_function():
	%DisconnectionCover._end()
	
