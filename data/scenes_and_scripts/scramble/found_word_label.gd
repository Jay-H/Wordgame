extends RichTextLabel
var font_size

func _process(_delta):
	
	if size > Vector2(1174.0,693.0):
		add_theme_font_size_override("normal_font_size", get_theme_font_size("normal_font_size") - 1)
	size = Vector2(1174.0, 693.0)
