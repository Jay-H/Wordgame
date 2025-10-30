extends Control
@onready var viewport_size = get_viewport_rect().size
@onready var bonus_value_timer = $BonusValueTimer 
var obscurity_value = 0
var bonus_value = 0
var current_bonus_node = null
var already_used_words = []
var bonus_letter_pressed = false
var bonus_letter_used = false
var bonus_letter_spawned = false
var alphabet = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
var bonus_letter = ""
var button_grid_scene = load('res://data/scenes_and_scripts/scramble/c_scramble_hgrid.tscn')
var button_scene = load('res://data/scenes_and_scripts/scramble/c_scramble_letter.tscn')
var button_block_scene = load('res://data/scenes_and_scripts/scramble/c_button_texture.tscn')
var found_words_scene = load('res://data/scenes_and_scripts/scramble/c_found_words.tscn')
var pulse = null
var final_letters_array = []
var selected_letters_array = []
var selected_word_string = ""
var possible_words_array = []
var found_words_alphabetical_array = []
var your_found_words_array = []
var found_word = ""
var found_words_cumulative = []
var letter_color = "BLACK"
var style_box_flat = StyleBoxEmpty.new()
var black_theme: Theme = load("res://data/themes/c_empty_theme.tres")
var red_theme: Theme = load("res://data/themes/c_red_letter.tres")
var aquamarine_theme: Theme = load("res://data/themes/c_aquamarine_theme.tres")
var counter = 0
var pulsing = false
var pulsing2 = false
var timer_tween_created = false
var timer_tween = null
var score = 0
var mini_score = 0
var seven_letter_bonus = 50
var minus_score = 2 # how much you lose for an illegal word
var game_started = false
var score_display = null
var round_finished = false
var five_second_trigger = false
var one_second_trigger = false
signal five_seconds
signal one_second
signal zero_seconds



@onready var timer_node = $Control3/Timer


const SCRABBLE_TILE_BAG = "AAAAAAAAABBCDDDEEEEEEEEEEEFFGGGHHIIIIIIIIIJKLLLLMMNNNNNNOOOOOOOOPPQRRRRRRSSSSSTTTTTTUUUUVVWWXYYZ"
const SCRABBLE_TILE_ARRAY = [
	"A", "A", "A", "A", "A", "A", "A", "A", "A", # 9 A's
	"B", "B", # 2 B's
	"C", "C", # 2 C's
	"D", "D", "D", "D", # 4 D's
	"E", "E", "E", "E", "E", "E", "E", "E", "E", "E", "E", "E", # 12 E's
	"F", "F", # 2 F's
	"G", "G", "G", # 3 G's
	"H", "H", # 2 H's
	"I", "I", "I", "I", "I", "I", "I", "I", "I", # 9 I's
	"J", # 1 J
	"K", # 1 K
	"L", "L", "L", "L", # 4 L's
	"M", "M", # 2 M's
	"N", "N", "N", "N", "N", "N", # 6 N's
	"O", "O", "O", "O", "O", "O", "O", "O", # 8 O's
	"P", "P", # 2 P's
	"Q", # 1 Q
	"R", "R", "R", "R", "R", "R", # 6 R's
	"S", "S", "S", "S", # 4 S's
	"T", "T", "T", "T", "T", "T", # 6 T's
	"U", "U", "U", "U", # 4 U's
	"V", "V", # 2 V's
	"W", "W", # 2 W's
	"X", # 1 X
	"Y", "Y", # 2 Y's
	"Z"]  # 1 Z
	# Total: 100 entries
@onready var global_data = get_node("/root/GlobalData")

func _ready():
	var viewport_size = get_viewport_rect().size 
	$ColorRect.size = viewport_size
	var success = false
	for i in range(1):
		if success == false:
			find_good_letters()
			generate_buttons()
	await get_tree().process_frame
	print(final_letters_array)
	submit_shuffle_clear_generator()
	current_letters_displayer()
	timer_creator()
	score_displayer()
	mini_score_displayer("bonus")
	game_started = true
	CSignals.bonus_clicked.connect(bonus_letter_getter)
	
func bonus_letter_getter(text):
	var bonus_letter_node = current_bonus_node
	var elapsed_time = bonus_value_timer.wait_time - bonus_value_timer.time_left
	var bonus_amount = int(elapsed_time) + GlobalData.SCRABBLE_POINTS[text]
	if bonus_letter_pressed == false:
		bonus_letter_pressed = true
		print(text)
		selected_letters_array.append(text)
		selected_word_string += text
		current_letters_displayer()
		mini_score_displayer("bonus", bonus_amount) 
		bonus_letter_node.add_theme_color_override("font_color", Color.GRAY)
		
		bonus_letter_used = true
		
	else:
		pass
		
func bonus_letter_remover():
	if bonus_letter_used == false:
		pass
	if bonus_letter_used == true:
		current_bonus_node.queue_free()
		bonus_letter_used = false
		bonus_letter_pressed = false
		bonus_letter_spawner()
	
	
func _process(delta):
	timer_updater()
	pass

