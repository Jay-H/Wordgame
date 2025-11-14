extends Control

func _play_login_music():
	%Music.volume_linear = 0
	%Music.stream = load("res://data/music/LoginPiano1.wav")
	%Music.play(1.21)
	var volume_tween = create_tween()
	volume_tween.tween_property(%Music, "volume_linear", 1, 0.5)
