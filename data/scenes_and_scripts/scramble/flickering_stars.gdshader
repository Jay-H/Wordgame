// Godot Shader for a dynamic, flickering starfield (Version 2).
// Features improved density control, more size variation, and multiple colors.
//
// How to use:
// 1. Apply to a full-screen ColorRect.
// 2. Adjust uniforms in the Inspector. For a very dense field, increase
//    both `star_density` and `star_spawn_chance`.
// 3. Control `parallax_offset` from a script for movement.

shader_type canvas_item;

// --- Starfield Uniforms ---
uniform float star_density : hint_range(50.0, 500.0) = 150.0;     // The number of grid cells (potential star locations)
uniform float star_spawn_chance : hint_range(0.0, 0.1, 0.001) = 0.02; // Chance a star will appear in a cell (higher is more)
uniform float flicker_speed : hint_range(0.1, 10.0) = 3.0;
uniform float flicker_intensity : hint_range(0.0, 1.0) = 0.7;
uniform vec2 parallax_offset = vec2(0.0, 0.0);

// --- Star Color Uniforms ---
uniform vec4 star_color_a : source_color = vec4(1.0, 1.0, 0.9, 1.0);     // Primary star color (e.g., white/yellow)
uniform vec4 star_color_b : source_color = vec4(0.7, 0.8, 1.0, 1.0);     // Secondary star color (e.g., blue)
uniform float color_variation_chance : hint_range(0.0, 1.0) = 0.3;      // Chance for a star to be color B

// --- Star Size Uniforms ---
uniform float min_star_size : hint_range(0.0, 0.1, 0.001) = 0.002;
uniform float max_star_size : hint_range(0.0, 0.1, 0.001) = 0.025;
uniform float size_distribution : hint_range(1.0, 10.0) = 5.0; // Higher values = more small stars and fewer large ones

// A simple pseudo-random function.
float random(vec2 uv) {
	return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec2 parallax_uv = UV + parallax_offset;
	vec2 grid_uv = floor(parallax_uv * star_density);
	vec2 cell_uv = fract(parallax_uv * star_density);

	float spawn_seed = random(grid_uv);

	vec4 final_color = vec4(0.0, 0.0, 0.0, 0.0);

	// The new density check. A star appears if its random seed is
	// less than the spawn chance you set in the inspector.
	if (spawn_seed < star_spawn_chance) {
		float time_offset = spawn_seed * 100.0;
		float flicker = (sin((TIME * flicker_speed) + time_offset) + 1.0) * 0.5;
		flicker = mix(1.0 - flicker_intensity, 1.0, flicker);

        // --- New Size Calculation ---
        // We use a separate random seed for size to decouple it from spawning.
        // The pow() function skews the random values, creating our size distribution.
		float size_seed = pow(random(grid_uv + 0.5), size_distribution);
        // We mix between the min and max size based on this skewed seed.
		float star_size = mix(min_star_size, max_star_size, size_seed);
		
		float distance_from_center = length(cell_uv - vec2(0.5));
		float star_mask = 1.0 - smoothstep(star_size, star_size + 0.01, distance_from_center);
		
		// --- New Color Selection ---
        // Use another unique seed for color selection.
		float color_seed = random(grid_uv + 0.25);
        // Mix between the two colors. step() acts like an if-statement, returning 0.0 or 1.0.
		vec3 chosen_star_color = mix(star_color_a.rgb, star_color_b.rgb, step(1.0 - color_variation_chance, color_seed));

		final_color.rgb = chosen_star_color * star_mask * flicker;
		final_color.a = star_mask;
	}

	COLOR = final_color;
}

