class_name MoveQualityTracker
extends RefCounted

## Foundation for "good moves earn currency." Scores a move by how much it
## improved the mover's evaluation (using the same evaluate() the AI already
## uses), and banks that as currency per team. This only measures and stores
## "how good was that move" -- what currency actually buys (the powerups
## themselves) isn't built yet, that's a separate design decision.

var rules: FesshRules
var currency: Dictionary = {} # Piece.Team -> float

func _init(_rules: FesshRules) -> void:
	rules = _rules
	currency[Piece.Team.REEF] = 0.0
	currency[Piece.Team.ABYSSAL] = 0.0

## Call with board snapshots taken immediately before and after a real move
## (see game_manager.gd's move_piece for the call site).
func score_move(board_before: SearchBoard, board_after: SearchBoard, mover: Piece.Team) -> float:
	var eval_before := rules.evaluate(board_before, mover)
	var eval_after := rules.evaluate(board_after, mover)
	# Only reward improvement for now -- doesn't yet penalize bad moves.
	var gain: float = max(0.0, eval_after - eval_before)

	currency[mover] = currency.get(mover, 0.0) + gain
	return gain

func get_currency(team: Piece.Team) -> float:
	return currency.get(team, 0.0)
