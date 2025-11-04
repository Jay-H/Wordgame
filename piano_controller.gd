extends Control

var twinkle_twinkle_melody = []
var counter = 0







var g_major_key = []
var g_major_chords = []

func _ready():
	var a_note = %A
	var a_sharp_note = %Asharp
	var b_note = %B
	var c_sharp_note = %Csharp
	var c_note = %C
	var d_note = %D
	var d_sharp_note = %Dsharp
	var e_note = %E
	var f_note = %F
	var f_sharp_note = %Fsharp
	var g_note = %G
	var g_sharp_note = %Gsharp
	var g_chord = %Gmajor
	var c_chord = %Cmajor
	var d_chord = %Dmajor
	var e_minor_chord = %Eminor
	g_major_key.append(a_note)
	g_major_key.append(b_note)
	g_major_key.append(c_note)
	g_major_key.append(d_note)
	g_major_key.append(e_note)
	g_major_key.append(f_sharp_note)
	g_major_key.append(g_note)
	
	g_major_chords.append(g_chord)
	g_major_chords.append(c_chord)
	g_major_chords.append(d_chord)
	g_major_chords.append(e_minor_chord)





	twinkle_twinkle_melody = [
	# Twinkle, twinkle, little star
	g_note, g_note, d_note, d_note, e_note, e_note, d_note,
	# How I wonder what you are
	c_note, c_note, b_note, b_note, a_note, a_note, g_note,
	# Up above the world so high
	d_note, d_note, c_note, c_note, b_note, b_note, a_note,
	# Like a diamond in the sky
	d_note, d_note, c_note, c_note, b_note, b_note, a_note,
	# Twinkle, twinkle, little star
	g_note, g_note, d_note, d_note, e_note, e_note, d_note,
	# How I wonder what you are
	c_note, c_note, b_note, b_note, a_note, a_note, g_note]

	

func play_random_note():
	g_major_key[randi_range(0, (g_major_key.size()-1))].play()
	
	#twinkle_twinkle_melody[counter].play()
	#counter += 1
	#if counter == 41:
		#counter = 0

func play_random_chord():
	g_major_chords[randi_range(0, (g_major_chords.size()-1))].play()
	#play_random_note()
	#g_major_chords[randi_range(0, (g_major_chords.size()-1))].play()
