extends ColorRect


# --- Step 1: Create a "Proxy" Variable ---
# This variable will be animated by our tween because it's simple and easy to access.
# We give it an initial value that matches the noise resource's default.
var _noise_frequency_proxy: float = 0.01

# We'll also store a reference to the noise resource to avoid fetching it every frame.
var _fast_noise_lite_resource: FastNoiseLite

func _ready():
	# --- Step 2: Get and Store a Reference to the Deeply Nested Resource ---
	# It's more efficient to get this once and store it.
	
	if material and material.get_shader_parameter("distortion_map") is NoiseTexture2D:
		var noise_texture = material.get_shader_parameter("distortion_map")
		if noise_texture.noise is FastNoiseLite:
			_fast_noise_lite_resource = noise_texture.noise
			# Sync our proxy with the real starting value.
			_noise_frequency_proxy = _fast_noise_lite_resource.frequency
		else:
			print("Error: Noise resource is not a FastNoiseLite.")
			return
	else:
		print("Error: Material or distortion_map not set up correctly.")
		return
		
	# --- Step 3: Animate the Proxy Variable ---
	# Create a tween to make the noise frequency pulse back and forth.
	var tween = create_tween().set_loops()
	#tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	# Notice we are tweening "_noise_frequency_proxy" on `self`.
	# This is easy for the tween to do.
	tween.tween_property(self, "_noise_frequency_proxy", 0, 10) # High frequency (small details)
	tween.tween_property(self, "_noise_frequency_proxy", 1, 10) # Low frequency (large blobs)


func _process(delta):
	# --- Step 4: Apply the Proxy Value to the Real Property Every Frame ---
	# If our reference to the resource is valid...
	if is_instance_valid(_fast_noise_lite_resource):
		# ...manually set the real frequency to match our animated proxy variable.
		_fast_noise_lite_resource.frequency = _noise_frequency_proxy
		
