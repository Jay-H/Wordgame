extends Node

var screensize : Rect2
signal next_round_time

@onready var fade_overlay = %FadeOverlay
@onready var game_over = %GameOverLabel
@onready var particles = %Control/GPUParticles2D
@onready var player_round_score = %PlayerRoundScore
@onready var enemy_round_score = %EnemyRoundScore
@onready var player_cumulative_score = %PlayerCumulativeScore
@onready var enemy_cumulative_score = %EnemyCumulativeScore
@onready var player_avatar = %PlayerAvatar
@onready var enemy_avatar = %EnemyAvatar
@onready var player_name = %PlayerNameLabel
@onready var enemy_name = %EnemyNameLabel
@onready var circle_node = load("res://data/scenes_and_scripts/scramble/animated_circle.tscn")
@onready var x_node = load("res://data/scenes_and_scripts/scramble/AnimatedX.tscn")
@onready var timer_node = %Timer
@onready var timer_label_node = %Label
@onready var timer_control_node = %TimerControl
var fade_in_started = false
var game_node = null

var font_size = 150

func _ready():
	await get_tree().process_frame
	
	screensize = get_tree().get_root().get_visible_rect()
	#positioning the avatars
	player_avatar.position.x -= screensize.size.x/4
	player_avatar.position.y += screensize.size.y/8
	enemy_avatar.position.x += screensize.size.x/4
	enemy_avatar.position.y += screensize.size.y/8
	#positioning player names
	player_name.text = CSignals.player_name
	enemy_name.text = CSignals.enemy_name
	player_name.position = player_avatar.position
	player_name.position.y -= player_avatar.size.y/2
	player_name.position.y += player_name.size.y/2
	player_name.position.x -= (player_name.size.x - player_avatar.size.x)/2
	enemy_name.position = enemy_avatar.position
	enemy_name.position.y -= enemy_avatar.size.y/2
	enemy_name.position.y += enemy_name.size.y/2
	enemy_name.position.x -= (enemy_name.size.x - player_avatar.size.x)/2
	#positioning the box that contains circles and Xs
	
	%BottomRoundLabel.position.y -= 150
	game_node = CSignals.current_game_node
	print(game_node)
	game_node.connect("one_second", fade_in)
	game_node.connect("zero_seconds", round_end_score_display)
	game_node.connect("zero_seconds", timer_node.start)
	game_node.connect("zero_seconds", timer_fade_in)
	
	
	
func _process(delta):
	timer_updater()

func timer_fade_in():
	var tween = create_tween()
	tween.tween_property(timer_control_node, "modulate:a", 0.75, 1)
	fade_in_started = true
	
func timer_updater():
	var time_left = int(timer_node.time_left)
	if fade_in_started == false:
		pass
	else:
		timer_label_node.text = str(time_left)
	if fade_in_started:
		if time_left == 0:
			emit_signal("next_round_time")
			
	
	
	
	pass

