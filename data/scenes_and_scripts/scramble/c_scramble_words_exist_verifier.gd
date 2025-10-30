# Add this to your GlobalData.gd (or a new utility script)

extends Node

# Assuming scrabble_dictionary is already loaded in GlobalData
var scrabble_dictionary = {} # This would be loaded in _ready()

# Helper function to convert a character string to a frequency map
func _get_letter_counts(letters_string: String) -> Dictionary:
	var counts = {}
	for char_code in letters_string.to_upper().unicode_at(0): # Iterate over characters as their uppercase unicode
		var char_str = String.chr(char_code)
		counts[char_str] = counts.get(char_str, 0) + 1
	return counts

# Function to find all valid words from a given set of letters
func find_valid_words_from_letters(letters: String) -> PackedStringArray:
	var found_words = PackedStringArray()
	var available_letters_counts = _get_letter_counts(letters)

	# We'll use a recursive helper function to build words
	# and check them against the dictionary
	var current_word_chars = [] # Stores characters of the word being built

	_generate_words_recursive(current_word_chars, available_letters_counts, found_words)

	return found_words

# Recursive helper function
func _generate_words_recursive(current_word_chars: Array, available_counts: Dictionary, found_words: PackedStringArray):
	# 1. Check if the current word is valid (if length >= 2)
	if current_word_chars.size() >= 2: # Minimum word length for Scrabble
		var word = "".join(current_word_chars)
		if GlobalData.is_valid_word(word): # Use your dictionary lookup
			# Add to found_words only if it's not already there (prevents duplicates from permutations of same letters)
			if not found_words.has(word):
				found_words.append(word)

	# 2. Base case: If no more letters can be used, stop
	if available_counts.empty():
		return

	# 3. Recursive step: Try adding each available letter
	for char_key in available_counts.keys():
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
