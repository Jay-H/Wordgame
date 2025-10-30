// Jupiter-like Gas Giant Shader for Godot 4.x (2D CanvasItem Version)
//
// Author: Gemini
// Date: 2024-08-28
//
// Description:
// This shader creates a procedural, animated texture resembling the atmosphere
// of a gas giant like Jupiter. It features:
// - Four distinct, customizable horizontal color bands with variable height and soft blending.
// - Smooth transitions between the different band types.
// - Flowing, turbulent cloud layers using simplex noise.
// - Per-band physics: Vortices and turbulence behave differently in each band type.
// - Evolving, spiral-shaped vortices (using a curl noise feedback loop) that warp the atmospheric bands.
// - Exposed parameters for easy editing in the Godot Inspector.
//
// How to Use:
// 1. Save this code as a `.gdshader` file in your Godot project (e.g., "jupiter_shader.gdshader").
// 2. Create a new ShaderMaterial in the Inspector.
// 3. Load this shader file into the ShaderMaterial.
// 4. Apply the ShaderMaterial to a ColorRect or any other 2D CanvasItem node.
// 5. Adjust the "Shader Parameters" in the Inspector to customize the appearance.

shader_type canvas_item;

// --- Inspector Parameters ---

group_uniforms band_colors;
uniform vec4 band_A_color_1 : source_color = vec4(0.83, 0.75, 0.64, 1.0);
uniform vec4 band_A_color_2 : source_color = vec4(0.65, 0.53, 0.41, 1.0);
uniform vec4 band_B_color_1 : source_color = vec4(0.91, 0.85, 0.76, 1.0);
uniform vec4 band_B_color_2 : source_color = vec4(0.53, 0.44, 0.35, 1.0);
uniform vec4 band_C_color_1 : source_color = vec4(0.75, 0.60, 0.50, 1.0);
uniform vec4 band_C_color_2 : source_color = vec4(0.45, 0.35, 0.30, 1.0);
uniform vec4 band_D_color_1 : source_color = vec4(1.0, 0.95, 0.9, 1.0);
uniform vec4 band_D_color_2 : source_color = vec4(0.8, 0.7, 0.6, 1.0);

group_uniforms band_properties;
uniform float band_frequency : hint_range(1.0, 30.0, 0.1) = 8.0; // Adjusted for 4 bands
uniform float band_sharpness : hint_range(1.0, 50.0, 0.5) = 20.0;
uniform float band_height_variation : hint_range(0.0, 5.0, 0.01) = 1.0;
uniform float band_definition_variation : hint_range(0.0, 20.0, 0.1) = 5.0;
uniform float band_blend_softness : hint_range(0.0, 0.5, 0.01) = 0.1;
uniform float band_type_transition_softness : hint_range(0.0, 0.5, 0.01) = 0.2;

group_uniforms global_flow;
uniform float noise_scale : hint_range(0.1, 20.0, 0.1) = 5.0;
uniform float vortex_curl_strength : hint_range(0.0, 5.0, 0.1) = 2.0;
uniform float vortex_evolution_speed : hint_range(0.0, 0.5, 0.001) = 0.05;
uniform float turbulence_intensity : hint_range(0.0, 1.0, 0.01) = 0.15;

group_uniforms per_band_physics;
uniform vec4 band_flow_speeds = vec4(0.02, -0.015, 0.03, 0.01);
uniform vec4 band_vortex_strengths = vec4(0.05, 0.04, 0.06, 0.03);
uniform vec4 band_vortex_feedbacks = vec4(0.3, 0.5, 0.2, 0.4);
uniform vec4 band_turbulence_details = vec4(2.5, 3.5, 2.0, 4.0);


// --- Simplex Noise Functions ---
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 mod289(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }
vec4 permute(vec4 x) { return mod289(((x*34.0)+1.0)*x); }
vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