func timer_updater():
	var timer = $Control3/Timer
	var time_left = int(timer.time_left)
	var timer_label_node = $Control3/Label
	var score_updated = false
	#if time_left < 45:
		#if bonus_letter_spawned == false:
			#bonus_letter_spawner()
			#bonus_letter_spawned = true
	if time_left > 9:
		timer_label_node.text = "00:" + str(time_left)
	else:
		timer_label_node.text = "00:0" + str(time_left)
	if time_left < 6:
		timer_label_node.add_theme_color_override("font_color", Color.RED)
		if timer_tween_created == false:
			timer_tween = create_tween()
			timer_tween_created = true
			timer_tween.set_loops(5)
			timer_tween.set_trans(Tween.TRANS_QUAD)
			timer_tween.set_ease(Tween.EASE_OUT)
		if pulsing2 == false:
			pulsing2 = true
			timer_tween.tween_property(timer_label_node, "theme_override_font_sizes/font_size", 180, 0.8)
			timer_tween.tween_property(timer_label_node, "theme_override_font_sizes/font_size", 130, 0.2)
	if time_left <5:
		if five_second_trigger == false:
			emit_signal("five_seconds")
			five_second_trigger = true
			
	if time_left <1:
		if one_second_trigger == false:
			one_second_trigger = true
			emit_signal("one_second")
	if round_finished == false:
		if time_left == 0:
			CSignals.player_round_score += score
			emit_signal("zero_seconds")
			print("running")
			round_finished = true
		
		
func bonus_letter_spawner():
	var bonus_letter_node = load("res://data/scenes_and_scripts/scramble/c_bonus_letter.tscn")
	var bonus_letter_node_instance = bonus_letter_node.instantiate()
	var bonus_letter_label = bonus_letter_node_instance.get_node("BonusLetter")
	print(viewport_size)
	
	
	
	bonus_value_timer.start()
	current_bonus_node = bonus_letter_label
	bonus_letter = alphabet[randi_range(0,25)]
	bonus_letter_label.text = bonus_letter
	GlobalData.current_bonus_letter = bonus_letter_label.text
	add_child(bonus_letter_node_instance)
	bonus_letter_label.position = viewport_size/2 - bonus_letter_label.size/2
	bonus_letter_label.position.y += viewport_size.y/2.5
	#await get_tree().process_frame
	bonus_letter_label.set_pivot_offset(bonus_letter_label.size/2)
	GlobalData.bonus_letter_global_position = bonus_letter_label.global_position
	print(bonus_letter_label.global_position)
	var pale_pink = Color.PINK
	var pale_blue = Color.NAVY_BLUE
	
	bonus_letter_label.modulate = pale_pink
	#bonus_letter_label.gui_input().connect(letter_collector.bind(bonus_letter_label.text, bonus_letter_label))
	
	var tween = create_tween()
	
	tween.set_loops(0)
	tween.tween_property(bonus_letter_label, "scale", Vector2(1,1), 0.7)
	tween.tween_property(bonus_letter_label, "scale", Vector2(0.85,0.85), 0.7)
	
	# Create a tween that will run forever
	var tween2 = create_tween().set_loops()
	
	# Animate from pink to blue over 2 seconds
	tween2.tween_property(bonus_letter_label, "modulate", pale_blue, 2.0)
	
	# Chain the next animation to run after the first one finishes
	# Animate from blue back to pink over 2 seconds
	tween2.chain().tween_property(bonus_letter_label, "modulate", pale_pink, 2.0)
	
	
	pass

func timer_creator():
	var timer_control = get_node("Control3")
	var viewport_size = get_viewport_rect().size 
	var timer_label_node = get_node("Control3/Label")
	
	timer_control.position.x = viewport_size.x/2
	timer_control.position.y = viewport_size.y/2
	timer_control.position.y += 330
	timer_label_node.add_theme_color_override("font_color", letter_color)
	

	pass
	
func found_words_alphabetizer():
	#this quickly alphabetizes the list of found words for other use into the found_words_alphabetical_array global variable. 
	found_words_alphabetical_array = found_words_cumulative
	found_words_alphabetical_array.sort()
		
	pass

func big_word_mover(label):
	var moving_word_control = PanelContainer.new()
	var moving_word = Label.new()
	moving_word_control.set_anchors_preset(Control.PRESET_CENTER)
	moving_word_control.self_modulate = Color.TRANSPARENT
	moving_word.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER) # Center text within the label
	moving_word.set_vertical_alignment(VERTICAL_ALIGNMENT_CENTER) # Center text within the label
	moving_word.text = found_word
	moving_word.add_theme_font_size_override("font_size", 150)
	moving_word.add_theme_color_override("font_color", Color.GOLDENROD)
	add_child(moving_word_control)
	moving_word_control.add_child(moving_word)
	await get_tree().process_frame
	await get_tree().process_frame
	moving_word_control.set_pivot_offset(moving_word.size/2)
	moving_word_control.position = get_viewport_rect().size/2.0
	moving_word_control.position -= moving_word.size/2.0
	moving_word_control.position.y -= 220
	
	
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	
	tween.tween_property(moving_word_control,"scale", Vector2(1.6,1.6), 0.5)
		
	tween.chain().tween_property(moving_word_control, "position", label.position, 0.8)
	tween.parallel().tween_property(moving_word_control, "modulate", Color.TRANSPARENT, 1.0)
	tween.parallel().tween_property(moving_word_control,"scale", Vector2(0.5,0.5), 0.8)

func word_scorer():
	score += mini_score
	score += obscurity_value
	if score <1:
		score = 0
	print("score = ", score)
	pass

