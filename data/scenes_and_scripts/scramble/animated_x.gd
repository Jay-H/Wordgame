# AnimatedX.gd
extends Control

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

# Get a reference to the AnimationPlayer node.
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# This function is called when the node enters the scene tree.
func _ready() -> void:
	position.x += %Line1.width
	position.y += %Line1.width
	pivot_offset = size/2
	# Play the "draw_x" animation we created.
	
func start_animation():
	animation_player.play("draw_x")
	await get_tree().create_timer(1.0).timeout
	start_pulsing_animation()
	
# You could also connect this to a button press or another event.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Pressing Space or Enter
		animation_player.play("draw_x")

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
