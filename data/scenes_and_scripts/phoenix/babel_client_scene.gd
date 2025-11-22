extends Control

var debug_mode = true
var brown_tower_art_array = []
var artisan_art = []
var builder_artisan_art = []
var IP_ADDRESS = "localhost"
var PORT = 7777
var my_client_id
var letter_is_held = false
var currently_pressed_letter_index = -1
var left_tower_crumbled = false
var middle_tower_crumbled = false
var right_tower_crumbled = false
var left_tower_finished = false
var middle_tower_finished = false
var right_tower_finished = false
var number_of_towers_disabled = 0
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
var division_borders = []
var topsy = true
var turvy = true
var last_touched_position

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
	
	

func _art_collector():
	var artisan_path = "res://data/images/textures/scribbles/artisans/"
	var artisan_dir = DirAccess.open("res://data/images/textures/scribbles/artisans/")
	var tower_pieces_path = "res://data/images/babel_pieces/"
	var tower_pieces_dir = DirAccess.open(tower_pieces_path)
	var builder_artisans_path = "res://data/images/babel_pieces/artisan_builders/"
	var builder_artisans_dir = DirAccess.open(builder_artisans_path)
	print(artisan_dir.get_files())
	for i in artisan_dir.get_files():
		if i.contains("import"):
			pass
		else:
			artisan_art.append(artisan_path + str(i))
	for i in tower_pieces_dir.get_files():
		if i.contains("import"):
			pass
		else:
			brown_tower_art_array.append(tower_pieces_path + str(i))
	for i in builder_artisans_dir.get_files():
		if i.contains("import"):
			pass
		else:
			builder_artisan_art.append(builder_artisans_path + str(i))
	
	
func _process(_delta):
	
	if letter_is_held:
		if current_touch_position != null:
			which_letter_node_held.position = current_touch_position - which_letter_node_held.size/2
			last_touched_position = current_touch_position
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
			tween.tween_property(%Division, "modulate:a", 0.25, 0.25)
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
	for i in %BigTowerBox.get_children(true):
		i.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%BigTowerBox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%ArtisanParticles.visible = false
	%MeteorParticles.visible = false
	%SparksParticles.visible = false
	%BrokenTower.visible = false
	%BrokenTower.modulate = Color.TRANSPARENT
	%TowerLetterPlaceholder.visible = false
	
func _ready():
	_art_collector()
	if debug_mode:
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
	currently_pressed_letter_index = -1 # reset this to an otherwise unused letter index
	var initial_position = last_touched_position
	letter_is_held = false
	letter_node.add_theme_font_size_override("font_size", 200)
	letter_node.modulate = Color.WHITE
	#var duplicate_letter = letter_node.duplicate()
	var duplicate_letter = %TowerLetterPlaceholder.duplicate()
	duplicate_letter.get_node("Letter").text = letter_node.text
	duplicate_letter.modulate = Color.TRANSPARENT
	duplicate_letter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	duplicate_letter.visible = true
	if letter_node.position.x < %FallingLettersControl.size.x/3:
		if left_tower_crumbled:
			_tried_to_use_disabled_tower(letter_node, %LeftTower)
			return
		if left_tower_finished:
			_tried_to_use_finished_tower(letter_node, %LeftTower)
			return
		%LeftTower.add_child(duplicate_letter)
		if turvy == true:
			%LeftTower.move_child(duplicate_letter, 0)
		call_deferred("_letter_dropper", duplicate_letter, %LeftTower)
		var quick_string = ""
		for i in %LeftTower.get_children():
			quick_string += i.get_node("Letter").text
		left_tower_string = quick_string
		print(left_tower_string)
			
		if %LeftTower.get_children().size() > 8:
			_tower_crumbles("left")
	elif letter_node.position.x > %FallingLettersControl.size.x/3 and letter_node.position.x < (%FallingLettersControl.size.x/3) * 2:
		if middle_tower_crumbled:
			_tried_to_use_disabled_tower(letter_node, %MiddleTower)
			return
		if middle_tower_finished:
			_tried_to_use_finished_tower(letter_node, %MiddleTower)
			return
		%MiddleTower.add_child(duplicate_letter)
		if turvy == true:
			%MiddleTower.move_child(duplicate_letter, 0)
		call_deferred("_letter_dropper", duplicate_letter, %MiddleTower)
		var quick_string = ""
		for i in %MiddleTower.get_children():
			quick_string += i.get_node("Letter").text
		middle_tower_string = quick_string
		print(middle_tower_string)
			
		if %MiddleTower.get_children().size() > 8:
			_tower_crumbles("middle")
	else:
		if right_tower_crumbled:
			_tried_to_use_disabled_tower(letter_node, %RightTower)
			return
		if right_tower_finished:
			_tried_to_use_finished_tower(letter_node, %RightTower)
			return
		%RightTower.add_child(duplicate_letter)
		if turvy == true:
			
			%RightTower.move_child(duplicate_letter, 0)
		call_deferred("_letter_dropper", duplicate_letter, %RightTower)
		var quick_string = ""
		for i in %RightTower.get_children():
			quick_string += i.get_node("Letter").text
		right_tower_string = quick_string
		print(right_tower_string)
			
		if %RightTower.get_children().size() > 8:
			_tower_crumbles("right")
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
		if letter_node_to_destroy != null:
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
		left_tower_finished = true
		%LeftSubmit.disabled = true
	if tower == "middle":
		tower_to_finish = %MiddleTower
		middle_tower_finished = true
		%MiddleSubmit.disabled = true
	if tower == "right":
		tower_to_finish = %RightTower
		right_tower_finished = true
		%RightSubmit.disabled = true
	number_of_towers_disabled += 1
	await _tower_rising(tower_to_finish)
	for i in tower_to_finish.get_children():
		
		i.get_node("Letter").add_theme_color_override("font_color", Color.DARK_GOLDENROD)

		

	pass

