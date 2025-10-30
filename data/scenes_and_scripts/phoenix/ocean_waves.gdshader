// A shader that creates a gentle, multi-layered sea wave effect.
// Perfect for 2D backgrounds in Godot.
shader_type canvas_item;

// ## Wave Colors
// Use the color pickers in the Inspector to change these.
uniform vec4 DEEP_WATER_COLOR : source_color = vec4(0.1, 0.3, 0.6, 1.0);
uniform vec4 SHALLOW_WATER_COLOR : source_color = vec4(0.2, 0.5, 0.8, 1.0);

// ## Wave Shape & Motion
// Control how the waves look and move.
uniform vec2 WAVE_FREQUENCY = vec2(4.0, 2.0); // How many waves appear on screen. Higher numbers = more, smaller waves.
uniform float WAVE_SPEED = 0.3; // How fast the waves move.
uniform float WAVE_HEIGHT = 0.05; // How pronounced the color difference is. Higher = more contrast.


void fragment() {
    // We will combine two different wave patterns to make the effect look more natural.
    // By using both UV.x and UV.y and slightly different parameters, the waves
    // will move diagonally and interfere with each other, which looks more like real water.

    // Wave Layer 1: The main, more prominent wave.
    // It uses a combination of x and y coordinates to move diagonally.
    float wave1 = sin(UV.x * WAVE_FREQUENCY.x + UV.y * WAVE_FREQUENCY.y + TIME * WAVE_SPEED);

    // Wave Layer 2: A secondary, slower, and larger wave to add variation.
    // We multiply the frequency and speed by smaller numbers to make it different.
    float wave2 = sin(UV.x * WAVE_FREQUENCY.x * 0.8 + UV.y * WAVE_FREQUENCY.y * 0.5 + TIME * WAVE_SPEED * 0.7);

    // Combine the two wave layers. We multiply them to create interesting interference patterns.
    // The result is a value that smoothly oscillates between -1.0 and 1.0.
    float combined_waves = (wave1 + wave2) * 0.5;

    // We scale the combined wave value by WAVE_HEIGHT to control the final intensity.
    float wave_factor = combined_waves * WAVE_HEIGHT;

    // To mix the colors, we need a value between 0.0 and 1.0.
    // Adding 0.5 shifts our wave factor into a mostly positive range suitable for mixing.
    float mix_amount = clamp(wave_factor + 0.5, 0.0, 1.0);

    // Mix the deep and shallow water colors based on the final wave height.
    // Where the waves are high (mix_amount closer to 1.0), we see the SHALLOW_WATER_COLOR.
    // Where the waves are in a trough (mix_amount closer to 0.0), we see the DEEP_WATER_COLOR.
    vec3 final_color = mix(DEEP_WATER_COLOR.rgb, SHALLOW_WATER_COLOR.rgb, mix_amount);

    // Apply the final color to the pixel.
    COLOR = vec4(final_color, 1.0);
}
