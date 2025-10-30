# ExportSevenLetterWords.gd
extends Node

# --- Configuration ---
const SCRABBLE_DICTIONARY_PATH = "res://data/text_files/scrabble_words.txt" # Path to your full Scrabble dictionary
const OUTPUT_FILE_PATH = "res://data/text_files/seven_letter_words_raw.txt" # Where to save the generated list

func _ready():
	print("Starting to export 7-letter words...")
	export_seven_letter_words()
	get_tree().quit() # Quit the game/editor after running this once

func export_seven_letter_words():
	var seven_letter_words = []

	# Open and read the main Scrabble dictionary
	var input_file = FileAccess.open(SCRABBLE_DICTIONARY_PATH, FileAccess.READ)

	if not input_file:
		print(ERR_CANT_OPEN, " Error: Could not open dictionary file: ", SCRABBLE_DICTIONARY_PATH)
		return

	print("Reading dictionary: ", SCRABBLE_DICTIONARY_PATH)
	while not input_file.eof_reached():
		var line = input_file.get_line().strip_escapes().to_upper()
		if line.length() == 7: # Check if it's exactly 7 letters
			seven_letter_words.append(line)
	input_file.close()

	print("Found ", seven_letter_words.size(), " 7-letter words.")

	# Save the filtered words to the output file
	var output_file = FileAccess.open(OUTPUT_FILE_PATH, FileAccess.WRITE)
	if not output_file:
		print(ERR_CANT_CREATE, " Error: Could not create output file: ", OUTPUT_FILE_PATH)
		return

	print("Writing 7-letter words to: ", OUTPUT_FILE_PATH)
	for word in seven_letter_words:
		output_file.store_line(word)
	output_file.close()

	print("Export complete! Check your project's 'data' folder for 'seven_letter_words_raw.txt'")
