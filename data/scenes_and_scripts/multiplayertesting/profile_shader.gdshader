shader_type canvas_item;

// This creates a slider in the Inspector to easily control the fade distance.
// A value of 0.0 means no fade, while 0.5 will fade from the very center.
uniform float softness : hint_range(0.0, 0.5) = 0.2;

void fragment() {
    // Get the original color and alpha from the texture at the current pixel (UV).
    vec4 texture_color = texture(TEXTURE, UV);

    // UV coordinates go from (0,0) at the top-left to (1,1) at the bottom-right.
    // By subtracting 0.5, we make the center (0,0) and the edges +/- 0.5.
    // The abs() function makes it symmetrical.
    vec2 distance_from_center = abs(UV - 0.5);

    // We take the larger of the x or y distances. This creates a box-shaped gradient
    // that is 0 at the center and 0.5 at the edges.
    float distance_from_edge = max(distance_from_center.x, distance_from_center.y);

    // smoothstep creates a smooth transition from 0.0 to 1.0.
    // We invert it (1.0 - ...) so that the center is opaque (alpha = 1.0)
    // and the edges are transparent (alpha = 0.0).
    float fade = 1.0 - smoothstep(0.5 - softness, 0.5, distance_from_edge);

    // Multiply the texture's original alpha by our calculated fade value.
    texture_color.a *= fade;

    // ✅ Apply the final color by multiplying it with the node's modulate color.
    // The built-in COLOR variable already contains the modulate property.
    COLOR *= texture_color;
}