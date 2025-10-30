// Godot Shader for a Swirling Gas Planet (like Jupiter)
//
// How to use:
// 1. Create a ColorRect or Sprite2D node in your scene.
// 2. Create a new ShaderMaterial for it in the Inspector.
// 3. Create a new Shader for the ShaderMaterial.
// 4. Copy and paste this code into the shader editor.
// 5. Adjust the "Uniforms" in the ShaderMaterial to change the colors, speed, and pattern scale.

shader_type canvas_item;

// Uniforms are variables you can adjust in the Godot editor's Inspector.
uniform vec4 color_dark : source_color = vec4(0.35, 0.2, 0.15, 1.0); // Dark reddish-brown
uniform vec4 color_mid : source_color = vec4(0.65, 0.5, 0.35, 1.0);  // Mid-tone tan
uniform vec4 color_light : source_color = vec4(0.9, 0.85, 0.75, 1.0); // Light cream

uniform float noise_scale : hint_range(1.0, 20.0) = 6.0;    // Controls the "zoom" level of the gas patterns.
uniform float swirl_speed : hint_range(0.01, 1.0) = 0.1;   // How fast the gases swirl and move.
uniform float distortion : hint_range(0.0, 0.5) = 0.05;     // The intensity of the swirling effect.
uniform float band_stretch : hint_range(0.1, 5.0) = 1.5;      // How much to stretch the bands vertically.
uniform float band_softness : hint_range(-5, 5) = 0.175; // Controls the softness of band edges.

// A simple pseudo-random number generator.
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// 2D Value Noise function. It creates smooth, organic patterns by interpolating random values.
float value_noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Get random values for the four corners of the grid cell.
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    // Smoothly interpolate between the corner values.
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Fractal Brownian Motion (FBM). This function stacks multiple layers of noise
// at different scales ("octaves") to create detailed, natural-looking textures.
float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;
    // Loop for 5 layers of noise (octaves). More octaves add more detail.
    for (int i = 0; i < 5; i++) {
        value += amplitude * value_noise(st);
        st *= 2.0; // Each layer is twice the frequency (smaller details).
        amplitude *= 0.5; // Each layer has half the influence.
    }
    return value;
}

void fragment() {
    vec2 uv = UV;

    // Create different horizontal motion speeds for different bands.
    // A sine wave based on the y-coordinate creates alternating flow directions.
    float band_pattern = sin(uv.y * 3.14159 * 2.0 * band_stretch);
    float band_motion = band_pattern * swirl_speed * TIME * 0.5;

    // Create a distortion field that is also stretched, enhancing the horizontal feel.
    float distortion_noise = fbm(vec2(uv.x, uv.y * band_stretch) + TIME * swirl_speed * 0.2);

    // Apply the horizontal motion and distortion to the x-coordinate.
    vec2 final_uv = uv;
    final_uv.x += band_motion + (distortion_noise - 0.5) * distortion;

    // For the main color pattern, we stretch the noise vertically to create horizontal bands.
    final_uv.y *= 0.2 * (1.0 / band_stretch);
    float noise_value = fbm(final_uv * noise_scale);

    // Map the noise value to our Jupiter-like color gradient. The softness is controlled by the new uniform.
    float mid_mix = smoothstep(0.425 - band_softness, 0.425 + band_softness, noise_value);
    float light_mix = smoothstep(0.675 - band_softness, 0.675 + band_softness, noise_value);

    vec3 final_color = mix(color_dark.rgb, color_mid.rgb, mid_mix);
    final_color = mix(final_color, color_light.rgb, light_mix);

    // Set the final pixel color, multiplying by the node's modulate property (passed in via the COLOR variable).
    COLOR *= vec4(final_color, 1.0);
}
