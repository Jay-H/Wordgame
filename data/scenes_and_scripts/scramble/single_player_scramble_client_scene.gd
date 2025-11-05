extends Control

signal game_over
var little_green_particles = "res://data/scenes_and_scripts/particles/small_green_particles.tscn"
var ranks = ["bad", "okay", "good", "great", "amazing", "unbelievable", "godlike", "universal master"]
var current_rank = ""
var rank_thresholds
var words_to_find = []
var found_words = []
var chosen_letters_string = ""
var chosen_letters_array = []
var selected_letters_array = []
var selected_letters_string = ""
var slot_dictionary = {}
var array_of_slots = []
var game_timer_node
var score : int
var mini_score : int
#variants
var show_words_to_find = true
var seven_letter_word_guaranteed = false
var score_matters = true
var time_limit = false
var time_limit_duration = 3
#end variants

func _setup(parameters):
	seven_letter_word_guaranteed = parameters[1]
	time_limit = parameters[2]
	show_words_to_find = parameters[3]
	score_matters = parameters[4]
	time_limit_duration = parameters[5]
	if not score_matters:
		%MiniScore.visible = false
	if not time_limit:
		%GameTimerLabel.visible = false
	if show_words_to_find:
		%WordsLeft.visible = false
	else:
		%WordsLeft.visible = true


func _ready():
	_clear_word_boxes() # take away the placeholder text
	_find_good_letters()
	_populate_word_list()
	_populate_letters()
	_connect_letter_signals()
	if time_limit:
		game_timer_node = Timer.new()
		game_timer_node.one_shot = true
		game_timer_node.timeout.connect(_game_over)
		game_timer_node.autostart = false
		add_child(game_timer_node)
		game_timer_node.start(time_limit_duration)
	print(_current_rank_determiner())
	pass
	
func _process(_delta):
	%CurrentWord.text = selected_letters_string
	if time_limit:
		%GameTimerLabel.text = str(int(game_timer_node.time_left))
	else: 
		%GameTimerLabel.text = ""
	if score_matters:
		%GameScore.text = "Score = " + str(score)
		%MiniScore.text = str(mini_score)
	else:
		%GameScore.text = ""
	if not show_words_to_find:
		%WordsLeft.text = "Words Found: " + str(int((found_words).size())) + "/" + str(int((words_to_find).size())) + "\n" + str(current_rank)
	pass

func _random_letter_generator():
	if seven_letter_word_guaranteed:
		var letters = GlobalData.seven_letter_words_list[randi_range(0, GlobalData.seven_letter_words_list.size() - 1)]
		return letters
	var letters = []
	for i in range(7):
		letters.append(GlobalData.alphabet[randi_range(0,25)])
	return letters

func _find_words_from_letters(letters_array):
	var letters_string = ""
	for i in letters_array:
		letters_string += str(i)
	var words = GlobalData.find_valid_words_from_letters(letters_string)
	return [words,letters_string,letters_array]
	pass

func _find_good_letters():
	var max_attempts = 2000
	var minimum_words = 35
	var maximum_words = 50
	var current_attempt = 0
	var chosen_letters
	var success = false
	var array
	while success == false:
		if current_attempt < max_attempts:
			print(current_attempt)
			current_attempt += 1
			array = _find_words_from_letters(_random_letter_generator())
			if array[0].size() < minimum_words:
				pass
			if array[0].size() >= minimum_words and array[0].size() <= maximum_words:
				success = true
	if success == true:
		words_to_find = array[0]
		chosen_letters_string = array[1]
		chosen_letters_array = array[2]
		return
	
	pass

func _populate_word_list():
	if show_words_to_find:
		var word_to_find_unpacked_array = Array(words_to_find)
		word_to_find_unpacked_array.sort_custom(_sort_words)
		print(word_to_find_unpacked_array)
		var number_of_words_to_find = words_to_find.size()
		for a in %HBoxContainer.get_children():
			for b in a.get_children():
				array_of_slots.append(b)
		for i in number_of_words_to_find:
			
			var word = word_to_find_unpacked_array[i]
			var slot = array_of_slots[i]
			var length = word.length()
			var unfound_word_string = ""
			for x in length:
				unfound_word_string += "[]"
			slot.text = unfound_word_string
			for b in 8 - length:
				slot.text += " "
			slot_dictionary[word] = slot
			slot.modulate.a = 0.5
	else:
		var number_of_words_to_find = words_to_find.size()
		for a in %HBoxContainer.get_children():
			for b in a.get_children():
				array_of_slots.append(b)
	pass

func _sort_words(a,b):
	if a.length() < b.length():
		return true
	return false
	pass


func _populate_letters():
	for i in range(7):
		%LetterContainer.get_child(i).text = chosen_letters_array[i]
	_on_shuffle_pressed()
	_on_shuffle_pressed()	
	_on_shuffle_pressed()
	