func found_words():
	# this function is what puts the found words in the grid at the top
	# also it puts the cumulatively found words in the array found_words_cumulative
	if found_word.length() >= 3: 
		found_words_cumulative.append(found_word)
		found_words_alphabetical_array = []
		found_words_alphabetizer()
		var array_of_grid_label_nodes = []
		var found_words = get_node("Control")
		var found_words_grid1 = found_words.get_node("GridContainer")
		var found_words_grid2 = found_words.get_node("GridContainer2")
		var found_words_grid3 = found_words.get_node("GridContainer3")
		var found_words_grid4 = found_words.get_node("GridContainer4")
		var found_words_grid5 = found_words.get_node("GridContainer5")
			
		var label = Label.new()
		label.name = "Label"+str(counter)
		counter += 1
		
		label.add_theme_font_size_override("font_size", 50)
		label.add_theme_color_override("font_color", letter_color)

		
		
		
		if found_words_cumulative.size() <12:
			found_words_grid1.add_child(label)
			label.text = found_word 
			big_word_mover(label)
			found_word = ""
		if found_words_cumulative.size() > 11 and found_words_cumulative.size() <23:
			found_words_grid2.add_child(label)
			label.text = found_word
			big_word_mover(label)
			found_word = ""
		if found_words_cumulative.size() >22 and found_words_cumulative.size() <34:
			found_words_grid3.add_child(label)
			label.text = found_word
			big_word_mover(label)
			found_word = ""
		if found_words_cumulative.size() > 33 and found_words_cumulative.size() <45:
			found_words_grid4.add_child(label)
			label.text = found_word
			big_word_mover(label)
			found_word = ""
		if found_words_cumulative.size() >44:
			found_words_grid5.add_child(label)
			label.text = found_word
			big_word_mover(label)
			found_word = ""
		print(found_word)
		array_of_grid_label_nodes = found_words_grid1.get_children() + found_words_grid2.get_children() + found_words_grid3.get_children() + found_words_grid4.get_children() + found_words_grid5.get_children()
		#the below part goes through the names of the labels which will populate the above containers and are named Label0, Label1, etc. 
		#it then changes the text in them to be in alphabetical order using their Label"n" as the index to search an array of the alphabetically sorted words. 
		for i in array_of_grid_label_nodes:
			var index = i.name
			var regex = RegEx.new()
			regex.compile("(\\d+)")
			var result = regex.search(index)
			if result:
				var number_string = result.get_string(1)
				var number_int = number_string.to_int()
				i.text = found_words_alphabetical_array[number_int]
				
			pass
	
func current_letters_displayer():
	# this function takes the letters from selected_letters_array and concatenates them into the display variable which is the text of a label 
	var display = get_node("Control2/Label")
	var control = get_node("Control2")
	var viewport_size = get_viewport_rect().size 
	display.add_theme_color_override("font_color", letter_color)
	control.position = viewport_size/2
	control.position.y -= 250
	control.position.x -= control.size.x/2
	var number_of_letters = selected_letters_array.size()
	var concatenated_starting = "".join(selected_letters_array)
	display.text = concatenated_starting
	if selected_letters_array.size() == 0:
		display.text = ""
	
		
	pass
	
func score_displayer():
	# THis one will display the score
	$CenterContainer2.set_anchors_preset(Control.PRESET_CENTER)
	$CenterContainer2.set_offsets_preset(Control.PRESET_CENTER)
	$CenterContainer2/Label.text = "Score = " + str(score)
	# The following two lines are to reset the color stuff done by the wrong_word_display function
	$CenterContainer2/Label.add_theme_color_override("font_color", Color.BLACK) 
	$CenterContainer2/Label.self_modulate = Color.WHITE
	$CenterContainer2.position = get_viewport_rect().size/2
	$CenterContainer2.set_pivot_offset($CenterContainer.size/2)
	$CenterContainer2.position -= $CenterContainer2.size/2
	$CenterContainer2.position.y -= 500
	
	
	pass

func wrong_word_display():
	var label = Label.new()
	var label_container = CenterContainer.new()
	var score_display = $CenterContainer2
	var score_display_label = $CenterContainer2/Label
	#label_container.position = score_display.position
	
	label.self_modulate.a = 0.0
	add_child(label_container)
	label_container.add_child(label)
	label.name = "wrong_word_display"
	label_container.name = "wrong_word_score_container"
	label.add_theme_font_size_override("font_size", 70)
	label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	label.set_vertical_alignment(VERTICAL_ALIGNMENT_CENTER)
	label.theme = red_theme
	label.text = "-2 points"
	await get_tree().process_frame
	await get_tree().process_frame
	
	
	var label_container_original_size = label_container.size
	
	label_container.scale = Vector2(0,0)
	
	await get_tree().process_frame
	label_container.set_pivot_offset(label_container.size / 2.0)
	label_container.global_position = score_display.position
	label_container.position.x += (score_display.size.x/2)
	label_container.position.y += (score_display.size.y) + ((score_display.size.y)/2)
	await get_tree().process_frame
	await get_tree().process_frame
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT) 
	tween.set_trans(Tween.TRANS_SPRING)
	score_display_label.add_theme_color_override("font_color", Color.RED)
	tween.parallel().tween_property(score_display_label, "self_modulate", Color.BLACK, 1)
	tween.parallel().tween_property(label, "self_modulate:a", 1, 0.5)
	tween.parallel().tween_property(label_container, "scale", Vector2(1,1), 0.5)
	
	
	tween.chain().tween_property(label, "self_modulate:b", 0, 0.5)
	
	await tween.finished
	label_container.queue_free()
	



	
	
	pass

