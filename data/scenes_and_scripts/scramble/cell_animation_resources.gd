extends Resource
class_name CellAnimationResource

# This resource acts as an abstract base class for all cell animations.
# It defines the interface (apply_animation method) that all concrete animation
# resources should implement. It has no export properties or animation logic itself.

# All concrete animation resources (e.g., WaveAnimationResource) will extend this
# and implement their specific animation logic and export their unique parameters.

func apply_animation(cells_to_animate: Array[LetterCell]) -> void:
	# This method is intended to be overridden by derived classes.
	# If this base method is called, it indicates a concrete animation resource
	# was not properly assigned or its apply_animation was not overridden.
	push_error("Error: apply_animation method called on base CellAnimationResource. This method must be overridden in derived animation resources.")
