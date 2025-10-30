extends Control

var alphabet = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]

func _ready():
	_letter_changer()
	var length = %Label.text.length()
	for i in range(length):
		var timer = Timer.new()
		timer.wait_time = randf_range(0.1, 0.7)
		timer.autostart = true
		timer.name = str(i)
		timer.timeout.connect(_letter_changer_2.bind(timer))
		add_child(timer)
	#%Timer.timeout.connect(_letter_changer)
	pass



func _letter_changer_2(timer):
	var timer_name = timer.name
	%Label.text[int(timer_name)] = alphabet[randi_range(0,25)]
	
	%Label.text[126] = "f"
	%Label.text[127] = "i"
	%Label.text[128] = "n"
	%Label.text[129] = "d"
	%Label.text[130] = " "
	%Label.text[131] = "g"
	%Label.text[132] = "a"
	%Label.text[133] = "m"
	%Label.text[134] = "e"
	%Label.text[135] = "."
	%Label.text[136] = " "
	
	%Label.text[144] = "s"
	%Label.text[145] = "e"
	%Label.text[146] = "t"
	%Label.text[147] = "t"
	%Label.text[148] = "i"
	%Label.text[149] = "n"
	%Label.text[150] = "g"
	%Label.text[151] = "s"
	%Label.text[152] = "."
	%Label.text[153] = " "

	# "single player. " (Starts at 162 = 144 + 18)
	%Label.text[162] = "s"
	%Label.text[163] = "i"
	%Label.text[164] = "n"
	%Label.text[165] = "g"
	%Label.text[166] = "l"
	%Label.text[167] = "e"
	%Label.text[168] = " "
	%Label.text[169] = "p"
	%Label.text[170] = "l"
	%Label.text[171] = "a"
	%Label.text[172] = "y"
	%Label.text[173] = "e"
	%Label.text[174] = "r"
	%Label.text[175] = "."
	%Label.text[176] = " "

	# "profile. " (Starts at 180 = 162 + 18)
	%Label.text[180] = "p"
	%Label.text[181] = "r"
	%Label.text[182] = "o"
	%Label.text[183] = "f"
	%Label.text[184] = "i"
	%Label.text[185] = "l"
	%Label.text[186] = "e"
	%Label.text[187] = "."
	%Label.text[188] = " "
	
	
	
	
	
	
	
	
func _letter_changer():
	var length = %Label.text.length()
	for i in range(length):
		%Label.text[i] = alphabet[randi_range(0,25)]
	#%Label.text[126] = "f"
	#%Label.text[127] = "i"
	#%Label.text[128] = "n"
	#%Label.text[129] = "d"
	#%Label.text[130] = " "
	#%Label.text[131] = "g"
	#%Label.text[132] = "a"
	#%Label.text[133] = "m"
	#%Label.text[134] = "e"
	pass
