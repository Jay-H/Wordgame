# LetterLabel.gd (attached to the Label node inside OneLetter.tscn)
extends Label

# Define a custom signal that this Label will emit
# This signal will carry the text of the letter that was entered.
signal letter_mouse_entered(letter_text: String, global_position: Vector2, grid_index: int)


# This function is called when the node enters the Scene Tree.
func _ready():
	# Connect this Label's built-in mouse_entered signal to a method in THIS script.
	# The 'self' refers to this Label node.
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited) # Optional: if you want to know when mouse leaves


# This method will be called when the mouse cursor enters this Label's area.
func _on_mouse_entered():
	# You can change its color to highlight it
	add_theme_color_override("font_color", Color.YELLOW)
	
	# Emit your custom signal, passing relevant data
	# To get the grid_index, you'll need the parent (OneLetter instance)'s name.
	var parent_one_letter_node = get_parent() # This is the root of your OneLetter.tscn
	
	# Extract the index from the parent's name (e.g., "Label0" -> 0)
	var grid_index = -1
	if parent_one_letter_node and parent_one_letter_node.name.begins_with("Label"):
		var index_string = parent_one_letter_node.name.replace("Label", "")
		grid_index = index_string.to_int()

	print("Mouse entered letter: ", text, " at grid index: ", grid_index)
	
	# Emit the signal with the letter, its global position, and its grid index
	letter_mouse_entered.emit(text, global_position, grid_index)


# Optional: Method called when the mouse cursor leaves this Label's area.
func _on_mouse_exited():
	# Revert color when mouse leaves
	add_theme_color_override("font_color", Color.BLACK) # Or whatever default color you use
