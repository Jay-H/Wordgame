extends Control
var letter_change = false

func _ready():
	self.text = GlobalData.alphabet[randi_range(0, 25)]

func _process(delta: float) -> void:
	if letter_change == false:
		letter_change = true
		self.text = GlobalData.alphabet[randi_range(0,25)]
		await get_tree().create_timer(0.5).timeout
		letter_change = false
