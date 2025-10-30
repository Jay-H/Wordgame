// Godot Shader for a surreal, dreamy overlay effect.
//
// How to use:
// 1. Apply this shader to a node that displays an image, like a
//    TextureRect or Sprite2D.
// 2. The shader will automatically affect the texture on that node.
// 3. Adjust the uniforms in the Inspector to customize the look. For a
//    subtle effect, start with low values for aberration and wave amplitude.

shader_type canvas_item;

// --- Effect Uniforms ---
uniform float aberration_amount : hint_range(0.0, 0.01, 0.0001) = 0.001; // How much the colors separate at the edges
uniform float bloom_threshold : hint_range(0.0, 1.0) = 0.7;             // Brightness level where bloom starts
uniform float bloom_intensity : hint_range(0.0, 5.0) = 1.5;             // How strong the glow is
uniform float fade: hint_range(0.0, 5.0) = 1;
// --- Distortion Uniforms ---
uniform float wave_speed : hint_range(0.1, 5.0) = 0.5;      // How fast the image distorts
uniform float wave_frequency : hint_range(1.0, 20.0) = 8.0; // How many waves are on screen
uniform float wave_amplitude : hint_range(0.0, 0.02, 0.001) = 0.005; // How much the image distorts

void fragment() {
	// --- Wavy Distortion ---
	// Create a gentle, time-based distortion using sine waves.
	// This makes the UV coordinates ripple, giving the image a "breathing" effect.
	vec2 distorted_uv = UV;
	float wave_effect = sin(UV.y * wave_frequency + TIME * wave_speed) * wave_amplitude;
	distorted_uv.x += wave_effect;

	// --- Chromatic Aberration ---
	// Sample the texture three times with slightly offset UVs for each color channel.
	// This mimics the color fringing of a real-world camera lens.
	vec4 original_color = texture(TEXTURE, distorted_uv);
	float red   = texture(TEXTURE, distorted_uv + vec2(aberration_amount, 0.0)).r;
	float green = texture(TEXTURE, distorted_uv).g;
	float blue  = texture(TEXTURE, distorted_uv - vec2(aberration_amount, 0.0)).b;
	
	vec3 final_color = vec3(red, green, blue);

	// --- Soft Bloom ---
	// Calculate the brightness (luminance) of the original pixel.
	float brightness = dot(original_color.rgb, vec3(0.2126, 0.7152, 0.0722));
	brightness -= fade;
	// If the pixel is brighter than the threshold, add a glowing effect.
	// smoothstep creates a soft falloff for the glow.
	float bloom_factor = smoothstep(bloom_threshold, bloom_threshold + 0.2, brightness);
	vec3 bloom_color = original_color.rgb * bloom_intensity * bloom_factor;
	
	// Combine the base color with the bloom effect.
	final_color += bloom_color;

	// Set the final color, preserving the original alpha.
	COLOR = vec4(final_color, original_color.a);
}
