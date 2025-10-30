extends Label

# Get the parent Timer and the child Label.
# Make sure your nodes are named "Timer" and "BonusValueLabel" in the scene tree.
@onready var timer: Timer = get_parent()
@onready var bonus_value_label: Label = %BonusValueLabel

func _ready():
	pass

func _process(_delta):
	# Calculate the base score from the timer's remaining time.
	var time_score = 10 - int(ceil(timer.time_left))
	
	# Check if there is a bonus letter to add.
	var current_bonus_letter = GlobalData.current_bonus_letter
	if current_bonus_letter != "":
		var bonus_value = GlobalData.SCRABBLE_POINTS[current_bonus_letter]
		text =  str(time_score) + " + " + str(bonus_value)
	else:
		text = str(time_score) + " + "
