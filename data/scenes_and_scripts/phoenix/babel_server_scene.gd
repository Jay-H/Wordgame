extends Control

var letter_is_held = false
var which_letter_node_held
var current_touch_position
var letter_node_tween_dictionary = {}
var topsy = true
var turvy = false

func _process(_delta):
	if letter_is_held:
		if current_touch_position != null:
			which_letter_node_held.position = current_touch_position - which_letter_node_held.size/2
	pass


func _ready():
	%PrototypeFallingLetter.visible = false
	%NewLetterTimer.start(1)
	%NewLetterTimer.timeout.connect(_random_letter_node_creator)

func _input(event: InputEvent):

	if event is InputEventScreenDrag:
		current_touch_position = event.position
		print(event.position)
	if event is InputEventScreenTouch:
		print(event.position)
		current_touch_position = event.position

func _random_letter_node_creator():
	%NewLetterTimer.start(randi_range(1,1))
	var font_size = randi_range(180,230)
	var time_to_fall = randf_range(5, 15)
	var letter_node = %PrototypeFallingLetter.duplicate()
	var letter_button = letter_node.get_node("Button")
	var spawn_span = %FallingLettersControl.size.x - 250
	var distance_to_fall = 0.5 * %FallingLettersControl.size.y
	var consonant_or_vowel
	var random = randi_range(0,10)
	if random >= 0 and random <= 4:
		consonant_or_vowel = "vowel"
	else:
		consonant_or_vowel = "consonant"
	letter_button.button_down.connect(_letter_pressed.bind(letter_node))
	letter_button.button_up.connect(_letter_unpressed.bind(letter_node))
	letter_node.visible = true
	if consonant_or_vowel == "vowel":
		
		letter_node.text = GlobalData.vowels[randi_range(0, GlobalData.vowels.size() - 1)]
	else:
		
		letter_node.text = GlobalData.consonants[randi_range(0, GlobalData.consonants.size() - 1)]
	letter_node.add_theme_font_size_override("font_size", font_size)
	letter_node.position.x = randi_range(250, spawn_span)
	letter_node.position.y = 0 - (letter_node.size.y + 50)
	%FallingLettersControl.add_child(letter_node)
	var motion_tween = create_tween()
	var transparency_tween = create_tween()
	letter_node_tween_dictionary[letter_node] = [motion_tween, transparency_tween]
	motion_tween.tween_property(letter_node, "position:y", distance_to_fall, time_to_fall)
	transparency_tween.tween_property(letter_node, "modulate", Color.WHITE, time_to_fall - 2)
	transparency_tween.chain().tween_property(letter_node, "modulate", Color.TRANSPARENT, 2)
	await motion_tween.finished
	letter_node.queue_free()
	
func _letter_pressed(letter_node):
	for i in letter_node_tween_dictionary[letter_node]:
		i.kill()
	which_letter_node_held = letter_node
	letter_is_held = true
	
	pass
	
func _letter_unpressed(letter_node):
	letter_is_held = false
	letter_node.add_theme_font_size_override("font_size", 200)
	letter_node.modulate = Color.WHITE
	var duplicate_letter = letter_node.duplicate()
	if letter_node.global_position.x < %FallingLettersControl.size.x/3:
		%LeftTower.add_child(duplicate_letter)
		if topsy == true:
			move_child(duplicate_letter, 0)
	elif letter_node.global_position.x > %FallingLettersControl.size.x/3 and letter_node.position.x < (%FallingLettersControl.size.x/3) * 2:
		%MiddleTower.add_child(duplicate_letter)
		if topsy == true:
			move_child(duplicate_letter, 0)
	else:
		%RightTower.add_child(duplicate_letter)
		if topsy == true:
			move_child(duplicate_letter, 0)
	letter_node.queue_free()
	pass
