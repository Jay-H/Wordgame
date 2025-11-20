extends Control

var brown_tower_art_array = ["res://data/images/babel_pieces/1.png", "res://data/images/babel_pieces/2.png", "res://data/images/babel_pieces/3.png",
"res://data/images/babel_pieces/4.png", "res://data/images/babel_pieces/5.png", "res://data/images/babel_pieces/6.png"
	
]
var IP_ADDRESS = "localhost"
var PORT = 7777
var my_client_id
var letter_is_held = false
var currently_pressed_letter_index = -1
var division_fading_in = false
var division_fading_out = false
var division_fully_shown = false
var division_fully_hidden = true
var max_letters_in_tower = 8
var letter_node_dictionary = {}
var which_letter_node_held
var current_touch_position
var letter_node_tween_dictionary = {}
var left_tower_string : String = ""
var middle_tower_string : String = ""
var right_tower_string : String = ""
var topsy = true
var turvy = false


func _debug_initializer():
	await get_tree().create_timer(1).timeout
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(IP_ADDRESS, PORT)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		my_client_id = multiplayer.get_unique_id()
		print(my_client_id)
		await get_tree().create_timer(0.5).timeout
		print("we here")
		rpc_id(1,"_debug_get_user_peer_id", my_client_id)
	else:
		print(error)

@rpc("authority")
func _debug_get_user_peer_id(id):
	pass
	
func _process(_delta):
	
	if letter_is_held:
		if current_touch_position != null:
			which_letter_node_held.position = current_touch_position - which_letter_node_held.size/2
		_division_shower()
	if not letter_is_held:
		_division_hider()
	pass

func _division_shower():
	if division_fully_hidden:
		if division_fading_in == false:
			division_fading_in = true
			division_fully_hidden = false
			var tween = create_tween()
			tween.tween_property(%Division, "modulate", Color.WHITE, 0.25)
			await tween.finished
			division_fading_in = false
			division_fully_shown = true
		
func _division_hider():
	if division_fully_shown:
		if division_fading_out == false:
			division_fully_shown = false
			division_fading_out = true
			var tween = create_tween()
			tween.tween_property(%Division, "modulate", Color.TRANSPARENT, 0.5)
			await tween.finished
			division_fading_out = false
			division_fully_hidden = true
	pass
func _placeholder_remover():
	%Division.modulate = Color.TRANSPARENT
	%PrototypeFallingLetter.visible = false
	for i in %LeftTower.get_children():
		i.queue_free()
	for i in %MiddleTower.get_children():
		i.queue_free()
	for i in %RightTower.get_children():
		i.queue_free()

func _ready():
	
	_debug_initializer()
	_placeholder_remover()
	
func _input(event: InputEvent):

	if event is InputEventScreenDrag:
		current_touch_position = event.position
	if event is InputEventScreenTouch:
		current_touch_position = event.position

@rpc("authority")
func _random_letter_node_creator(letter_information_array):
	var percentage_position = letter_information_array[4]
	var font_size = letter_information_array[1]
	var time_to_fall = letter_information_array[2]
	var current_letter_index = letter_information_array[3]
	var letter_node = %PrototypeFallingLetter.duplicate()
	var letter_button = letter_node.get_node("Button")
	var spawn_span = %FallingLettersControl.size.x - 250
	var distance_to_fall = 0.5 * %FallingLettersControl.size.y
	letter_node.text = letter_information_array[0]
	letter_node.set_meta("letter_index", current_letter_index)
	letter_button.button_down.connect(_letter_pressed.bind(letter_node))
	letter_button.button_up.connect(_letter_unpressed.bind(letter_node))
	letter_node.visible = true
	letter_node.add_theme_font_size_override("font_size", font_size)
	letter_node.position.x = spawn_span * percentage_position
	letter_node.position.y = 0 - (letter_node.size.y + 50)
	letter_node_dictionary[current_letter_index] = letter_node
	%FallingLettersControl.add_child(letter_node)
	var motion_tween = create_tween()
	var transparency_tween = create_tween()
	letter_node_tween_dictionary[letter_node] = [motion_tween, transparency_tween]
	motion_tween.tween_property(letter_node, "position:y", distance_to_fall, time_to_fall)
	transparency_tween.tween_property(letter_node, "modulate", Color.WHITE, time_to_fall - 2)
	transparency_tween.chain().tween_property(letter_node, "modulate", Color.TRANSPARENT, 2)
	await motion_tween.finished
	if letter_node != null:
		letter_node.queue_free()
	
func _letter_pressed(letter_node):
	var letter_index = letter_node.get_meta("letter_index")
	currently_pressed_letter_index = letter_index
	for i in letter_node_tween_dictionary[letter_node]:
		i.kill()
	which_letter_node_held = letter_node
	letter_is_held = true
	rpc_id(1, "_inform_server_letter_pressed", letter_index)
	pass
	
