// Godot Shader for a Fuzzy, Fluctuating Sun
//
// How to use:
// 1. Create a ColorRect or Sprite2D node in your scene.
// 2. Create a new ShaderMaterial for it in the Inspector.
// 3. Create a new Shader for the ShaderMaterial.
// 4. Copy and paste this code into the shader editor.
// 5. Adjust the "Uniforms" in the ShaderMaterial to change the color, speed, and fuzziness.

shader_type canvas_item;

// Uniforms are variables you can adjust in the Godot editor's Inspector.
uniform vec4 sun_color : source_color = vec4(1.0, 0.9, 0.5, 1.0); // The core color of the sun
uniform float fluctuation_speed : hint_range(0.1, 5.0) = 0.8;    // How fast the brightness flickers
uniform float edge_softness : hint_range(0.1, 1.0) = 0.5;         // How blurry the edge is
uniform float noise_intensity : hint_range(0.0, 0.2) = 0.05;      // The strength of the surface distortion

// A simple function to generate pseudo-random noise.
// It takes a 2D vector (like UV coordinates) and returns a single float value.
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    // UV coordinates go from (0,0) at the top-left to (1,1) at the bottom-right.
    // We remap them so (0,0) is at the center of the sprite.
    vec2 centered_uv = UV - vec2(0.5);

    // Calculate the distance from the center. This will be 0 at the center
    // and 0.5 at the edge of the sprite.
    float distance_from_center = length(centered_uv);

    // Create a time-based value that smoothly oscillates between -1 and 1
    // using a sine wave. This will drive our brightness fluctuation.
    float time_wave = sin(TIME * fluctuation_speed);

    // Add some noise to the time wave to make the flicker less predictable.
    float flicker = time_wave * 0.1 + 0.9; // Base brightness oscillates gently around 0.9

    // Generate some noise based on UV and time to create a shimmering surface effect.
    float surface_noise = random(UV + vec2(TIME * 0.1, 0.0)) * noise_intensity;

    // Define the outer edge of our circle. We add the noise to make the edge
    // subtly distort and shimmer over time.
    float circle_edge = 0.5 - surface_noise;

    // smoothstep creates a soft transition between 0.0 and 1.0.
    // We use it here to create the fuzzy/blurry edge of the sun.
    // It will be 1.0 inside the circle_edge and fade to 0.0 at the edge_softness boundary.
    float alpha = 1.0 - smoothstep(circle_edge - edge_softness, circle_edge, distance_from_center);

    // Final color is the sun_color multiplied by the flickering brightness.
    COLOR.rgb = sun_color.rgb * flicker;

    // The final alpha (transparency) is determined by the smoothstep function.
    COLOR.a = alpha * COLOR.a;
}
