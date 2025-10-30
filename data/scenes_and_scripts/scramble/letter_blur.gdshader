// A simple Box Blur shader for 2D canvas items.
// This version correctly handles alpha and works with the modulate property.
shader_type canvas_item;

// The uniform "blur_amount" will appear in the Inspector when you
// edit the ShaderMaterial. It controls the intensity of the blur.
uniform float blur_amount : hint_range(0.0, 5.0) = 1.0;


void fragment() {
	vec4 accumulated_color = vec4(0.0);
	float total_alpha = 0.0;
	
	const int kernel_size = 5;
	const int kernel_half_size = kernel_size / 2;

	// Loop through a grid of neighboring pixels.
	for (int i = -kernel_half_size; i <= kernel_half_size; i++) {
		for (int j = -kernel_half_size; j <= kernel_half_size; j++) {
			
			vec2 offset = vec2(float(i), float(j)) * TEXTURE_PIXEL_SIZE * blur_amount;
			vec4 sample = texture(TEXTURE, UV + offset);
			
			// --- FIX for WHITE LETTERS ---
			// Weight the color by its alpha value. This means the color of
			// fully transparent pixels (alpha=0) won't bleed into the result.
			accumulated_color.rgb += sample.rgb * sample.a;
			total_alpha += sample.a;
		}
	}
	
	vec4 final_color;
	if (total_alpha > 0.0) {
		// Calculate the average color and alpha based on the weighted sum.
		final_color.rgb = accumulated_color.rgb / total_alpha;
		final_color.a = total_alpha / float(kernel_size * kernel_size);
	} else {
		// If all surrounding pixels were transparent, this pixel should be too.
		final_color = vec4(0.0, 0.0, 0.0, 0.0);
	}
	
	// --- FIX for MODULATE ---
	// Multiply our final blurred color by the node's vertex color (which
	// includes the modulate property). This tints our result correctly.
	COLOR = final_color * COLOR;
}

