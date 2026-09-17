extends Node

signal turn_changed(new_team: String)
signal turn_started(team: String, turn_number: int)

var current_team: String = "Reef"
var turn_number: int = 1
var teams: Array[String] = ["Abyssal", "Reef"]

func _ready() -> void:
	turn_started.emit(current_team, turn_number)

func end_turn() -> void:
	var current_index = teams.find(current_team)
	var next_index = (current_index + 1) % teams.size()
	current_team = teams[next_index]

	# bump turn_number once per full cycle back to the first team
	if next_index == 0:
		turn_number += 1

	turn_changed.emit(current_team)
	turn_started.emit(current_team, turn_number)

func is_turn(team: String) -> bool:
	return team == current_team

func get_current_team() -> String:
	return current_team
func get_current_team_number(current_team: String):
	if current_team == "Reef":
		return 0
	elif current_team == "Abyssal":
		return 1
