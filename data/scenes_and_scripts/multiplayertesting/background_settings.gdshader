// A shader that applies a subtle, surreal, and glitchy flicker effect.
// Ideal for 2D sprites or UI elements.
shader_type canvas_item;

// Tweak these parameters in the Inspector to control the effect's intensity.
uniform float aberration_amount : hint_range(0.0, 0.1, 0.001) = 0.003;
uniform float aberration_speed : hint_range(0.0, 20.0, 0.1) = 5.0;
uniform float aberration_randomness : hint_range(0.0, 1.0, 0.01) = 0.5; // NEW: How much random jitter to add to aberration
uniform float jitter_frequency : hint_range(0.0, 50.0, 0.1) = 15.0;
uniform float jitter_magnitude : hint_range(0.0, 0.1, 0.001) = 0.005;
uniform float jitter_rarity : hint_range(0.9, 1.0, 0.001) = 0.95; // Higher values make jitter happen less often
uniform float flicker_intensity : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float flicker_density : hint_range(0.0, 50.0, 0.1) = 10.0; // Controls vertical density of flicker lines
uniform float flicker_threshold : hint_range(0.0, 1.0, 0.01) = 0.8; // Higher values make flicker lines rarer

// A simple pseudo-random function.
float random(vec2 uv) {
	return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	// -- 1. Chromatic Aberration --
	// Create small, random offsets for the red and blue channels based on time.
	float base_aberration = sin(TIME * aberration_speed) * aberration_amount;
	// Add a random, jerky offset that changes at a different frequency.
	float random_jerk = (random(vec2(floor(TIME * 15.0), 2.0)) - 0.5) * 2.0; // random value between -1.0 and 1.0
	float random_offset = random_jerk * aberration_amount * aberration_randomness;
	float aberration_offset = base_aberration + random_offset;

	vec4 red_channel = texture(TEXTURE, UV + vec2(aberration_offset, 0.0));
	vec4 blue_channel = texture(TEXTURE, UV - vec2(aberration_offset, 0.0));
	vec4 green_channel = texture(TEXTURE, UV); // Green channel stays in the middle.
	
	// -- 2. UV Jitter --
	// Create a new UV coordinate set that will be distorted.
	vec2 jitter_uv = UV;
	// Use time to decide WHEN to glitch. Multiplying by frequency makes it faster.
	// The `step` function creates a sharp on/off effect.
	float jitter_trigger = step(jitter_rarity, sin(TIME * jitter_frequency));
	
	if (jitter_trigger > 0.0) {
		// If triggered, apply a random, small offset to the UVs.
		// Multiplying by magnitude controls how far the image jumps.
		jitter_uv += (random(UV + TIME) - 0.5) * jitter_magnitude;
	}

	// -- 3. Combine Effects & Add Flicker --
	// Sample the texture with the potentially jittered UVs.
	vec4 jittered_color = texture(TEXTURE, jitter_uv);

	// Combine the chromatic aberration channels with the jittered base.
	vec4 final_color;
	final_color.r = texture(TEXTURE, jitter_uv + vec2(aberration_offset, 0.0)).r;
	final_color.g = jittered_color.g;
	final_color.b = texture(TEXTURE, jitter_uv - vec2(aberration_offset, 0.0)).b;
	final_color.a = green_channel.a;

	// -- 4. Line Flicker --
	// Create a random value based on the vertical position and time.
	float line_noise = random(vec2(UV.y * flicker_density, TIME));
	// Apply a subtle brightness reduction to random horizontal lines.
	final_color.rgb -= line_noise * flicker_intensity * step(flicker_threshold, line_noise);

	// Set the final output color.
	COLOR = final_color*COLOR;
}