func _tower_crumbles(tower):
	print(str(tower) + " tower crumbles to the ground, incomprehensible")
	var tower_to_crumble
	var reference_button
	if tower == "left":
		tower_to_crumble = %LeftTower
		left_tower_crumbled = true
		%LeftSubmit.disabled = true
		reference_button = %LeftSubmit
	if tower == "middle":
		tower_to_crumble = %MiddleTower
		middle_tower_crumbled = true
		%MiddleSubmit.disabled = true
		reference_button = %MiddleSubmit
	if tower == "right":
		tower_to_crumble = %RightTower
		right_tower_crumbled = true
		%RightSubmit.disabled = true
		reference_button = %RightSubmit
	number_of_towers_disabled += 1
	var tower_size = tower_to_crumble.size
	var tower_position = tower_to_crumble.global_position

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
		
	var broken_tower = %BrokenTower.duplicate()
	%FallingLettersControl.add_child(broken_tower)
	await get_tree().process_frame

	broken_tower.global_position.y = %LeftSubmit.global_position.y
	broken_tower.global_position.x = reference_button.global_position.x
	broken_tower.global_position.x += (reference_button.size.x - broken_tower.size.x)/2
	
	broken_tower.size = tower_size
	broken_tower.position.y -= (broken_tower.size.y + 50) 
	print(broken_tower.position)
	broken_tower.visible = true
	
	#broken_tower.position.y = 
	var tween = create_tween()
	tween.tween_property(broken_tower, "modulate", Color.WHITE, 3)
	pass

func _artisan_spawner(node):
	var artisan = TextureRect.new()
	artisan.texture = load(builder_artisan_art[randi_range(0, builder_artisan_art.size() - 1)])
	node.add_child(artisan)
	var random = randi_range(0,2)
	if random == 0:
		return
	elif random == 1:
		artisan.flip_h = true
		artisan.position.x += 50
	else:
		artisan.position.x -= 50
		return
	#var artisan = TextureRect.new()
	#var random_1 = randi_range(0,2)
	#if random_1 == 2:
		#return
	#else:
		#var artisan_texture = artisan_art[randi_range(0, artisan_art.size() - 1)]
		#artisan.texture = load(artisan_texture)
		#artisan.modulate = Color.TRANSPARENT
		#node.add_child(artisan)
		#if random_1 == 0:
			#artisan.position.x += node.get_theme_font_size("font_size")
		#if random_1 == 1:
			#artisan.flip_h = true
			##artisan.position.x -= 200
		#var tween = create_tween()
		#tween.tween_property(artisan, "modulate", Color.WHITE, 1)

