// Godot Shader for a glitchy, fuzzy, fluctuating sun.
// Combines a procedural circle generation with surreal glitch effects.
shader_type canvas_item;

// --- Sun Uniforms ---
uniform vec4 sun_color : source_color = vec4(1.0, 0.9, 0.5, 1.0); // The core color of the sun
uniform float fluctuation_speed : hint_range(0.1, 5.0) = 0.8;    // How fast the brightness flickers
uniform float edge_softness : hint_range(0.1, 1.0) = 0.5;         // How blurry the edge is
uniform float noise_intensity : hint_range(0.0, 0.2) = 0.05;      // The strength of the surface distortion

// --- Glitch Uniforms ---
uniform float aberration_amount : hint_range(0.0, 0.1, 0.001) = 0.003;
uniform float aberration_speed : hint_range(0.0, 20.0, 0.1) = 5.0;
uniform float aberration_randomness : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float jitter_frequency : hint_range(0.0, 50.0, 0.1) = 15.0;
uniform float jitter_magnitude : hint_range(0.0, 0.1, 0.001) = 0.005;
uniform float jitter_rarity : hint_range(0.9, 1.0, 0.001) = 0.95;
uniform float flicker_intensity : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float flicker_density : hint_range(0.0, 50.0, 0.1) = 10.0;
uniform float flicker_threshold : hint_range(0.0, 1.0, 0.01) = 0.8;

// A simple pseudo-random function.
float random(vec2 uv) {
	return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Helper function to calculate the sun's color and alpha at a specific UV coordinate.
// This allows us to re-use the logic for chromatic aberration.
vec4 calculate_sun_at_uv(vec2 p_uv) {
	vec2 centered_uv = p_uv - vec2(0.5);
	float distance_from_center = length(centered_uv);
	
	float time_wave = sin(TIME * fluctuation_speed);
	float flicker = time_wave * 0.1 + 0.9;
	
	float surface_noise = random(p_uv + vec2(TIME * 0.1, 0.0)) * noise_intensity;
	float circle_edge = 0.5 - surface_noise;
	
	float alpha = 1.0 - smoothstep(circle_edge - edge_softness, circle_edge, distance_from_center);
	
	vec4 col;
	col.rgb = sun_color.rgb * flicker;
	col.a = alpha;
	return col;
}

void fragment() {
	// -- 1. Calculate Glitch Offsets --
    // Chromatic Aberration offset
	float base_aberration = sin(TIME * aberration_speed) * aberration_amount;
	float random_jerk = (random(vec2(floor(TIME * 15.0), 2.0)) - 0.5) * 2.0;
	float random_offset = random_jerk * aberration_amount * aberration_randomness;
	float aberration_offset = base_aberration + random_offset;

    // UV Jitter calculation
	vec2 jitter_uv = UV;
	float jitter_trigger = step(jitter_rarity, sin(TIME * jitter_frequency));
	if (jitter_trigger > 0.0) {
		jitter_uv += (random(UV + TIME) - 0.5) * jitter_magnitude;
	}

    // -- 2. Procedurally Generate Color Channels --
    // Instead of sampling a texture, we run our procedural sun generation
    // three times with the different offsets to simulate aberration.
    vec4 color_g = calculate_sun_at_uv(jitter_uv); // Green channel (center)
    vec4 color_r = calculate_sun_at_uv(jitter_uv + vec2(aberration_offset, 0.0)); // Red channel
    vec4 color_b = calculate_sun_at_uv(jitter_uv - vec2(aberration_offset, 0.0)); // Blue channel
    
    // -- 3. Combine Channels --
    vec4 final_color;
    final_color.r = color_r.r;
    final_color.g = color_g.g;
    final_color.b = color_b.b;
    final_color.a = color_g.a; // Use the alpha from the central, un-shifted channel

    // -- 4. Apply Line Flicker on top --
	float line_noise = random(vec2(UV.y * flicker_density, TIME));
	final_color.rgb -= line_noise * flicker_intensity * step(flicker_threshold, line_noise);

	// Set the final output color.
	COLOR = final_color;
}

