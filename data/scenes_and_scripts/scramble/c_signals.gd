extends Node

signal score(new_score)
signal one_second
signal bonus_clicked(text)
var current_game_node = ""

var all_found_words = []

var player_score = 0 # cumulative score over rounds
var enemy_score = 0 # cumulative score over rounds

var player_round_score = 0
var enemy_round_score = 0

var player_name : String = "Chris"
var enemy_name : String = "Jason"

var round_number = 0

var round_one_ended = false
var round_two_ended = false
var round_three_ended = false

var player_won_round_one = false
var enemy_won_round_one = false
var player_won_round_two = false
var enemy_won_round_two = false
var player_won_round_three = false
var enemy_won_round_three = false
var round_one_tie = false
var round_two_tie = false
var round_three_tie = false
