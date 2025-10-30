extends CanvasLayer

@onready var wordsearch = load("res://data/scenes_and_scripts/wordsearch/WordSearch.tscn")
@onready var scramble = load("res://data/scenes_and_scripts/scramble/c_scramble.tscn")
@onready var particles = load("res://data/scenes_and_scripts/scramble/c_particles.tscn")
var roundmarker = 0
var number_of_game_variants = Globals.game_variant_list.size() - 1
signal game_node_name(node_name)
var fadekillingstarted = false
var transition_time = 5
var current_fade_manager_instance = null
var fade_canvas_modulate = null
var skip_pressed = false
var is_transitioning = false


@onready var fademanager = load("res://data/scenes_and_scripts/scramble/FadeManager.tscn")

func _ready():
	
	rules_screen_transition()
	$RulesTransition/CanvasModulate/Control/Button.connect("pressed", skipper)
	
	await get_tree().create_timer(transition_time + 2).timeout
	if skip_pressed == false:
		game_spawner()
		print("maingamespawn")
	else:
		print("no main game spawn")
	
	
func skipper():
	if is_transitioning == false:
		if skip_pressed == false:
			skip_pressed = true
			game_spawner()
			$RulesTransition/CanvasModulate/Control/Button.disabled = true
			$RulesTransition/CanvasModulate/Control/Button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var tween2 = create_tween()
			tween2.tween_property($RulesTransition/CanvasModulate, "color", Color.TRANSPARENT, 1)
			tween2.tween_property(%TransitionBox, "modulate", Color.TRANSPARENT, 1)
			tween2.parallel().tween_property($RulesTransition/CanvasModulate/Control/RulesParticles, "modulate:a", 0, 1)
		
	else:
		print("alreadyskipped")
	
func game_spawner():
	if CSignals.round_number <= 2:
		CSignals.round_number += 1
		var chosen_game_path = game_chooser()
		print(chosen_game_path)
		var chosen_game_scene = load(chosen_game_path)
		
		var game_instance = chosen_game_scene.instantiate()
		var fademanager_instance = fademanager.instantiate()
		var particles_instance = particles.instantiate()
		
		await get_tree().create_timer(1.0).timeout
		%CurrentGameCanvasModulate.add_child(game_instance)
		
		game_instance.connect("five_seconds", fade_in_particles)
		game_instance.connect("zero_seconds", half_fade_out_particles)
		game_instance.connect("zero_seconds", game_killer.bind(game_instance))
		
		#scramble_instance.connect("one_second", fade_in)
		%FadeManager.add_child(fademanager_instance)
		current_fade_manager_instance = fademanager_instance
		add_child(particles_instance)
		fademanager_instance.connect("next_round_time", fade_killer.bind(fademanager_instance))
		fademanager_instance.connect("next_round_time", rules_screen_transition)
		fade_canvas_modulate = %FadeManagerCanvasModulate
		CSignals.current_game_node = game_instance
		#if chosen_game_scene == wordsearch:
			#print("this is it" + str(game_instance)) 
			#game_instance.position = get_viewport_rect().size/2
	if CSignals.round_number >2:
		print("GAMEOVER")


func _process(delta):
	move_child(%CanvasLayer,-1)
	#if skip_pressed == true:
		
		#$RulesTransition/CanvasModulate.modulate = Color.TRANSPARENT
		
	pass

func rules_screen_transition():
	is_transitioning = true
	$RulesTransition/CanvasModulate/Control/Button.disabled = false
	$RulesTransition/CanvasModulate/Control/Button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var fade_in_tween = create_tween()
	%RulesTransition.visible = true
	
	fade_in_tween.tween_property(%TransitionBox, "modulate", Color.WHITE, 1)
	fade_in_tween.tween_property($RulesTransition/CanvasModulate, "color", Color.WHITE, 1)
	fade_in_tween.tween_property($RulesTransition/CanvasModulate/Control/RulesParticles, "modulate:a", 1, 1)
	
	await fade_in_tween.finished
	is_transitioning = false
	await get_tree().create_timer(2).timeout
	
	
	
	
	await get_tree().create_timer(transition_time).timeout
	var tween2 = create_tween()
	tween2.tween_property($RulesTransition/CanvasModulate, "color", Color.TRANSPARENT, 1)
	tween2.tween_property(%TransitionBox, "modulate", Color.TRANSPARENT, 1)
	tween2.parallel().tween_property($RulesTransition/CanvasModulate/Control/RulesParticles, "modulate:a", 0, 1)
	await tween2.finished
	skip_pressed = false
	
	
func game_killer(gamenode):
	var tween = create_tween()
	tween.tween_property(%CurrentGameCanvasModulate, "color", Color.TRANSPARENT, 1)
	await tween.finished
	gamenode.queue_free()
	%CurrentGameCanvasModulate.color = Color.WHITE
	
	skip_pressed = false
	
func fade_killer(fademanager):
	var actual_particles = get_node("Particles/GPUParticles2D")
	if fadekillingstarted == false:
		fadekillingstarted = true
		await get_tree().create_timer(2).timeout
		fademanager.queue_free()
		var tween2 = create_tween()
		tween2.tween_property(actual_particles, "modulate:a", 0, 5)
		await get_tree().create_timer(transition_time).timeout
		if skip_pressed == false:
			game_spawner()
		fadekillingstarted = false

	if fadekillingstarted == true:
		pass
		
func game_chooser():
	var chosen_game_index = randi_range(0, number_of_game_variants-2)
	var chosen_game = Globals.game_variant_list[chosen_game_index]
	return chosen_game
	
	
	
func fade_in_particles():
	var tween = create_tween()
	var actual_particles = get_node("Particles/GPUParticles2D")
	
	# Animate from transparent to opaque
	tween.tween_property(actual_particles, "modulate:a", 1, 3)


func half_fade_out_particles():
	var tween = create_tween()
	var actual_particles = get_node("Particles/GPUParticles2D")
	tween.tween_property(actual_particles, "modulate:a", 0.5, 1)
	
	
	
