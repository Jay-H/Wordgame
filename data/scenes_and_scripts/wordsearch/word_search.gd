extends Control


@export var letter_cell_scene: PackedScene
@onready var pregame_timer_node = get_node("/root/MainMenu/PregameTimer")
# --- Word Selection ---
@onready var grid_container: GridContainer = %GridContainer
@onready var words_list_container: HBoxContainer = %Words
@onready var shared_list: VBoxContainer = %SharedWords
@onready var words_list_p1: VBoxContainer = %Words_P1
@onready var words_list_p2: VBoxContainer = %Words_P2
@onready var wrong_label: Label = %WrongLabel
@onready var correct_label: Label = %CorrectLabel
@onready var win_label: Label = %WinLabel
@onready var lose_label: Label = %LoseLabel
@onready var game_timer: Control = %GameTimer

var grid_cells: Array = [] # This will be our 2D array of LetterCell nodes.
var is_dragging: bool = false
var current_locked_direction: Vector2i = Vector2i.ZERO
var start_cell: LetterCell = null

var selection_path: Array[LetterCell] = [] # The current chain of selected cells.

var _information_from_server: Variant = {}
var enet_peer: ENetMultiplayerPeer
var play_count = 0
var big_dictionary = {"game_type": "wordsearch"}

# the references to each player's word list in DEFAULT variant
var words_labels: Dictionary = {}

# the variant that the server has chosen
var variant

#TODO: temporary until we have a real setup
var sounds_to_play = [
	preload("res://data/sounds/WS_temp_1.mp3"),
	preload("res://data/sounds/WS_temp_2.mp3"),
	preload("res://data/sounds/WS_temp_3.mp3"),
	preload("res://data/sounds/WS_temp_4.mp3"),
	preload("res://data/sounds/WS_temp_5.mp3"),
	]
var wrong_sound = preload("res://data/sounds/WS_temp_wrong.mp3")
var opponent_found_sound = preload("res://data/sounds/WS_temp_opponent_found.mp3")

@onready var sound_player: AudioStreamPlayer2D = %SoundPlayer

# --- Animation Properties ---
@export_group("Grid Spawn Animation")
@export var animate_spawn: bool = true
@export var spawn_anim_duration: float = 2 # Duration of each cell's animation
@export var spawn_anim_max_delay: float = 0.2 # Max random delay for a cell
@export var spawn_initial_modulate_alpha: float = 0.0 # Start fully transparent (0.0 means transparent)

# Wrong Label Animation Properties
@export_group("Wrong Label Animation")
@export var wrong_label_duration: float = 1.0 # Total time for grow and fade
@export var wrong_label_initial_scale: Vector2 = Vector2(0.5, 0.5) # Start small
@export var wrong_label_final_scale: Vector2 = Vector2(2.5, 2.5) # Grow larger
@export var wrong_label_initial_alpha: float = 1.0 # Start invisible

# Correct Label Animation Properties
@export_group("Correct Label Animation")
@export var correct_label_duration: float = 1.0 # Total time for grow and fade
@export var correct_label_initial_scale: Vector2 = Vector2(0.5, 0.5) # Start small
@export var correct_label_final_scale: Vector2 = Vector2(2.5, 2.5) # Grow larger
@export var correct_label_initial_alpha: float = 1.0 # Start invisible

@export var found_word_animation: CellAnimationResource

var ws_test_words = []

func _process(delta):
	if pregame_timer_node != null:
		%PreTimerLabel.text = str(int(pregame_timer_node.time_left))

