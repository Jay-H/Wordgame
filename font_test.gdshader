shader_type canvas_item;

// This uniform is where you will drag-and-drop your NoiseTexture
uniform sampler2D noise_texture : source_color, filter_nearest;

void fragment() {
	// 1. Get the text's color and alpha.
	// TEXTURE is the built-in variable for what the CanvasGroup is rendering.
	vec4 text_color = texture(TEXTURE, UV);
	
	// 2. Get the noise color from your texture at the same UV coordinate.
	vec4 noise_color = texture(noise_texture, UV);

	// 3. Set the final color.
	// We use the noise_color.rgb for the color,
	// and the text_color.a for the alpha.
	// This makes the noise "fill" the shape of the text.
	COLOR = vec4(noise_color.rgb, text_color.a);
}