func letter_collector(button_text, button_node):
	# this function will take the pressed letters and put them into the global variable selected_letters_array 
	# it will also deactivate the button until a word is submitted or cleared
	selected_letters_array.append(button_text)
	current_letters_displayer()
	create_points_pop_up(button_node)
	letter_disabler(button_node)
	selected_word_string += button_text
	button_node.theme = aquamarine_theme
	mini_score_displayer(button_text)

	
func mini_score_displayer(button_text, points_to_add = 0):
	#if pulsing == true:
		#pulsing = false
		#print("pulse" + str(pulse))
		#pulse.kill()
		#$CenterContainer.scale = Vector2(1,1)
	if selected_letters_array.size() <7:
		if pulse:
			pulse.kill()
			$CenterContainer.scale = Vector2(1,1)
			pulsing = false
	if button_text != "bonus":
		mini_score += GlobalData.SCRABBLE_POINTS[button_text]
	else:
		mini_score += points_to_add
	var mini_score_label = $CenterContainer/Label
	mini_score_label.text = str(mini_score)
	mini_score_label.set_pivot_offset(mini_score_label.size/2)
	viewport_size = get_viewport_rect().size
	$CenterContainer.set_anchors_preset(Control.PRESET_CENTER)
	$CenterContainer.set_offsets_preset(Control.PRESET_CENTER)
	$CenterContainer.set_pivot_offset($CenterContainer.size/2)
	$CenterContainer.position = viewport_size/2
	$CenterContainer.position -= mini_score_label.size/2
	$CenterContainer.position.y += 700
	GlobalData.mini_score_display_global_position = mini_score_label.global_position
	GlobalData.mini_score_display_size = mini_score_label.size
	
	
	if selected_letters_array.size() > 6:
		
		if pulsing == false:
			pulsing = true
			mini_score_label.add_theme_color_override("font_color", Color.BLUE)
			pulse = create_tween()
			pulse.set_loops()
			mini_score += seven_letter_bonus
			mini_score_label.text = str(mini_score)
			await get_tree().process_frame
			pulse.set_ease(Tween.EASE_IN_OUT)
			pulse.set_trans(Tween.TRANS_QUAD)
			$CenterContainer.set_pivot_offset($CenterContainer.size/2)
			$CenterContainer.position = viewport_size/2
			$CenterContainer.position -= mini_score_label.size/2
			$CenterContainer.position.y += 700
			pulse.tween_property($CenterContainer,"scale",Vector2(1.5,1.5),0.5)
			pulse.tween_property($CenterContainer,"scale",Vector2(1.0,1.0),0.5)
	
		
	else:
		pass
	
	pass

func mini_score_clearer():
	$CenterContainer/Label.text = "0"
	$CenterContainer/Label.add_theme_color_override("font_color", Color.BLACK)
	mini_score = 0
	pass
	
func letter_disabler(button_node):
	# to disable repeat clicking of the same letter
	button_node.disabled = true
	pass	
	
func letter_resetter():
	var HBoxContainer_node = $"CScrambleHgrid/HBoxContainer"
	for i in HBoxContainer_node.get_children():
		for x in i.get_children():
			x.add_theme_color_override("font_color", Color.BLACK)
			x.add_theme_color_override("font_pressed_color", Color.BLACK)
			x.add_theme_color_override("font_hover_color", Color.BLACK)
			x.add_theme_color_override("font_focus_color", Color.BLACK)
			x.theme = black_theme
			
			x.disabled = false
				
	pass

#func submitter():
	#var word = selected_word_string
	#print(selected_word_string)
	#print(selected_letters_array)
	#if GlobalData.is_valid_word(selected_word_string):
		#print("valid")
		#already_used_words.append(word) 
	#if selected_letters_array.size()>=3:
		#if selected_word_string in possible_words_array:
			#if not already_used_words.has(selected_word_string):
				#if selected_word_string.length() == 7: 
					#show_success_animation()
					#screen_shaker()
					#found_seven_letter_word()
					#found_word = selected_word_string
					#print("BOSS")
					#var remover = possible_words_array.find(selected_word_string)
					#possible_words_array.remove_at(remover)
					#selected_word_string = ""
					#found_words()
					#selected_letters_array = []
					#current_letters_displayer()
					#letter_resetter()
					#word_scorer()
					#score_displayer()
					#mini_score_clearer()
					#bonus_letter_remover()
				#
				#
				#
				#
				#
				#else:
					#print("real word")
					#found_word = selected_word_string
					#var remover = possible_words_array.find(selected_word_string)
					#possible_words_array.remove_at(remover)
					#selected_word_string = ""
					#found_words()
					#selected_letters_array = []
					#current_letters_displayer()
					#letter_resetter()
					#found_words_alphabetizer()
					#word_scorer()
					#score_displayer()
					#mini_score_clearer()
					#bonus_letter_remover()
				#
		#else:
			#if selected_word_string.length() >= GlobalData.allowed_word_length:
				#print("you suck")	
				#wrong_word_display()
				#selected_word_string = ""
				#selected_letters_array = []
				#current_letters_displayer()
				#letter_resetter()
				#score -= minus_score
				#if score < 0:
					#score = 0
				#score_displayer()
				#mini_score_clearer()
				#bonus_letter_pressed = false
				#
				#
			#else: 
				#pass
	#pass
	