func _connect_letter_signals():
	for i in %LetterContainer.get_children():
		i.pressed.connect(_letter_collector)
		pass
		
func _letter_collector(letter_text, letter_node, changed):
	Haptics.stacatto_singleton_longer()
	%PianoController.play_random_note()
	if score_matters:
		_little_green_letters(letter_text, letter_node)
	selected_letters_array.append(letter_text)
	selected_letters_string += letter_text
	letter_node.mouse_filter = MOUSE_FILTER_IGNORE
	letter_node.add_theme_color_override("font_color", Color.DIM_GRAY)
	mini_score += GlobalData.SCRABBLE_POINTS[letter_text]


func _on_shuffle_pressed() -> void:
	Haptics.pitter_patter_light()
	for i in %LetterContainer.get_children():
		%LetterContainer.move_child(i,randi_range(0,6))
	pass # Replace with function body.


func _on_clear_pressed() -> void:
	Haptics.stacatto_doublet()
	for i in %LetterContainer.get_children():
		i.mouse_filter = MOUSE_FILTER_STOP
		i.add_theme_color_override("font_color", Color.BLACK)
		selected_letters_array = []
		selected_letters_string = ""
		mini_score = 0
	pass # Replace with function body.
	

func _on_submit_pressed() -> void:
	Haptics.pitter_patter_light()
	var word_score : int = 0
	if selected_letters_array.size() <3:
		Haptics.hard_half_second()
		_too_short_word_shaker()
	
	if GlobalData.is_valid_word(selected_letters_string):
		Haptics.pitter_patter_heavy()
		for i in selected_letters_array:
			word_score += GlobalData.SCRABBLE_POINTS[i]
		found_words.append(selected_letters_string)
		_found_word_revealer(selected_letters_string)
		_on_clear_pressed()
		score += word_score
		_current_rank_determiner()
			
	else:
		_wrong_word_display()
		_on_clear_pressed()



func _too_short_word_shaker():
	print("shake")
	pass

func _wrong_word_display():
	print("invalid")
	pass

func _found_word_revealer(word):
	if show_words_to_find:
		var found_word_node = slot_dictionary[word]
		found_word_node.text = word
		found_word_node.modulate.a = 1.0
		found_word_node.add_theme_color_override("font_color", Color.WEB_GREEN)
	else:
		var slot = array_of_slots[found_words.size() -1 ]
		slot.text = str(word)
		
	pass

func _game_over():
	var tween = create_tween()
	tween.tween_property(%CanvasModulate, "color", Color.TRANSPARENT, 1)
	await tween.finished
	game_over.emit(self)
	
	pass


func _on_back_to_menu_pressed() -> void:
	_game_over()
	pass # Replace with function body.

func _current_rank_determiner():
	if rank_thresholds == null:
		current_rank = ranks[0]
		var denominator : float = words_to_find.size()
		var numerator  : float = found_words.size()
		var threshold_decimal : float  = 1.0/ranks.size()
		print(threshold_decimal)
		var threshold_array = []
		var counter : float  = 0
		for i in (ranks.size()):
			threshold_array.append(threshold_decimal + counter)
			counter += threshold_decimal
		rank_thresholds = threshold_array
	else:
		var denominator : float = words_to_find.size()
		var numerator  : float = found_words.size()	
		var fraction: float = numerator/denominator
		print(fraction)
		print(rank_thresholds)
		var thresholds_reached = 0
		for i in rank_thresholds:
			if fraction >= i:
				thresholds_reached += 1
		current_rank = ranks[thresholds_reached]
	
func _clear_word_boxes():
	for i in %HBoxContainer.get_children():
		for x in i.get_children():
			x.text = ""
func _little_green_letters(letter_text, letter_node):
	var points = GlobalData.SCRABBLE_POINTS[letter_text]
	var little_green_letter_node = Label.new()
	little_green_letter_node.add_theme_font_size_override("font_size", 100)
	little_green_letter_node.add_theme_color_override("font_color", Color.GREEN)
	little_green_letter_node.text = str(points)
	letter_node.add_child(little_green_letter_node)
	var particles = load(little_green_particles).instantiate()
	particles.position += little_green_letter_node.size/2
	little_green_letter_node.add_child(particles)
	little_green_letter_node.position += letter_node.size/2
	little_green_letter_node.position -= little_green_letter_node.size/2
	var target_position = Vector2(little_green_letter_node.position.x, -1000)
	var tween = create_tween()
	var random_additional_vector2 = Vector2(randi_range(-300, 300), 0)
	
	tween.tween_property(little_green_letter_node, "position", target_position + random_additional_vector2, 2)
	tween.parallel().tween_property(little_green_letter_node, "modulate", Color.TRANSPARENT, 1)
	await tween.finished
	little_green_letter_node.queue_free()
	pass