func round_end_score_display():
	#var baseboard = get_node("../Baseboard")
	print("round end working")
	await get_tree().process_frame
	if CSignals.round_number == 3:
		%GameOverLabel.text = "Game Over"
		
	if CSignals.round_number == 1:
		if CSignals.player_round_score > CSignals.enemy_round_score:
			CSignals.player_won_round_one = true
		if CSignals.player_round_score < CSignals.enemy_round_score:
			CSignals.enemy_won_round_one = true
		if CSignals.player_round_score == CSignals.enemy_round_score:
			CSignals.round_one_tie = true
			
	if CSignals.round_number == 2:
		if CSignals.player_round_score > CSignals.enemy_round_score:
			CSignals.player_won_round_two = true
		if CSignals.player_round_score < CSignals.enemy_round_score:
			CSignals.enemy_won_round_two = true
		if CSignals.player_round_score == CSignals.enemy_round_score:
			CSignals.round_two_tie = true
			
	if CSignals.round_number == 3:
		if CSignals.player_round_score > CSignals.enemy_round_score:
			CSignals.player_won_round_three = true
		if CSignals.player_round_score < CSignals.enemy_round_score:
			CSignals.enemy_won_round_three = true
		if CSignals.player_round_score == CSignals.enemy_round_score:
			CSignals.round_three_tie = true		
			
	game_over.position.y -= game_over.size.y # position the round over label
	player_round_score.text = "Round score " + str(CSignals.player_round_score) 
	enemy_round_score.text = "Round score " + str(CSignals.enemy_round_score)
	CSignals.player_score += CSignals.player_round_score
	CSignals.enemy_score += CSignals.enemy_round_score
	CSignals.player_round_score = 0
	CSignals.enemy_round_score = 0
	
	player_cumulative_score.text = "Game score: " + str(CSignals.player_score)
	enemy_cumulative_score.text = "Game score: " + str(CSignals.enemy_score)
	print(CSignals.player_score)
	print(player_cumulative_score.text)
	print(player_cumulative_score.position)
	await get_tree().process_frame
	player_round_score.position = player_avatar.position
	player_round_score.position.y += player_avatar.size.y + player_round_score.size.y/2
	player_round_score.position.x -= (player_round_score.size.x - player_avatar.size.x)/2
	
	enemy_round_score.position = enemy_avatar.position
	enemy_round_score.position.y += enemy_avatar.size.y + enemy_round_score.size.y/2
	enemy_round_score.position.x -= (enemy_round_score.size.x - enemy_avatar.size.x)/2
	
	player_cumulative_score.position = player_avatar.position
	player_cumulative_score.position.y += player_avatar.size.y + player_cumulative_score.size.y
	player_cumulative_score.position.x -= (player_cumulative_score.size.x - player_avatar.size.x)/2
	enemy_cumulative_score.position = enemy_avatar.position
	enemy_cumulative_score.position.y += enemy_avatar.size.y + enemy_cumulative_score.size.y
	enemy_cumulative_score.position.x -= (enemy_cumulative_score.size.x - enemy_avatar.size.x)/2
	#player_cumulative_score.position.y += player_cumulative_score.size.y + (player_cumulative_score.size.y/2)
	var circle_node_instance = circle_node.instantiate()
	var circle_node_instance2 = circle_node.instantiate()
	var circle_node_instance3 = circle_node.instantiate()
	var x_node_instance = x_node.instantiate()
	var x_node_instance2 = x_node.instantiate()
	var x_node_instance3 = x_node.instantiate()
	
	#if CSignals.round_number == 1:
		#if CSignals.player_won_round_one == true:
			#circle_node_instance2.modulate = Color.TRANSPARENT
			#circle_node_instance3.modulate = Color.TRANSPARENT
		#if CSignals.enemy_won_round_one == true:
			#circle_node_instance.modulate = Color.TRANSPARENT
			#circle_node_instance2.modulate = Color.TRANSPARENT
			#circle_node_instance3.modulate = Color.TRANSPARENT
	#if CSignals.round_number == 2:
		#circle_node_instance3.modulate = Color.TRANSPARENT
		#circle_node_instance2.modulate = Color.WHITE

	#for i in baseboard.get_children():
		#i.queue_free()
	#next_round_bringer()
	
	
	var tween = create_tween()
	# Animate from transparent to opaque
	
	tween.tween_property(game_over, "modulate:a", 0.5, 1)

	tween.chain().tween_property(player_avatar, "modulate:a", 1, 0.5)
	tween.parallel().tween_property(enemy_avatar, "modulate:a", 1, 0.5)
	tween.parallel().tween_property(player_name, "modulate:a", 1, 0.5)
	tween.parallel().tween_property(enemy_name, "modulate:a", 1, 0.5)
	tween.chain().tween_property(player_round_score, "modulate:a", 0.5, 0.5) 
	tween.parallel().tween_property(enemy_round_score, "modulate:a", 0.5, 0.5)
	tween.chain().tween_property(player_cumulative_score, "modulate:a", 0.5, 0.5)
	tween.parallel().tween_property(enemy_cumulative_score, "modulate:a", 0.5, 0.5)
	await get_tree().create_timer(2.0).timeout
	
	%WinLoseBox.position.y = (screensize.size.y - 575)
	%WinLoseBox.position.x += ((screensize.size.x - (3 * 250) - (2 * %WinLoseBox.get_theme_constant("separation"))))/2  #the 3x250 is 3 x the size horizontal size of circle/X 
	if CSignals.round_number == 1:
		if CSignals.player_won_round_one == true:
			%WinLoseBox.add_child(circle_node_instance)
		if CSignals.enemy_won_round_one == true: 
			%WinLoseBox.add_child(x_node_instance)
		if CSignals.round_one_tie == true:
			%WinLoseBox.add_child(x_node_instance)
			
	if CSignals.round_number == 2:
		if CSignals.player_won_round_one == true:
			%WinLoseBox.add_child(circle_node_instance)
		if CSignals.enemy_won_round_one == true: 
			%WinLoseBox.add_child(x_node_instance)
		if CSignals.round_one_tie == true:
			%WinLoseBox.add_child(x_node_instance)
		await get_tree().create_timer(1.0).timeout
		if CSignals.player_won_round_two == true:
			%WinLoseBox.add_child(circle_node_instance2)
		if CSignals.enemy_won_round_two == true: 
			%WinLoseBox.add_child(x_node_instance2)
		if CSignals.round_two_tie == true:
			%WinLoseBox.add_child(x_node_instance2)
			
	if CSignals.round_number == 3:
		if CSignals.player_won_round_one == true:
			%WinLoseBox.add_child(circle_node_instance)
		if CSignals.enemy_won_round_one == true: 
			%WinLoseBox.add_child(x_node_instance)
		if CSignals.round_one_tie == true:
			%WinLoseBox.add_child(x_node_instance)
		await get_tree().create_timer(1.0).timeout
		if CSignals.player_won_round_two == true:
			%WinLoseBox.add_child(circle_node_instance2)
		if CSignals.enemy_won_round_two == true: 
			%WinLoseBox.add_child(x_node_instance2)
		if CSignals.round_two_tie == true:
			%WinLoseBox.add_child(x_node_instance2)
		await get_tree().create_timer(1.0).timeout
		if CSignals.player_won_round_three == true:
			%WinLoseBox.add_child(circle_node_instance3)
		if CSignals.enemy_won_round_three == true: 
			%WinLoseBox.add_child(x_node_instance3)
		if CSignals.round_three_tie == true:
			%WinLoseBox.add_child(x_node_instance3)
			
			
	#%WinLoseBox.add_child(circle_node_instance)
	#await get_tree().process_frame
	##  next line positions the WinLoseBox HBoxContainer appropriately so that it will be centered with three elements
	#%WinLoseBox.position.x = ((screensize.size.x - (3 * circle_node_instance.size.x) - (%WinLoseBox.get_theme_constant("separation") * 2)))/2
	#
	#await get_tree().process_frame
	#%WinLoseBox.add_child(circle_node_instance2)
	#await get_tree().create_timer(1.0).timeout
	#await get_tree().process_frame
	#%WinLoseBox.add_child(circle_node_instance3)
	#print(circle_node)


	
	
			
		
	
	pass


func next_round_bringer():
	await get_tree().create_timer(3.0).timeout
	var tween = create_tween()
	tween.parallel().tween_property(fade_overlay, "modulate:a", 0, 1.5)
	
	
	
	
func fade_in_particles():
	var tween = create_tween()
	# Animate from transparent to opaque
	tween.tween_property(particles, "modulate:a", 1, 5)
	
func fade_in(duration: float = 1.0):
	#fade_overlay.color = color
	game_over.add_theme_font_size_override("font_size",font_size)
	print("fade in worked")
	
	var tween = create_tween()
	# Animate from transparent to opaque
	tween.parallel().tween_property(fade_overlay, "modulate:a", 1, 1.5)
	tween.parallel().tween_property(game_over, "modulate:a", 1, 1.5)
	
	
# Call this to fade the screen FROM a color (to transparent)
func fade_out(duration: float = 1.0):
	var tween = create_tween()
	# Animate from opaque to transparent
	tween.tween_property(fade_overlay, "modulate:a", 0.0, duration).from(1.0)

	await tween.finished
