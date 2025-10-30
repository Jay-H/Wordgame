extends ColorRect

var planets = []
var big_parent

func _ready():
	var parent = get_parent()
	big_parent = parent.get_parent()
	planets = %Planets.get_children()
	signal_setter()
	print(%Planets)
	print(planets)
	play_song()
	
func play_song():
	
	%SolarSystemSong.play()
	await %SolarSystemSong.finished
	play_song()
	
func stop_song():
	%SolarSystemSong.stop()

func signal_setter():
	for i in planets:
		print(i)
		i.connect("gui_input", get_planet_name.bind(i))
		i.pivot_offset += i.size/2
	pass # Replace with function body.

func get_planet_name(event: InputEvent, planet: Node):
	if event is InputEventMouseButton and event.is_pressed():
		print(planet.name)
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(planet, "scale", Vector2(1.5,1.5), 1)
		tween.parallel().tween_property(planet, "position", Vector2(planet.position.x, -1000), 3)
		tween.parallel().tween_property(planet, "modulate", Color.TRANSPARENT, 1.5)
		var audio = load("res://data/sound_effects/PianoF#.wav")
		%SoundEffect.stream = audio
		%SoundEffect.play()
		big_parent.background_setter(planet.name) 
	pass

 


func _on_back_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(%SolarSystemSong, "volume_db", -80, 1)
	big_parent._on_back_pressed()
	pass # Replace with function body.
