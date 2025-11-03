extends Node

var PlayerDictionary = {}

var profile_pics = ["res://data/images/profilepics/Alan.png", "res://data/images/profilepics/Bookman.png", "res://data/images/profilepics/Gary.png","res://data/images/profilepics/Alan.png", "res://data/images/profilepics/Bookman.png", "res://data/images/profilepics/Gary.png", "res://data/images/profilepics/Arnold.png", "res://data/images/profilepics/Eugene.png", "res://data/images/profilepics/Jennifer.png", "res://data/images/profilepics/Kasper.png", "res://data/images/profilepics/Oak.png" ]
var current_bonus_letter = ""
var bonus_letter_global_position : Vector2 = Vector2(0,0)
var mini_score_display_global_position : Vector2 = Vector2(0,0)
var mini_score_display_size : Vector2 = Vector2(0,0)
var scrabble_dictionary = {}
var obscurity_dictionary = {}
const SCRABBLE_TILE_BAG = "AAAAAAAAABBCDDDEEEEEEEEEEEFFGGGHHIIIIIIIIIJKLLLLMMNNNNNNOOOOOOOOPPQRRRRRRSSSSSTTTTTTUUUUVVWWXYYZ"
var alphabet = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
var vowels = ["A", "E", "I", "O", "U"]
var consonants = ["B", "C", "D","F", "G", "H","J", "K", "L", "M", "N", "P", "Q", "R", "S", "T","V", "W", "X", "Y", "Z"]
var seven_letter_words_list = [] # This list will hold all 7-letter words from your dictionary
var allowed_word_length = 3 # this doesn't affect words that are valid when submitted in scramble, it affects making sure that there are
					# a certain number of words of this length that are real from the functions on this script that are called from the scramble server 
const SCRABBLE_POINTS = {
	'A': 1, 'E': 1, 'I': 1, 'O': 1, 'U': 1, 'L': 1, 'N': 1, 'S': 1, 'T': 1, 'R': 1,
	'D': 2, 'G': 2,
	'B': 3, 'C': 3, 'M': 3, 'P': 3,
	'F': 4, 'H': 4, 'V': 4, 'W': 4, 'Y': 4,
	'K': 5,
	'J': 8, 'X': 8,
	'Q': 10, 'Z': 10,
	'BLANK': 0 # Represents the blank tile in Scrabble
}

func _init():
	load_dictionary("res://data/text_files/scrabble_words.txt")
	load_obscurity("res://data/text_files/obscurity.json")
	print("globals initialization function run")

func _ready():
	load_dictionary("res://data/text_files/scrabble_words.txt")
	load_obscurity("res://data/text_files/obscurity.json")
	
func load_obscurity(file_path):
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not FileAccess.file_exists(file_path):
		print("Error: Dictionary file not found.")
		return

	var json_data = JSON.parse_string(file.get_as_text())
	
	if typeof(json_data) == TYPE_DICTIONARY:
		obscurity_dictionary = json_data
		print("Game dictionary loaded successfully.")
	else:
		print("Error parsing dictionary file.")	

func load_dictionary(path: String): 
	print("load dictionary function run")
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		while not file.eof_reached():
			var line = file.get_line().strip_escapes().to_upper()
			if line != "":
				scrabble_dictionary[line] = true
				if line.length() == 7: # Store all 7-letter words
					seven_letter_words_list.append(line)
		file.close()
		print("7-letter words found: ", seven_letter_words_list.size())
	else:
		print("Error: Could not open dictionary file at ", path)
		
		
func is_valid_word(word_to_check: String) -> bool:
	return scrabble_dictionary.has(word_to_check.to_upper())


# Helper function to convert a character string to a frequency map
func _get_letter_counts(letters_string: String) -> Dictionary:
	var counts = {}
	# Iterate through each character of the string
	for i in letters_string.length():
		var char_str = letters_string[i].to_upper()
		counts[char_str] = counts.get(char_str, 0) + 1
	return counts

# Function to find all valid words from a given set of letters
func find_valid_words_from_letters(letters: String) -> PackedStringArray:
	var found_words = PackedStringArray()
	var available_letters_counts = _get_letter_counts(letters)

	# We'll use a recursive helper function to build words
	# and check them against the dictionary
	var current_word_chars = [] # Stores characters of the word being built

	# Start the recursion. The initial call passes empty_word and full counts
	_generate_words_recursive(current_word_chars, available_letters_counts, found_words)

	return found_words

# Recursive helper function
func _generate_words_recursive(current_word_chars: Array, available_counts: Dictionary, found_words: PackedStringArray):
	# 1. Check if the current word is valid (if length >= 2)
	if current_word_chars.size() >= allowed_word_length: # Minimum word length for Scrabble
		var word = "".join(current_word_chars)
		if GlobalData.is_valid_word(word): # Use your dictionary lookup
			# Add to found_words only if it's not already there (prevents duplicates from permutations of same letters)
			if not found_words.has(word):
				found_words.append(word)

	# 2. Base case: If no more letters can be used, stop
	if available_counts.size() == 0:
		return

	# 3. Recursive step: Try adding each available letter
	for char_key in available_counts.keys().duplicate():
		if available_counts[char_key] > 0:
			# Use the letter
			current_word_chars.append(char_key)
			available_counts[char_key] -= 1

			# Recurse: Continue building the word with remaining letters
			_generate_words_recursive(current_word_chars, available_counts, found_words)

			# Backtrack: Remove the letter and restore count for other branches
			available_counts[char_key] += 1
			current_word_chars.pop_back()

# You might want another utility function to count available words
func count_possible_words(letters: String, min_words: int) -> bool:
	var words = find_valid_words_from_letters(letters)
	return words.size() >= min_words
	
func meets_game_criteria(letters: String, min_total_words: int, require_seven_letter_word: bool = false) -> bool:
	var possible_words = find_valid_words_from_letters(letters)

	# 1. Check if the total number of words meets the minimum
	if possible_words.size() < min_total_words:
		print("Not enough total words found (", possible_words.size(), " < ", min_total_words, ")")
		return false

	# 2. If a 7-letter word is required, check for its existence
	if require_seven_letter_word:
		var has_seven_letter_word = false
		for word in possible_words:
			if word.length() == 7:
				has_seven_letter_word = true
				break # Found one, no need to check further
		
		if not has_seven_letter_word:
			print("No 7-letter word found.")
			return false

	# If all checks pass
	print("All word criteria met!")
	return true