func submitter():
	var word = selected_word_string
	print(selected_word_string)
	print(selected_letters_array)
	if not GlobalData.is_valid_word(selected_word_string):		
		print("invalid")
		if selected_word_string.length() >= GlobalData.allowed_word_length:
			print("you suck")	
			wrong_word_display()
			selected_word_string = ""
			selected_letters_array = []
			current_letters_displayer()
			letter_resetter()
			score -= minus_score
			if score < 0:
				score = 0
			score_displayer()
			mini_score_displayer("bonus")
			mini_score_clearer()
			bonus_letter_pressed = false
			#current_bonus_node.add_theme_color_override("font_color", Color.GOLDENROD)
			
	if GlobalData.is_valid_word(selected_word_string):
		print("valid")
		#already_used_words.append(word) 
		print(already_used_words)
		if selected_letters_array.size()>=3:
			if already_used_words.has(selected_word_string):
				selected_word_string = ""
				selected_letters_array = []
				letter_resetter()
				mini_score_displayer("bonus")
				mini_score_clearer()
				current_letters_displayer()
				bonus_letter_pressed = false
				#current_bonus_node.add_theme_color_override("font_color", Color.GOLDENROD)
				
				pass
			if not already_used_words.has(selected_word_string):
				if selected_word_string.length() == 7:
					already_used_words.append(word)
					#obscurity_value = obscurity_collector(selected_word_string) 
					show_success_animation()
					screen_shaker()
					#show_obscurity_popup(obscurity_value)
					found_seven_letter_word()
					found_word = selected_word_string
					print("BOSS")
					var remover = possible_words_array.find(selected_word_string)
					possible_words_array.remove_at(remover)
					selected_word_string = ""
					found_words()
					selected_letters_array = []
					current_letters_displayer()
					letter_resetter()
					word_scorer()
					score_displayer()
					mini_score_displayer("bonus")
					mini_score_clearer()
					bonus_letter_remover()
					
					
				else:
					print("real word")
					#obscurity_value = obscurity_collector(selected_word_string)
					#show_obscurity_popup(obscurity_value)
					found_word = selected_word_string
					already_used_words.append(word)
					var remover = possible_words_array.find(selected_word_string)
					possible_words_array.remove_at(remover)
					selected_word_string = ""
					
					found_words()
					selected_letters_array = []
					current_letters_displayer()
					letter_resetter()
					found_words_alphabetizer()
					word_scorer()
					score_displayer()
					mini_score_clearer()
					bonus_letter_remover()
	
			
			
		else: 
			pass
		pass
	
func found_seven_letter_word():
	
	pass
	

func clearer():
	selected_letters_array = []
	selected_word_string = ""
	current_letters_displayer()
	letter_resetter()
	mini_score_displayer("bonus")
	mini_score_clearer()
	bonus_letter_pressed = false
	bonus_letter_used = false
	pass
	
func submit_shuffle_clear_generator():
	var viewport_size = get_viewport_rect().size
	var submit_button = Button.new()
	var shuffle_button = Button.new()
	var clear_button = Button.new()
	submit_button.add_to_group("shakeable")
	clear_button.add_to_group("shakeable")
	shuffle_button.add_to_group("shakeable")
	add_child(submit_button)
	add_child(shuffle_button)
	add_child(clear_button)
	
	submit_button.position = viewport_size/2
	submit_button.add_theme_font_size_override("font_size",70)
	submit_button.add_theme_stylebox_override("normal", style_box_flat)
	submit_button.add_theme_stylebox_override("pressed", style_box_flat)
	submit_button.add_theme_stylebox_override("focus", style_box_flat)
	submit_button.add_theme_stylebox_override("hover", style_box_flat)
	submit_button.theme = black_theme
	
	
		
	submit_button.text = "Submit"
	await get_tree().process_frame
	submit_button.position -= submit_button.get_rect().size/2
	submit_button.position.y += 300
	submit_button.position.x -= 400
	submit_button.pressed.connect(submitter)
	
	shuffle_button.position = viewport_size/2
	shuffle_button.add_theme_font_size_override("font_size", 70)
	shuffle_button.add_theme_color_override("font_color", letter_color)
	shuffle_button.add_theme_stylebox_override("normal", style_box_flat)
	shuffle_button.add_theme_stylebox_override("normal", style_box_flat)
	shuffle_button.add_theme_stylebox_override("pressed", style_box_flat)
	shuffle_button.add_theme_stylebox_override("focus", style_box_flat)
	shuffle_button.add_theme_stylebox_override("hover", style_box_flat)
	shuffle_button.theme = black_theme
	shuffle_button.text = "Shuffle"
	await get_tree().process_frame
	shuffle_button.position -= shuffle_button.get_rect().size/2
	shuffle_button.position.y += 300
	shuffle_button.position.x += 400
	shuffle_button.pressed.connect(shuffler)
	
	
	clear_button.position = viewport_size/2
	clear_button.add_theme_font_size_override("font_size",70)
	clear_button.add_theme_color_override("font_color", letter_color)
	clear_button.add_theme_stylebox_override("normal", style_box_flat)
	clear_button.add_theme_stylebox_override("normal", style_box_flat)
	clear_button.add_theme_stylebox_override("normal", style_box_flat)
	clear_button.add_theme_stylebox_override("pressed", style_box_flat)
	clear_button.add_theme_stylebox_override("focus", style_box_flat)
	clear_button.add_theme_stylebox_override("hover", style_box_flat)
	clear_button.theme = black_theme
	clear_button.text = "Clear"
	await get_tree().process_frame
	clear_button.position -= clear_button.get_rect().size/2
	clear_button.position.y += 500
	#clear_button.position.x += 400
	clear_button.pressed.connect(clearer)
	
	
	

