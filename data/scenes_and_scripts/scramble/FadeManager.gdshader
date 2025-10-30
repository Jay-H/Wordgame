// Spruced Up Shader - Idea 2: Distortion
shader_type canvas_item;

// Existing uniforms...
uniform vec4 color_one : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 color_two : source_color = vec4(0.2, 0.0, 0.3, 1.0);
uniform float speed = 0.5;
uniform float frequency = 5.0;
uniform float angle = 45.0;

// --- New parameters for distortion ---
// The noise texture you created.
uniform sampler2D distortion_map : source_color,filter_linear,repeat_enable;
// How much the noise affects the shape.
uniform float distortion_strength = 0.05;
// How fast the noise pattern scrolls, creating a watery effect.
uniform float distortion_speed = 0.1;

void fragment() {
    // --- The new logic ---
    // Animate the noise texture coordinates by scrolling them over time.
    vec2 distorted_uv = UV + vec2(TIME * distortion_speed);
    
    // Sample the noise texture at the animated coordinates to get a distortion value.
    // We only need one channel (e.g., .r) since noise is usually grayscale.
    float distortion = texture(distortion_map, distorted_uv).r * distortion_strength;

    // Apply the distortion to the original UV coordinates before calculating the gradient.
    vec2 final_uv = UV + distortion;

    float angle_rad = radians(angle);
    vec2 direction = vec2(cos(angle_rad), sin(angle_rad));
    // Use the distorted UVs to calculate the gradient value.
    float gradient_value = dot(final_uv, direction);
    
    float animated_value = (sin(gradient_value * frequency + (TIME * speed)) * 0.5) + 0.5;
    
    vec4 final_color = mix(color_one, color_two, animated_value);
    final_color.a *= COLOR.a;
    COLOR = final_color;
}