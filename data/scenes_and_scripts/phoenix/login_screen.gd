extends Control
@onready var main_menu = get_parent()
var duration = 2
var connected_to_server = false
var shader_array = []
func _ready():
	
	%BottomParticles.emitting = false
	await %SplashScreen.fade_process()
	%SplashScreen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%TextureRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_in(duration)

func fade_in(duration):
	%BottomParticles.emitting = true
	shader_array = [%Login, %CreateAccount, %ChrisLabel]
	for i in shader_array:
		i.material.set_shader_parameter("light_radius_pixels", 0)
		i.material.set_shader_parameter("softness_pixels", 0)
	%EmailBox.modulate = Color.TRANSPARENT
	%PasswordBox.modulate = Color.TRANSPARENT
	
	var tween = create_tween()
	tween.tween_property(%CanvasModulate, "color", Color.WHITE, duration)
	for i in shader_array:
		var tween2 = create_tween()
		tween2.parallel().tween_method(func(a):
			i.material.set_shader_parameter("light_radius_pixels", a),
			0, 340, 2)
		tween2.parallel().tween_method(func(a):
			i.material.set_shader_parameter("softness_pixels", a),
			0, 340, 2)
	for i in [%EmailBox, %PasswordBox]:
		var tween3 = create_tween()
		tween3.tween_property(i, "modulate", Color.WHITE, 4)
	
func _process(_delta):

	pass

func _on_login_pressed() -> void:
	%login_btn.play()
	if connected_to_server:
		var email = %EmailBox.text
		var password = %PasswordBox.text
		if %EmailBox.text == "":
			shake_effect(%EmailBox)
		if %PasswordBox.text == "":
			shake_effect(%PasswordBox)
		if %EmailBox.text != "" and %PasswordBox.text != "":
			Firebase.Auth.login_succeeded.connect(main_menu._verify_not_already_logged_in_firebase)
			Firebase.Auth.login_failed.connect(_incorrect_login)
			Firebase.Auth.login_with_email_and_password(email, password)
			pass
	else:
		print("you can't login until connected to game server")

func _already_logged_in():
	%EmailBox.text = "Already Logged In!"
	shake_effect(%EmailBox)
	shake_effect(%PasswordBox)
	pass

func _incorrect_login(code, message):
	print(code)
	print(message)
	if message == "INVALID_EMAIL":
		%EmailBox.text = "Invalid Email!"
		shake_effect(%EmailBox)
		pass
	if message == "INVALID_LOGIN_CREDENTIALS":
		%EmailBox.text = "Check Password?"
		shake_effect(%EmailBox)
		pass	
	pass

func _on_create_account_pressed() -> void:
	%create_account_btn.play()
	if %EmailBox.text == "":
		shake_effect(%EmailBox)
	if %PasswordBox.text == "":
		shake_effect(%PasswordBox)
	if %EmailBox.text != "" and %PasswordBox.text != "":
		main_menu._create_account(%EmailBox.text, %PasswordBox.text)


func fade_out():
	var tween = create_tween()
	var tween_text = create_tween()
	var tween_particles = create_tween()
	tween_text.tween_property(%FirstScreenControl, "modulate", Color.TRANSPARENT, 1)
	tween.tween_property(%ColorRect, "color", Color.WHITE, 1)
	tween.parallel().tween_property(%LoginScreenMusic, "volume_linear", 0, 1)
	tween_particles.tween_property(%BottomParticles, "modulate", Color.TRANSPARENT, 1)
	await tween.finished
	await tween_particles.finished
	return
	
## Shakes the target control node and flashes its font color to red.
## Ideal for giving feedback on invalid input in a LineEdit or TextEdit.
## Also using this to change color of the background temporarily
func shake_effect(node: Control, duration: float = 0.5, strength: float = 16.0):
	# A running tween on the same property will be interrupted and replaced.
	var tween = get_tree().create_tween()

	# Bind the tween to the node to ensure it's cleaned up if the node is freed.
	tween.bind_node(node)
	# Use a bouncy transition for a more impactful feel.
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)

	# --- Part 1: Color Flash ---
	# Save the original color to restore it later.
	var original_color = node.get_theme_color("font_placeholder_color")
	# Immediately override the color to red.
	node.add_theme_color_override("font_placeholder_color", Color(0.341, 0.1, 0.07, 0.718))

	%BottomParticles.modulate = Color.RED
	
	# --- Part 2: Shake Motion ---
	var initial_x = node.position.x
	var shake_count = 6 # The number of back-and-forth movements
	var time_per_shake = duration / float(shake_count + 1)

	# Chain several small movements together to create the shake.
	for i in range(shake_count):
		# The shake strength diminishes over time.
		var current_strength = strength * (1.0 - float(i) / shake_count)
		# Alternate direction.
		var direction = 1 if i % 2 == 0 else -1
		
		tween.tween_property(
			node, "position:x", initial_x + current_strength * direction, time_per_shake
		)

	# --- Part 3: Reset State ---
	# Chain a final property tween to return the node to its starting position.
	tween.tween_property(node, "position:x", initial_x, time_per_shake)
	await tween.finished
	# After all movement is finished, chain a callback to remove the color override,
	# which restores the original font color.
	tween.tween_callback(func(): node.remove_theme_color_override("font_placeholder_color"))
	%BottomParticles.modulate = Color(1,1,1,1)


func _on_quick_login_a_pressed() -> void:
	%EmailBox.text = "christopherhaddad12@gmail.com"
	%PasswordBox.text = "supersonic"
	_on_login_pressed()
	pass # Replace with function body.


func _on_quick_login_b_pressed() -> void:
	%EmailBox.text = "john@hotmail.com"
	%PasswordBox.text = "supersonic"
	_on_login_pressed()
	pass # Replace with function body.


func _on_quick_login_c_pressed() -> void:
	%EmailBox.text = "a@hotmail.com"
	%PasswordBox.text = "supersonic"
	_on_login_pressed()
	pass # Replace with function body.


func _on_quick_login_d_pressed() -> void:
	%EmailBox.text = "b@hotmail.com"
	%PasswordBox.text = "supersonic"
	_on_login_pressed()
	pass # Replace with function body.

func _on_wstest_pressed() -> void:
	Globals.WSTEST = true
	get_tree().change_scene_to_file("res://data/scenes_and_scripts/wordsearch/WordSearch.tscn")
	pass # Replace with function body.