func shuffler():
	var hbox_node_container = get_node("CScrambleHgrid/HBoxContainer")
	var children = hbox_node_container.get_children()
	children.shuffle()
	for i in range(children.size()):
		var child_node = children[i]
		hbox_node_container.move_child(child_node, i)
	pass
	

	
	
	
	
func generate_buttons():
	var button_grid = button_grid_scene.instantiate()
	var button_font_size = 180
	var button_size = 200
	var separation = button_size
	add_child(button_grid)
	var button_hbox_node = button_grid.get_node("HBoxContainer")
	var viewport_size = get_viewport_rect().size
	
	button_grid.position = viewport_size/2 
	button_grid.position.x -= separation/2
	
	# Wait for the node to be processed once to get its size accurately for centering
	await get_tree().process_frame 
	button_grid.position.x -= button_grid.get_rect().size.x / 2
	
	button_hbox_node.add_theme_constant_override("separation", separation)

	for i in range(7):
		# Instantiate your letter button scene (e.g., a Control node with a Button child)
		var button_instance = button_scene.instantiate()
		button_instance.add_to_group("shakeable")
		#button_instance.mouse_filter = Control.MOUSE_FILTER_PASS
		# We don't need a new PanelContainer for each button if the HBoxContainer handles layout.
		# Directly add the button instance to the HBoxContainer.
		button_hbox_node.add_child(button_instance)
		
		
		# Get the actual Button node from within your instantiated scene
		var button_node = button_instance.get_node("Button")
		button_node.size.x = button_size
		button_node.size.y = button_size
		
		# Check if the node was found to prevent errors
		if button_node:
			button_node.text = final_letters_array[i]
			button_node.add_theme_font_size_override("font_size", button_font_size)
			button_node.theme = black_theme
			button_node.add_theme_stylebox_override("normal", style_box_flat)
			
			# This is the correct way to connect the signal.
			# The 'pressed' signal from the button_node will now call 'letter_collector'.
			button_node.pressed.connect(letter_collector.bind(button_node.text, button_node))
			
		else:
			print("Error: Could not find node 'Button' in scene 'c_scramble_letter.tscn'")


	
	

		
	pass


	
func find_good_letters():
	# Define your specific criteria for a "good" hand
	var min_other_words_required = 25 # At least 25 OTHER words (3-6 letters)
									  # This implies the total words will be >= 26 (20 + the 7-letter word)

	var chosen_letters_string = ""
	var attempts = 0
	var max_attempts = 2000 # Increased max attempts as this can be harder to satisfy

	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var start_total_time = Time.get_ticks_msec()

	# Essential check: make sure we actually have 7-letter words loaded
	if global_data.seven_letter_words_list.is_empty():
		print("Error: No 7-letter words found in the dictionary! Cannot generate a hand with a guaranteed 7-letter word.")
		return # Abort if the 7-letter word list is empty

	while true:
		attempts += 1
		if attempts > max_attempts:
			print("Failed to find suitable letters after ", max_attempts, " attempts.")
			print("Consider relaxing 'min_other_words_required' (current: ", min_other_words_required, ") or checking your dictionary.")
			return # Exit function if max attempts reached

		# 1. Pick a random 7-letter word from the pre-filtered list
		var random_seven_word_index = rng.randi_range(0, global_data.seven_letter_words_list.size() - 1)
		var chosen_seven_word = global_data.seven_letter_words_list[random_seven_word_index]
		
		# The hand for the player is now directly the letters of this chosen 7-letter word
		chosen_letters_string = chosen_seven_word
		var shuffled_letters_array = []
			# Convert the string into an array of its characters
		for char in chosen_letters_string:
			shuffled_letters_array.append(char)
			
			# Shuffle the array
			shuffled_letters_array.shuffle()
			
			# Join the array back into a string (if you need it as a string for display/storage)
			var final_shuffled_display_string = "".join(shuffled_letters_array)
			print("Shuffled letters for display: ", final_shuffled_display_string)
		print("\n--- Attempt ", attempts, ": Testing hand from chosen 7-letter word: '", chosen_letters_string, "' ---")

		var start_check_time = Time.get_ticks_msec()

		# 2. Find ALL possible words from this hand (including the 7-letter word itself, and 3-6 letter words)
		var all_possible_words_from_hand = global_data.find_valid_words_from_letters(chosen_letters_string)

		var end_check_time = Time.get_ticks_msec()
		print("Time taken for word generation and lookup: ", (end_check_time - start_check_time) / 1000.0, " seconds")

		# 3. Check the criteria:
		#    a. We know a 7-letter word exists (it's `chosen_seven_word`).
		#    b. We need to check for at least `min_other_words_required` *additional* words (3-6 letters).

		var total_words_found = all_possible_words_from_hand.size()
		
		# The number of "other" words is the total found minus the 7-letter word we picked
		# (assuming `find_valid_words_from_letters` only returns 3+ letter words, including the 7-letter one).
		var actual_other_words_count = total_words_found - 1

		var criteria_met = (actual_other_words_count >= min_other_words_required)

		if criteria_met:
			print("SUCCESS! Found a good hand: '", chosen_letters_string, "'")
			print("Total words found (3+ letters): ", total_words_found)
			print(all_possible_words_from_hand)
			possible_words_array = all_possible_words_from_hand
			print("Other words (3-6 letters): ", actual_other_words_count, " (>= ", min_other_words_required, " required)")
			break # Exit the loop, we found a suitable set of letters!
		else:
			print("Hand '", chosen_letters_string, "' did not meet criteria.")
			print("Only found ", actual_other_words_count, " other words (needed ", min_other_words_required, ").")

	var end_total_time = Time.get_ticks_msec()
	print("Total time to find suitable letters (including multiple attempts): ", (end_total_time - start_total_time) / 1000.0, " seconds")

	# `chosen_letters_string` now holds the letters for the player's hand
	print("\n--- Game will start with letters: ", chosen_letters_string, " ---")
	for character in chosen_letters_string:
		final_letters_array.append(character)
		final_letters_array.shuffle()
		if final_letters_array.size() == 7:
			return final_letters_array
	
	print(final_letters_array)
	
	

	

