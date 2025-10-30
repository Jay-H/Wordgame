extends CanvasLayer
@onready var main_menu = get_parent()
# Get Bonus nodes

var fadeables = []
var username_1
var username_2
var gametype
var skip_pressed = false
var waiting_text_running = false
var nonrefadeables

func _ready():
	var particles_node = %Particles.get_child(0)
	particles_node.modulate = Color.WHITE


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

func setup(username1, username2, game_type, opponent_info, player_info):
	print(game_type)
	customizer(game_type)
	fadeables_collector()
	
	gametype = game_type
	username_1 = player_info["Username"]
	username_2 = opponent_info["Username"]
	
	%playerpic.texture = load(player_info["ProfilePic"])
	%P1Label.text = username_1
	%P2Label.text = username_2
	%opponentpic.texture = load(opponent_info["ProfilePic"])

func fadeables_collector():
	fadeables.clear()
	for i in %CanvasModulate.get_children():
		if not i is CanvasGroup:
			fadeables.append(i)
	pass

func _on_scramble_pressed() -> void:
	var fadingtween = create_tween()
	for i in fadeables:
		fadingtween.parallel().tween_property(i, "modulate", Color.TRANSPARENT, 0.5)
		
	var close_button = %ScrambleRulesPanel.get_child(1)
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
	var close_button = %BonusLetterRulesPanel.get_child(1)
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
	var close_button = %ObscurityRulesPanel.get_child(1)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(%ObscurityRulesPanel, "modulate", Color. WHITE, 0.75)
	tween.chain().tween_property(close_button, "modulate", Color.WHITE, 0.37)
	await tween.finished
	close_button.mouse_filter = Control.MOUSE_FILTER_STOP

func close_button_pressed(close_button_node):
	print("close_button_pressed")
	
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
	main_menu.rpc_id(1,"rules_skip", username_1, username_2)
	
	
	pass # Replace with function body.

func fade_in():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	var canvasmodulate = %CanvasModulate
	tween.tween_property(canvasmodulate, "color", Color.WHITE, 1)
	

func fade_out():
	%SkipWaiting.visible = false
	var tween = create_tween()
	for i in get_children():
		tween.parallel().tween_property(i, "modulate", Color.TRANSPARENT, 1)
	queue_free()

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
	var close_button = %WonderRulesPanel.get_child(1)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(%WonderRulesPanel, "modulate", Color. WHITE, 0.75)
	tween.chain().tween_property(close_button, "modulate", Color.WHITE, 0.37)
	await tween.finished
	close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	pass # Replace with function body.
