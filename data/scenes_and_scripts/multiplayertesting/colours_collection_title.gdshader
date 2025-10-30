shader_type canvas_item;

// Rainbow Effect Shader for RichTextLabel
// This shader cycles through rainbow colors horizontally across the text.

// PARAMETERS (uniforms)
// These values can be adjusted in the Godot Inspector.

// Controls how fast the rainbow colors cycle.
uniform float speed : hint_range(0.0, 2.0) = 0.2;
// Controls the width of the rainbow bands. Higher values mean more, tighter bands.
uniform float frequency : hint_range(0.1, 5.0) = 1.0;
// Controls the intensity of the colors. 0.0 is grayscale, 1.0 is full color.
uniform float saturation : hint_range(0.0, 1.0) = 1.0;
// Controls the overall brightness of the text.
uniform float brightness : hint_range(0.0, 1.0) = 1.0;

// This helper function converts a color from the HSV (Hue, Saturation, Value)
// color space to the RGB color space. This is very useful for creating
// rainbow effects, as you can just cycle the Hue (the 'h' in hsv).
vec3 hsv_to_rgb(vec3 hsv) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(hsv.xxx + K.xyz) * 6.0 - K.www);
	return hsv.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), hsv.y);
}

void fragment() {
	// Get the original color and alpha from the RichTextLabel's texture.
	// This is crucial because we only want to color the pixels that the text occupies.
	vec4 original_color = texture(TEXTURE, UV);

	// Calculate the current hue value.
	// - 'UV.x * frequency' makes the rainbow spread across the label horizontally.
	// - 'TIME * speed' makes the colors animate over time.
	// 'fract()' keeps the value between 0.0 and 1.0, creating a smooth loop.
	float current_hue = fract(UV.x * frequency - TIME * speed);

	// Create the color in HSV format using our calculated hue and the parameters.
	vec3 hsv = vec3(current_hue, saturation, brightness);

	// Convert the HSV color to RGB.
	vec3 rgb = hsv_to_rgb(hsv);

	// Set the final pixel color.
	// We use our calculated RGB color and the original alpha value from the text.
	// This ensures that the background of the label remains transparent.
	COLOR = vec4(rgb, original_color.a) * COLOR.a;
}
