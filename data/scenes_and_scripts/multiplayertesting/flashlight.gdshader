shader_type canvas_item;

uniform vec2 light_position_pixels = vec2(256.0, 256.0); // The center of the light, now in pixel coordinates
uniform vec4 light_color : source_color = vec4(1.0, 1.0, 0.9, 1.0); // Yellowish light
uniform float light_radius_pixels : hint_range(0.0, 1000.0) = 100.0;
uniform float softness_pixels : hint_range(0.0, 500.0) = 50.0;
uniform float ambient_light : hint_range(0.0, 1.0) = 0.1; // How visible the rest of the texture is

void fragment() {
    // Get the original color of the texture at this pixel
    vec4 texture_color = texture(TEXTURE, UV);
    
    // Get the coordinate of the current pixel. (UV / TEXTURE_PIXEL_SIZE) gives the absolute pixel coordinate.
    vec2 current_pixel_coord = UV / TEXTURE_PIXEL_SIZE;
    
    // Calculate the distance from the current pixel to the light's position in pixels.
    // The aspect ratio correction is no longer needed as we are working directly in pixel space.
    float distance_to_light = distance(current_pixel_coord, light_position_pixels);

    // Use smoothstep to create a soft falloff for the light circle, using pixel-based values.
    float light_intensity = 1.0 - smoothstep(light_radius_pixels - softness_pixels, light_radius_pixels + softness_pixels, distance_to_light);

    // The final color is a mix of the lit texture color and the ambient color
    vec4 lit_color = mix(texture_color * ambient_light, texture_color * light_color, light_intensity);

    // Set the final color of the pixel
    COLOR = lit_color * COLOR;
}