func _letter_dropper(duplicate_letter, tower):
	_tower_rising(tower)
	for i in range(5):
		await get_tree().process_frame
	#var moving_letter = duplicate_letter.duplicate()
	var moving_letter = %PrototypeFallingLetter.duplicate()
	moving_letter.position = Vector2(0,0)
	moving_letter.visible = true
	moving_letter.size = duplicate_letter.size
	moving_letter.text = duplicate_letter.get_node("Letter").text
	var final_position = duplicate_letter.get_node("Letter").global_position
	printerr(duplicate_letter.get_node("Letter").get_theme_font_size("font_size"))
	printerr(moving_letter.get_theme_font_size("font_size"))
	var font_size_fraction = float(duplicate_letter.get_node("Letter").get_theme_font_size("font_size"))/float(moving_letter.get_theme_font_size("font_size"))
	printerr(font_size_fraction)
	var target_scale = Vector2(font_size_fraction, font_size_fraction)
	#final_position += (moving_letter.size - duplicate_letter.size)/2
	var initial_position = last_touched_position
	print(final_position)
	%MovingLettersControl.add_child(moving_letter)
	moving_letter.global_position = initial_position - moving_letter.size/2
	var tween = create_tween()
	tween.tween_property(moving_letter, "global_position", final_position, 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(moving_letter, "scale", target_scale, 1)
	await tween.finished
	var style_box = StyleBoxTexture.new()
	printerr(brown_tower_art_array)
	var texture = load(brown_tower_art_array[randi_range(0, brown_tower_art_array.size() -1)])
	print(texture)
	style_box.texture = load(brown_tower_art_array[randi_range(0, brown_tower_art_array.size() -1)])
	duplicate_letter.add_theme_stylebox_override("panel", style_box)
	duplicate_letter.modulate = Color.WHITE
	duplicate_letter.visible = true
	moving_letter.queue_free()
	_artisan_spawner(duplicate_letter)
	
func _tower_rising(tower):
	
	tower.modulate.a = 0.1
	await get_tree().create_timer(0.25).timeout
	tower.modulate.a = 0.4
	await get_tree().create_timer(0.25).timeout
	tower.modulate.a = 0.7	
	await get_tree().create_timer(0.25).timeout
	tower.modulate.a = 1.0	
	
func _tried_to_use_disabled_tower(letter_node, tower):
	var temp_letter_node = letter_node.duplicate()
	%MovingLettersControl.add_child(temp_letter_node)
	letter_node.queue_free()
	var artisan_particles = %ArtisanParticles.duplicate()
	var meteor_particles = %MeteorParticles.duplicate()
	var target_position = Vector2(tower.global_position.x + tower.size.x/2, tower.global_position.y + tower.size.y)
	artisan_particles.position = Vector2.ZERO
	meteor_particles.position = Vector2.ZERO
	temp_letter_node.add_child(artisan_particles)
	temp_letter_node.add_child(meteor_particles)
	artisan_particles.position += temp_letter_node.size/2
	meteor_particles.position = artisan_particles.position
	artisan_particles.visible = true
	artisan_particles.texture = load(artisan_art[randi_range(0, artisan_art.size()-1)])
	meteor_particles.visible = true
	
	var tween = create_tween()
	tween.tween_property(temp_letter_node, "global_position", target_position, 1).set_trans(Tween.TRANS_SINE)
	await tween.finished
	artisan_particles.emitting = true
	meteor_particles.emitting = false
	temp_letter_node.self_modulate = Color.TRANSPARENT
	await get_tree().create_timer(artisan_particles.lifetime).timeout
	temp_letter_node.queue_free()

func _tried_to_use_finished_tower(letter_node,tower):

	 
	var initial_position = Vector2(tower.global_position.x + tower.size.x/2, tower.global_position.y)
	var temp_letter_node = letter_node.duplicate()
	var target_texture = TextureRect.new()
	target_texture.modulate = Color.TRANSPARENT
	target_texture.texture = load("res://data/images/textures/scribbles/DoodleTarget.png")
	target_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	target_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	target_texture.size = temp_letter_node.size + Vector2(50,50)
	temp_letter_node.add_child(target_texture)
	target_texture.position -= (target_texture.size - temp_letter_node.size)/2
	temp_letter_node.pivot_offset = temp_letter_node.size/2
	var target_position = temp_letter_node.global_position
	target_position += temp_letter_node.size/2
	var meteor_particles = %MeteorParticles.duplicate()
	var sparks_particles = %SparksParticles.duplicate()
	meteor_particles.global_position = initial_position
	%MovingLettersControl.add_child(temp_letter_node)
	%MovingLettersControl.add_child(meteor_particles)
	letter_node.queue_free()
	var tween = create_tween()
	meteor_particles.visible = true
	tween.tween_property(meteor_particles, "global_position", target_position, 1).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(target_texture, "modulate", Color.WHITE, 0.25)
	await tween.finished
	var letter_destroy_tween = create_tween()
	letter_destroy_tween.tween_property(temp_letter_node, "scale", Vector2.ZERO, 1).set_trans(Tween.TRANS_BACK)
	letter_destroy_tween.parallel().tween_property(temp_letter_node, "modulate", Color.TRANSPARENT, 0.6)
	%MovingLettersControl.add_child(sparks_particles)
	sparks_particles.global_position = target_position
	sparks_particles.visible = true
	sparks_particles.emitting = true
	meteor_particles.emitting = false
	await get_tree().create_timer(sparks_particles.lifetime).timeout
	sparks_particles.queue_free()
	meteor_particles.queue_free()
	temp_letter_node.queue_free()
	
	pass
