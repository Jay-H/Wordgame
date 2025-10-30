# I added this to autoloader, eventually we'll see how we can load all of the necessary info from a server or
# decide what gets saved on the phone to avoid them screwing around with too many things

extends Control

@export var top_players = []
@export var top_players_dictionary = {}
var level_name_array = ["Dirt", "Bacterium", "Amoeba", "Fungus", "Fungi", "Fun Guy", "Naked Mole Rat", "Common Slug", "Uncommon Slug", "Mouse", "Guinea Pig", "Hamster", "Cat", "Dog", "Rare Slug", "Eagle", "Zebra", "Lion", "Elephant", "Chimpanzee", "Human Being", "Mythic Slug", "Lesser Angel", "Cherubim", "Seraphim", "Archangel", "Exotic Slug", "Demiurge", "Omnipotent God", "Multiverse God", "Holy Spirit", "Nirvanist", "Hologram Breaker", "Universal Eldritch Being", "Wielder of the Phoenix Armament", "Welder of the Phoenix Armament", "CJ Enterprises Co-CEO", "CJ Enterprises Co-CEO's Mom", "Legendary Slug", "Singularity", "One With Nothing"]
var rank_name_array = ["Wood", "Bronze", "Iron", "Steel", "Platinum", "Diamond", "Antimatter"]

#var game_types = [
	#"ScrambleVanilla", "ScrambleBonus","ScrambleBonusObscurity", "ScrambleObscurity", "ScrambleWonder", "ScrambleBonusWonder",
	#"ScrambleObscurityWonder", "ScrambleBonusObscurityWonder", "WordsearchVanilla", "WordsearchShared", 
	#"WordsearchVanilla", "WordsearchShared", "WordsearchVanilla", "WordsearchShared", "WordsearchVanilla", "WordsearchShared"
	#]

#var game_types = ["ScrambleVanilla", "ScrambleBonus","ScrambleBonusObscurity", "ScrambleObscurity", "ScrambleWonder", "ScrambleBonusWonder",
	#"ScrambleObscurityWonder", "ScrambleBonusObscurityWonder"]
	
var game_types = ["ScrambleWonder", "ScrambleWonder", "ScrambleWonder", "ScrambleWonder", "ScrambleWonder", "ScrambleWonder", ]



var backgrounds_dictionary = {"Jupiter": "res://data/scenes_and_scripts/scramble/jupiter4test.tres", "Mars": "res://data/scenes_and_scripts/multiplayertesting/mars.gdshader"}

#region wordsearch
enum WordResult {WIN = 0, RIGHT = 1, WRONG = 2}
enum WordsearchRpcMsgType {SUBMIT_WORD = 0, GENERATE_GRID = 1, WINNER = 2}
enum WordsearchVariants {DEFAULT = 0, SHARED_BOARD = 1, HIDDEN = 2}

var player_save_data : Dictionary = {}

const GRID_SIZE = Vector2i(9, 11)
const GUARANTEED_WORD_COUNT = 5 # might want to reduce or increase for some events or something
const MAX_WORD_LENGTH = 6

const LABEL_FONT_SIZE = 80
const LABEL_FONT_COLOR = Color.WHITE

const CELL_BACKGROUND_COLOR = Color.TRANSPARENT # Background color of each cell
const CELL_HOVER_COLOR = Color.DARK_GRAY # Hover color of each cell
const CELL_HIGHLIGHT_COLOR = Color.LIGHT_SKY_BLUE # Highlight color of each cell
const CELL_FOUND_COLOR = Color.GREEN_YELLOW # Found color of each cell
const CELL_FOUND_BY_OPPONENT_COLOR = Color.ORANGE_RED # Found color of each opponent's cells

const WRONG_LABEL_FONT_SIZE = 100
const WRONG_LABEL_FONT_COLOR = Color.ORANGE

const CORRECT_LABEL_FONT_SIZE = 100
const CORRECT_LABEL_FONT_COLOR = Color.GREEN

const TIMER_LABEL_FONT_SIZE = 100
const TIMER_LABEL_FONT_COLOR = Color.BLUE

const WIN_LABEL_FONT_SIZE = 100
const WIN_LABEL_FONT_COLOR = Color.PURPLE

const LOSE_LABEL_FONT_SIZE = 100
const LOSE_LABEL_FONT_COLOR = Color.CRIMSON

