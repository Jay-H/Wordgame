extends Control

var particle_fired = false

# Constants for clarity and easy adjustment
const MAX_EXPERIENCE = 100.0
const SCALE_FACTOR = 5.0

func _ready():
	var experience_before
	var experience_after # Lower value to simulate a level up
	
func _process(_delta):
	pass

func setup(experience_before):
	if $Line2D.points.size() < 2:
		$Line2D.points = [Vector2.ZERO, Vector2.ZERO]
	
	var start_x = experience_before * SCALE_FACTOR
	$Line2D.points[1] = Vector2(start_x, 0)
	
# This helper function is called by the tween to update the line's position
func _update_line_point(new_position: Vector2):
	var current_points = $Line2D.points
	current_points[1] = new_position
	if new_position.x == 500:
		if particle_fired == false:
			particle_fired = true
			%GPUParticles2D.emitting = true
			
	
	$Line2D.points = current_points

func animate(experience_before, experience_after):
	var tween = create_tween()

	var start_pos = Vector2(experience_before * SCALE_FACTOR, 0)
	var final_pos = Vector2(experience_after * SCALE_FACTOR, 0)
	
	# Check for a level-up scenario
	if experience_after < experience_before:
		# --- Level Up Animation ---
		var max_pos = Vector2(MAX_EXPERIENCE * SCALE_FACTOR, 0)
		var zero_pos = Vector2.ZERO
		
		# Make the tweens run one after another, not at the same time
		tween.set_parallel(false)
		
		# 1. Animate from the starting XP up to 100
		tween.tween_method(_update_line_point, start_pos, max_pos, 1)
		
		# 2. Instantly snap the bar to 0. A callback runs once between tweens.
		tween.tween_callback(_update_line_point.bind(zero_pos))
		
		# 3. Animate from 0 to the final XP value
		tween.tween_method(_update_line_point, zero_pos, final_pos, 1)
		
	else:
		# --- Normal XP Gain Animation ---
		tween.tween_method(_update_line_point, start_pos, final_pos, 2)