func _ready() -> void:
	wrong_label.visible = false
	wrong_label.add_theme_font_size_override("font_size", Globals.WRONG_LABEL_FONT_SIZE)
	wrong_label.add_theme_color_override("font_color", Globals.WRONG_LABEL_FONT_COLOR)
	
	correct_label.visible = false
	correct_label.add_theme_font_size_override("font_size", Globals.CORRECT_LABEL_FONT_SIZE)
	correct_label.add_theme_color_override("font_color", Globals.CORRECT_LABEL_FONT_COLOR)
	
	win_label.visible = false
	win_label.add_theme_font_size_override("font_size", Globals.WIN_LABEL_FONT_SIZE)
	win_label.add_theme_color_override("font_color", Globals.WIN_LABEL_FONT_COLOR)
	
	lose_label.visible = false
	lose_label.add_theme_font_size_override("font_size", Globals.LOSE_LABEL_FONT_SIZE)
	lose_label.add_theme_color_override("font_color", Globals.LOSE_LABEL_FONT_COLOR)
	
	if not letter_cell_scene:
		push_error("LetterCell scene is not set in the Inspector!")
		return

	game_timer.position.y = 200 # Small offset from top
	game_timer.timeout_reached.connect(_on_game_timer_timeout) # Connect its signal
	
	grid_container.columns = Globals.GRID_SIZE.x
	
	set_process_priority(1) # Ensure this node processes drawing after its children
	queue_redraw() # Request a redraw when the grid is generated/ready
	
	generate_grid_testing()
	generate_grid()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and !event.is_pressed():
		if is_dragging: # Only process if a drag was active
			is_dragging = false
			start_cell = null
			if Globals.WSTEST:
				print("TESTINGGGGG")
				process_selection_test()
			else:
				process_selection()
			get_viewport().set_input_as_handled()
			return # Event handled, stop processing

func generate_grid() -> void:
	# Clear previous grid and data
	for child in grid_container.get_children():
		child.queue_free()
	
	# Populate the grid with LetterCell instances
	for y in range(Globals.GRID_SIZE.y):
		for x in range(Globals.GRID_SIZE.x):
			var cell = letter_cell_scene.instantiate()
			
			# Add the cell to the scene tree FIRST. This makes its @onready vars available.
			grid_container.add_child(cell)
			
			cell.set_letter(grid_cells[y][x])

			# Now we can safely configure the cell.
			cell.grid_position = Vector2i(x, y)

			# Connect to the cell's signals
			cell.label.drag_started.connect(_on_cell_drag_started)
			cell.label.mouse_entered_cell.connect(_on_cell_mouse_entered)
			
			# Always apply animation
			if animate_spawn:
				var initial_color = cell.modulate
				initial_color.a = spawn_initial_modulate_alpha
				cell.modulate = initial_color
				_animate_cell_spawn(cell, x, y)
	
	# Request a redraw after the grid is generated, in case dimensions change
	queue_redraw()

	if game_timer:
		game_timer.start_timer(Globals.GAME_DURATION_SECONDS)

# --- Animation Function ---
func _animate_cell_spawn(cell: LetterCell, x: int, y: int) -> void:
	var tween = create_tween()
	tween.set_parallel(true) # Allow properties to animate simultaneously
	
	# Add a random delay for a more natural fall effect
	var delay = randf_range(0.0, spawn_anim_max_delay)
	
	# You can add a more structured delay here if you want cells to animate
	# row by row, or column by column, etc. For now, it's just random.
	# Example: delay = (x * 0.05) + (y * 0.03) + randf_range(0, 0.1)

	# Animate scale
	tween.tween_property(cell, "scale", Vector2(1.0, 1.0), spawn_anim_duration)\
		.set_delay(delay)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BACK) # TRANS_BACK makes it overshoot slightly for a bouncy feel

	# Animate modulate (fade in)
	var final_modulate = cell.modulate # Get current modulate (which might have been set to a transparent value)
	final_modulate.a = 1.0 # Set final alpha to opaque
	tween.tween_property(cell, "modulate", final_modulate, spawn_anim_duration)\
		.set_delay(delay)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUAD) # Simple fade

	# Optional: Reset modulate alpha to 1.0 after animation is done if you didn't animate it to 1.0
	# tween.tween_callback(func(): cell.modulate.a = 1.0).set_delay(delay + spawn_anim_duration)
	
func _on_game_timer_timeout() -> void:
	set_process_unhandled_input(false)

# --- Signal Handlers ---

func _on_cell_drag_started(cell: LetterCell) -> void:
	is_dragging = true
	
	# Unhighlight any previous path (in case of a bug)
	unhighlight_current_selection()
	selection_path.clear()

	# Set the new pivot
	start_cell = cell 
	current_locked_direction = Vector2i.ZERO # No direction yet
	
	# Start the new selection
	selection_path.append(cell)
	cell.highlight(Globals.CELL_HIGHLIGHT_COLOR)

