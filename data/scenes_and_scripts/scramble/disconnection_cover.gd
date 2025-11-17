extends Control

var in_progress = false

func _begin(time_left):
	in_progress = true
	%timelefttimer.start(time_left)
	self.visible = true

func _end():
	in_progress = false
	%timelefttimer.stop()
	self.visible = false
	
func _process(_delta):
	if in_progress:
		%timeleft.text = str(int(%timelefttimer.time_left))