# Just a random one for now, asked gemini to give me a list of words for a godot wordsearch :P
# Eventually depending on certain things, figure we want to base these words on the nubmer of letters
# per word that we want
const WORD_LIST = [
	"GODOT", "SWIFT", "MOBILE", "GAME", "GRID", "DRAG",
	"NODE", "SCENE", "CODE", "DEBUG", "PIXEL", "VECTOR",
	"SHADER", "SPRITE", "SIGNAL", "INPUT", "EXPORT"
]

const SERVER_ADDRESS: String = "127.0.0.1" # Use 127.0.0.1 for local testing
const SERVER_PORT: int = 7777

const LETTER_FREQUENCIES = {
	"A": 8.167, "B": 1.492, "C": 2.782, "D": 4.253, "E": 12.702,
	"F": 2.228, "G": 2.015, "H": 6.094, "I": 6.966, "J": 0.153,
	"K": 0.772, "L": 4.025, "M": 2.406, "N": 6.749, "O": 7.507,
	"P": 1.929, "Q": 0.095, "R": 5.987, "S": 6.327, "T": 9.056,
	"U": 2.758, "V": 0.978, "W": 2.360, "X": 0.150, "Y": 1.974,
	"Z": 0.074
}

# Directions for word placement (8 directions)
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),   # Right
	Vector2i(-1, 0),  # Left
	Vector2i(0, 1),   # Down
	Vector2i(0, -1),  # Up
	Vector2i(1, 1),   # Diagonal Down-Right
	Vector2i(-1, 1),  # Diagonal Down-Left
	Vector2i(1, -1),  # Diagonal Up-Right
	Vector2i(-1, -1)  # Diagonal Up-Left
]

# We can figure this out at some point
const PAIR_FREQUENCIES = {
}

const GAME_DURATION_SECONDS: int = 70
const SUDDEN_DEATH_DURATION_SECONDS: int = 10

func save_to_file():
	#print("Attempting to save data: ", player_save_data)
	var file = FileAccess.open("res://data/text_files/save_game.json", FileAccess.WRITE)
	# Convert the dictionary to a JSON string
	var json_string = JSON.stringify(player_save_data)
	file.store_string(json_string)

func load_from_file():
	var file_path = "res://data/text_files/save_game.json"
	
	if not FileAccess.file_exists(file_path):
		print("Load failed: Save file does not exist at path: %s" % file_path)
		player_save_data = {}
		return player_save_data

	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	
	# CRITICAL LOGGING: Print the file's content before parsing.
	#print("Attempting to parse JSON content: '", json_string, "'")

	if json_string.is_empty():
		print("Load failed: File is empty.")
		player_save_data = {}
		return player_save_data

	var data = JSON.parse_string(json_string)

	if data:
		player_save_data = data
	else:
		# This block runs if the save file is corrupted or contains invalid JSON.
		print("Error parsing JSON data. The save file might be corrupted.")
		print("Loading default placeholder data and overwriting the corrupted save file.")
		
		# 1. Assign the default placeholder data.
		player_save_data = {
			"Auron": {"Experience": int(0), "Level": int(0), "Password": "a", "Rank": int(0), "WinsRemaining": int(3), "ProfilePic": "res://data/images/profilepic.jpg", "Username": "Auron"},
			"Tidus": {"Experience": int(0), "Level": int(0), "Password": "a", "Rank": int(0), "WinsRemaining": int(3), "ProfilePic": "res://data/images/profilepic.jpg", "Username": "Tidus"},
			"Wakka": {"Experience": int(0), "Level": int(0), "Password": "a","Rank": int(0), "WinsRemaining": int(3), "ProfilePic": "res://data/images/profilepic.jpg", "Username": "Wakka"},
			"Yuna": {"Experience": int(0), "Level": int(0), "Password": "a","Rank": int(0), "WinsRemaining": int(3), "ProfilePic": "res://data/images/profilepic.jpg", "Username": "Yuna"},
			"a": {"Experience": int(0), "Level": int(0), "Password": "a", "Rank": int(0), "WinsRemaining": int(3), "ProfilePic": "res://data/images/profilepic.jpg", "Username": "a"},
			"b": {"Experience": int(0), "Level": int(0), "Password": "b", "Rank": int(0), "WinsRemaining": int(3), "ProfilePic": "res://data/images/profilepic.jpg", "Username": "b"},
			"v": {"Experience": int(0), "Level": int(0), "Password": "v", "Rank": int(0), "WinsRemaining": int(3), "ProfilePic": "res://data/images/profilepic.jpg", "Username": "v"},
			}
		
		# 2. Immediately save this new valid data to the file.
		# This overwrites the corrupted data and prevents the infinite loop on the next load attempt.
		save_to_file()
		await get_tree().create_timer(2).timeout
	return player_save_data
#endregion