func _on_cell_mouse_entered(cell: LetterCell) -> void:
	if not is_dragging or not start_cell or cell == selection_path.back():
		return

	var start_to_hover_vec: Vector2i = cell.grid_position - start_cell.grid_position
	
	if start_to_hover_vec == Vector2i.ZERO:
		# This handles moving off and back to the start cell
		unhighlight_current_selection()
		selection_path = [start_cell]
		start_cell.highlight(Globals.CELL_HIGHLIGHT_COLOR)
		current_locked_direction = Vector2i.ZERO
		return

	var new_direction = get_snapped_direction(start_to_hover_vec)
	
	# had to google this because good LORD
	var line_length = max(abs(start_to_hover_vec.x), abs(start_to_hover_vec.y))

	#if nothing changed, just break out
	if new_direction == current_locked_direction and line_length == selection_path.size() - 1:
		return

	current_locked_direction = new_direction
	
	#remove old path 
	unhighlight_current_selection()
	selection_path.clear()
	
	#build new one
	for i in range(line_length + 1): 
		var step_vector = current_locked_direction * i
		var cell_pos = start_cell.grid_position + step_vector
		
		var cell_on_path = get_cell_from_grid_pos(cell_pos)
		
		if cell_on_path:
			selection_path.append(cell_on_path)
			cell_on_path.highlight(Globals.CELL_HIGHLIGHT_COLOR)
		else:
			#this means we are off the grid, just break and ignore
			break

# --- Selection Logic ---
func process_selection() -> void:
	if selection_path.is_empty():
		return
	
	# tracks how many letters in the selection path are already found
	var cell_found_count = 0

	var selected_word: String = ""
	for cell in selection_path:
		if cell.is_found or cell.is_found_by_opponent:
			cell_found_count += 1
		selected_word += cell.letter
	
	# means that they are submitting an word that's already been found
	if cell_found_count == selected_word.length():
		for cell in selection_path:
			cell.unhighlight()
		return

	var word_result = await RpcAwait.send_rpc(1, _word_received.bind(selected_word, generate_serialized_selection_path_coords(selection_path)))
	
	# just check first if they won
	if word_result == Globals.WordResult.WIN:
		sound_player.stream = sounds_to_play[play_count]
		sound_player.play()
		_animate_correct_label()
		if found_word_animation:
			found_word_animation.apply_animation(selection_path) 
		else:
			push_error("Animation borked, something went wrong")
		
		for cell in selection_path:
			cell.set_found(true)
		if game_timer:
			game_timer.stop_timer() # stop the timer
		set_process_unhandled_input(false) # Disable further input
		win_label.visible = true
			
	elif word_result == Globals.WordResult.RIGHT:
		sound_player.stream = sounds_to_play[play_count]
		sound_player.play()
		play_count = play_count + 1
		var label
		# here we find the label in this clients list and make it green
		if variant == Globals.WordsearchVariants.DEFAULT:
			label = find_label_by_text(words_labels, str(multiplayer.get_unique_id()), selected_word)
		elif variant == Globals.WordsearchVariants.SHARED_BOARD:
			label = find_label_by_text_shared(words_labels, "shared_words", selected_word)
		
		if label:
			print("Found:", label.text)
		
		# error on HIDDEN variant because it's hidden
		if variant != Globals.WordsearchVariants.HIDDEN:
			label.add_theme_color_override("font_color", Color.GREEN)
		################################################################
		
		_animate_correct_label()
		_animate_found_word_pulse(selection_path)
		if found_word_animation:
			found_word_animation.apply_animation(selection_path) 
		else:
			push_error("Animation borked, something went wrong")
		
		for cell in selection_path:
			cell.set_found(true)
			
	# this means they submitted a wrong word
	else:
		sound_player.stream = wrong_sound
		sound_player.play()
		_animate_wrong_label()
		# Iterate through the current selection_path and unhighlight.
		# LetterCell's unhighlight() method handles if it should stay green or go to default.
		for cell in selection_path:
			cell.unhighlight()
		
	selection_path.clear() # Always clear the selection path after processing

# Reset everything
func unhighlight_all_cells() -> void:
	for y in range(Globals.GRID_SIZE.y):
		for x in range(Globals.GRID_SIZE.x):
			var cell = grid_cells[y][x]
			if is_instance_valid(cell):
				cell.set_found(false) # Reset found state
				cell.unhighlight() # Revert to default color
				
