extends Control
@onready var canvaslayernode = get_parent()
@onready var true_menu = canvaslayernode.get_parent()

var game_panels_visible = false
var variant_panel_visible = false
var selected_game = ""

#scramble variants region
var ensure_seven_letter_word = false
var time_limit = false
var show_words_to_find = false
var score = false
var time_limit_amount = 45
#end scramble variants region


func _process(_delta):
	%TimeLimitLabel.text = str(time_limit_amount)
	if selected_game == "wordsearch":
		%TitleLabel.text = "word search."
	if selected_game == "scramble":
		%TitleLabel.text = "scramble."
	if selected_game == "":
		%TitleLabel.text = "single player."
	if selected_game != "":
		if not variant_panel_visible:
			$StartPanel.visible = true
		if variant_panel_visible:
			$StartPanel.visible = false

func _fade_out():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 1)
	await tween.finished
	self.visible = false

func _fade_in():
	self.modulate = Color.TRANSPARENT
	self.visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 1)

func _on_back_button_pressed() -> void:
	await _fade_out()
	%MainMenuItems._fade_in()
	selected_game = ""
	$StartPanel.visible = false
	pass # Replace with function body.


func _on_game_button_pressed() -> void:
	%PianoController.play_random_chord()
	if game_panels_visible == false:
		$WordsearchPanel.visible = true
		$ScramblePanel.visible = true
		game_panels_visible = true
		return
	if game_panels_visible == true:
		$WordsearchPanel.visible = false
		$ScramblePanel.visible = false
		game_panels_visible = false
		return
	pass # Replace with function body.


func _on_wordsearch_button_pressed() -> void:
	selected_game = "wordsearch"
	$WordsearchPanel.visible = false
	$ScramblePanel.visible = false
	pass # Replace with function body.


func _on_scramble_button_pressed() -> void:
	selected_game = "scramble"
	$WordsearchPanel.visible = false
	$ScramblePanel.visible = false
	pass # Replace with function body.


func _on_start_button_pressed() -> void:
	%PianoController.play_random_chord()
	var parameters = []
	if selected_game == "scramble":
		parameters = [selected_game, ensure_seven_letter_word, time_limit, show_words_to_find, score, time_limit_amount]
		true_menu._single_player_start(parameters)
	pass
	pass # Replace with function body.


func _on_variants_button_pressed() -> void:
	%PianoController.play_random_chord()
	if selected_game == "scramble":
		if variant_panel_visible == false:
			$ScrambleVariantsMenu.visible = true
			variant_panel_visible = true
			return
		if variant_panel_visible == true:		
			$ScrambleVariantsMenu.visible = false
			variant_panel_visible = false
			return
		
	pass # Replace with function body.

func _on_record_score_toggled(toggled_on: bool) -> void:
	%PianoController.play_random_note()
	Input.vibrate_handheld(200, -1)
	if toggled_on:
		score = true
	if not toggled_on:
		score = false
	pass # Replace with function body.


func _on_word_list_toggled(toggled_on: bool) -> void:
	%PianoController.play_random_note()
	Input.vibrate_handheld(200, -1)
	if toggled_on:
		show_words_to_find = true
	if not toggled_on:
		show_words_to_find = false
	pass # Replace with function body.


func _on_seven_ensure_toggled(toggled_on: bool) -> void:
	%PianoController.play_random_note()
	Input.vibrate_handheld(200, -1)
	if toggled_on:
		ensure_seven_letter_word = true
	if not toggled_on:
		ensure_seven_letter_word = false
	pass # Replace with function body.


func _on_time_limit_toggled(toggled_on: bool) -> void:
	%PianoController.play_random_note()
	Input.vibrate_handheld(200, -1)
	if toggled_on:
		time_limit = true
		%TimeLimitLabel.visible = true
		%TimeLimit.visible = false
		%SevenEnsure.visible = false
		%WordList.visible = false
		%RecordScore.visible = false
	if not toggled_on:
		time_limit = false
	pass # Replace with function body.


func _on_up_button_pressed() -> void:
	Input.vibrate_handheld(200, 1)
	if time_limit_amount <= 950:
		time_limit_amount += 15
	else:
		await _time_limit_label_error()
	pass # Replace with function body.


func _on_down_button_pressed() -> void:
	Input.vibrate_handheld(200, 1)
	if time_limit_amount >= 45:
		time_limit_amount -= 15
	else:
		await _time_limit_label_error()
	pass # Replace with function body.

func _time_limit_label_error():
	var previous_amount = time_limit_amount
	time_limit_amount = "err"
	%DownButton.disabled = true
	%UpButton.disabled = true
	%ConfirmButton.disabled = true
	await get_tree().create_timer(0.35).timeout
	time_limit_amount = previous_amount
	%DownButton.disabled = false
	%UpButton.disabled = false
	%ConfirmButton.disabled = false
	pass


func _on_confirm_button_pressed() -> void:
	Input.vibrate_handheld(200, 1)
	await get_tree().create_timer(0.2).timeout
	Input.vibrate_handheld(200, 0.7)
	await get_tree().create_timer(0.2).timeout
	Input.vibrate_handheld(200, 0.3)
	%TimeLimitLabel.visible = false
	%TimeLimit.visible = true
	%SevenEnsure.visible = true
	%WordList.visible = true
	%RecordScore.visible = true
	
	pass # Replace with function body.
