# animated_circle.gd
# Attach this script to a Control node.
# The animation is now triggered by calling the start_animation() function.

extends Control

# --- Configuration ---
@export var circle_color: Color = Color.GREEN
@export var circle_radius: float = 150.0
@export var circle_width: float = 8.0
@export var draw_duration: float = 1.5
@export var pulse_duration: float = 0.2
@export var pulse_scale: float = 1.2

# --- Internal Variables ---
var _draw_progress: float = 0.0
var _is_drawing: bool = false # Changed: Defaults to false to prevent auto-start
var _has_pulsed: bool = false
var _tween: Tween

func _ready() -> void:
	# Set the minimum size and pivot point for the control node.
	# This part remains the same.
	custom_minimum_size = Vector2(circle_radius * 2, circle_radius * 2)
	set_pivot_offset(custom_minimum_size / 2)

# NEW: This is the function you will call from other scripts.
func start_animation() -> void:
	# Kill any previous tween to prevent conflicts if re-triggered.
	if _tween:
		_tween.kill()

	# --- Reset all state variables to their defaults ---
	scale = Vector2.ONE # Reset scale in case it was mid-pulse
	_draw_progress = 0.0
	_has_pulsed = false
	_is_drawing = true # This starts the drawing process in _process()

func _process(delta: float) -> void:
	# This block only runs if _is_drawing is true.
	if _is_drawing:
		_draw_progress += delta / draw_duration
		queue_redraw()

		if _draw_progress >= 1.0:
			_is_drawing = false
			_draw_progress = 1.0
			start_pulsing_animation()

func _draw() -> void:
	# This function remains the same.
	var angle_to = _draw_progress * TAU
	var center = size / 2.0
	draw_arc(center, circle_radius, 0, angle_to, 64, circle_color, circle_width)

func start_pulsing_animation() -> void:
	# This function remains mostly the same.
	if _has_pulsed:
		return
	_has_pulsed = true

	if _tween:
		_tween.kill()
	
	_tween = create_tween()

	# The animation sequence remains the same.
	_tween.tween_property(self, "scale", Vector2(pulse_scale, pulse_scale), pulse_duration)\
		 .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	_tween.tween_property(self, "scale", Vector2.ONE, pulse_duration)\
		 .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	_tween.tween_property(self, "scale", Vector2(pulse_scale, pulse_scale), pulse_duration)\
		 .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		 
	_tween.tween_property(self, "scale", Vector2.ONE, pulse_duration)\
		 .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
