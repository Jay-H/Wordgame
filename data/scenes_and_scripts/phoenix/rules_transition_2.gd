extends CanvasLayer
@onready var main_menu = get_parent()
# Get Bonus nodes
signal skip_button_pressed


var fadeables = []
var username_1
var username_2
var gametype
var skip_pressed = false
var waiting_text_running = false
var nonrefadeables

func _ready():
	pass


func _process(delta):
	
	if skip_pressed == true:
		if waiting_text_running == false:
			waiting_text_running = true
			%SkipWaiting.text = "Waiting"
			await get_tree().create_timer(0.5).timeout
			%SkipWaiting.text = "Waiting."
			await get_tree().create_timer(0.5).timeout
			%SkipWaiting.text = "Waiting.."
			await get_tree().create_timer(0.5).timeout
			%SkipWaiting.text = "Waiting..."
			await get_tree().create_timer(0.5).timeout
			waiting_text_running = false

func setup(rules, dict):
	var my_player_number
	customizer(rules)
	fadeables_collector()
	gametype = rules
	%SkipButton.disabled = true
	if main_menu.firebase_local_id == dict["player_one_firebase_id"]:
		my_player_number = "one"
	else:
		my_player_number = "two"
	if my_player_number == "one":
		%P1Label.text = str(dict["player_one_dictionary"]["username"])
		%P2Label.text = str(dict["player_two_dictionary"]["username"])
		%playerpic.setup(GlobalData.profile_pics[dict["player_one_dictionary"]["profilepic"]])
		%opponentpic.setup(GlobalData.profile_pics[dict["player_two_dictionary"]["profilepic"]])
	if my_player_number == "two":
		%P1Label.text = str(dict["player_two_dictionary"]["username"])
		%P2Label.text = str(dict["player_one_dictionary"]["username"])
		%playerpic.setup(GlobalData.profile_pics[dict["player_two_dictionary"]["profilepic"]])
		%opponentpic.setup(GlobalData.profile_pics[dict["player_one_dictionary"]["profilepic"]])		
	if dict["rules_skipped"] == true:
		%SkipButton.disabled = true
		%SkipButton.text = "Auto Skip!"
		%SkipButton.icon = null
		%SkipButton.add_theme_color_override("font_disabled_color", Color.GOLDENROD)
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SPRING)
		%SkipButton.position.x = 0 - %SkipButton.size.x - 50
		var screen_size = %Control.size
		var target_position = Vector2((screen_size.x + %SkipButton.size.x + 50), %SkipButton.position.y)
		var mid_position = Vector2(screen_size.x/2 - %SkipButton.size.x/2, %SkipButton.position.y)
		tween.tween_property(%SkipButton, "position", mid_position, 0.5)
		await tween.finished
		await get_tree().create_timer(0.5).timeout
		%SkipButton.add_theme_color_override("font_disabled_color", Color.GOLDENROD)
		var tween2 = create_tween()
		tween2.tween_property(%SkipButton, "position", target_position, 1)
	if dict["rules_skipped"] == false:
		%SkipButton.disabled = false
func fadeables_collector():
	fadeables.clear()
	for i in %Control.get_children():
		if not i == %NonFadeables:
			
			fadeables.append(i)
	pass

func _on_scramble_pressed() -> void:
	
	
	var fadingtween = create_tween()
	for i in fadeables:
		fadingtween.parallel().tween_property(i, "modulate", Color.TRANSPARENT, 0.5)	
	var close_button = %ScrambleRulesPanel.get_node("BackButton")
	close_button.pressed.connect(close_button_pressed.bind(close_button))
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(%ScrambleRulesPanel, "modulate", Color. WHITE, 0.75)
	tween.chain().tween_property(close_button, "modulate", Color.WHITE, 0.37)
	await tween.finished
	close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	
	pass # Replace with function body.


func _on_bonus_letter_pressed() -> void:
	var fadingtween = create_tween()
	for i in fadeables:
		fadingtween.parallel().tween_property(i, "modulate", Color.TRANSPARENT, 0.5)
	var close_button = %BonusLetterRulesPanel.get_node("BackButton")
	close_button.pressed.connect(close_button_pressed.bind(close_button))
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(%BonusLetterRulesPanel, "modulate", Color. WHITE, 0.75)
	tween.chain().tween_property(close_button, "modulate", Color.WHITE, 0.37)
	await tween.finished
	close_button.mouse_filter = Control.MOUSE_FILTER_STOP


func _on_obscurity_pressed() -> void:
	var fadingtween = create_tween()
	for i in fadeables:
		fadingtween.parallel().tween_property(i, "modulate", Color.TRANSPARENT, 0.5)
	var close_button = %ObscurityRulesPanel.get_node("BackButton")
	close_button.pressed.connect(close_button_pressed.bind(close_button))
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(%ObscurityRulesPanel, "modulate", Color. WHITE, 0.75)
	tween.chain().tween_property(close_button, "modulate", Color.WHITE, 0.37)
	await tween.finished
	close_button.mouse_filter = Control.MOUSE_FILTER_STOP

