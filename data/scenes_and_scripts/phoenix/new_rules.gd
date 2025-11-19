extends Control

signal skip_button_pressed

var green_button = load("res://data/images/textures/scribbles/DoodleButton2Green.png")
var red_button = load("res://data/images/textures/scribbles/DoodleButton2.png")
var game_variant
var active_variants = 0
@onready var variant_label_node_array = [%Variant1, %Variant2, %Variant3, %Variant4]
@onready var variant_HBox_node_array = [%Variant1HBox, %Variant2HBox, %Variant3HBox, %Variant4HBox]
@onready var information_nodes = [%InformationBackground, %InformationControl, %RulesInformation, %BackButton, %TitleLabel]
@onready var main_menu = get_parent()
var information_screen_fading = false
var skip_pressed = false
var waiting_text_running = false


func _process(delta: float) -> void:
	if skip_pressed == true:
		if waiting_text_running == false:
			waiting_text_running = true
			%SkipButton.text = "Waiting"
			await get_tree().create_timer(0.5).timeout
			%SkipButton.text = "Waiting."
			await get_tree().create_timer(0.5).timeout
			%SkipButton.text = "Waiting.."
			await get_tree().create_timer(0.5).timeout
			%SkipButton.text = "Waiting..."
			await get_tree().create_timer(0.5).timeout
			waiting_text_running = false

func _ready():
	%SkipButton.disabled = true
	%SkipButton.modulate = Color.TRANSPARENT
	Globals._load_rules()
	%InformationControl.modulate = Color.TRANSPARENT
	%InformationControl.visible = true
	for i in information_nodes:
		i.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if main_menu.my_info["auto_skip_rules"] == true:
		await get_tree().create_timer(1).timeout
		var tween = create_tween()
		tween.tween_property(%SkipButton, "modulate", Color.WHITE, 1)
		
		_on_skip_button_pressed(false)
	else:
		await get_tree().create_timer(1).timeout
		var tween = create_tween()
		tween.tween_property(%SkipButton, "modulate", Color.WHITE, 1)
		%SkipButton.disabled = false
		
func _setup(variant, dict):
	if dict["rules_skipped"] == true:
		%SkipButton.text = "AUTO SKIP!"
		%SkipButton.disabled = true
	
	var compatible_variant = variant
	if variant.contains("Hangman"):
		if variant.contains("ChaosShared"):
			compatible_variant = "HangmanAbsolutebedlam"
		if variant.contains("ChaosVanilla"):
			compatible_variant = "HangmanBedlam"
		if variant.contains("ChaosEphemeral"):
			compatible_variant = "HangmanBedlamEphemeral"
		if variant.contains("DelayEphemeral"):
			compatible_variant = "HangmanEphemeralLiminal"
		if variant.contains("Delay") and not variant.contains("DelayEphemeral"):
			compatible_variant = "HangmanLiminal"
	if variant.contains("WordsearchVanilla"):
		compatible_variant = "WordsearchSeparate"
	if variant.contains("WordsearchShared"):
		compatible_variant = "WordsearchTogether"
	if variant.contains("WordsearchHidden"):
		compatible_variant = "WordsearchNightmare"
	game_variant = compatible_variant
	print(compatible_variant)
	
	var individual_words = []
	var regex = RegEx.new()
	var error = regex.compile("[A-Z](?:[A-Z]*(?![a-z])|[a-z]*)")
	
	if error == OK:
		var matches = regex.search_all(compatible_variant)
		for i in matches:
			individual_words.append(i.get_string().to_lower())
		
		print(individual_words)
	else:
		print("regex error")
	
	%UpcomingGame.text = individual_words[0]
	for i in (individual_words.size() - 1):
		var variant_text = individual_words[i+1].to_lower()
		if variant_text == "absolutebedlam":
			variant_text = "absolute\nbedlam"
		variant_label_node_array[i].text = variant_text
		active_variants += 1
	var iterative_number = 4-active_variants
	for i in range(1, iterative_number + 1):
		var negative_index = 0 - i
		variant_HBox_node_array[negative_index].modulate.a = 0.25
		var button_scribble_node = get_node("CanvasLayer/MainVBox/MainVariantVBox/SubVariantVBox/" + str(variant_HBox_node_array[negative_index].name) + str("/ButtonScribble"))
		var hand_scribble_node = get_node("CanvasLayer/MainVBox/MainVariantVBox/SubVariantVBox/" + str(variant_HBox_node_array[negative_index].name) + str("/ButtonScribble/HandScribble"))
		variant_HBox_node_array[negative_index].mouse_filter = Control.MOUSE_FILTER_IGNORE
		variant_label_node_array[negative_index].text = "inactive"
		button_scribble_node.texture = red_button
		hand_scribble_node.modulate = Color.TRANSPARENT
	print("setup done")
	
