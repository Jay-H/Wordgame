// Godot Shader for a Dreamy Dusk Sky Background
//
// This shader is designed to be used with a ColorRect node to create a
// procedurally generated, animated background that mimics the colors
// and gentle movement of a sky at dusk.
//
// How to Use:
// 1. Create a ColorRect node in your scene and make it fill the desired area (e.g., the entire screen).
// 2. Create a new ShaderMaterial for the ColorRect.
// 3. Create a new Shader and paste this code into it.
// 4. Assign the shader to the ShaderMaterial.
// 5. You can adjust the colors, speed, complexity, and detail directly in the Inspector.

shader_type canvas_item;

// You can tweak these parameters in the Godot Editor's Inspector panel
uniform vec4 pink_color : source_color = vec4(1.0, 0.7, 0.8, 1.0);
uniform vec4 blue_color : source_color = vec4(0.3, 0.4, 0.7, 1.0);
uniform float noise_scale : hint_range(1.0, 20.0) = 4.0;
uniform float motion_speed : hint_range(0.01, 0.5) = 0.05;
uniform int fbm_octaves : hint_range(1, 8) = 5; // Controls the detail of the clouds


// --- 3D Perlin Noise Functions ---
// This implementation of Perlin noise produces a higher quality, more organic
// noise pattern that avoids the "blocky" look of simpler noise algorithms.

// A hash function to get a pseudo-random float from a 3D vector.
vec3 hash(vec3 p) {
    p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
             dot(p, vec3(269.5, 183.3, 246.1)),
             dot(p, vec3(113.5, 271.9, 124.6)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

// 3D Perlin Noise function
float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);

    // Quintic interpolation curve (smoother than smoothstep)
    vec3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    // Gradients for the 8 corners of the cube
    float g000 = dot(hash(i + vec3(0.0, 0.0, 0.0)), f - vec3(0.0, 0.0, 0.0));
    float g100 = dot(hash(i + vec3(1.0, 0.0, 0.0)), f - vec3(1.0, 0.0, 0.0));
    float g010 = dot(hash(i + vec3(0.0, 1.0, 0.0)), f - vec3(0.0, 1.0, 0.0));
    float g110 = dot(hash(i + vec3(1.0, 1.0, 0.0)), f - vec3(1.0, 1.0, 0.0));
    float g001 = dot(hash(i + vec3(0.0, 0.0, 1.0)), f - vec3(0.0, 0.0, 1.0));
    float g101 = dot(hash(i + vec3(1.0, 0.0, 1.0)), f - vec3(1.0, 0.0, 1.0));
    float g011 = dot(hash(i + vec3(0.0, 1.0, 1.0)), f - vec3(0.0, 1.0, 1.0));
    float g111 = dot(hash(i + vec3(1.0, 1.0, 1.0)), f - vec3(1.0, 1.0, 1.0));

    // Interpolate along x, then y, then z
    return mix(mix(mix(g000, g100, u.x),
                   mix(g010, g110, u.x), u.y),
               mix(mix(g001, g101, u.x),
                   mix(g011, g111, u.x), u.y), u.z);
}

// Fractional Brownian Motion (FBM) function.
// This function layers multiple "octaves" of noise at different scales
// to create a more natural, detailed, and less repetitive pattern.
float fbm(vec3 coord) {
    float total = 0.0;
    float frequency = 1.0;
    float amplitude = 0.5;

    for (int i = 0; i < fbm_octaves; i++) {
        total += noise(coord * frequency) * amplitude;
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    return total;
}


void fragment() {
    // --- Vertical Gradient ---
    // Create a base gradient from pink at the bottom to blue at the top.
    vec4 gradient = mix(blue_color, pink_color, SCREEN_UV.y * 0.8 + 0.2);

    // --- Animated FBM Noise ---
    // We create a single, more complex noise pattern using FBM.
    // Time is used as the third dimension to create smooth, evolving animation.
    vec3 noise_coord = vec3(SCREEN_UV * noise_scale, TIME * motion_speed);

    // We remap the noise from [-1, 1] to [0, 1] for visual use.
    float fbm_noise = fbm(noise_coord) * 0.5 + 0.5;

    // --- Final Color ---
    // Mix the base gradient with a slightly brighter version based on the noise.
    // This makes the "clouds" appear as lighter parts of the sky.
    vec4 final_color = mix(gradient, gradient + vec4(0.15, 0.15, 0.15, 0.0), fbm_noise);

    // Modulate the final color with the node's color property (which is passed in as COLOR).
    // This allows you to tint the sky or fade it in/out using the ColorRect's color.
    COLOR = final_color * COLOR;
}
