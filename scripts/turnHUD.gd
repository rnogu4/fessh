extends Control

@onready var turn_label: Label = $TurnLabel

func _ready() -> void:
	TurnTracker.turn_changed.connect(_on_turn_changed)
	TurnTracker.turn_started.connect(_on_turn_started)
	# set initial text in case turn_started already fired before we connected
	_on_turn_changed(TurnTracker.get_current_team())

func _on_turn_changed(new_team: String) -> void:
	turn_label.text = "%s's turn" % new_team.capitalize()

	# optional: flip color per team
	match new_team:
		"a":
			turn_label.modulate = Color.CORNFLOWER_BLUE
		"r":
			turn_label.modulate = Color.INDIAN_RED

func _on_turn_started(team: String, turn_number: int) -> void:
	# useful if you want a "Turn 4" style counter somewhere too
	print("Turn %d starting for %s" % [turn_number, team])
