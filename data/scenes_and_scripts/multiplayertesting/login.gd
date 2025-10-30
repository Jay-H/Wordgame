extends Control
var mainmenu
var new_valid_username


func _ready():
	mainmenu = get_parent()
	

func _on_check_availability_pressed() -> void:
	var username_attempt = %NewUsernameInput.text
	%NewUsernameInput.text = ""
	mainmenu.username_available_authenticator(username_attempt)
	
func make_password_chooser_available(username):
	new_valid_username = username
	%Available.text = "Available!"
	%Available.add_theme_color_override("font_color", Color.GREEN)
	%ChooseAPassword.visible = true
	%ChooseAUsername.visible = false
	%NewUsernameInput.visible = false
	%NewPasswordInput.visible = true
	%NewPasswordSubmit.visible = true

func unavailable():
	%Available.text = "Unavailable :("
	%Available.add_theme_color_override("font_color", Color.RED)

func _on_new_password_submit_pressed() -> void:
	var password = %NewPasswordInput.text
	%NewPasswordInput.text = ""
	mainmenu.password_registration(new_valid_username, password)
	%NewAccountScreen.queue_free()
	pass # Replace with function body.


func _on_submit_pressed() -> void:
	var username = %UsernameInput.text
	var password = %PasswordInput.text
	%UsernameInput.text = ""
	%PasswordInput.text = ""
	mainmenu.login_authenticator(username, password)
	pass # Replace with function body.


func _on_new_account_meta_clicked(meta: Variant) -> void:
	%NewAccountScreen.visible = true
	pass # Replace with function body.


func _on_back_button_pressed() -> void:
	%NewAccountScreen.visible = false
	pass # Replace with function body.


func _on_connect_pressed() -> void:
	mainmenu.connect_to_server()
	pass # Replace with function body.