func letter_chooser():
	var seven_letters = []
	for a in range(7):
		var b = randi_range(0,97)
		seven_letters.append(SCRABBLE_TILE_ARRAY[b])
		
	print(seven_letters)
		
	pass
	
	



# This function could be in your main game script or a utility script.
# It requires the 'target_tile_label' which is the existing Label node
# (e.g., your letter tile) to spawn the points label over.

func create_points_pop_up(target_tile_label: Button):
	# 1. Create a container for the points label to ensure centering during scaling
	var pop_up_container = CenterContainer.new()
	add_child(pop_up_container) # Add to the scene tree first

	# 2. Create the actual points Label
	var points_label = Label.new()
	pop_up_container.add_child(points_label)

	# 3. Get the points based on the target_tile_label's text
	var letter = target_tile_label.text.to_upper() # Ensure uppercase for dictionary lookup
	var points = GlobalData.SCRABBLE_POINTS.get(letter, -1) # Get points, default to -1 if letter not found

	if points == -1:
		# Handle cases where the target_tile_label text isn't a valid Scrabble letter
		# You might want to print an error, or just not show the pop-up.
		print("Warning: '{letter}' is not a valid Scrabble letter for points lookup.")
		pop_up_container.queue_free() # Clean up the container if invalid
		return

	points_label.text = str(points) # Set the number as text

	# 4. Styling the points label
	points_label.add_theme_font_size_override("font_size", 100) # Initial font size
	points_label.add_theme_color_override("font_color", Color.LIGHT_SEA_GREEN) # Bright color for visibility
	points_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	points_label.set_vertical_alignment(VERTICAL_ALIGNMENT_CENTER)
	

	# Make the container transparent and scaled down initially for the fade-in/expand animation
	pop_up_container.modulate = Color(1, 1, 1, 0) # Fully transparent
	pop_up_container.scale = Vector2(0.5, 0.5) # Start very small

	# 5. Crucial: Wait for the layout to be processed to get correct sizes
	await get_tree().process_frame
	await get_tree().process_frame

	# Set pivot offset to the center of the container for scaling
	pop_up_container.set_pivot_offset(pop_up_container.size / 2.0)

	# Position the container's center over the target_tile_label's center
	# target_tile_label.global_position is its top-left corner
	# target_tile_label.size gives its width/height
	var target_center = target_tile_label.global_position + (target_tile_label.size / 2.0)
	pop_up_container.global_position = target_center - (pop_up_container.size / 2.0)
	pop_up_container.position.y -= 100
	pop_up_container.position.x -= 0
	

	

	# 6. Create and run the Tween animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT) # Easing for a bouncy effect
	tween.set_trans(Tween.TRANS_SPRING)

	# Phase 1: Fade in and expand
	tween.tween_property(pop_up_container, "modulate", Color(1, 1, 1, 1), 0.3) # Fade to fully opaque
	tween.tween_property(pop_up_container, "scale", Vector2(1.5, 1.5), 0.3) # Expand significantly
	

	 # Ensure the next phase starts after the first one

	# Phase 2: Quickly fade out and shrink/disappear
	tween.set_parallel() # Run position, modulate, and scale in parallel
	tween.chain().tween_property(pop_up_container, "modulate", Color(1, 1, 1, 0), 0.5) # Fade out
	tween.tween_property(pop_up_container, "scale", Vector2(0.0, 0.0), 0.5) # Shrink to nothing
	
	# Optional: Make it float upwards slightly as it fades
	tween.tween_property(pop_up_container, "global_position", pop_up_container.global_position - Vector2(0, 50), 0.5)

	# 7. Clean up the label after the animation finishes
	await tween.finished	
	pop_up_container.queue_free()

# --- Example Usage (place this in a script where you have a target Label) ---
# Assuming you have a Label node named "LetterTile" in your scene
# and its text is something like "A", "B", "Q", etc.

# func _ready():
#     # This is just for demonstration purposes.
#     # In a real game, you'd call create_points_pop_up
#     # when a letter tile is placed, clicked, or its score needs to be shown.
#     await get_tree().create_timer(1.0).timeout # Wait a bit before demo
#     var my_letter_tile = get_node("Path/To/Your/LetterTileLabel") # Replace with actual path
#     if my_letter_tile:
#         create_points_pop_up(my_letter_tile)
#     else:
#         print("Error: Could not find LetterTileLabel in the scene.")