func _fade_in():
	%CanvasModulate.color = Color.TRANSPARENT
	var tween = create_tween()
	tween.tween_property(%CanvasModulate, "color", Color.WHITE, 1)	
	await tween.finished

func _fade_out():
	%CanvasModulate.color = Color.WHITE
	var tween = create_tween()
	tween.tween_property(%CanvasModulate, "color", Color.TRANSPARENT, 1)	
	await tween.finished

func _on_upcoming_game_h_box_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		print("touched")
		
		_information_shower(%UpcomingGame.text)
	pass # Replace with function body.


func _on_variant_1h_box_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		_information_shower(%Variant1.text)
		print("touched")
	pass # Replace with function body.


func _on_variant_2h_box_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		_information_shower(%Variant2.text)
		print("touched")
	pass # Replace with function body.


func _on_variant_3h_box_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		_information_shower(%Variant3.text)
		print("touched")
	pass # Replace with function body.


func _on_variant_4h_box_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		_information_shower(%Variant4.text)
		print("touched")
	pass # Replace with function body.


func _on_back_button_pressed() -> void:
	if information_screen_fading == false:
		Haptics.triple_quick_medium()
		information_screen_fading = true
		for i in information_nodes:
			i.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tween = create_tween()
		tween.tween_property(%InformationControl, "modulate", Color.TRANSPARENT, 0.5)
		tween.parallel().tween_property(%MainVBox, "modulate", Color.WHITE, 0.5)
		tween.parallel().tween_property(%Scribbles, "modulate", Color.WHITE, 0.5)
		await tween.finished
		information_screen_fading = false
	pass # Replace with function body.


func _information_shower(variant_name):
	if information_screen_fading == false:
		Haptics.double_quick_medium()
		if game_variant == "HangmanAbsolutebedlam":
			%RulesInformation.text = Globals.rules_text_dictionary["absolutebedlam"]
		else:
			%RulesInformation.text = Globals.rules_text_dictionary[str(variant_name)]
		%TitleLabel.text = str(variant_name)
		var tween = create_tween()
		information_screen_fading =  true
		tween.tween_property(%MainVBox, "modulate", Color.TRANSPARENT, 0.5)
		tween.parallel().tween_property(%InformationControl, "modulate", Color.WHITE, 0.5)
		tween.parallel().tween_property(%Scribbles, "modulate", Color.TRANSPARENT, 0.5)
		await tween.finished
		for i in information_nodes:
			i.mouse_filter = Control.MOUSE_FILTER_STOP
		information_screen_fading = false
	else:
		return
	pass


func _on_skip_button_pressed(send_to_server) -> void:
	Haptics.hard_doublet()
	if send_to_server == true:
		skip_button_pressed.emit()
	%SkipButton.disabled = true
	skip_pressed = true
	#var tween = create_tween()
	#tween.tween_property(%SkipButton, "modulate", Color.TRANSPARENT, 0.25)
	pass # Replace with function body.
