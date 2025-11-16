extends Control
@onready var canvaslayernode = get_parent()
@onready var true_menu = canvaslayernode.get_parent()
var game_type_light_nodes = []
var game_type_light_dictionary = {}
var game_type_button_array = []
var modifier_light_nodes = []
var modifier_light_dictionary = {}
var button_node_array = []
var modifier_button_node_array = []
var button_to_light_dictionary = {}
var red_light = load("res://data/images/textures/scribbles/DoodleButton2.png")
var green_light = load("res://data/images/textures/scribbles/DoodleButton2Green.png")
var active_game
var active_modifiers = []

func _ready():
	var hbox_array = []
	for i in %GameTypeBox.get_children():
		hbox_array.append(i)
	for i in hbox_array:
		game_type_light_nodes.append(i.get_node("Light"))
		game_type_light_dictionary[i.get_node("Light")] = i.get_node("Button")
		button_node_array.append(i.get_node("Button"))
		button_to_light_dictionary[i.get_node("Button")] = i.get_node("Light")
		game_type_button_array.append(i.get_node("Button"))
	hbox_array = []
	for i in %ModifierBox.get_children():
		hbox_array.append(i)
	for i in hbox_array:
		modifier_light_nodes.append(i.get_node("Light"))
		modifier_light_dictionary[i.get_node("Light")] = i.get_node("Button")
		button_node_array.append(i.get_node("Button"))
		button_to_light_dictionary[i.get_node("Button")] = i.get_node("Light")
		modifier_button_node_array.append(i.get_node("Button"))
		print(i.get_node("Button"))
	for i in button_node_array:
		i.pressed.connect(_on_button_pressed.bind(i))

func _on_button_pressed(button_node):
	var button_text = button_node.text
	var light = button_to_light_dictionary[button_node]

	if game_type_button_array.has(button_node):
		if button_node.button_pressed:
			active_game = button_node.text
			for i in game_type_button_array:
				if i != button_node:
					i.set_pressed_no_signal(false)
					button_to_light_dictionary[i].texture = red_light
	if button_node.button_pressed:
		light.texture = green_light
	else:
		light.texture = red_light
	pass


	#seven_letter_word_guaranteed = parameters[1]
	#time_limit = parameters[2]
	#show_words_to_find = parameters[3]
	#score_matters = parameters[4]
	#time_limit_duration = parameters[5]
func _on_begin_pressed() -> void:
	var parameters = []
	parameters = [str(active_game), false, false, false, false, 120]
	if active_game == "Scramble":
		for i in modifier_button_node_array:
			if i.text == "Seven" and i.button_pressed:
				parameters[1]  = true
			if i.text == "Limit" and i.button_pressed:
				parameters[2] = true
			if i.text == "Score" and i.button_pressed:
				parameters[4] = true
			if i.text == "Clues" and i.button_pressed:
				parameters[3] = true
	true_menu._single_player_start(parameters)
	pass # Replace with function body.


func _fade_out():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.5)
	await tween.finished
	self.visible = false

func _fade_in():
	self.modulate = Color.TRANSPARENT
	self.visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.5)


func _on_back_pressed() -> void:
	await _fade_out()
	%MainMenuItems._fade_in()
	for i in button_node_array:
		i.set_pressed_no_signal(false)
	for i in game_type_light_nodes:
		i.texture = red_light
	for i in modifier_light_nodes:
		i.texture = red_light
	pass # Replace with function body.
