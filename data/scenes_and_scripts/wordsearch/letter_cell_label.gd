extends Label

# Signals to notify the main script about interactions.
signal drag_started(cell)
signal mouse_entered_cell(cell)

const HOVER_COLOR = Color.DARK_GRAY # Really only used for testing on PC, not going to happen on phone

func _gui_input(event: InputEvent) -> void:
	# A drag starts when the mouse button or a finger is pressed down on this cell.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		emit_signal("drag_started", get_parent())
		get_viewport().set_input_as_handled() # Prevent event from propagating
	
	if event is InputEventScreenTouch and event.is_pressed():
		emit_signal("drag_started", get_parent())
		get_viewport().set_input_as_handled()
		
func _ready() -> void:
	# Connect mouse enter/exit signals for hover effect.
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

# --- Signal Handlers for Hover Effect ---

func _on_mouse_entered() -> void:
	# Let the main script know the mouse/finger is over this cell.
	emit_signal("mouse_entered_cell", get_parent())
	
	# Also provide a simple visual hover effect if not highlighted.
	if not get_parent().is_found and not get_parent().is_found_by_opponent and get_parent().color_rect.color == Globals.CELL_BACKGROUND_COLOR:
		get_parent().color_rect.color = HOVER_COLOR

func _on_mouse_exited() -> void:
	# Revert hover effect if not part of a final selection.
	if not get_parent().is_found and get_parent().color_rect.color == HOVER_COLOR:
		get_parent().color_rect.color = Globals.CELL_BACKGROUND_COLOR
