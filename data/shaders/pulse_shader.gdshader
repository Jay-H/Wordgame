shader_type canvas_item;
render_mode blend_mix;

uniform float progress = 0.0;
uniform sampler2D gradient_tex;

// Define overall thickness (e.g., 30% of line length)
uniform float total_pulse_width = 0.3; 
// Define the fraction of the total width that should be the fade (e.g., 30% fade, 70% solid)
uniform float fade_fraction = 0.3; 

void fragment() {
	// UV.x is the normalized distance along the Line2D path (0.0 to 1.0).
	float line_progress = clamp(UV.x, 0.0, 1.0); 

	float fade_length = total_pulse_width * fade_fraction;
	float solid_length = total_pulse_width - fade_length;
    
    // Define the start and end points of the entire pulse window based on the animated 'progress'
    float pulse_end = progress;                  // Leading edge (where the pulse stops)
    float pulse_start = progress - total_pulse_width; // Trailing edge (where the pulse begins)
    float fade_point = progress - fade_length;       // Point where the solid white ends

    float alpha_val = 0.0;
    
    // 1. Check if the fragment is within the solid white region
    if (line_progress >= pulse_start && line_progress < fade_point) {
        // We are in the solid white part of the pulse.
        alpha_val = 1.0;
    }
    
    // 2. Check if the fragment is within the gradient region
    if (line_progress >= fade_point && line_progress < pulse_end) {
        // Use smoothstep to create a perfect gradient ramp from 1.0 down to 0.0.
        // The ramp goes from 1.0 at fade_point to 0.0 at pulse_end.
        // We use an inverse smoothstep to make it fade out (1.0 to 0.0).
        // The value should be 1.0 at fade_point and 0.0 at pulse_end.
        
        // This calculates the distance of the fragment into the fade zone (0.0 to fade_length)
        float distance_into_fade = line_progress - fade_point;
        
        // Normalize the distance (0.0 to 1.0) for the fade length
        float normalized_fade = distance_into_fade / fade_length;

        // Since we want the color to fade from white (1.0) to transparent (0.0)
        // we use (1.0 - normalized_fade)
        alpha_val = normalized_fade;
    }
    
    // Read the color
	vec4 color = texture(gradient_tex, vec2(line_progress, 0.5));
	
	// Apply the final alpha
	COLOR = color;
	COLOR.a *= alpha_val;
}