// 2D simplex noise
float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod289(i);
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 )) + i.x + vec3(0.0, i1.x, 1.0 ));
    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m;
    m = m*m;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 70.0 * dot(m, g);
}

// 3D simplex noise for evolving vortices
float snoise3d(vec3 v) {
    const vec2 C = vec2(1.0/6.0, 1.0/3.0);
    const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
    vec3 i  = floor(v + dot(v, C.yyy));
    vec3 x0 = v - i + dot(i, C.xxx);
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min(g.xyz, l.zxy);
    vec3 i2 = max(g.xyz, l.zxy);
    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy;
    vec3 x3 = x0 - D.yyy;
    i = mod289(i);
    vec4 p = permute(permute(permute(i.z + vec4(0.0, i1.z, i2.z, 1.0)) + i.y + vec4(0.0, i1.y, i2.y, 1.0)) + i.x + vec4(0.0, i1.x, i2.x, 1.0));
    float n_ = 0.142857142857;
    vec3 ns = n_ * D.wyz - D.xzx;
    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_);
    vec4 x = x_ * ns.x + ns.yyyy;
    vec4 y = y_ * ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);
    vec4 b0 = vec4(x.xy, y.xy);
    vec4 b1 = vec4(x.zw, y.zw);
    vec4 s0 = floor(b0) * 2.0 + 1.0;
    vec4 s1 = floor(b1) * 2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));
    vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
    vec3 p0 = vec3(a0.xy, h.x);
    vec3 p1 = vec3(a0.zw, h.y);
    vec3 p2 = vec3(a1.xy, h.z);
    vec3 p3 = vec3(a1.zw, h.w);
    vec4 norm = taylorInvSqrt(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;
    vec4 m = max(0.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
    m = m * m;
    return 42.0 * dot(m * m, vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

// Function to calculate curl noise at a specific point in time and space
vec2 get_curl(vec3 p, float p_vortex_strength) {
    float epsilon = 0.01;
    float n_y_pos = snoise3d(p + vec3(0.0, epsilon, 0.0));
    float n_y_neg = snoise3d(p - vec3(0.0, epsilon, 0.0));
    float n_x_pos = snoise3d(p + vec3(epsilon, 0.0, 0.0));
    float n_x_neg = snoise3d(p - vec3(epsilon, 0.0, 0.0));
    float dF_dy = n_y_pos - n_y_neg;
    float dF_dx = n_x_pos - n_x_neg;
    return vec2(dF_dy, -dF_dx) * p_vortex_strength * vortex_curl_strength;
}

// --- Fragment Shader ---
void fragment() {
    vec2 base_uv = UV;

    // --- 1. Determine Band Identity and blend factor ---
    float height_noise = snoise(base_uv * noise_scale * 0.5 + TIME * vortex_evolution_speed * 0.1);
    float band_y_coord = base_uv.y + height_noise * band_height_variation * 0.1;
    // We get 4 bands by multiplying frequency by 0.25
    float band_selector = fract(band_y_coord * band_frequency * 0.25) * 4.0;
    
    int band_id_current = int(floor(band_selector));
    int band_id_next = (band_id_current + 1) % 4; // Wrap around for the last band

    // Calculate blend factor for smooth transitions between major band types
    float band_transition_value = fract(band_selector);
    float blend_factor = smoothstep(1.0 - band_type_transition_softness, 1.0, band_transition_value);

    // --- 2. Mix Per-Band Physics Parameters ---
    float current_flow_speed = mix(band_flow_speeds[band_id_current], band_flow_speeds[band_id_next], blend_factor);
    float current_vortex_strength = mix(band_vortex_strengths[band_id_current], band_vortex_strengths[band_id_next], blend_factor);
    float current_vortex_feedback = mix(band_vortex_feedbacks[band_id_current], band_vortex_feedbacks[band_id_next], blend_factor);
    float current_turbulence_detail = mix(band_turbulence_details[band_id_current], band_turbulence_details[band_id_next], blend_factor);

    // --- 3. Calculate Evolving Curl Noise with Blended Physics ---
    vec3 p1 = vec3(base_uv * noise_scale, TIME * vortex_evolution_speed);
    p1.x += TIME * current_flow_speed * 0.5;
    vec2 distortion1 = get_curl(p1, current_vortex_strength);
    
    vec3 p2 = vec3((base_uv + distortion1) * noise_scale, TIME * vortex_evolution_speed * 0.8);
    p2.x += TIME * current_flow_speed * 0.7;
    vec2 distortion2 = get_curl(p2, current_vortex_strength);
    
    vec2 final_distortion = distortion1 + distortion2 * current_vortex_feedback;
    vec2 distorted_uv = base_uv + final_distortion;
    
    // --- 4. Create Atmospheric Bands with Blended Colors ---
    float definition_noise = (snoise(base_uv * 1.5 + TIME * vortex_evolution_speed * 0.2) + 1.0) * 0.5;
    float varied_sharpness = band_sharpness + definition_noise * band_definition_variation;
    
    float softness_noise = (snoise(base_uv * 3.0 + TIME * vortex_evolution_speed * 0.15) + 1.0) * 0.5 * band_blend_softness;
    float blend_start = 0.5 - softness_noise;
    float blend_end = 0.5 + softness_noise;
    
    // Get colors for current band
    vec4 c1_curr, c2_curr;
    if (band_id_current == 0) { c1_curr = band_A_color_1; c2_curr = band_A_color_2; }
    else if (band_id_current == 1) { c1_curr = band_B_color_1; c2_curr = band_B_color_2; }
    else if (band_id_current == 2) { c1_curr = band_C_color_1; c2_curr = band_C_color_2; }
    else { c1_curr = band_D_color_1; c2_curr = band_D_color_2; }

    // Get colors for next band
    vec4 c1_next, c2_next;
    if (band_id_next == 0) { c1_next = band_A_color_1; c2_next = band_A_color_2; }
    else if (band_id_next == 1) { c1_next = band_B_color_1; c2_next = band_B_color_2; }
    else if (band_id_next == 2) { c1_next = band_C_color_1; c2_next = band_C_color_2; }
    else { c1_next = band_D_color_1; c2_next = band_D_color_2; }
    
    // Mix the color palettes based on the major band transition
    vec4 c1 = mix(c1_curr, c1_next, blend_factor);
    vec4 c2 = mix(c2_curr, c2_next, blend_factor);

	// Use distorted UVs to draw the final bands
    float final_band_pattern = (sin((distorted_uv.y + height_noise * band_height_variation * 0.1) * band_frequency) + 1.0) * 0.5;

    vec4 color_A = mix(c1, c2, smoothstep(blend_start, blend_end, final_band_pattern));
    vec4 color_B = mix(c1, c2, 1.0 - smoothstep(blend_start, blend_end, 1.0 - final_band_pattern));
	// The pow() function adjusts the sharpness/ratio of the two colors.
	// By using final_band_pattern here, we ensure this sharpness gradient flows with the turbulence.
    float band_mix_factor = pow(final_band_pattern, varied_sharpness);
    vec4 base_color = mix(color_A, color_B, band_mix_factor);

    // --- 5. Create INTEGRATED Flowing Eddies ---
    vec2 flow_uv = distorted_uv * noise_scale * current_turbulence_detail;
    flow_uv.x += TIME * current_flow_speed * 2.5;
    float overlay_noise = (snoise(flow_uv) + 1.0) * 0.5;
    
    // --- 6. Combine Bands and Turbulence ---
    vec3 final_color = base_color.rgb * (1.0 - (overlay_noise * turbulence_intensity));

    // --- 7. Final Output ---
	// Multiply the calculated color by the node's modulate property to allow tinting.
    COLOR.rgb *= final_color;
}
