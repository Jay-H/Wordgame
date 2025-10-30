extends HBoxContainer

func _ready():
	var pictures_control = get_children()
	for i in pictures_control:
		var pictures = i.get_children()
		i.size = Vector2(300,300)
		for x in pictures:
			x.size = Vector2(300,300)
