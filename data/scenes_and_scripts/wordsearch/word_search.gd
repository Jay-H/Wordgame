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
var _drag_direction: Vector2i = Vector2i.ZERO

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
@export var wrong_label_duration: float = 1.0 # How long the label stays visible
@export var wrong_label_move_distance: float = 20.0 # How far it moves left/right

# Correct Label Animation Properties
@export_group("Correct Label Animation")
@export var correct_label_duration: float = 0.8 # Total time for grow and fade
@export var correct_label_initial_scale: Vector2 = Vector2(0.5, 0.5) # Start small
@export var correct_label_final_scale: Vector2 = Vector2(2.0, 2.0) # Grow larger
@export var correct_label_initial_alpha: float = 1.0 # Start invisible

@export var found_word_animation: CellAnimationResource

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and !event.is_pressed():
		if is_dragging: # Only process if a drag was active
			is_dragging = false
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
	# Reset drag direction at the start of a new drag
	_drag_direction = Vector2i.ZERO 
	# When a new drag starts, clear the previous selection path.
	# Cells that were part of a found word (green) will remain green
	# due to LetterCell's `is_found` logic.
	for existing_cell in selection_path:
		existing_cell.unhighlight() # This will revert if not found, or stay green if found.
			
	selection_path.clear()
	
	# Start the new selection
	selection_path.append(cell)
	cell.highlight(Globals.CELL_HIGHLIGHT_COLOR)
	#Input.vibrate_handheld(30)

func _on_cell_mouse_entered(cell: LetterCell) -> void:
	if not is_dragging or cell in selection_path:
		return

	var last_cell: LetterCell = selection_path.back()
	var current_segment_direction: Vector2i = cell.grid_position - last_cell.grid_position
	
	# Ensure adjacency (already existing logic)
	if abs(current_segment_direction.x) > 1 or abs(current_segment_direction.y) > 1:
		return # Not adjacent, ignore

	# Check for straight line or diagonal (abs(x)==abs(y) for diagonal, x==0 or y==0 for straight)
	var is_straight_or_diagonal = (current_segment_direction.x == 0 or current_segment_direction.y == 0) or \
								  (abs(current_segment_direction.x) == abs(current_segment_direction.y))
	
	if not is_straight_or_diagonal:
		return # Not a straight or diagonal move, ignore
	
	# Determine or enforce the drag direction
	if selection_path.size() == 1:
		# This is the second cell, so establish the drag direction
		_drag_direction = current_segment_direction
	else:
		# For subsequent cells, ensure they continue in the established direction
		if current_segment_direction != _drag_direction:
			return # Direction changed, ignore
		
	# If all checks pass, append the cell
	selection_path.append(cell)
	cell.highlight(Globals.CELL_HIGHLIGHT_COLOR)
	Input.vibrate_handheld(50)

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
	var original_pos = wrong_label.position
	
	var tween = create_tween()
	tween.set_parallel(false) # Make these animations sequential
	
	Input.vibrate_handheld(100)
	Input.vibrate_handheld(100)
	Input.vibrate_handheld(100)
	
	# Move right
	tween.tween_property(wrong_label, "position:x", original_pos.x + wrong_label_move_distance, 0.1)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_SINE)
	# Move left
	tween.tween_property(wrong_label, "position:x", original_pos.x - wrong_label_move_distance, 0.1)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_SINE)
	# Move right
	tween.tween_property(wrong_label, "position:x", original_pos.x + wrong_label_move_distance, 0.1)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_SINE)
	# Move left
	tween.tween_property(wrong_label, "position:x", original_pos.x - wrong_label_move_distance, 0.1)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_SINE)
	# Move back to center
	tween.tween_property(wrong_label, "position:x", original_pos.x, 0.1)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_SINE)
		
	# Wait for a bit, then hide
	tween.tween_interval(wrong_label_duration - (0.1*7)) # Subtract animation time
	tween.tween_callback(func(): wrong_label.visible = false)

func _animate_correct_label() -> void:
	correct_label.visible = true
	
	#So that it grows from the center-top of the label, and not the default top-left
	correct_label.pivot_offset = correct_label.size / 2.0
	
	correct_label.scale = correct_label_initial_scale
	var current_modulate = correct_label.modulate # Get the label's current modulate (color)
	current_modulate.a = 1.0 # Set alpha to fully opaque
	correct_label.modulate = current_modulate
	
	Input.vibrate_handheld(300)
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
	Input.vibrate_handheld(100)
	Input.vibrate_handheld(100)
	Input.vibrate_handheld(100)
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
