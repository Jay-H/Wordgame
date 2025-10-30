extends ScrollContainer
var profile_pic_scene = "res://data/scenes_and_scripts/multiplayertesting/profile_picture.tscn"

@onready var HBOX = get_child(0)
@onready var pics = []



func _ready():

	var number_of_pics = GlobalData.profile_pics.size()
	for i in number_of_pics:
		HBOX.add_child(load(profile_pic_scene).instantiate())
	for x in HBOX.get_children():
		pics.append(x)
		var index = x.get_index()
		x.setup(GlobalData.profile_pics[index])	

func _populate_images():
	var number_of_pics = GlobalData.profile_pics.size()
	
