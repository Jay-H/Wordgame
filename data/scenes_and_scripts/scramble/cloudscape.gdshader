// Shader for creating SEAMLESS, realistic, multi-layered clouds.
shader_type canvas_item;

// ## Tiling
// Defines the period over which the noise pattern repeats to avoid seams.
uniform vec2 tile_period = vec2(10.0, 10.0);

// ## Cloud Shape & Density
uniform float scale : hint_range(0.5, 20.0) = 4.0;
uniform int octaves : hint_range(1, 10) = 6;
uniform float persistence : hint_range(0.1, 1.0) = 0.5;
uniform float lacunarity : hint_range(1.0, 4.0) = 2.0;
uniform float coverage : hint_range(0.0, 1.0) = 0.5;
uniform float softness : hint_range(0.01, 0.5) = 0.15;

// ## Color & Style
uniform vec4 sky_color : source_color = vec4(0.3, 0.5, 0.8, 1.0);
uniform vec4 cloud_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// ## Animation
uniform float speed_primary : hint_range(0.0, 2) = 0.02;
uniform float speed_secondary : hint_range(0.0, 2) = 0.01;

// 2D pseudo-random number generator
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// 2D Noise function - MODIFIED FOR SEAMLESS TILING
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners of a tile, wrapped using mod() to make them tileable.
    float a = random(mod(i, tile_period));
    float b = random(mod(i + vec2(1.0, 0.0), tile_period));
    float c = random(mod(i + vec2(0.0, 1.0), tile_period));
    float d = random(mod(i + vec2(1.0, 1.0), tile_period));

    // Smoothly interpolate between corners
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.y * u.x;
}

// Fractal Brownian Motion (FBM) - layering noise for a natural look
float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;

    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise(st);
        st *= lacunarity;
        amplitude *= persistence;
    }
    return value;
}


void fragment() {
    // ## Animate Coordinates
    vec2 uv_primary = UV * scale;
    uv_primary.y -= TIME * speed_primary;

    vec2 uv_secondary = UV * scale * 0.6;
    uv_secondary.y -= TIME * speed_secondary;

    // ## Generate Cloud Patterns
    float fbm_primary = fbm(uv_primary);
    float fbm_secondary = fbm(uv_secondary);
    float combined_fbm = max(fbm_primary, fbm_secondary);

    // ## Shape and Blend
    float cloud_alpha = smoothstep(coverage - softness, coverage + softness, combined_fbm);

    // ## Final Color
    vec4 final_color = mix(sky_color, cloud_color, cloud_alpha);
    COLOR = final_color * COLOR;
}