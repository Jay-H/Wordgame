# WaveAnimationResource.gd
extends CellAnimationResource
class_name DefaultWaveAnimation

# Export properties specific to the wave animation
@export var peak_scale: float = 1.2
@export var single_cell_duration: float = 0.3 # Time for one cell to scale up and down
@export var delay_per_cell: float = 0.1 # Delay between each cell's animation start

# This method implements the animation logic for the wave effect.
# It overrides the abstract apply_animation method from the base class.
func apply_animation(cells_to_animate: Array[LetterCell]) -> void:
	# Loop through each cell in the found word
	for i in range(cells_to_animate.size()):
		var cell = cells_to_animate[i]
		
		# Create a new tween specifically for this cell.
		var tween = cell.create_tween()
		
		# Ensure steps within this cell's tween are sequential (scale up, then scale down)
		tween.set_parallel(false) 
		
		# Calculate the staggered delay for this cell based on its index in the word
		var delay = i * delay_per_cell
		
		# Animate: Scale up
		tween.tween_interval(delay) # Apply the staggered delay before starting animation
		tween.tween_property(cell, "scale", Vector2(peak_scale, peak_scale), single_cell_duration / 2.0)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_BACK) # TRANS_BACK for a slight overshoot/bounce
		
		# Animate: Scale back down
		tween.tween_property(cell, "scale", Vector2(1.0, 1.0), single_cell_duration / 2.0)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_SINE) # TRANS_SINE for a smooth return
