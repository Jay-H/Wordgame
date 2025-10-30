extends Label

func _ready():
	text = CSignals.enemy_name
	await get_tree().process_frame
	position.x -= size.x/2