func _letter_unpressed(letter_node):
	currently_pressed_letter_index = -1
	letter_is_held = false
	letter_node.add_theme_font_size_override("font_size", 200)
	letter_node.modulate = Color.WHITE
	var duplicate_letter = letter_node.duplicate()
	if letter_node.position.x < %FallingLettersControl.size.x/3:
		%LeftTower.add_child(duplicate_letter)
		if topsy == true:
			move_child(duplicate_letter, 0)
			var quick_string = ""
			for i in %LeftTower.get_children():
				quick_string += i.text
			left_tower_string = quick_string
			print(left_tower_string)
	elif letter_node.position.x > %FallingLettersControl.size.x/3 and letter_node.position.x < (%FallingLettersControl.size.x/3) * 2:
		%MiddleTower.add_child(duplicate_letter)
		if topsy == true:
			move_child(duplicate_letter, 0)
			var quick_string = ""
			for i in %MiddleTower.get_children():
				quick_string += i.text
			middle_tower_string = quick_string
			print(middle_tower_string)
	else:
		%RightTower.add_child(duplicate_letter)
		if topsy == true:
			move_child(duplicate_letter, 0)
			var quick_string = ""
			for i in %RightTower.get_children():
				quick_string += i.text
			right_tower_string = quick_string
			print(right_tower_string)
	letter_node.queue_free()
	pass
@rpc("authority")
func _inform_server_letter_pressed(letter_index):
	pass

@rpc("authority")
func _inform_clients_letter_pressed(letter_index):
	if currently_pressed_letter_index == letter_index: #if you are the one who pressed the letter, no animation shown
		return
	else:
		var letter_node_to_destroy = letter_node_dictionary[letter_index]
		var letter_node_button = letter_node_to_destroy.get_node("Button")
		letter_node_button.disabled = true
		letter_node_to_destroy.pivot_offset = letter_node_to_destroy.size/2
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(letter_node_to_destroy, "scale", Vector2(0.25,0.25), 0.25).set_trans(Tween.TRANS_SINE)
		tween.chain().tween_property(letter_node_to_destroy, "scale", Vector2(2,2), 0.5).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(letter_node_to_destroy, "modulate", Color.TRANSPARENT, 0.5).set_trans(Tween.TRANS_SINE)
		await tween.finished
		letter_node_to_destroy.queue_free()
		pass
	pass

func _on_left_submit_pressed() -> void:
	if left_tower_string.length() < 3:
		print("too short")
		return
	rpc_id(1, "_submit_word", left_tower_string)
	pass # Replace with function body.


func _on_middle_submit_pressed() -> void:
	if middle_tower_string.length() < 3:
		print("too short")
		return
	rpc_id(1, "_submit_word", middle_tower_string)
	pass # Replace with function body.


func _on_right_submit_pressed() -> void:
	if right_tower_string.length() < 3:
		print("too short")
		return
	rpc_id(1, "_submit_word", right_tower_string)
	pass # Replace with function body.

@rpc("authority")
func _submit_word(word):
	pass

@rpc("authority")
func _valid_word_informer(word):
	if word == left_tower_string:
		_tower_finished("left")
	elif word == middle_tower_string:
		_tower_finished("middle")
	elif word == right_tower_string:
		_tower_finished("right")
	pass
	
@rpc("authority")
func _invalid_word_informer(word):
	if word == left_tower_string:
		_tower_crumbles("left")
	elif word == middle_tower_string:
		_tower_crumbles("middle")
	elif word == right_tower_string:
		_tower_crumbles("right")
	pass
	
func _tower_finished(tower):
	print(str(tower) + " tower is finished, glory to Babel")
	var tower_to_finish
	if tower == "left":
		tower_to_finish = %LeftTower
	if tower == "middle":
		tower_to_finish = %MiddleTower
	if tower == "right":
		tower_to_finish = %RightTower
	for i in tower_to_finish.get_children():
		var art = brown_tower_art_array[randi_range(0, brown_tower_art_array.size()-1)]
		var texture_rect = TextureRect.new()
		texture_rect.size = i.size
		i.add_child(texture_rect)
		texture_rect.texture = load(art)

	pass

func _tower_crumbles(tower):
	print(str(tower) + " tower crumbles to the ground, incomprehensible")
	var tower_to_crumble
	if tower == "left":
		tower_to_crumble = %LeftTower
	if tower == "middle":
		tower_to_crumble = %MiddleTower
	if tower == "right":
		tower_to_crumble = %RightTower
	for i in tower_to_crumble.get_children():
		var target_rotation = randi_range(-20, 20)
		var target_y_position = get_viewport_rect().size.y + 300
		var horizontal_movement = randi_range(-100, 100)
		var original_x_position = i.position.x
		var target_x_position = original_x_position + horizontal_movement
		var tween = create_tween()
		var fall_tween = create_tween()
		i.pivot_offset = i.size/2
		tween.parallel().tween_property(i, "rotation", target_rotation, randf_range(2,3))
		tween.parallel().tween_property(i, "position:x", target_x_position, randf_range(2,3))
		fall_tween.parallel().tween_property(i, "position:y", target_y_position, 3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await get_tree().create_timer(randf_range(0.3,0.6)).timeout
			
	pass
