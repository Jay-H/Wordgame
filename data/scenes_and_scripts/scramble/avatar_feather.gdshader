shader_type canvas_item;

// Controls the size of the feathered border. A larger value means a wider, softer edge.
uniform float feather_size : hint_range(0.0, 0.5) = 0.25;

void fragment() {
    // Get the original pixel color from the texture.
    vec4 color = texture(TEXTURE, UV);
    
    // Calculate the minimum distance to a horizontal or vertical edge.
    // UV.x is dist from left, (1.0 - UV.x) is dist from right.
    // UV.y is dist from top, (1.0 - UV.y) is dist from bottom.
    float min_dist_x = min(UV.x, 1.0 - UV.x);
    float min_dist_y = min(UV.y, 1.0 - UV.y);
    float dist_to_edge = min(min_dist_x, min_dist_y);

    // Create a smooth alpha transition based on the distance to the edge.
    // The alpha will be 0 at the very edge and 1 inside the feathered area.
    float alpha = smoothstep(0.0, feather_size, dist_to_edge);
    
    // Multiply the original pixel's alpha by our new feathered alpha.
    color.a *= alpha;
    
    // Set the final pixel color.
    COLOR = color;
}