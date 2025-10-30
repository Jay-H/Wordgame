// Jupiter-like Gas Giant Shader for Godot 4.x (2D CanvasItem Version)
//
// Author: Gemini
// Date: 2024-08-28
//
// Description:
// This shader creates a procedural, animated texture resembling the atmosphere
// of a gas giant like Jupiter. It features:
// - Customizable horizontal color bands that are distorted by turbulence.
// - Flowing, turbulent cloud layers using simplex noise.
// - Swirling, spiral-shaped vortices (using curl noise) that warp the atmospheric bands.
// - Exposed parameters for easy editing in the Godot Inspector.
//
// How to Use:
// 1. Save this code as a `.gdshader` file in your Godot project (e.g., "jupiter_shader.gdshader").
// 2. Create a new ShaderMaterial in the Inspector.
// 3. Load this shader file into the ShaderMaterial.
// 4. Apply the ShaderMaterial to a ColorRect or any other 2D CanvasItem node.
// 5. Adjust the "Shader Parameters" in the Inspector to customize the appearance.

shader_type canvas_item; // Changed from 'spatial' to 'canvas_item' for 2D nodes.

// --- Inspector Parameters ---

group_uniforms bands;
uniform vec4 band_color_1 : source_color = vec4(0.83, 0.75, 0.64, 1.0);
uniform vec4 band_color_2 : source_color = vec4(0.65, 0.53, 0.41, 1.0);
uniform vec4 band_color_3 : source_color = vec4(0.91, 0.85, 0.76, 1.0);
uniform vec4 band_color_4 : source_color = vec4(0.53, 0.44, 0.35, 1.0);
uniform float band_frequency : hint_range(1.0, 30.0, 0.1) = 12.0;
uniform float band_sharpness : hint_range(1.0, 50.0, 0.5) = 20.0;

group_uniforms flow_and_vortices;
uniform float noise_scale : hint_range(0.1, 20.0, 0.1) = 5.0;
uniform float flow_speed : hint_range(0.0, 0.5, 0.001) = 0.02;
uniform float vortex_strength : hint_range(0.0, 0.2, 0.001) = 0.05;
uniform float vortex_curl_strength : hint_range(0.0, 5.0, 0.1) = 2.0;
uniform float turbulence_detail : hint_range(1.0, 5.0, 0.1) = 2.5;
uniform float turbulence_intensity : hint_range(0.0, 1.0, 0.01) = 0.15;

// --- Simplex Noise Functions ---
// 2D simplex noise, a foundational function for creating natural-looking procedural textures.
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                        0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                       -0.577350269189626,  // -1.0 + 2.0 * C.x
                        0.024390243902439); // 1.0 / 41.0
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);
    vec2 i1;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod289(i);
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
        + i.x + vec3(0.0, i1.x, 1.0 ));
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
    // The multiplier was too high, causing the color to blow out to white.
    // Reduced from 130.0 to 70.0 to normalize the output.
    return 70.0 * dot(m, g);
}

// --- Fragment Shader ---
void fragment() {
    // In a 2D shader, we use UV directly without 3D-specific modifications.
    vec2 base_uv = UV;

    // --- 1. Calculate Curl Noise for Spiral Vortices ---
    // We create a vector field based on the derivative of a noise function
    // to generate swirling patterns (curl noise). This creates the spiral eddies.
    float epsilon = 0.01; // Small offset for calculating derivatives.
    vec2 curl_uv = base_uv * noise_scale;
    curl_uv.x += TIME * flow_speed * 0.5;

    // Sample noise at points offset along Y and X axes.
    float n_y_pos = snoise(curl_uv + vec2(0.0, epsilon));
    float n_y_neg = snoise(curl_uv - vec2(0.0, epsilon));
    float n_x_pos = snoise(curl_uv + vec2(epsilon, 0.0));
    float n_x_neg = snoise(curl_uv - vec2(epsilon, 0.0));

    // Calculate derivatives (dF/dy and dF/dx).
    float dF_dy = n_y_pos - n_y_neg;
    float dF_dx = n_x_pos - n_x_neg;

    // Create the curl vector: (dF/dy, -dF/dx). This creates rotation.
    vec2 distortion = vec2(dF_dy, -dF_dx) * vortex_strength * vortex_curl_strength;

    // Apply the distortion to the base UVs.
    vec2 distorted_uv = base_uv + distortion;
    
    // --- 2. Create Atmospheric Bands using DISTORTED UVs ---
    // Now the bands will follow the shape of the turbulence.
    float band_pattern = (sin(distorted_uv.y * band_frequency) + 1.0) * 0.5;
    
    // Mix the four band colors based on the band pattern.
    vec4 color_A = mix(band_color_1, band_color_2, smoothstep(0.4, 0.6, band_pattern));
    vec4 color_B = mix(band_color_3, band_color_4, smoothstep(0.4, 0.6, band_pattern));
    float band_mix_factor = pow(band_pattern, band_sharpness);
    vec4 base_color = mix(color_A, color_B, band_mix_factor);

    // --- 3. Create INTEGRATED Flowing Eddies ---
    // This adds fine, turbulent detail that modulates the brightness of the bands,
    // rather than being a separate layer on top.
    vec2 flow_uv = distorted_uv * noise_scale * turbulence_detail;
    flow_uv.x += TIME * flow_speed * 2.5;
	// Remap noise from [-1, 1] to [0, 1] for multiplication
    float overlay_noise = (snoise(flow_uv) + 1.0) * 0.5;
    
    // --- 4. Combine Bands and Turbulence ---
    // Modulate the brightness of the band color with the turbulence noise.
    // This integrates the effect, removing the "film" look.
    vec3 final_color = base_color.rgb * (1.0 - (overlay_noise * turbulence_intensity));

    // --- 5. Final Output ---
    // For canvas_item shaders, the output is 'COLOR'.
    COLOR.rgb = final_color;
    COLOR.a = 1.0;
}
