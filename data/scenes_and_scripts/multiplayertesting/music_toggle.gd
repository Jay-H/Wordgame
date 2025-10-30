extends Button

var music_on = false




func _on_toggled(toggled_on: bool) -> void:
	if toggled_on: 
		$Music.volume_db = 12
		print($Music.volume_db)
		#$Music.play()
	if not toggled_on:
		$Music.volume_db = -80
		print($Music.volume_db)
		#$Music.stop()
	pass # Replace with function body.