func _animate_wrong_label() -> void:
	wrong_label.visible = true
	
	#So that it grows from the center-top of the label, and not the default top-left
	wrong_label.pivot_offset = wrong_label.size / 2.0
	
	wrong_label.scale = wrong_label_initial_scale
	var current_modulate = wrong_label.modulate # Get the label's current modulate (color)
	current_modulate.a = 1.0 # Set alpha to fully opaque
	wrong_label.modulate = current_modulate
	
	Haptics.stacatto_singleton_longer()
	var tween = create_tween()
	tween.set_parallel(true) # Animate scale and alpha simultaneously
	
	# Animate scale: grow from initial to final scale
	tween.tween_property(wrong_label, "scale", wrong_label_final_scale, wrong_label_duration)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUAD)
		
	# Animate modulate alpha: fade out (from 1.0 to 0.0)
	# The target alpha is 0.0. The starting alpha is already set to 1.0 above.
	tween.tween_property(wrong_label, "modulate:a", 0.0, wrong_label_duration)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUAD)
		
	tween.set_parallel(false) # Switch to sequential mode for the following steps
	tween.tween_interval(0.0) # Wait for the parallel animations to complete
	
	tween.tween_callback(func(): wrong_label.visible = false)
	


func _animate_correct_label() -> void:
	correct_label.visible = true
	
	#So that it grows from the center-top of the label, and not the default top-left
	correct_label.pivot_offset = correct_label.size / 2.0
	
	correct_label.scale = correct_label_initial_scale
	var current_modulate = correct_label.modulate # Get the label's current modulate (color)
	current_modulate.a = 1.0 # Set alpha to fully opaque
	correct_label.modulate = current_modulate
	
	Haptics.hard_half_second()
	var tween = create_tween()
	tween.set_parallel(true) # Animate scale and alpha simultaneously
	
	# Animate scale: grow from initial to final scale
	tween.tween_property(correct_label, "scale", correct_label_final_scale, correct_label_duration)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUAD)
		
	# Animate modulate alpha: fade out (from 1.0 to 0.0)
	# The target alpha is 0.0. The starting alpha is already set to 1.0 above.
	tween.tween_property(correct_label, "modulate:a", 0.0, correct_label_duration)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUAD)
		
	tween.set_parallel(false) # Switch to sequential mode for the following steps
	tween.tween_interval(0.0) # Wait for the parallel animations to complete
	
	tween.tween_callback(func(): correct_label.visible = false)

# sets your found word to red IF IT IS NOT GREEN  
@rpc("authority", "call_local")
func set_red_label(word: String, opponent_id: int, selection_path_opponent: Array):
	var label
	Haptics.double_normal_hard()
	if variant == Globals.WordsearchVariants.DEFAULT:
		label = find_label_by_text(words_labels, str(opponent_id), word)
	elif variant == Globals.WordsearchVariants.SHARED_BOARD:
		var cells_to_animate: Array[LetterCell] = []
		for cell_pos in selection_path_opponent:
			var index = cell_pos.y * grid_container.columns + cell_pos.x
			if index >= 0 and index < grid_container.get_child_count():
				var cell = grid_container.get_child(index) as LetterCell
				cell.set_found_by_opponent()
				cells_to_animate.append(cell)
		if found_word_animation:
			found_word_animation.apply_animation(cells_to_animate)
		label = find_label_by_text_shared(words_labels, "shared_words", word)
		sound_player.stream = opponent_found_sound
		sound_player.play()
	
	# label is hidden in HIDDEN variant
	elif variant == Globals.WordsearchVariants.HIDDEN:
		return
	label.add_theme_color_override("font_color", Color.RED)

@rpc("authority", "call_local")
func process_loss():
	lose_label.visible = true
	if game_timer:
		game_timer.stop_timer() # stop the timer
	set_process_unhandled_input(false) # disable further input
	
@rpc("authority", "call_local")
func _word_received():
	pass

@rpc("authority", "call_local")
func start_sudden_death():
	game_timer.time_label.add_theme_color_override("font_color", Color.DARK_RED)
	game_timer.start_timer(Globals.SUDDEN_DEATH_DURATION_SECONDS)

