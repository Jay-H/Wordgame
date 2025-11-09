shader_type canvas_item;

uniform float speed : hint_range(0.0, 5.0) = 1.0;
uniform float line_width : hint_range(0.0, 0.2) = 0.15;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float custom_time = 0.0;
uniform float pause_duration : hint_range(0.0, 2.0) = 0.15;
uniform float offset = 2.0;
uniform int pixelate_line : hint_range(0, 1) = 1;
uniform sampler2D screen_texture : hint_screen_texture;

void fragment() {
    // --- CHANGE 1: Use SCREEN_UV for position ---
    // SCREEN_UV ranges from (0,0) to (1,1) across the entire viewport.
    vec2 pos_uv = SCREEN_UV;
    
    // Cycle timing with pause at end
    float cycle_duration = offset + pause_duration;
    float adjusted_time = mod(custom_time * speed, cycle_duration);    

    // Line movement with pause (right to left)
    float line_position;
    if (adjusted_time <= offset) {
        // The line position starts high (off-screen right) and moves left
        line_position = offset - adjusted_time; 
    } else {
        // Pause duration: set the line far off-screen
        line_position = -0.5; 
    }
    
    // Line position source: SCREEN_UV
    vec2 uv_for_line = pos_uv;
    
    // Pixelate the line position calculation (on screen space)
    if (pixelate_line == 1) {
        // Get the size of the viewport in pixels
        vec2 viewport_size = 1.0 / SCREEN_PIXEL_SIZE;
        // Pixelate the UV coordinate
        uv_for_line = floor(pos_uv * viewport_size) / viewport_size;
    }
    
    // Diagonal line rotation (This remains the core effect)
    // The rotation formula should be adjusted slightly since SCREEN_UV is used.
    float rotated_pos = (uv_for_line.x + uv_for_line.y) * 0.5;
    float dist = abs(rotated_pos - line_position);
    
    // Line width and smoothness
    float line_intensity = smoothstep(line_width, 0.0, dist);
    
    // --- CHANGE 2: Combine with the entire screen color ---
    // Sample the screen (what's already drawn)
    vec4 base_color = texture(screen_texture, SCREEN_UV);

    // Apply the line effect only where the line intensity is high
    vec3 final_color = mix(base_color.rgb, line_color.rgb, line_intensity * line_color.a);
    
    // Preserve original alpha and output
    COLOR = vec4(final_color, base_color.a);
}