func close_button_pressed(close_button_node):
	print("close_button_pressed")
	
	print(close_button_node)
	var rules_panel = close_button_node.get_parent()
	print(rules_panel)
	rules_panel.modulate = Color.TRANSPARENT
	close_button_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close_button_node.modulate = Color.TRANSPARENT
	var unfadingtween = create_tween()
	var partialfadetween = create_tween()
	var node = %Wonder
	print(node)
	for i in fadeables:
		if i not in nonrefadeables:
			unfadingtween.parallel().tween_property(i, "modulate", Color.WHITE, 0.5)
		if i in nonrefadeables:
			partialfadetween.parallel().tween_property(i, "modulate", Color(1.0, 1.0, 1.0, 0.165), 0.5)


	


func _on_skip_button_pressed() -> void:
	%SkipButton.disabled = true
	skip_pressed = true
	skip_button_pressed.emit()
	var tween = create_tween()
	tween.tween_property(%SkipButton, "modulate", Color.TRANSPARENT, 0.5)
	
	
	pass # Replace with function body.

func fade_in():
	var canvasmodulate = %CanvasModulate
	canvasmodulate.color = Color.TRANSPARENT
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(canvasmodulate, "color", Color.WHITE, 1)
	await tween.finished
	

func fade_out():
	%SkipWaiting.visible = false
	var tween = create_tween()
	for i in get_children():
		tween.parallel().tween_property(i, "modulate", Color.TRANSPARENT, 1)
	await tween.finished

func customizer(game_type):
	 # 1. Create a RegEx object.
	var regex = RegEx.new()

	# 2. Compile the pattern. This finds and "captures" any capital letter A-Z.
	# The parentheses ( ) are what create the capture group.
	regex.compile("([A-Z])")

	# 3. Use sub() to replace all matches.
	# The second argument is the replacement string. "$1" is a backreference
	# that inserts the text from the first capture group (the capital letter).
	# "MyString" becomes " My String".
	var with_spaces = regex.sub(game_type, " $1", true)

	# 4. Clean up the string and split it.
	# strip_edges() removes any leading/trailing space (e.g., from the start).
	# split(" ") then creates the array.
	var words = with_spaces.strip_edges().split(" ")
	var not_for_refade = []
	for i in words:
		match i:
			"Scramble":
				%Scramble.visible = true
				%ScrambleButton.visible = true
				%ScramblePanel.visible = true
			"Bonus":
				%Bonus.modulate = Color.WHITE
				%BonusButton.visible = true
				%BonusPanel.modulate = Color.WHITE
				%BonusRedLine.visible = false
				%Bonus.mouse_filter = Control.MOUSE_FILTER_STOP

			"Obscurity":
				%Obscurity.modulate = Color.WHITE
				%ObscurityButton.visible = true
				%ObscurityPanel.modulate = Color.WHITE
				%ObscurityRedLine.visible = false
				%Obscurity.mouse_filter = Control.MOUSE_FILTER_STOP

			"Wonder":
				%Wonder.modulate = Color.WHITE
				%WonderButton.visible = true
				%WonderPanel.modulate = Color.WHITE	
				%WonderRedLine.visible = false
				%Wonder.mouse_filter = Control.MOUSE_FILTER_STOP

		if "Bonus" not in words:
			not_for_refade.append(%Bonus)
			not_for_refade.append(%BonusButton)
			not_for_refade.append(%BonusPanel)
			not_for_refade.append(%BonusRedLine)
		if "Obscurity" not in words:
			not_for_refade.append(%Obscurity)
			not_for_refade.append(%ObscurityButton)
			not_for_refade.append(%ObscurityPanel)
			not_for_refade.append(%ObscurityRedLine)
		if "Wonder" not in words:
			not_for_refade.append(%Wonder)
			not_for_refade.append(%WonderButton)
			not_for_refade.append(%WonderPanel)
			not_for_refade.append(%WonderRedLine)
			
	nonrefadeables = not_for_refade
	print(words)
	print(nonrefadeables)

func _on_wonder_pressed() -> void:
	var fadingtween = create_tween()
	for i in fadeables:
		fadingtween.parallel().tween_property(i, "modulate", Color.TRANSPARENT, 0.5)
	var close_button = %WonderRulesPanel.get_node("BackButton")
	close_button.pressed.connect(close_button_pressed.bind(close_button))
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(%WonderRulesPanel, "modulate", Color. WHITE, 0.75)
	tween.chain().tween_property(close_button, "modulate", Color.WHITE, 0.37)
	await tween.finished
	close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	pass # Replace with function body.
