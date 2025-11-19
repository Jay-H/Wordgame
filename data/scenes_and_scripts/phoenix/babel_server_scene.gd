extends Control

var letter_is_held = false
var which_letter_node_held
var current_touch_position

func _process(_delta):
	#if letter_is_held:
		#which_letter_node_held.position = 
	pass


func _ready():
	%PrototypeFallingLetter.visible = false
	%NewLetterTimer.start(1)
	%NewLetterTimer.timeout.connect(_random_letter_node_creator)

func _input(event: InputEvent) -> void:
	if event == InputEventScreenDrag:
		current_touch_position = event.position
	if event == InputEventScreenTouch:
		current_touch_position = event.position

func _random_letter_node_creator():
	%NewLetterTimer.start(randi_range(1,3))
	var font_size = randi_range(180,230)
	var time_to_fall = randf_range(5, 15)
	var letter_node = %PrototypeFallingLetter.duplicate()
	var letter_button = letter_node.get_node("Button")
	var spawn_span = %FallingLettersControl.size.x - 250
	var distance_to_fall = 0.666 * %FallingLettersControl.size.y
	letter_button.button_down.connect(_letter_pressed.bind(letter_node))
	letter_button.button_up.connect(_letter_unpressed.bind(letter_node))
	letter_node.visible = true
	letter_node.text = GlobalData.alphabet[randi_range(0, GlobalData.alphabet.size() - 1)]
	letter_node.add_theme_font_size_override("font_size", font_size)
	letter_node.position.x = randi_range(250, spawn_span)
	letter_node.position.y = 0 - (letter_node.size.y + 50)
	%FallingLettersControl.add_child(letter_node)
	var tween = create_tween()
	tween.tween_property(letter_node, "position:y", distance_to_fall, time_to_fall)
	tween.chain().tween_property(letter_node, "modulate", Color.TRANSPARENT, 2)
	await tween.finished
	letter_node.queue_free()

func _letter_pressed(letter_node):
	which_letter_node_held = letter_node
	letter_is_held = true
	pass
	
func _letter_unpressed(letter_node):
	pass