@rpc("authority", "call_local")
func _server_ready(_information_from_server):
	print("Server has generated grid and words...")
	
	# store a local reference to each players words so we can change their colors when found - JUST used for tracking who found what
	words_labels[_information_from_server.players[0]] = []
	words_labels[_information_from_server.players[1]] = []
	
	# only populated if its shared_board variant
	words_labels["shared_words"] = []
	
	variant = _information_from_server.variant
	
	for word in _information_from_server.words:
		# it's called lblP1, but in the shared mode variant, it's just the word with no player association
		var lblP1 = Label.new()
		lblP1.text = word
		lblP1.add_theme_font_size_override("font_size", 70)
		lblP1.add_theme_color_override("font_color", Color.BLACK)
		
		# default is the standard game, make both lists
		if variant == Globals.WordsearchVariants.DEFAULT:
			var lblP2 = lblP1.duplicate()
			
			# in a pair of VBoxes
			words_list_p1.add_child(lblP1)
			words_list_p2.add_child(lblP2)
			
			# to track the references to each label
			words_labels[_information_from_server.players[0]].append(lblP1)
			words_labels[_information_from_server.players[1]].append(lblP2)
			shared_list.hide()

		# this is the mode where it's one shared list
		elif variant == Globals.WordsearchVariants.SHARED_BOARD:
			shared_list.add_child(lblP1)
			words_labels["shared_words"].append(lblP1)
			words_list_container.hide()

		# this variant is the same as DEFAULT, but the words are hidden
		elif variant == Globals.WordsearchVariants.HIDDEN:
			var lblP2 = lblP1.duplicate()
			
			# in a pair of VBoxes
			words_list_p1.add_child(lblP1)
			words_list_p2.add_child(lblP2)
			
			# to track the references to each label
			words_labels[_information_from_server.players[0]].append(lblP1)
			words_labels[_information_from_server.players[1]].append(lblP2)
			shared_list.hide()
			
			# hide the word lists
			words_list_container.hide()
			
	grid_cells = _information_from_server.grid
	generate_grid()
	
func generate_serialized_selection_path_coords(cell_data: Array[LetterCell]):
	var returned_data = []
	for data in cell_data:
		returned_data.append(data.grid_position)
	return returned_data
	
################################### HELPERS ################################

# purely a helper function to find labels in a dict based on text and player id
func find_label_by_text(dict: Dictionary, key: String, word: String) -> Label:
	if dict.has(int(key)):
		for label in dict[int(key)]:
			if label.text == word:
				return label
	return null

# TODO: for some reason, godot is complaining when I use string (SHARED_WORDS) or int (DEFAULT) for dict.has, so made two separate
# for now until i make it better, this is a bit ugly
func find_label_by_text_shared(dict: Dictionary, key: String, word: String) -> Label:
	if dict.has(key):
		for label in dict[key]:
			if label.text == word:
				return label
	return null

func fade_pregame():
	var pregame_node = %ColoredBlocker
	var tween = create_tween()
	tween.tween_property(pregame_node, "modulate", Color.TRANSPARENT, 0.5)

func _initialize(dict):
	pass
	
func fade_out():
	var tween = create_tween()
	tween.tween_property(%CanvasModulate, "color", Color.TRANSPARENT, 1)
	await tween.finished
	pass
	
#needed some massive google help here
func get_snapped_direction(vec: Vector2i) -> Vector2i:
	if vec == Vector2i.ZERO:
		return Vector2i.ZERO

	# first get angle
	var angle = Vector2(vec).angle()
	
	var pi_over_4 = PI / 4.0
	var snapped_angle = round(angle / pi_over_4) * pi_over_4
	
	var snapped_vec_f = Vector2.from_angle(snapped_angle)
	
	# Rround the nubmer to get it to be 0 or 1
	return Vector2i(round(snapped_vec_f.x), round(snapped_vec_f.y))

func get_cell_from_grid_pos(pos: Vector2i) -> LetterCell:
	if pos.x < 0 or pos.x >= Globals.GRID_SIZE.x or pos.y < 0 or pos.y >= Globals.GRID_SIZE.y:
		return null
		
	var index = pos.y * grid_container.columns + pos.x
	
	if index >= 0 and index < grid_container.get_child_count():
		return grid_container.get_child(index) as LetterCell
		
	return null #shouldnt happen

