shader_type canvas_item;

// Dreamy Aberration Shader for Godot
// Apply this to a Label or Sprite to create a soft, distorted, and chromatically aberrated effect.
// For the best effect, add a WorldEnvironment node to your scene and enable the "Glow" property.

// PARAMETERS (Adjust these in the Inspector under Shader Parameters)

// The main color of the text or sprite.
uniform vec4 base_color : source_color = vec4(0.8, 0.9, 1.0, 1.0);

// The brightness multiplier. Values > 1 will be picked up by a Glow/Bloom post-processing effect.
uniform float glow_intensity : hint_range(1.0, 15.0) = 3.0;

// Controls the speed of the gentle pulsing glow.
uniform float pulse_speed : hint_range(0.1, 10.0) = 1.0;

// Controls how much the glow dims and brightens during a pulse. 0 is no pulse, 1 is a full pulse.
uniform float pulse_depth : hint_range(0.0, 1.0) = 0.5;

// --- Optional Effects ---
// Controls the amount of chromatic aberration (color separation).
uniform float color_aberration : hint_range(0.0, 0.02) = 0.005;

// Controls the strength of the wavy "electrical interference" distortion effect.
uniform float distortion_amount : hint_range(0.0, 0.1) = 0.01;

// Controls the speed of the wavy distortion.
uniform float distortion_speed : hint_range(0.1, 10.0) = 1.2;


void fragment() {
    // --- Distortion ---
    // Create a time-based offset for a wavy, vertical distortion effect.
    vec2 distorted_uv = UV;
    float distortion_wave = sin(distorted_uv.y * 15.0 + TIME * distortion_speed) * distortion_amount;
    distorted_uv.x += distortion_wave;

    // --- Chromatic Aberration & Masking ---
    // Sample the alpha channel of the texture at different points. We'll use these to build the final shape.
    float alpha_mask_r = texture(TEXTURE, distorted_uv + vec2(color_aberration, 0.0)).a;
    float alpha_mask_g = texture(TEXTURE, distorted_uv).a;
    float alpha_mask_b = texture(TEXTURE, distorted_uv - vec2(color_aberration, 0.0)).a;

    // The final alpha is the combination of all channels, ensuring the shape is solid.
    float final_alpha = max(max(alpha_mask_r, alpha_mask_g), alpha_mask_b);

    // Only proceed if the pixel is visible.
    if (final_alpha > 0.0) {
        // --- Dreamy Pulse Logic ---
        // Create a smooth, slow-moving wave using sine.
        // The `0.5 + 0.5 *` part remaps sin's -1 to 1 range to a more useful 0 to 1 range.
        float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);

        // Apply the pulse depth to control how much the glow changes.
        float current_glow = glow_intensity * (1.0 - pulse_depth * pulse);

        // The final color is the base color, multiplied by the current pulsating glow.
        vec3 final_rgb = base_color.rgb * current_glow;

        // Construct the final color with separated channels based on our alpha masks to create the aberration effect.
        COLOR.r = final_rgb.r * alpha_mask_r;
        COLOR.g = final_rgb.g * alpha_mask_g;
        COLOR.b = final_rgb.b * alpha_mask_b;
        COLOR.a = final_alpha;

    } else {
        // Pixel is transparent.
        COLOR = vec4(0.0);
    }
}
