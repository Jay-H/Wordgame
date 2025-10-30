// Godot Shader for a Swirling Gas Planet (like Jupiter)
//
// How to use:
// 1. Create a ColorRect or Sprite2D node in your scene.
// 2. Create a new ShaderMaterial for it in the Inspector.
// 3. Create a new Shader for the ShaderMaterial.
// 4. Copy and paste this code into the shader editor.
// 5. Adjust the "Uniforms" in the ShaderMaterial to get the desired atmospheric effect.

shader_type canvas_item;

// --- Uniforms ---
uniform vec4 color_dark : source_color = vec4(0.35, 0.2, 0.15, 1.0); // Dark reddish-brown
uniform vec4 color_mid : source_color = vec4(0.65, 0.5, 0.35, 1.0);  // Mid-tone tan
uniform vec4 color_light : source_color = vec4(0.9, 0.85, 0.75, 1.0); // Light cream

uniform float noise_scale : hint_range(1.0, 20.0) = 8.0;      // Controls the "zoom" of the final color pattern.
uniform float swirl_speed : hint_range(0.01, 1.0) = 0.05;     // Global speed of all motion.
uniform float band_stretch : hint_range(0.1, 5.0) = 1.5;      // How much to stretch the bands vertically.
uniform float band_softness : hint_range(0.01, 0.6) = 0.2;  // Softness of the transitions between color bands.

// New controls for the advanced fluid simulation
uniform float vortex_scale : hint_range(1.0, 10.0) = 2.5;     // The size of the large, primary swirls.
uniform float vortex_intensity : hint_range(0.0, 0.5) = 0.15;  // The strength of the large swirls.
uniform float detail_scale : hint_range(5.0, 25.0) = 12.0;    // The size of the smaller, faster details.
uniform float detail_intensity : hint_range(0.0, 0.1) = 0.02; // The strength of the fine, wispy details.

// NEW: Controls the directional drift of the entire weather system.
uniform float propagation_x : hint_range(-0.5, 0.5) = 0.1;
uniform float propagation_y : hint_range(-0.5, 0.5) = 0.05;

// --- Noise Functions ---

// A simple pseudo-random number generator.
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// 2D Value Noise function. It creates smooth, organic patterns by interpolating random values.
float value_noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    // UPDATED: Using a quintic interpolation (smootherstep) instead of cubic.
    // This produces smoother gradients and heavily reduces visible grid artifacts (the "weird lines").
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Fractal Brownian Motion (FBM). Stacks layers of noise for more detail.
float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 5; i++) {
        value += amplitude * value_noise(st);
        st *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

// --- Curl Noise Function ---
// This is the key to realistic fluid motion. It computes the "curl" of a noise
// field, which results in a swirling, divergence-free vector field.
vec2 curl_noise(vec2 uv, float time) {
    const float epsilon = 0.01;
    // Sample the noise field (potential) at four points around the input 'uv'.
    float n1 = fbm(uv + vec2(epsilon, 0.0) + time);
    float n2 = fbm(uv - vec2(epsilon, 0.0) + time);
    float n3 = fbm(uv + vec2(0.0, epsilon) + time);
    float n4 = fbm(uv - vec2(0.0, epsilon) + time);
    // Calculate derivatives to find the curl.
    float dx = (n1 - n2) / (2.0 * epsilon);
    float dy = (n3 - n4) / (2.0 * epsilon);
    return vec2(dy, -dx);
}

// --- Main Shader Logic ---
void fragment() {
    vec2 uv = UV;
    float time = TIME * swirl_speed;
	vec2 propagation_direction = vec2(propagation_x, propagation_y);

    // --- Fluid Flow Field Calculation (Curl Noise) ---
    // We create two layers of curl noise for a sense of depth and complexity.
    // UPDATED: The time component now includes the propagation_direction, making the
    // weather systems drift across the surface instead of just evolving in place.

    // 1. Large, slow-moving vortices that define the main structure.
    float vortex_time = time * 0.2 + dot(uv, propagation_direction * 2.0);
    vec2 vortex_flow = curl_noise(uv * vortex_scale, vortex_time) * vortex_intensity;

    // 2. Smaller, faster-moving details that add fine, wispy motion.
    float detail_time = time * 0.8 + dot(uv, propagation_direction);
    vec2 detail_flow = curl_noise(uv * detail_scale, detail_time) * detail_intensity;

    // Combine the flow fields to create the final distortion map.
    vec2 distortion = vortex_flow + detail_flow;

    // --- Horizontal Band Motion ---
    // A sine wave creates alternating flow directions for Jupiter's iconic bands.
    float band_pattern = sin(uv.y * 3.14159 * 2.0 * band_stretch);
    float band_motion = band_pattern * swirl_speed * TIME * 0.5;

    // --- Apply all distortions ---
    vec2 final_uv = uv;
    final_uv.x += band_motion; // Apply horizontal shearing.
    final_uv += distortion;    // Apply the swirling fluid distortion.

    // For the main color pattern, we stretch the noise vertically.
    final_uv.y *= 0.2 * (1.0 / band_stretch);
    float noise_value = fbm(final_uv * noise_scale);

    // --- Color Blending ---
    // Map the final noise value to our Jupiter-like color gradient.
    float mid_mix = smoothstep(0.45 - band_softness, 0.45 + band_softness, noise_value);
    float light_mix = smoothstep(0.7 - band_softness, 0.7 + band_softness, noise_value);

    vec3 final_color = mix(color_dark.rgb, color_mid.rgb, mid_mix);
    final_color = mix(final_color, color_light.rgb, light_mix);

    // Set the final pixel color, multiplying by the node's modulate property.
    COLOR *= vec4(final_color, 1.0);
}
