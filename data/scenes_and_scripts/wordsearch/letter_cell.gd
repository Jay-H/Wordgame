class_name LetterCell
extends Control

# Properties to store the cell's state.
var letter: String = ""
var grid_position: Vector2i = Vector2i.ZERO
var is_found: bool = false
var is_found_by_opponent: bool = false

@onready var label: Label = $Label
@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	# Set a minimum size for the cell to ensure it's visible in the grid.
	custom_minimum_size = Vector2(120, 120)
	
	unhighlight()
	
	# Defer setting pivot_offset to ensure 'size' is valid after layout calculations.
	# This function will be called once the node is ready and its size is determined.
	call_deferred("set_pivot_to_center")

func set_pivot_to_center() -> void:
	# Ensure size is valid before calculating pivot.
	if size != Vector2.ZERO:
		pivot_offset = size / 2.0
	else:
		# Fallback/warning if size is still zero for some reason (shouldn't happen with custom_minimum_size)
		print("WARNING: LetterCell size is zero when setting pivot offset. Cannot set pivot to center.")

# --- Public Methods ---

func set_letter(p_letter: String) -> void:
	letter = p_letter
	label.text = letter

func highlight(color: Color) -> void:
	# Only apply temporary highlight if the cell is NOT already found
	if not is_found or not is_found_by_opponent:
		color_rect.color = color
		
func set_found(found: bool) -> void:
	is_found = found
	if is_found:
		color_rect.color = Globals.CELL_FOUND_COLOR
	else:
		color_rect.color = Globals.CELL_BACKGROUND_COLOR
		
func set_found_by_opponent():
	is_found_by_opponent = true
	color_rect.color = Globals.CELL_FOUND_BY_OPPONENT_COLOR

func unhighlight() -> void:
	# If the cell is found, it should remain the FOUND_COLOR.
	# Otherwise, revert to the DEFAULT_COLOR.
	if is_found:
		color_rect.color = Globals.CELL_FOUND_COLOR
	elif is_found_by_opponent:
		color_rect.color = Globals.CELL_FOUND_BY_OPPONENT_COLOR
	else:
		color_rect.color = Globals.CELL_BACKGROUND_COLOR