func screen_shaker():
	# An array of all the parent nodes you want to shake.
	# This makes it easy to manage what gets affected.
	
	var nodes_to_shake = [
	$Control,  # Container for found words grids
	$Control2, # Container for the current letters display
	$Control3, # Container for the timer
	get_node("CScrambleHgrid"), # The grid with the letter buttons
	$CenterContainer, # Mini-score display
	$CenterContainer2]# Main score display
		# You can also add the dynamically created buttons if you want them to shake individually
		# For example, you could pass the submit/shuffle/clear buttons to this array.
	
	
	var shakeables = get_tree().get_nodes_in_group("shakeable")
	
	nodes_to_shake.append_array(shakeables)	
	
	if game_started == true:
		var tween = create_tween()
		#tween.set_parallel(true) # Allow all animations to run at the same time

		var shake_intensity = 20
		var shake_duration = 0.03

		for node in nodes_to_shake:
			if is_instance_valid(node): # Good practice to check if node exists
				print(node)
				print(node.position)
				var original_position = node.position
				# Chain multiple small, rapid movements together for a shake effect
				tween.chain().tween_property(node, "position", original_position + Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity)), shake_duration)
				tween.parallel().tween_property(node, "position", original_position + Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity)), shake_duration)
				tween.parallel().tween_property(node, "position", original_position + Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity)), shake_duration)
				tween.chain().tween_property(node, "position", original_position, shake_duration) # Return to original position
			
func show_success_animation():
	# 1. Create the Label and its container
	var success_container = PanelContainer.new()
	var success_label = Label.new()
	var viewport_size = get_viewport_rect().size

	success_container.self_modulate = Color.TRANSPARENT # Make panel background invisible
	success_label.text = "BIG BOSS"
	success_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	success_label.set_vertical_alignment(VERTICAL_ALIGNMENT_CENTER)

	# 2. Style the Label
	success_label.add_theme_font_size_override("font_size", 150)
	success_label.add_theme_color_override("font_color", Color.GOLD)
	# Optional: Add an outline for better visibility
	var outline_style = StyleBoxFlat.new()
	outline_style.set("outline_color", Color.BLACK)
	outline_style.set("outline_size", 10)
	outline_style.set("bg_color", Color.TRANSPARENT)
	success_label.add_theme_stylebox_override("normal", outline_style)

	# 3. Add to the scene and position
	add_child(success_container)
	success_container.add_child(success_label)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	# Center the container
	success_container.set_pivot_offset(success_container.size / 2.0)
	await get_tree().process_frame
	success_container.position.x = viewport_size.x/2
	success_container.position.x -= success_container.size.x/2
	success_container.position.y += 300
	await get_tree().process_frame # Wait a frame for size to be calculated
	print(success_container.position.x)


	# 4. Create and run the animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC) # A bouncy, celebratory transition

	# Start small and transparent
	success_container.scale = Vector2(0.1, 0.1)
	success_container.modulate.a = 0.0

	# Animate properties
	tween.parallel().tween_property(success_container, "scale", Vector2(1.2, 1.2), 0.8)
	tween.parallel().tween_property(success_container, "modulate:a", 1.0, 0.5) # Fade in quickly

	# Chain the fade out animation
	tween.chain().tween_interval(1.0) # Hold the "SUCCESS" message on screen
	tween.chain().tween_property(success_container, "modulate:a", 0.0, 0.5) # Fade out

	# 5. Clean up the node after animation finishes
	await tween.finished
	success_container.queue_free()


#func obscurity_collector(word):
	#print("collector run")
	##print("obscurity =" + str(GlobalData.obscurity_dictionary[word]))
	#if word in GlobalData.obscurity_dictionary:
		#return int((GlobalData.obscurity_dictionary[word]))
	#else:
		#return 0
	#pass
	#
## This function creates a temporary label that animates and then deletes itself.
#func show_obscurity_popup(obscurity: int):
	## 1. Create and style the Label
	#var label = Label.new()
	#label.text = "Obscurity = %s/10" % obscurity
	#label.add_theme_font_size_override("font_size", 80)
	#label.add_theme_color_override("font_color", Color.BLACK)
	## Optional: Add an outline for better visibility
	##var outline = LabelSettings.new()
	##outline.outline_size = 5
	##outline.outline_color = Color.BLACK
	##label.label_settings = outline
	#
	## 2. Add to scene and wait one frame for its size to be calculated
	#add_child(label)
	#await get_tree().process_frame
	#
	#
	## 3. Calculate start and end positions
	#var screen_size = get_viewport_rect().size
	#var label_size = label.size
	#
	#var start_pos = screen_size/2 - label.size/2 
	#var end_pos = Vector2((screen_size.x - label_size.x) / 2, screen_size.y * 0.2)
	#
	## 4. Set initial state (invisible and at the start position)
	#label.global_position = start_pos
	#label.modulate.a = 0.0
	#
	## 5. Create and run animations
	## This tween handles the movement over 1 second
	#var move_tween = create_tween()
	#move_tween.tween_property(label, "global_position", end_pos, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	#
	## This tween handles the fade-in and fade-out sequence
	#var fade_tween = create_tween()
	#fade_tween.tween_property(label, "modulate:a", 1.0, 0.3) # Fade in over 0.3s
	#fade_tween.tween_property(label, "modulate:a", 0.0, 2) # Fade out over the remaining 0.7s
	#
	## 6. Clean up the label after the animation is done
	#await fade_tween.finished
	#label.queue_free()