func unhighlight_current_selection():
	for cell in selection_path:
		if is_instance_valid(cell):
			cell.unhighlight()

####### PURELY FOR TESTING #######
func generate_grid_testing() -> void:
	grid_cells.clear()
	ws_test_words.clear()

	# Create the 2D array structure
	grid_cells.resize(Globals.GRID_SIZE.y)
	ws_test_words.resize(Globals.GRID_SIZE.y)
	
	# Populate the grid with words and letters
	for y in range(Globals.GRID_SIZE.y):
		grid_cells[y] = []
		grid_cells[y].resize(Globals.GRID_SIZE.x)
		ws_test_words[y] = []
		ws_test_words[y].resize(Globals.GRID_SIZE.x)
		for x in range(Globals.GRID_SIZE.x):
			ws_test_words[y][x] = false
			grid_cells[y][x] = "X"

	# --- FIRST: Insert words into the grid ---
	insert_words()
	
	# --- SECOND: Populate the remaining cells with random letters and start animation ---
	for y in range(Globals.GRID_SIZE.y):
		for x in range(Globals.GRID_SIZE.x):
			var cell = grid_cells[y][x]
			if not ws_test_words[y][x]: # If this cell is NOT occupied by a word
				cell = "X"

func insert_words() -> void:
	var words_to_place = []
	var placed_count = 0
	
	# The list of words that have been attempted and failed
	var failed_words: Array[String] = []
	
	"""
	 Keep trying until we reach the the word count we need
	 
	 When the length of words allowed are like, above 8, SOMETIMES it fails to place it after 1000 attempts and would
	 just not try another word. So I asked gemini to make another loop that handles adding another word if one fails. it added
	 a touch of complexity but still understandable.
	 I've yet to see this problem occur at words of only 6 or less length, but need to account for it!
	"""
	while placed_count < Globals.GUARANTEED_WORD_COUNT:
		# Step 1: Get a word to place
		var word_to_try: String
		var fake_word = "TRUCK"

		var attempts = 0
		var word_found = false
		while not word_found and attempts < 1000:
			var picked_word = fake_word
			if not failed_words.has(picked_word) and not words_to_place.has(picked_word):
				word_to_try = picked_word.to_upper()
				words_to_place.append(word_to_try) # Add to our list of words for the puzzle
				word_found = true
			attempts += 1
		
		if not word_found:
			print("Could not find a new valid word to try. Exiting.")
			break

		var word_len = word_to_try.length()
		var placed_this_word = false
		
		var placement_attempts = 0
		
		# Step 2: Try to place the word
		while placement_attempts < 1000 and not placed_this_word:
			placement_attempts += 1
			
			# Random starting position
			var start_x = randi_range(0, Globals.GRID_SIZE.x - 1)
			var start_y = randi_range(0, Globals.GRID_SIZE.y - 1)
			var start_pos = Vector2i(start_x, start_y)
			
			# Random direction
			var direction_idx = randi_range(0, Globals.DIRECTIONS.size() - 1)
			var direction = Globals.DIRECTIONS[direction_idx]
			
			var can_place = true
			var cells_to_occupy: Array[Vector2i] = []
			
			for j in range(word_len):
				var current_pos = start_pos + direction * j
				
				if not (current_pos.x >= 0 and current_pos.x < Globals.GRID_SIZE.x and current_pos.y >= 0 and current_pos.y < Globals.GRID_SIZE.y):
					can_place = false
					break
				
				if ws_test_words[current_pos.y][current_pos.x]:
					if grid_cells[current_pos.y][current_pos.x] != word_to_try[j]:
						can_place = false
						break
				
				cells_to_occupy.append(current_pos)
			
			if can_place:
				for j in range(word_len):
					var cell_pos = cells_to_occupy[j]
					grid_cells[cell_pos.y][cell_pos.x] = word_to_try[j]
					ws_test_words[cell_pos.y][cell_pos.x] = true
				
				placed_this_word = true
				placed_count += 1
				print("Successfully placed word: ", word_to_try)
		
		if not placed_this_word:
			# If the word fails to place after 1000 attempts, mark it as failed
			# so we don't try it again, and let the outer loop pick a new one.
			print("Could not place word: ", word_to_try, " after ", placement_attempts, " attempts.")
			failed_words.append(word_to_try)
			# Do not increment placed_count, the outer loop will continue.

	print("Finished placing words. Placed count: ", placed_count, " out of ", Globals.GUARANTEED_WORD_COUNT)

