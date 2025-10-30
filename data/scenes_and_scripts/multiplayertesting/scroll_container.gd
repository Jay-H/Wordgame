# SnappingSwipeContainer.gd
# This version uses a GridContainer for a multi-column, snapping layout.

extends ScrollContainer

signal picture_selected(texture: Texture2D)

# --- Script Variables ---
@export var image_paths: Array[String]

# NEW: Define the number of columns for the grid.
@export var columns: int = 2

@export var snap_speed: float = 0.2
@export var image_size: Vector2 = Vector2(250, 250)

# CHANGED: The reference is now to a GridContainer.
@onready var grid_container: GridContainer = $PictureBox

var is_dragging: bool = false
var was_dragging_this_frame: bool = false


func _ready() -> void:
	# NEW: Set the number of columns on the GridContainer node.
	grid_container.columns = columns
	populate_images()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not event.is_pressed():
		is_dragging = false
		
	if event is InputEventScreenDrag:
		is_dragging = true


func _process(_delta: float) -> void:
	if was_dragging_this_frame and not is_dragging:
		snap_to_closest()
		
	was_dragging_this_frame = is_dragging


func populate_images() -> void:
	# This function works the same, but adds children to a GridContainer.
	for child in grid_container.get_children():
		child.queue_free()

	for image_path in image_paths:
		if image_path.is_empty():
			print("Warning: An empty image path was found. Skipping.")
			continue
		
		var panel = Control.new()
		panel.custom_minimum_size = image_size
		
		var texture_rect = TextureRect.new()
		texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		var texture = load(image_path)
		texture_rect.gui_input.connect(_on_picture_gui_input.bind(texture))
		
		texture_rect.texture = texture
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		panel.add_child(texture_rect)
		grid_container.add_child(panel)


func _on_picture_gui_input(event: InputEvent, texture: Texture2D):
	# This function requires no changes.
	var is_click = event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT
	var is_tap = event is InputEventScreenTouch and event.is_pressed()
	if (is_click or is_tap) and not is_dragging:
		emit_signal("picture_selected", texture)
		print("signal emitted")


# CHANGED: The snapping logic is now based on rows, not individual items.
func snap_to_closest() -> void:
	var child_count = grid_container.get_child_count()
	if child_count == 0:
		return

	# Get the height of a single image panel.
	var child_height = grid_container.get_child(0).size.y
	# CHANGED: Get the vertical separation for the GridContainer.
	var separation = grid_container.get_theme_constant("v_separation", "GridContainer")
	var row_full_height = child_height + separation
	
	# NEW: Calculate the total number of rows.
	var number_of_rows = ceil(float(child_count) / columns)
	
	var container_center = size.y / 2.0
	var current_scroll = scroll_vertical
	
	# Calculate which ROW index we are closest to.
	var target_row_index = round((current_scroll + container_center - (child_height / 2.0)) / row_full_height)

	# CHANGED: Clamp the index to the valid range of ROWS.
	target_row_index = clamp(target_row_index, 0, number_of_rows - 1)
	
	# Calculate the target scroll position to center the target row.
	var target_scroll = (row_full_height * target_row_index) - container_center + (child_height / 2.0)
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scroll_vertical", target_scroll, snap_speed)
