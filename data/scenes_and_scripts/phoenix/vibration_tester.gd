extends Control

var strength : float = 0.5
var duration : int = 500
var number_of_pulses : int = 1
var time_between_pulses : float = 0.1



func _process(_delta):
	%Label.text = "strength: " + str(strength) + "\n" + "duration: " + str(duration) + " ms"+ "\n" + "number of pulses: " + str(number_of_pulses) + "\n" + "time between: " + str(time_between_pulses) + " sec"	
	pass


func _on_vibration_strength_button_pressed() -> void:
	strength = float(%VibrationStrength.text) 
	pass # Replace with function body.


func _on_number_of_pulses_button_pressed() -> void:
	number_of_pulses = int(%NumberOfPulses.text)
	pass # Replace with function body.


func _on_time_between_pulses_button_pressed() -> void:
	time_between_pulses = float(%TimeBetweenPulses.text)
	pass # Replace with function body.


func _on_vibration_duration_button_pressed() -> void:
	duration = int(%VibrationDuration.text)
	pass # Replace with function body.


func _on_tester_button_pressed() -> void:
	for i in number_of_pulses:
		await _vibrate()
	pass # Replace with function body.

func _vibrate():
	print("vibrated")
	Input.vibrate_handheld(duration, strength)
	await get_tree().create_timer(time_between_pulses).timeout