func process_selection_test() -> void:
	if selection_path.is_empty():
		return
	
	# tracks how many letters in the selection path are already found
	var cell_found_count = 0

	var selected_word: String = ""
	for cell in selection_path:
		if cell.is_found or cell.is_found_by_opponent:
			cell_found_count += 1
		selected_word += cell.letter

	if selected_word == "TRUCK":
		sound_player.stream = sounds_to_play[play_count]
		sound_player.play()
		play_count = play_count + 1
		var label
		label = find_label_by_text(words_labels, str(multiplayer.get_unique_id()), selected_word)
		_animate_correct_label()
		_animate_found_word_pulse(selection_path)
		if found_word_animation:
			found_word_animation.apply_animation(selection_path) 
		else:
			push_error("Animation borked, something went wrong")
		
		for cell in selection_path:
			cell.set_found(true)
			
	else:
		sound_player.stream = wrong_sound
		sound_player.play()
		_animate_wrong_label()
		for cell in selection_path:
			cell.unhighlight()
		
	selection_path.clear()

## ✨ Creates a directional pulse spanning the entire screen.
func _animate_found_word_pulse(selection: Array[LetterCell]) -> void:
	if selection.size() < 2:
		return

	var pulse_line = Line2D.new()
	var chungus_layer = get_node("chungus") 
	pulse_line.z_index = 100 
	chungus_layer.add_child(pulse_line) 
	
	var pulse_duration = 1.3
	var viewport_size = get_viewport().size
	# The diagonal length of the viewport, which is the minimum size needed to cover the screen.
	var massive_coverage_dimension = viewport_size.length() 
	# Use a factor of 2x the diagonal to guarantee the line is longer and wider than the screen.
	var line_dimension = massive_coverage_dimension * 20.0
	
	# ------------------ Directional Calculation ------------------
	var start_cell = selection.front()
	var end_cell = selection.back()

	var start_global_center = start_cell.get_global_position() + start_cell.size / 2.0
	var end_global_center = end_cell.get_global_position() + end_cell.size / 2.0
	
	var word_direction = (end_global_center - start_global_center).normalized()
	var wavefront_direction = Vector2(-word_direction.y, word_direction.x).normalized()
	
	# 4. Define the line's two points using the wavefront direction.
	# These points define a line segment that is much longer than the screen's diagonal 
	# and is centered near the found word.
	var point_a = start_global_center + word_direction * line_dimension
	var point_b = start_global_center - word_direction * line_dimension

	# 5. Convert points to the CanvasLayer's local space
	var start_local_pos = pulse_line.to_local(point_a)
	var end_local_pos = pulse_line.to_local(point_b)
	
	# To ensure the pulse travels in the direction of the word, 
	# we set the line points to go from START_of_word direction to END_of_word direction.
	# If the pulse direction is wrong, swap these two lines!
	pulse_line.add_point(end_local_pos)
	pulse_line.add_point(start_local_pos)
	
	# ------------------ SHADER & ANIMATION SETUP ------------------
	
	var pulse_shader = preload("res://data/shaders/pulse_shader.gdshader")
	var material = ShaderMaterial.new()
	material.shader = pulse_shader
	pulse_line.material = material
	material.set_shader_parameter("total_pulse_width", 0.5)
	material.set_shader_parameter("fade_fraction", 1.0)
	
	pulse_line.default_color = Color.WHITE
	pulse_line.width = line_dimension 
	pulse_line.texture_mode = Line2D.LINE_TEXTURE_TILE

	# 1. Animate the Pulse Movement 
	var tween_offset = create_tween()
	tween_offset.play()
	
	tween_offset.tween_method(
		func(value): material.set_shader_parameter("progress", value), 
		0.0,  # Start the pulse entirely off-screen
		2.0,   # End the pulse entirely off-screen
		pulse_duration
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	# 2. Clean up the node
	tween_offset.tween_callback(pulse_line.queue_free)
