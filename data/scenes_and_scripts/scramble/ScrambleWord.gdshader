shader_type canvas_item;

// Uniforms are variables you can edit in the Inspector
uniform vec4 color1 : source_color = vec4(1.0, 0.0, 1.0, 1.0); // Magenta
uniform vec4 color2 : source_color = vec4(1.0, 1.0, 0.0, 1.0); // Yellow
uniform vec4 color3 : source_color = vec4(0.0, 1.0, 1.0, 1.0); // Cyan
uniform float speed = 0.5;
uniform float width = 1.0;

void fragment() {
    // Get the original texture color (the text pixels)
    vec4 original_color = COLOR * texture(TEXTURE, UV);

    // --- THIS IS THE UPDATED LINE ---
    // Use sin() to create a smooth "ping-pong" effect from 0.0 to 1.0
    float position = (sin((UV.x * width) + (TIME * speed)) + 1.0) * 0.5;

    // Blend the three colors based on the position
    // First, blend between color1 and color2 for the first half
    vec3 mixed_color = mix(color1.rgb, color2.rgb, smoothstep(0.0, 0.5, position));
    // Then, blend the result with color3 for the second half
    mixed_color = mix(mixed_color, color3.rgb, smoothstep(0.5, 1.0, position));

    // Apply the gradient color to the text
    COLOR.rgb = mixed_color;
    // Use the original alpha channel to keep the background transparent
    COLOR.a = original_color.a;
}